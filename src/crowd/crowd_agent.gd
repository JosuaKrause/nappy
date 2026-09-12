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

## The walker's five authored views, keyed by name rather than by sector — `WALKER_VIEW_BY_SECTOR`
## below does the sector-to-view lookup, so drawing never repeats an eight-way if-chain of its
## own to get here. All five share one 18x38 canvas and one (9, 38) feet anchor (see
## `docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`); body is tinted per walker, trim is
## drawn untinted above it — see `_draw_body()`.
const WALKER_BODY_BY_VIEW := {
	"front": preload("res://assets/crowd/walker_front_body.svg"),
	"back": preload("res://assets/crowd/walker_back_body.svg"),
	"side": preload("res://assets/crowd/walker_side_body.svg"),
	"front_diagonal": preload("res://assets/crowd/walker_front_diagonal_body.svg"),
	"back_diagonal": preload("res://assets/crowd/walker_back_diagonal_body.svg"),
}
const WALKER_TRIM_BY_VIEW := {
	"front": preload("res://assets/crowd/walker_front_trim.svg"),
	"back": preload("res://assets/crowd/walker_back_trim.svg"),
	"side": preload("res://assets/crowd/walker_side_trim.svg"),
	"front_diagonal": preload("res://assets/crowd/walker_front_diagonal_trim.svg"),
	"back_diagonal": preload("res://assets/crowd/walker_back_diagonal_trim.svg"),
}
## Which authored view each of `EightDirection`'s eight sectors draws — N back, NE/NW
## back_diagonal, E/W side, SE/SW front_diagonal, S front, the same N/NE/E/SE/S coverage the
## mother/pram family uses. Sectors 3 (SW), 4 (W) and 5 (NW) mirror their partner here rather
## than being separately authored — see `EightDirection.is_mirrored()`.
const WALKER_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
## Which authored view each of `EightDirection`'s eight sectors draws — identical to the walker's
## own table above, since the crowd car shares the same five projections and the same west-mirror
## convention (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car` rows).
const CAR_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]
## The car's five authored views, keyed by name the way the walker's own two tables are —
## `CAR_VIEW_BY_SECTOR` above does the sector lookup. Body is tinted per car, trim is drawn
## untinted above it (`_draw_body()`); front/back are 30x46, side is 52x30, the diagonals are
## 52x42. `car_end_{body,trim}.svg`, the old two-view family's foreshortened top-down picture, is
## no longer read by either table — see `docs/GRAPHICS.md` for where it stands now.
const CAR_BODY_BY_VIEW := {
	"front": preload("res://assets/crowd/car_front_body.svg"),
	"back": preload("res://assets/crowd/car_back_body.svg"),
	"side": preload("res://assets/crowd/car_side_body.svg"),
	"front_diagonal": preload("res://assets/crowd/car_front_diagonal_body.svg"),
	"back_diagonal": preload("res://assets/crowd/car_back_diagonal_body.svg"),
}
const CAR_TRIM_BY_VIEW := {
	"front": preload("res://assets/crowd/car_front_trim.svg"),
	"back": preload("res://assets/crowd/car_back_trim.svg"),
	"side": preload("res://assets/crowd/car_side_trim.svg"),
	"front_diagonal": preload("res://assets/crowd/car_front_diagonal_trim.svg"),
	"back_diagonal": preload("res://assets/crowd/car_back_diagonal_trim.svg"),
}

## How fast an agent closes on its lane centre. Slow enough that a corner reads as a turn.
const STEER_SPEED := 90.0
## How far ahead an agent looks for a street it cannot travel, and how far down a street it
## checks before turning into one — a corridor's width plus a tile, so a probe fired from
## *anywhere* inside a junction clears it and lands on the street beyond.
##
## **A probe that only just clears the obstruction turns at the far edge of the junction**, and a
## turn takes the coordinate the agent had *along* its old corridor and makes it the one it has
## *across* the new one — so turning at the far edge drops a car onto the pavement band and it
## spends the next three tiles steering back to its lane. Rare with a handful of closures a day;
## constant once every calm zone has four dead-end arms on it. Seeing it a street early and turning
## in the middle of the junction is what `_can_turn_here` is for.
const LOOKAHEAD := (Tuning.STREET_WIDTH + 1) * Tuning.TILE_SIZE
## The same distance in tiles, for the scans that walk rather than probe. See `_way_is_blocked`.
const LOOKAHEAD_TILES := Tuning.STREET_WIDTH + 1
## Where a car's own caret sits, and how big it is. Matched to `EventInstance`'s so the two carets
## are the same cue rather than two similar ones, but lower, because a car is 26px of sprite
## against a standing figure's 46.
const MARK_HEIGHT := 30.0
const MARK_WIDTH := 15.0

var kind := Kind.WALKER
var colour := Color.WHITE

## This agent's own ground shape, set once in `setup()`: a point for a walker, a capsule along the
## travel axis for a car (`_car_shadow_shape()`). Read by `_draw_body()` for the shadow; there is
## no body for either — see `_car_shadow_shape()`'s own docstring for why a car gets none, and
## `CAR_STRIKE_HALF_LENGTH`/`CAR_STRIKE_HALF_WIDTH` in `tuning.gd` for the lethal rectangle this
## shape is not: *"lethal != noise"* (the player, 2026-09-10) — this datum is the noise (and the
## shadow) a car makes, `will_be_lethal()`'s strike box is what it hits, and this commit leaves
## the strike box exactly where it stands.
var shape: GroundShape

## The box this agent lives in, held by reference and moved by `Crowd`. Leaving the box is what
## recycles an agent — not leaving the map. See `CrowdField`.
var field: CrowdField

## Where the other cars are, by lane, so a turn can look before it commits. Held by reference and
## refilled once a frame by `Crowd`; null for an agent built by hand in a test, which then turns
## the way it always did. See `TrafficIndex`.
var traffic: TrafficIndex

## Today's region-door segment keys (`StreetNetwork.Segment.key()` -> `true`), held by reference
## and rebuilt once a day by `Crowd.start_day()` from `City.region_plan().doors`. Empty for an
## agent built by hand in a test or for a rig with no city behind it, which then treats every held
## segment as wall the way `_cannot_go_on` already would. The one carve-out `CityMap.is_held_at`
## does not make on its own: a wall segment and a hard seal's segment are shut outright, but a
## door is a crossing the day's structure means to keep open — a car brakes and queues for the
## gate (`Crowd._stop_for_gates()`) rather than being turned away at the last junction, and a
## walker passes the hut the way she does.
var door_segments := {}

## The segments bordering the home block, the second carve-out `is_held_at` cannot make on its
## own — rebuilt beside `door_segments` from `StreetNetwork.around_blocks(Rect2i(map.home_block,
## Vector2i.ONE))`, the exact set `EventManager.start_day` holds them from for the opposite reason:
## those segments are held only so no catalogue row lands on the home block's own street, never
## because a body stands across it. The home is a notch with one exit, she walks out onto one of
## these every morning, and `held_segments` has no way to say *why* a segment is held — this list
## is the crowd's own answer, the same shape `door_segments` already is.
var home_segments := {}

## Somebody standing in front of this car, or `Vector2.INF` for nobody. Written once per
## physics frame by `Crowd` for the cars near the player and read here: an agent has no
## business knowing who the player is, but it does have to decide whether to stop.
var pedestrian_ahead := Vector2.INF

## Clear road to the back of the car in front, in px, or INF when there is nobody ahead.
## Written once per physics frame by `Crowd`, for the same reason `pedestrian_ahead` is: the
## neighbour search is one pass over the whole crowd, not one per agent.
var gap_ahead := INF

## How fast the car that gap is measured to is going, or 0.0 when there is nobody ahead. Written
## beside `gap_ahead` and by the same pass, because the two are only ever asked together: a gap is
## a distance and *do not block the box* is a question about whether that distance is opening.
var leader_speed := 0.0

## Distance to the stop line of a junction this car has to give way at, or `INF` when it has
## right of way. Written once per physics frame by `Crowd.give_way_at_junctions()`, because
## whose turn it is at a box is a question about the pair of them and not about either one.
var junction_hold := INF

## Distance to the stop line of a checkpoint gate this car has to give way at, or `INF` when there
## is none ahead or it is raised. Written once per physics frame by `Crowd._stop_for_gates()`,
## the same shape `junction_hold` already is — see `_give_way()` for why the two, and the zebra's
## own stop line, all compose by taking the lowest speed rather than each owning a brake.
var gate_hold := INF

## True while the player is touching this agent. Owned by `Crowd`, and the reason it exists is
## that a contact is not instantaneous: she walks faster than a pedestrian does, so a person
## bumped from behind stays inside the contact radius for the better part of a second. Without
## it the contact re-fires every frame and one person costs what a crowd should.
var touching := false

## This frame's player position, or `Vector2.INF` before the first frame — part of
## `ExcitementHalo`'s duck type, told once a frame through `set_player_at()`. `Crowd` only ever
## hands an agent the player's position when the agent is a car near a road (`pedestrian_ahead`),
## so this is the one channel that reaches every agent in the crowd regardless, which is what
## `expected_impact_at()` and `will_be_lethal()` need to answer for a walker as well as a car.
var player_at := Vector2.INF

func set_player_at(at: Vector2) -> void:
	player_at = at

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

## The turn this car has committed to, or null. Cars only; a walker still swaps its axis where it
## stands, because a person turning a corner *is* a body that can change direction in a stride and
## has no lane, no queue and no length to swing round. See `CarTurn`.
##
## Committed to before the arc begins rather than when it does: the whole of it — the ground it
## sweeps and the room in the lane it lands in — is checked once, up front, and nothing revisits the
## decision afterwards. A turn that cannot be made is never started.
var _turn: CarTurn = null
## How much straight lane is left before the arc begins, in px. The car drives its own lane for
## this much and then curves, so the approach is ordinary travel with every ordinary rule on it.
var _turn_run_up := 0.0
## The frame and flip currently drawn, so a redraw only happens when they change.
var _picture := Vector2i(-1, -1)
## Whether this car's own caret was up last frame, so it gets one redraw to come off with.
var _was_marked := false

## Built lazily on this agent's own first non-zero glow, and freed once it has faded all the way
## back out — see `set_halo_strength()`. A halo built for every agent in a crowd of a couple of
## hundred, whether or not it is ever picked, would be cost paid for nothing — only the handful
## `ExcitementHalo.MAX_SOURCES` ever picks needs one at all.
var _halo: EntityHalo

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

