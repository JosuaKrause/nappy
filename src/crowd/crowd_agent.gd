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

## Where the other cars are, by lane, so a turn can look before it commits. Held by reference and
## refilled once a frame by `Crowd`; null for an agent built by hand in a test, which then turns
## the way it always did. See `TrafficIndex`.
var traffic: TrafficIndex

## Somebody standing in front of this car, or `Vector2.INF` for nobody. Written once per
## physics frame by `Crowd` for the cars near the player and read here: an agent has no
## business knowing who the player is, but it does have to decide whether to stop.
var pedestrian_ahead := Vector2.INF

## Clear road to the back of the car in front, in px, or INF when there is nobody ahead.
## Written once per physics frame by `Crowd`, for the same reason `pedestrian_ahead` is: the
## neighbour search is one pass over the whole crowd, not one per agent.
var gap_ahead := INF

## Distance to the stop line of a junction this car has to give way at, or `INF` when it has
## right of way. Written once per physics frame by `Crowd.give_way_at_junctions()`, because
## whose turn it is at a box is a question about the pair of them and not about either one.
var junction_hold := INF

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

## A sidestep held for a moment after being walked into: how far across its own corridor, and how
## long is left on it. See `step_aside()`.
var _detour := 0.0
var _detour_left := 0.0
## And the same for somebody *crossing* her path rather than sharing it, who has no sidestep to
## make: whether it is hurrying across or waiting, and how long is left on it.
var _yield_hurry := false
var _yield_left := 0.0

func setup(agent_kind: Kind, map: CityMap, crowd_field: CrowdField, seed_value: int,
		axis_roll: float) -> void:
	kind = agent_kind
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	# Start somewhere along the field rather than at its edge, or the whole crowd arrives from
	# one side in a wave on the first morning. Re-rolled if it lands somewhere it could not have
	# walked to: behind a barrier, which reads as the barrier being fake, or in the middle of a
	# four-block calm zone, where the corridor it belongs to has been park since generation.
	#
	# **And if the whole street is wrong, it picks another street.** *(Playtest 13.)* Re-rolling
	# only the position along a corridor cannot help a car that was given a corridor with nowhere
	# drivable in view — a precinct is three blocks of an otherwise ordinary street, so the
	# corridor keeps its car weight and the *stretch in the field* may be entirely pedestrianised.
	# Eight position re-rolls all landed among the bollards and the ninth placed it there anyway:
	# a car standing in a precinct, which `tests/test_crowd.gd` asks about by name. This is M38's
	# rule one scale out — **a retry is not a guarantee** — and the answer is the same shape:
	# when re-rolling the small decision keeps failing, re-take the big one.
	for _street in 4:
		_choose_lane(axis_roll)
		var bounds := field.along_bounds(_vertical)
		var placed := false
		for _attempt in 8:
			_set_along(_rng.randf_range(bounds.x, bounds.y))
			_set_cross(_lane_centre)
			if _stands_on_a_street():
				placed = true
				break
		if placed:
			break
		# A fresh axis roll, or the second attempt at a car is the first attempt again: the roll
		# the caller passed is a *fixed* alternation for walkers, so re-using it re-picks the same
		# axis and, in a field with one drivable corridor, very often the same corridor.
		axis_roll = _rng.randf()
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
	if not _map.in_bounds(tile):
		return true
	# A precinct is paved end to end, so every tile of it says "street" and a car placed there
	# would look perfectly settled right up to the moment it drove off down the paving. Asked
	# here rather than at lane-choosing time because it is a question about a *place*, and the
	# place is not decided until the along position is rolled.
	if kind == Kind.CAR and not _map.is_driveable_at(_vertical, tile):
		return false
	# And a walker is never placed in a carriageway. It matters since M41 because a precinct's
	# lanes run the whole width of the corridor, and a lane is chosen before the along position
	# that decides whether this stretch is a precinct at all — so the re-roll is what keeps the
	# two in step rather than an ordering assumption that would be wrong once in ten.
	if kind == Kind.WALKER and _map.tile_at(tile) == GameEnums.TileType.ROAD:
		return false
	return _map.is_street(tile)

