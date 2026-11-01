class_name LaneMover
extends Node2D
## The lane movement a walker and a car share, with none of what makes it a member of the crowd.
##
## Movement is lane-following, not pathfinding. A mover belongs to one corridor lane at a time,
## advances along it, and steers toward the lane's centre rather than being pinned to it — which is
## what lets a walker round a corner without teleporting a half-tile sideways when it changes lane.
##
## **A walker and a car are one mover with two strategies.** What both kinds share — the lane state,
## the look-ahead, the held step, placement and recycling, the junction and queue questions, the
## heading and the velocity — is here, and never asks which kind it is; what only one kind does is
## its `strategy`, a `WalkerStrategy` or a `CarStrategy` that `kind` installs (`LaneStrategy` says
## what it is asked). The per-frame inputs `Crowd` writes for the cars and for the walkers at a door
## are fields of the mover the crowd hands them to.
##
## **The mover has no picture, no excitement and no halo.** `CrowdAgent` is the crowd member built on
## it: it adds the field it contributes to the baby's meter, the halo and caret that warn of it, and
## the drawing, and answers six hooks that do nothing here: `_entry_picture_clearance()`, beside the
## placement code that asks it, and at the foot of this file `_kind_installed()`,
## `restart_the_picture()`, `advance_the_picture()`, `_dress()` and `_end_the_frame()`.

enum Kind { WALKER, CAR }

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
## in the middle of the junction is what `WalkerStrategy._can_turn_here` is for.
const LOOKAHEAD := (Tuning.STREET_WIDTH + 1) * Tuning.TILE_SIZE
## The same distance in tiles, for the scans that walk rather than probe. See `_way_is_blocked`.
const LOOKAHEAD_TILES := Tuning.STREET_WIDTH + 1
## Which kind of agent this is. Setting it installs that kind's `strategy`, at construction or on a
## hand-built agent afterwards, so the agent has that kind's rules from then on. Setting the kind
## it already has changes nothing: a fresh strategy would drop a walker's hold on a hut without
## letting go of it.
var kind := Kind.WALKER:
	set(value):
		if value == kind and strategy:
			return
		kind = value
		_install(CarStrategy.new(self) if value == Kind.CAR else WalkerStrategy.new(self))
		_kind_installed()
## What only this agent's kind does on the lanes — `WalkerStrategy` or `CarStrategy`, installed by
## `kind`. Everything here that differs between a walker and a car asks it. See `LaneStrategy`.
var strategy: LaneStrategy

## This agent's own ground shape, set once in `setup()`: a point for a walker, a capsule along the
## travel axis for a car (`CarStrategy.shadow_shape()`). Read for the shadow and the debug view;
## there is no body for either. It is the noise (and the shadow) a car makes, not what it hits:
## `will_be_lethal()`'s strike box (the front half of the body, `Tuning.CAR_STRIKE_HALF_LENGTH` and
## `CAR_STRIKE_HALF_WIDTH`) is the lethal rectangle, since lethal is not noise (M61).
var shape: GroundShape

## The box this agent lives in, held by reference and moved by `Crowd`. Leaving the box is what
## recycles an agent — not leaving the map. See `CrowdField`.
var field: CrowdField

## What the screen shows, held by reference and handed in by `Crowd` — the camera the stretch's
## recycling keeps out of sight of, and the box `CrowdAgent` draws within. Null for an agent built by
## hand, which then has no camera to be out of view of and no screen to be off. See `CrowdView`.
var view: CrowdView = null

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
## walker crosses unless its own `WalkerStrategy.DoorAnswer` is to turn back.
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
## the same shape `junction_hold` already is — see `CarStrategy._give_way()` for why the two, and the zebra's
## own stop line, all compose by taking the lowest speed rather than each owning a brake.
var gate_hold := INF

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

## The speed this agent wants to be doing. A car brakes toward 0 for a crossing somebody is
## waiting at and accelerates back to `_cruise` afterwards; walkers never use it.
var _cruise := 60.0
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

## Stepped on the physics tick, inside the crowd's own (`step()`), so it is drawn interpolated
## between two ticks as she and the events are, and moves as smoothly as they do on a screen drawing
## faster than thirty frames a second. It inherits the setting from `City`'s shared, y-sorted
## `Entities` node it is added under (`City.add_entity()`). Placed before it enters the tree, so the
## first frame draws it where it stands rather than gliding in from the origin; every later jump is
## reset where it is made (`_recycle()`, `WalkerStrategy._emerge_from_the_hut()`).
func _ready() -> void:
	reset_physics_interpolation()

## On its map's list of moves (`WorldMap.moves`) while it is in the world, so a pass over every
## mover's proposal sees it.
func _enter_tree() -> void:
	if _map:
		_map.moves.join(_move, position)

