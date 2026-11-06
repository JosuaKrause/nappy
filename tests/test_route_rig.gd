extends RefCounted
## `RouteRig` (`src/dev/route_rig.gd`) is `--route`'s own walker — docs/TODO.md, M184, "A rig
## walks the route" — and `RouteRigPlanner` (`src/dev/route_rig_planner.gd`) is what it asks where
## a target is and how to walk there. This suite asks the planner what the rig asks it, against a
## real `City` in a run of its own, and drives the rig the way `main` does — `setup()`, `start_day()`
## and real physics frames, with a real `Stroller` walking by `move_and_slide()` — reading what the
## rig does from what it presses (`Input`'s move actions) and from the lines it writes in the run
## log (a memory log, `Telemetry.begin_memory_log()`), which is what `tests/probes/m184_route_timing.gd`
## reads a real run back from. The whole loop — resolve, plan, walk, arrive — is proven, and not
## only its pieces (the verify skill: "a rig that steps the parts is not running the whole, and the
## gap is silent both ways").
##
## **Each group of tests has a city of its own, and no test leans on what an earlier one left.**
## The day-6 city is shared by the tests that read it or put back what they change; a test that
## moves the resistance on (a mark completed) builds its own; the door day's city is built once the
## day-6 one is gone, since a real frame steps every city in the tree and two cities built from one
## seed stand their walls on the same ground.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STROLLER_SCENE := preload("res://scenes/player/stroller.tscn")
const ContactTouches := preload("res://tests/contact_touches.gd")
const SEED := 4242
## Day 6, "A chalk mark" — the first task day, and the smallest one whose mark is a pickup step
## rather than null, the same reason `tests/test_dev_rig.gd` picks it for `--spawn contact`.
const DAY := 6
## The seed of the run each city stands in. Which ground the rig's targets resolve to depends on it.
## The checks hold on the seeds tried besides it (1, 3 and 5) but for the two plan-past-the-van
## checks in `_test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van`, which fail on
## seed 2: those two are the seed-bound ones, and why the plan crosses a body's clearance there is
## not known.
const RUN_SEED := 4
## How much faster than real time a test's stretch of real physics frames runs: the engine hands
## each tick `Engine.time_scale` times its ordinary length, so the rig's half-second checks and
## three-second waits pass in a quarter of the wall time (`_real_frames()`).
const FAST := 4.0

var _run: RunState
var _city: City
var _resistance: ResistanceDirector
var _stroller: Stroller
## The day whose spec the planners read the escape's exits off — never started, since nothing here
## asks the clock; a test about the rig starts a day of its own (`_started_day()`).
var _clock: DayController

func run(t) -> void:
	t.gives_back_observers()
	_build_day(t)
	_test_a_plan_never_cuts_a_true_diagonal(t)
	_test_a_straight_run_on_plain_road_is_never_cut(t)
	_test_a_straight_run_onto_a_crossing_is_cut(t)
	_test_plan_never_steps_on_a_plain_road_tile_when_the_sidewalk_reaches(t)
	_test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van(t)
	_test_a_crossed_clearance_tile_is_walked_at_its_roomiest_point(t)
	_test_a_replan_keeps_off_the_ground_round_what_caught_her(t)
	_test_unstick_tries_the_direction_away_from_what_caught_her_first(t)
	_test_a_plan_never_goes_through_a_precincts_posts(t)
	_test_resolve_target_mark_is_todays_contact(t)
	_test_resolve_target_task_is_unavailable_before_the_mark_is_touched(t)
	_test_resolve_target_home_is_the_home_rects_centre(t)
	_test_resolve_target_spawn_reaches_devrig(t)
	_test_resolve_target_tunnel_and_bridge_are_the_escape_cities_exits(t)
	_test_resolve_target_unknown_word_warns_and_answers_inf(t)
	_test_task_target_resolves_for_the_neighbor_task_on_day_10(t)
	_test_task_target_steps_off_obstructed_ground(t)
	await _test_task_target_resolves_for_the_mast_task_on_day_11(t)
	_test_task_target_resolves_for_the_swing_task_on_day_12(t)
	_test_task_target_resolves_for_the_door_task_on_day_9(t)
	await _test_task_target_resolves_for_the_station_door_on_the_last_night(t)
	_test_nearest_calm_excludes_ground_the_day_has_spoiled(t)
	_test_calm_leaves_the_park_being_taken(t)
	_test_resolve_target_calm_home_prefers_the_combined_walk(t)
	await _test_pace_does_not_advance_the_target(t)
	await _test_check_settled_waits_for_asleep(t)
	await _test_calm_ground_gone_under_her_looks_again(t)
	await _test_on_day_finished_won_still_finishes(t)
	await _test_maybe_replan_waits_before_forcing_a_physical_maneuver(t)
	await _test_a_mark_leg_follows_the_mark_when_it_moves(t)
	await _test_a_door_hold_is_not_a_stall_and_its_far_side_is_planned_from(t)
	await _test_a_real_leg_walks_her_there_and_reports_it(t)
	_free_day()
	await _test_a_mark_leg_ends_when_the_director_records_the_mark(t)
	var doors := _build_day_with_doors(t)
	_test_a_door_between_two_lanes_opens_both_as_its_crossing(t, doors)
	_test_a_plan_never_goes_through_the_boom(t, doors)
	_test_a_plan_does_not_walk_into_a_door_that_has_just_let_her_out(t, doors)
	await _test_a_rig_run_never_walks_under_a_boom(t, doors)
	_free_fixture(doors)
	_clock.free()

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

## One day's city in a run of its own, built the way `main._start_day()` builds it — closures before
## events — with streaming off so a plan is placed with nobody near it, a resistance director over it
## and a real `Stroller` scene parked on the doorstep: the one real leg this suite walks needs
## `move_and_slide()` to actually move her, which only the real scene does (see the verify skill).
## `progress_at_dawn` is the run's resistance progress as the director's `start_day()` reads it — 0
## for every ordinary day, `Tuning.RESISTANCE_GOAL` for the last night's finale, which needs
## `RunState.sabotage_available()` to hold before the step is on offer at all. `her` hands the
## director and the events her (`use_player()`), as `main` does. Freed by `_free_fixture()`.
func _build_fixture(t, day: int, progress_at_dawn := 0, her := true) -> Dictionary:
	var run := RunState.new()
	run.start_run(RUN_SEED)
	run.resistance.progress = progress_at_dawn
	var city: City = CITY_SCENE.instantiate()
	city.run = run
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	city.events.stream_radius = INF

	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng(day, "closures"))
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), consumed)

	var stroller: Stroller = STROLLER_SCENE.instantiate()
	t.add_child(stroller)
	stroller.global_position = city.map.doorstep_world_position()
	if her:
		city.events.use_player(stroller)

	var resistance := ResistanceDirector.new()
	t.add_child(resistance)
	resistance.set_process(false)
	resistance.setup(city, city.map)
	if her:
		resistance.use_player(stroller)
	resistance.start_day(day, _rng(day, "resistance"), Tuning.day_length(day) if her else 300.0)
	return {"city": city, "resistance": resistance, "stroller": stroller, "state": state,
			"run": run}

func _free_fixture(fixture: Dictionary) -> void:
	(fixture["stroller"] as Stroller).free()
	(fixture["resistance"] as ResistanceDirector).free()
	(fixture["city"] as City).free()
	(fixture["run"] as RunState).free()

## The suite's own day 6, with nobody handed to the director or the events, so nothing reads her
## position but the rig and its planner.
func _build_day(t) -> void:
	var fixture := _build_fixture(t, DAY, 0, false)
	_run = fixture["run"]
	_city = fixture["city"]
	_resistance = fixture["resistance"]
	_stroller = fixture["stroller"]
	_day_fixture = fixture
	_clock = DayController.new()
	t.add_child(_clock)

var _day_fixture: Dictionary

func _free_day() -> void:
	_release()
	_free_fixture(_day_fixture)
	_city = null
	_resistance = null
	_stroller = null
	_run = null

## The planner the rig builds in its `setup()`, over the suite's day 6 and her.
func _planner(resistance: ResistanceDirector = _resistance) -> RouteRigPlanner:
	return RouteRigPlanner.new(_city, _stroller, resistance, _clock, _run)

## A fixture's planner, the same shape.
func _fixture_planner(fixture: Dictionary) -> RouteRigPlanner:
	return RouteRigPlanner.new(fixture["city"], fixture["stroller"], fixture["resistance"], _clock,
			fixture["run"])

func _release() -> void:
	TouchControls.set_axis(&"move_left", &"move_right", 0.0)
	TouchControls.set_axis(&"move_up", &"move_down", 0.0)

## The first tile of `type` the map has, at least `margin` tiles clear of every edge, scanned
## rather than hard-coded, so a change to the generator's own layout cannot make this suite pass
## on a coincidence. `t.check`s that one exists rather than crashing on `Vector2i(-1, -1)` if a
## future seed or a future generator ever ran out.
func _find_tile(t, type: GameEnums.TileType, margin: int = 3) -> Vector2i:
	for y in range(margin, _city.map.size.y - margin):
		for x in range(margin, _city.map.size.x - margin):
			var tile := Vector2i(x, y)
			if _city.map.tile_at(tile) == type:
				return tile
	t.check(false, "seed %d day %d has a %s tile to test against, clear of the map edge"
			% [SEED, DAY, type])
	return Vector2i(-1, -1)

## Whether `tile` is ground a straight cut may cross: open, unobstructed and not plain `ROAD`.
func _cuttable(tile: Vector2i) -> bool:
	return _city.map.is_open(tile) and not _city.map.is_obstructed(tile) \
			and _city.map.tile_at(tile) != GameEnums.TileType.ROAD

# ----------------------------------------------------------------- the rig ---

## A day of her own for the rig to walk, started as `main` starts one, over `city`'s map.
func _started_day(t, city: City, stroller: Stroller, run: RunState) -> DayController:
	var day := DayController.new()
	t.add_child(day)
	day.setup(city.map, stroller, run)
	day.set_process(false)
	day.start(600.0)
	return day