## `[when, points]` entries landed on her from this agent, `when` stamped from `_clock` in
## seconds, for whatever is still inside `ExcitementHalo.WINDOW` — a true sliding sum rather than
## a decayed average. Lazily grown: an agent that has never landed anything keeps this empty.
## Duck-typed with `EventInstance`'s own copy — see `ExcitementHalo`'s class doc for the whole
## shape.
var _landed_history: Array = []

## This agent's own simulation clock, in seconds, advanced by `delta` in `_process()`. `landed()`
## is measured against this rather than `Time.get_ticks_msec()` so that a paused game does not
## empty the halo, and so a rig can measure the window on simulated time by advancing this
## directly instead of waiting on the wall clock.
var _clock := 0.0

## A sidestep held for a moment after being walked into: how far across its own corridor, and how
## long is left on it. See `step_aside()`.
## The way ahead, and the state it was worked out for. See `_look_ahead`.
var _scan_at := Vector2i(-9999, -9999)
var _scan_vertical := false
var _scan_direction := 0.0
## Tiles to the first thing this agent cannot pass, or `LOOKAHEAD_TILES + 1` for a clear road.
var _blocked_in := LOOKAHEAD_TILES + 1

var _detour := 0.0
var _detour_left := 0.0
## And the same for somebody *crossing* her path rather than sharing it, who has no sidestep to
## make: whether it is hurrying across or waiting, and how long is left on it.
var _yield_hurry := false
var _yield_left := 0.0

func setup(agent_kind: Kind, map: CityMap, crowd_field: CrowdField, seed_value: int,
		axis_roll: float) -> void:
	kind = agent_kind
	shape = GroundShape.point(7.0) if kind == Kind.WALKER else _car_shadow_shape()
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	# Start somewhere along the field rather than at its edge, or the whole crowd arrives from
	# one side in a wave on the first morning. Re-rolled if it lands somewhere it could not have
	# walked to: behind a barrier, which reads as the barrier being fake, or in the middle of a
	# four-block calm zone, where the corridor it belongs to has been park since generation.
	#
	# **And if the whole street is wrong, it picks another street.** Re-rolling only the position
	# along a corridor cannot help a car that was given a corridor with nowhere drivable in view — a
	# precinct is three blocks of an otherwise ordinary street, so the corridor keeps its car weight
	# and the *stretch in the field* may be entirely pedestrianised. The position re-rolls below then
	# land among the bollards every time and the last one places it there anyway: a car standing in a
	# precinct, which `tests/test_crowd.gd` asks about by name. **A retry is not a guarantee** — when
	# re-rolling the small decision keeps failing, re-take the big one.
	for _street in 4:
		_choose_lane(axis_roll)
		var bounds := field.along_bounds(_vertical)
		var placed := false
		# **A held segment can swallow most of a corridor's visible stretch** — a region wall or a
		# hard seal is kept off `held_segments` by the tile, not by a fraction of it, so a field
		# centred close to one narrows the open ground a random draw can land on far more than a
		# precinct's own bollards ever did. More draws is the same "retry is not a guarantee" trade
		# the docstring above already makes, just carried far enough that the small decision keeps
		# up with how much narrower "the small decision" can now be.
		for _attempt in 24:
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
## the street while it steers back to a pavement. Rare enough that only a reshuffled crowd shows it.
func _settle_junction() -> void:
	_junction = CrowdLanes.corridor_at(_along())

## Whether this agent is standing somewhere it could have got to on its own: an open street, or
## — for a car on the spine, leaving by the tunnel or the bridge — the one place an entry band may
## legitimately begin outside the map. Everywhere else outside the map is refused, the same
## exception `_cannot_go_on` makes: a walker placed out there would find every direction blocked
## and go nowhere, which is worse than the retry `_recycle` already has to make anyway.
func _stands_on_a_street() -> bool:
	var tile := _map.world_to_tile(position)
	if _map.is_closed(tile):
		return false
	if _segment_is_shut(tile):
		return false
	if kind == Kind.WALKER and _map.is_soft_sealed(tile):
		return false
	if not _map.in_bounds(tile):
		return kind == Kind.CAR and _vertical and _corridor == _map.main_road \
				and (tile.y < 0 or tile.y >= _map.size.y)
	# A precinct is paved end to end, so every tile of it says "street" and a car placed there
	# would look perfectly settled right up to the moment it drove off down the paving. Asked
	# here rather than at lane-choosing time because it is a question about a *place*, and the
	# place is not decided until the along position is rolled.
	if kind == Kind.CAR and not _map.is_driveable_at(_vertical, tile):
		return false
	# And a walker is never placed in a carriageway. It matters because a precinct's lanes run the
	# whole width of the corridor, and a lane is chosen before the along position that decides
	# whether this stretch is a precinct at all — so the re-roll is what keeps the two in step
	# rather than an ordering assumption that would be wrong once in ten.
	if kind == Kind.WALKER and _map.tile_at(tile) == GameEnums.TileType.ROAD:
		return false
	return _map.is_street(tile)

## Whether a tile's own street segment is shut to this agent the way a hard blocker is: held for
## today (`CityMap.is_held_at` — a hard seal's segment, a region wall, a closure, or the streets
## around the home block) and neither of the two carve-outs `held_segments` cannot make on its
## own. A region door is a crossing anybody may still enter — a car brakes and queues for the gate
## rather than turning away, and a walker passes the hut. The home block's own bordering streets
## are held only so no catalogue row lands there, never because a body stands across one — she
## walks out onto one of them every morning, and the home is a notch with one exit, so sealing it
## would seal her in. Both lists are empty outside a real day (a hand-built test agent, a rig with
## no city, or before the wall itself stands), which is a harmless no-op: nothing is held then
## either.
func _segment_is_shut(tile: Vector2i) -> bool:
	if not _map.is_held_at(tile):
		return false
	var segment := StreetNetwork.segment_containing(tile)
	if segment == null:
		return true
	var key := segment.key()
	return not door_segments.has(key) and not home_segments.has(key)

func _process(delta: float) -> void:
	_clock += delta
	var before_position := position
	_jolt = maxf(0.0, _jolt - delta)
	if _detour_left > 0.0:
		_detour_left = maxf(0.0, _detour_left - delta)
		if _detour_left <= 0.0:
			_detour = 0.0
	_yield_left = maxf(0.0, _yield_left - delta)
	if kind == Kind.CAR:
		_give_way(delta)
		# A car in a turn is following a path that was checked before it started, so none of the
		# lane steering, lookahead or diverting below applies to it: the only thing left to decide
		# is how far along the curve it has come. It is not recycled mid-turn either — a recycle is
		# a teleport, and half a turn is the one place in a car's life where that would be seen.
		if _turn:
			_follow_the_turn(delta)
			_claim_the_turn()
			_redraw_if_the_picture_changed()
			return
	_set_along(_along() + _speed * _yield_factor() * _direction * delta)
	_set_cross(move_toward(_cross(), _lane_centre + _detour, STEER_SPEED * delta))
	if kind == Kind.WALKER:
		_consider_turning()
	_look_ahead()
	if _blocked_in <= LOOKAHEAD_TILES:
		_divert()
	var recycled := false
	if _has_left_the_field():
		_recycle()
		recycled = true
	_redraw_if_the_picture_changed()

## Asks for a redraw when what this agent is showing has actually changed.
##
## Moving a Node2D does not invalidate its draw list — the transform is applied when it is
## replayed — so an agent only redraws when its picture actually changes. At this population that
## is the difference between five hundred redraws a frame and a handful.
func _redraw_if_the_picture_changed() -> void:
	var picture := Vector2i(_frame(), 1 if _flipped() else 0)
	if picture != _picture:
		_picture = picture
		queue_redraw()
	# A marked car draws a caret that can breathe with its own horn, and a projected approach
	# can change its strength frame to frame with nothing else about the picture moving. The
	# one frame after the mark comes down is what takes the caret off again.
	elif kind == Kind.CAR and (_caret_strength() > 0 or _was_marked):
		_was_marked = _caret_strength() > 0
		queue_redraw()

## Excitement per second this agent contributes at a point. Same falloff as an event, so
## the crowd and the events are the same kind of quantity to the baby — and the same kernel too:
## `GroundShape.eccentric_distance()`, eccentric while moving and the plain distance a disc always
## used the instant it stops, off `velocity()` rather than a shape of its own — a crowd body is
## always a point in field terms (see `GroundShape`'s class doc on why nobody builds the general
## capsule-and-ellipse sum), so there is no body to set aside the way a stationary event's is.
##
## The jolt is added on top of the body's ordinary noise rather than replacing it, and it
## fades linearly over its own duration — so a bump is a spike with a tail rather than a step
## that ends abruptly, and two people bumped in the same second cost twice. **The same distance
## prices both** — the horn or the bump is the same source being louder, not a second one.
func contribution_at(world_position: Vector2) -> float:
	var distance := GroundShape.eccentric_distance(global_position, velocity(), world_position)
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

## The furthest this agent's own field can currently reach — its ordinary outer radius, or the
## jolt's own if a jolt is running and reaches further, the way a car's `CAR_HORN_OUTER_RADIUS`
## (132px) reaches past its ordinary `CAR_OUTER_RADIUS` (104px), then grown forward by
## `Tuning.field_scale()` at the fastest this agent's own kind ever moves. What `expected_impact_at()`
## and `will_be_lethal()` both compare a projected approach against, so a source mid-jolt or
## mid-approach is not skipped early on a reach that no longer describes it — a car's own forward
## reach at `CAR_SPEED.y` (the top of its own speed range, not merely its current one) is the widest
## this agent's field can ever be, so the early-out has to be stated over that rather than over
## whatever it happens to be doing this frame.
##
## **Not `EventDef.field_reach()`'s business.** That one adds a segment's `half_length` back in for
## a stationary body; a crowd agent has no body in field terms — see `contribution_at()`'s own doc.
func _current_reach() -> float:
	var reach := Tuning.CAR_OUTER_RADIUS if kind == Kind.CAR else Tuning.PEDESTRIAN_OUTER_RADIUS
	if _jolt > 0.0:
		reach = maxf(reach, _jolt_outer)
	var top_speed := Tuning.CAR_SPEED.y if kind == Kind.CAR else Tuning.PEDESTRIAN_SPEED.y
	return reach * Tuning.field_scale(Tuning.field_eccentricity(top_speed))

