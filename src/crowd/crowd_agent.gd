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
##
## **A walker and a car are one mover with two strategies.** What both kinds share — the lane
## state, the look-ahead, the held step, placement and recycling, the junction and queue questions,
## the heading and the velocity — is here, and never asks which kind it is; what only one kind does
## is its `strategy`, a `WalkerStrategy` or a `CarStrategy` that `kind` installs (`LaneStrategy`
## says what it is asked). The per-frame inputs `Crowd` writes for the cars and for the walkers at a
## door stay here, as fields of the agent the crowd hands them to.

enum Kind { WALKER, CAR }

## The walker's five authored views, keyed by name rather than by sector — `WALKER_VIEW_BY_SECTOR`
## below does the sector-to-view lookup, so drawing never repeats an eight-way if-chain of its
## own to get here. All five share one 18x38 canvas and one (9, 38) feet anchor (see
## `docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`); body is tinted per walker, trim is
## drawn untinted above it — see `_draw_body()`.
##
## Paths rather than `preload()`d textures: the milestone's whole point is that a picture baked
## into `assets/atlases/baked/crowd.png` is not also resident as its own loaded resource.
## `_region_of()` is what turns one of these into the name `AtlasLibrary.region()` and
## `native_size()` actually take.
const WALKER_BODY_BY_VIEW := {
	"front": "crowd/walker_front_body",
	"back": "crowd/walker_back_body",
	"side": "crowd/walker_side_body",
	"front_diagonal": "crowd/walker_front_diagonal_body",
	"back_diagonal": "crowd/walker_back_diagonal_body",
}
const WALKER_TRIM_BY_VIEW := {
	"front": "crowd/walker_front_trim",
	"back": "crowd/walker_back_trim",
	"side": "crowd/walker_side_trim",
	"front_diagonal": "crowd/walker_front_diagonal_trim",
	"back_diagonal": "crowd/walker_back_diagonal_trim",
}
## The walker's second gait frame, feet passing — the mother's own `_b` pose for each view. Only
## the legs and shoes differ from the tables above; the coat stays put in the three-quarter views
## and lifts a pixel in front/back/side, exactly the correction the mother's own frames needed
## (`docs/DECISIONS.md`, "Eight-direction style transfer"). Kept as separate `_b`-suffixed files
## beside the unsuffixed frame-a sources rather than renaming those into `_a`, so nothing that
## already points at `walker_front_body.svg` and so on has to change.
const WALKER_BODY_BY_VIEW_B := {
	"front": "crowd/walker_front_body_b",
	"back": "crowd/walker_back_body_b",
	"side": "crowd/walker_side_body_b",
	"front_diagonal": "crowd/walker_front_diagonal_body_b",
	"back_diagonal": "crowd/walker_back_diagonal_body_b",
}
const WALKER_TRIM_BY_VIEW_B := {
	"front": "crowd/walker_front_trim_b",
	"back": "crowd/walker_back_trim_b",
	"side": "crowd/walker_side_trim_b",
	"front_diagonal": "crowd/walker_front_diagonal_trim_b",
	"back_diagonal": "crowd/walker_back_diagonal_trim_b",
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
## `CAR_VIEW_BY_SECTOR` above does the sector lookup. Three layers per view on one canvas and one
## anchor: the body, tinted per car; the trim, glass and lamps, untinted above it; and the wheels,
## untinted above both, which stay on the ground while the body and trim ride `_body_bob()` — see
## `_draw_body()`. Front/back are 30x46, side is 52x30, the diagonals are 52x42.
## `car_end_{body,trim}.svg`, the old two-view family's foreshortened top-down picture, is read by
## none of the three tables — see `docs/GRAPHICS.md` for where it stands now.
const CAR_BODY_BY_VIEW := {
	"front": "crowd/car_front_body",
	"back": "crowd/car_back_body",
	"side": "crowd/car_side_body",
	"front_diagonal": "crowd/car_front_diagonal_body",
	"back_diagonal": "crowd/car_back_diagonal_body",
}
const CAR_TRIM_BY_VIEW := {
	"front": "crowd/car_front_trim",
	"back": "crowd/car_back_trim",
	"side": "crowd/car_side_trim",
	"front_diagonal": "crowd/car_front_diagonal_trim",
	"back_diagonal": "crowd/car_back_diagonal_trim",
}
const CAR_WHEELS_BY_VIEW := {
	"front": "crowd/car_front_wheels",
	"back": "crowd/car_back_wheels",
	"side": "crowd/car_side_wheels",
	"front_diagonal": "crowd/car_front_diagonal_wheels",
	"back_diagonal": "crowd/car_back_diagonal_wheels",
}

## `WALKER_BODY_BY_VIEW`'s (and its five sibling tables') own entry as the `StringName` that
## `AtlasLibrary.region()`/`native_size()` take. The tables hold plain `String`s because a `const`
## `Dictionary` cannot hold a `StringName` literal the type checker will keep, and this is the one
## conversion between the two.
static func _region_of(name: String) -> StringName:
	return StringName(name)

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

## Which kind of agent this is. Setting it installs that kind's `strategy`, at construction or on a
## hand-built agent afterwards, so the agent has that kind's rules from then on.
var kind := Kind.WALKER:
	set(value):
		kind = value
		_install(CarStrategy.new(self) if value == Kind.CAR else WalkerStrategy.new(self))
## What only this agent's kind does on the lanes — `WalkerStrategy` or `CarStrategy`, installed by
## `kind`. Everything here that differs between a walker and a car asks it. See `LaneStrategy`.
var strategy: LaneStrategy
var colour := Color.WHITE

## `--skip crowd`, handed in by the `Crowd` that makes this agent: `_draw()` returns before
## drawing anything.
var skip_draw := false

## `--skip motion`, handed in the same way. `_process` returns before its first line while it is
## set, so this agent's clocks, steering, lookahead, turning, gait and recycling all stand still;
## it is still drawn wherever the day placed it.
var skip_motion := false

## This agent's own ground shape, set once in `setup()`: a point for a walker, a capsule along the
## travel axis for a car (`_car_shadow_shape()`). Read by `_draw_body()` for the shadow; there is
## no body for either — see `_car_shadow_shape()`'s own docstring for why a car gets none, and
## `CAR_STRIKE_HALF_LENGTH`/`CAR_STRIKE_HALF_WIDTH` in `tuning.gd` for the lethal rectangle this
## shape is not: *"lethal != noise"* (the player, 2026-09-10) — this datum is the noise (and the
## shadow) a car makes, `will_be_lethal()`'s strike box (the front half of the body) is what it hits, and this commit
## leaves the body's rectangle exactly where it stands.
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
## segment as wall the way `cannot_go_on` already would. The one carve-out `CityMap.is_held_at`
## does not make on its own: a wall segment and a hard seal's segment are shut outright, but a
## door is a crossing the day's structure means to keep open — a car brakes and queues for the
## gate (`Crowd._stop_for_gates()`) rather than being turned away at the last junction, and a
## walker crosses unless its own `DoorAnswer` is to turn back.
var door_segments := {}

## The segments bordering the home block, the second carve-out `is_held_at` cannot make on its
## own — rebuilt beside `door_segments` from `StreetNetwork.around_blocks(Rect2i(map.home_block,
## Vector2i.ONE))`, the exact set `EventManager.start_day` holds them from for the opposite reason:
## those segments are held only so no catalogue row lands on the home block's own street, never
## because a body stands across it. The home is a notch with one exit, she walks out onto one of
## these every morning, and `held_segments` has no way to say *why* a segment is held — this list
## is the crowd's own answer, the same shape `door_segments` already is.
var home_segments := {}

## Where today's seals have left ground this agent could get into and not out of, or `null` for an
## agent built by hand in a test, which then treats every street as somewhere it can leave. Held by
## reference and shared with the rest of the crowd, since it is a fact about the day's map rather
## than about anybody standing on it — see `CrowdPockets`.
var pockets: CrowdPockets = null

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

## Her current velocity, `Baby.decay_rate()` and `Baby.current_sensitivity()` — see
## `EventInstance`'s own copy of these three fields for what `expected_impact_at()` does with
## them. Defaults answer exactly as this function always did for any caller that has not told this
## agent her actual state.
var player_velocity := Vector2.ZERO
var player_decay_rate := 0.0
var player_sensitivity := 1.0

## The sum of `expected_gross_at()` over every source `ExcitementHalo` is running this frame, told
## once a frame through `set_expected_total_gross()` — `-1.0` (the default) means nobody has, so
## `expected_impact_at()` nets the whole projected decay against this agent alone, exactly as it
## always did. See `EventInstance`'s own copy for the shared arithmetic.
var player_expected_total_gross := -1.0

func set_player_at(at: Vector2, velocity: Vector2 = Vector2.ZERO, decay_rate: float = 0.0,
		sensitivity: float = 1.0) -> void:
	player_at = at
	player_velocity = velocity
	player_decay_rate = decay_rate
	player_sensitivity = sensitivity

## Told once a frame by `ExcitementHalo`, after every live candidate's own `expected_gross_at()`
## has been asked at the same position — see that function's own doc for why the total has to be
## gathered before any one source's share of the decay can be known.
func set_expected_total_gross(total: float) -> void:
	player_expected_total_gross = total

## The checkpoint hut standing in front of this walker right now, or `null` for none — written once
## per frame by `Crowd._hold_walkers_at_doors()`, which owns the geometry, the same shape
## `gate_hold` already is for a car. Null for a car, for an agent built by hand in a test, and on
## every day before the region wall stands.
var door_ahead: WalkerDoorHold = null

## And how far along this walker's own line of travel that hut is, or `INF` for none. Written
## beside `door_ahead` and only ever read together with it.
var door_ahead_along := INF

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

## The sector, flip and third term currently drawn, so a redraw only happens when one of them
## changes. The third is the gait frame for a walker and the body's bob for a car, quantised by
## `CAR_BOB_STEPS_PER_PX` — the two things each kind draws that move without the sector moving.
##
## **This is the quantised half of what the drawing reads, and a car has a continuous half too** —
## `_drawn_heading` below. See `_redraw_if_the_picture_changed()`.
var _picture := Vector3i(-1, -1, -1)
## The live heading a car's picture was last drawn at, quantised by `CAR_HEADING_STEPS` — the other
## half of the redraw key. Always `Vector2i.ZERO` for a walker, whose drawing reads no heading at
## all: its own picture is the sector, the mirror and the gait frame and nothing else.
var _drawn_heading := Vector2i.ZERO
## Whether this car's own caret was up last frame, so it gets one redraw to come off with.
var _was_marked := false
## True while what this agent shows is not being kept current because none of it can be on the
## screen (`DrawnView`), so the first frame it is back in the box redraws it whatever the key says.
var _picture_is_stale := false

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
var _jolt_outer := 0.0:
	set(value):
		_jolt_outer = value
		_widest_jolt_outer = maxf(_widest_jolt_outer, value)

## The widest `_jolt_outer` any agent has carried in this process — it only ever grows, through
## the setter above, however the radius is written. What `silent_beyond()` is stated over, so a
## jolt wider than any `startle()` passes today still counts the moment it exists.
static var _widest_jolt_outer := 0.0

## A distance from any agent beyond which its field is exactly zero: the reach
## `contribution_at()` rejects past, taken over both kinds and the widest jolt there has been.
## `Crowd.excitement_sources_at()` asks it once a sweep and skips a body past it without calling
## into the body at all, which is most of the crowd most of the time.
static func silent_beyond() -> float:
	var outer := maxf(maxf(Tuning.CAR_OUTER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS),
			_widest_jolt_outer)
	return outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)

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