func _process(delta: float) -> void:
	_jolt = maxf(0.0, _jolt - delta)
	if _detour_left > 0.0:
		_detour_left = maxf(0.0, _detour_left - delta)
		if _detour_left <= 0.0:
			_detour = 0.0
	_yield_left = maxf(0.0, _yield_left - delta)
	if kind == Kind.CAR:
		_give_way(delta)
	_set_along(_along() + _speed * _yield_factor() * _direction * delta)
	_set_cross(move_toward(_cross(), _lane_centre + _detour, STEER_SPEED * delta))
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

## This car has hit another one in a junction. It stops dead and sounds off, and then pulls away
## again on its own — `_cruise` is untouched, so recovery is the ordinary acceleration.
##
## The startle is what makes it *loud where it happened* rather than a number written at the baby;
## see `Crowd._collide_in_the_box` for why a collision is this and not a catalogue row. Already
## being startled is enough to skip it, which is the same hysteresis a contact uses: a pair sitting
## inside each other for half a second must cost one crash, not thirty.
func crashed_into() -> void:
	if _jolt > 0.0:
		return
	_speed = 0.0
	startle(Tuning.CAR_HORN_INTENSITY, Tuning.CAR_HORN_DURATION * 2.0,
			Tuning.CAR_HORN_INNER_RADIUS, Tuning.CAR_HORN_OUTER_RADIUS)

## How fast it is actually going, for the strike test. A car that has stopped for a crossing
## cannot run anybody over.
func speed() -> float:
	return _speed

## How fast and which way it is actually travelling, for anything predicting where it will be.
func velocity() -> Vector2:
	return heading() * _speed * _yield_factor()

## True while travelling along a vertical corridor. What decides whether two cars at the same
## junction are crossing each other's path or merely queueing behind one another.
func travelling_vertically() -> bool:
	return _vertical

# -------------------------------------------------------------- junctions ---
# A lane is a queue and a junction is a **box**, and until M41 only the queue was modelled. Two
# cars on crossing arms each saw a clear lane ahead, both entered, and the M27 positional resolve
# then did the only thing it can — move a body. Measured over ninety seconds of the arterial:
# 3,776 overlapping crossing-axis pairs, one in half of all frames, the deepest 39px into a 40px
# footprint. That is two cars passing through each other's centres, in plain sight, and the queue
# was legal on every frame — which is why five milestones of "no two cars are inside each other"
# tests could not see it. Same shape as M38's fix one level along: look before committing.

## Half the length of the body along its own line of travel, which is what actually enters a box
## first and leaves it last. Zero for a walker, who is not what a box is rationed between.
func _nose() -> float:
	return Tuning.CAR_STRIKE_HALF_LENGTH if kind == Kind.CAR else 0.0

## The junction this agent's **body** is standing in, or `(-1, -1)`. Nose and tail, not the
## centre: a car is 52px long against a 192px box, so half a length of it is still in the way
## after its middle has left.
func junction_occupied() -> Vector2i:
	var half := _nose()
	for edge in [_along() - half, _along() + half]:
		var tile_along := floori(edge / float(Tuning.TILE_SIZE))
		if CityMap.corridor_offset(tile_along) < 0:
			continue
		var index := CityMap.junction_index(tile_along)
		return Vector2i(_corridor, index) if _vertical else Vector2i(index, _corridor)
	return Vector2i(-1, -1)

## The junction this agent is coming to, whether or not it is in it yet.
func junction_ahead() -> Vector2i:
	var index := _junction_index()
	return Vector2i(_corridor, index) if _vertical else Vector2i(index, _corridor)

## Distance from this agent's nose to the near edge of that box. Negative once it is inside.
func distance_to_junction() -> float:
	var index := _junction_index()
	var low := float(index * CityMap.period() * Tuning.TILE_SIZE)
	var near := low if _direction > 0.0 \
			else low + Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE)
	return (near - _along()) * _direction - _nose()

## Which corridor band along its own axis the agent is in or heading for. Inside one, that is the
## one it is in; in the block band between two, it is whichever lies the way it is pointing.
func _junction_index() -> int:
	var along_tile := floori(_along() / float(Tuning.TILE_SIZE))
	var index := CityMap.junction_index(along_tile)
	if CityMap.corridor_offset(along_tile) < 0 and _direction > 0.0:
		index += 1
	return index

## Which way it is pointing, in world space.
func heading() -> Vector2:
	return (Vector2(0.0, _direction) if _vertical else Vector2(_direction, 0.0)).normalized()

