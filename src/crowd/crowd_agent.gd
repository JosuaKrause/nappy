class_name CrowdAgent
extends Node2D
## One person or one car, going about its business.
##
## An agent is not an event. An event is authored, telegraphed and held to the fairness
## contract; an agent is traffic, and the player is expected to walk around it rather than
## be warned about it. What the two share is the *query*: `Crowd` sums `contribution_at()`
## over its agents exactly as `EventManager` does over its instances, so nothing pushes a
## value at the baby and the crowd composes with the events by plain addition.
##
## Movement is lane-following, not pathfinding. An agent belongs to one corridor lane at a
## time, advances along it, and steers toward the lane's centre rather than being pinned to
## it — which is what lets a walker round a corner without teleporting a half-tile sideways
## when it changes lane.

enum Kind { WALKER, CAR }

const WALKER_BODY: Array[Texture2D] = [
	preload("res://assets/crowd/walker_front_body.svg"),
	preload("res://assets/crowd/walker_back_body.svg"),
	preload("res://assets/crowd/walker_side_body.svg"),
]
const WALKER_TRIM: Array[Texture2D] = [
	preload("res://assets/crowd/walker_front_trim.svg"),
	preload("res://assets/crowd/walker_back_trim.svg"),
	preload("res://assets/crowd/walker_side_trim.svg"),
]
const CAR_BODY: Array[Texture2D] = [
	preload("res://assets/crowd/car_end_body.svg"),
	preload("res://assets/crowd/car_side_body.svg"),
]
const CAR_TRIM: Array[Texture2D] = [
	preload("res://assets/crowd/car_end_trim.svg"),
	preload("res://assets/crowd/car_side_trim.svg"),
]

## How fast an agent closes on its lane centre. Slow enough that a corner reads as a turn.
const STEER_SPEED := 90.0
## How far ahead an agent looks for a closed street. Just under a tile: far enough to turn
## at the junction rather than at the barrier, close enough that it does not turn a block
## early and leave the street it was on looking mysteriously avoided.
const CLOSURE_LOOKAHEAD := 26.0
## How far down a street an agent checks before turning into it. A whole tile past the
## junction, so it does not turn out of one closed street straight into another.
const DIVERT_PROBE := 40.0

var kind := Kind.WALKER
var colour := Color.WHITE

var _map: CityMap
## Its own RNG, seeded from the day and its own index. Per-agent rather than shared so a
## turn taken at a junction cannot depend on the order agents happen to reach junctions in
## — which frame timing would otherwise decide.
var _rng := RandomNumberGenerator.new()

## True when travelling along a vertical corridor, i.e. moving in Y.
var _vertical := false
var _corridor := 0
var _lane := 0
var _direction := 1.0
var _speed := 60.0
var _lane_centre := 0.0
## The junction the agent is currently inside, so a turn is rolled once per junction and
## not once per frame for as long as it takes to cross one.
var _junction := -1
## The frame and flip currently drawn, so a redraw only happens when they change.
var _picture := Vector2i(-1, -1)

func setup(agent_kind: Kind, map: CityMap, seed_value: int, axis_roll: float) -> void:
	kind = agent_kind
	_map = map
	_rng.seed = seed_value
	_choose_lane(axis_roll)
	# Start somewhere along the corridor rather than at its mouth, or the whole crowd
	# arrives at the map edge in one wave on the first morning. Re-rolled if it lands inside
	# a street that is closed today: an agent that starts behind a barrier would walk out
	# through it once, which reads as the barrier being fake.
	var limit: float = _map.world_size()[1 if _vertical else 0]
	for _attempt in 8:
		_set_along(_rng.randf() * limit)
		_set_cross(_lane_centre)
		if not _map.is_closed(_map.world_to_tile(position)):
			break
	colour = _colour()

func _process(delta: float) -> void:
	_set_along(_along() + _speed * _direction * delta)
	_set_cross(move_toward(_cross(), _lane_centre, STEER_SPEED * delta))
	if kind == Kind.WALKER:
		_consider_turning()
	if _closed_ahead(_vertical, _direction, CLOSURE_LOOKAHEAD):
		_divert()
	if _has_left_the_map():
		_recycle()
	# Moving a Node2D does not invalidate its draw list — the transform is applied when it
	# is replayed — so an agent only redraws when its picture actually changes. At this
	# population that is the difference between five hundred redraws a frame and a handful.
	var picture := Vector2i(_frame(), 1 if _flipped() else 0)
	if picture != _picture:
		_picture = picture
		queue_redraw()