## Seconds this agent has left of the stride it owes its last about-face. See `_turn_round()`.
var _turn_back_hold := 0.0

## Moves itself in `_process`, not on the physics tick, so physics interpolation would draw it
## gliding between two stale tick positions rather than where `_process` actually put it. Set on
## the instance itself rather than inherited from a parent: every agent is added under `City`'s
## shared, y-sorted `Entities` node (`City.add_entity()`), beside the player, who does want her
## own physics-tick motion interpolated.
func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _init() -> void:
	_install(WalkerStrategy.new(self))

## Takes up a kind's strategy, and the three fixed facts of it the crowd reads every frame of every
## agent — the nose, the distance a barrier is acted on at and where the look-ahead is asked from —
## as plain members of this node, since a member read is several times cheaper than asking another
## object.
func _install(rules: LaneStrategy) -> void:
	strategy = rules
	_nose = rules.nose
	_acts_within = rules.acts_within
	_scans_from_its_lane = rules.scans_from_its_lane

## `strategy.nose`, `strategy.acts_within` and `strategy.scans_from_its_lane`, kept here by
## `_install()`.
var _nose := 0.0
var _acts_within := 1
var _scans_from_its_lane := false

## Constructs a pinned actor through the same initial lane eligibility as a rolled morning.
## The cross coordinate must already be the lane center; authoring never snaps a placement.
func setup_at(agent_kind: int, map: CityMap, crowd_field: CrowdField, seed_value: int,
		at: Vector2, direction: Vector2, speed: float) -> String:
	kind = agent_kind as Kind
	shape = strategy.ground_shape()
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	strategy.draw_the_door_answer()
	_vertical = direction.x == 0.0
	_direction = direction.y if _vertical else direction.x
	position = at
	_corridor = CrowdLanes.corridor_at(_cross())
	if _corridor < 0:
		return "actor is outside a street corridor"
	_lane = CityMap.corridor_offset(floori(_cross() / Tuning.TILE_SIZE))
	var offsets := strategy.lane_offsets_at(floori(_along() / Tuning.TILE_SIZE))
	if not _lane in offsets:
		return "actor lane is not available to its kind"
	var problem := strategy.placement_problem()
	if not problem.is_empty():
		return problem
	_lane_centre = _lane_centre_here()
	if not is_equal_approx(_cross(), _lane_centre):
		return "actor must start exactly at lane center %.3f" % _lane_centre
	var range_of_speed := strategy.speed_range()
	_speed = speed if speed >= 0.0 else _rng.randf_range(range_of_speed.x, range_of_speed.y)
	if _speed < range_of_speed.x or _speed > range_of_speed.y:
		return "actor speed is outside its ordinary generation range"
	_cruise = _speed
	if not _stands_on_a_street() or not _within_the_map_with_room_for_its_picture():
		return "actor placement fails ordinary street/body clearance"
	if strategy.is_in_a_pocket():
		return "car placement is in a closed traffic pocket"
	_settle_junction()
	colour = _colour()
	return ""

func setup(agent_kind: Kind, map: CityMap, crowd_field: CrowdField, seed_value: int,
		axis_roll: float) -> void:
	kind = agent_kind
	shape = strategy.ground_shape()
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	# Unlike `_walker_view` above, holding this stale on purpose would cost nothing correct — a
	# fresh walker's stride starting mid-cycle looks the same as one starting at rest for as long
	# as it takes to notice — but resetting it is free and keeps a placement deterministic for a
	# given seed, the same reason `Stroller.reset_at()` zeroes `_walk_phase` for a new day.
	_walker_gait_phase = 0.0
	strategy.draw_the_door_answer()
	# Start somewhere along the field rather than at its edge, or the whole crowd arrives from
	# one side in a wave on the first morning. Re-rolled if it lands somewhere it could not have
	# walked to: behind a barrier, which reads as the barrier being fake, or in the middle of a
	# four-block calm zone, where the corridor it belongs to has been park since generation — or
	# somewhere it could have walked to and could never leave again, which is a pocket.
	#
	# **And if the whole street is wrong, it picks another street.** Re-rolling only the position
	# along a corridor cannot help a car that was given a corridor with nowhere drivable in view — a
	# precinct is three blocks of an otherwise ordinary street, so the corridor keeps its car weight
	# and the *stretch in the field* may be entirely pedestrianised. The position re-rolls below then
	# land among the bollards every time and the last one places it there anyway: a car standing in a
	# precinct, which `tests/test_crowd.gd` asks about by name. **A retry is not a guarantee** — when
	# re-rolling the small decision keeps failing, re-take the big one.
	# The best spot the rolls below have refused so far: open street the agent could never leave
	# again. Preferred over nothing at all, and given back only if no roll finds a street with a way
	# out of it, so that refusing a pocket can never end with somebody standing in a café instead —
	# the fallback that takes whatever the last roll was is the one place a placement can still land
	# inside a body. See `_placement_taken()`.
	var pocketed: Array = []
	var placed := false
	for _street in 4:
		_choose_lane(axis_roll)
		var bounds := field.along_bounds(_vertical)
		# **A held segment can swallow most of a corridor's visible stretch** — a region wall or a
		# hard seal is kept off `held_segments` by the tile, not by a fraction of it, so a field
		# centred close to one narrows the open ground a random draw can land on far more than a
		# precinct's own bollards ever did. More draws is the same "retry is not a guarantee" trade
		# the docstring above already makes, just carried far enough that the small decision keeps
		# up with how much narrower "the small decision" can now be.
		for _attempt in 24:
			_set_along(_rng.randf_range(bounds.x, bounds.y))
			_set_cross(_lane_centre)
			if not _stands_on_a_street():
				continue
			# `bounds` is already clamped flush to the true edge near one, and this roll asks no
			# room question the way `_recycle()`'s own entry band does — so beside a wall a walker
			# or a car can roll close enough that its picture, not just its centre, sits past the
			# true edge on the very first morning. See `_entry_picture_clearance()`.
			if not _within_the_map_with_room_for_its_picture():
				continue
			if not strategy.is_in_a_pocket():
				placed = true
				break
			if pocketed.is_empty():
				pocketed = _placement_taken()
		if placed:
			break
		# A fresh axis roll, or the second attempt at a car is the first attempt again: the roll
		# the caller passed is a *fixed* alternation for walkers, so re-using it re-picks the same
		# axis and, in a field with one drivable corridor, very often the same corridor.
		axis_roll = _rng.randf()
	if not placed and not pocketed.is_empty():
		_take_the_placement(pocketed)
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
## exception `cannot_go_on()` makes: a walker placed out there would find every direction blocked
## and go nowhere, which is worse than the retry `_recycle` already has to make anyway.
func _stands_on_a_street() -> bool:
	var tile := _map.world_to_tile(position)
	if _segment_is_shut(tile):
		return false
	# Nothing today has put down here, for this kind: no closure, no soft seal for a walker, and
	# nobody starts the day inside a solid body, whichever kind they are and whichever lane of a
	# footway it happens to be on: an agent placed inside one is a body standing in a café, and the
	# sidestep that carries a walker round a body it is *approaching* has nothing to open a gap it
	# is already in — separation between bodies is positional and never a force.
	if not _map.passable(tile, strategy.today):
		return false
	if not _map.in_bounds(tile):
		return strategy.may_stand_off_the_map(tile)
	# And this kind's own clause: no precinct paving for a car, no carriageway for a walker.
	if not strategy.may_be_placed_on(tile):
		return false
	return _map.is_street(tile)

## Whether this agent is far enough from the camera that taking it away cannot be seen.
##
## **`CrowdField.centre` is the camera.** `Crowd._physics_process()` puts it on the player every
## frame and a rig puts it wherever it is looking, so the distance from it is the distance from the
## middle of the screen — and `Tuning.OUT_OF_SIGHT` (420px) is the round number outside the
## viewport's own far corner at this zoom, which is what *nothing vanishes while you are looking at
## it* has always been measured against.
##
## The field's own edge is nowhere near this: it is 800px out, so an agent recycled for leaving the
## box is out of sight several hundred pixels over. This is for the one recycle that happens
## somewhere the player may well be standing — a pocket — and it is the whole of what makes that
## legal.
func _out_of_view() -> bool:
	if not field:
		return true
	if field.has_stretch():
		return _beyond_every_view(position)
	return position.distance_to(field.looking_at()) > Tuning.OUT_OF_SIGHT

## **On a stretch, the camera's own view, in both presentations, with a body's room round it.** A
## stretch's ends are often in the picture — the street runs into the void a few tiles from her — so
## the radius a played day recycles beyond is not enough: nothing may appear or vanish where she can
## see it *(the player's rule, PR #597)*. True when no part of a body standing at `at` (`room`
## either side, a car's length and more by default, `ENTRY_PICTURE_ROOM`) is inside a square
## centred where the camera looks, as wide and as tall as the larger side of the design box at the
## camera's zoom (640x640 world pixels at zoom 2). That is stricter than the real view: both
## presentations show the same 640x360 world, a portrait touch screen turning it a quarter
## (`ScreenOrientation.apply_to_camera()`), so the square holds a margin above and below it. With
## no camera — a rig that steps agents by hand — the played day's radius answers.
func _beyond_every_view(at: Vector2, room := ENTRY_PICTURE_ROOM) -> bool:
	var camera := get_viewport().get_camera_2d() if is_inside_tree() else null
	if not camera:
		return at.distance_to(field.looking_at()) > Tuning.OUT_OF_SIGHT
	var size := Vector2(maxf(ScreenOrientation.DESIGN_SIZE.x, ScreenOrientation.ROTATED_SIZE.x),
			maxf(ScreenOrientation.DESIGN_SIZE.y, ScreenOrientation.ROTATED_SIZE.y)) / camera.zoom
	var offset := (at - camera.get_screen_center_position()).abs()
	return offset.x > size.x * 0.5 + room or offset.y > size.y * 0.5 + room

