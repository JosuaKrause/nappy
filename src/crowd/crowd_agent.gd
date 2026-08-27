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
## How far ahead an agent looks for a street it cannot travel, and how far down a street it
## checks before turning into one — a corridor's width plus a tile, so a probe fired from
## *anywhere* inside a junction clears it and lands on the street beyond.
##
## It was 26px until M21, which is where a turn actually goes wrong. The agent then saw the
## obstruction with a fifth of a tile to spare, so it turned at the far edge of the junction —
## and a turn takes the coordinate the agent had *along* its old corridor and makes it the one
## it has *across* the new one. Turning at the far edge therefore drops a car onto the pavement
## band and it spends the next three tiles steering back to its lane. Rare with four closures a
## day; constant once every four-block calm zone has four dead-end arms on it. Seeing it a
## street early and turning in the middle of the junction is what `_can_turn_here` is for.
const LOOKAHEAD := (Tuning.STREET_WIDTH + 1) * Tuning.TILE_SIZE
## Where the horn's caret sits over a car, and how big it is. Matched to `EventInstance`'s so
## the two carets are the same cue rather than two similar ones, but lower, because a car is
## 26px of sprite against a standing figure's 46.
const HORN_MARK_HEIGHT := 30.0
const HORN_MARK_WIDTH := 15.0

var kind := Kind.WALKER
var colour := Color.WHITE

## The box this agent lives in, held by reference and moved by `Crowd`. Leaving it is what
## recycles an agent now; leaving the *map* was what did it before M27. See `CrowdField`.
var field: CrowdField

## Somebody standing in front of this car, or `Vector2.INF` for nobody. Written once per
## physics frame by `Crowd` for the cars near the player and read here: an agent has no
## business knowing who the player is, but it does have to decide whether to stop.
var pedestrian_ahead := Vector2.INF

## Clear road to the back of the car in front, in px, or INF when there is nobody ahead.
## Written once per physics frame by `Crowd`, for the same reason `pedestrian_ahead` is: the
## neighbour search is one pass over the whole crowd, not one per agent.
var gap_ahead := INF

## True while the player is touching this agent. Owned by `Crowd`, and the reason it exists is
## that a contact is not instantaneous: she walks faster than a pedestrian does, so a person
## bumped from behind stays inside the contact radius for the better part of a second. Without
## it the contact re-fires every frame and one person costs what a crowd should.
var touching := false

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
## Whether the horn caret was up last frame, so it gets one redraw to come off with.
var _was_horning := false

## The speed this agent wants to be doing. A car brakes toward 0 for a crossing somebody is
## waiting at and accelerates back to `_cruise` afterwards; walkers never use it.
var _cruise := 60.0
## Seconds of agitation left, and how loud the agitation started. A person she walked into is
## startled and says so; a car that had to sound its horn keeps sounding for a moment. This is
## how a contact reaches the meter *without* anything writing to `Baby.excitement`: the source
## is the body she touched, summed by `Crowd` exactly like every other body.
var _jolt := 0.0
var _jolt_for := 1.0
var _jolt_intensity := 0.0
var _jolt_inner := 0.0
var _jolt_outer := 0.0

func setup(agent_kind: Kind, map: CityMap, crowd_field: CrowdField, seed_value: int,
		axis_roll: float) -> void:
	kind = agent_kind
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	_choose_lane(axis_roll)
	# Start somewhere along the field rather than at its edge, or the whole crowd arrives from
	# one side in a wave on the first morning. Re-rolled if it lands somewhere it could not have
	# walked to: behind a barrier, which reads as the barrier being fake, or in the middle of a
	# four-block calm zone, where the corridor it belongs to has been park since generation.
	var bounds := field.along_bounds(_vertical)
	for _attempt in 8:
		_set_along(_rng.randf_range(bounds.x, bounds.y))
		_set_cross(_lane_centre)
		if _stands_on_a_street():
			break
	_settle_junction()
	colour = _colour()