## Everything about where this agent is travelling that decides whether another agent is *in
## front of it* — the axis, the corridor, the lane and the way it is pointing. Two agents share
## a queue exactly when they share this. `Crowd` buckets on it once per frame rather than
## comparing every car against every other one.
func lane_key() -> String:
	return make_lane_key(_vertical, _corridor, _lane, _direction)

## The same key for a lane this agent is not in yet, which is what a car needs to ask whether the
## arm it is about to turn into has anybody in it.
static func make_lane_key(vertical: bool, corridor: int, lane: int, direction: float) -> String:
	return "%s:%d:%d:%d" % ["v" if vertical else "h", corridor, lane, signi(int(direction))]

## How far along its own corridor it is, signed so that "ahead" is always *larger*. Only ever
## compared between two agents with the same `lane_key()`, where the direction is shared.
func queue_position() -> float:
	return _along() * _direction

## Slides this agent back down its own lane. `Crowd` uses it to open a gap that the brake could
## not: a car that is recycled into a lane can materialise inside one that is already there, and
## from inside there is no speed either of them can choose that separates them.
func nudge_back(distance: float) -> void:
	_set_along(_along() - distance * _direction)

## Somebody she walked into gets out of her way. *(Playtest 07, finding 5.)*
##
## The separation `Crowd._bump` applies is positional and it works — and it is undone on the very
## next frame by this agent steering back to `_lane_centre`, which is where she is standing. So a
## bump resolved and re-formed for as long as she stayed there, which is the sticking the player
## reported and, with a fresh jolt each time, most of the "instant death".
##
## What moves is the agent's own **steering target**, not the player: it aims a lane over for a
## couple of seconds and then comes back. That keeps the invariant intact — separation between
## bodies is positional, never a force — and it is also just what a person does when you walk into
## them.
##
## `away` is in world space; only the component across this agent's own corridor means anything to
## it, and the result is clamped inside the pavement band, because a walker that yields into the
## carriageway is a walker under a car.
func step_aside(away: Vector2, distance: float, seconds: float) -> void:
	if kind == Kind.CAR:
		# A car does not get out of anybody's way. The carriageway is hers to stay off.
		return
	var across := away.x if _vertical else away.y
	var along := away.y if _vertical else away.x
	if absf(across) >= absf(along):
		var band := _pavement_band()
		_detour = clampf(_lane_centre + _detour + signf(across) * distance, band.x, band.y) \
				- _lane_centre
		_detour_left = maxf(_detour_left, seconds)
		return

	# **The direction she needs is this walker's own line of travel**, so there is nothing to
	# steer: it is crossing her path rather than sharing it. *(Playtest 07, finding 17. A probe
	# says nine to eleven of every twelve contacts on a forty-second walk are with somebody
	# crossing, which is the whole reason this branch exists — a sidestep alone left the number
	# exactly where it found it.)*
	#
	# What a person does at a corner is hurry across or wait, and which one depends only on
	# whether carrying on takes them further from her line. Both are a speed for a moment; neither
	# touches the lane, the corridor or the path, so a walker that yields is still going exactly
	# where it was going.
	_yield_hurry = signf(along) == signf(_direction)
	_yield_left = maxf(_yield_left, seconds)

## The stretch of cross-axis coordinate this walker's own pavement covers, as `(low, high)`.
##
## Clamped against the **band**, not against a symmetric distance from the lane centre, because
## the pavement is not symmetric about a lane: offsets 0 and 1 are one footway and 4 and 5 are the
## other, with the carriageway in between. A walker on the kerbside lane that is asked to move
## kerbwards must stop at the kerb — the first version clamped by distance and would happily have
## put somebody 48px into the road to get out of her way, which is a pedestrian under a car.
func _pavement_band() -> Vector2:
	var offsets := CrowdLanes.walkable_offsets(_map, _vertical, _corridor,
			floori(_along() / float(Tuning.TILE_SIZE)))
	# A precinct has one footway and it is the whole street, so there is no far side to be on.
	if offsets.size() > 4:
		var slack_all := float(Tuning.TILE_SIZE) * 0.5
		return Vector2(CrowdLanes.lane_centre(_corridor, offsets[0]) - slack_all,
				CrowdLanes.lane_centre(_corridor, offsets[offsets.size() - 1]) + slack_all)
	var near_side: bool = _lane <= offsets[1]
	var low := CrowdLanes.lane_centre(_corridor, offsets[0] if near_side else offsets[2])
	var high := CrowdLanes.lane_centre(_corridor, offsets[1] if near_side else offsets[3])
	# Half a tile of slack at each end: a lane centre is the middle of a tile, and the footway
	# reaches to that tile's edge.
	var slack := float(Tuning.TILE_SIZE) * 0.5
	return Vector2(low - slack, high + slack)