## How far past a body's centre its picture may reach, for `_beyond_every_view()`: two tiles, more than
## a car's half length and its shadow.
const ENTRY_PICTURE_ROOM := 2.0 * Tuning.TILE_SIZE

## Everything this agent's own drawing can cover, relative to its position — what
## `_redraw_if_the_picture_changed()` asks `DrawnView` about. `ENTRY_PICTURE_ROOM` either side, and
## above that a car's doubled caret at its tallest (`_draw_mark()`): the upper chevron's top stands
## `MARK_HEIGHT + 10 + 1.65 × MARK_WIDTH` above the node, about 65px, with its outline's width on top.
const DRAWN_REACH := Rect2(-ENTRY_PICTURE_ROOM, -(MARK_HEIGHT + 10.0 + MARK_WIDTH * 1.65 + 4.0),
		ENTRY_PICTURE_ROOM * 2.0, MARK_HEIGHT + 10.0 + MARK_WIDTH * 1.65 + 4.0 + ENTRY_PICTURE_ROOM)

## Whether a tile's own street segment is shut to this agent the way a hard blocker is: held for
## today (`CityMap.is_held_at` — a hard seal's segment, a region wall, a closure, or the streets
## around the home block) and neither of the two carve-outs `held_segments` cannot make on its
## own. A region door is a crossing anybody may still enter — a car brakes and queues for the gate
## rather than turning away, and so does a walker unless its own answer is to turn back. The home
## block's own bordering streets are held only so no catalogue row lands there, never because a body stands
## across one — she walks out onto one of them every morning, and the home is a notch with one exit,
## so sealing it would seal her in. Both lists are empty outside a real day (a hand-built test agent,
## a rig with no city, or before the wall itself stands), which is a harmless no-op: nothing is held
## then either.
##
## Whether a hold shuts the street is the kind's (`LaneStrategy.shut_by_a_hold`): a car is turned
## away a junction before the body that stands across it, a walker walks up to the body itself. A
## door's carve-out is per walker (`WalkerStrategy.door_is_shut()`).
func _segment_is_shut(tile: Vector2i) -> bool:
	if not _map.is_held_at(tile):
		return false
	var segment := StreetNetwork.segment_containing(tile)
	if segment == null:
		return strategy.shut_by_a_hold
	var key := segment.key()
	if home_segments.has(key):
		return false
	if door_segments.has(key):
		return strategy.door_is_shut(key)
	return strategy.shut_by_a_hold

## Whether the frame record (`FrameRecord`) was running when this agent was made, read once here
## so that, with the record off, `_process()` pays one member read rather than a static read and a
## call into a second function: with two hundred or so agents a frame, that difference made every
## player's frame measurably longer on a desktop (docs/evidence/m159-frame-record-2026-10-04/). An
## agent is made per day, after the recorder has started, so every one made under a record is timed.
var _timed := FrameRecord.on
## True while `_process()` runs its own body inside the record's timing, so the call it makes to
## itself is the body rather than another round of timing.
var _timing := false

func _process(delta: float) -> void:
	# The record's timing, when this agent was made under one and it is still running: the body
	# below runs inside it through the call to itself. See `_timed`.
	if _timed and not _timing and FrameRecord.on:
		var outer := FrameRecord.enter(FrameRecord.CROWD)
		_timing = true
		_process(delta)
		_timing = false
		FrameRecord.leave(outer)
		return
	# `--skip motion`'s own probe (docs/DECISIONS.md, M140, "the crowd's scripts parked"): returns
	# before anything below runs, so this agent stands exactly where the day placed it — no clock,
	# steering, lookahead, turn, gait or recycle. It is still drawn; see `_draw()`'s own `skip_draw`.
	if skip_motion:
		return
	_clock += delta
	_jolt = maxf(0.0, _jolt - delta)
	# The stride an about-face owes its new heading, run down here rather than where it is spent, so
	# that a body held at a gate or stopped behind a queue works it off too. See `_turn_round()`.
	_turn_back_hold = maxf(0.0, _turn_back_hold - delta)
	# The kind's own start of the frame: a walker's sidestep and yield clocks; a car's bob, its
	# give-way, and the arc it may be following, which is the whole of its frame while it is on one.
	# It also ends the frame for a body held where it stands — a walker inside a checkpoint hut, a
	# car a pocket has caught — recycled, if it has to be, by the kind's own rule.
	if strategy.begin_frame(delta):
		_redraw_if_the_picture_changed()
		return
	var stood_on := _map.world_to_tile(position)
	_set_along(_along() + strategy.paced(_speed) * _direction * delta)
	_set_cross(move_toward(_cross(), _lane_centre + _detour, STEER_SPEED * delta))
	_keep_out_of_a_body(stood_on)
	strategy.after_the_step(delta)
	_look_ahead()
	if field.has_stretch() and _walks_off_the_stretch() and _out_of_view():
		_recycle()
		_redraw_if_the_picture_changed()
		return
	if _blocked_in <= _acts_within:
		strategy.divert(delta)
	# A car with no road either way goes when nobody is looking, which is the rule a body a pocket
	# has caught already follows. It is the same situation read off the lane instead of off the
	# junction — see `LaneStrategy.nowhere_to_turn`.
	if _has_left_the_field() or (strategy.nowhere_to_turn and _out_of_view()):
		_recycle()
	_redraw_if_the_picture_changed()

## Keeps an agent's own centre out of a tile it may not stand on, when the step it has just taken
## would have carried it in. `stood_on` is the tile it was on before that step.
##
## **A brake and a sidestep are both approaches, and an approach arrives late.** A car easing toward
## a blockage overshoots by whatever the last frame's speed bought it, and a walker crossing to the
## other lane of its footway is still half way over when it draws level with a café's first table —
## so neither can *promise* that nothing ever stands inside a body, however well it is tuned.
## Holding the step is the promise, and it is the same shape `nudge_back()` already has for the
## backward direction: separation between bodies is positional, never a force.
##
## **The cross step is given up first and that ordering is load-bearing.** Giving up both at once
## wedges a walker crossing a pavement beside a body for good: its steering target does not move, so
## the same step is refused on every frame after. Undoing only the sideways half leaves it walking
## along the street beside the body and crossing once it is past — which is what a person does. The
## along half is given up only when there is nowhere legal left at all, and an agent already
## standing somewhere it may not be is left alone, since there is nothing there to preserve.
func _keep_out_of_a_body(stood_on: Vector2i) -> void:
	var now := _map.world_to_tile(position)
	if now == stood_on or strategy.may_stand_on(now) or not strategy.may_stand_on(stood_on):
		return
	_hold_inside_the_tile(stood_on, false)
	if strategy.may_stand_on(_map.world_to_tile(position)):
		return
	_hold_inside_the_tile(stood_on, true)

## Pulls one axis back inside the tile band this agent started the frame in. A pixel short of the
## far edge, the same fencepost `_recycle` gives up so a clamp cannot land exactly on the line and
## read as the next tile along.
func _hold_inside_the_tile(stood_on: Vector2i, along_axis: bool) -> void:
	var band := stood_on.y if (_vertical == along_axis) else stood_on.x
	var low := float(band * Tuning.TILE_SIZE)
	var held := clampf(_along() if along_axis else _cross(), low,
			low + float(Tuning.TILE_SIZE) - 1.0)
	if along_axis:
		_set_along(held)
	else:
		_set_cross(held)

## Asks for a redraw when what this agent is showing has actually changed, and answers whether it
## asked.
##
## Moving a Node2D does not invalidate its draw list — the transform is applied when it is
## replayed — so an agent only redraws when its picture actually changes. At this population that
## is the difference between five hundred redraws a frame and a handful.
##
## **And only while any of it can be on the screen** (`DrawnView`, `DRAWN_REACH`). Most of the
## crowd is off screen, and those agents were most of the redraws and every car's caret projection;
## the key is still kept every frame, so nothing about the picture's own state depends on where the
## camera is, and an agent coming back into the box redraws once on that frame whatever the key says.
##
## **A term missing from the key is a frozen picture rather than a crash**, the same rule
## `EventInstance._redraw_if_the_picture_changed()` states for the catalogue's own gate — so the key
## has to name every time-varying thing `_draw_body()` reads and not a plausible subset. A walker's
## drawing is the sector, the mirror and the gait frame, all three quantised and all three above. A
## car's third term is its body's bob instead (`_body_bob()`), which moves on every frame it is
## driving while nothing else about a car in a lane does. **A car's drawing also reads its live
## heading, twice**: `_car_body_anchor()` registers the picture
## `26·|heading.y| + 14·|heading.x|` south of the node, and `_draw_shape_shadow()` sweeps the
## capsule along the same heading. Both are continuous through an arc while the sector is not, so a
## key made only of the quantised half leaves a car that has turned wearing the anchor and the
## shadow axis it last had at a sector boundary — up to 22.5 degrees back, which lands an east- or
## west-bound car's picture about nine pixels south of its own body and keeps it there for the
## rest of its run in that lane, since nothing about the quantised picture ever changes again. The
## rim does not go with it: `EntityHalo` re-traces the body every frame it is drawn, so the halo
## stands where the car should be and the car does not. That is exactly what the player saw.
func _redraw_if_the_picture_changed() -> bool:
	var third: int
	var view: int
	if kind == Kind.WALKER:
		# One `velocity()` serves the gait and the sector: the same value `_walker_gait_frame()` and
		# `_walker_heading()` would each have computed, nothing between them moves it.
		var along := velocity()
		third = _walker_gait_frame_at(along)
		_walker_view = EightDirection.update(_walker_view, _walker_heading_at(along),
				WALKER_IDLE_SPEED)
		view = _walker_view
	else:
		# One `velocity()` serves the bob and the sector, the same value `_body_bob()` and
		# `_update_car_view()` would each have computed.
		var moving := velocity()
		third = roundi(WheelBob.lift(_car_travelled, moving.length() / CAR_BOB_FULL_SPEED)
				* CAR_BOB_STEPS_PER_PX)
		_car_view = EightDirection.update(_car_view, moving, CAR_IDLE_SPEED)
		view = _car_view
	var picture := Vector3i(view, 1 if _flipped() else 0, third)
	var drawn_heading := _drawn_heading_key()
	var changed := picture != _picture or drawn_heading != _drawn_heading
	_picture = picture
	_drawn_heading = drawn_heading
	# Off screen nothing is redrawn and no caret is projected (`DrawnView`): the picture is left as
	# it was, and the first frame any of it is back inside the box redraws it from what it is now,
	# caret included, which is before the margin has let any of it onto the screen.
	if not DrawnView.shows(self, DRAWN_REACH):
		_picture_is_stale = true
		return false
	if changed or _picture_is_stale:
		_picture_is_stale = false
		# What this redraw puts up is the mark as it stands now — the same answer `_draw()` asks
		# for, cached against the clock — so a mark that drops on the next frame is taken off.
		_was_marked = kind == Kind.CAR and _caret_strength() > 0
		queue_redraw()
		return true
	# A marked car draws a caret that can breathe with its own horn, and a projected approach
	# can change its strength frame to frame with nothing else about the picture moving. The
	# one frame after the mark comes down is what takes the caret off again.
	if kind == Kind.CAR and (_caret_strength() > 0 or _was_marked):
		_was_marked = _caret_strength() > 0
		queue_redraw()
		return true
	return false