## Points this agent is projected to land on her over `Tuning.EXPECTED_IMPACT_HORIZON`, her
## position held fixed and only this agent moving — `EventInstance.expected_impact_at()`'s own
## quantity, read here off `velocity()` instead of `travel_velocity()`. See that method for the
## reasoning: a stationary body's own field does not change under the projection and the
## subtraction cancels it to zero, and the reach test below skips anything the walk cannot close
## inside the horizon without sampling it.
func expected_impact_at(player_position: Vector2) -> float:
	var vel := velocity()
	var reach := vel.length() * Tuning.EXPECTED_IMPACT_HORIZON + _current_reach()
	if global_position.distance_to(player_position) > reach:
		return 0.0
	if vel.is_zero_approx():
		return 0.0
	var current_rate := contribution_at(player_position)
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	for i in steps:
		landed += contribution_at(player_position - vel * (float(i + 1) * dt)) * dt
	return landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON

## Whether this car's own strike box reaches her at some point before
## `Tuning.EXPECTED_IMPACT_HORIZON`, on its current course, her position held fixed — a car's
## equivalent of `EventInstance.will_be_lethal()`, over the same rectangle `Crowd._strike()` tests
## for the actual collision. Never true for a walker: nothing about a pedestrian ends the day, and
## never true for a car already too slow to strike at all (`Crowd._strike()`'s own guard).
func will_be_lethal(player_position: Vector2) -> bool:
	if kind != Kind.CAR or _speed < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var vel := velocity()
	var forward := heading()
	var side := Vector2(-forward.y, forward.x)
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	for i in steps + 1:
		var offset := player_position - (global_position + vel * (float(i) * dt))
		if absf(offset.dot(forward)) <= Tuning.CAR_STRIKE_HALF_LENGTH \
				and absf(offset.dot(side)) <= Tuning.CAR_STRIKE_HALF_WIDTH:
			return true
	return false

## Duck-typed with `EventInstance`'s own copy — see `ExcitementHalo`'s class doc. `points` is not
## recomputed here: `Baby._update_excitement()` traces it back from the meter's own sum as this
## agent's exact share of what landed this frame, so an ordinary walker's colour and a honking
## car's colour both come from the same place a bump or a horn ever reached the meter at all.
## Stamped with `_clock`, this agent's own simulation clock, rather than the wall clock, so a
## paused game does not empty the halo and a rig can measure the window on simulated time.
func accumulate_landed(points: float) -> void:
	_prune_landed_history()
	if points > 0.0:
		_landed_history.append([_clock, points])

## The sum of every entry still inside `ExcitementHalo.WINDOW`. Pruned here too, not only on
## write, so an agent nobody has visited in a while reports honestly the moment it is asked.
func landed() -> float:
	_prune_landed_history()
	var total := 0.0
	for entry in _landed_history:
		total += entry[1]
	return total

func _prune_landed_history() -> void:
	var cutoff := _clock - ExcitementHalo.WINDOW
	while not _landed_history.is_empty() and _landed_history[0][0] < cutoff:
		_landed_history.pop_front()

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

## The jolt's own inner and outer radii, valid only while `is_startled()` — read by `DebugLayers`
## so its fields layer can draw the extra field a running jolt adds on top of this agent's ordinary
## one, the same pair `contribution_at()` sums in.
func jolt_radii() -> Vector2:
	return Vector2(_jolt_inner, _jolt_outer)

## Forwards to `_halo`'s own `set_glow()` — see `EntityHalo`'s class doc for the duck-typed shape
## `EventInstance` shares. Called by `ExcitementHalo` once a frame for every agent in the crowd —
## nonzero for the handful `select_sources()` picked, zero for everything else. Builds `_halo`
## lazily on first use, rather than paying for an `EntityHalo` on every agent the crowd ever holds,
## and frees it once `EntityHalo.is_faded_out()` says the fade is actually over — not the frame the
## target first reaches zero, or a burst that just left `MAX_SOURCES` would be cut off mid-fade
## instead of draining over `EntityHalo.FADE_OUT_SECONDS`.
func set_halo_strength(strength: float, colour: Color) -> void:
	if strength <= 0.0:
		if _halo:
			_halo.set_glow(0.0, colour)
			if _halo.is_faded_out():
				_halo.queue_free()
				_halo = null
		return
	if not _halo:
		_halo = EntityHalo.new(_draw_body, _zero_bob)
		add_child(_halo)
	_halo.set_glow(strength, colour)

## The crowd never bobs — only an `EventInstance` rides a stride's worth of lift — so this is the
## flat `bob()` `EntityHalo` asks every owner for.
func _zero_bob() -> float:
	return 0.0

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
##
## **Read off the heading rather than off the lane while a car is in a turn**, because mid-turn
## there is no lane to read and the question is about the path: a car that has swung past the
## diagonal is across the traffic it used to be queueing with. It ties to the axis it came in on,
## which is the half of the turn it has not yet finished.
func travelling_vertically() -> bool:
	if _turn and _turn_run_up <= 0.0:
		var forward := heading()
		return absf(forward.y) >= absf(forward.x)
	return _vertical

# -------------------------------------------------------------- junctions ---
# A lane is a queue and a junction is a **box**, and modelling only the queue is not enough. Two
# cars on crossing arms each see a clear lane ahead, both enter, and the positional resolve then
# does the only thing it can — move a body. Measured that way over ninety seconds of the arterial:
# 3,776 overlapping crossing-axis pairs, one in half of all frames, the deepest 39px into a 40px
# footprint — two cars passing through each other's centres in plain sight, with every lane legal on
# every frame, which is why a suite full of "no two cars are inside each other" assertions cannot
# see it. **Look before committing.**

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

## Which way it is pointing, in world space: a unit vector along its actual line of travel,
## **continuous through a turn**.
##
## Cardinal while an agent is following a lane, and the tangent of its own arc while a car is in a
## turn — so it sweeps through the diagonals over the length of the manoeuvre rather than switching
## from one axis to the other between two frames. Everything that asks which way a car is pointing
## goes through this one answer: the lethal strike box and the horn (`Crowd._strike`, `Crowd._horn`),
## right of way at a box, the gate's own along/across projection, the shadow and the picture. A turn
## that changed the axis without changing this would point every one of them at a car that is not
## there.
func heading() -> Vector2:
	if _turn and _turn_run_up <= 0.0:
		return _turn.heading_at(_turn.travelled)
	return Vector2(0.0, _direction) if _vertical else Vector2(_direction, 0.0)

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
##
## **Never past ground it could not have driven onto itself.** This is pure spacing arithmetic with
## no notion of the map underneath it, so unguarded it can shove the rearmost car of a queue back
## across a junction and into whatever borders it on the far side — measured as a car grazing a big
## building's own footprint by one tile. `_cannot_go_on` is the same predicate `_look_ahead` already
## trusts for the *forward* direction; asked here for the backward one, a nudge that would cross
## into blocked ground is simply refused, which leaves that one pair a little closer than
## `Tuning.CAR_GAP_MIN` for a frame rather than parking either of them in a wall.
func nudge_back(distance: float) -> void:
	# **Never a car in a turn.** Sliding one back down its entry lane takes it off the arc it is
	# following, which is the separation pass repairing a manoeuvre — and a manoeuvre that needs
	# repairing is one that should not have been started. The room a turn lands in is checked and
	# held before the car commits; whoever ended up too close to it is nudged instead.
	if _turn:
		return
	var target := _along() - distance * _direction
	var probe := Vector2(_cross(), target) if _vertical else Vector2(target, _cross())
	if _cannot_go_on(_vertical, _map.world_to_tile(probe)):
		return
	_set_along(target)

## Somebody she walked into gets out of her way.
##
## **A positional separation alone is undone on the very next frame** by this agent steering back to
## `_lane_centre`, which is where she is standing — so the bump resolves and re-forms for as long as
## she stays there, with a fresh jolt each time. That is being stuck to somebody, and it loses days.
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
	# steer: it is crossing her path rather than sharing it. Measured, nine to eleven of every
	# twelve contacts on a forty-second walk are with somebody **crossing**, which is why this
	# branch exists at all — a sidestep alone leaves the contact count exactly where it found it.
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
## **A car picks its axis by weight, and a walker still splits it evenly.** An even split applied to
## both silently caps the main road: the axis is decided *before* the corridor, so `busyness` can
## only redistribute cars **within** an axis, and no weight — 5.0, 50, any number — can put more
## than half the traffic on one north-south street. Measured that way at act I density, the spine
## holds 11.2 cars of forty with a weight five times its neighbours'.
##
## So for cars the two decisions become one: pick among the corridors of **both** axes in
## proportion to how busy each is, which is what the weight was always supposed to mean. Walkers
## keep the even split deliberately — a pavement has no hierarchy for them to follow (a precinct
## is a *place*, not an axis), and the alternating roll from `Crowd._populate` is what stops a
## morning's crowd landing lopsided by chance.
func _choose_lane(roll: float) -> void:
	_vertical = roll < 0.5 if kind != Kind.CAR else _pick_axis_by_weight()
	# Only the corridors the field actually reaches. Picking from the whole city and then discarding
	# what is out of view is the same crowd spread over ten thousand tiles, which is the density
	# falling to a third of what the numbers say.
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
	_lane_centre = _lane_centre_here()
	_junction = -1
	# A planned turn is about a junction on a corridor this agent is no longer on.
	_turn = null
	_turn_run_up = 0.0
	_forget_the_detour()

## Where this agent travels in its lane. A car sits on the tile centre; a walker is pushed toward
## the outer edge of its own footway, which is what leaves a gap between the two lanes of a
## pavement worth aiming at. See `CrowdLanes.SIDEWALK_LANE_SPREAD`.
func _lane_centre_here() -> float:
	if kind == Kind.CAR:
		return CrowdLanes.lane_centre(_corridor, _lane)
	return CrowdLanes.walker_lane_centre(_corridor, _lane,
			CrowdLanes.walkable_offsets(_map, _vertical, _corridor,
			floori(_along() / float(Tuning.TILE_SIZE))))

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