## A rig built and started the way `main` builds one (`main._add_the_route_rig()`, then the day's
## `RunFlow.day_planned`), walking `targets` over `city` on `day`, in a memory log of its own so a
## test reads back what it wrote. The rig's own frames run from here on.
func _started_rig(t, city: City, stroller: Stroller, resistance: ResistanceDirector,
		day: DayController, run: RunState, words: Array) -> RouteRig:
	var rig := RouteRigNoQuit.new()
	t.add_child(rig)
	var baby: Baby = stroller.get_node("Baby")
	var targets: Array[String] = []
	targets.assign(words)
	rig.setup(city, stroller, baby, resistance, day, targets, run)
	Telemetry.begin_memory_log()
	rig.start_day(day.spec)
	return rig

## The rig's lines in the run log, in order.
func _route_lines() -> Array[String]:
	var lines: Array[String] = []
	if Telemetry.current_log() == null:
		return lines
	for line in Telemetry.current_log().lines:
		if line.contains(" route ") or line.contains("route  "):
			lines.append(line)
	return lines

## How many of the rig's lines so far contain `text`.
func _count(text: String) -> int:
	var found := 0
	for line in _route_lines():
		if line.contains(text):
			found += 1
	return found

## The direction the rig is pressing now, as `Input`'s move actions hold it.
func _pressed() -> Vector2:
	return Vector2(Input.get_action_strength(&"move_right") - Input.get_action_strength(&"move_left"),
			Input.get_action_strength(&"move_down") - Input.get_action_strength(&"move_up"))

## Real frames, each exactly one physics tick, at `scale` times real time: every node in the tree
## takes its `_physics_process()` once a frame — the rig presses, she walks — and `each` is called
## after every frame with the day time run so far, which stops the run by answering true. Stops
## after `ticks` ticks at the latest, and answers the day time the frames took. **Every stretch of
## real frames in this suite goes through here.** After a slow frame the engine would catch up by
## running several ticks in one (up to `Engine.max_physics_steps_per_frame`), so a check made
## between frames would miss what happened on the ticks inside it — the rig's first plan makes the
## next frame such a frame even on a quiet machine, and a loaded one makes them anywhere. Held to
## one tick a frame, the simulation slows down under load rather than catching up, and the frame
## timeline is the tick timeline. The engine's own values are put back however the run ends: `each`
## cannot return past this function.
func _real_frames(t, ticks: int, each: Callable = Callable(), scale := FAST) -> float:
	var clock := Engine.time_scale
	var steps := Engine.max_physics_steps_per_frame
	Engine.time_scale = scale
	Engine.max_physics_steps_per_frame = 1
	var tick := scale / Engine.physics_ticks_per_second
	var ran := 0
	while ran < ticks:
		var before := Engine.get_physics_frames()
		await t.get_tree().physics_frame
		await t.get_tree().process_frame
		ran += Engine.get_physics_frames() - before
		if each.is_valid() and each.call(ran * tick):
			break
	Engine.max_physics_steps_per_frame = steps
	Engine.time_scale = clock
	return ran * tick

## The ticks `seconds` of day time take at `FAST`, rounded up.
func _ticks_for(seconds: float) -> int:
	return ceili(seconds * Engine.physics_ticks_per_second / FAST - 0.001)

## Real frames for `seconds` of day time at `FAST`.
func _frames_for(t, seconds: float) -> void:
	await _real_frames(t, _ticks_for(seconds))

## `count` real frames at real time, one tick each.
func _steps(t, count: int) -> void:
	await _real_frames(t, count, Callable(), 1.0)

## Ends the rig's memory log and frees what a rig test built.
func _end_rig(rig: RouteRig, day: DayController) -> void:
	Telemetry.end_run()
	rig.free()
	day.free()
	_release()

# ---------------------------------------------------------- straight cuts ---

## An open square of `size` tiles on cuttable ground, its top-left tile, scanned like `_find_tile()`.
func _find_open_square(t, size: int) -> Vector2i:
	for y in range(3, _city.map.size.y - 3 - size):
		for x in range(3, _city.map.size.x - 3 - size):
			var fits := true
			for dy in size:
				for dx in size:
					if not _cuttable(Vector2i(x + dx, y + dy)):
						fits = false
						break
				if not fits:
					break
			if fits:
				return Vector2i(x, y)
	t.check(false, "seed %d day %d has an open square of %d tiles" % [SEED, DAY, size])
	return Vector2i(-1, -1)

## The structural guarantee itself: two tiles that differ on both axes are never joined by one
## straight cut, whatever ground lies between them — see `RouteRigPlanner._line_of_sight()`'s doc for
## the corner a sampled diagonal cannot see (`ReachabilityGrid`'s own two-components case). A plan
## one step diagonally across the middle of an open square, all of it cuttable ground clear by more
## than a cut's own clearance, keeps its corner, which is what makes this a test of the rule and not
## of the ground.
func _test_a_plan_never_cuts_a_true_diagonal(t) -> void:
	var square := _find_open_square(t, 5)
	if square == Vector2i(-1, -1):
		return
	var planner := _planner()
	var a := square + Vector2i(2, 2)
	var b := a + Vector2i(1, 1)
	var planned := planner.plan(a, b)
	t.check(planned.size() == 3 and planned[0] == a and planned[2] == b
			and (planned[1].x == a.x or planned[1].y == a.y),
			"a true diagonal (%s to %s) is walked round its corner, never cut (%s)" % [a, b, planned])

## A stretch of plain `ROAD` down one column, `length` tiles, with open ground on both sides, so a
## cut down it fails on the tile type and nothing else; its top tile.
func _find_road_column(t, length: int) -> Vector2i:
	for y in range(4, _city.map.size.y - 4 - length):
		for x in range(4, _city.map.size.x - 4):
			var fits := true
			for k in length:
				var here := Vector2i(x, y + k)
				if _city.map.tile_at(here) != GameEnums.TileType.ROAD or not _city.map.is_open(here) \
						or _city.map.is_obstructed(here) \
						or not _city.map.is_open(here + Vector2i.LEFT) \
						or not _city.map.is_open(here + Vector2i.RIGHT):
					fits = false
					break
			if fits:
				return Vector2i(x, y)
	t.check(false, "seed %d day %d has a straight stretch of road down one column" % [SEED, DAY])
	return Vector2i(-1, -1)

## **A straight cut onto plain `ROAD` is refused, even where every sampled point along it reads
## open** — the rule is about the tile *type*, not about what is in the way of it. A plan held down
## a column of plain road (the ground either side kept off, as a re-plan keeps off what caught her)
## keeps a waypoint on every tile of it rather than joining the ends.
func _test_a_straight_run_on_plain_road_is_never_cut(t) -> void:
	var top := _find_road_column(t, 7)
	if top == Vector2i(-1, -1):
		return
	var keep_off := {}
	for k in range(-2, 9):
		for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			keep_off[top + Vector2i(0, k) + side] = true
	keep_off[top + Vector2i(0, -1)] = true
	keep_off[top + Vector2i(0, 7)] = true
	var planned := _planner().plan(top, top + Vector2i(0, 6), keep_off)
	t.check(planned.size() == 7,
			"a straight run down plain ROAD from %s keeps every tile rather than one cut (%s)"
			% [top, planned])

## The left end of a straight run of `length` tiles along one row that a cut may cross all the way
## down, with the row above and the row below it cuttable too (the cut samples a body's width
## either side of its line), and none of it a crossing already; answers `Vector2i(-1, -1)` if
## there is none. Scanned rather than hard-coded, like `_find_tile()`.
func _find_cuttable_row(length: int) -> Vector2i:
	for y in range(4, _city.map.size.y - 4):
		for x in range(4, _city.map.size.x - 4 - length):
			var fits := true
			for k in length:
				for dy in range(-1, 2):
					var tile := Vector2i(x + k, y + dy)
					if not _cuttable(tile) or _city.map.tile_at(tile) == GameEnums.TileType.CROSSING:
						fits = false
						break
				if not fits:
					break
			if fits:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

## A `CROSSING` tile (a zebra) is not refused the way a plain `ROAD` tile is — crossing there is
## the legal way over the carriageway, which is the entire point of hugging the kerb rather than
## simply refusing every carriageway tile outright. **Asked through `plan()` on a map the test
## paints**: the generator's own zebras are two tiles wide with plain road either side, so no plan
## on a generated city cuts onto one, but a planner handed a city whose map holds a crosswalk three
## tiles wide (the tiles of an open run, painted over and put back) keeps the straight cut from the
## run's near end to its far end as two waypoints, and a cut refusing the crossing would keep a
## waypoint on every tile.
func _test_a_straight_run_onto_a_crossing_is_cut(t) -> void:
	var left := _find_cuttable_row(5)
	t.check(left != Vector2i(-1, -1), "seed %d day %d has an open run of five tiles to paint a crosswalk on"
			% [SEED, DAY])
	if left == Vector2i(-1, -1):
		return
	var right := left + Vector2i(4, 0)
	var plain := _planner().plan(left, right)
	t.check(plain.size() == 2,
			"the open run %s to %s is walked as one straight cut before it is painted (%s)"
			% [left, right, plain])
	var was := {}
	for k in range(1, 4):
		var tile := left + Vector2i(k, 0)
		was[tile] = _city.map.tile_at(tile)
		_city.map.set_tile(tile, GameEnums.TileType.CROSSING)
	var crossed := _planner().plan(left, right)
	for tile: Vector2i in was:
		_city.map.set_tile(tile, was[tile])
	t.check(crossed.size() == 2,
			"a crosswalk three tiles wide on the run %s to %s is cut straight across, not refused "
			% [left, right] + "the way a ROAD tile is (%s)" % [crossed])

# ------------------------------------------------------------------- plans ---