## How finely the redraw key reads a car's own live heading: each component of the unit vector to
## the nearest hundred-and-twenty-eighth. That is at most 1/256 of error per component, so the
## anchor it decides — `26·|heading.y| + 14·|heading.x|`, whose steepest term is the 26 —
## can be held back by at most `(26 + 14) / 256`, about a sixth of a world pixel, and the shadow
## capsule's own axis by about a quarter of a degree. Nothing a screen can show at any zoom the game
## uses is ever frozen waiting for a step.
##
## **A car in a lane costs nothing for it.** `heading()` there is exactly `(±1, 0)` or `(0, ±1)` —
## built from `_direction` rather than integrated from a float — so the key is the same value every
## tick and no redraw is asked for, which is the whole of what the gate is for. Only the seconds a
## car is actually on an arc pay, and that is a handful of cars on the busiest street.
const CAR_HEADING_STEPS := 128.0

## The continuous half of the redraw key — see `_redraw_if_the_picture_changed()`. A walker answers
## `Vector2i.ZERO` and means it: nothing in the walker branch of `_draw_body()` reads a heading, so
## there is no continuous term for its own key to carry.
func _drawn_heading_key() -> Vector2i:
	if kind != Kind.CAR:
		return Vector2i.ZERO
	return Vector2i((heading() * CAR_HEADING_STEPS).round())

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
## **Not cached the way `EventInstance.contribution_at()` now is.** *(docs/DECISIONS.md, M124:
## per-frame audit.)* A per-`_clock` cache was tried and reverted: unlike an event, whose own
## motion and telegraph state only ever change inside its own `_process()` alongside `age`, a
## crowd agent's position and jolt are written from **outside** it — `Crowd._bump()` and
## `Crowd._horn()` call `startle()` and move an agent mid-tick, from `Crowd`'s own step rather than
## this agent's `_process()` — so a cache keyed on `_clock` could answer with the jolt or the
## position from before the bump that tick, the one frame a fresh startle is supposed to show up
## on. `tests/test_crowd.gd`'s own `_test_walking_into_somebody_displaces_and_startles_them` reads
## `contribution_at()` again immediately after a bump with `_clock` unmoved and expects the fresh
## jolt, which is exactly the case a clock-keyed cache would have answered stale.
##
## **Nothing reaches her through a building**, the same rule an event's field keeps: a positive
## field is zero when `_walled_off()` says a building stands between this body and the point. The
## horn and a startled walker included — *(plaid-wombat, inbox #554: "Excitement should not go
## through any wall")* — since the jolt is this body being louder, not a second source. `walls`
## false answers the field alone, which is what the caret's projection asks before it asks about
## walls at the two bodies' own projected places. One function rather than a field function called
## from this one: every body in the crowd is asked this every frame, most of them out of reach, and
## a second call each is a cost paid by the whole crowd for the handful a wall could matter to.
func contribution_at(world_position: Vector2, walls := true) -> float:
	# d_eff = r * (1 - e * cos(theta)) is at least r * (1 - e_max), at every speed
	# and heading. Outside this bound both falloffs are zero, so the common distant-body
	# case needs no velocity/turn/pocket lookup or elliptical distance calculation. Read the
	# current jolt each time: a horn or an external bump can extend its reach between queries.
	var outer := Tuning.CAR_OUTER_RADIUS if kind == Kind.CAR else Tuning.PEDESTRIAN_OUTER_RADIUS
	if _jolt > 0.0:
		outer = maxf(outer, _jolt_outer)
	var reach := outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)
	var origin := global_position
	if origin.distance_squared_to(world_position) > reach * reach:
		return 0.0
	var distance := GroundShape.eccentric_distance(origin, velocity(), world_position)
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
	if walls and total > 0.0 and _walled_off_now(origin, world_position):
		return 0.0
	return total

## Whether a building stands between this body at `body_at` and her at `her_at`, deep enough to
## keep its noise from her — `CityMap.wall_between()`, as `EventInstance._walled_off()` asks it.
## False with no map, which is every data-level rig built without one.
func _walled_off(body_at: Vector2, her_at: Vector2) -> bool:
	return _map != null and _map.wall_between(body_at, her_at)

## The grid `_walled_off()` asks, the city's map or `null` — read by the debug view's fields layer,
## which cuts this body's outline from its own position along the same lines
## (`DebugLayers.open_runs()`).
func wall_grid() -> CityMap:
	return _map

## The last line `contribution_at()` asked about and its answer, kept by value. The meter's sum,
## the halo's pick and the caret's present rate ask the same pair in a frame, and the answer
## depends on nothing but the two points and the map — a body moved from outside is a new key, so
## nothing here can answer stale the way a clock-keyed cache of the field would.
var _wall_from := Vector2.INF
var _wall_to := Vector2.INF
var _wall_map: CityMap = null
var _wall_answer := false

## `_walled_off()` through that one-line cache, for `contribution_at()` alone: the caret's
## projection asks a different pair at every step and would only push the frame's own pair out.
func _walled_off_now(body_at: Vector2, her_at: Vector2) -> bool:
	if body_at != _wall_from or her_at != _wall_to or _map != _wall_map:
		_wall_from = body_at
		_wall_to = her_at
		_wall_map = _map
		_wall_answer = _walled_off(body_at, her_at)
	return _wall_answer

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

## One bounded integral cache per source; effective inputs include externally written state.
var _expected_landed_key: Array = []
var _expected_landed_cache := 0.0

## The gross points this agent is anticipated to land over `Tuning.EXPECTED_IMPACT_HORIZON` if she
## and it both carry on exactly as they are, before her own decay is netted against it —
## `EventInstance.expected_gross_at()`'s own quantity, read here off `velocity()` instead of
## `travel_velocity()`. See that method for the full reasoning, `player_velocity`/
## `player_sensitivity` included; the reach test below skips anything the pair's own closing speed
## cannot cross inside the horizon without sampling it. Floored at zero, the same as the net it
## feeds: a source she is outrunning has nothing to share with the others `ExcitementHalo` is
## summing this frame.
func expected_gross_at(player_position: Vector2) -> float:
	var vel := velocity()
	var closing := player_velocity - vel
	var reach := closing.length() * Tuning.EXPECTED_IMPACT_HORIZON + _current_reach()
	if global_position.distance_to(player_position) > reach:
		return 0.0
	if vel.is_zero_approx() and player_velocity.is_zero_approx():
		return 0.0
	var current_rate := contribution_at(player_position)
	# Velocity includes turns, yielding, door holds and pockets. Read it and every jolt value
	# afresh: the crowd can move/startle this body without advancing its own clock.
	var key := [global_position, player_position, player_velocity, vel, kind,
		_jolt, _jolt_for, _jolt_intensity, _jolt_inner, _jolt_outer]
	if key != _expected_landed_key:
		_expected_landed_cache = _sample_expected_landed(player_position, vel)
		_expected_landed_key = key
	var gross := _expected_landed_cache - current_rate * Tuning.EXPECTED_IMPACT_HORIZON
	return maxf(gross * player_sensitivity, 0.0)

## The future samples alone are reusable; current contribution, sensitivity and the net's
## shared decay are still evaluated for each request. Tuning inputs are immutable constants.
func _sample_expected_landed(player_position: Vector2, vel: Vector2) -> float:
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var integral := 0.0
	for i in steps:
		# The field translates; a wall does not. So the wall is asked between the two bodies'
		# own projected places, where a building actually stands, never at the translated point.
		var t := float(i + 1) * dt
		var rate := contribution_at(player_position + player_velocity * t - vel * t, false)
		if rate > 0.0 and _walled_off(global_position + vel * t, player_position + player_velocity * t):
			rate = 0.0
		integral += rate * dt
	return integral

## The net points this agent is anticipated to add to the bar over `Tuning.EXPECTED_IMPACT_HORIZON`
## — `expected_gross_at()` less her own decay over the same horizon.
##
## **Shared with every other source worth a mark when `ExcitementHalo` is driving the frame,
## charged against this agent alone otherwise.** `player_expected_total_gross` is `-1.0` for any
## caller that has not told this agent the frame's total — a data-level test among them — and the
## decay nets whole against this agent exactly as it always did; `ExcitementHalo` sets it once a
## frame to the sum of every live candidate's own `expected_gross_at()`, and this agent's own share
## of the decay then follows `ExcitementHalo.net_landed()`'s own arithmetic, forward instead of
## back — see `EventInstance.expected_impact_at()`'s doc for why summing that share across every
## source it was taken from reproduces the bar's own projected rise exactly, not approximately.
func expected_impact_at(player_position: Vector2) -> float:
	var gross := expected_gross_at(player_position)
	if gross <= 0.0:
		return 0.0
	var decay := player_decay_rate * Tuning.EXPECTED_IMPACT_HORIZON
	if player_expected_total_gross >= 0.0:
		return ExcitementHalo.net_landed(gross, player_expected_total_gross, decay)
	return maxf(gross - decay, 0.0)