## Marks the junction this agent is standing in, if it is standing in one, so that it does not
## roll a turn on its very first frame.
##
## A turn swaps the axes and takes the *along* coordinate as the new *cross* one — which is the
## lane it steers away from. Entering a junction that coordinate is at the junction's edge, so
## the walker cuts the corner onto the nearest pavement and is never on the carriageway. Being
## dropped into the middle of one is different: the coordinate is wherever it was placed, which
## can be the road band, and the walker then strolls out of the junction and up the middle of
## the street while it steers back to a pavement. Rare enough that only a reshuffled crowd found
## it, and it has been possible since M13.
func _settle_junction() -> void:
	_junction = CrowdLanes.corridor_at(_along())

## Whether this agent is standing somewhere it could have got to on its own: an open street, or
## outside the map, which is where an entry band legitimately begins.
func _stands_on_a_street() -> bool:
	var tile := _map.world_to_tile(position)
	if _map.is_closed(tile):
		return false
	return not _map.in_bounds(tile) or _map.is_street(tile)

func _process(delta: float) -> void:
	_jolt = maxf(0.0, _jolt - delta)
	if kind == Kind.CAR:
		_give_way(delta)
	_set_along(_along() + _speed * _direction * delta)
	_set_cross(move_toward(_cross(), _lane_centre, STEER_SPEED * delta))
	if kind == Kind.WALKER:
		_consider_turning()
	if _blocked_ahead(_vertical, _direction, LOOKAHEAD):
		_divert()
	if _has_left_the_field():
		_recycle()
	# Moving a Node2D does not invalidate its draw list — the transform is applied when it
	# is replayed — so an agent only redraws when its picture actually changes. At this
	# population that is the difference between five hundred redraws a frame and a handful.
	var picture := Vector2i(_frame(), 1 if _flipped() else 0)
	if picture != _picture:
		_picture = picture
		queue_redraw()
	# A car sounding its horn draws a caret that breathes, and breathing is per-frame by
	# definition. The one frame after it stops is what takes the caret off again.
	elif kind == Kind.CAR and (_jolt > 0.0 or _was_horning):
		_was_horning = _jolt > 0.0
		queue_redraw()