## **A zebra is only the safe way over if the traffic honours it** — otherwise it is paint, and the
## choice between crossing here and jaywalking there has one arm missing.
##
## Braking rather than stopping dead, and from `CAR_ZEBRA_SIGHT` out, because the giving way has to
## be *visible* from the kerb: a player deciding whether to step off needs to see the car slowing,
## not discover afterwards that it would have.
##
## It is also where a car decides not to drive through the one in front, waits its turn at a
## junction, or stops for a checkpoint gate. **The four wants compose by taking the lowest**, which
## is the whole trick: a car held at a box, a car held at a gate, and a car behind another car are
## the same behaviour asked for by different things, and giving any one of them its own brake would
## be a second answer to a question that already has one.
func _give_way(delta: float) -> void:
	var wanted := _cruise
	if junction_hold < INF:
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * junction_hold))
	if gate_hold < INF:
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * gate_hold))
	# A turn it has committed to: ease toward the speed the arc is taken at over whatever run-up is
	# left, and hold that speed for the whole curve. When the junction came into sight too late for
	# the easing to finish — which the lookahead makes the ordinary case rather than the unlucky one
	# — the car is still braking as it turns, which is what a driver who took a corner a little fast
	# does. See `Tuning.CAR_TURN_SPEED`.
	if _turn:
		wanted = minf(wanted, sqrt(Tuning.CAR_TURN_SPEED * Tuning.CAR_TURN_SPEED
				+ 2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * _turn_run_up))
	# And the wall itself, for the car that has no manoeuvre that fits. Nothing used to brake for a
	# blockage at all, because reversing on the spot was always available; refusing that has to leave
	# the car somewhere it could have stopped.
	var blockage := _room_to_stop_in()
	if blockage < INF:
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * blockage))
	var to_line := _distance_to_stop_line()
	if to_line < INF:
		# The speed that runs out exactly at the line at the *approach* rate. **Braking toward a
		# point rather than toward zero** is the whole of it: aiming at zero stops the car wherever
		# the curve happens to end, which is most of a block early.
		# The gentle rate is what makes the easing start in sight of the kerb — see
		# `CAR_ZEBRA_APPROACH_BRAKE` for what shaping it with `CAR_BRAKE` does instead.
		wanted = minf(wanted, sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * to_line))
	wanted = minf(wanted, _following_speed())
	var rate := Tuning.CAR_BRAKE if wanted < _speed else Tuning.CAR_ACCELERATE
	_speed = move_toward(_speed, wanted, rate * delta)

## How far this car has to the stop line of a crossing it should give way at, or `INF` when
## there is nothing to give way to — nobody waiting, or **it is already too late to stop**.
##
## The second half is the **commit rule**. A car that arrives at the paint as the player reaches the
## kerb and brakes anyway parks on the zebra; there is only one safe thing it can do that late, and
## it is to clear the crossing. `CAR_ZEBRA_SIGHT`
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
## an ordinary street's. The paint is identical and what honours it is not: on an
## ordinary street the drivers do, which makes crossing a matter of catching somebody's eye; on
## the spine the light does, which makes it a matter of waiting for one. Take this exemption away
## and a signal is decoration on top of a courtesy that was already enough.
func _crossing_ahead_somebody_is_waiting_at() -> float:
	if pedestrian_ahead == Vector2.INF:
		return INF
	# **A car mid-turn is inside the box and has nothing to give way at.** The scan below walks
	# tiles down one axis from the car's own tile, which is a question about a lane the car is not
	# in while it is on an arc — and stopping there would be stopping in the junction, which is the
	# one thing the box rules exist to prevent. The zebras a turn crosses are at the box's own edges
	# and the car gave way at them, or committed, on the way in.
	if _turn and _turn_run_up <= 0.0:
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

	# A turn is the one move that commits without looking, and that is free only while the only
	# unwalkable thing a street can turn into is a barrier, which `_divert` picks up on the next
	# frame. It is not free here: a T-junction on the edge of a calm zone has one arm that is park,
	# and a walker that turns into it is standing on grass before anything notices. So the direction
	# is chosen from the arms that go somewhere, and a junction with no such arm is one this walker
	# carries straight on through.
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
	_lane_centre = _lane_centre_here()
	_direction = turning
	_forget_the_detour()
	# It is now travelling through the corridor it just came down, so that is the junction
	# it is in — otherwise it would roll a second turn before clearing the first.
	_junction = kept

## Whether the street `distance` ahead along an axis is one this agent cannot travel: shut for
## the day, or not a street at all.
##
## The second half is the calm zones. A zone is painted straight over the corridors between its own
## blocks, so a lane that would run the width of the city runs into a park instead — and those tiles
## are perfectly walkable, which is why `is_closed` alone has nothing to say about them. Diverting
## is the same move a barricade produces, with the same good side effect: a street with nobody on it
## is a street that does not go through.
##
## Out of bounds **is** blocked, in `_cannot_go_on()` below — a body that reaches the boundary
## pavement turns rather than walking into the mountain, and only a car on the spine leaves by the
## tunnel or the bridge. The map edge is still what `_has_left_the_field` recycles at. **The thing
## to watch is the pavement she is walking towards near an edge**: a body that turns round at the
## boundary instead of recycling is one fewer arriving from that side, and whether the edge
## streets read thinner for it is a played question rather than a tested one.
func _blocked_ahead(vertical: bool, direction: float, distance: float,
		from := Vector2.INF) -> bool:
	var origin := position if from == Vector2.INF else from
	var offset := Vector2(0.0, direction * distance) if vertical \
			else Vector2(direction * distance, 0.0)
	return _cannot_go_on(vertical, _map.world_to_tile(origin + offset))

## Whether a *tile* is somewhere this agent may be. The predicate under both of the questions
## below, so "the way is shut" means one thing however it is asked.
##
## **Out of bounds is blocked**, with one exception: a car on the spine's own corridor
## (`_map.main_road`) leaving by the tunnel to the north or the bridge to the south, the two edges
## `City._spawn_spine_exits` places them at — `CityEdge` draws the carriageway going on there, and
## nowhere else does the border carry a road. Never a walker: playtest 16, finding 3, *"only cars
## should be able to"*. Stated over which edge and which corridor rather than over "vertical and
## out of bounds", because the spine is the one corridor this is true of, not every vertical one.
func _cannot_go_on(vertical: bool, tile: Vector2i) -> bool:
	if _map.is_closed(tile):
		return true
	# A hard seal and a region wall stand bodies across the whole carriageway, kerb to kerb, the
	# same way a dead end's own wall does — `_segment_is_shut` is the fact `_look_ahead` sees from
	# `LOOKAHEAD_TILES` off, so both walkers and cars turn away at the last junction rather than
	# walking or driving through what they cannot see through. A region door is carved out of the
	# same check: it is a crossing the day means to keep open, not a wall with a picture on it.
	if _segment_is_shut(tile):
		return true
	# A soft seal takes both pavements and leaves the carriageway to the cars — walkers only.
	if kind == Kind.WALKER and _map.is_soft_sealed(tile):
		return true
	if not _map.in_bounds(tile):
		var leaves_by_the_spine := kind == Kind.CAR and vertical and _corridor == _map.main_road \
				and (tile.y < 0 or tile.y >= _map.size.y)
		return not leaves_by_the_spine
	# And a precinct is a wall to a car and a street to everybody else. The tile map cannot say
	# so — it is paving either way — so the street kind has to, or a car reaching the three
	# blocks of a precinct drives onto them instead of turning off.
	if kind == Kind.CAR and not _map.is_driveable_at(vertical, tile):
		return true
	return not _map.is_street(tile)

## How far the way ahead is clear, in tiles, worked out **once per tile** rather than once per
## frame. `LOOKAHEAD_TILES + 1` means nothing within reach.
##
## **Sampling a tile grid by stepping world points aliases, and it aliases where it matters.** A
## single probe fired seven tiles out answers *is there something coming up* and cannot answer *is
## the next tile a wall* — it looks straight **past** a cul-de-sac's two-tile plug into the open
## road behind it, so an agent entering a dead-end street from the junction beside the wall never
## sees the wall and walks into the building. Measured with the probe: eight agents inside one at
## once, and something in one on 87% of frames.
##
## **Caching it by tile is what pays for the walk**, and it is exact rather than an approximation:
## the answer depends on the agent's tile, its axis and its direction, and on a map that is fixed
## for the day. An agent covers a tile in about twenty frames at walking pace, so seven lookups per
## tile is cheaper than the one probe per frame it replaces — and the probe was the version that
## could not see a wall.
func _look_ahead() -> void:
	var here := _map.world_to_tile(position)
	if here == _scan_at and _vertical == _scan_vertical and _direction == _scan_direction:
		return
	_scan_at = here
	_scan_vertical = _vertical
	_scan_direction = _direction
	_blocked_in = LOOKAHEAD_TILES + 1
	var step := (Vector2i.DOWN if _vertical else Vector2i.RIGHT) * int(signf(_direction))
	for i in range(1, LOOKAHEAD_TILES + 1):
		if _cannot_go_on(_vertical, here + step * i):
			_blocked_in = i
			return

## Traffic goes round a closure, and that is half of what makes one legible: the street with
## nobody on it is the street that is shut, which reads from a block away — further than the
## barrier itself does.
##
## Turning here rather than only in `_consider_turning` is why cars divert too. A car that
## carried on would drive through the barrier, and a car that vanished at the junction would
## be worse: at this population something popping out of existence is very visible.
##
## **A walker turns where it stands and a car plans a curve** — see `_plan_a_turn`. The rest of this
## function is the walker's own version: a person changes direction in a stride, has no lane to be
## on the correct side of and no length to swing round, so there is nothing for a path to be
## continuous about.
func _divert() -> void:
	if kind == Kind.CAR:
		_plan_a_turn()
		return
	var crossing := CrowdLanes.corridor_at(_along())
	if crossing < 0:
		# Still in the street, a junction short of where it can turn. Carry on — unless it is
		# standing *in* the thing it is avoiding, which is a day that started behind a barrier,
		# or the thing is the very next tile, which is a **cul-de-sac**. Both have nowhere to go
		# but back.
		if not _stands_on_a_street() or _blocked_in <= 1:
			_turn_round()
		return
	if not _can_turn_here():
		# Inside a junction on the wrong band to turn from — a walker on the carriageway strip, a
		# car on a pavement one — which normally costs a tile of waiting. It costs everything when
		# the wall is the next tile: an agent leaving a junction straight into a cul-de-sac's plug
		# has no tile left to wait for the right band in, so it turns round instead.
		if _blocked_in <= 1:
			_turn_round()
		return

	var turning := _pick_an_arm(crossing, 1.0 if _rng.randf() < 0.5 else -1.0)
	if turning == 0.0:
		_turn_round()   # boxed in on three sides; go back the way it came
		return

	var kept := _corridor
	_vertical = not _vertical
	_corridor = crossing
	_direction = turning
	if kind == Kind.CAR:
		# Back onto the correct side of the road for the way it is now pointing — and it is the
		# **new** axis that decides which side that is. Driving on the right flips with the axis.
		_lane = CrowdLanes.road_lane(_vertical, turning)
	else:
		_lane = CrowdLanes.nearest_sidewalk(_corridor, _cross())
	_lane_centre = _lane_centre_here()
	_forget_the_detour()
	_junction = kept
	_claim_the_road_here()