## Whether this car's own strike box reaches her at some point before
## `Tuning.EXPECTED_IMPACT_HORIZON`, on its current course, her position held fixed — a car's
## equivalent of `EventInstance.will_be_lethal()`, over the same rectangle `Crowd._strike()` tests
## for the actual collision: the car's front half, from its centre forward. Never true for a
## walker: nothing about a pedestrian ends the day, and never true for a car already too slow to strike at all (`Crowd._strike()`'s own guard).
func will_be_lethal(player_position: Vector2) -> bool:
	if kind != Kind.CAR or _speed < Tuning.CAR_STRIKE_MIN_SPEED:
		return false
	var vel := velocity()
	var forward := heading()
	var side := Vector2(-forward.y, forward.x)
	var offset := player_position - global_position
	if absf(offset.dot(side)) > Tuning.CAR_STRIKE_HALF_WIDTH:
		return false
	# The box is the car's front half, 26px long, and a fast car covers more than that between
	# two samples, so the question is answered on the line rather than by stepping: the car
	# closes on her at `closing` px/s along its heading, and she is struck when the distance
	# ahead of its centre falls into [0, CAR_STRIKE_HALF_LENGTH] within the horizon.
	var ahead := offset.dot(forward)
	if ahead < 0.0:
		return false
	var closing := vel.dot(forward)
	if closing <= 0.0:
		return ahead <= Tuning.CAR_STRIKE_HALF_LENGTH
	return (ahead - Tuning.CAR_STRIKE_HALF_LENGTH) / closing <= Tuning.EXPECTED_IMPACT_HORIZON

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
## instead of draining over `EntityHalo.FADE_OUT_SECONDS`. See `EntityHalo`'s class doc for the web
## renderer's ceiling that this lifetime, and `ExcitementHalo`'s budget, keep under.
func set_halo_strength(strength: float, colour: Color) -> void:
	if strength <= 0.0:
		if _halo:
			_halo.set_glow(0.0, colour)
			if _halo.is_faded_out():
				release_halo()
		return
	if not _halo:
		_halo = EntityHalo.new(_draw_body, _body_bob)
		add_child(_halo)
	_halo.set_glow(strength, colour)

## Whether this agent holds a rim right now, lit or still fading — what `ExcitementHalo` counts
## against `EntityHalo.RIM_BUDGET`.
func holds_a_halo() -> bool:
	return _halo != null

## Frees the rim on the spot rather than through `queue_free()`, so its block in the web renderer's
## instance buffer is free before any rim built later this frame asks for one — see
## `EntityHalo.release()`. The same pair `EventInstance.release_halo()` is.
func release_halo() -> void:
	if _halo:
		EntityHalo.release(_halo)
		_halo = null

## The lift this agent's body rides right now, the `bob()` `EntityHalo` asks every owner for: a
## walker's is zero, since its stride is two frames rather than a lift; a car's is `WheelBob.lift()`
## over the ground it has covered, at full height from `CAR_BOB_FULL_SPEED` up and fading to
## nothing as it slows, so a car braking to a light settles onto its wheels rather than freezing
## mid-rise, and a stopped car sits still. `_draw()` lifts the whole drawing by it and
## `_draw_body()` draws the wheels and the shadow back down by it, which is what lets the halo's
## ring ride the same lift and trace the body where it is drawn.
func _body_bob() -> float:
	if kind != Kind.CAR:
		return 0.0
	return WheelBob.lift(_car_travelled, velocity().length() / CAR_BOB_FULL_SPEED)

## The speed a car's bob reaches its full height at: a car in a turn and every car cruising down a
## lane bob fully, and only a car braking below it settles.
const CAR_BOB_FULL_SPEED := Tuning.CAR_TURN_SPEED

## How finely the redraw key reads a car's bob: a quarter of a world pixel, half a screen pixel at
## the camera's zoom. A car in a lane changes nothing else about its picture from one frame to the
## next, so this is the step it redraws on while it is moving, and a stopped one never does.
const CAR_BOB_STEPS_PER_PX := 4.0

## Advances `_car_travelled` by the ground this car covered this tick. Called once from
## `_process()`, never from the drawing, which a halo ring calls several times a frame — the same
## rule `_advance_walker_gait()` states for the walker's stride.
func _advance_car_bob(delta: float) -> void:
	_car_travelled = wrapf(_car_travelled + velocity().length() * delta, 0.0, WheelBob.WAVELENGTH)

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
##
## **A walker held at a checkpoint is travelling at nothing**, which is what makes the stopped pose
## come out right for free: `_walker_gait_frame()` and `_update_walker_view()` both read this, so a
## walker standing in a door's line holds its last facing and frame a the way every stopped walker
## in the crowd already does, and its own field stops being stretched forward by `field_scale()`.
##
## **A body a pocket has caught reads the same way**, through `_pocket_factor()`: it is not going
## anywhere either, so its field is a plain falloff rather than one stretched forward, and its
## projected impact and expected approach both answer "nowhere" the way a stopped body's should.
func velocity() -> Vector2:
	return strategy.paced_velocity(heading() * _speed)

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

## The junction this agent's **body** is standing in, or `(-1, -1)`. Nose and tail, not the
## centre: a car is 52px long against a 192px box, so half a length of it is still in the way
## after its middle has left.
##
## The end nearer the lattice's origin is asked first and the other second, each written out
## rather than looped over, since `Crowd.give_way_at_junctions()` asks every car this once a
## physics tick and a loop over the pair would build an array to walk every time.
func junction_occupied() -> Vector2i:
	var half := _nose
	var along := _along()
	var tile_along := floori((along - half) / float(Tuning.TILE_SIZE))
	if CityMap.corridor_offset(tile_along) < 0:
		tile_along = floori((along + half) / float(Tuning.TILE_SIZE))
		if CityMap.corridor_offset(tile_along) < 0:
			return Vector2i(-1, -1)
	var index := CityMap.junction_index(tile_along)
	return Vector2i(_corridor, index) if _vertical else Vector2i(index, _corridor)

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
	return (near - _along()) * _direction - _nose

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
func lane_key() -> int:
	return make_lane_key(_vertical, _corridor, _lane, _direction)

## The same key for a lane this agent is not in yet, which is what a car needs to ask whether the
## arm it is about to turn into has anybody in it.
##
## **An integer, packed from the four parts** (`_LANE_KEY_SLOTS` values each for the corridor and the
## lane, one bit for the axis and two for the direction), because the key is built several times
## for every car every tick and a formatted string was the largest single cost of the queue resolve.
## Two lanes share a key exactly when the string version of it matched: the parts are offset so
## that a corridor or lane of -1 (none) packs without colliding with a real one.
static func make_lane_key(vertical: bool, corridor: int, lane: int, direction: float) -> int:
	return (((corridor + 1) * _LANE_KEY_SLOTS + lane + 1) * 2 + (1 if vertical else 0)) * 4 \
			+ signi(int(direction)) + 1

## How many lanes (and so how many corridors) the packed key tells apart; both are far fewer.
const _LANE_KEY_SLOTS := 64

## The four parts a packed lane key was made from, in `make_lane_key()`'s argument order, for a
## suite that stands a car in the lane a key names. The direction comes back as -1, 0 or 1.
static func lane_key_parts(key: int) -> Array:
	var direction := key % 4 - 1
	var rest := key / 4
	var vertical := rest % 2 == 1
	rest /= 2
	return [vertical, rest / _LANE_KEY_SLOTS - 1, rest % _LANE_KEY_SLOTS - 1, direction]

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
## building's own footprint by one tile. `cannot_go_on` is the same predicate `_look_ahead` already
## trusts for the *forward* direction, asked here for the backward one, tile by tile from the car's
## own — **walked rather than sampled at the target**, since a nudge of a car's length is two tiles
## and a probe at its end looks straight past a one-tile barrier between.
##
## **A nudge that meets blocked ground goes as far as the ground allows and stops there**, a pixel
## short of the blocked tile, rather than being refused whole. A refusal is not a smaller correction,
## it is a deferred one: the pair stays inside each other, and the overlap is paid in a single jump
## on whichever later frame the leader has pulled far enough ahead for the full target to be legal.
## That frame is chosen by nobody, so it can be in front of her, and on the morning it is the one
## thing the resolve in `Crowd.start_day()` exists to prevent: a car placed in a stub of road with a
## barrier behind it unpacked on the second frame instead of before the first. Going as far as the
## ground allows leaves the same pair as close as it can legally be, on the frame the overlap arose,
## and nothing is left over to settle later.
func nudge_back(distance: float) -> void:
	# **Never a car in a turn.** Sliding one back down its entry lane takes it off the arc it is
	# following, which is the separation pass repairing a manoeuvre — and a manoeuvre that needs
	# repairing is one that should not have been started. The room a turn lands in is checked and
	# held before the car commits; whoever ended up too close to it is nudged instead.
	if _turn or distance <= 0.0:
		return
	_set_along(_furthest_back_towards(_along() - distance * _direction))

## How far back down its own lane toward `target` this car may slide without its centre crossing
## onto a tile `cannot_go_on` refuses — `target` itself when every tile on the way is road, a
## pixel short of the first blocked one otherwise, and where it already stands when the tile it is
## on is refused too, since an agent already standing somewhere it may not be is left alone rather
## than dragged further through it.
func _furthest_back_towards(target: float) -> float:
	var here := _map.world_to_tile(position)
	if strategy.cannot_go_on(_vertical, here):
		return _along()
	var probe := Vector2(_cross(), target) if _vertical else Vector2(target, _cross())
	var goal := _map.world_to_tile(probe)
	var step := Vector2i(0, -signi(int(_direction))) if _vertical \
			else Vector2i(-signi(int(_direction)), 0)
	var tile := here
	while tile != goal:
		var next := tile + step
		if strategy.cannot_go_on(_vertical, next):
			# The edge of the last good tile on the side the car is sliding toward.
			var band := tile.y if _vertical else tile.x
			var low := float(band * Tuning.TILE_SIZE)
			return low if _direction > 0.0 else low + float(Tuning.TILE_SIZE) - 1.0
		tile = next
	return target

## Somebody she walked into gets out of her way — a walker's answer (`WalkerStrategy.step_aside()`);
## a car does not get out of anybody's way, since the carriageway is hers to stay off.
func step_aside(away: Vector2, distance: float, seconds: float) -> void:
	strategy.step_aside(away, distance, seconds)

## Drops any sidestep. A detour is a distance across *this* corridor, so it means nothing once the
## agent has changed corridor, changed lane, or swapped its axes at a junction.
func _forget_the_detour() -> void:
	_detour = 0.0
	strategy.forget_the_detour()

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