## Excitement per second this agent contributes at a point. Same falloff as an event, so
## the crowd and the events are the same kind of quantity to the baby.
##
## The jolt is added on top of the body's ordinary noise rather than replacing it, and it
## fades linearly over its own duration — so a bump is a spike with a tail rather than a step
## that ends abruptly, and two people bumped in the same second cost twice.
func contribution_at(world_position: Vector2) -> float:
	var distance := global_position.distance_to(world_position)
	var total := 0.0
	if kind == Kind.CAR:
		total = Tuning.falloff(distance, Tuning.CAR_INTENSITY,
				Tuning.CAR_INNER_RADIUS, Tuning.CAR_OUTER_RADIUS)
	else:
		total = Tuning.falloff(distance, Tuning.PEDESTRIAN_INTENSITY,
				Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	if _jolt > 0.0:
		total += Tuning.falloff(distance, _jolt_intensity * (_jolt / _jolt_for),
				_jolt_inner, _jolt_outer)
	return total

## Startles this agent for `seconds`. The only way anything outside the crowd adds excitement
## to the world, and it deliberately adds it to a *body* rather than to the baby.
func startle(intensity: float, seconds: float, inner: float, outer: float) -> void:
	# Never shortens an agitation already running: a second bump on top of the first must not
	# be able to make the first one quieter.
	if _jolt > 0.0 and intensity * seconds < _jolt_intensity * _jolt:
		return
	_jolt = seconds
	_jolt_for = seconds
	_jolt_intensity = intensity
	_jolt_inner = inner
	_jolt_outer = outer

## True while this agent is agitated, so the same contact is not written down twice.
func is_startled() -> bool:
	return _jolt > 0.0

## How fast it is actually going, for the strike test. A car that has stopped for a crossing
## cannot run anybody over.
func speed() -> float:
	return _speed

## Which way it is pointing, in world space.
func heading() -> Vector2:
	return (Vector2(0.0, _direction) if _vertical else Vector2(_direction, 0.0)).normalized()

## Everything about where this agent is travelling that decides whether another agent is *in
## front of it* — the axis, the corridor, the lane and the way it is pointing. Two agents share
## a queue exactly when they share this. `Crowd` buckets on it once per frame rather than
## comparing every car against every other one.
func lane_key() -> String:
	return "%s:%d:%d:%d" % ["v" if _vertical else "h", _corridor, _lane, signi(int(_direction))]

## How far along its own corridor it is, signed so that "ahead" is always *larger*. Only ever
## compared between two agents with the same `lane_key()`, where the direction is shared.
func queue_position() -> float:
	return _along() * _direction

## Slides this agent back down its own lane. `Crowd` uses it to open a gap that the brake could
## not: a car that is recycled into a lane can materialise inside one that is already there, and
## from inside there is no speed either of them can choose that separates them.
func nudge_back(distance: float) -> void:
	_set_along(_along() - distance * _direction)

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
	# Only the corridors the field actually reaches. Picking from the whole city and then
	# discarding what is out of view is the same crowd spread over ten thousand tiles, which
	# is the thing M27 stops doing.
	_corridor = CrowdLanes.pick_corridor_in_range(_rng, _map.seed_used, _vertical,
			field.corridor_range(_vertical))
	if kind == Kind.CAR:
		_lane = CrowdLanes.ROAD_OFFSETS[_rng.randi_range(0, 1)]
		_direction = CrowdLanes.road_direction(_vertical, _lane)
		_speed = _rng.randf_range(Tuning.CAR_SPEED.x, Tuning.CAR_SPEED.y)
	else:
		_lane = CrowdLanes.SIDEWALK_OFFSETS[_rng.randi_range(
				0, CrowdLanes.SIDEWALK_OFFSETS.size() - 1)]
		_direction = 1.0 if _rng.randf() < 0.5 else -1.0
		_speed = _rng.randf_range(Tuning.PEDESTRIAN_SPEED.x, Tuning.PEDESTRIAN_SPEED.y)
	_cruise = _speed
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_junction = -1

## Playtest 02, finding 3: *"cars should stop at crossings when I am close."* A zebra is only
## the safe way over if the traffic actually honours it — otherwise it is paint, and the
## choice between crossing here and jaywalking there has one arm missing.
##
## Braking rather than stopping dead, and from `CAR_ZEBRA_SIGHT` out, because the giving way
## has to be *visible* from the kerb: a player deciding whether to step off needs to see the
## car slowing, not discover afterwards that it would have.
##
## Since M27 it is also where a car decides not to drive through the one in front — playtest
## 04, *"cars still bump into each other"*. The two wants compose by taking the lower, so a
## queue at a zebra is the car in front stopping and everybody behind it honouring the headway,
## rather than a special case for queues.
func _give_way(delta: float) -> void:
	var wanted := _cruise
	var to_line := _distance_to_stop_line()
	if to_line < INF:
		# The speed that runs out exactly at the line at the *approach* rate. Braking toward a
		# **point** rather than toward zero is the whole of playtest 05's finding 1: aiming at
		# zero stops the car wherever the curve happens to end, which is most of a block early.
		# The gentle rate is what makes the easing start in sight of the kerb — see
		# `CAR_ZEBRA_APPROACH_BRAKE` for what shaping it with `CAR_BRAKE` does instead.
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * to_line))
	wanted = minf(wanted, _following_speed())
	var rate := Tuning.CAR_BRAKE if wanted < _speed else Tuning.CAR_ACCELERATE
	_speed = move_toward(_speed, wanted, rate * delta)

## How far this car has to the stop line of a crossing it should give way at, or `INF` when
## there is nothing to give way to — nobody waiting, or **it is already too late to stop**.
##
## The second half is the commit rule, and it is the other half of finding 1. A car that arrives
## at the paint as the player reaches the kerb used to brake anyway and park on the zebra. There
## is only one safe thing it can do that late, and it is to clear the crossing: `CAR_ZEBRA_SIGHT`
## is nearly four times the distance a car needs to stop, so this only ever fires for somebody
## who stepped up *after* the car had committed, and never for a player who was waiting there.
func _distance_to_stop_line() -> float:
	var crossing := _crossing_ahead_somebody_is_waiting_at()
	if crossing == INF:
		return INF
	# Measured against the **paint**, not against the line. The setback is a comfort margin, so
	# ending up inside it is a car stopped a little close; ending up on the zebra is the thing
	# the rule exists to prevent. Written the other way round — commit when it cannot stop at
	# the *line* — a car that has come to rest exactly there has a braking distance of nothing,
	# decides it is too late, and drives off over the crossing it just stopped for.
	if crossing < Tuning.braking_distance(_speed):
		return INF
	return maxf(0.0, crossing - Tuning.CAR_STOP_LINE_SETBACK)