## `plan()`'s own contract, checked end to end rather than by re-deriving the algorithm: every
## tile of the finished route from the doorstep to the nearest calm tile is open ground that is not
## `ROAD`. On a seed with a calm tile ordinarily reachable on foot — every seed
## `tests/test_route_tree.gd` already requires one for — the sidewalk is priced so far below the
## carriageway that nothing here should be `ROAD` at all.
func _test_plan_never_steps_on_a_plain_road_tile_when_the_sidewalk_reaches(t) -> void:
	var planner := _planner()
	var here := _city.map.world_to_tile(_city.map.doorstep_world_position())
	var calm := _city.map.calm_tiles()
	t.check(not calm.is_empty(), "day %d has calm ground to route to" % DAY)
	if calm.is_empty():
		return
	var field := _city.map.walk_field(here)
	var nearest := calm[0]
	var best := _city.map.distance_at(field, nearest)
	for tile in calm:
		var distance := _city.map.distance_at(field, tile)
		if distance >= 0 and (best < 0 or distance < best):
			best = distance
			nearest = tile
	var path := planner.plan(here, nearest)
	t.check(not path.is_empty(), "a path from the doorstep to the nearest calm tile exists")
	var road_steps := 0
	for tile in _walked_tiles(path):
		if _city.map.tile_at(tile) == GameEnums.TileType.ROAD:
			road_steps += 1
	t.check(road_steps == 0,
			"the route to calm ground takes no plain ROAD tile when the sidewalk graph reaches it (%d found)"
			% road_steps)

# ---------------------------------------------------------------- bodies ---

## A kerb tile with a two-lane pavement behind it and a building behind that, the carriageway in
## front, and the same on the three tiles either side along the street — the site a `delivery_van`
## (`pavement_side = AT_THE_KERB`) is parked on — far enough from the doorstep that nothing this
## suite walks passes it, and with no body's clearance already reaching its frontage tile.
## Scanned rather than hard-coded, like `_find_tile()`. Answers `Vector2i(-1, -1)` if none.
func _find_kerb_site(t, planner: RouteRigPlanner) -> Vector2i:
	var doorstep := _city.map.world_to_tile(_city.map.doorstep_world_position())
	var clear := planner.body_clear_tiles()
	for y in range(4, _city.map.size.y - 4):
		for x in range(4, _city.map.size.x - 4):
			var kerb := Vector2i(x, y)
			if absi(kerb.x - doorstep.x) + absi(kerb.y - doorstep.y) < 12:
				continue
			var inward := _city.map.pavement_inward(kerb)
			if inward == Vector2i.ZERO:
				continue
			if _kerb_site_fits(kerb, inward, clear):
				return kerb
	t.check(false, "seed %d day %d has a clear kerb with a two-lane pavement to park a van at"
			% [SEED, DAY])
	return Vector2i(-1, -1)

func _kerb_site_fits(kerb: Vector2i, inward: Vector2i, clear: Dictionary) -> bool:
	var along := Vector2i(inward.y, inward.x)
	for k in range(-3, 4):
		var here := kerb + along * k
		if _city.map.pavement_inward(here) != inward \
				or _city.map.tile_at(here - inward) != GameEnums.TileType.ROAD \
				or _city.map.tile_at(here - inward * 2) != GameEnums.TileType.ROAD \
				or _city.map.tile_at(here + inward) != GameEnums.TileType.SIDEWALK \
				or _city.map.is_walkable(here + inward * 2):
			return false
		for tile: Vector2i in [here, here + inward, here - inward, here - inward * 2]:
			if not _city.map.is_open(tile) or _city.map.is_obstructed(tile) or clear.has(tile):
				return false
	return true

## The chokepoint the rig stalled at: a kerbed `delivery_van` (22px) covers only its own kerb
## tile's centre, so `CityMap.obstructed_tiles` records that tile alone — yet the frontage tile
## beside it is 10px from the van's side, under her 14px radius, and so is the carriageway's first
## lane. `body_clear_tiles()` must keep a plan off both, and off the kerb tiles either side, while
## leaving the carriageway's second lane open: that is the way past a van at the kerb.
func _test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van(t) -> void:
	var planner := _planner()
	var kerb := _find_kerb_site(t, planner)
	if kerb == Vector2i(-1, -1):
		return
	var inward := _city.map.pavement_inward(kerb)
	var along := Vector2i(inward.y, inward.x)
	var van := _city.events.spawn_extra(EventCatalogue.by_id("delivery_van"),
			_city.map.tile_to_world(kerb))
	t.check(van.is_solid(), "the van stands with a solid body")
	var frontage := kerb + inward
	t.check(_city.map.is_obstructed(kerb) and not _city.map.is_obstructed(frontage),
			"the tile record has the van's kerb tile and not the frontage tile beside it")
	var clear := planner.body_clear_tiles()
	t.check(clear.has(frontage), "the frontage tile beside the van is kept clear of")
	t.check(clear.has(kerb - inward), "the carriageway's first lane beside the van is kept clear of")
	t.check(clear.has(kerb - along) and clear.has(kerb + along),
			"the kerb tiles either side of the van are kept clear of")
	t.check(not clear.has(kerb - inward * 2), "the carriageway's second lane stays open")
	var caught := planner.ground_round_body(van)
	t.check(caught.has(frontage + along) and caught.has(frontage - along),
			"the ground round a van that caught her reaches past its own clearance")
	t.check(not caught.has(kerb - inward * 2),
			"and still leaves the carriageway's second lane open past it")

	var from := frontage - along * 3
	var to := frontage + along * 3
	var path := planner.plan(from, to)
	t.check(not path.is_empty(), "a plan past the van along its own pavement exists")
	t.check(planner.crossed().is_empty(), "and crosses none of any body's clearance")
	var pressed := 0
	for tile in _walked(planner.to_world(path)):
		if clear.has(tile) and tile != from and tile != to:
			pressed += 1
	t.check(pressed == 0, "no step of the plan past the van is one she cannot stand in the middle"
			+ " of (%d found)" % pressed)
	_city.events.retire(van)
	_city.map.release_obstruction(van.get_instance_id())

## **A tile of a body's clearance the plan chose to cross is walked at its roomiest point, not its
## centre.** The carriageway's first lane beside a kerbed `delivery_van` has its centre 10px from the
## van's side, under her 14px radius, and room past it on the far side: a plan held down that lane
## (the second lane and the pavement kept off, as a re-plan keeps off what caught her) keeps the
## tile as a waypoint of its own and moves it off the van, which is how she gets through a gap that
## fits her only off the tile centres, as between two vans at the kerb either side of a road.
func _test_a_crossed_clearance_tile_is_walked_at_its_roomiest_point(t) -> void:
	var planner := _planner()
	var kerb := _find_kerb_site(t, planner)
	if kerb == Vector2i(-1, -1):
		return
	var inward := _city.map.pavement_inward(kerb)
	var along := Vector2i(inward.y, inward.x)
	var van := _city.events.spawn_extra(EventCatalogue.by_id("delivery_van"),
			_city.map.tile_to_world(kerb))
	var lane := kerb - inward
	var surface := func(point: Vector2) -> float:
		return van.global_position.distance_to(point) - van.def.shape.reach()
	var centre := _city.map.tile_to_world(lane)
	t.check(surface.call(centre) < Tuning.PLAYER_BODY_RADIUS,
			"the lane's centre is nearer the van's side than her radius (%.1fpx)" % surface.call(centre))
	var keep_off := {}
	for k in range(-5, 6):
		for row: Vector2i in [kerb - inward * 2, kerb, kerb + inward]:
			keep_off[row + along * k] = true
	keep_off[lane - along * 4] = true
	keep_off[lane + along * 4] = true
	var planned := planner.plan(lane - along * 3, lane + along * 3, keep_off)
	t.check(planned.has(lane) and planner.crossed().has(lane),
			"the crossed clearance tile stays a waypoint of its own (%s)" % [planned])
	if planned.has(lane):
		var moved: Vector2 = planner.to_world(planned)[planned.find(lane)]
		t.check(_city.map.world_to_tile(moved) == lane
				and surface.call(moved) >= Tuning.PLAYER_BODY_RADIUS,
				"and is walked at a point of its tile clear of the van by her radius (%.1fpx)"
				% surface.call(moved))
	_city.events.retire(van)
	_city.map.release_obstruction(van.get_instance_id())

## Every tile a walk down `waypoints` passes through, in order — a plan keeps only the ends of a
## straight run, and every run is along one row or column (a diagonal is never cut), so the tiles
## between two waypoints are a straight line of them.
func _walked(waypoints: Array[Vector2]) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for point in waypoints:
		tiles.append(_city.map.world_to_tile(point))
	return _walked_tiles(tiles)

func _walked_tiles(path: Array[Vector2i]) -> Array[Vector2i]:
	var walked: Array[Vector2i] = []
	for i in path.size():
		var a := path[i]
		if i == path.size() - 1:
			walked.append(a)
			break
		var b := path[i + 1]
		var tile := a
		while tile != b:
			walked.append(tile)
			tile += _step_toward(tile, b)
	return walked

## One tile step from `tile` toward `to`, along the row first: a straight run is walked tile by
## tile, and a pair that is not straight (which a plan never hands out) is walked as an L rather
## than never arriving.
func _step_toward(tile: Vector2i, to: Vector2i) -> Vector2i:
	if tile.x != to.x:
		return Vector2i(signi(to.x - tile.x), 0)
	return Vector2i(0, signi(to.y - tile.y))