## Picks a corridor, a lane in it, a direction and a speed — the kind's own roll
## (`LaneStrategy.choose_lane()`: a car picks its axis by weight, a walker splits it evenly, and
## `roll` decides the axis for the even split, so a caller can spread a crowd evenly across both).
## Only the corridors the field actually reaches: picking from the whole city and then discarding
## what is out of view is the same crowd spread over ten thousand tiles, which is the density
## falling to a third of what the numbers say.
func _choose_lane(roll: float) -> void:
	strategy.choose_lane(roll)
	_cruise = _speed
	_lane_centre = _lane_centre_here()
	_junction = -1
	# A planned turn is about a junction on a corridor this agent is no longer on, and so is the
	# stride an about-face there was still owed.
	_turn = null
	_turn_run_up = 0.0
	_turn_back_hold = 0.0
	_forget_the_detour()

## Where this agent travels in its lane. A car sits on the tile centre; a walker is pushed toward
## the outer edge of its own footway, which is what leaves a gap between the two lanes of a
## pavement worth aiming at. See `CrowdLanes.SIDEWALK_LANE_SPREAD`.
func _lane_centre_here() -> float:
	return strategy.lane_centre_here()

## The tile `distance` away along an axis, from this agent or from `from`.
func _tile_ahead(vertical: bool, direction: float, distance: float, from: Vector2) -> Vector2i:
	var origin := position if from == Vector2.INF else from
	var offset := Vector2(0.0, direction * distance) if vertical \
			else Vector2(direction * distance, 0.0)
	return _map.world_to_tile(origin + offset)

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
##
## **Where it is asked from is the kind's** (`LaneStrategy.scans_from_its_lane`): a car asks from its
## lane centre and a walker from its body.
func _look_ahead() -> void:
	var here := _map.world_to_tile(CarTurn.world(_vertical, _along(), _lane_centre)) \
			if _scans_from_its_lane else _map.world_to_tile(position)
	if here == _scan_at and _vertical == _scan_vertical and _direction == _scan_direction:
		return
	_scan_at = here
	_scan_vertical = _vertical
	_scan_direction = _direction
	strategy.on_new_scan(here)
	_blocked_in = LOOKAHEAD_TILES + 1
	var step := (Vector2i.DOWN if _vertical else Vector2i.RIGHT) * int(signf(_direction))
	for i in range(1, LOOKAHEAD_TILES + 1):
		# A stretch's street goes on into the void as far as anybody on it knows: out of her view the
		# agent walks to its end and leaves the scene there (`_walks_off_the_stretch()`). In her view
		# the end is a wall like any other — a walker turns round at it and a car turns off before
		# it or waits — since nothing may vanish where she can see it.
		var ahead := here + step * i
		if _map.is_cut_off(ahead) and _beyond_every_view(_map.tile_to_world(ahead)):
			break
		if strategy.cannot_go_on(_vertical, here + step * i):
			_blocked_in = i
			return
	strategy.on_the_road_clear()

## Turns an agent round where it stands: a dead end, a barrier at a mouth, a precinct's paving.
##
## **A car changes lane with it** (`CarStrategy.on_turned_round()`): a lane is one side of a
## carriageway, and which side depends on the way it is pointing.
##
## **And it costs a stride.** The decision that calls this is taken again on the very next frame
## from the very next scan, so an agent with a seal at each end of the ground it is on reverses on
## *every* frame: `_look_ahead()` re-scans the moment
## the direction changes, finds the other seal, and `divert()` turns it round again. At sixty
## frames a second that is not pacing, it is a body facing two ways at once — the flicker playtest
## 66 reported, and it is a defect whether or not the agent has anywhere to go. So a reversal is
## refused while the last one is still being walked off (`_stride_seconds()`), and what the agent
## does instead is keep walking the way it has just turned; the step that would carry it into the
## seal is held by `_keep_out_of_a_body()` the way any illegal step is.
func _turn_round() -> void:
	if _turn_back_hold > 0.0:
		return
	_turn_back_hold = _stride_seconds()
	_direction = -_direction
	_forget_the_detour()
	strategy.on_turned_round()

## How long one stride of this body takes at the speed it cruises at, in seconds — the unit an
## about-face commits its new heading for.
##
## **A stride is a distance, and each kind already has one.** A walker's is the gait's own: it draws
## two frames and `_walker_gait_frame()` carries it through both of them over half a turn of
## `_walker_gait_phase`, which `WALKER_GAIT_RATE` prices at 0.09 radians per pixel walked — so a
## stride is `PI / 0.09`, about 35px, and at `Tuning.PEDESTRIAN_SPEED` (46–74px/s) that is half a
## second or so. A car has no gait and its stride is its own length, the same 52px the body is
## measured over, which at `Tuning.CAR_SPEED` (130–185px/s) is about a third of a second.
##
## Stated in seconds rather than as a distance travelled, because the agent this exists for is
## usually **stopped** — nose to a seal, or braked behind one — and a hold measured in pixels covered
## would never expire at all for a body that is not covering any.
func _stride_seconds() -> float:
	return strategy.stride_length() / maxf(_cruise, 1.0)

# ----------------------------------------------------- the arc it follows ---
# A car's turn is an arc it has planned and found room for before it starts (`CarStrategy`); the
# arc lives here, on the mover, because the heading, the queue and the junction box all read it.

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
func turn_lane_key() -> int:
	if not _turn:
		return -1
	return make_lane_key(_turn.exit_vertical, _turn.exit_corridor, _turn.exit_lane,
			_turn.exit_direction)

func turn_landing() -> float:
	return _turn.landing() if _turn else 0.0

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
	# Past the room beyond the map: a tile for everybody but a car on the spine, whose tunnel and
	# bridge carry the road on (`has_left_the_map()`).
	if strategy.has_left_the_map(at, limit):
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

	# `field.along_bounds(_vertical)` built inline from the world size already held: `field.map` is
	# the map every agent is set up with (`Crowd` makes the one field and hands it to all of them).
	var here: float = field.centre.y if _vertical else field.centre.x
	var bounds := Vector2(maxf(0.0, here - field.radius), minf(limit, here + field.radius))
	if _direction > 0.0:
		return at > bounds.y or at < bounds.x - ENTRY_SPREAD
	return at < bounds.x or at > bounds.y + ENTRY_SPREAD

## How far this kind's own drawn picture reaches past `_along()`, along this axis, in the
## direction a plain edge lies — read off the baked region's own native size and the same anchor
## arithmetic `_draw_body()`/`_car_body_anchor()` use, not a guessed number, because "the whole
## picture inside the map" means exactly what `_draw_body()` puts on screen. `native_size()`
## answers from the region table with nothing acquired, which matters here: a placement roll in
## `setup()` asks this before `Crowd.start_day()`'s own acquire needs to have happened.
##
## **`entry_room()` grants room past the true edge; this grants none, and states what "none" has
## to mean instead.** A walker or an off-spine car's `entry_room()` is 0.0 — no room *past* the
## line — but a centre sitting exactly on the line still has a picture straddling it, since
## `Sprites.draw_standing` anchors a walker's whole canvas bottom-centred on its own position: the
## height rises entirely to the north of it and nothing at all to the south, so a walker's picture
## overhangs a north edge by its full canvas height and a south edge by nothing. A car's canvas is
## anchored south of its own position by `_car_body_anchor()`'s own reach, so both overhangs are
## real and unequal there too. **The larger of the two is kept for both edges of the axis**, so one
## number clears whichever edge this placement is beside without the caller having to say which —
## conservative on the edge that needed less, never short on the one that needed more. Only the
## cardinal (`front`, `side`) views are asked, since a fresh entry never lands mid-turn.
func _entry_picture_clearance() -> float:
	if kind == Kind.CAR:
		if _vertical:
			var body := AtlasLibrary.native_size(_region_of(CAR_BODY_BY_VIEW["front"]))
			var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH \
					+ float(CAR_CANVAS_BOTTOM_MARGIN["front"])
			return maxf(south_reach, float(body.y) - south_reach)
		var side := AtlasLibrary.native_size(_region_of(CAR_BODY_BY_VIEW["side"]))
		return float(side.x) * 0.5
	var walker := AtlasLibrary.native_size(_region_of(WALKER_BODY_BY_VIEW["front"]))
	return float(walker.y) if _vertical else float(walker.x) * 0.5