func _exit_tree() -> void:
	if _map:
		_map.moves.leave(_move)

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

## Takes its kind's ground shape (`shape`), and the reach round its centre its move carries for
## whoever gives way or is given way to (`MoveProposal.radius`): once, at either setup, a rolled
## morning's or a pinned actor's.
func _take_the_shape() -> void:
	shape = strategy.ground_shape()
	_move.radius = shape.reach()

## Constructs a pinned actor through the same initial lane eligibility as a rolled morning.
## The cross coordinate must already be the lane center; authoring never snaps a placement.
func setup_at(agent_kind: int, map: CityMap, crowd_field: CrowdField, seed_value: int,
		at: Vector2, direction: Vector2, speed: float) -> String:
	kind = agent_kind as Kind
	_take_the_shape()
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
	_dress()
	return ""

func setup(agent_kind: Kind, map: CityMap, crowd_field: CrowdField, seed_value: int,
		axis_roll: float) -> void:
	kind = agent_kind
	_take_the_shape()
	_map = map
	field = crowd_field
	_rng.seed = seed_value
	# A placement starts the picture's own state afresh (a walker's stride at rest), which keeps a
	# placement deterministic for a given seed, the same reason `Stroller.reset_at()` zeroes
	# `_walk_phase` for a new day.
	restart_the_picture()
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
		# precinct's own bollards ever do. More draws is the same "retry is not a guarantee" trade
		# as above, carried far enough that the small decision keeps up with how narrow it can get.
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
	_dress()

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
## either side, a car's length and more by default, `ENTRY_PICTURE_ROOM`) is inside the square
## `CrowdView.beyond_every_view()` describes. The camera is the crowd's `view`; with none, or with
## the agent out of the tree — a rig that steps agents by hand — the played day's radius answers.
func _beyond_every_view(at: Vector2, room := ENTRY_PICTURE_ROOM) -> bool:
	if view == null or not is_inside_tree():
		return at.distance_to(field.looking_at()) > Tuning.OUT_OF_SIGHT
	return view.beyond_every_view(at, room, field.looking_at())

## How far past a body's centre its picture may reach, for `_beyond_every_view()`: two tiles, more than
## a car's half length and its shadow.
const ENTRY_PICTURE_ROOM := 2.0 * Tuning.TILE_SIZE

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

## What this agent counts its draws to (`CrowdAgent._draw()`), handed in by the `Crowd` that makes
## it; none for an agent built by hand. Its step times nothing of its own: it runs inside the
## crowd's physics tick, which is timed once (see `CrowdTiming`).
var frame_timing: CrowdTiming = null

## One physics tick of this agent's motion: its clocks, steering, look-ahead, turning, gait and
## recycling, and the crowd member's own end of the tick. `Crowd` runs it for every agent at the end
## of its own physics tick (`Crowd._step_the_agents()`), after the traffic is spaced out and she is
## met (the order a drawn frame ran them in before), so the motion and every rule about it run one to one on every machine, at 30Hz with a 1/30s
## `delta`, and every clock here (the about-face's stride, a walker's sidestep, yield and hut, a
## car's give-way, turn wait and bob, the excitement's jolt) ends on a tick (minty-dolphin #866).
## The node is drawn interpolated between two ticks (see `_ready()`). A rig steps the whole crowd
## with `Crowd.step()`; a suite may step one agent by hand.
func step(delta: float) -> void:
	# The stride an about-face owes its new heading, run down here rather than where it is spent, so
	# that a body held at a gate or stopped behind a queue works it off too. See `_turn_round()`.
	_turn_back_hold = maxf(0.0, _turn_back_hold - delta)
	# The kind's own start of the frame: a walker's sidestep and yield clocks; a car's bob, its
	# give-way, and the arc it may be following, which is the whole of its frame while it is on one.
	# It also ends the frame for a body held where it stands — a walker inside a checkpoint hut, a
	# car a pocket has caught — recycled, if it has to be, by the kind's own rule.
	if strategy.begin_frame(delta):
		_end_the_frame(delta)
		return
	# **Proposed, checked, then committed** (`MoveProposal`, the world's shape for every mover's
	# step): the along and cross step proposed from where it stands, given way to the movers that
	# keep their course (`LaneStrategy.give_way_on_the_step()`, the map's `SeparationPass`), held out
	# of a tile its body may not stand on, and only then is it where it stands, so everything after —
	# the look-ahead, the recycling, the kind's own end of the step — acts on the committed pose.
	var stood_on := _map.world_to_tile(position)
	_propose_the_step(delta)
	strategy.give_way_on_the_step(delta)
	_keep_out_of_a_body(stood_on)
	position = _move.commit()
	strategy.after_the_step(delta)
	_look_ahead()
	if field.has_stretch() and _walks_off_the_stretch() and _out_of_view():
		_recycle()
		_end_the_frame(delta)
		return
	# A closed tile within reach, or for a car a parked figure in its lane (inbox #909 in freckled-moose): the same
	# turn round either way.
	if _blocked_in <= _acts_within or strategy.blocked_by_a_figure():
		strategy.divert(delta)
	# A car with no road either way goes when nobody is looking, which is the rule a body a pocket
	# has caught already follows. It is the same situation read off the lane instead of off the
	# junction — see `LaneStrategy.nowhere_to_turn`.
	if _has_left_the_field() or (strategy.nowhere_to_turn and _out_of_view()):
		_recycle()
	_end_the_frame(delta)