## A re-plan keeps off the ground round what has caught her this leg (`RouteRig._leg_avoid`, which
## it hands every re-plan), rather than ringing her own position and walking her straight back to
## the same pinch. Pinned on a tile the ordinary plan walks through, since the claim under test is
## what a plan does with that ground once a stall has named it.
func _test_a_replan_keeps_off_the_ground_round_what_caught_her(t) -> void:
	var planner := _planner()
	_stroller.global_position = _city.map.doorstep_world_position()
	var calm := planner.resolve("calm")
	t.check(calm != Vector2.INF, "a calm target exists for this leg")
	if calm == Vector2.INF:
		return
	var here := planner.standing_tile()
	var to := _city.map.world_to_tile(calm)
	var first := _walked_tiles(planner.plan(here, to))
	t.check(first.size() >= 5, "the ordinary plan to calm ground has a middle to take away")
	if first.size() < 5:
		return
	var pinch := first[first.size() / 2]
	var again := planner.plan(here, to, {pinch: true})
	t.check(not again.is_empty() and not _walked_tiles(again).has(pinch),
			"the re-plan walks round the ground round what caught her (%s)" % pinch)

## The maneuver starts from the compass point pointing most directly away from what caught her,
## rather than always from north — pressing into the body first spends a whole
## `RouteRig._UNSTICK_TRY_SECONDS` on the one direction that cannot work.
func _test_unstick_tries_the_direction_away_from_what_caught_her_first(t) -> void:
	var planner := _planner()
	_stroller.global_position = _city.map.doorstep_world_position()
	var order := planner.unstick_order(Vector2.LEFT, 48.0)
	t.check(order[0] == Vector2.LEFT, "the first direction tried is away from the body")
	t.check(order[order.size() - 1] == Vector2.RIGHT, "the last is straight back into it")
	var plain := planner.unstick_order(Vector2.ZERO, 48.0)
	t.check(plain.size() == 8 and plain[0] == Vector2.UP and plain[1] == Vector2.DOWN
			and plain[2] == Vector2.LEFT and plain[3] == Vector2.RIGHT,
			"with nothing solid touching her, the plain compass order (%s)" % [plain])

## **A plan across a precinct's mouth goes round the row on the pavement.** The posts shut the
## carriageway band (`CityMap.post_positions()`, `tests/test_bollards.gd`), so a plan from the
## street side of the middle of the row to the precinct side must not step on a tile within her
## body's reach of a post, and the pavement beside the row stays open, so there is a plan. The
## reach is the rig's own (a post's radius plus hers), copied here as the test's oracle.
func _test_a_plan_never_goes_through_a_precincts_posts(t) -> void:
	var posts := _city.map.post_positions()
	t.check(posts.size() >= 2, "the suite's city has a precinct with a row of posts")
	if posts.size() < 2:
		return
	var planner := _planner()
	var vertical := not is_equal_approx(posts[0].x, posts[1].x)
	var count := posts.size() / (2 * _city.map.precinct_spans.size())
	var middle := posts[count / 2]
	var along := Vector2(0.0, 1.0) if vertical else Vector2(1.0, 0.0)
	var from := _city.map.world_to_tile(middle - along * Tuning.TILE_SIZE * 3.0)
	var to := _city.map.world_to_tile(middle + along * Tuning.TILE_SIZE * 3.0)
	var reach := Prop.bollard_shape().radius + Tuning.PLAYER_BODY_RADIUS
	var shut := func(tile: Vector2i) -> bool:
		for at in posts:
			if _city.map.tile_to_world(tile).distance_to(at) < reach:
				return true
		return false
	var aimed := planner.plan(from, _city.map.world_to_tile(middle))
	t.check(not aimed.is_empty() and not shut.call(aimed[aimed.size() - 1]),
			"the row's own tile is blocked to every plan: one aimed at it ends beside the posts")
	var planned := planner.plan(from, to)
	var through := false
	for tile in _walked_tiles(planned):
		through = through or shut.call(tile)
	t.check(not planned.is_empty() and not through,
			"a plan across a precinct's mouth goes round the row rather than through its posts")

# ---------------------------------------------------------------- resolving ---

## `mark` is today's own contact for exactly as long as the pickup step is still on offer — day 6's
## own mark, in this suite's fixture.
func _test_resolve_target_mark_is_todays_contact(t) -> void:
	var step := _resistance.current_step()
	t.check(step != null and step.is_pickup, "day %d's own step on offer is the pickup mark" % DAY)
	t.check(_planner().resolve("mark") == _resistance.contact_position(),
			"'mark' resolves to the day's own contact position")

## `task` answers `Vector2.INF` until the mark that unlocks it has actually been touched.
func _test_resolve_target_task_is_unavailable_before_the_mark_is_touched(t) -> void:
	t.check(_planner().resolve("task") == Vector2.INF,
			"'task' is unresolved while the mark is still the step on offer")

func _test_resolve_target_home_is_the_home_rects_centre(t) -> void:
	t.check(_planner().resolve("home") == _city.map.home_world_position(),
			"'home' resolves to CityMap.home_world_position()")

## `spawn:<name>` is handed straight to `DevRig.for_spawn_target()`, the same lookup `--spawn`
## itself uses — `park` is one `tests/test_dev_rig.gd` already exercises directly.
func _test_resolve_target_spawn_reaches_devrig(t) -> void:
	var at := _planner().resolve("spawn:park")
	t.check(at == DevRig.for_spawn_target("park", _city, _resistance, _run.header),
			"'spawn:park' resolves exactly as DevRig.for_spawn_target('park', ...) does")

## `tunnel` and `bridge` are the escape city's two ways out, read off the day's spec
## (`DaySpec.exits`, which `main` hands a `CITY_EDGE` section once its city stands); a day has none,
## so on a day they are unavailable, and with no `ResistanceDirector` — the escape has none —
## `mark` and `task` are unavailable rather than a crash.
func _test_resolve_target_tunnel_and_bridge_are_the_escape_cities_exits(t) -> void:
	var clock := DayController.new()
	t.add_child(clock)
	var planner := RouteRigPlanner.new(_city, _stroller, _resistance, clock, _run)
	t.check(planner.resolve("tunnel") == Vector2.INF and planner.resolve("bridge") \
			== Vector2.INF, "a day has no tunnel or bridge to walk to")
	var tunnel := _city.map.tile_to_world(FinalePlanner.exit_tile(_city.map, CityEdge.Kind.TUNNEL))
	var bridge := _city.map.tile_to_world(FinalePlanner.exit_tile(_city.map, CityEdge.Kind.BRIDGE))
	clock.spec = DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
	clock.spec.exits = {CityEdge.Kind.TUNNEL: tunnel, CityEdge.Kind.BRIDGE: bridge}
	t.check(planner.resolve("tunnel") == tunnel, "'tunnel' resolves to the spec's tunnel")
	t.check(planner.resolve("bridge") == bridge, "'bridge' resolves to the spec's bridge")
	var escape := RouteRigPlanner.new(_city, _stroller, null, clock, _run)
	t.check(escape.resolve("mark") == Vector2.INF and escape.resolve("task") \
			== Vector2.INF, "with no resistance director, 'mark' and 'task' are unavailable")
	clock.free()

func _test_resolve_target_unknown_word_warns_and_answers_inf(t) -> void:
	t.check(_planner().resolve("not-a-real-target") == Vector2.INF,
			"an unrecognised --route word answers Vector2.INF rather than guessing")

# ---------------------------------------------------- 'task' per bare-point shape ---

## docs/TODO.md, M181, "the late days are timed": one `--route task` resolution test per
## `ResistanceSteps` bare-point shape (`sits_on_a_bare_point()`'s `NARROW_KINDS` plus `MAST`) and per
## `NEIGHBOR`, since all six are `is_one_place` and reach the planner's `contact_position()` branch
## rather than its nearest live instance — a step this suite's own day 6 fixture (an `EVENT`
## any-instance task) never exercises. Each builds its own day in a run of its own, since a
## bare-point task's own day is fixed by the calendar (`ResistanceSteps._build()`) and cannot be
## asked of day 6.

## Completes `fixture`'s own mark as she would by reading it (`ContactPoint.complete_now()`, the
## contact's own completion) and answers the perform step it unlocks.
func _touch_the_mark(fixture: Dictionary) -> ResistanceSteps.Step:
	var resistance: ResistanceDirector = fixture["resistance"]
	resistance.contact().complete_now()
	return resistance.current_step()

## Day 10, warn the neighbor: `TargetKind.NEIGHBOR` rides the neighbor out in the city, and the
## planner follows it through `contact_position()` exactly as it follows a `mark` that has moved.
func _test_task_target_resolves_for_the_neighbor_task_on_day_10(t) -> void:
	var fixture := _build_fixture(t, 10)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 10 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.NEIGHBOR
			and task.is_one_place, "touching it offers the neighbor, a one-place task")
	var resolved := _fixture_planner(fixture).resolve("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the neighbor's own contact position")
	_free_fixture(fixture)

## The day 13 "no path to 'task'" regression: a contact standing on a solid row's own ground
## (`roadblock`'s `obstructs_radius`, from `GroundShape.band(60.0)`) is exactly the ground every plan
## refuses, so the planner must never hand the rig a target sitting inside one. Day 10's neighbor
## stands on open ground, which is handed back unchanged; with its tile recorded obstructed
## (`CityMap.obstructed_tiles`, written here as `EventManager` records a body — `tests/probes/m110_bodies.gd`
## reads and rewrites it the same way) the point found is open, unobstructed ground beside it.
func _test_task_target_steps_off_obstructed_ground(t) -> void:
	var fixture := _build_fixture(t, 10)
	_touch_the_mark(fixture)
	var map: CityMap = (fixture["city"] as City).map
	var contact := (fixture["resistance"] as ResistanceDirector).contact_position()
	var planner := _fixture_planner(fixture)
	var contact_tile := map.world_to_tile(contact)
	t.check(map.is_open(contact_tile) and not map.is_obstructed(contact_tile),
			"the tile this test obstructs starts out open, or the test proves nothing")
	t.check(planner.resolve("task") == contact,
			"open ground is returned unchanged rather than nudged to a neighbour")
	var covered: Array[Vector2i] = [contact_tile]
	map.obstruct_tiles(1, covered)
	var reachable := planner.resolve("task")
	var reachable_tile := map.world_to_tile(reachable)
	t.check(reachable != Vector2.INF and reachable_tile != contact_tile,
			"an obstructed centre is never handed back as the reachable point")
	t.check(map.is_open(reachable_tile) and not map.is_obstructed(reachable_tile),
			"the point found near an obstructed centre is itself open, unobstructed ground")
	map.release_obstruction(1)
	_free_fixture(fixture)