## Whether this agent's own coordinate leaves its picture entirely inside the map — the question
## `_entry_band_fits()` and `_keep_within_the_room_beyond_the_map()` both ask once `entry_room()`
## grants no room past the edge at all, and the one `setup()`'s own placement loop asks too: a
## morning roll lands anywhere in the field's box with no room question asked otherwise, and that
## box is already clamped flush to the true edge near one.
func _within_the_map_with_room_for_its_picture() -> bool:
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var clearance := _entry_picture_clearance()
	var at := _along()
	return at >= clearance and at <= limit - clearance

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
## The band itself is kept inside this kind's own room (`entry_room()`) rather than rolled the
## full `ENTRY_SPREAD` and hoped over: near the city wall the box hangs into nothing, and an agent
## rolled into that overhang would walk visibly through the boundary before it reaches the street —
## a walker or an off-spine car has no room out there at all, so its roll never leaves the map, and
## a spine car keeps the same reach it is allowed on the way out. A lane running the other way, or
## on the other axis, is not narrowed at all, so a handful of rolls still settles which one lands
## on a real street.
##
## The entry *point* is rolled inside the same loop and checked too, because a corridor may be park
## for two blocks of its length: a car re-entering there would be standing on grass and would divert
## on the first frame, which is a car appearing in a park and driving out of it.
##
## And it has to be a piece of road **nobody is on**. A recycled car that cannot see the lane it
## lands in leaves the positional resolve to sort it out, which is the resolve doing a placement's
## job. It is only a preference: after six rolls it takes what it has, because an entry band with
## nothing free in it must still put the car somewhere.
##
## **And it has to be somewhere with a way out of it.** A spot inside a pocket — a junction whose
## four arms are all held — is refused exactly the way a spot with no room is, because an agent put
## there walks to one seal, turns, walks to the next and does that until the day ends. That is the
## whole of *"or never spawn in the first place"*; `is_in_a_pocket()` is the question and
## `CrowdPockets` is what answers it without a search per roll.
func _recycle() -> void:
	# The look-ahead is a cached answer about where this agent was standing, and a recycle puts it
	# somewhere else; then the kind's own fresh start (a walker's stride, door and answer).
	_scan_at = Vector2i(-9999, -9999)
	strategy.on_recycled()
	if field.has_stretch():
		# Whatever asked for the recycle — the end of a street, the edge of the field, a pocket —
		# nothing vanishes in her view: in it the agent turns round where it is instead.
		if not _out_of_view():
			_turn_round()
			return
		_enter_at_a_stretch_end()
		return
	var legal: Array = []
	for _attempt in 6:
		_choose_lane(_rng.randf())
		var bounds := field.along_bounds(_vertical)
		# The roll itself is kept inside this kind's own room rather than rolled the full
		# `ENTRY_SPREAD` and rejected afterwards — see `entry_room()`. Beside a plain edge
		# `bounds.x`/`bounds.y` is already the field's own clamped edge, so a `reach` capped at
		# `bounds.x + _entry_room()` (or the mirror on the other side) can never carry `back` past
		# what this kind may stand on, and the near-`ENTRY_SPREAD` band mid-map is untouched because
		# there the cap is never the smaller number.
		var reach := ENTRY_SPREAD
		var beyond := strategy.entry_room(_direction < 0.0)
		if _direction > 0.0:
			reach = minf(reach, bounds.x + beyond)
		else:
			var extent := _map.world_size()
			var limit: float = extent.y if _vertical else extent.x
			reach = minf(reach, limit + beyond - bounds.y)
		var back := _rng.randf() * maxf(reach, 0.0)
		_set_along(bounds.x - back if _direction > 0.0 else bounds.y + back)
		strategy.hide_the_spine_entry()
		_set_cross(_lane_centre)
		if not _entry_band_fits() or not _stands_on_a_street():
			continue
		if not strategy.is_in_a_pocket() and strategy.has_room_here():
			legal = []
			break
		if legal.is_empty():
			legal = _placement_taken()
	if not legal.is_empty():
		_take_the_placement(legal)
	strategy.join_the_back_of_the_queue()
	_settle_junction()
	strategy.claim_the_road_here()
	gap_ahead = INF
	junction_hold = INF
	gate_hold = INF
	_keep_within_the_room_beyond_the_map()
	# The loop above only ever *tries* for `_stands_on_a_street`; six misses in a row near a true
	# edge leave whatever the best roll was. `_keep_within_the_room_beyond_the_map` holds that to
	# `entry_room()` now — nothing at all for anybody but the spine's own car, which is already
	# standing somewhere real — so this branch is for a miss `_stands_on_a_street` refuses for a
	# reason the room does not reach: a closed segment, a soft seal, a body already standing there.
	# Pulled onto the map's own last row or column here, the one lane still guaranteed to exist,
	# because `cannot_go_on` refuses the very step that would once have drifted it back onto the
	# street on its own.
	if not _stands_on_a_street():
		var extent := _map.world_size()
		var limit: float = extent.y if _vertical else extent.x
		# `limit` itself is one past the last tile's own far edge, the same fencepost
		# `world_to_tile` always floors away — so the clamp's own top has to give up a whole
		# pixel or it can land exactly on the line and read as out of bounds again.
		_set_along(clampf(_along(), 0.0, limit - 1.0))

## Whether this agent is about to step off the end of a stretch's street into the void: the tile
## half a tile ahead of it, along its lane, is ground the stretch cut off (`CityMap.is_cut_off()`).
## A wall is not this — a street that ends at a building is turned at as everywhere else. It leaves
## there only out of her view (`_out_of_view()`); in it the end is a wall.
func _walks_off_the_stretch() -> bool:
	var ahead := Vector2(_lane_centre, _along()) if _vertical else Vector2(_along(), _lane_centre)
	ahead += (Vector2.DOWN if _vertical else Vector2.RIGHT) * signf(_direction) * Tuning.TILE_SIZE * 0.5
	return _map.is_cut_off(_map.world_to_tile(ahead))

## **A recycle on a stretch: in at one of its ends, out of her view.** *(azure-beaver, proposed and
## built: "walkers and cars recycled at the stretch's ends".)* The scene's crowd is the street she
## walks and nothing beyond it exists, so an agent that walks off one end comes back in at an end,
## rolled from the field's own ends (`CrowdField.stretch_ends`) that are out of every view
## (`_beyond_every_view()`), heading in: a car on the lane that drives that way, a walker on any
## lane its footway has there, each at its ordinary speed. The same ground and room a recycle
## anywhere asks for are asked here, for a handful of rolls, including the final queue position.
## With no accepted entry, or every end in view, it turns
## round where it is, at the end it left by, which is out of view or it would not have left.
func _enter_at_a_stretch_end() -> void:
	var before := _placement_taken()
	var ends: Array[Dictionary] = []
	for end in field.stretch_ends:
		var along := (float(end.along) + 0.5) * Tuning.TILE_SIZE
		var across := (float(end.corridor) * CityMap.period() + Tuning.STREET_WIDTH * 0.5) \
				* Tuning.TILE_SIZE
		if _beyond_every_view(Vector2(across, along) if end.vertical else Vector2(along, across)):
			ends.append(end)
	if ends.is_empty():
		_turn_round()
		return
	for _attempt in 8:
		var end: Dictionary = ends[_rng.randi_range(0, ends.size() - 1)]
		_vertical = end.vertical
		_corridor = end.corridor
		_direction = end.direction
		var along_tile: int = end.along
		if not strategy.enter_at_an_end(along_tile):
			continue
		_cruise = _speed
		_set_along((along_tile + 0.5) * Tuning.TILE_SIZE)
		_lane_centre = _lane_centre_here()
		_set_cross(_lane_centre)
		_junction = -1
		_turn = null
		_turn_run_up = 0.0
		_turn_back_hold = 0.0
		_forget_the_detour()
		if not _stands_on_a_street() or strategy.is_in_a_pocket() or not strategy.has_room_here():
			continue
		strategy.join_the_back_of_the_queue()
		_settle_junction()
		# The lane can lie nearer the picture than the street's middle, and joining a queue can
		# move it again. Check the final placement, not merely the candidate street end.
		if not _beyond_every_view(position) or not _stands_on_a_street():
			continue
		strategy.claim_the_road_here()
		gap_ahead = INF
		junction_hold = INF
		gate_hold = INF
		return
	# No accepted entry is no teleport. The original point was already off camera; turn there.
	_take_the_placement(before)
	_turn_round()
	strategy.claim_the_road_here()

## The lane and the spot one placement roll settled on, kept so that a later roll which turns out
## worse can be given the earlier one back.
##
## **A roll cannot be replayed, which is why this exists.** `_choose_lane()` draws from `_rng`
## itself — the corridor, the lane within it, the direction and the speed — so calling it again with
## the same argument picks a different lane and moves the stream on. The state it wrote is the only
## copy of that decision there is.
##
## It carries everything `_choose_lane()` writes that a placement depends on. The rest of what that
## function clears — the junction it is standing in, a planned turn, a detour — is the same after
## every roll of one loop, so there is nothing there to put back.
func _placement_taken() -> Array:
	return [_vertical, _corridor, _lane, _direction, _speed, _lane_centre, position]

## Puts back a placement `_placement_taken()` kept. See that function.
func _take_the_placement(taken: Array) -> void:
	_vertical = bool(taken[0])
	_corridor = int(taken[1])
	_lane = int(taken[2])
	_direction = float(taken[3])
	_speed = float(taken[4])
	_cruise = _speed
	_lane_centre = float(taken[5])
	var at: Vector2 = taken[6]
	position = at

## However the rolls above landed, an entry point may not sit further past the map's true edge
## than `entry_room()` allows this kind to arrive at — zero for everybody but a car on the spine —
## and where that is zero, it may not sit closer to the true edge than its own picture needs either.
##
## **`ENTRY_SPREAD` is a car's-length band and every kind shares it**, because the *normal* job of
## a spread is an off-screen buffer inside the box, which every kind wants the same amount of. The
## fallback below it is the trap: the roll above is already kept inside this kind's own room, but a
## `join_the_back_of_the_queue()` retreat or a stale `_placement_taken()` from an earlier attempt
## this frame is not, so this stays the one place that holds the final answer to it regardless of
## how it got there. Without this a walker can appear already standing on the crossing, which is
## the one thing only a car may do.
##
## **A centre sitting exactly on the true edge is not far enough in**, whatever `entry_room()`
## says: the picture is what a player actually sees, and `_entry_picture_clearance()` is how far
## past the coordinate this kind's own picture reaches. So wherever `entry_room()` grants nothing
## past the edge, this clamps inward to that clearance instead of out to the true edge itself.
func _keep_within_the_room_beyond_the_map() -> void:
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var north := strategy.entry_room(false)
	if north <= 0.0:
		var clearance := _entry_picture_clearance()
		_set_along(clampf(_along(), clearance, limit - clearance))
		return
	_set_along(clampf(_along(), -north, limit + strategy.entry_room(true)))

## Whether the entry point the roll above landed on is ground this kind's own room reaches.
##
## **A check on the landed point, not a prediction of the band**, now that the roll itself is
## already kept inside `entry_room()` — see the `reach` computed in `_recycle()`'s loop, capped at
## `bounds.x + _entry_room()` (or the mirror) rather than rolled the full `ENTRY_SPREAD` and
## rejected afterwards. That makes this trivially true for anything the clip already reached, which
## is the point: it stays a stated invariant rather than a silent assumption, and it is still what
## lets a car on the spine in through the tunnel or off the bridge — `entry_room()` grants that
## kind the tunnel's roof depth in the north and the bridge deck's length in the south, so the
## same roll that would refuse anybody else still lands a southbound spine lane beside the north
## edge inside the tunnel.
##
## **Zero room past the edge is not the same question as "does the picture fit."** A centre exactly
## on the true edge satisfies "no room past it" trivially, so where `entry_room()` grants nothing
## past the edge, the roll also has to leave room for the picture on the near side of it —
## `_within_the_map_with_room_for_its_picture()` is that second question.
func _entry_band_fits() -> bool:
	var north := strategy.entry_room(false)
	if north <= 0.0:
		return _within_the_map_with_room_for_its_picture()
	var extent := _map.world_size()
	var limit: float = extent.y if _vertical else extent.x
	var at := _along()
	return at >= -north and at <= limit + strategy.entry_room(true)

# ---------------------------------------------------------------- drawing ---