## The fastest this car may go and still keep `CAR_HEADWAY_TIME` of clear road in front of it.
##
## A time headway rather than a fixed distance, because a fixed one either tailgates at speed
## or leaves a bus-length gap in a jam. `CAR_GAP_MIN` is the standstill distance underneath it:
## without it the arithmetic asks for zero speed at zero gap, which is a car parked inside
## another car rather than behind it.
func _following_speed() -> float:
	if gap_ahead == INF:
		return _cruise
	return maxf(0.0, (gap_ahead - Tuning.CAR_GAP_MIN) / Tuning.CAR_HEADWAY_TIME)

## Distance along the street to the **near edge** of the first crossing ahead that somebody is
## standing at, or `INF` for none.
##
## The near edge rather than the tile centre, because a zebra is several tiles deep and a car
## that stops a setback short of the middle of one is standing on the first half of it.
##
## `pedestrian_ahead` is only ever set for the handful of cars near the player, so this probe
## does not run for the other hundred.
func _crossing_ahead_somebody_is_waiting_at() -> float:
	if pedestrian_ahead == Vector2.INF:
		return INF
	# Somebody in the next street over is not this street's problem.
	var lateral := absf((pedestrian_ahead.x if _vertical else pedestrian_ahead.y) - _cross())
	if lateral > Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5:
		return INF

	# Stepped **tile by tile from the car's own tile**, not by sampling world points every 32px.
	# The sampled version aliases, and the way it fails is the worst possible one: a car stopped
	# at the line is a few pixels from the paint, so both samples miss the crossing, it decides
	# there is nothing to give way to and pulls away with somebody on the zebra. Starting at
	# zero also means a car already on the paint sees it, which is what makes the commit rule
	# below able to tell "not yet there" from "already across".
	var waiting_along := pedestrian_ahead.y if _vertical else pedestrian_ahead.x
	var step_tile := Vector2i(0, signi(int(_direction))) if _vertical \
			else Vector2i(signi(int(_direction)), 0)
	var here := _map.world_to_tile(global_position)
	for step in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var tile := here + step_tile * step
		if _map.tile_at(tile) != GameEnums.TileType.CROSSING:
			continue
		# Distance along the street, not straight-line: somebody waiting at the far kerb of a
		# six-tile corridor is beside the crossing, not two tiles from it.
		var crossing_along := float((tile.y if _vertical else tile.x) * Tuning.TILE_SIZE)
		if absf(waiting_along - crossing_along) > Tuning.CAR_ZEBRA_WAIT_RADIUS:
			continue
		var edge_tile: int = (tile.y if _vertical else tile.x) + (0 if _direction > 0.0 else 1)
		return (float(edge_tile * Tuning.TILE_SIZE) - _along()) * _direction
	return INF

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

	# A turn is the one move that commits without looking, and until M21 that cost nothing: the
	# only unwalkable thing a street could turn into was a barrier, and `_divert` picked the
	# turn up on the next frame. It is not free now — a T-junction on the edge of a four-block
	# calm zone has one arm that is park, and a walker that turns into it is standing on grass
	# before anything notices. So the direction is chosen from the ones that go somewhere, and
	# a junction with no such arm is one this walker carries straight on through.
	var turning := 1.0 if _rng.randf() < 0.5 else -1.0
	if _blocked_ahead(not _vertical, turning, LOOKAHEAD):
		turning = -turning
		if _blocked_ahead(not _vertical, turning, LOOKAHEAD):
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
	_direction = turning
	# It is now travelling through the corridor it just came down, so that is the junction
	# it is in — otherwise it would roll a second turn before clearing the first.
	_junction = kept