## Day 11, silence a mast: `TargetKind.MAST` sits beside a live mast's own foot, a bare point the
## director computes rather than a rider.
func _test_task_target_resolves_for_the_mast_task_on_day_11(t) -> void:
	var fixture := _build_fixture(t, 11)
	var director := fixture["resistance"] as ResistanceDirector
	var mark: ResistanceSteps.Step = director.current_step()
	t.check(mark != null and mark.is_pickup, "day 11 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.MAST
			and task.is_one_place, "touching it offers the mast, a one-place task")
	var resolved := _fixture_planner(fixture).resolve("task")
	# The contact stands on the mast's foot. Where that tile is a body's, which no plan can end on,
	# the leg aims at the open ground nearest it; where it is open — the mast put up beside the
	# mark she read standing at the doorstep — at the foot itself. From either the touch completes.
	var contact := director.contact_position()
	var map := (fixture["city"] as City).map
	var foot := map.world_to_tile(contact)
	var on_a_body := not map.is_walkable(foot) or map.is_obstructed(foot)
	var touched := false
	if resolved != Vector2.INF:
		touched = await ContactTouches.touches_from_one(t, director, resolved)
	t.check(resolved != Vector2.INF and (resolved != contact) == on_a_body and touched,
			"'task' resolves to ground the mast's foot is touched from (%s)"
			% ("open ground beside it" if on_a_body else "the open foot itself"))
	_free_fixture(fixture)

## Day 12, the swing: `TargetKind.PARK_SWING` sits at the one park the city chose for it, a bare
## point `ResistanceSteps.target_candidates()` computes from today's city.
func _test_task_target_resolves_for_the_swing_task_on_day_12(t) -> void:
	var fixture := _build_fixture(t, 12)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 12 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING
			and task.is_one_place, "touching it offers the swing, a one-place task")
	var resolved := _fixture_planner(fixture).resolve("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the swing's own point")
	_free_fixture(fixture)

## Day 9, the crossing: `TargetKind.DOOR` sits at one of today's region-wall doors, the other bare
## point `target_candidates()` computes rather than a rider.
func _test_task_target_resolves_for_the_door_task_on_day_9(t) -> void:
	var fixture := _build_fixture(t, 9)
	var mark: ResistanceSteps.Step = (fixture["resistance"] as ResistanceDirector).current_step()
	t.check(mark != null and mark.is_pickup, "day 9 offers a mark")
	var task := _touch_the_mark(fixture)
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.DOOR
			and task.is_one_place, "touching it offers the district door, a one-place task")
	var resolved := _fixture_planner(fixture).resolve("task")
	t.check(resolved != Vector2.INF
			and resolved == (fixture["resistance"] as ResistanceDirector).contact_position(),
			"'task' resolves to the district door's own crossing tile")
	_free_fixture(fixture)

## The last night: `TargetKind.STATION_DOOR` is the finale, offered with no mark of its own
## (`ResistanceSteps._finale()`) and only once `RunState.sabotage_available()` holds — set on the
## run here so the step is on offer at all, the same gate `docs/TODO.md`, M181, "the late days are
## timed" found `--day 14` alone never carries. `mark` stays `Vector2.INF` on this day (the rig's
## class doc's own note). **A contact on a building's wall is walked to from the open tile nearest
## it, and the tile straight across from it comes before a diagonal one** (feathery-marmot, the
## day-8 door): the door is walked to from the tile straight out from the facade (32px), never a
## diagonal (45px), which a leg arriving within `RouteRigPlanner.ARRIVE_RADIUS` could leave past
## the door's reach (`ResistanceDirector.DOOR_REACH`, 50.6px).
func _test_task_target_resolves_for_the_station_door_on_the_last_night(t) -> void:
	var fixture := _build_fixture(t, Tuning.RUN_LENGTH_DAYS, Tuning.RESISTANCE_GOAL)
	var director := fixture["resistance"] as ResistanceDirector
	var task: ResistanceSteps.Step = director.current_step()
	t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.STATION_DOOR
			and task.is_one_place and not task.is_pickup,
			"the finale is on offer directly, with no mark, once the goal is met")
	var planner := _fixture_planner(fixture)
	t.check(planner.resolve("mark") == Vector2.INF,
			"'mark' is unavailable on the last night, which has none")
	var resolved := planner.resolve("task")
	var map := (fixture["city"] as City).map
	var touched := false
	if resolved != Vector2.INF:
		touched = await ContactTouches.touches_from_one(t, director, resolved)
	t.check(resolved != Vector2.INF and touched and map.is_walkable(map.world_to_tile(resolved)),
			"'task' resolves to the pavement the power station's front door is touched from")
	var door := director.contact_position()
	var door_tile := map.world_to_tile(door)
	var open_straight_out := false
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		open_straight_out = open_straight_out or map.is_open(door_tile + step)
	t.check(not map.is_walkable(door_tile) and open_straight_out,
			"the station's door stands on its facade with open ground straight out from it")
	var off := map.world_to_tile(resolved) - door_tile
	t.check(absi(off.x) + absi(off.y) == 1,
			"the door at %s is walked to from the tile straight out from it (got %s)"
			% [map.world_to_tile(door), map.world_to_tile(resolved)])
	t.check(resolved.distance_to(door) + RouteRigPlanner.ARRIVE_RADIUS
			< ResistanceDirector.DOOR_REACH,
			"which, arrived at within the rig's own radius, is inside the door's reach")
	_free_fixture(fixture)

# ------------------------------------------------------------------- calm ---

## `calm` reads `CityMap.calm_tiles()` live, so a tile spoiled after the fixture was built (the
## day 12 shape, once the swing is reached) is never offered — pinned directly with `set_tile()`
## rather than by playing a whole day forward to spoil one for real.
func _test_nearest_calm_excludes_ground_the_day_has_spoiled(t) -> void:
	var planner := _planner()
	_stroller.global_position = _city.map.doorstep_world_position()
	var first := planner.resolve("calm")
	t.check(first != Vector2.INF, "a calm tile is reachable from the doorstep")
	if first == Vector2.INF:
		return
	var spoiled_tile := _city.map.world_to_tile(first)
	var original := _city.map.tile_at(spoiled_tile)
	_city.map.set_tile(spoiled_tile, GameEnums.TileType.SPOILED)
	var second := planner.resolve("calm")
	t.check(second != first,
			"once the nearest calm tile is spoiled, 'calm' answers a different one (%s vs %s)"
			% [first, second])
	_city.map.set_tile(spoiled_tile, original)

## **Day 12: once the swing is reached, `calm` is the day's other calm area, not the swing's own
## park.** The park leaves `CityMap.calm_blocks` the moment it is taken, but its grass stays grass
## while the police cordon it off (`ParkCordon`), so all of it still reads calm tile by tile — and
## she is standing in it, so the nearest calm tile by walking is in it. On an ordinary morning that
## park is calm ground like any other; taken here the way `Happenings.take_the_park()` takes it,
## `CityState.take()` then `CityMap.recompute_calm()`, it is not.
func _test_calm_leaves_the_park_being_taken(t) -> void:
	var fixture := _build_fixture(t, 12)
	var map: CityMap = (fixture["city"] as City).map
	var stroller: Stroller = fixture["stroller"]
	var planner := _fixture_planner(fixture)
	_touch_the_mark(fixture)
	stroller.global_position = (fixture["resistance"] as ResistanceDirector).contact_position()
	var park := CityGenerator.swing_park(map)
	var lot := map.lot_rect(park)
	var morning := planner.resolve("calm")
	t.check(morning != Vector2.INF and lot.has_point(map.world_to_tile(morning)),
			"on an ordinary morning no calm tile is left out: the park she stands in answers (%s)"
			% [map.world_to_tile(morning) if morning != Vector2.INF else Vector2i(-1, -1)])
	var state: CityState = fixture["state"]
	t.check(state.take(map.block_plans, park, 12), "the swing's park is taken")
	map.recompute_calm(state)
	var still_calm := 0
	for tile in map.calm_tiles():
		if lot.has_point(tile):
			still_calm += 1
	t.check(still_calm > 0 and lot.has_point(map.world_to_tile(stroller.global_position)),
			"she stands in the park, whose grass still reads calm tile by tile (%d tiles)" % still_calm)
	var calm := planner.resolve("calm")
	t.check(calm != Vector2.INF and not lot.has_point(map.world_to_tile(calm))
			and Tile.is_calm(map.tile_type_at_world(calm)),
			"'calm' answers calm ground outside the park being taken (%s, park lot %s)"
			% [map.world_to_tile(calm) if calm != Vector2.INF else Vector2i(-1, -1), lot])
	_free_fixture(fixture)