## The sector each kind is currently drawn in — `EightDirection`'s own indexing, clockwise from
## east — persisted across frames so `_update_walker_view()`/`_update_car_view()` can hold it
## through the boundary and hysteresis `EightDirection.update()` applies. A walker and a car keep
## separate fields because they read different headings: a walker's is `_walker_heading()`'s
## along-plus-cross blend, a car's is `velocity()` alone.
var _walker_view := 2
var _car_view := 2

## A walker's stride, in the same units `Stroller._walk_phase` uses: wrapped 0..TAU, advanced by
## distance actually covered (`_advance_walker_gait()`) rather than by time, so it stays in step
## at any speed the way the mother's own does. Cars have no gait; only a walker reads this.
var _walker_gait_phase := 0.0

## How much ground this car has covered, wrapped to one `WheelBob.WAVELENGTH`, which is the phase
## of the rise and fall its body rides over its wheels. Advanced by distance actually covered
## (`_advance_car_bob()`), once per tick, the same way `_walker_gait_phase` is. A walker never
## reads it.
var _car_travelled := 0.0

## Radians of gait per pixel walked. `Stroller._physics_process()` advances `_walk_phase` at the
## identical rate, so the crowd and the player share one stride length per pixel covered — and
## `_stride_seconds()` reads it back to price a stride as a distance.
const WALKER_GAIT_RATE := 0.09

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
	return _walker_heading_at(velocity())

## `_walker_heading()` for a `velocity()` the caller already holds.
func _walker_heading_at(along: Vector2) -> Vector2:
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

## Advances the walker's stride by how far it actually travelled this tick — `velocity()`, the
## along-lane speed the crowd already stops to zero at a give-way, a queue or a light, the same
## quantity `_current_reach()` and `contribution_at()` read. Called once from `_process()` rather
## than from `_draw_body()`/`_walker_gait_frame()`, which a halo ring calls several times a frame:
## unlike the sector hold above, adding a distance is not idempotent, so it must run once per tick
## or a walker with three halo rings would stride three times as fast as one with none.
## `Stroller._physics_process()`'s own `_walk_phase` uses the identical 0.09 rate, so the crowd and
## the player share one stride length per pixel walked.
func _advance_walker_gait(delta: float) -> void:
	_walker_gait_phase = wrapf(_walker_gait_phase + velocity().length() * delta * WALKER_GAIT_RATE,
			0.0, TAU)

## Which of the walker's two gait frames to draw right now: frame 1 (feet passing) for half of
## every stride while actually moving, frame 0 (the rest pose) otherwise — `Stroller._draw_mother()`'s
## own `stepping` test, read here off `WALKER_IDLE_SPEED` instead of the mother's own small gait
## floor, since a walker already has that threshold for exactly "is this body actually moving".
func _walker_gait_frame() -> int:
	return _walker_gait_frame_at(velocity())

## `_walker_gait_frame()` for a `velocity()` the caller already holds.
func _walker_gait_frame_at(along: Vector2) -> int:
	if along.length() <= WALKER_IDLE_SPEED:
		return 0
	return 1 if sin(_walker_gait_phase * 2.0) > 0.0 else 0

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
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_CROWD)
	# `--skip crowd`'s own probe (docs/DECISIONS.md, M124, "the desktop half", row (d)): returns
	# before anything is drawn, so a frame under the flag differs from an ordinary one by drawing
	# alone — the crowd's own motion, lanes and traffic negotiation keep running. `_draw_body()` is
	# left alone rather than gated itself, since `EntityHalo` calls it too for a picked agent's own
	# ring, which is a different drawing than the ordinary frame this flag measures.
	if skip_draw:
		return
	# Told to `Sprites` as well as to the canvas, for the reason `EventInstance._draw()` gives: the
	# mirror inside `draw_standing()` sets an absolute matrix, so a west-facing car not handed the
	# lift would drop it.
	var bob := _body_bob()
	var lift := Transform2D(0.0, Vector2(0.0, bob))
	Sprites.set_base_transform(lift)
	draw_set_transform_matrix(lift)
	_draw_body(self)
	Sprites.set_base_transform(Transform2D.IDENTITY)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if kind == Kind.CAR:
		_draw_mark()

## Draws this agent's own body onto `canvas`. `EntityHalo` calls this once per ring offset to
## trace whichever silhouette the sprite actually is; the ordinary frame draws it once at self.
##
## **Both callers have already lifted the canvas by `_body_bob()`**, so what stays on the ground —
## a car's wheels and its shadow — is drawn back down by the same amount here, and the body and the
## trim are drawn where the lift puts them. That split is the whole of the bob: the wheels never
## move, the paint and the glass above them rise and fall about a pixel.
##
## **Reads `AtlasLibrary.region()`, which is null with an engine error the moment `crowd` is not
## acquired.** `Crowd.start_day()` acquires it before an agent exists to draw and `Crowd.clear()`
## releases it once every agent is freed, so nothing here has a lifetime of its own to manage —
## see the class doc on `Crowd` for why the owner holds one reference for the whole day rather
## than every agent acquiring for itself.
func _draw_body(canvas: CanvasItem) -> void:
	var frame := _frame()
	var flip := _flipped()
	if kind == Kind.CAR:
		var forward := _travel_axis()
		var grounded := Vector2(0.0, -_body_bob())
		_draw_shape_shadow(canvas, shape, grounded, forward)
		var view: String = CAR_VIEW_BY_SECTOR[frame]
		# The same heading the shadow above and the debug view's bounding box are drawn on, so the
		# picture cannot register against a car that is not there — see `_car_body_anchor()`.
		var anchor := _car_body_anchor(view, forward)
		var body := AtlasLibrary.region(_region_of(CAR_BODY_BY_VIEW[view]))
		var trim := AtlasLibrary.region(_region_of(CAR_TRIM_BY_VIEW[view]))
		var wheels := AtlasLibrary.region(_region_of(CAR_WHEELS_BY_VIEW[view]))
		Sprites.draw_standing(canvas, body, anchor, Vector2.ZERO, flip, colour)
		Sprites.draw_standing(canvas, trim, anchor, Vector2.ZERO, flip)
		# Last, as they were when they were part of the trim: each tyre is drawn over the paint.
		Sprites.draw_standing(canvas, wheels, anchor + grounded, Vector2.ZERO, flip)
		return
	_draw_shape_shadow(canvas, shape, Vector2.ZERO, Vector2.RIGHT)
	var view: String = WALKER_VIEW_BY_SECTOR[frame]
	# One lookup decides both layers, so the coat and the legs can never show two different
	# instants of the same stride.
	var stepping := _walker_gait_frame() == 1
	var body_paths: Dictionary = WALKER_BODY_BY_VIEW_B if stepping else WALKER_BODY_BY_VIEW
	var trim_paths: Dictionary = WALKER_TRIM_BY_VIEW_B if stepping else WALKER_TRIM_BY_VIEW
	var body := AtlasLibrary.region(_region_of(body_paths[view]))
	var trim := AtlasLibrary.region(_region_of(trim_paths[view]))
	# The body is tinted per agent (`colour`, `_colour()`'s "authored near-white and multiplied");
	# the trim above it draws at `Sprites.draw_standing()`'s own default `Color.WHITE` — the split
	# that keeps a crowd from reading as one silhouette in one colour. Two separate baked regions
	# rather than one, so tinting one never touches the other's own pixels.
	Sprites.draw_standing(canvas, body, Vector2.ZERO, Vector2.ZERO, flip, colour)
	Sprites.draw_standing(canvas, trim, Vector2.ZERO, Vector2.ZERO, flip)

## How much empty canvas each authored view leaves below its own drawn content, in px — read off
## `facings.csv`'s alpha bounds (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`, the `car`
## rows): the two diagonals draw to y40 of a 42-tall canvas and front/back to y44 of a 46-tall one,
## while the side view's own content touches the bottom row. The anchor below adds it back, so what
## lands on the ground line is the drawn corner rather than the empty edge above it.
const CAR_CANVAS_BOTTOM_MARGIN := {
	"front": 2.0,
	"back": 2.0,
	"side": 0.0,
	"front_diagonal": 2.0,
	"back_diagonal": 2.0,
}

## Where a car's own body texture is anchored for `Sprites.draw_standing`. `draw_standing` always
## bottom-centres a texture at the point it is given, and every one of the five authored views is a
## standing elevation whose bottom row is the car's **nearest ground contact** — the part of its
## footprint closest to the camera. So there is one registration rule for the whole family, and it
## is stated over the heading rather than per view:
##
## > the drawn content's bottom edge lands on the southernmost point of the car's body.
##
## That body is `Tuning.CAR_STRIKE_HALF_LENGTH` (26) by `CAR_STRIKE_HALF_WIDTH` (14), centred on the
## node and rotated onto the heading, so its southern reach is `26·|heading.y| + 14·|heading.x|` —
## 26 pointed along a vertical lane, 14 along a horizontal one, `(26 + 14)/sqrt(2)` ≈ 28.28 at
## exactly 45 degrees, and every value between while a car is on an arc.
##
## **Read off the live heading rather than off the quantised view, because a turn is continuous and
## the eight views are not.** `EightDirection` swaps the texture at a sector boundary; if the anchor
## swapped with it the body would jump the whole difference between two views' ground lines in one
## frame, which is what a turning car was doing — and the same arithmetic keeps the shadow capsule,
## the debug view's bounding box and the picture travelling together for the whole manoeuvre
## instead of the first two rotating while the third sat still and then leapt. A standing car's
## heading is exactly cardinal, so this is an exact value there and nothing about a car in a lane
## depends on a texture's own axis.
##
## **Because it is read off the heading, the redraw gate has to read the heading too.** This is one
## of the two continuous terms `_redraw_if_the_picture_changed()`'s key carries; keyed on the
## quantised view alone, a car that has turned keeps the anchor it had at the last sector boundary
## and its picture sits south of its own body for the rest of its run.
func _car_body_anchor(view: String, forward: Vector2) -> Vector2:
	var south_reach := Tuning.CAR_STRIKE_HALF_LENGTH * absf(forward.y) \
			+ Tuning.CAR_STRIKE_HALF_WIDTH * absf(forward.x)
	return Vector2(0.0, south_reach + float(CAR_CANVAS_BOTTOM_MARGIN[view]))

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
## along. `heading()` is already continuous — cardinal in a lane, the tangent of its own arc
## mid-turn — so the capsule, and through `travel_axis()` below the debug view's own shadow layer,
## rotates with the turn instead of snapping between two axes at the moment one starts or ends.
func _travel_axis() -> Vector2:
	return heading()

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