## Turns an agent round where it stands: a dead end, a barrier at a mouth, a precinct's paving.
##
## **A car changes lane with it**, which `_direction = -_direction` on its own did not. A lane is
## one side of a carriageway and which side depends on the way it is pointing, so a car that only
## flipped its heading drove the wrong way down its own queue — and `space_out_the_traffic` then had
## to resolve a head-on overlap the only way it can, by moving a body. It is the same line
## `_divert` runs after a turn and for the same reason.
func _turn_round() -> void:
	_direction = -_direction
	if kind == Kind.CAR:
		_lane = CrowdLanes.road_lane(_vertical, _direction)
		_lane_centre = _lane_centre_here()
	_forget_the_detour()
	_claim_the_road_here()

## Which way to turn out of `crossing`, trying `first` before the other one, or `0.0` for neither.
##
## Two questions and they are not the same question. **Can it go that way at all** is the tile map
## — shut for the day, or never a street — and an arm that fails it is not an option. **Is there
## room** is the other cars, and an arm that fails *that* is a bad option rather than no option.
##
## **The second one exists because a turn is a placement.** It takes the coordinate the car had
## along its old corridor and makes it the one it has across the new one, so the car materialises
## somewhere in another queue — and the separation rule then resolves the overlap the only way it
## can, by moving a body. Front-to-back, so the shortfall cascades down the queue behind it and a
## car is jumped backwards by up to six of its own lengths in a single frame. Off screen at the
## entry band that is exactly what it is for; at a junction the player is looking at, it is a car
## vanishing.
##
## Preferring rather than requiring, because a car that refuses to turn drives into the barrier it
## was avoiding. When both arms are full it takes the first one anyway and the resolve does what it
## can — which makes the jump the rare case instead of the usual one.
##
## `from` is where the two probes are fired from, and it matters because a car asks this question
## **before** it reaches the junction rather than from inside it: fired from where the car happens
## to be standing, a probe across the axis lands in the block beside it and reports both arms shut.
## It defaults to the agent's own position, which is where a walker asks from.
func _pick_an_arm(crossing: int, first: float, from := Vector2.INF) -> float:
	# A precinct is not an arm a car has. Neither of the two questions below would catch it: it is
	# paved end to end, so the tile map says it is a street, and there is never a car in it to
	# leave no room. A car with nowhere else to go turns round instead, which is what a driver
	# meeting a bollarded street actually does.
	if kind == Kind.CAR and not _map.is_driveable(not _vertical, crossing,
			floori(_cross() / float(Tuning.TILE_SIZE))):
		return 0.0
	var open: Array[float] = []
	for turning in [first, -first]:
		if not _blocked_ahead(not _vertical, turning, LOOKAHEAD, from):
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
## the lane the agent then has to steer away from. So a walker turns while it is on one of the
## junction's pavement bands and ends the turn a few pixels from a lane it is allowed to be in
## rather than two tiles from one. Every walker crosses both bands on its way through a junction, so
## waiting costs at most a tile. **Walkers only now** — a car's turn is a planned arc that lands on
## its exit lane exactly, so where it may start from is the arc's own geometry rather than a band.
func _can_turn_here() -> bool:
	var offset := CityMap.corridor_offset(floori(_along() / float(Tuning.TILE_SIZE)))
	if offset < 0:
		return false
	return CityMap.is_road_offset(offset) == (kind == Kind.CAR)

# ------------------------------------------------------------- car turns ---
# **A turn is a path a car has to be able to take, and both halves of that were missing.** It used
# to swap the axis and the lane in the frame it happened: the car was carried sideways across the
# carriageway by its own steering afterwards, and on the frame itself its heading jumped a right
# angle — or, turning round, a straight reversal — so the strike box, the horn and the picture all
# pointed somewhere the car had never been going. *(Playtest 53: "when a car turns or turns around
# it should make a proper turn".)*
#
# So a car now plans the whole manoeuvre before it starts it. `CarTurn` is the curve; everything
# here is the *deciding*: where the arc goes, whether the ground it sweeps is road the car may be
# on, whether the lane it lands in has room, and what it does when the answer is no.
#
# **What it does when the answer is no is stop.** A car that cannot fit a turn does not take a
# smaller one and does not fall back on the separation pass to repair it — it brakes for the
# blockage and stands there. See `_distance_to_the_blockage`.

## A car plans its way round the blockage ahead and commits to the whole of it before it moves.
##
## Called instead of the walker's `_divert` body, and it takes the same two decisions in the same
## order: which arm of the junction (`_pick_an_arm`, unchanged, with the probes fired from the
## junction rather than from wherever the car is standing) and, when neither arm is open, the way it
## came. What is new is that each of those is now a *curve* that has to fit, so the order below is
## the order of preference among places to turn rather than a single answer:
##
## 1. **The arm it picked**, as a quarter turn taken from the junction's own carriageway entry.
## 2. **The other arm**, which is a wider arc — the far-side lane is three times the radius away —
##    and so fits in some junctions where the near one does not.
## 3. **An about-face in the middle of the junction box**, where the crossing street's own
##    carriageway is the room a half turn needs.
## 4. **An about-face in the street**, short of whatever is blocking it. This is the one manoeuvre
##    in the game whose swept body crosses a kerb, and it is a fact about the city rather than a
##    concession: the two lanes of a carriageway are 32px apart, so a half turn between them is a
##    16px arc and a car's own corners then reach 40px from the centre of it — 8px past a kerb that
##    is 32px away. There is no rounder way to do it, the alternative manoeuvre is a three-point
##    turn the traffic has no reverse gear for, and refusing it outright parks a third of the
##    traffic: measured over ninety seconds, stopped cars at the end went 10 → 33 of 34, because one
##    car nose-to-wall in a dead end takes its whole street with it. Nothing else is relaxed — the
##    wall, the closure, the seal and the building are all still refused.
func _plan_a_turn() -> void:
	if _turn:
		return
	# Standing on ground it may not be on at all, which is a day that started behind a barrier. There
	# is no legal space to sweep and nothing to be gained by waiting for some, so the about-face on
	# the spot stays exactly what it was: the way out of a state that is already illegal.
	if not _stands_on_a_street():
		_turn_round()
		return
	var band := _junction_index()
	if band < 0:
		return
	var box := junction_ahead()
	var probe := CarTurn.world(_vertical, CarTurn.carriageway_centre(band), _cross())
	var first := 1.0 if _rng.randf() < 0.5 else -1.0
	var turning := _pick_an_arm(band, first, probe)
	if turning != 0.0:
		if _commit_to_a_turn(_arm_turn(band, turning, box)):
			return
		var other := _pick_an_arm(band, -turning, probe)
		if other != 0.0 and other != turning and _commit_to_a_turn(_arm_turn(band, other, box)):
			return
	if _commit_to_a_turn(_about_face_at(CarTurn.carriageway_centre(band), box)):
		return
	var blockage := _distance_to_the_blockage()
	if blockage == INF:
		return
	if _commit_to_a_turn(_about_face_at(_along() + (blockage - CarTurn.about_face_reach())
			* _direction, Vector2i(-1, -1)), true):
		return
	# **Nothing fits, and the car has run out of road to find something that does.** A car still
	# rolling keeps asking, since a few pixels further on the answer changes; one that has come to
	# rest with less than a half turn's room in front of it has no manoeuvre left at all — it is
	# parked closer to the barrier than any curve needs, which is a state the model does not cover
	# and only a placement or a barrier that arrived after it did can produce. The alternative to
	# reversing its heading where it stands is a car that never moves again, and a car that never
	# moves again holds the junction box it is standing in and takes the whole street behind it: 33
	# of 34 cars at a standstill in ninety seconds, measured. Reverse gear is the manoeuvre this
	# wants and the traffic has none.
	if _speed < Tuning.CAR_STOPPED_SPEED and _room_to_stop_in() < _nose():
		_turn_round()

## The half turn back down the other lane, taken at a given point along this corridor.
func _about_face_at(at_along: float, box: Vector2i) -> CarTurn:
	return CarTurn.about_face(_vertical, _direction, _corridor, _lane, _cross(), at_along,
			CrowdLanes.road_lane(_vertical, -_direction), box)

## The arc into one arm of the junction ahead. The lane it lands in is the one on its own right for
## the way it will then be pointing, which is the **new** axis's answer — driving on the right flips
## with the axis, exactly as it did when this was a lane swap.
func _arm_turn(band: int, turning: float, box: Vector2i) -> CarTurn:
	return CarTurn.into_an_arm(_vertical, _direction, _corridor, _cross(), band,
			CrowdLanes.road_lane(not _vertical, turning), turning, box)

## Takes a planned turn if it fits, and says whether it did.
##
## Three things have to be true, and none of them is revisited afterwards: there is a straight
## run-up to the arc rather than the arc starting behind the car, the ground the body sweeps is road
## it may drive on, and the lane it lands in has a car's length free. The room is then *held* for
## every frame of the manoeuvre, run-up included, so nothing else turns or recycles into the piece of
## road this car is already committed to.
func _commit_to_a_turn(turn: CarTurn, over_the_kerb := false) -> bool:
	var run_up := (turn.entry_along - _along()) * _direction
	# Further off than the car watches a junction from is further off than it can know the road is
	# still going to be clear when it gets there.
	if run_up > Tuning.CAR_JUNCTION_SIGHT:
		return false
	# **The run-up is driving, and it has to be legal driving.** Only the arc's own ground is swept
	# and checked; the straight before it is ordinary lane travel, so what says whether it is clear
	# is the lookahead. Without this a car blocked in mid-street plans for the junction *beyond* the
	# barrier — `_junction_index()` names the one it is heading for — and drives through the barrier
	# to reach it.
	if run_up > _distance_to_the_blockage():
		return false
	if run_up < 0.0:
		# Past the entry the geometry would have chosen — a car that only found out it was turning
		# once it was already in the box. What is left of the junction is a tighter arc, and one
		# tighter than `Tuning.CAR_TURN_RADIUS_MIN` is refused rather than squeezed.
		if not turn.tighten_to(_along(), _cross()):
			return false
		run_up = 0.0
	if not _the_ground_a_turn_sweeps_is_clear(turn, over_the_kerb):
		return false
	if not _the_exit_has_room_to_leave(turn):
		return false
	if not _has_room_to_land(turn):
		return false
	_turn = turn
	_turn_run_up = run_up
	_claim_the_turn()
	return true