## `calm:home` — docs/TODO.md, M181, "the late days are timed", item 3's rig option — answers a real
## calm tile scored by the combined walk (hers to it, and its own walk home) rather than by her walk
## alone. Asked from sidewalk tiles across the city until the two readings part. The walks are
## measured over the ground the planner's first reading keeps to — the sidewalk, off closed,
## sealed and obstructed ground — which is the reading both answers come from here.
func _test_resolve_target_calm_home_prefers_the_combined_walk(t) -> void:
	var planner := _planner()
	var map := _city.map
	var stands := map.tiles_of_type(GameEnums.TileType.SIDEWALK)
	var parted := false
	var plain := Vector2.INF
	var toward_home := Vector2.INF
	var here := Vector2i(-1, -1)
	for k in range(0, stands.size(), maxi(1, stands.size() / 60)):
		here = stands[k]
		if not map.is_open(here):
			continue
		_stroller.global_position = map.tile_to_world(here)
		plain = planner.resolve("calm")
		toward_home = planner.resolve("calm:home")
		if plain != Vector2.INF and toward_home != Vector2.INF and plain != toward_home:
			parted = true
			break
	t.check(parted, "standing somewhere in the city, 'calm' and 'calm:home' answer different tiles")
	_stroller.global_position = map.doorstep_world_position()
	if not parted:
		return
	var kept := {}
	for tile in map.tiles_of_type(GameEnums.TileType.ROAD):
		kept[tile] = true
	for tiles: Dictionary in [map.closed_tiles, map.soft_sealed_tiles, map.obstructed_tiles]:
		for tile: Vector2i in tiles:
			kept[tile] = true
	kept.erase(here)
	var home_tile := map.world_to_tile(map.home_world_position())
	var home_kept := kept.duplicate()
	home_kept.erase(home_tile)
	var hers := map.walk_field(here, kept)
	var home := map.walk_field(home_tile, home_kept)
	var a := map.world_to_tile(plain)
	var b := map.world_to_tile(toward_home)
	var plain_total := map.distance_at(hers, a) + map.distance_at(home, a)
	var home_total := map.distance_at(hers, b) + map.distance_at(home, b)
	t.check(home_total <= plain_total,
			"the combined walk (%d) is no longer than the plain reading's tile's (%d)"
			% [home_total, plain_total])
	t.check(map.distance_at(hers, a) <= map.distance_at(hers, b),
			"the plain reading still answers the tile nearest her, for the contrast (%d vs %d)"
			% [map.distance_at(hers, a), map.distance_at(hers, b)])

# ------------------------------------------------------------------ settling ---

## A calm tile of the suite's city the rig settles on where she stands: the nearest calm ground to
## the doorstep, which the planner offers.
func _settling_ground() -> Vector2:
	_stroller.global_position = _city.map.doorstep_world_position()
	return _planner().resolve("calm")

## A rig set down on calm ground with the baby awake, walking `targets` from there: its first leg
## ends where it begins, so it is pacing at `calm` within a frame or two.
func _settling_rig(t, targets: Array) -> Dictionary:
	var baby: Baby = _stroller.get_node("Baby")
	baby.reset()
	baby.set_physics_process(false)
	var at := _settling_ground()
	_stroller.reset_at(at)
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, targets)
	return {"rig": rig, "day": day, "baby": baby, "at": at}

func _end_settling(settle: Dictionary) -> void:
	_end_rig(settle["rig"], settle["day"])
	var baby: Baby = settle["baby"]
	baby.reset()
	baby.set_physics_process(true)
	_stroller.reset_at(_city.map.doorstep_world_position())

## Pacing presses toward the far end of its own short walk and nothing else — the regression for a
## stray `_advance_target()` once left at the end of `RouteRig._pace()`, which skipped the whole
## point of settling (waiting for the baby to fall asleep) the moment she took her very first step
## of it: `calm` would "settle" in one physics frame regardless of whether the baby was anywhere
## near asleep, and she would set off for home.
func _test_pace_does_not_advance_the_target(t) -> void:
	var settle := await _begin_settling(t, ["calm", "home"])
	if settle.is_empty():
		return
	var at: Vector2 = settle["at"]
	var seen := {"farthest": 0.0, "turned": false, "last_x": 0.0}
	await _real_frames(t, _ticks_for(3.0), func(_at: float) -> bool:
		seen["farthest"] = maxf(seen["farthest"], _stroller.global_position.distance_to(at))
		var x := _pressed().x
		var last_x: float = seen["last_x"]
		seen["turned"] = seen["turned"] or (last_x != 0.0 and x != 0.0 and signf(x) != signf(last_x))
		if x != 0.0:
			seen["last_x"] = x
		return false)
	t.check(seen["farthest"] < Tuning.TILE_SIZE and seen["turned"] and _count("'home'") == 0,
			"pacing never advances the target on its own (%.1fpx from the calm point at most, turned %s)"
			% [seen["farthest"], seen["turned"]])
	_end_settling(settle)

## Starts a settling rig and lets it reach its calm point. Answers it, or `{}` (after a failed
## check) when the leg never ended there.
func _begin_settling(t, targets: Array) -> Dictionary:
	var settle := _settling_rig(t, targets)
	await _frames_for(t, 0.5)
	t.check(_count("reached 'calm'") == 1,
			"the rig set down on calm ground reaches it (%s)" % [_route_lines()])
	if _count("reached 'calm'") != 1:
		_end_settling(settle)
		return {}
	return settle

## Settling ends only once the baby is asleep, and she paces meanwhile rather than standing — the
## other half of the regression above: pacing alone must never finish the leg, and settling must
## actually wait for the state the meter reports rather than a fixed number of frames.
## `Baby.force_sleep()` is the same dev affordance `--spawn` rigs already use to skip walking the
## meter up by hand.
func _test_check_settled_waits_for_asleep(t) -> void:
	var settle := await _begin_settling(t, ["calm"])
	if settle.is_empty():
		return
	await _frames_for(t, 2.0)
	t.check(_count("baby settled") == 0 and _count("route done") == 0 and _pressed() != Vector2.ZERO,
			"still settling while the baby is awake, pacing (%s)" % _pressed())
	(settle["baby"] as Baby).force_sleep()
	await _frames_for(t, 0.2)
	var lines := _route_lines()
	t.check(_count("baby settled at 'calm'") == 1 and lines[lines.size() - 1].contains("route done"),
			"settling ends and the target advances once the baby is asleep (%s)" % [lines])
	_end_settling(settle)

## **Ground that goes from under her while she settles sends her to look again**, on the same
## target, since a baby does not settle on ground that is no longer calm and pacing on where the
## calm tile was would never end. Nothing in the game repaints calm ground during a day (day 12's
## park keeps its grass under the cordon, `ParkCordon`), so this holds the rig's own rule for
## ground that stops being calm under her. Pinned with `set_tile()` on the tile she paces on.
func _test_calm_ground_gone_under_her_looks_again(t) -> void:
	var settle := await _begin_settling(t, ["calm", "home"])
	if settle.is_empty():
		return
	var tile := _city.map.world_to_tile(settle["at"])
	var original := _city.map.tile_at(tile)
	_city.map.set_tile(tile, GameEnums.TileType.SPOILED)
	await _frames_for(t, 1.0)
	_city.map.set_tile(tile, original)
	t.check(_count("is gone, looking again") == 1 and _count("reached 'calm'") == 2
			and _count("'home'") == 0,
			"once the ground she paces on is spoiled she resolves 'calm' again rather than pacing on (%s)"
			% [_route_lines()])
	_end_settling(settle)

## A won day finishes the rig rather than being a no-op — the regression for the race
## `RouteRig._on_day_finished()`'s own doc names: `DayController`'s own `WON` fires the moment she
## is anywhere on the `HOME` tile with the baby asleep, a looser check than the rig's own arrival
## within `RouteRigPlanner.ARRIVE_RADIUS` of the exact doorstep point, so a day can win a few pixels
## before the rig arrives. She stands on home ground a tile off its centre, walking `home`, and the
## baby falls asleep (`Baby.force_sleep()`), which wins the day on the spot.
func _test_on_day_finished_won_still_finishes(t) -> void:
	var map := _city.map
	var centre := map.home_world_position()
	var stand := Vector2.INF
	for offset: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var point := centre + offset * Tuning.TILE_SIZE
		if map.tile_type_at_world(point) == GameEnums.TileType.HOME:
			stand = point
			break
	t.check(stand != Vector2.INF, "the home block has home ground a tile off its centre")
	if stand == Vector2.INF:
		return
	var baby: Baby = _stroller.get_node("Baby")
	baby.reset()
	baby.set_physics_process(false)
	_stroller.set_physics_process(false)
	_stroller.reset_at(stand)
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, ["home"])
	await _steps(t, 2)
	t.check(_count("route done") == 0 and _count("day won") == 0 and _pressed() != Vector2.ZERO,
			"not finished before the day is won: she is walking home")
	baby.force_sleep()
	await _steps(t, 1)
	t.check(not day.is_running() and _count("day won") == 1 and _pressed() == Vector2.ZERO,
			"WON finishes the rig rather than being ignored (%s)" % [_route_lines()])
	_end_rig(rig, day)
	baby.reset()
	baby.set_physics_process(true)
	_stroller.set_physics_process(true)
	_stroller.reset_at(map.doorstep_world_position())

# ------------------------------------------------------------ chokepoints ---

