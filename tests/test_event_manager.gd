extends RefCounted
## EventManager's wiring over a day: what the bugs that live here have in common is that a
## data-level test of one part cannot show them, an instance freed but left in the list, a
## successor spawned but never tracked. Both of those happened. The manager is real; the one wiring
## the events and the crowd share, a body the events stand on a lane taking the car there away, is
## the builder's that makes it (`tests/test_simulation_builder.gd`).
##
## **What each case stands the manager on.** Most cases ask of the streets only a stretch of
## sidewalk to stand on, so they stand it on drawn streets (`StreetMap.full()`) with plans of their
## own. The cases that start a day through the manager (the manager's plan taken as the walk's, the
## ground the dawn made handed to the walk) stand it on the seed's generated map, whose day the dawn
## plans; the one case that asks the city's own dawn (`City.start_day()`) stands it in a city,
## because it is the dawn there that grows the route tree and holds the closures the manager's walk
## must be. No other case builds a city. Two cases run after the others on the generated map: the
## cyclist's warning, which stands a manager of its own, and the parked fire engine's route
## guarantee, which builds no manager and reads the map's street network. The last case asks the
## spawner (`EventSpawner.as_warned()`) of each catalogue row and builds nothing: no suite is the
## spawner's, and the spawner is one of the manager's parts, so its question is held here.
##
## **Three cases ask the dev rig's `--spawn event` target** (`DevRig.for_spawn_target()`) of a day the
## manager planned on the generated map: the target reads the manager's placed plans, so where it
## stands her is the placement's answer.

const Rig := preload("res://tests/event_manager_rig.gd")
const STEP := 1.0 / 60.0

var _stage: Rig.Stage

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	# Every case stands a manager of its own, so none leans on what an earlier one left behind: the
	# scars a fire writes, the streaming radius, the day a case started.
	var on_streets: Array[Callable] = [
		_test_the_summary_names_what_the_day_planned,
		_test_finished_instances_are_dropped,
		_test_successor_replaces_its_parent,
		_test_excitement_sums_over_instances,
		_test_an_event_waits_until_she_is_near_it,
		_test_an_event_that_has_run_does_not_run_again,
		_test_a_running_event_comes_back_where_it_got_to,
		_test_a_streamed_pursuer_resumes_the_chase,
		_test_a_walk_starts_with_nobody_told_where_she_is,
		_test_a_row_warned_down_her_line_arrives_at_its_own_intensity,
		_test_the_first_dog_of_the_run_day_is_the_lesson,
		_test_a_moved_guard_keeps_what_he_is_in_the_middle_of,
		_test_a_drawn_body_is_told_to_whoever_listens,
		_test_a_recipes_bodies_are_in_its_way_on,
	]
	for test in on_streets:
		_stage = Rig.build_stage(t, null, StreetMap.full())
		await test.call(t)
		_stage.free_events()
	var on_the_generated_map: Array[Callable] = [
		_test_day_populates_the_manager,
		_test_the_spawn_target_event_lands_near_a_placed_event,
		_test_a_queue_fed_row_refuses_the_spawn_target_by_name,
		_test_a_waiting_row_stands_outside_its_trigger_at_the_spawn_target,
		_test_the_walk_is_handed_the_ground_the_dawn_made,
		_test_what_is_sited_on_her_walk_asks_the_ground_the_walk_carries,
	]
	for test in on_the_generated_map:
		_stage = Rig.build_stage(t)
		await test.call(t)
		_stage.free_events()
	_stage = Rig.build_city_stage(t)
	await _test_a_day_started_through_the_manager_is_planned_on_its_streets(t)
	_stage.free_events()
	# These build no stage: the manager's own world is theirs, or the street network is.
	await _test_a_world_keeps_the_navigator_it_was_handed(t)
	var map_tests: Array[Callable] = [
		_test_the_cyclist_is_warned_shortly_before_he_arrives,
		_test_a_parked_body_closes_no_street,
	]
	for test in map_tests:
		await test.call(t)
	# Nor does this one: it asks the catalogue's rows what the spawner makes of each.
	_test_every_pursuer_sent_from_off_screen_is_warned_first(t)

## **A world keeps the navigator it was handed** (`EventSurroundings.moving_by()`), whichever map
## that navigator walks: a manager set up on a street map and handed a navigator over open ground
## answers that same object, never one built over its own map in its place.
func _test_a_world_keeps_the_navigator_it_was_handed(t: TestRunner) -> void:
	var run := RunState.new()
	run.start_run(1)
	var handed := Navigator.new()
	var events := EventManager.new(EventSurroundings.new().on(StreetMap.full()).moving_by(handed))
	events.setup(run)
	t.check(events.world.navigator() == handed,
			"the events' world answers the navigator it was handed, not one over its map")
	events.free()

## **A walk begins with nobody told where she is**: the world's word is forgotten as the walk
## starts (`EventManager.start_day()`, `start_recipe()` and `stand_down()` all reach
## `_clear()`), so an event streamed in before the walk's first word does not hear where she stood
## at the end of the last one.
func _test_a_walk_starts_with_nobody_told_where_she_is(t: TestRunner) -> void:
	var events := _stage.events()
	events.world.where_she_is().tell(Vector2(700.0, 700.0), Vector2(714.0, 700.0),
			Rect2(0.0, 0.0, 9.0, 9.0), true, false, true)
	var handle := events.world.where_she_is().handle_for_an_event()
	var no_plans: Array[EventPlan] = []
	events.start_recipe(no_plans, DaySpec.for_day(2), 2, Vector2.ZERO)
	t.check(handle.at() == Vector2.INF and not handle.is_running() and handle.baby_is_awake(),
			"a walk begun forgets the last walk's word for every handle")

## A ground that counts what it is asked, for the siting's hand-on to be seen.
class _CountingGround extends RowGround:
	var asks := 0

	## Overrides RowGround.tiles_for.
	func tiles_for(def: EventDef, side: int = -1) -> Array[Vector2i]:
		asks += 1
		return super(def, side)

	## Overrides RowGround.offers_for.
	func offers_for(def: EventDef, side: int = -1) -> Dictionary:
		asks += 1
		return super(def, side)

	## Overrides RowGround.offers_for_role.
	func offers_for_role(def: EventDef, role: GameEnums.BlockerRole) -> Dictionary:
		asks += 1
		return super(def, role)

## **A guard moved is the same man, in the middle of what he was doing** (`move_extra()`): day 13's
## task guard following her to her roadblock keeps his warning and its clock, where a guard retired
## and made again would forget her. **And a guard walking off is never turned back**: one that left
## before he ever noticed her still answers `is_waiting()`, and the task setting him on her
## (`EventInstance.notice_her_at()`) leaves him leaving.
func _test_a_moved_guard_keeps_what_he_is_in_the_middle_of(t: TestRunner) -> void:
	var events := _stage.events()
	var at := CrowdLanes.arterial_pavement(_stage.map())
	var her := at + Vector2(200.0, 0.0)
	var guard := events.spawn_extra(EventCatalogue.task_guard(), at)
	guard.notice_her_at(her, Tuning.WARNING_ALONE_MAX, true)
	guard.restore(guard.save().at_age(guard.age() + 0.4))
	var noticed := guard.save().noticed_at()
	t.check(guard.is_telegraphing() and noticed != INF, "set on her, the guard warns her")
	events.move_extra(guard, at + Vector2(64.0, 0.0))
	t.check(is_instance_valid(guard) and not guard.is_gone()
			and guard.global_position.is_equal_approx(at + Vector2(64.0, 0.0))
			and guard.is_telegraphing() and guard.save().noticed_at() == noticed
			and guard.is_standing_for_its_notice(),
			"moved, he is the same man, still warning her on the same clock (noticed at %.2f, %.2f)"
			% [noticed, guard.save().noticed_at()])
	var walking := events.spawn_extra(EventCatalogue.task_guard(), at)
	walking.leave_for_a_completed_task()
	t.check(walking.is_on_its_way_out() and walking.is_waiting(),
			"a guard who left before he noticed her still answers waiting")
	walking.notice_her_at(her, Tuning.WARNING_ALONE_MAX, true)
	t.check(walking.is_on_its_way_out() and not walking.is_telegraphing(),
			"and set on her, he walks on rather than warning her")
	for instance: EventInstance in [guard, walking]:
		events.retire(instance)