## Moves this car along its own planned turn: the straight run-up first, then the arc.
##
## **The frame that changes over from one to the other splits its travel between them**, so the car
## covers exactly `speed × delta` on it like every other frame and starts curving from the entry
## point rather than from wherever the last straight step happened to leave it. The same split
## happens at the far end, where what is left over is spent going straight down the new lane.
func _follow_the_turn(delta: float) -> void:
	var travel := _speed * delta
	if _turn_run_up > 0.0:
		var straight := minf(travel, _turn_run_up)
		_set_along(_along() + straight * _direction)
		_set_cross(move_toward(_cross(), _lane_centre, STEER_SPEED * delta))
		_turn_run_up -= straight
		travel -= straight
		if _turn_run_up > 0.0:
			return
		# The arc is put on the car rather than the car on the arc: whatever fraction of a pixel it
		# is off its own lane centre is where the curve begins. A quarter turn still lands on its
		# exit lane exactly — see `CarTurn.begin_at`.
		_turn.begin_at(_cross())
	_turn.travelled += travel
	if _turn.travelled < _turn.length():
		position = _turn.point_at(_turn.travelled)
		return
	var overshoot := _turn.travelled - _turn.length()
	_land_the_turn()
	_set_along(_along() + overshoot * _direction)

## The end of a turn: the car takes up the axis, corridor, lane and direction it turned into.
##
## It is standing on the exit lane's own centre line, pointing along it, because that is where the
## arc ends — so there is nothing to steer back to and nothing that has to be spaced out. The
## lookahead is thrown away, since it is a cached answer about an axis this car no longer has.
func _land_the_turn() -> void:
	position = _turn.point_at(_turn.length())
	_vertical = _turn.exit_vertical
	_corridor = _turn.exit_corridor
	_lane = _turn.exit_lane
	_direction = _turn.exit_direction
	_junction = _turn.entry_corridor
	_turn = null
	_turn_run_up = 0.0
	_lane_centre = _lane_centre_here()
	_forget_the_detour()
	_scan_at = Vector2i(-9999, -9999)
	_claim_the_road_here()

## Whether every tile the car's own body passes over during the arc is road it may drive on.
##
## **The strike box is the datum** — the 52×28px rectangle that makes a car lethal — swept along the
## curve and sampled at its own corners and the points between them. It is deliberately the same
## rectangle the game already tells the player is the dangerous part of a car, rather than a second
## footprint nobody can see.
##
## What it adds to `_cannot_go_on` is the **kerb**. Going straight, a car is kept off the pavement by
## lane arithmetic and `_cannot_go_on` never had to say so — a sidewalk tile is a perfectly good
## street. A curve has no lane to be in the middle of, so the pavement has to be refused explicitly
## or the first tight turn puts a car's back wheels through a bus queue.
##
## `over_the_kerb` is the one exemption, and it is only ever granted to the about-face of last
## resort: see `_plan_a_turn` for why a half turn between two lanes of one carriageway cannot be
## contained by it. Everything a car may not *be* on — a wall, a closure, a seal, a precinct's
## paving, the ground outside the map — is refused either way.
func _the_ground_a_turn_sweeps_is_clear(turn: CarTurn, over_the_kerb: bool) -> bool:
	var seen := {}
	var length := turn.length()
	var steps := maxi(1, ceili(length / TURN_SWEEP_STEP))
	for i in steps + 1:
		var at := length * float(i) / float(steps)
		var centre := turn.point_at(at)
		var forward := turn.heading_at(at)
		var side := Vector2(-forward.y, forward.x)
		for a in TURN_BODY_SAMPLES.x:
			var along := lerpf(-1.0, 1.0, float(a) / float(TURN_BODY_SAMPLES.x - 1))
			for b in TURN_BODY_SAMPLES.y:
				var across := lerpf(-1.0, 1.0, float(b) / float(TURN_BODY_SAMPLES.y - 1))
				var tile := _map.world_to_tile(centre
						+ forward * (along * Tuning.CAR_STRIKE_HALF_LENGTH)
						+ side * (across * Tuning.CAR_STRIKE_HALF_WIDTH))
				if seen.has(tile):
					continue
				seen[tile] = true
				if _cannot_drive_over(tile, over_the_kerb):
					return false
	return true

## How finely the swept body is sampled: a pose every `TURN_SWEEP_STEP` px of arc, and the strike
## box itself on a grid that includes its own four corners.
##
## Four pixels is a seventh of the tightest arc's own quarter turn, which is fine enough that the
## body cannot pass a whole tile between two poses. It is not free — a rejected turn is a hundred-odd
## tile questions — but a turn is a thing a car does a few times a minute, not a thing it does every
## frame, and the tiles are deduplicated because consecutive samples mostly land on the same one.
const TURN_SWEEP_STEP := 4.0
const TURN_BODY_SAMPLES := Vector2i(5, 3)

## Whether a tile is carriageway this car may sweep over: open today, in bounds, not a precinct's
## paving, and road rather than pavement. See `_the_ground_a_turn_sweeps_is_clear` for why the last
## one is asked here and nowhere else.
func _cannot_drive_over(tile: Vector2i, over_the_kerb: bool) -> bool:
	if _cannot_go_on(_vertical, tile):
		return true
	return not over_the_kerb and not Tile.is_road(_map.tile_at(tile))

## Whether there is enough road past the end of the arc for the car to have got itself out of the
## turn — *nothing enters a junction it cannot leave*, asked of the street it is leaving into.
##
## **The arm a car picks is probed with a single point seven tiles out, and a single probe looks
## straight past a two-tile plug** — the same aliasing `_look_ahead` walks tiles to avoid. That was
## harmless while a car could reverse its heading wherever it stood: it turned into the cul-de-sac,
## met the plug and flipped. It is not harmless now, because a car that lands nose-to-wall has no
## room left to swing round in and stands there for the rest of the day, holding the junction it
## came through shut and taking the whole street behind it with it — measured, that one hole put
## 33 of 34 cars at a standstill inside ninety seconds.
##
## Stated over the room a *turnaround* needs rather than over some tile count: a car that can still
## turn round is never stuck, whatever it finds later.
func _the_exit_has_room_to_leave(turn: CarTurn) -> bool:
	var end := turn.point_at(turn.length())
	var forward := turn.heading_at(turn.length())
	var step := Vector2i(roundi(forward.x), roundi(forward.y))
	var needed := ceili((CarTurn.about_face_reach() + _nose()) / float(Tuning.TILE_SIZE))
	var here := _map.world_to_tile(end)
	for i in range(1, needed + 1):
		if _cannot_drive_over(here + step * i, false):
			return false
	return true

## Whether the lane a planned turn lands in has a car's length of road to spare where it lands.
##
## The landing is the arc's own end point rather than the approximation `_has_room_to_turn` makes
## for the *preference* between two arms — those are the same question asked for different purposes,
## one to choose between arms and this one to refuse a turn outright, and this one knows exactly
## where the car will be standing.
func _has_room_to_land(turn: CarTurn) -> bool:
	if not traffic:
		return true
	return traffic.room_at(make_lane_key(turn.exit_vertical, turn.exit_corridor, turn.exit_lane,
			turn.exit_direction), turn.landing(), Tuning.CAR_GAP_MIN)

## Holds the piece of road a committed turn is going to land on, once a frame for as long as the
## manoeuvre lasts.
##
## **Two cars can commit to the same piece of road in one frame** — the index they both read is
## rebuilt once a frame and predates both of them — which is the same hole `TrafficIndex.claim()`
## closes for recycling, and a turn is the case where it is worst: the reservation has to outlive
## the whole manoeuvre rather than one frame, because the car is not in that lane yet and nothing
## else would put it in the index. Re-made every frame, since every rebuild throws it away.
func _claim_the_turn() -> void:
	if not traffic or not _turn:
		return
	traffic.claim(turn_lane_key(), _turn.landing())

## True while this car is following a planned turn, run-up included. What tells `Crowd` to hold the
## junction box shut on both axes until the car is out of it.
func is_turning() -> bool:
	return _turn != null

## The junction box a turning car is claiming, or `(-1, -1)`.
##
## **Only once the arc has actually begun**, never during the run-up: a car that has committed to a
## turn from a junction's sight distance away is still queueing for the box like anybody else, and
## holding it shut for the length of its approach would empty the crossing street for a second and a
## half. What it claims is the box it is *in*.
func turning_in() -> Vector2i:
	return _turn.junction if _turn and _turn_run_up <= 0.0 else Vector2i(-1, -1)

## The lane a turning car has reserved a place in, and where in it — `Crowd` puts the pair into the
## index it rebuilds, so the reservation is visible to every car for the whole frame rather than
## only to the ones that happen to look after this one has moved.
func turn_lane_key() -> String:
	if not _turn:
		return ""
	return make_lane_key(_turn.exit_vertical, _turn.exit_corridor, _turn.exit_lane,
			_turn.exit_direction)

func turn_landing() -> float:
	return _turn.landing() if _turn else 0.0

## How far this car has to the near edge of the first thing it cannot drive past, or `INF` when the
## road ahead is clear as far as it looks.
##
## **Braking for it is what makes a turnaround possible at all.** Nothing used to brake for a
## blockage, because reversing the heading on the spot was always available however close the wall
## was. A car that has to swing round needs road to swing into, so `_room_to_stop_in` is what the
## brake actually aims at and this is the distance under it.
func _distance_to_the_blockage() -> float:
	# Nothing to answer on the arc itself: the lookahead is a cached scan down the lane the car has
	# left, and the ground the curve covers was checked before it started.
	if kind != Kind.CAR or _blocked_in > LOOKAHEAD_TILES:
		return INF
	if _turn and _turn_run_up <= 0.0:
		return INF
	var here := floori(_along() / float(Tuning.TILE_SIZE))
	var tile := here + _blocked_in * signi(int(_direction))
	var edge := float(tile * Tuning.TILE_SIZE)
	if _direction < 0.0:
		edge += float(Tuning.TILE_SIZE)
	return maxf(0.0, (edge - _along()) * _direction - _nose())