## How fast this walker is going right now as a fraction of its own pace: hurrying across in front
## of her, waiting for her to pass, or simply walking. See `step_aside()`.
##
## A factor rather than a write to `_speed`, so nothing has to remember what the speed used to be
## — and so a walker that is being asked to yield every frame while she approaches does not ratchet
## itself to a standstill it never recovers from.
func _yield_factor() -> float:
	if _yield_left <= 0.0:
		return 1.0
	return YIELD_HURRY if _yield_hurry else 0.0

## How much faster somebody crossing in front of her walks to get out of the way. Enough to clear
## her line inside the notice distance and not so much that a pavement breaks into a jog.
const YIELD_HURRY := 1.7

## Drops any sidestep. A detour is a distance across *this* corridor, so it means nothing once the
## agent has changed corridor, changed lane, or swapped its axes at a junction.
func _forget_the_detour() -> void:
	_detour = 0.0
	_detour_left = 0.0
	_yield_left = 0.0

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
##
## **A car picks its axis by weight, and a walker still splits it evenly.** *(Playtest 13,
## finding 7: "the main road doesn't really have much traffic I can freely walk over it".)* The
## even split was applied to both and it silently capped the main road: the axis was decided
## *before* the corridor, so `busyness` could only ever redistribute cars **within** an axis, and
## no weight — 5.0, 50, any number — could put more than half the traffic on one north-south
## street. Measured at act I density the spine held 11.2 cars of forty with a weight five times
## its neighbours'.
##
## So for cars the two decisions become one: pick among the corridors of **both** axes in
## proportion to how busy each is, which is what the weight was always supposed to mean. Walkers
## keep the even split deliberately — a pavement has no hierarchy for them to follow (a precinct
## is a *place*, not an axis), and the alternating roll from `Crowd._populate` is what stops a
## morning's crowd landing lopsided by chance.
func _choose_lane(roll: float) -> void:
	_vertical = roll < 0.5 if kind != Kind.CAR else _pick_axis_by_weight()
	# Only the corridors the field actually reaches. Picking from the whole city and then
	# discarding what is out of view is the same crowd spread over ten thousand tiles, which
	# is the thing M27 stops doing.
	_corridor = CrowdLanes.pick_corridor_in_range(_rng, _map, _vertical,
			field.corridor_range(_vertical), kind == Kind.CAR)
	if kind == Kind.CAR:
		_lane = CrowdLanes.ROAD_OFFSETS[_rng.randi_range(0, 1)]
		_direction = CrowdLanes.road_direction(_vertical, _lane)
		_speed = _rng.randf_range(Tuning.CAR_SPEED.x, Tuning.CAR_SPEED.y)
	else:
		var offsets := CrowdLanes.walkable_offsets(_map, _vertical, _corridor,
				floori(_along() / float(Tuning.TILE_SIZE)))
		_lane = offsets[_rng.randi_range(0, offsets.size() - 1)]
		_direction = 1.0 if _rng.randf() < 0.5 else -1.0
		_speed = _rng.randf_range(Tuning.PEDESTRIAN_SPEED.x, Tuning.PEDESTRIAN_SPEED.y)
	_cruise = _speed
	_lane_centre = CrowdLanes.lane_centre(_corridor, _lane)
	_junction = -1
	_forget_the_detour()

## Which way a car drives, weighted by the traffic each axis is carrying **inside the field**.
##
## Restricted to the corridors in view for the same reason `pick_corridor_in_range` is: the crowd
## is a population of the box around her, so the question is which streets *she* can see, and a
## spine two miles north is not competing for these cars. A field with no drivable weight in it at
## all — every corridor in view a precinct — falls back to an even split rather than dividing by
## nothing, exactly as the corridor pick does; the caller re-rolls anyway.
func _pick_axis_by_weight() -> bool:
	var vertical_weight := _axis_weight(true)
	var horizontal_weight := _axis_weight(false)
	var total := vertical_weight + horizontal_weight
	if total <= 0.0:
		return _rng.randf() < 0.5
	return _rng.randf() * total < vertical_weight