## Whether the street `distance` ahead along an axis is one this agent cannot travel: shut for
## the day, or not a street at all.
##
## The second half is M21. A four-block calm zone is painted straight over the corridors between
## its own blocks, so a lane that used to run the width of the city now runs into a park — and
## the tiles are perfectly walkable, which is why `is_closed` alone has nothing to say about
## them. Diverting is the same move a barricade already produces, and it produces the same good
## side effect: a street with nobody on it is a street that does not go through.
##
## Out of bounds is deliberately **not** blocked. The map edge is what `_has_left_the_field`
## handles, and treating it as a wall here would turn agents round at the boundary instead of
## recycling them, which quietly drains the pavement the player is walking towards.
func _blocked_ahead(vertical: bool, direction: float, distance: float) -> bool:
	var offset := Vector2(0.0, direction * distance) if vertical \
			else Vector2(direction * distance, 0.0)
	var tile := _map.world_to_tile(position + offset)
	if _map.is_closed(tile):
		return true
	return _map.in_bounds(tile) and not _map.is_street(tile)

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
		# Still in the street, a junction short of where it can turn. Carry on — unless it is
		# standing *in* the thing it is avoiding, which is a day that started behind a barrier
		# and is the one case with nowhere to go but back.
		if not _stands_on_a_street():
			_direction = -_direction
		return
	if not _can_turn_here():
		return

	var turning := 1.0 if _rng.randf() < 0.5 else -1.0
	if _blocked_ahead(not _vertical, turning, LOOKAHEAD):
		turning = -turning
	if _blocked_ahead(not _vertical, turning, LOOKAHEAD):
		_direction = -_direction   # boxed in on three sides; go back the way it came
		return

	var kept := _corridor
	_vertical = not _vertical
	_corridor = crossing
	_direction = turning
	if kind == Kind.CAR:
		# Back onto the correct side of the road for the way it is now pointing — and it is the
		# *new* axis that decides which side that is, which is what M29 fixed.
		_lane = CrowdLanes.road_lane(_vertical, turning)
	else:
		_lane = CrowdLanes.nearest_sidewalk(_corridor, _cross())
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_junction = kept

## Whether the agent is far enough into a junction to turn without landing on the wrong surface.
##
## A turn makes the *along* coordinate the new *across* one, and the new across coordinate is
## the lane the agent then has to steer away from. So a car turns while it is on the junction's
## carriageway band and a walker while it is on one of its pavement bands, and each ends the
## turn a few pixels from a lane it is allowed to be in rather than two tiles from one. Every
## agent crosses both bands on its way through a junction, so waiting costs at most a tile.
func _can_turn_here() -> bool:
	var offset := CityMap.corridor_offset(floori(_along() / float(Tuning.TILE_SIZE)))
	if offset < 0:
		return false
	return CityMap.is_road_offset(offset) == (kind == Kind.CAR)

## Whether this agent has walked out of the patch of city that is being simulated — either off
## the map entirely, or out of the box that travels with the player.
##
## Deliberately asymmetric along the axis of travel: an agent is done as soon as it passes the
## edge it is *heading for*, and gets the depth of the entry band behind the edge it came in at.
## The obvious symmetric version — "outside the box" — makes the approach lane uninhabitable,
## because anything recycled just outside it qualifies again on the very next frame.
func _has_left_the_field() -> bool:
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var at := _along()
	if at < -Tuning.TILE_SIZE or at > limit + Tuning.TILE_SIZE:
		return true

	# Across the axis first: a street the box has stopped reaching at all. This is not the rare
	# case it looks like — a player walking north leaves behind everybody on every east-west
	# street she has passed, and they are travelling *along* those streets perfectly happily.
	# Checking it after the along-axis test means never checking it, because an agent always has
	# a direction and the along-axis test always answers.
	var lateral: float = field.centre.x if _vertical else field.centre.y
	# A street's width of tolerance, so a corridor half in view keeps the people on it rather
	# than emptying the pavement the player is about to turn onto.
	if absf(_cross() - lateral) > field.radius + Tuning.STREET_WIDTH * Tuning.TILE_SIZE:
		return true

	# Then along it: past the edge it is heading for, or further behind the edge it came in at
	# than the entry band is deep. The second half is not symmetry for its own sake — the player
	# walks faster than a pedestrian, so anybody going her way is steadily left behind, and
	# without it the pavement in front of her drains into a crowd standing two streets back.
	var bounds := field.along_bounds(_vertical)
	if _direction > 0.0:
		return at > bounds.y or at < bounds.x - ENTRY_SPREAD
	return at < bounds.x or at > bounds.y + ENTRY_SPREAD