## Where a car braking for a blockage aims to come to rest: a half turn's worth of road short of it,
## so that a car which has to turn round has somewhere to do it. A driver meeting a dead end stops a
## car's length off the wall rather than nosing into it, and for the same reason.
func _room_to_stop_in() -> float:
	# **Not while a turn is committed**, and this is the difference between a car that turns round at
	# a dead end and one that creeps to a halt just short of turning round: the two brakes aim at the
	# same point, and a car easing to *zero* there never reaches the entry it was easing toward. The
	# turn's own brake is what governs the approach once there is a turn, and the road it runs over
	# was checked before the car committed.
	if _turn:
		return INF
	var blockage := _distance_to_the_blockage()
	if blockage == INF:
		return INF
	return maxf(0.0, blockage - CarTurn.about_face_reach())

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
	var beyond := _room_beyond_the_map()
	if at < -beyond or at > limit + beyond:
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
	# Past the edge of the map and still inside its allowance: it is *leaving the city*, which is
	# what the tunnel and the bridge are for. The box's own bounds are clamped to the map, so
	# asking them here would recycle a car on the deck of the bridge — which is the bug.
	if at < 0.0 or at > limit:
		return false

	var bounds := field.along_bounds(_vertical)
	if _direction > 0.0:
		return at > bounds.y or at < bounds.x - ENTRY_SPREAD
	return at < bounds.x or at > bounds.y + ENTRY_SPREAD

## How far past the edge of the map this agent may go before it stops existing.
##
## **Nothing vanishes while you are looking at it** — the rule written for events, arriving at the
## crowd. A recycle normally happens at the edge of a box nowhere near anything the player can see;
## the three holes in the boundary are exactly where that is not true, because a car reaching the
## bridge is at the one place in the city that is *about* leaving.
##
## **A tile for everybody else, and that is not stinginess.** Outside the map is water, forest and
## mountainside — painted ground with no road on it — so a car allowed to overrun anywhere would
## drive into the sea. The spine is the exception because it is the only place the carriageway
## carries on through the border: `City._paint_outside_the_map` puts road out there at the spine's
## own width and nowhere else, and `CityEdge` is the tunnel and the bridge standing over it.
## Walkers keep the tile for the same reason — the pavements do not carry on, only the road does.
func _room_beyond_the_map() -> float:
	if kind != Kind.CAR or not _vertical or _corridor != _map.main_road:
		return Tuning.TILE_SIZE
	return Tuning.OUT_OF_SIGHT

## How far outside the box an agent may enter, in px.
##
## **It has to be a band and not a point.** Recycling everybody onto the exact edge coordinate puts
## every car that re-enters a lane on the same pixel — and once cars keep a headway, a pile that
## would sort itself out by driving through itself becomes a permanent stationary queue against the
## boundary. Measured that way: eight overlapping pairs a frame, on a road nobody can see.
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
## The entry *point* is rolled inside the same loop and checked too, because a corridor may be park
## for two blocks of its length: a car re-entering there would be standing on grass and would divert
## on the first frame, which is a car appearing in a park and driving out of it.
##
## And it has to be a piece of road **nobody is on**. A recycled car that cannot see the lane it
## lands in leaves the positional resolve to sort it out, which is the resolve doing a placement's
## job. It is only a preference: after six rolls it takes what it has, because an entry band with
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
	gate_hold = INF
	_keep_within_the_room_beyond_the_map()
	# The loop above only ever *tries* for `_stands_on_a_street`; six misses in a row near a true
	# edge leave whatever the last roll was, which `_keep_within_the_room_beyond_the_map` still
	# lets sit up to one tile past it — the same tile every kind but the spine's own car was
	# already allowed to overrun by before this. That used to correct itself the moment the agent
	# next moved, because nothing stopped it walking back onto the street. Now `_cannot_go_on`
	# refuses the very step that would have done it, so a fallback that lands out of bounds is
	# stuck there instead of drifting in — pulled onto the map's own last row or column here,
	# the one lane still guaranteed to exist. Never for the spine's own exception, which is
	# already standing somewhere real.
	if not _stands_on_a_street():
		var extent := _map.world_size()
		var limit: float = extent.y if _vertical else extent.x
		# `limit` itself is one past the last tile's own far edge, the same fencepost
		# `world_to_tile` always floors away — so the clamp's own top has to give up a whole
		# pixel or it can land exactly on the line and read as out of bounds again.
		_set_along(clampf(_along(), 0.0, limit - 1.0))

## However the rolls above landed, an entry point may not sit further past the map's true edge
## than this agent is allowed to travel before it is recycled again — the same room
## `_room_beyond_the_map` grants the far end of a journey, asked of the near end too.
##
## **`ENTRY_SPREAD` is a car's-length band and every kind shares it**, because the *normal* job of
## a spread is an off-screen buffer inside the box, which every kind wants the same amount of. The
## fallback below it is the trap: when six rolls near a boundary all miss — likely exactly where
## the arterial's own weight keeps re-offering the spine — the entry point can land `ENTRY_SPREAD`
## past the edge regardless of kind, because nothing here knew a walker's own overrun is a single
## tile where a car's on the spine is the length of the bridge. Without this a walker can appear
## already standing on the crossing, which is the one thing only a car may do.
func _keep_within_the_room_beyond_the_map() -> void:
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var beyond := _room_beyond_the_map()
	_set_along(clampf(_along(), -beyond, limit + beyond))

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
##
## **Never past ground it could not have driven onto itself**, for the same reason `nudge_back`
## checks it: the rearmost car's own position says nothing about what stands behind it, and a queue
## that has backed up almost to a wall would otherwise place the newcomer inside it. Refusing the
## move leaves the car wherever `_recycle`'s own loop already found it standing on a street, which
## is the position this whole fallback exists to improve on rather than one it has to guarantee.
func _join_the_back_of_the_queue() -> void:
	if kind != Kind.CAR or not traffic or _has_room_here():
		return
	var last := traffic.rearmost(lane_key())
	if last == INF:
		return
	var target := (last - Tuning.CAR_GAP_MIN) * _direction
	var probe := Vector2(_cross(), target) if _vertical else Vector2(target, _cross())
	if _cannot_go_on(_vertical, _map.world_to_tile(probe)):
		return
	_set_along(target)

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

## Whether the whole entry band lies on ground this agent may stand on. The box's bounds are
## clamped to the map, so beside a boundary the band an inward-bound lane enters through is the
## stretch *past* the edge — and that is refused for everybody but a car on the spine, who gets
## the same `_room_beyond_the_map` on the way in that it gets on the way out. Without the
## exception nothing ever comes out of the tunnel or off the bridge: every roll of a southbound
## spine lane beside the north edge lands in the tunnel, every roll is refused, and the traffic
## through the two holes in the border runs one way.
func _entry_band_fits() -> bool:
	var bounds := field.along_bounds(_vertical)
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var beyond := _room_beyond_the_map()
	if _direction > 0.0:
		return bounds.x - ENTRY_SPREAD >= -beyond
	return bounds.y + ENTRY_SPREAD <= limit + beyond

# ---------------------------------------------------------------- drawing ---

## The sector each kind is currently drawn in — `EightDirection`'s own indexing, clockwise from
## east — persisted across frames so `_update_walker_view()`/`_update_car_view()` can hold it
## through the boundary and hysteresis `EightDirection.update()` applies. A walker and a car keep
## separate fields because they read different headings: a walker's is `_walker_heading()`'s
## along-plus-cross blend, a car's is `velocity()` alone.
var _walker_view := 2
var _car_view := 2

## Below this speed a walker's own applied heading (`_walker_heading()`) is too close to zero to
## mean a facing, so it holds whatever it was last drawn as rather than chattering on the residual
## few px/s `_yield_factor()` and float noise can still leave in it. Well under
## `Tuning.PEDESTRIAN_SPEED`'s own floor (46px/s), so only an actually-stopped walker — a give-way,
## a queue, a halt — ever reads as idle.
const WALKER_IDLE_SPEED := 5.0

## The same hold for a car. `velocity()` is `heading()` — always unit length, cardinal in a lane or
## the tangent of an arc mid-turn — times the actual speed, so a car braked to a stop reads as a
## zero heading rather than whatever axis it last pointed along. Well under
## `Tuning.CAR_STRIKE_MIN_SPEED` (20px/s, the floor below which a car cannot strike anybody) and far
## under `Tuning.CAR_SPEED.x` (130px/s), so only a car actually stopped — a light, a gate, a
## give-way — ever reads as idle.
const CAR_IDLE_SPEED := 5.0

## Which of `EightDirection`'s eight sectors the agent is showing, advanced here for whichever kind
## it is — `_process()` already calls `_frame()` once every physics tick, so this is where the
## hold actually runs rather than in a second per-frame hook. Calling it again — `_draw_body()`'s
## own call, and every halo ring atop that — is safe: asking `EightDirection.update()` twice with
## the same starting sector and the same heading always answers the same way.
func _frame() -> int:
	if kind == Kind.CAR:
		_update_car_view()
		return _car_view
	_update_walker_view()
	return _walker_view

func _flipped() -> bool:
	return EightDirection.is_mirrored(_car_view if kind == Kind.CAR else _walker_view)

## The walker's own instantaneous heading this frame: its along-lane velocity (`velocity()`, the
## actual-motion quantity M111's own turning work already reads elsewhere) plus whatever its
## steering is doing across the lane right now — the term `_frame()`'s old lane-axis-only version
## never had, and the one that swings a walker rounding a corner, or nudged aside by
## `step_aside()`, onto a diagonal view a moment before its lane assignment itself turns. The
## cross term is `_set_cross()`'s own target (`_lane_centre + _detour`) minus where it actually is,
## signed and capped at `STEER_SPEED` — the rate `_process()`'s own `move_toward` steers at while
## it has not yet arrived. Zero once it has arrived with no detour running, which a stopped walker
## (give-way, queue, halted) always has, since `_yield_factor()` also zeroes the along term then.
func _walker_heading() -> Vector2:
	var along := velocity()
	var cross_gap := _lane_centre + _detour - _cross()
	if is_zero_approx(cross_gap):
		return along
	var cross_speed := signf(cross_gap) * STEER_SPEED
	return along + (Vector2(cross_speed, 0.0) if _vertical else Vector2(0.0, cross_speed))