## Its move this tick (`MoveProposal`), its own, on its map's list of moves (`WorldMap.moves`) while
## it is in the world: a crowd body's, the one kind that gives way (`MoveProposal.yields`), reaching
## as far round its centre as its ground shape does (set in `setup_at()`).
var _move := MoveProposal.new(true)

## **Puts its move where it stands, after something outside its step has moved it**: a car carried
## along a turn (`CarStrategy._follow_the_turn()`), a walker pushed by her bump (`Crowd._bump()`).
## Its own setters (`_set_along()`, `_set_cross()`) and a placement taken back already do, so outside
## a step its move is always where it stands.
func place_its_move() -> void:
	_move.place(position)

## Proposes the tick's step from where it stands (`_move`): along its lane at its kind's pace, and
## across toward its lane's centre and any detour at `STEER_SPEED`.
func _propose_the_step(delta: float) -> void:
	_move.propose(position)
	var along := _along() + strategy.paced(_speed) * _direction * delta
	var cross := move_toward(_cross(), _lane_centre + _detour, STEER_SPEED * delta)
	_move.to = Vector2(cross, along) if _vertical else Vector2(along, cross)

## **The check on its proposed step**: keeps an agent's own centre out of a tile it may not stand on,
## when the step proposed (`_move.to`) would carry it in. `stood_on` is the tile it was on before
## that step.
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
	var now := _map.world_to_tile(_move.to)
	if now == stood_on or strategy.may_stand_on(now) or not strategy.may_stand_on(stood_on):
		return
	_hold_inside_the_tile(stood_on, false)
	if strategy.may_stand_on(_map.world_to_tile(_move.to)):
		return
	_hold_inside_the_tile(stood_on, true)

## Pulls one axis of the proposed step back inside the tile band this agent started the step in. A
## pixel short of the far edge, the same fencepost `_recycle` gives up so a clamp cannot land exactly
## on the line and read as the next tile along.
func _hold_inside_the_tile(stood_on: Vector2i, along_axis: bool) -> void:
	var band := stood_on.y if (_vertical == along_axis) else stood_on.x
	var low := float(band * Tuning.TILE_SIZE)
	var on_y := _vertical == along_axis
	var held := clampf(_move.to.y if on_y else _move.to.x, low,
			low + float(Tuning.TILE_SIZE) - 1.0)
	if on_y:
		_move.to.y = held
	else:
		_move.to.x = held

## How fast it is actually going, for the strike test. A car that has stopped for a crossing
## cannot run anybody over.
func speed() -> float:
	return _speed

## How fast and which way it is actually travelling, for anything predicting where it will be.
##
## **A walker held at a checkpoint is travelling at nothing**, which is what makes the stopped pose
## come out right for free: `WalkerLook.gait_frame()` and `WalkerLook.sector()` both read this, so a
## walker standing in a door's line holds its last facing and frame the way every stopped walker
## in the crowd already does, and its own field stops being stretched forward by `Field.scale()`.
##
## **A body a pocket has caught reads the same way**, through `CarStrategy._pocket_factor()`: it is not going
## anywhere either, so its field is a plain falloff rather than one stretched forward, and its
## projected impact and expected approach both answer "nowhere" the way a stopped body's should.
func velocity() -> Vector2:
	return strategy.paced_velocity(heading() * _speed)

## True while travelling along a vertical corridor. What decides whether two cars at the same
## junction are crossing each other's path or merely queueing behind one another.
##
## **Read off the heading rather than off the lane while a car is in a turn**, because mid-turn
## there is no lane to read and the question is about the path: a car that has swung past the
## diagonal is across the traffic it was queueing with. It ties to the axis it came in on,
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
	return GiveWay.junction_at(CityMap.junction_index(tile_along), _corridor, _vertical)

## The junction this agent is coming to, whether or not it is in it yet.
func junction_ahead() -> Vector2i:
	return GiveWay.junction_at(GiveWay.box_index(_along(), _direction), _corridor, _vertical)