func _axis_weight(vertical: bool) -> float:
	var span := field.corridor_range(vertical)
	var total := 0.0
	for index in range(span.x, span.y + 1):
		total += CrowdLanes.busyness_for(_map, vertical, index, true)
	return total

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
## Since M41 it is also where a car waits its turn at a junction. The three wants compose by
## taking the lowest, exactly as the queue and the zebra already did — a car held at a box and a
## car behind another car are the same behaviour asked for by two different things, and giving
## the junction its own brake would be a second answer to a question that already has one.
func _give_way(delta: float) -> void:
	var wanted := _cruise
	if junction_hold < INF:
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * junction_hold))
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
## **A main road does not give way**, and that is the whole difference between its crossings and
## an ordinary street's. *(M41.)* The paint is identical and what honours it is not: on an
## ordinary street the drivers do, which makes crossing a matter of catching somebody's eye; on
## the spine the light does, which makes it a matter of waiting for one. Take this exemption away
## and a signal is decoration on top of a courtesy that was already enough.
func _crossing_ahead_somebody_is_waiting_at() -> float:
	if pedestrian_ahead == Vector2.INF:
		return INF
	if _map.street_kind_at(_vertical, _map.world_to_tile(global_position)) \
			== GameEnums.StreetKind.MAIN:
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
	# The first tile of the run of paint currently being walked, or -1 between runs. **A zebra is
	# not one tile**, and the car has to stop short of the whole of it rather than short of the
	# tile the person happens to be standing on — otherwise it parks on the near half of the same
	# crossing and the paint stops meaning anything. Two tiles deep on an ordinary street, and
	# *six* where a road crosses a pedestrianised one, which is where this first showed up.
	var run_start := -1
	for step in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var tile := here + step_tile * step
		var along_index: int = tile.y if _vertical else tile.x
		if _map.tile_at(tile) != GameEnums.TileType.CROSSING:
			run_start = -1
			continue
		if run_start < 0:
			run_start = along_index
		# Distance along the street, not straight-line: somebody waiting at the far kerb of a
		# six-tile corridor is beside the crossing, not two tiles from it.
		var crossing_along := float(along_index * Tuning.TILE_SIZE)
		if absf(waiting_along - crossing_along) > Tuning.CAR_ZEBRA_WAIT_RADIUS:
			continue
		# The near edge of the run, which is its lowest coordinate going one way and its highest
		# going the other — the scan always starts at the end nearest the car.
		var edge_tile := run_start + (0 if _direction > 0.0 else 1)
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
	_forget_the_detour()
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
	if not _map.in_bounds(tile):
		return false
	# And a precinct is a wall to a car and a street to everybody else. The tile map cannot say
	# so — it is paving either way — so the street kind has to, or a car reaching the three
	# blocks of a precinct drives onto them instead of turning off.
	if kind == Kind.CAR and not _map.is_driveable_at(vertical, tile):
		return true
	return not _map.is_street(tile)

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

	var turning := _pick_an_arm(crossing, 1.0 if _rng.randf() < 0.5 else -1.0)
	if turning == 0.0:
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
	_forget_the_detour()
	_junction = kept
	_claim_the_road_here()