## Advances `_walker_view` for this frame. `setup()` and `_recycle()` place a walker with no
## cross-lane steering yet running (`_set_cross(_lane_centre)`, `_forget_the_detour()`), so
## `_walker_heading()` right after either is always exactly along the new lane axis — a sector
## centre 45° clear of its neighbours, twice the hold's own 27.5° reach — and the ordinary test
## below already replaces whatever sector was drawn before without a special reset call into
## either function. Both are owned by the concurrent lane-turning work on this file (see the class
## doc), which is the other reason this reaches for the plain hold here rather than a call added
## to either placement.
func _update_walker_view() -> void:
	_walker_view = EightDirection.update(_walker_view, _walker_heading(), WALKER_IDLE_SPEED)

## Advances `_car_view` for this frame. **There is no cross term the way a walker has one**: a
## car's own `velocity()` already is its instantaneous line of travel — cardinal in a lane, the
## tangent of its own arc mid-turn (`heading()`) — so the sector runs through the diagonal for
## exactly the length of a turn and holds at whichever cardinal or diagonal it last pointed while
## the car is at or under `CAR_IDLE_SPEED`. `setup()` and `_recycle()` place a car with no turn
## running and its heading exactly on a lane axis — a sector centre 45° clear of its neighbours,
## twice the hold's own reach — so the ordinary update below already replaces whatever sector was
## drawn before, the same "no reset call needed" property `_update_walker_view()` documents for the
## walker.
func _update_car_view() -> void:
	_car_view = EightDirection.update(_car_view, velocity(), CAR_IDLE_SPEED)

func _draw() -> void:
	_draw_body(self)
	if kind == Kind.CAR:
		_draw_mark()

## Draws this agent's own body onto `canvas`. `EntityHalo` calls this once per ring offset to
## trace whichever silhouette the sprite actually is; the ordinary frame draws it once at self.
func _draw_body(canvas: CanvasItem) -> void:
	var frame := _frame()
	var flip := _flipped()
	if kind == Kind.CAR:
		_draw_shape_shadow(canvas, shape, Vector2.ZERO, _travel_axis())
		var view: String = CAR_VIEW_BY_SECTOR[frame]
		var anchor := _car_body_anchor(view)
		Sprites.draw_standing(canvas, CAR_BODY_BY_VIEW[view], anchor, Vector2.ZERO, flip, colour)
		Sprites.draw_standing(canvas, CAR_TRIM_BY_VIEW[view], anchor, Vector2.ZERO, flip)
		return
	_draw_shape_shadow(canvas, shape, Vector2.ZERO, Vector2.RIGHT)
	var view: String = WALKER_VIEW_BY_SECTOR[frame]
	Sprites.draw_standing(canvas, WALKER_BODY_BY_VIEW[view], Vector2.ZERO, Vector2.ZERO, flip, colour)
	Sprites.draw_standing(canvas, WALKER_TRIM_BY_VIEW[view], Vector2.ZERO, Vector2.ZERO, flip)

## The strike box's own southernmost point when the heading is a diagonal, in px south of the
## node — `Tuning.CAR_STRIKE_HALF_LENGTH` (26) and `Tuning.CAR_STRIKE_HALF_WIDTH` (14) each rotated
## 45 degrees onto the screen's south axis, `(26 + 14) / sqrt(2)` ≈ 28.28, plus the 2px the
## diagonal canvas leaves between its own alpha content and its own edge (`facings.csv`: content to
## y40 of a 42-tall canvas) — so the anchor below lands the *drawn* corner, not the empty canvas
## edge, on the strike box's own corner. A literal rather than a computed constant because GDScript
## consts cannot call `sqrt()`; the value is `(CAR_STRIKE_HALF_LENGTH + CAR_STRIKE_HALF_WIDTH) /
## sqrt(2.0) + 2.0` and this is asked back of `Tuning`'s own two constants by
## `tests/test_car_views.gd` rather than pinned as a bare number there.
const CAR_DIAGONAL_ANCHOR_Y := 30.284271247461902

## Where a car's own body texture is anchored for `Sprites.draw_standing`, keyed by the view name
## `CAR_VIEW_BY_SECTOR` names rather than by sector, since the two mirrored sectors of a standing
## view need the same offset. `draw_standing` always bottom-centres a texture at the point it is
## given, and each authored view puts a different part of the car at that edge:
##
## - **Side** needs no correction, as it never did: the car's along-track length is the texture's
##   own *width*, which `draw_standing` centres by default, and its own alpha content already
##   touches the canvas's bottom row (`facings.csv`'s own alpha bounds).
## - **Front/back** are standing elevation pictures rather than the old flattened top-down end
##   view: the canvas's own bottom edge is the car's south end — the near bumper for one heading
##   and the far one for the other, which does not matter since the strike box is symmetric between
##   them — so it belongs `CAR_STRIKE_HALF_LENGTH` south of the node, exactly where the box's own
##   south edge already sits for a car pointed along that axis.
## - **The diagonals** draw the car turned 45 degrees to the screen, so the strike box's own
##   southernmost point is a *corner* rather than an edge — see `CAR_DIAGONAL_ANCHOR_Y`.
func _car_body_anchor(view: String) -> Vector2:
	match view:
		"front", "back":
			return Vector2(0.0, Tuning.CAR_STRIKE_HALF_LENGTH)
		"front_diagonal", "back_diagonal":
			return Vector2(0.0, CAR_DIAGONAL_ANCHOR_Y)
		_:
			return Vector2.ZERO

## The car's own along-track length and across-track width for the shadow capsule below — fixed
## constants rather than read off a texture. This used to take the side view's own width for the
## along measurement and the end view's for the across one straight off `CAR_BODY[1]`/`CAR_BODY[0]`;
## the side view (`car_side_body.svg`) is still 52px wide and still that same along-track
## measurement, and 30px is the same across-track measurement the old end view carried, now pinned
## here directly. Reading it off a texture again would mean reading it off one of the five standing
## views' own width, which no longer has to agree with this number the way the old two-slot table's
## did by construction — pinning it is what stops a binding a picture cannot resize.
const CAR_SHADOW_ALONG := 52.0
const CAR_SHADOW_ACROSS := 30.0

## A car's own shadow shape — a capsule along its travel axis, sized from `CAR_SHADOW_ALONG`/
## `CAR_SHADOW_ACROSS` rather than a hand-picked radius: `radius` is half the across measurement and
## `half_length` is what is left of half the along once the two end caps are accounted for.
##
## **No body for a car.** A car's lethality is `TrafficIndex`'s, not a field's, and a `StaticBody2D`
## here would change the crowd's own collision rules rather than only how it looks — see
## docs/EVENTS.md and the **crowd-traffic** skill on why separation between bodies is positional,
## never a shape a car could get pinned against. This shape exists for the shadow alone.
static func _car_shadow_shape() -> GroundShape:
	var radius := CAR_SHADOW_ACROSS * 0.5
	return GroundShape.segment(CAR_SHADOW_ALONG * 0.5 - radius, radius)

## Which way this car is travelling, on the ground plane — the axis its shadow's capsule sweeps
## along. `_vertical` is the same flag `_frame()` reads to choose which standing view to draw.
func _travel_axis() -> Vector2:
	return Vector2.DOWN if _vertical else Vector2.RIGHT

## `_travel_axis()`, read by `DebugLayers` so its shadow layer rotates a car's capsule the same way
## `_draw_body()` already does, rather than a second guess at which axis this agent is travelling
## along.
func travel_axis() -> Vector2:
	return _travel_axis()

## The drop shadow under this agent's own `shape`, skipped for its own halo ring — the same rule
## `EventInstance._draw_shape_shadow` has, for the same reason: the shadow is the ground under the
## thing, not the thing, and a cue for what is charging her right now has nothing to say about it.
func _draw_shape_shadow(canvas: CanvasItem, shape: GroundShape, at: Vector2, axis: Vector2) -> void:
	if canvas == _halo:
		return
	shape.draw_shadow(canvas, at, axis)

## The caret's own answer for this car, 0 (none), 1 (amber) or 2 (doubled red), cached against
## `_clock` for the same reason `EventInstance._caret_strength()` caches against `age`: `_draw()`
## and `_process()`'s own redraw-forcing check below both ask in the same frame, and each is a
## fresh sampling loop over `expected_impact_at()` or `will_be_lethal()` if they do not share one.
var _mark_strength_clock := -1.0
var _mark_strength := 0

func _caret_strength() -> int:
	if _mark_strength_clock == _clock:
		return _mark_strength
	_mark_strength_clock = _clock
	_mark_strength = 0
	if player_at != Vector2.INF:
		if will_be_lethal(player_at):
			_mark_strength = 2
		elif expected_impact_at(player_at) >= Tuning.EXPECTED_IMPACT_POINTS:
			_mark_strength = 1
	return _mark_strength

## The caret over a car, in the same two strengths `EventInstance` draws.
##
## The vocabulary's first row is *the entity itself carries most of it*, and the traffic is the
## easiest place to leave that undone: the caret is drawn by `EventInstance` and a car is not an
## event, so without this a lethal thing bearing down on the player produces a mark over **her**
## head and nothing anywhere else — the load-bearing cue paying for a warning it should only be
## adding to.
##
## **The honk is a consequence of this, not the rule it follows.** `Crowd._horn()` still sounds and
## still startles — that is what makes the jolt in `swell` below real noise on a real body — but a
## car projected onto her without ever coming close enough to trigger `_horn()`'s own tighter
## proximity gate is marked all the same: a car whose lane she is standing in is projected into
## her, on its current course, whether or not it has honked yet.
##
## Doubled and in `MARK_LETHAL` exactly when `will_be_lethal()` says the strike box reaches her,
## because a car is exactly as lethal as a `hard_fail` event and being told apart by hue is what
## the doubling exists to avoid. **Breathes with the horn's own decay while one is running** —
## the one thing a ring does that a discrete symbol does not get for free — and holds full size
## the rest of the time, since a projected approach with no jolt running has no envelope of its
## own to breathe with.
func _draw_mark() -> void:
	var strength := _caret_strength()
	if strength <= 0:
		return
	var swell := (_jolt / _jolt_for) if _jolt > 0.0 else 1.0
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	var colour := Palette.MARK_LETHAL if strength == 2 else Palette.MARK_COSTLY
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, colour)
	if strength == 2:
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, colour)

## The coat, or the paintwork. Authored near-white and multiplied, the same trick the
## buildings use, so a crowd is not one silhouette in one colour ninety times over.
func _colour() -> Color:
	var palette := Palette.CAR_PAINT if kind == Kind.CAR else Palette.COATS
	return palette[_rng.randi_range(0, palette.size() - 1)]