## The chokepoint fix (docs/TODO.md, M184, "the rig gets through chokepoints"): a second stall in
## a row waits for a crowd to clear rather than reaching straight for the eight-direction maneuver,
## and only a third stall right after waiting — proof that waiting alone did not answer it — reaches
## the maneuver. A real leg over real frames, with her standing still whatever the rig presses (her
## own frames switched off), which is exactly what a physical wedge reads as to the tile grid:
## nothing wrong with the ground, and no progress since the last check. Read off what the rig
## presses and the re-plans it writes, frame by frame.
func _test_maybe_replan_waits_before_forcing_a_physical_maneuver(t) -> void:
	_stroller.reset_at(_city.map.doorstep_world_position())
	t.check(_planner().resolve("calm") != Vector2.INF, "a calm target exists for this leg")
	_stroller.set_physics_process(false)
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, ["calm"])
	# One entry a tick (`_real_frames()`), so no step of the ladder falls between two entries.
	var timeline: Array[Dictionary] = []
	await _real_frames(t, _ticks_for(9.5), func(at: float) -> bool:
		timeline.append({"at": at, "replans": _count("re-planned"), "pressed": _pressed()})
		return false)
	# The first frame resolves the target and plans the leg; the second presses along it.
	t.check(timeline[1]["pressed"] != Vector2.ZERO, "the leg starts with a real plan she is pressed along")

	var first := _first_at(timeline, func(f: Dictionary) -> bool: return f["replans"] >= 1)
	var walking_until_then := true
	for k in range(1, maxi(first, 0)):
		walking_until_then = walking_until_then and timeline[k]["pressed"] != Vector2.ZERO
	t.check(first > 0 and timeline[first]["at"] > 0.75 and walking_until_then,
			"the first check has no stall to read yet: no re-plan before the second (%.2fs)"
			% (timeline[first]["at"] if first > 0 else -1.0))
	t.check(first > 0 and timeline[first]["pressed"] != Vector2.ZERO,
			"a first stall replans rather than waiting or forcing a maneuver")

	var released := _first_at(timeline, func(f: Dictionary) -> bool:
		return f["replans"] == 1 and f["pressed"] == Vector2.ZERO)
	t.check(released > first and timeline[released]["at"] - timeline[first]["at"] < 0.75,
			"a second stall in a row waits for a crowd to clear rather than forcing a maneuver")

	var resumed := _first_at(timeline, func(f: Dictionary) -> bool: return f["replans"] >= 2)
	var still := true
	for k in range(maxi(released, 0), maxi(resumed, 0)):
		still = still and timeline[k]["pressed"] == Vector2.ZERO
	t.check(released > 0 and resumed > released and still
			and absf(timeline[resumed]["at"] - timeline[released]["at"] - 3.0) < 0.3,
			"waiting ends once three seconds have passed, with a fresh plan (%.2fs)"
			% (timeline[resumed]["at"] - timeline[released]["at"] if resumed > 0 and released > 0
					else -1.0))

	var up := _first_at(timeline, func(f: Dictionary) -> bool:
		return f["replans"] >= 2 and f["pressed"] == Vector2.UP)
	var down := _first_at(timeline, func(f: Dictionary) -> bool:
		return f["replans"] >= 2 and f["pressed"] == Vector2.DOWN)
	var never_released := true
	# From the frame after the fresh plan: the frame that ends the wait makes the plan and presses
	# nothing yet.
	for k in range(maxi(resumed, 0) + 1, timeline.size()):
		never_released = never_released and timeline[k]["pressed"] != Vector2.ZERO
	t.check(up > resumed and down > up and never_released
			and timeline[up]["at"] - timeline[resumed]["at"] < 0.75,
			"still stuck right after waiting escalates to the physical maneuver, not a second wait"
			+ " (north first, then south)")
	_end_rig(rig, day)
	_stroller.set_physics_process(true)
	_stroller.reset_at(_city.map.doorstep_world_position())

## The index of the first frame in `timeline` that `matches`, or -1.
func _first_at(timeline: Array[Dictionary], matches: Callable) -> int:
	for k in timeline.size():
		if matches.call(timeline[k]):
			return k
	return -1

## A mark nobody has seen is moved to an alley near her (`ResistanceDirector._move_the_mark()`),
## usually on the day's first frame, after the rig has planned to where it stood at dawn — the
## day 6 seed 1234567 leg that walked the other way across the city and stalled far from any mark.
## The contact is moved by hand here (`ResistanceDirector.contact()`, its position the one thing the
## director's own move changes), and put back.
func _test_a_mark_leg_follows_the_mark_when_it_moves(t) -> void:
	_stroller.reset_at(_city.map.doorstep_world_position())
	var dawn := _resistance.contact_position()
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, ["mark"])
	await _frames_for(t, 0.7)
	t.check(_count("moved to") == 0 and _pressed() != Vector2.ZERO,
			"a mark still where the leg aimed is not re-planned to")
	var moved := _city.map.home_world_position()
	_resistance.contact().global_position = moved
	await _frames_for(t, 0.6)
	t.check(_count("'mark' moved to %s, re-planning" % RunTrace.tile(_city.map.world_to_tile(moved)))
			== 1, "a mark that has moved is re-planned to where it is now (%s)" % [_route_lines()])
	_resistance.contact().global_position = dawn
	_end_rig(rig, day)
	_stroller.reset_at(_city.map.doorstep_world_position())

## A `mark` leg ends when the director records the mark completed, whatever the waypoints say —
## `ContactPoint.REACH` (36px) completes it before the last waypoint, which a body beside the mark
## can keep her from. Its own day 6, since completing the mark moves the day's resistance on. The
## mark is completed as reading it completes it (`ContactPoint.complete_now()`) while she is still
## far from it.
func _test_a_mark_leg_ends_when_the_director_records_the_mark(t) -> void:
	var fixture := _build_fixture(t, DAY, 0, false)
	var city: City = fixture["city"]
	var stroller: Stroller = fixture["stroller"]
	var resistance: ResistanceDirector = fixture["resistance"]
	var run: RunState = fixture["run"]
	stroller.set_physics_process(false)
	var day := _started_day(t, city, stroller, run)
	var rig := _started_rig(t, city, stroller, resistance, day, run, ["mark"])
	await _steps(t, 2)
	t.check(_pressed() != Vector2.ZERO and _count("reached") == 0,
			"the mark leg has waypoints left to walk")
	var far := stroller.global_position.distance_to(resistance.contact_position())
	resistance.contact().complete_now()
	await _steps(t, 1)
	t.check(_count("reached 'mark'") == 1 and far > ContactPoint.REACH,
			"a mark leg remembers the step it walks to: the step recorded completed ends the leg"
			+ " %.0fpx short of the mark" % far)
	t.check(_count("route done") == 1,
			"the leg ends once its step is recorded completed, and the next target begins")
	_end_rig(rig, day)
	_free_fixture(fixture)

## A door's hold (`Stroller.detain()`, what a checkpoint's hut does to her) is not a stall — she
## stands still because a checkpoint is talking to her — so the stall ladder stays at its first rung
## however long it lasts, and the door setting her down on its far side (`Stroller.teleport_to()`, a
## jump no step covers, made as the hold ends) re-plans from where she lands rather than walking her
## back to the stale waypoints on the side she came from. She lands on the calm tile the leg walks
## to, so a plan from where she landed arrives at once.
func _test_a_door_hold_is_not_a_stall_and_its_far_side_is_planned_from(t) -> void:
	_stroller.reset_at(_city.map.doorstep_world_position())
	var calm := _planner().resolve("calm")
	t.check(calm != Vector2.INF, "a calm target exists for this leg")
	if calm == Vector2.INF:
		return
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, ["calm"])
	await _frames_for(t, 0.3)
	_stroller.detain(2.0)
	var replans := _count("re-planned")
	var seen := {"held_still": true}
	var elapsed := 0.0
	if _stroller.is_detained():
		elapsed = await _real_frames(t, _ticks_for(3.0), func(_at: float) -> bool:
			if not _stroller.is_detained():
				return true
			seen["held_still"] = seen["held_still"] and _pressed() == Vector2.ZERO \
					and _count("re-planned") == replans
			return false)
	var held_still: bool = seen["held_still"]
	t.check(held_still and elapsed >= 1.9,
			"while a door holds her the rig waits it out without counting a stall (%.1fs, %s)"
			% [elapsed, _route_lines()])
	var landed := _city.map.tile_to_world(_city.map.world_to_tile(calm))
	_stroller.teleport_to(landed)
	var replans_at_landing := _count("re-planned")
	await _frames_for(t, 1.0)
	t.check(_count("re-planned") - replans_at_landing <= 1,
			"the release is consumed once (%d re-plans after she landed)"
			% (_count("re-planned") - replans_at_landing))
	t.check(_count("reached 'calm'") == 1,
			"the plan after the door starts where the door set her down (%s)" % [_route_lines()])
	_end_rig(rig, day)
	_stroller.reset_at(_city.map.doorstep_world_position())

# ------------------------------------------------------------ end to end ---

## The whole loop, once, with a real `Stroller` and `Baby` walking real physics frames: resolving
## the target, planning a path, pressing the ordinary input axes, her own `move_and_slide()` taking
## her there, and the rig reporting it reached and done. `home` rather than `calm`: the doorstep sits
## right on the home block's own edge, so this leg is short and has nothing left to prove about
## calm ground or the baby's own settle that the dedicated tests above have not already covered.
func _test_a_real_leg_walks_her_there_and_reports_it(t) -> void:
	_stroller.reset_at(_city.map.doorstep_world_position())
	var start_position := _stroller.global_position
	var day := _started_day(t, _city, _stroller, _run)
	var rig := _started_rig(t, _city, _stroller, _resistance, day, _run, ["home"])
	await _real_frames(t, _ticks_for(30.0), func(_at: float) -> bool: return _count("route done") > 0)
	t.check(_count("reached 'home'") == 1 and _count("route done") == 1,
			"a short leg to 'home' is reported reached and done within 30s of day time (%s)"
			% [_route_lines()])
	t.check(_stroller.global_position.distance_to(start_position) > 1.0,
			"she actually moved from the doorstep rather than the leg completing vacuously")
	t.check(_city.map.tile_type_at_world(_stroller.global_position) == GameEnums.TileType.HOME,
			"she actually stands on HOME ground once the leg reports done")
	_end_rig(rig, day)
	_stroller.reset_at(_city.map.doorstep_world_position())

# ---------------------------------------------------------------- doors ---

## The first day a region wall stands, in a run of its own, with her handed to the events so its
## doors hold and set her down, and the wall's street door: its boom (`checkpoint_gate`, the body
## solid while lowered) and the hut standing on its line.
func _build_day_with_doors(t) -> Dictionary:
	var fixture := _build_fixture(t, Tuning.REGION_WALL_FIRST_DAY)
	var city: City = fixture["city"]
	var gate: EventInstance = null
	var hut: EventInstance = null
	for instance in city.events.instances():
		if instance.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED and not gate:
			gate = instance
	if gate:
		var axis := gate.facing_now()
		for instance in city.events.instances():
			if instance.def.id == "checkpoint_hut" and absf(
					(instance.global_position - gate.global_position).dot(axis)) <= 1.0:
				hut = instance
				break
	t.check(gate != null and hut != null,
			"seed %d day %d stands a street door to walk through" % [SEED, Tuning.REGION_WALL_FIRST_DAY])
	fixture["gate"] = gate
	fixture["hut"] = hut
	return fixture