## **The day-3 lesson's dog is a row of its own**, `charging_dog_tutorial`, so its charging counter
## and its seen and lost-day counts tell it from the up to three that day's `max_per_day` lets the
## director send (`EventDirector._teach_the_run()` hands it out; docs/TELEMETRY.md, "The page counts
## visits", and `tests/test_visit_counter.gd` for what its counter sends). What the manager makes of
## each row is named by the row alone, on the day the run is taught as on any other.
func _test_the_first_dog_of_the_run_day_is_the_lesson(t: TestRunner) -> void:
	var events := _stage.events()
	var dog := EventCatalogue.by_id("charging_dog")
	var lesson := EventCatalogue.lesson_of(dog)
	var at := CrowdLanes.arterial_pavement(_stage.map())
	events.world.take_the_day(Tuning.RUN_TAUGHT_DAY)
	var robber := events.spawner.create(EventCatalogue.by_id("alley_robbery"), at)
	var first := events.spawner.create(lesson, at)
	var second := events.spawner.create(dog, at)
	t.check(lesson.id() == "charging_dog_tutorial" and lesson != dog
			and lesson.pursues() and lesson.picture() == dog.picture(),
			"the lesson's dog is a row of its own, drawn and chasing as the dog does")
	t.check(first.logged_name() == "charging_dog_tutorial" and second.logged_name() == "charging_dog",
			"and seen apart (%s, %s)" % [first.logged_name(), second.logged_name()])
	t.check(EventCatalogue.lesson_of(robber.row()) == robber.row(),
			"no other row has a lesson's row of its own")
	for instance: EventInstance in [robber, first, second]:
		instance.queue_free()

## The page's own lifetime, and that every look a row can carry has pictures on it, are
## `tests/test_atlas_events.gd`: with one baked page for the whole catalogue there is no
## per-family group left for a rig like this one to watch come and go, and the questions that
## replace it — the manager's reference count across days and teardown, and every picture a look
## can draw resolving on the `events` page — are about `AtlasLibrary` rather than about this
## suite's city.

## **A body a draw stands is told on, tile for tile** (`EventStreaming.use_body_listener()`): the
## listener is called once for each placed plan whose row has a solid body, with
## `EventSpawner.footprint_of()` of it, and for no plan without one, and **after the body is
## recorded on the map**, so a car recycled for it is rolled with the body in the record. With no
## listener a draw says nothing and still stands its rows.
func _test_a_drawn_body_is_told_to_whoever_listens(t: TestRunner) -> void:
	var map := _stage.map()
	var events := _stage.events()
	var told: Array[String] = []
	# Told tiles the map does not yet hold as a body's, asked as the listener is called: the body
	# is recorded before the crowd is told, so every tile told is one the map already holds.
	var not_yet_recorded: Array[Vector2i] = []
	events.use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append(str(tiles))
		for tile in tiles:
			if not map.is_obstructed(tile):
				not_yet_recorded.append(tile))
	# One row with a solid body and one without, stood on the sidewalk a block apart.
	var at := CrowdLanes.arterial_pavement(map)
	var drawn: Array[EventPlan] = [
		EventPlan.new(EventCatalogue.by_id("barricade"), at),
		EventPlan.new(EventCatalogue.by_id("cat_dash"), at + Vector2(0.0, CityMap.period() * Tuning.TILE_SIZE)),
	]
	var expected: Array[String] = []
	for plan in drawn:
		events.streaming.add(plan)
		var tiles := EventSpawner.footprint_of(BodyStance.of(map, plan.row(), plan.placed_at(),
				plan.faces()))
		if not tiles.is_empty():
			expected.append(str(tiles))
	expected.sort()
	told.sort()
	t.check(not expected.is_empty() and expected.size() < drawn.size(),
			"the draw stands rows with a body and rows without one (%d of %d placed have one)"
			% [expected.size(), drawn.size()])
	t.check(told == expected,
			"the listener is told the footprint of each placed plan that has one, and no other"
			+ " (%d told, %d expected)" % [told.size(), expected.size()])
	t.check(not_yet_recorded.is_empty(),
			"and each is told after the body is recorded: the map holds every tile told as a body's"
			+ " (%d tiles it did not yet)" % not_yet_recorded.size())
	var told_so_far := told.size()
	events.use_body_listener(Callable())
	var drawn_before := events.plans().size()
	events.streaming.add(EventPlan.new(EventCatalogue.by_id("barricade"),
			at + Vector2(0.0, 2.0 * CityMap.period() * Tuning.TILE_SIZE)))
	t.check(told.size() == told_so_far and events.plans().size() > drawn_before,
			"with no listener a draw tells nobody and still stands its rows")

## **A scene recipe's bodies are in the through roads its walk's way on drives by** (`WayOn`,
## `ThroughRoads`, made as the walk is taken): a sent patrol in the lane of a street running
## east-west, short of a junction box, drives straight through it with nothing planned; a recipe whose
## one row is a barricade standing on the street beyond that box turns it in the box instead, since
## that street is no through road once the barricade is on it. Its leg never reaches the barricade, so
## only the through roads can turn it: they are made after the recipe's bodies are recorded.
func _test_a_recipes_bodies_are_in_its_way_on(t: TestRunner) -> void:
	var map := _stage.map()
	var events := _stage.events()
	var day := 13
	var nothing: Array[EventPlan] = []
	events.start_recipe(nothing, DaySpec.for_day(day), day, Vector2.ZERO)
	var patrol := EventCatalogue.by_id("police_patrol").as_sent_ahead()
	var period := CityMap.period()
	var tile := float(Tuning.TILE_SIZE)
	var boxes := (map.size_in_tiles().x - Tuning.STREET_WIDTH) / period + 1
	var at := Vector2.INF
	var beyond := Vector2.INF
	var far_edge := 0.0
	for row in range(1, boxes - 1):
		for column in range(0, boxes - 3):
			var lane := CrowdLanes.lane_centre(row, CrowdLanes.road_lane(false, 1.0))
			var from := Vector2((column * period + Tuning.STREET_WIDTH + 2.5) * tile, lane)
			var leg := events.ahead.director().way_on().next_leg(patrol, from, Vector2.RIGHT,
					Vector2.INF)
			far_edge = ((column + 1) * period + Tuning.STREET_WIDTH) * tile
			if leg.size() == 2 and is_equal_approx(leg[1].x, far_edge):
				at = from
				beyond = Vector2(far_edge + 4.5 * tile, lane)
				break
		if at != Vector2.INF:
			break
	t.check(at != Vector2.INF, "with nothing planned a sent patrol drives straight through a box")
	if at == Vector2.INF:
		return
	var barricade: Array[EventPlan] = [EventPlan.new(EventCatalogue.by_id("barricade"), beyond)]
	events.start_recipe(barricade, DaySpec.for_day(day), day, Vector2.ZERO)
	var leg := events.ahead.director().way_on().next_leg(patrol, at, Vector2.RIGHT, Vector2.INF)
	t.check(map.is_obstructed(map.world_to_tile(beyond))
			and not (leg.size() == 2 and is_equal_approx(leg[1].x, far_edge)),
			"and with a recipe's barricade on the street beyond it, it no longer does (%s)" % leg)