## Excitement per second this agent contributes at a point. Same falloff as an event, so
## the crowd and the events are the same kind of quantity to the baby.
func contribution_at(world_position: Vector2) -> float:
	if kind == Kind.CAR:
		return Tuning.falloff(global_position.distance_to(world_position),
				Tuning.CAR_INTENSITY, Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	return Tuning.falloff(global_position.distance_to(world_position),
			Tuning.PEDESTRIAN_INTENSITY, Tuning.PEDESTRIAN_INNER_RADIUS,
			Tuning.PEDESTRIAN_OUTER_RADIUS)

# ------------------------------------------------------------------ lanes ---

func _along() -> float:
	return position.y if _vertical else position.x

func _cross() -> float:
	return position.x if _vertical else position.y

func _set_along(value: float) -> void:
	if _vertical:
		position.y = value
	else:
		position.x = value

func _set_cross(value: float) -> void:
	if _vertical:
		position.x = value
	else:
		position.y = value

## Picks a corridor, a lane in it and a direction. `roll` decides the axis, so a caller can
## spread a crowd evenly across both instead of letting one axis win by chance.
func _choose_lane(roll: float) -> void:
	_vertical = roll < 0.5
	_corridor = CrowdLanes.pick_corridor(_rng, _map.seed_used, _vertical)
	if kind == Kind.CAR:
		_lane = CrowdLanes.ROAD_OFFSETS[_rng.randi_range(0, 1)]
		_direction = CrowdLanes.road_direction(_lane)
		_speed = _rng.randf_range(Tuning.CAR_SPEED.x, Tuning.CAR_SPEED.y)
	else:
		_lane = CrowdLanes.SIDEWALK_OFFSETS[_rng.randi_range(
				0, CrowdLanes.SIDEWALK_OFFSETS.size() - 1)]
		_direction = 1.0 if _rng.randf() < 0.5 else -1.0
		_speed = _rng.randf_range(Tuning.PEDESTRIAN_SPEED.x, Tuning.PEDESTRIAN_SPEED.y)
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_junction = -1

## A walker rounds a corner. Rolled once per junction, and the new lane is whichever
## pavement is nearest: someone turning a corner keeps to the side they are already on
## rather than stepping across the carriageway to do it.
func _consider_turning() -> void:
	var crossing := CrowdLanes.corridor_at(_along())
	if crossing < 0:
		_junction = -1
		return
	if crossing == _junction:
		return
	_junction = crossing
	if _rng.randf() >= Tuning.PEDESTRIAN_TURN_CHANCE:
		return

	# The two axes swap roles and the position does not move: what was the distance along
	# the old corridor is, unchanged, the distance across the new one. The lane it steers
	# to is the nearest pavement, so a walker that turns from the middle of a junction cuts
	# the corner instead of stepping back to the kerb first.
	var kept := _corridor
	_vertical = not _vertical
	_corridor = crossing
	_lane = CrowdLanes.nearest_sidewalk(_corridor, _cross())
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_direction = 1.0 if _rng.randf() < 0.5 else -1.0
	# It is now travelling through the corridor it just came down, so that is the junction
	# it is in — otherwise it would roll a second turn before clearing the first.
	_junction = kept

## Whether the street `distance` ahead along an axis is closed today.
func _closed_ahead(vertical: bool, direction: float, distance: float) -> bool:
	var offset := Vector2(0.0, direction * distance) if vertical \
			else Vector2(direction * distance, 0.0)
	return _map.is_closed(_map.world_to_tile(position + offset))

## Traffic goes round a closure, and that is half of what makes one legible: the street with
## nobody on it is the street that is shut, which reads from a block away — further than the
## barrier itself does.
##
## Turning here rather than only in `_consider_turning` is why cars divert too. A car that
## carried on would drive through the barrier, and a car that vanished at the junction would
## be worse: at this population something popping out of existence is very visible.
func _divert() -> void:
	var crossing := CrowdLanes.corridor_at(_along())
	if crossing < 0:
		# Caught mid-street, which only happens on the first frame of a day. Turn round.
		_direction = -_direction
		return

	var turning := 1.0 if _rng.randf() < 0.5 else -1.0
	if _closed_ahead(not _vertical, turning, DIVERT_PROBE):
		turning = -turning
	if _closed_ahead(not _vertical, turning, DIVERT_PROBE):
		_direction = -_direction   # boxed in on three sides; go back the way it came
		return

	var kept := _corridor
	_vertical = not _vertical
	_corridor = crossing
	_direction = turning
	if kind == Kind.CAR:
		# Back onto the correct side of the road for the way it is now pointing.
		_lane = CrowdLanes.ROAD_OFFSETS[1] if turning > 0.0 else CrowdLanes.ROAD_OFFSETS[0]
	else:
		_lane = CrowdLanes.nearest_sidewalk(_corridor, _cross())
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_junction = kept

func _has_left_the_map() -> bool:
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var at := _along()
	return at < -Tuning.TILE_SIZE or at > limit + Tuning.TILE_SIZE

## Off the edge of the world and back on again somewhere else. The population is fixed for
## the day, so the streets never quietly empty out over five minutes.
func _recycle() -> void:
	_choose_lane(_rng.randf())
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	_set_along(-Tuning.TILE_SIZE if _direction > 0.0 else limit + Tuning.TILE_SIZE)
	_set_cross(_lane_centre)

# ---------------------------------------------------------------- drawing ---

## Which sprite the agent is showing: side-on along a horizontal corridor, front or back
## along a vertical one. A car has no front/back pair — at this angle both ends of a car are
## the same shape, and the lights in the trim say which way it is pointing.
func _frame() -> int:
	if kind == Kind.CAR:
		return 1 if not _vertical else 0
	if not _vertical:
		return 2
	return 0 if _direction > 0.0 else 1

func _flipped() -> bool:
	return not _vertical and _direction < 0.0

func _draw() -> void:
	var frame := _frame()
	var flip := _flipped()
	if kind == Kind.CAR:
		Sprites.draw_shadow(self, Vector2.ZERO, 18.0)
		Sprites.draw_standing(self, CAR_BODY[frame], Vector2.ZERO, Vector2.ZERO, flip, colour)
		Sprites.draw_standing(self, CAR_TRIM[frame], Vector2.ZERO, Vector2.ZERO, flip)
		return
	Sprites.draw_shadow(self, Vector2.ZERO, 7.0)
	Sprites.draw_standing(self, WALKER_BODY[frame], Vector2.ZERO, Vector2.ZERO, flip, colour)
	Sprites.draw_standing(self, WALKER_TRIM[frame], Vector2.ZERO, Vector2.ZERO, flip)

## The coat, or the paintwork. Authored near-white and multiplied, the same trick the
## buildings use, so a crowd is not one silhouette in one colour ninety times over.
func _colour() -> Color:
	var palette := Palette.CAR_PAINT if kind == Kind.CAR else Palette.COATS
	return palette[_rng.randi_range(0, palette.size() - 1)]