## The open, unobstructed ground nearest `point`, a tile centre — where a test stands her near a
## door.
func _open_point_near(map: CityMap, point: Vector2) -> Vector2:
	var centre := map.world_to_tile(point)
	for radius in range(0, 6):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var tile := centre + Vector2i(dx, dy)
				var distance := map.tile_to_world(tile).distance_to(point)
				if map.is_open(tile) and not map.is_obstructed(tile) and distance < best_distance:
					best = tile
					best_distance = distance
		if best != Vector2i(-1, -1):
			return map.tile_to_world(best)
	return point

## Whether any tile a path steps on — every tile of each straight run between two waypoints — has
## its centre within `reach` of `point`.
func _passes_within(map: CityMap, path: Array[Vector2i], point: Vector2, reach: float) -> bool:
	for k in path.size():
		var tile := path[k]
		var stop := path[mini(k + 1, path.size() - 1)]
		while true:
			if map.tile_to_world(tile).distance_to(point) <= reach:
				return true
			if tile == stop:
				break
			tile += _step_toward(tile, stop)
	return false

## A door body stands in the middle of its two-lane sidewalk
## (`EventInstance._centred_on_the_pavement_band()`), on the line between two lanes, so each lane's
## centre is exactly half a tile off the body's crossing axis: both lanes are the crossing, and the
## lane beside them is door reach. Read as neither, a door left no open way through its wall, so
## the plan gave up every door's reach and walked her into the hut from the side.
func _test_a_door_between_two_lanes_opens_both_as_its_crossing(t, doors: Dictionary) -> void:
	var hut: EventInstance = doors.get("hut")
	if not hut:
		return
	var city: City = doors["city"]
	var stroller: Stroller = doors["stroller"]
	stroller.global_position = city.map.doorstep_world_position()
	var reach := _fixture_planner(doors).door_tiles()
	var axis := hut.facing_now().normalized()
	var across := Vector2(-axis.y, axis.x)
	var ahead := hut.global_position + axis * Tuning.TILE_SIZE
	var lanes := [city.map.world_to_tile(ahead + across * 16.0),
			city.map.world_to_tile(ahead - across * 16.0)]
	var beyond := city.map.world_to_tile(ahead + across * 48.0)
	t.check(not reach.has(lanes[0]) and not reach.has(lanes[1]),
			"both lanes either side of a door centred between them are its crossing line")
	t.check(reach.has(beyond) and lanes[0] != lanes[1],
			"the lane beyond them is the door's reach, and a crossing lane is not")

## **The rig never goes through a street door's boom** *(2026-09-24, the player: "The bot shouldn't
## route through the boom either way.")*: a plan from four tiles on one side of the boom to four
## tiles on the other, down the carriageway the bare grid walks straight through it, never steps on
## ground where the boom — rather than a hut — would be the body to take her.
func _test_a_plan_never_goes_through_the_boom(t, doors: Dictionary) -> void:
	var gate: EventInstance = doors.get("gate")
	if not gate:
		return
	var city: City = doors["city"]
	var map := city.map
	var axis := gate.facing_now().normalized()
	var from := map.world_to_tile(gate.global_position - axis * Tuning.TILE_SIZE * 4.0)
	var to := map.world_to_tile(gate.global_position + axis * Tuning.TILE_SIZE * 4.0)
	var bare := map.walk_field(from, {})
	t.check(map.distance_at(bare, to) == absi(to.x - from.x) + absi(to.y - from.y),
			"the bare grid walks straight down the road from one side of the gate to the other")
	(doors["stroller"] as Stroller).global_position = map.doorstep_world_position()
	var planner := _fixture_planner(doors)
	# Where her body would touch the boom's: the boom inspects nobody, so there is no trigger to
	# measure from, and what a plan must never do is put her under it.
	var reach := gate.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS
	var planned := planner.plan(from, to)
	t.check(not planned.is_empty() and not _passes_within(map, planned, gate.global_position, reach),
			"a plan past a street door's boom goes round it rather than under it")
	# The ground under the boom is kept off by every plan, the last resort that gives up the hazards
	# included, so even a plan aimed at it ends beside it.
	var aimed := planner.plan(from, map.world_to_tile(gate.global_position))
	t.check(not aimed.is_empty()
			and map.tile_to_world(aimed[aimed.size() - 1]).distance_to(gate.global_position) > reach,
			"even a plan aimed at the boom's own ground ends beside it, not under it")

## **A door that has just let her out is not planned back through.** A hut's crossing line runs
## through its body, and a latched hut does not take her in (`CheckpointController`'s release latch,
## which the planner copies once a door lets her go: `RouteRigPlanner.latch_the_doors_round_her()`),
## so a plan down the line walks her into the hut and holds her pressed against it. With the hut
## latched round where she stands the plan goes round its body; with her far from it the same plan
## goes down its line, which is the crossing — so the first answer is the latch's and not a hut the
## plan could never have walked through.
func _test_a_plan_does_not_walk_into_a_door_that_has_just_let_her_out(t, doors: Dictionary) -> void:
	var hut: EventInstance = doors.get("hut")
	if not hut:
		return
	var city: City = doors["city"]
	var map := city.map
	var stroller: Stroller = doors["stroller"]
	var axis := hut.facing_now().normalized()
	var across := Vector2(-axis.y, axis.x) * 16.0
	var body := hut.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS
	var to := map.world_to_tile(hut.global_position + axis * Tuning.TILE_SIZE * 3.0 + across)
	stroller.global_position = hut.global_position - axis * Tuning.TILE_SIZE * 8.0
	var crossing := _fixture_planner(doors).plan(
			map.world_to_tile(hut.global_position - axis * Tuning.TILE_SIZE * 3.0 + across), to)
	t.check(_passes_within(map, crossing, hut.global_position, body),
			"a plan through a door that can take her goes down its crossing line")
	var planner := _fixture_planner(doors)
	stroller.global_position = hut.global_position - axis * (hut.def.detain_distance() - 6.0) + across
	planner.latch_the_doors_round_her()
	var planned := planner.plan(map.world_to_tile(stroller.global_position), to)
	t.check(not planned.is_empty() and not _passes_within(map, planned, hut.global_position, body),
			"a plan past a door that has just let her out goes round its body")
	# And the maneuver that works her free of a stall beside the door tries the way into its
	# circle last, even when that is the way away from what caught her.
	stroller.global_position = hut.global_position - axis * (hut.def.detain_distance() + 20.0)
	var order := planner.unstick_order(axis, 48.0)
	t.check(order[0] != axis and order[order.size() - 1].dot(axis) > 0.0,
			"the unstick tries stepping into a door's circle last (%s first)" % order[0])
	stroller.global_position = map.doorstep_world_position()

## **A rig run through a street door goes through a hut, never under the boom.** *(2026-09-24, the
## player: "The bot shouldn't route through the boom either way".)* One real leg along the
## carriageway from one side of a street door's boom to the other, walked over real frames: the
## rig's own presses, her own `move_and_slide()`, and the events' own frame, which steps the doors,
## holds her and sets her down, and counts a walk under the boom
## (`EventManager.walks_under_a_boom()`). The leg's end is handed to the rig as the escape's tunnel
## would be (`DaySpec.exits`), the one target word that names a point the test chooses. The count
## must stay at zero while she ends up on the far side, held by a hut on the way, which is what says
## the leg crossed.
func _test_a_rig_run_never_walks_under_a_boom(t, doors: Dictionary) -> void:
	var gate: EventInstance = doors.get("gate")
	if not gate:
		return
	var city: City = doors["city"]
	var stroller: Stroller = doors["stroller"]
	var run: RunState = doors["run"]
	var axis := gate.facing_now()
	var reach := float(Tuning.TILE_SIZE) * 5.0
	# On the carriageway either side of the boom, so the straight line — and the bare grid's
	# shortest walk — is under it, and going through a hut is the detour the rig has to choose.
	var from := _open_point_near(city.map, gate.global_position - axis * reach)
	var to := _open_point_near(city.map, gate.global_position + axis * reach)
	stroller.reset_at(from)
	var day := _started_day(t, city, stroller, run)
	day.spec.exits = {CityEdge.Kind.TUNNEL: to}
	var rig := _started_rig(t, city, stroller, doors["resistance"], day, run, ["tunnel"])
	await _steps(t, 2)
	t.check(_pressed() != Vector2.ZERO and _count("no path") == 0,
			"the rig plans a leg through the door")
	var seen := {"held": false}
	var elapsed := 0.0
	if _count("route done") == 0:
		elapsed = await _real_frames(t, _ticks_for(60.0), func(_at: float) -> bool:
			seen["held"] = seen["held"] or stroller.is_detained()
			return _count("route done") > 0)
	var held: bool = seen["held"]
	var crossed := (stroller.global_position - gate.global_position).dot(axis) > 0.0
	print("[test_route_rig] through the door at %s: %s after %.1fs, held %s, %d walks under" % [
		RunTrace.tile(city.map.world_to_tile(gate.global_position)),
		"arrived" if _count("route done") > 0 else "still walking", elapsed, held,
		city.events.walks_under_a_boom()])
	t.check(crossed and held,
			"she ends the leg on the far side of the door, held by a hut on the way "
			+ "(far side %s, held %s) — otherwise this run never crossed a door" % [crossed, held])
	t.check(city.events.walks_under_a_boom() == 0,
			"and the rig never walked under the boom (%d walks under)"
			% city.events.walks_under_a_boom())
	_end_rig(rig, day)
	# And the same count sees a walk under this boom when there is one — so the zero above is the
	# rig's route and not a count that could not have counted anything.
	var lane := gate.global_position + Vector2(-axis.y, axis.x) * 16.0
	stroller.reset_at(lane - axis * 20.0)
	city.events.checkpoints.watch_the_door_lines()
	stroller.global_position = lane + axis * 20.0
	city.events.checkpoints.watch_the_door_lines()
	t.check(city.events.walks_under_a_boom() == 1,
			"while walking straight along the carriageway under it is counted (%d)"
			% city.events.walks_under_a_boom())