func _start(day: int) -> void:
	Rig.start(_stage, day)

func _test_day_populates_the_manager(t: TestRunner) -> void:
	_start(1)
	t.check(_stage.events().active_count() > 0, "starting a day puts events in the world")
	for instance in _stage.events().instances():
		t.check(is_instance_valid(instance), "every tracked instance is a live node")
		t.check(instance.row() != null, "every tracked instance has a def")

## The day the `--spawn` target cases plan: one that places events by the plan, before any is sited
## from her walk.
const _SPAWN_DAY := 6

## `DevRig.for_spawn_target()` as `main` asks it: the stage's day, no resistance mark.
func _spawn_at(target: String, told: Array[String]) -> Vector2:
	return DevRig.for_spawn_target(target, _stage.map(), _stage.events(), _stage.streets(), null,
			_stage.run().header(), RecordingTrace.new(told))

## `--spawn event` takes the first non-ambient placed plan: `start_day()` with streaming reaching
## the whole map places every plan without a player to stream one in, so the day's set has at least
## one, and the target puts her on a walkable tile beside it.
func _test_the_spawn_target_event_lands_near_a_placed_event(t: TestRunner) -> void:
	_start(_SPAWN_DAY)
	var told: Array[String] = []
	var at := _spawn_at("event", told)
	t.check(_stage.map().is_walkable(_stage.map().world_to_tile(at)),
			"--spawn event lands on a walkable tile (%s)" % at)

## A row sited from her walk (`cat_dash`) has no position at dawn, so `event:cat_dash` refuses
## rather than starting her on the doorstep as if nothing were wrong: the row and the reason land in
## the run log through the trace it is handed, and she is left on the doorstep.
func _test_a_queue_fed_row_refuses_the_spawn_target_by_name(t: TestRunner) -> void:
	_start(_SPAWN_DAY)
	var lines: Array[String] = []
	var at := _spawn_at("event:cat_dash", lines)
	t.check(at == _stage.map().home_world_position(),
			"a queue-fed row still leaves her somewhere to stand: the doorstep")
	var named := false
	for line in lines:
		if line.contains("spawn") and line.contains("cat_dash"):
			named = true
	t.check(named, "the refusal names the row in the run log (got %s)" % [lines])

## A row that waits (`EventDef.waits_for_her()`: the pigeon flock, the charging dog) and has a copy
## placed on the day: `event:<row>` stands her outside both its wait trigger and its field. The
## offset has to clear the larger of the two plus a tile's margin. The first such row the day placed
## is asked, since which rows a day places moves with the declared table (`PlacementDensity`).
func _test_a_waiting_row_stands_outside_its_trigger_at_the_spawn_target(t: TestRunner) -> void:
	_start(_SPAWN_DAY)
	_stage.events().draw_the_ground_round(Vector2.ZERO, INF)
	var found: EventPlan = null
	for plan in _stage.events().plans():
		if plan.notice_within() > 0.0 and plan.is_placed():
			found = plan
			break
	t.check(found != null, "day %d has a placed row that waits to stand outside of" % _SPAWN_DAY)
	if found == null:
		return
	var told: Array[String] = []
	var at := _spawn_at("event:" + found.row_id(), told)
	var dist := at.distance_to(found.placed_at())
	t.check(dist > found.notice_within(),
			"stands outside the wait trigger, %.0fpx > its notice's %.0fpx"
					% [dist, found.notice_within()])
	t.check(dist > found.heard_within(),
			"and outside the field itself, %.0fpx > outer_radius %.0fpx"
					% [dist, found.heard_within()])

## Before a day there is no plan to count, so the run log's `events:` line says none; once a walk's
## plans are taken it names each row the plan holds.
func _test_the_summary_names_what_the_day_planned(t: TestRunner) -> void:
	t.check(_stage.events().event_summary() == "none", "with no day planned the summary says none")
	var plans: Array[EventPlan] = [EventPlan.new(EventCatalogue.by_id("alley_robbery"),
			CrowdLanes.arterial_pavement(_stage.map()))]
	_stage.events().walk_events().take(plans)
	var summary := _stage.events().event_summary()
	t.check(summary != "none" and not _stage.events().plans().is_empty()
			and summary.contains(_stage.events().plans()[0].row_id()),
			"a planned day's summary names its rows (%s)" % [summary])

## A dog walker laid on a sidewalk of the day's city at a tile, as a scene recipe lays one
## (`EventScheduler.recipe_placement()`), walking six tiles along its street, and in the world:
## the one row on a day that walks a route and runs out at its end, since the director sends every
## other dog walker ahead of her (`EventDef.is_sent_ahead()`) rather than the day planning one. It
## joins the walk as a placed row does (`EventStreaming.add()`). Null on a city with no such stretch.
func _a_dog_walker_laid_in_the_world() -> EventPlan:
	var map := _stage.map()
	var size := map.size_in_tiles()
	for y in range(Tuning.STREET_WIDTH, size.y - Tuning.STREET_WIDTH):
		for x in range(Tuning.STREET_WIDTH, size.x - Tuning.STREET_WIDTH):
			var tile := Vector2i(x, y)
			var inward := map.pavement_inward(tile)
			if inward == Vector2i.ZERO:
				continue
			var along := Vector2i(inward.y, inward.x).abs()
			var clear := true
			for step in range(1, 7):
				clear = clear and map.pavement_inward(tile + along * step) == inward
			if not clear:
				continue
			var start := map.tile_to_world(tile)
			var plan := EventPlan.new(EventCatalogue.by_id("dog_walker"), start,
					PackedVector2Array([start, map.tile_to_world(tile + along * 6)]))
			_stage.events().streaming.add(plan)
			_stage.events().stream_around(start)
			return plan
	return null

func _test_finished_instances_are_dropped(t: TestRunner) -> void:
	_a_dog_walker_laid_in_the_world()
	# A bystander standing on, so the list a retirement leaves is not empty to be asked of.
	var bystander := EventPlan.new(EventCatalogue.by_id("burning_building"),
			CrowdLanes.arterial_pavement(_stage.map()) + Vector2(0.0, 600.0))
	_stage.events().streaming.add(bystander)
	_stage.events().stream_around(bystander.placed_at())
	# One that leaves nothing behind and runs out on its own, stepped the way the manager steps it.
	var victim: EventInstance = null
	for instance in _stage.events().instances():
		if instance.leaves_behind() == "" and _run_to_its_end(instance):
			victim = instance
			break
	t.check(victim != null, "there is an event that leaves nothing behind and runs out")
	var before := _stage.events().active_count()
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(_stage.events().active_count() == before - 1, "a finished event is dropped")
	for instance in _stage.events().instances():
		t.check(is_instance_valid(instance),
				"no freed node is left in the list after a retirement")

## Steps `instance` a second at a time, nobody told where she is, until it has run its course;
## whether it did within an hour of them.
func _run_to_its_end(instance: EventInstance) -> bool:
	for _second in 3600:
		if instance.is_gone():
			return true
		instance.step(1.0)
	return instance.is_gone()