## Which way to turn out of `crossing`, trying `first` before the other one, or `0.0` for neither.
##
## Two questions and they are not the same question. **Can it go that way at all** is the tile map
## — shut for the day, or never a street — and an arm that fails it is not an option. **Is there
## room** is the other cars, and an arm that fails *that* is a bad option rather than no option.
##
## The second one is M38, and it is the fix for *"when a car turns into an occupied lane the other
## car just disappears"*. A turn is a **placement**: it takes the coordinate the car had along its
## old corridor and makes it the one it has across the new one, so the car simply materialises
## somewhere in another queue. The M27 rule then resolves the overlap the only way it can, by moving
## a body — front-to-back, so the shortfall cascades down the queue behind it, and a car is jumped
## backwards by up to six of its own lengths in a single frame. Off screen, at the entry band, that
## is exactly what it is for; at a junction the player is looking at, it is a car vanishing.
##
## Preferring rather than requiring, because a car that refuses to turn drives into the barrier it
## was avoiding. When both arms are full it takes the first one anyway and the resolve does what it
## always did — which leaves the old behaviour as the rare case instead of the usual one.
func _pick_an_arm(crossing: int, first: float) -> float:
	# A precinct is not an arm a car has. Neither of the two questions below would catch it: it is
	# paved end to end, so the tile map says it is a street, and there is never a car in it to
	# leave no room. A car with nowhere else to go turns round instead, which is what a driver
	# meeting a bollarded street actually does.
	if kind == Kind.CAR and not _map.is_driveable(not _vertical, crossing,
			floori(_cross() / float(Tuning.TILE_SIZE))):
		return 0.0
	var open: Array[float] = []
	for turning in [first, -first]:
		if not _blocked_ahead(not _vertical, turning, LOOKAHEAD):
			open.append(turning)
	if open.is_empty():
		return 0.0
	for turning in open:
		if _has_room_to_turn(crossing, turning):
			return turning
	return open[0]

## Whether the lane this car would land in has a car's length of road to spare where it would land.
##
## Walkers are exempt: two people on a pavement are not two cars in a lane, `space_out_the_traffic`
## has never looked at them, and there is nothing for this to prevent.
func _has_room_to_turn(crossing: int, turning: float) -> bool:
	if kind != Kind.CAR or not traffic:
		return true
	var vertical := not _vertical
	var lane := CrowdLanes.road_lane(vertical, turning)
	# After the turn the axes swap: what is currently the coordinate *across* this corridor becomes
	# the one *along* the new one, which is where in that queue the car would appear.
	var landing := _cross() * turning
	return traffic.room_at(make_lane_key(vertical, crossing, lane, turning),
			landing, Tuning.CAR_GAP_MIN)

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
##
## And since M38 it also has to be a piece of road nobody is on, which is the case M27 wrote the
## positional resolve for — *"a car recycled into a lane lands at a point it cannot see"*. It can
## see it now, so the resolve goes back to being a backstop rather than the way a car enters a
## street. It is only a preference: after six rolls it takes what it has, because an entry band with
## nothing free in it must still put the car somewhere.
func _recycle() -> void:
	for _attempt in 6:
		_choose_lane(_rng.randf())
		var bounds := field.along_bounds(_vertical)
		var back := _rng.randf() * ENTRY_SPREAD
		_set_along(bounds.x - back if _direction > 0.0 else bounds.y + back)
		_set_cross(_lane_centre)
		if _entry_band_fits() and _stands_on_a_street() and _has_room_here():
			break
	_join_the_back_of_the_queue()
	_settle_junction()
	_claim_the_road_here()
	gap_ahead = INF
	junction_hold = INF

## Drops the car in behind whatever is already in its lane, when the rolls above could not find a
## gap. Nothing at all if it landed somewhere free, which is almost always.
##
## **A retry is not a guarantee, and this is the difference.** Six rolls into a busy entry band all
## miss often enough to happen about once a minute, and what follows is the whole of the bug this
## chased: the car materialises inside a queue, and the separation pass then shunts everybody behind
## it back by the overlap *plus* everything moved in front of them — 180px, measured, with the rolls
## in place. Behind the last car is the one place in a lane that is free by construction.
##
## It may put the car further back than the entry band is deep, which is exactly right: further back
## is further off-screen, and the alternative is a car appearing inside another one.
func _join_the_back_of_the_queue() -> void:
	if kind != Kind.CAR or not traffic or _has_room_here():
		return
	var last := traffic.rearmost(lane_key())
	if last == INF:
		return
	_set_along((last - Tuning.CAR_GAP_MIN) * _direction)

## Tells the index this car is here, so that another one recycling or turning later in the same
## frame does not choose the same piece of road. See `TrafficIndex.claim()`.
func _claim_the_road_here() -> void:
	if kind != Kind.CAR or not traffic:
		return
	traffic.claim(lane_key(), queue_position())

## Whether this car is standing in a piece of its own lane that no other car is in.
func _has_room_here() -> bool:
	if kind != Kind.CAR or not traffic:
		return true
	return traffic.room_at(lane_key(), queue_position(), Tuning.CAR_GAP_MIN)

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