## How far outside the box an agent may enter, in px.
##
## It has to be a band and not a point, and this is the second thing the M27 probe found by
## printing numbers. Recycling everybody onto the exact edge coordinate puts every car that
## re-enters a lane on the same pixel — and once cars keep a headway, a pile that used to sort
## itself out by driving through each other becomes a permanent stationary queue against the
## boundary. Eight overlapping pairs a frame, on a road nobody could see.
const ENTRY_SPREAD := 420.0

## Out of the field at one edge and back in at the other. The population is fixed for the day,
## so the streets around the player never quietly empty out over five minutes.
##
## It enters somewhere in the band outside whichever edge its new direction carries it inward
## from, which is the whole trick: the field is bigger than the screen, so an agent is always
## off-camera when it appears and has walked a few hundred pixels of pavement by the time it
## is visible.
##
## The lane is re-rolled until the band it would enter through is off the map rather than over
## it. Near the city wall the box hangs into nothing, and an agent placed in that overhang walks
## visibly through the boundary before it reaches the street; a lane running the other way, or
## on the other axis, almost always has room, so a handful of rolls settles it.
##
## Since M21 the entry *point* is rolled inside the same loop and checked too, because a corridor
## may be park for two blocks of its length: a car re-entering there would be standing on grass
## and would divert at the first frame, which is a car appearing in a park and driving out of it.
func _recycle() -> void:
	for _attempt in 6:
		_choose_lane(_rng.randf())
		var bounds := field.along_bounds(_vertical)
		var back := _rng.randf() * ENTRY_SPREAD
		_set_along(bounds.x - back if _direction > 0.0 else bounds.y + back)
		_set_cross(_lane_centre)
		if _entry_band_fits() and _stands_on_a_street():
			break
	_settle_junction()
	gap_ahead = INF

## Whether the whole entry band lies outside the map rather than straddling its edge.
func _entry_band_fits() -> bool:
	var bounds := field.along_bounds(_vertical)
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	if _direction > 0.0:
		return bounds.x - ENTRY_SPREAD >= -Tuning.TILE_SIZE
	return bounds.y + ENTRY_SPREAD <= limit + Tuning.TILE_SIZE

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
		_draw_horn_mark()
		return
	Sprites.draw_shadow(self, Vector2.ZERO, 7.0)
	Sprites.draw_standing(self, WALKER_BODY[frame], Vector2.ZERO, Vector2.ZERO, flip, colour)
	Sprites.draw_standing(self, WALKER_TRIM[frame], Vector2.ZERO, Vector2.ZERO, flip)

## The doubled lethal caret over a car that is sounding its horn. *(M30, playtest 05 finding 3.)*
##
## The vocabulary's first row is *the entity itself carries most of it*, and until M30 the
## traffic was the one place nothing did: the caret is drawn by `EventInstance` and a car is not
## an event, so a lethal thing bearing down on the player produced a mark over **her** head and
## nothing anywhere else. That is the load-bearing cue paying for a warning it should only be
## adding to, and the horn that was supposed to carry it is silent in a game with no audio —
## which is *"audio is never the only channel"* failing in the one place the traffic fairness
## contract depends on it.
##
## Doubled and in `MARK_LETHAL`, exactly as a `hard_fail` event's caret is, because a car is
## exactly as lethal and being told apart by hue is what the doubling exists to avoid. It
## **breathes** with the horn's own decay, which is the one thing the deleted rings did that a
## discrete symbol does not get for free.
func _draw_horn_mark() -> void:
	if _jolt <= 0.0:
		return
	var swell := _jolt / _jolt_for
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(HORN_MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(self, at, HORN_MARK_WIDTH * scale, Palette.MARK_LETHAL)
	Sprites.draw_caret(self, at - Vector2(0.0, HORN_MARK_WIDTH * scale * 0.85),
			HORN_MARK_WIDTH * scale, Palette.MARK_LETHAL)

## The coat, or the paintwork. Authored near-white and multiplied, the same trick the
## buildings use, so a crowd is not one silhouette in one colour ninety times over.
func _colour() -> Color:
	var palette := Palette.CAR_PAINT if kind == Kind.CAR else Palette.COATS
	return palette[_rng.randi_range(0, palette.size() - 1)]