## The bug this exists for: one event finishing and spawning one successor leaves the list
## the same LENGTH, so a size comparison concluded nothing had changed — and left a freed
## node in the array while never tracking the successor at all.
##
## `finale_explosion`/`impact_crater`, the one row `aftermath.leaves_behind()` governs: a burst that has
## run its course leaves its crater where it went off. Spawned directly, since the escape's rows are
## not a day's.
func _test_successor_replaces_its_parent(t: TestRunner) -> void:
	# A bystander standing on, so a swap that kept only the successors would change the count and
	# leave the list without it.
	var bystander := EventPlan.new(EventCatalogue.by_id("burning_building"),
			CrowdLanes.arterial_pavement(_stage.map()) + Vector2(0.0, 600.0))
	_stage.events().streaming.add(bystander)
	_stage.events().stream_around(bystander.placed_at())
	var burst := _stage.events().spawner.spawn(EventCatalogue.by_id("finale_explosion"),
			Vector2(500, 500))
	var before := _stage.events().active_count()
	t.check(_run_to_its_end(burst), "the burst runs out on its own")
	var where := burst.global_position
	await PhysicsTicks.pass_ticks(t, 1)

	t.check(_stage.events().active_count() == before,
			"a one-for-one replacement keeps the count the same")
	var crater: EventInstance = null
	for instance in _stage.events().instances():
		t.check(is_instance_valid(instance), "no freed node survives a successor swap")
		if instance.row_id() == "impact_crater":
			crater = instance
	t.check(crater != null, "the burst leaves a crater behind it")
	if crater:
		t.close_to(crater.global_position.distance_to(where), 0.0,
				"the crater starts where the burst went off", 1.0)

func _test_excitement_sums_over_instances(t: TestRunner) -> void:
	var here := CrowdLanes.arterial_pavement(_stage.map())
	for row: String in ["burning_building", "alley_robbery", "charging_dog"]:
		_stage.events().streaming.add(EventPlan.new(EventCatalogue.by_id(row), here))
	_stage.events().stream_around(here)
	var instances := _stage.events().instances()
	t.check(instances.size() > 1, "there are several events to sum")

	var at: Vector2 = instances[0].global_position
	var expected := 0.0
	for instance in instances:
		expected += instance.source().contribution_at(at)
	t.close_to(_stage.events().excitement_sources().total_at(at), expected,
			"the manager's total is the sum of the instances' contributions")

	var far := Vector2(-10000.0, -10000.0)
	t.close_to(_stage.events().excitement_sources().total_at(far), 0.0,
			"nothing reaches a point outside every radius")

# ---------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"don't load everything upfront."* The day is still planned across the whole
# city, so every invariant stated over a day survives; what changed is when a plan becomes a
# node. These are the two properties that make that legal.

## An event is in the world exactly when the player is near it. The distances matter: the
## streaming radius has to be wider than the widest field in the catalogue, or an event would
## appear *already inside* its own outer radius and the fairness contract would be a lie.
func _test_an_event_waits_until_she_is_near_it(t: TestRunner) -> void:
	_stage.events().stream_within(Tuning.EVENT_STREAM_RADIUS)
	# Not mobile: a route means the reach is measured to the nearest point of it, which is a
	# different check.
	var plan := EventPlan.new(EventCatalogue.by_id("burning_building"),
			CrowdLanes.arterial_pavement(_stage.map()))
	_stage.events().streaming.add(plan)
	t.check(plan.is_placed() and plan.walks().is_empty(),
			"there is a stationary event somewhere in the city")

	var at := plan.placed_at()
	var away := at + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0)
	_stage.events().stream_around(away)
	t.check(not plan.is_in_the_world(), "an event across the city is not in the world")

	_stage.events().stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS - 40.0, 0.0))
	t.check(plan.is_in_the_world(), "walking into reach of it puts it there")
	var arrived := _live(plan)
	t.check(arrived.age() <= 0.0 or arrived.is_telegraphing(),
			"and it starts its telegraph on arrival, so the warning is not spent off-screen")

	# The hysteresis: a player pacing on the boundary must not rebuild it every other frame,
	# because a rebuilt instance telegraphs again and would crouch at her forever.
	_stage.events().stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS + 40.0, 0.0))
	t.check(_live(plan) == arrived, "stepping just past the edge does not take it away again")
	_stage.events().stream_around(away)
	t.check(not plan.is_in_the_world(), "walking properly away does")

	t.check(Tuning.EVENT_STREAM_RADIUS > _widest_field(),
			"an event streams in from further out (%.0f) than its own reach (%.0f), so it is "
			% [Tuning.EVENT_STREAM_RADIUS, _widest_field()]
			+ "never already on top of her when it appears")

func _widest_field() -> float:
	var widest := 0.0
	for def in CatalogueRows.every():
		widest = maxf(widest, def.heard_within())
	return widest