## Distance from this agent's nose to the near edge of that box. Negative once it is inside.
func distance_to_junction() -> float:
	return GiveWay.distance_to_box(_along(), _direction, _nose)

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

## Stands it at `value` along its lane, outside the step's own move, so its move stands there too
## (`place_its_move()`).
func _set_along(value: float) -> void:
	if _vertical:
		position.y = value
	else:
		position.x = value
	_move.place(position)

## Stands it at `value` across its lane, outside the step's own move, so its move stands there too
## (`place_its_move()`).
func _set_cross(value: float) -> void:
	if _vertical:
		position.x = value
	else:
		position.y = value
	_move.place(position)

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
## two frames and `WalkerLook.gait_frame()` carries it through both of them over half a turn of
## `WalkerLook.gait_phase`, which `WalkerLook.GAIT_RATE` prices at 0.09 radians per pixel walked — so a
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
	# asking them here would recycle a car on the deck of the bridge, which is wrong.
	if at < 0.0 or at > limit:
		return false

	# `field.along_bounds(_vertical)` built inline from the world size already held: `field.map` is
	# the map every agent is set up with (`Crowd` makes the one field and hands it to all of them).
	var here: float = field.centre.y if _vertical else field.centre.x
	var bounds := Vector2(maxf(0.0, here - field.radius), minf(limit, here + field.radius))
	if _direction > 0.0:
		return at > bounds.y or at < bounds.x - ENTRY_SPREAD
	return at < bounds.x or at > bounds.y + ENTRY_SPREAD

## How far this mover's drawn picture reaches past `_along()`, along its axis, which a placement must
## leave inside the map. A mover with no picture needs none; `CrowdAgent` answers for what it draws.
func _entry_picture_clearance() -> float:
	return 0.0

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
		reset_physics_interpolation()
		return
	var legal: Array = []
	for _attempt in 6:
		_choose_lane(_rng.randf())
		var bounds := field.along_bounds(_vertical)
		# The roll itself is kept inside this kind's own room rather than rolled the full
		# `ENTRY_SPREAD` and rejected afterwards — see `entry_room()`. Beside a plain edge
		# `bounds.x`/`bounds.y` is already the field's own clamped edge, so a `reach` capped at
		# `bounds.x + entry_room()` (or the mirror on the other side) can never carry `back` past
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
	# `entry_room()` — nothing at all for anybody but the spine's own car, which is already
	# standing somewhere real — so this branch is for a miss `_stands_on_a_street` refuses for a
	# reason the room does not reach: a closed segment, a soft seal, a body already standing there.
	# Pulled onto the map's own last row or column here, the one lane still guaranteed to exist,
	# because `cannot_go_on` refuses the very step that would drift it back onto the street on its
	# own.
	if not _stands_on_a_street():
		var extent := _map.world_size()
		var limit: float = extent.y if _vertical else extent.x
		# `limit` itself is one past the last tile's own far edge, the same fencepost
		# `world_to_tile` always floors away — so the clamp's own top has to give up a whole
		# pixel or it can land exactly on the line and read as out of bounds again.
		_set_along(clampf(_along(), 0.0, limit - 1.0))
	# A recycle is a jump, so the drawing starts again from where it landed rather than being
	# interpolated across the map from where it left (see `_ready()`).
	reset_physics_interpolation()

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
	_move.place(at)

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
## **A check on the landed point, not a prediction of the band**: the roll itself is kept inside
## `entry_room()` — see the `reach` computed in `_recycle()`'s loop, capped at
## `bounds.x + entry_room()` (or the mirror) rather than rolled the full `ENTRY_SPREAD` and
## rejected afterwards. That makes this trivially true for anything the clip already reached, which
## is the point: it is a stated invariant rather than a silent assumption, and it is what
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

# ------------------------------------------------------------------- hooks ---
# What a mover leaves to the crowd member built on it: the picture it keeps, the clocks only a crowd
# member has, and what it wears. Each does nothing here.

## Takes up whatever else depends on the kind, once `kind` has installed its strategy.
func _kind_installed() -> void:
	pass

## Starts the picture's own state afresh for a placement: a walker's stride at rest.
func restart_the_picture() -> void:
	pass

## Advances the picture's own state by the ground this tick covered — a walker's stride, a car's
## bob. Asked by the strategies at the point of the frame where their kind advances it.
func advance_the_picture(_delta: float) -> void:
	pass

## What this mover wears, chosen from its own `_rng` at the end of a placement.
func _dress() -> void:
	pass

## Ends every frame that is not skipped, once: the crowd member runs its clocks down by `delta` and
## redraws what changed in its picture, answering whether it asked for a redraw. A hook rather than
## two, because each hook is a call every agent pays every frame.
func _end_the_frame(_delta: float) -> bool:
	return false