## The other half, and the one a naive implementation gets wrong: an event that has already
## happened must not happen again because she walked back past it. Streaming is allowed to take
## an event away and give it back while it is *running*; it is not allowed to rewind it.
func _test_an_event_that_has_run_does_not_run_again(t: TestRunner) -> void:
	_stage.events().stream_within(Tuning.EVENT_STREAM_RADIUS)
	_a_dog_walker_laid_in_the_world()
	var plan: EventPlan = null
	# One that leaves nothing behind and, walked up to, runs out on its own (a dog walker's route
	# ends; a parked van never does).
	for candidate in _stage.events().plans():
		if candidate.is_placed() and candidate.row().leaves_behind() == "" \
				and candidate.walks().size() > 1:
			_stage.events().stream_around(candidate.placed_at())
			if candidate.is_in_the_world() and _run_to_its_end(_live(candidate)):
				plan = candidate
				break
	if not plan:
		t.check(false, "there is an event that runs out on its own")
		_stage.events().stream_within(INF)
		return

	_stage.events().stream_around(plan.placed_at())
	t.check(plan.is_in_the_world(), "she walks up to it and it is there")
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(plan.is_spent() and not plan.is_in_the_world(), "it runs its course and the plan is spent")

	_stage.events().stream_around(plan.placed_at() + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	_stage.events().stream_around(plan.placed_at())
	t.check(not plan.is_in_the_world(), "and coming back does not start it over")
	_stage.events().stream_within(INF)

## The third case, and the one that was actually wrong. *(M31.)* An event that is still
## **running** may be taken away and given back — but it has to come back where it got to, not
## where the day put it at dawn.
##
## Reported as *"dog walkers are not moving?"*, which they were: at 32px/s a dog walker covers a
## tile a second, and every time the player left its radius and came back it was rebuilt from
## `plan.placed_at()` and teleported to the top of its street. At a third of her walking speed that
## is most times, so from outside it was an event that never went anywhere.
func _test_a_running_event_comes_back_where_it_got_to(t: TestRunner) -> void:
	_stage.events().stream_within(Tuning.EVENT_STREAM_RADIUS)
	_a_dog_walker_laid_in_the_world()
	var plan: EventPlan = null
	for candidate in _stage.events().plans():
		if candidate.is_placed() and candidate.row().moves() and candidate.walks().size() > 1 \
				and not candidate.row().holds_still():
			plan = candidate
			break
	t.check(plan != null, "there is something walking down a street")
	if not plan:
		_stage.events().stream_within(INF)
		return

	_stage.events().stream_around(plan.placed_at())
	t.check(plan.is_in_the_world(), "she comes near it and it is there")
	var started := _live(plan).global_position
	for i in 120:
		_live(plan).step(1.0 / 60.0)
	var walked := _live(plan).global_position
	t.check(started.distance_to(walked) > 1.0,
			"it covers ground while she is watching (%.0fpx in 2s)"
			% started.distance_to(walked))
	var aged := _live(plan).age()

	_stage.events().stream_around(plan.placed_at() + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	t.check(not plan.is_in_the_world(), "she walks away and it leaves the world")
	_stage.events().stream_around(walked)
	t.check(plan.is_in_the_world(), "she comes back and it is there again")
	if _live(plan):
		t.check(_live(plan).global_position.distance_to(walked) < 1.0,
				"and it is where it had got to, not back at the top of its street (%.0fpx off)"
				% _live(plan).global_position.distance_to(walked))
		# The age comes back with it, so an event cannot be made immortal by being visited
		# twice — its telegraph, its pulse and its duration all carry on rather than restart.
		t.check(absf(_live(plan).age() - aged) < 0.01,
				"and it is as old as it was, so revisiting cannot restart its clock")
	_stage.events().stream_within(INF)

## **A day started through the manager is planned against the streets it was handed**
## (`EventManager.setup()`, the city's `DayStreets`), never against a tree of its own: after the
## city's own dawn (`City.start_day()`), the walk the manager planned is the dawn's route tree, and
## every street the dawn closed and every segment of its region wall is held before the catalogue
## rolls a candidate (`CityMap.held_streets()`), and the day's plans are the dawn's own wall and door
## bodies. A planner that grew its own tree would plan a walk that is not the dawn's, one that read
## no closures would leave a closed street unheld, and one that grew its own region plan would place
## bodies of its own beside the ones the siting and the crowd read.
func _test_a_day_started_through_the_manager_is_planned_on_its_streets(t: TestRunner) -> void:
	var day := Tuning.REGION_WALL_FIRST_DAY  # so a region wall is in play, not only seals.
	var state := CityState.new()
	state.begin_day(_stage.map().plans_by_block(), day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("m100-seals:closures:%d" % day)
	_stage.city().start_day(state, day, closures_rng)
	var consumed: Array[String] = []
	_stage.events().start_day(DaySpec.for_day(day), Rig.rng(day), consumed)
	var streets := _stage.streets()
	t.check(streets.route_tree() != null and _stage.events().walk() == streets.route_tree(),
			"the day the manager planned walks the tree the city's dawn grew")
	var held := _stage.map().held_streets()
	t.check(not streets.closures().is_empty(),
			"the dawn closed streets to hold (%d)" % streets.closures().size())
	for closure in streets.closures():
		t.check(held.has(closure.street_key()), "the street the dawn closed (%s) is held"
				% closure.street_key())
	t.check(not streets.region_plan().wall_segments().is_empty(),
			"the dawn grew a region wall to hold (%d segments)"
			% streets.region_plan().wall_segments().size())
	for segment in streets.region_plan().wall_segments():
		t.check(held.has(segment.key()), "the region wall's segment %s is held" % segment.key())
	# The very bodies of the dawn's region plan are the day's, not those of a plan grown again from
	# the same tree: the siting's region and the crowd's gates read the streets' plan.
	var bodies: Array[EventPlan] = streets.region_plan().wall_plans() \
			+ streets.region_plan().door_plans()
	var plans := _stage.events().plans()
	var among := 0
	for body in bodies:
		if plans.has(body):
			among += 1
	t.check(not bodies.is_empty(), "the dawn's region plan has bodies to find (%d)" % bodies.size())
	t.check(among == bodies.size(),
			"every wall and door body of the dawn's region plan is among the day's plans (%d of %d)"
			% [among, bodies.size()])


## M100, small, real, and nobody's: the wiring half of "a pursuer streamed out mid-chase comes
## back having forgotten it." `tests/test_heat.gd` already drives `EventInstance.restore()` directly
## and pins that its save restores the notice; the gap that shipped anyway
## was one level up — `EventPlan` had no field to hold the notice, so
## `EventStreaming.stream_in()` always restored a save with the default `INF` notice and a
## row that waits for her (`EventDef.waits_for_her()`) streamed out mid-chase came back
## `is_waiting()`, standing where the day planted it. This drives the same encounter through
## `EventStreaming.stream_in()`/`stream_out()` themselves, the only place that bug could
## actually live — the same kind of wiring question the rest of this suite exists for (see the
## class doc above).
##
## `alley_robbery` rather than a scheduled plan: it waits for her (`EventDef.waits_for_her()`) cold,
## with no heat level or a particular day's roll needed to reach it, and a `EventPlan` built by
## hand is deterministic where waiting for the scheduler to place one on some day would not be.
func _test_a_streamed_pursuer_resumes_the_chase(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var plan := EventPlan.new(def, Vector2(500.0, 500.0))

	_stage.events().streaming.stream_in(plan)
	t.check(plan.is_in_the_world(), "the hand-built plan streams in like any other")
	if not _live(plan):
		return

	var her := plan.placed_at() + Vector2(def.notice_within() - 10.0, 0.0)
	_stage.events().world.where_she_is().tell(her)
	_live(plan).step(1.0 / 60.0)
	t.check(not _live(plan).is_waiting(), "she is inside the trigger, so it notices her")
	for i in 60:
		_stage.events().world.where_she_is().tell(her)
		_live(plan).step(1.0 / 60.0)
	t.check(not _live(plan).is_waiting(), "and a second later it is still chasing, not patrolling")
	var noticed_at_before := _live(plan).save().noticed_at()

	_stage.events().streaming.stream_out(plan)
	t.check(not plan.is_in_the_world(), "streaming out through the manager clears the live instance")
	t.check(plan.saved().noticed_at() != INF,
			"and the plan itself remembers when it noticed her, not just the freed instance")

	_stage.events().streaming.stream_in(plan)
	t.check(plan.is_in_the_world(), "streaming back in rebuilds it")
	if _live(plan):
		t.check(not _live(plan).is_waiting(),
				"streamed back in through EventManager it is still chasing, not waiting")
		t.close_to(_live(plan).save().noticed_at(), noticed_at_before,
				"and the notice kept the start it was carried with rather than restarting at it", 0.05)

## **A row warned of down her line is created with its telegraph spent, at its own intensity from
## its first frame.** *(2026-09-20: "unleashed dog still has too little influence -- needs to be more
## intense".)* `EventInstance.is_lethal_at()` refuses the whole telegraph and `_notice_damping()`
## holds the field at `EventInstance.TELEGRAPH_INTENSITY_FRACTION` through it, so a row that arrived still
## telegraphing would ride past her unable to do the one thing it is for — the kill for a lethal
## row, the noise for a loud one. The warning was the telegraph, so the thing it warned of is created
## past it.
##
## Asked of the game's own path on a real city, every `TOWARD_PLAYER` row on foot: for one that
## telegraphs, the director's warning, which the manager's own ticks put up when she walks up the
## arterial's sidewalk with the row owed her, and the instance it creates once its warning is over;
## for one that does not (`loose_dog`), the instance created at once with no warning. On its first
## frame it is not telegraphing, its field is undamped, and a lethal row is lethal at its own centre.
func _test_a_row_warned_down_her_line_arrives_at_its_own_intensity(t: TestRunner) -> void:
	var map := _stage.map()
	var checked: Array[String] = []
	var events := _stage.events()
	var rig: Stroller = null
	for def in CatalogueRows.every():
		if not def.comes_down_her_line():
			continue
		checked.append(def.id())
		# Nothing planned and nothing sited ahead of her, then the one row owed her from a route bag
		# holding nothing else, as a scene's recipe hands it (`EventManager.start_recipe_route()`),
		# due as soon as she is walking.
		var nothing: Array[EventPlan] = []
		events.start_recipe(nothing, DaySpec.for_day(Tuning.RUN_TAUGHT_DAY + 2),
				Tuning.RUN_TAUGHT_DAY + 2, Vector2.ZERO)
		var owed := events.start_recipe_route([def.id()], [def.id()], 1, 0.0)
		t.check(owed == 1, "the director owes her '%s' (%d)" % [def.id(), owed])
		var her := CrowdLanes.arterial_pavement(map)
		for _tile in map.size_in_tiles().y / 2:
			if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
				break
			her.y += Tuning.TILE_SIZE
		if rig == null:
			rig = Rig.walker(t, _stage, her)
		rig.global_position = her
		rig.velocity = Vector2.ZERO
		events.use_player(rig)
		var before := events.instances().duplicate()
		var warnings_before := events.pending_warnings().size()
		# She walks up the sidewalk by hand, one tick a frame, until the manager's own tick has sent
		# the row: its warning is up, or, for a row that does not telegraph, it is in the world.
		# The warning is looked for before the arrival on every tick, so a warning and a row made on
		# one tick are told apart from a warning that went up first.
		var seen := {"arrived": null, "warned_at": -1, "arrived_at": -1, "tick": 0,
				"warnings_at_arrival": -1}
		var each := func(_n: int) -> void:
			if seen["arrived"] != null:
				return
			seen["tick"] += 1
			if seen["warned_at"] < 0 and events.pending_warnings().size() > warnings_before:
				seen["warned_at"] = seen["tick"]
			for instance in events.instances():
				if instance.row_id() == def.id() and not before.has(instance):
					seen["arrived"] = instance
					seen["arrived_at"] = seen["tick"]
					seen["warnings_at_arrival"] = events.pending_warnings().size()
			if seen["arrived"] == null and seen["warned_at"] < 0:
				rig.velocity = Vector2.UP * Tuning.WALK_SPEED
				rig.global_position += rig.velocity * Rig.WALK_STEP
			else:
				rig.velocity = Vector2.ZERO
		var ticks := 0
		var limit := PhysicsTicks.ticks_for(def.telegraphs_for() + 10.0, Rig.WALK_SCALE)
		while seen["arrived"] == null and ticks < limit:
			await PhysicsTicks.pass_ticks(t, 1, each, Rig.WALK_SCALE)
			ticks += 1
		if not def.telegraphs_its_coming():
			t.check(seen["warned_at"] < 0 and seen["arrived"] != null
					and seen["warnings_at_arrival"] == warnings_before,
					"'%s' does not telegraph: no warning goes up for it, it is created at once" % def.id())
		else:
			t.check(seen["warned_at"] >= 0 and seen["warned_at"] < seen["arrived_at"],
					"'%s' is warned of down her line on a tick before it exists (warned on %d, made on %d)"
					% [def.id(), seen["warned_at"], seen["arrived_at"]])
		var arrived: EventInstance = seen["arrived"]
		t.check(arrived != null, "'%s' is sent down her line and created" % def.id())
		if not arrived:
			continue
		t.check(not arrived.is_telegraphing() and is_equal_approx(arrived.current_intensity(1.0), def.peak()),
				("'%s' is created with its telegraph spent, emitting at its own intensity rather "
				% def.id()) + "than the telegraph's %.0f%%" % (EventInstance.TELEGRAPH_INTENSITY_FRACTION * 100.0))
		if def.ends_the_day():
			t.check(arrived.is_lethal_at(arrived.global_position),
					"and '%s', declared as ending the day, is lethal from its first frame" % def.id())
		events.retire(arrived)
	if rig:
		events.use_player(null)
		rig.free()
	for id: String in ["cyclist", "loose_dog"]:
		t.check(checked.has(id), "'%s' is among the rows sent down her line (%s)"
				% [id, ", ".join(checked)])

## **The ground the dawn made is the walk's** (`DawnContext.ground()` at dawn,
## `DayPlanner.Plan.use_ground()`, `EventManager._take()`, `WalkEvents.ground()`): a day started
## through the manager carries one, so what is sited while she walks is not made a ground of its
## own by `EventsAhead._ground_of_the_walk()`'s fallback, which would scan the city a second time
## and change no answer, so nothing else here would show the link dropped.
func _test_the_walk_is_handed_the_ground_the_dawn_made(t: TestRunner) -> void:
	_start(1)
	t.check(_stage.events().walk_events().ground() != null,
			"a day started through the manager carries the ground the dawn made for its walk")

## **What is sited on her walk asks the ground the walk carries** (`EventsAhead.start_day()` hands
## `WalkEvents.ground()` to the siting it makes for a plan left for her walk): a ground that counts
## its asks is handed to the walk, the director's day is started over it again, and the siting's
## one-time scans (`WalkSiting.prepare()`) ask it. A siting handed a ground of its own would leave
## the count at zero.
func _test_what_is_sited_on_her_walk_asks_the_ground_the_walk_carries(t: TestRunner) -> void:
	var asked := -1
	# Day 3 is the first day to leave a plan for her walk to site (its fire).
	var day := Tuning.RUN_TAUGHT_DAY
	_start(day)
	var left_for_her_walk := false
	for plan in _stage.events().plans():
		if plan.row().is_sited_from_her_walk() and not plan.is_placed():
			left_for_her_walk = true
	if left_for_her_walk:
		var walk := _stage.events().walk_events()
		var counting := _CountingGround.new(_stage.map(), null, true, RowGround.Weights.new(),
				func(_row: EventDef) -> bool: return false)
		walk.take(walk.plans(), walk.calm(), walk.doors(), walk.reach(), walk.locations(), counting)
		_stage.events().ahead.start_day(day, _stage.events().walk())
		asked = counting.asks
	t.check(asked >= 0, "a day leaves a plan for her walk to site")
	t.check(asked > 0, "and the siting made for it asks the ground the walk carries (%d asks)" % asked)

## The live event of `plan`, asked of the city's event manager.
func _live(plan: EventPlan) -> EventInstance:
	return _stage.events().event_of(plan)

## **The cyclist is warned by himself first, for at most a second, and then comes into view at once
## where the warning pointed.** *(2026-09-25: "I feel the same with the biker. it gets warned too
## early so most of the time you're already gone when anything happens." · PLAYTEST-145: "the
## warning appears by itself with a reasonable position and when the time is right the object is
## spawned in at that location just offscreen" · "the biker needs to stay on the sidewalk";
## calm-kestrel, inbox #559: "show the warning for x seconds (never longer than 2s) without placing
## anything then place the object immediately off screen so it will immediately start coming on the
## screen turning off the warning ... they jump around wildly"; busy-quail, inbox #569: "1s warning
## should be enough".)*
##
## On the real map, with the warning held the way `EventManager` holds one (`warn_first()`,
## `WarningBoard.run()`) and read by a real `DangerEdge`, while she walks up her sidewalk and steps
## out onto the carriageway and back:
##
## - **the badge is up with nothing in the world**, for no more than `Tuning.WARNING_ALONE_MAX`;
## - **the badge holds still**: its place keeps the same offset from her every frame, so it moves
##   only with her own walking and never jumps to another piece of ground;
## - **he is created once his second is up, on a sidewalk, wholly out of sight, with his telegraph
##   spent**, and he comes into sight as soon as he moves — or, where the ground just out of sight is
##   a cross street's carriageway and his sidewalk is beyond it, as soon as he has ridden that far —
##   which takes the badge down.
##
## Then, walked by `M207Lead.measure()` (`tests/probes/m207_warning_lead.gd`, the probe that prints
## every warned row's lead) on open ground on both axes: **from the badge to his reach, walking into
## him, is at least the contract's floor**, exactly his second and then his approach from just out of
## sight, and standing still he still reaches her no sooner than the floor.
func _test_the_cyclist_is_warned_shortly_before_he_arrives(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("cyclist")
	t.check(def.warned_for() <= Tuning.WARNING_ALONE_MAX,
			"his badge is up alone for %.2fs, at most %.2fs" % [def.warned_for(), Tuning.WARNING_ALONE_MAX])
	var map := Rig.MapCache.of(Rig.SEED)
	# Her own kerb-side sidewalk beside the arterial, walking north from a point where the place just
	# out of sight ahead of her is on a sidewalk too rather than in the carriageway of a cross street.
	var her := CrowdLanes.arterial_pavement(map)
	for _tile in map.size_in_tiles().y / 2:
		if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
			break
		her.y += Tuning.TILE_SIZE
	# Handed the city map, drawn in a node of its own, and a run (`EventManager.setup()` with no
	# streets, lights or poster walls), as a rig that builds no city hands them.
	var holder := WorldContext.new()
	t.add_child(holder)
	var run := RunState.new()
	var atlas := AtlasLibrary.new()
	atlas.acquire(&"events")
	# The page every event made here is drawn from, as `main` hands the manager its library.
	var manager := EventManager.new(EventSurroundings.new().in_the_city(map).drawn_in(holder)
			.drawn_from(atlas))
	manager.setup(run)
	var player := Node2D.new()
	t.add_child(player)
	player.global_position = her
	var edge := DangerEdge.new()
	edge.use_atlas(atlas)
	edge.size = Vector2(1280.0, 720.0)
	t.add_child(edge)
	edge.setup(manager, player)
	manager.visible_view().look(VisibleView.around(her, null).camera_view(), null)
	var created: Array[EventInstance] = []
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.down_her_line(map, def, at, Vector2.UP, VisibleView.around(at, null))
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var path := PendingWarning.route_down_her_line(map, place, at, Vector2.UP)
		# Created as the game's own arrival creates him (`EventSpawner.spawn_warned()`), so he is
		# in the manager's own list and the edge measures him as it does the game's own badge.
		created.append(manager.spawn_warned(def, path))
		return true
	var warning := manager.warn_first(def, her, where, arrive)
	t.check(warning != null, "the cyclist's warning goes up on the sidewalk she is walking")
	if not warning:
		manager.free()
		holder.free()
		edge.free()
		atlas.release(&"events")
		return
	# The edge is in the tree and measures on the frame the engine gives it; the frame after this one
	# has read the badge up.
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var badged := false
	for badge in edge.badges().announcing():
		badged = badged or badge.logged_name() == "cyclist"
	t.check(badged and created.is_empty(), "its badge is up with nothing in the world yet")

	var ground := [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	var offset := warning.points_at() - her
	var elapsed := 0.0
	var looked := 0
	var jumped := 0
	var came_at := INF
	while elapsed < Tuning.WARNING_ALONE_MAX + 1.0:
		# North up the sidewalk, then a stride out onto the carriageway and back.
		var step := Vector2.UP
		if elapsed > 0.3 and elapsed <= 0.6:
			step = Vector2.RIGHT
		elif elapsed > 0.6 and elapsed <= 0.9:
			step = Vector2.LEFT
		her += step * Tuning.WALK_SPEED * STEP
		manager.visible_view().look(VisibleView.around(her, null).camera_view(), null)
		manager.warnings.run(STEP, her)
		elapsed += STEP
		if not created.is_empty():
			came_at = elapsed
			break
		looked += 1
		if not (warning.points_at() - her).is_equal_approx(offset):
			jumped += 1
	t.check(looked > 0 and jumped == 0,
			"it was watched (%d frames) and its place kept its offset from her every frame (%d not)"
			% [looked, jumped])
	t.check(created.size() == 1 and came_at <= Tuning.WARNING_ALONE_MAX + 2.0 * STEP,
			"he is created once his %.2fs badge is over (%.2fs)" % [def.warned_for(), came_at])
	if created.size() == 1:
		var bike := created[0]
		var view := VisibleView.around(her, null)
		t.check(ground.has(map.tile_at(map.world_to_tile(bike.global_position))),
				"on a sidewalk")
		t.check(SpawnSiting.is_out_of_sight(view, EventFootprints.footprint_of(def), her,
				bike.global_position),
				"wholly out of sight the frame he exists")
		t.check(not bike.is_telegraphing(), "with his telegraph already spent, so he can end the day")
		var into_sight := INF
		var gone := INF
		var since := 0.0
		player.global_position = her
		while since < 1.0 and (into_sight == INF or gone == INF):
			bike.step(STEP)
			since += STEP
			await t.get_tree().process_frame
			var box := EventFootprints.footprint_of(def)
			if into_sight == INF and manager.visible_view().sees_any(
					Rect2(bike.global_position + box.position, box.size)):
				into_sight = since
			var still_badged := false
			for badge in edge.badges().announcing():
				still_badged = still_badged or badge.logged_name() == "cyclist"
			if gone == INF and not still_badged:
				gone = since
		# At once from just out of sight; where its ground is further — the carriageway of a cross
		# street just out of sight, so the far sidewalk — as soon as he has ridden the difference.
		var just_out := SpawnSiting.just_out_of_sight(view, EventFootprints.footprint_of(def), her,
				Vector2.UP)
		var further := maxf(0.0, (bike.walks()[0] - just_out).dot(Vector2.UP))
		t.check(into_sight <= further / def.speed() + 3.0 * STEP,
				"and he comes into sight as soon as he has ridden the %.0fpx his ground put him past "
				% further + "just out of sight (%.2fs after he exists)" % into_sight)
		t.check(gone <= into_sight + 0.2,
				"and the badge goes down as he comes into sight (%.2fs, in sight at %.2fs)" % [gone, into_sight])
	edge.free()
	player.free()
	manager.free()
	holder.free()
	atlas.release(&"events")

	var walked := 0
	for encounter in M207Lead.encounters():
		var row: EventDef = encounter["def"]
		if row.id() != "cyclist":
			continue
		walked += 1
		var floor_s := row.minimum_telegraph()
		var probe_edge := DangerEdge.new()
		var toward := M207Lead.measure(encounter, M207Lead.Answer.TOWARD, probe_edge)
		t.check(toward["by"] == "badge" and toward["lead"] < INF,
				"cyclist (%s): the badge warns her before he can hit her (by %s, %.2fs)"
				% [encounter["how"], toward["by"], toward["lead"]])
		t.check(toward["lead"] >= floor_s,
				"cyclist (%s): walking into him she is warned %.2fs ahead, at least the %.2fs floor"
				% [encounter["how"], toward["lead"], floor_s])
		# What the walk measures is the contract's own figure on this axis: his second, then his
		# approach from just out of sight to his reach. The horizontal axis adds only the wider view.
		var heading: Vector2 = encounter["heading"]
		var closing := row.speed() + Tuning.WALK_SPEED
		var created_at := PendingWarning.down_her_line(null, row, Vector2.ZERO, heading).length()
		var predicted := row.warned_for() + (created_at - row.lethal_reach()) / closing
		t.close_to(toward["lead"], predicted,
				"cyclist (%s): which is his second and then his approach from just out of sight"
				% encounter["how"], 3.0 * STEP)
		var stood := M207Lead.measure(encounter, M207Lead.Answer.STAND, probe_edge)
		t.check(stood["lead"] < INF and stood["lead"] >= floor_s,
				"cyclist (%s): standing on his line she is still reached, %.2fs after the warning"
				% [encounter["how"], stood["lead"]])
		probe_edge.free()
	t.check(walked >= 2, "the cyclist was walked on both axes (%d)" % walked)

## **The route-redundancy guarantee with it parked** (the **city** skill: a day leaves distinct
## routes from home to its calm areas, counted as a max flow, `StreetNetwork.route_count()`). The
## engine parks on the carriageway's near tile across from the fire
## (`CityMap.kerb_across_from()`), its body a capsule along the street. On a real
## city, at every such kerb tried, every tile the body overlaps at all is blocked; the street it
## stands in counts as closed unless a way along it past the body is left inside its own corridor;
## and every calm area must keep as many distinct routes from home, up to two, as it had without
## it. The same check run with a body the street's whole width finds the street closed, which is
## what shows it can fail; the lattice leaves every calm area its routes past most single closed
## streets, so the count of routes lost is reported for it rather than required.
func _test_a_parked_body_closes_no_street(t: TestRunner) -> void:
	var map := Rig.MapCache.of(Rig.SEED)
	var kerbs := _kerbs(map)
	t.check(kerbs.size() >= 20, "enough kerbs were tried (%d)" % kerbs.size())
	var truck := EventCatalogue.by_id("fire_truck").ground_shape()
	var lost := _routes_lost(map, kerbs, truck)
	t.check(lost.x == 0 and lost.y == 0,
			"with the parked engine's tiles blocked, no street is closed (%d) and no calm area "
			% lost.x + "loses a route from home (%d)" % lost.y)
	var street := float(Tuning.STREET_WIDTH * Tuning.TILE_SIZE)
	var wide := _routes_lost(map, kerbs, GroundShape.segment(truck.spine_half_length(), street))
	t.check(wide.x > 0,
			"and a body the street's whole width closes the street it stands in (%d of %d kerbs; "
			% [wide.x, kerbs.size()] + "%d calm areas then lose a route)" % wide.y)

## The kerbs a summoned engine can park at on `map`, as `[park, along]`: the carriageway tile
## against the kerb across from every sidewalk tile beside a carriageway
## (`CityMap.kerb_across_from()`, the same tile from either sidewalk tile of a kerb), sampled across
## the map, and the street's own axis there.
func _kerbs(map: CityMap) -> Array[Array]:
	var kerbs: Array[Array] = []
	var tile_count := map.size_in_tiles().x * map.size_in_tiles().y
	var step := maxi(1, tile_count / 160)
	for index in range(0, tile_count, step):
		var tile := Vector2i(index % map.size_in_tiles().x, index / map.size_in_tiles().x)
		var inward := map.pavement_inward(tile)
		if inward == Vector2i.ZERO:
			continue
		var park := map.kerb_across_from(map.tile_to_world(tile))
		if park == Vector2.INF or not Tile.is_road(map.tile_type_at_world(park)):
			continue
		kerbs.append([park, Vector2(absf(float(inward.y)), absf(float(inward.x)))])
	return kerbs

## With `body` parked at each of `kerbs`: how many times the street it stands in is closed, as
## `x`, and how many calm areas have fewer distinct routes from home than without it, as `y`.
func _routes_lost(map: CityMap, kerbs: Array[Array], body: GroundShape) -> Vector2i:
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	var open := map.blocked_segments()
	var before: Array[int] = []
	for area in areas:
		before.append(map.street_network().route_count(home, area.access, open, 2))
	var lost := Vector2i.ZERO
	for kerb: Array in kerbs:
		var park: Vector2 = kerb[0]
		var along: Vector2 = kerb[1]
		var blocked := _tiles_touched(body, park, along)
		var segment := map.street_network().segment_containing(map.world_to_tile(park))
		if segment == null or _passes(map, park, along, body, blocked):
			continue
		lost.x += 1
		var closed := open.duplicate()
		closed[segment.key()] = true
		for i in areas.size():
			if map.street_network().route_count(home, areas[i].access, closed, 2) < before[i]:
				lost.y += 1
	return lost

## Every tile `body`, parked at `at` along `along`, overlaps at all — not only the tiles whose
## centres it covers, which for a 26px body is one tile in six across the street.
func _tiles_touched(body: GroundShape, at: Vector2, along: Vector2) -> Dictionary:
	var size := float(Tuning.TILE_SIZE)
	var spine := Rect2(at - along * body.spine_half_length(), Vector2.ZERO).expand(at + along * body.spine_half_length())
	var reach := ceili((body.spine_half_length() + body.rounding_radius()) / size) + 1
	var centre := Vector2i(floori(at.x / size), floori(at.y / size))
	var touched := {}
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			var box := Rect2(Vector2(tile) * size, Vector2.ONE * size)
			var gap := Vector2(
					maxf(0.0, maxf(box.position.x - spine.end.x, spine.position.x - box.end.x)),
					maxf(0.0, maxf(box.position.y - spine.end.y, spine.position.y - box.end.y)))
			if gap.length() < body.rounding_radius():
				touched[tile] = true
	return touched

## Whether, with `blocked` closed, she can still walk along the street at `at` past `body`, inside
## the street's own corridor: from the walkable tiles across it a few tiles before the body to
## those a few tiles after it.
func _passes(map: CityMap, at: Vector2, along: Vector2, body: GroundShape,
		blocked: Dictionary) -> bool:
	var vertical := along.y > 0.5
	var tile := map.world_to_tile(at)
	var cross := tile.x if vertical else tile.y
	var first := cross - CityMap.corridor_offset(cross)
	var down := tile.y if vertical else tile.x
	var span := ceili((body.spine_half_length() + body.rounding_radius())
			/ float(Tuning.TILE_SIZE)) + 2
	var make := func(a: int, c: int) -> Vector2i:
		return Vector2i(c, a) if vertical else Vector2i(a, c)
	var open := func(at_tile: Vector2i) -> bool:
		return map.in_bounds(at_tile) and map.is_walkable(at_tile) and not blocked.has(at_tile)
	var seen := {}
	var queue: Array[Vector2i] = []
	for c in range(first, first + Tuning.STREET_WIDTH):
		var start: Vector2i = make.call(down - span, c)
		if open.call(start):
			seen[start] = true
			queue.append(start)
	var head := 0
	while head < queue.size():
		var here := queue[head]
		head += 1
		var a := here.y if vertical else here.x
		if a == down + span:
			return true
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := here + step
			var a_next := next.y if vertical else next.x
			var c_next := next.x if vertical else next.y
			if a_next < down - span or a_next > down + span or c_next < first \
					or c_next >= first + Tuning.STREET_WIDTH:
				continue
			if seen.has(next) or not open.call(next):
				continue
			seen[next] = true
			queue.append(next)
	return false

## **Nothing comes at her from off screen unwarned.** *(PLAYTEST-145: "all offscreen events should
## work like that".)* Every pursuer that is sent rather than met — no trigger to wait on, and not
## set off beside her at a door — is warned of first: the resistance's own two by their rows, and the
## day-3 dog by the copy `EventSpawner.as_warned()` makes as the director sends it. Each one's badge
## alone is at most `Tuning.WARNING_ALONE_MAX`.
func _test_every_pursuer_sent_from_off_screen_is_warned_first(t: TestRunner) -> void:
	var sent := 0
	for def in CatalogueRows.every():
		if not def.pursues() or def.notice_within() > 0.0 or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER):
			continue
		sent += 1
		var warned := EventSpawner.as_warned(def)
		t.check(warned.warns_before_it_exists() and warned.warned_for() <= Tuning.WARNING_ALONE_MAX,
				"'%s' is warned first, its badge alone %.2fs, at most %.2fs"
				% [def.id(), warned.warned_for(), Tuning.WARNING_ALONE_MAX])
	t.check(sent >= 3, "the dog and the resistance's two are among them (%d)" % sent)
