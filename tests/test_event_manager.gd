extends RefCounted
## EventManager against a real generated City.
##
## Everything else in the event tests runs on plain data. This one builds an actual city
## and runs a day through it, because the bugs that live here are wiring bugs: an instance
## that is freed but left in the list, a successor that is spawned but never tracked. Both
## of those are invisible to a data-level test and both happened. It also holds the one wiring the
## events and the crowd share, which no suite of either can see: the city handing the events the
## crowd's recycle of a car a body lands on (`_test_a_car_under_a_far_body_is_recycled_by_the_city_wiring`).

const Rig := preload("res://tests/event_manager_rig.gd")

var _city: City

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	# Every test builds a city and a run of its own, so none leans on what an earlier one left
	# behind: the scars a fire writes, the streaming radius, the day a test started.
	var tests: Array[Callable] = [
		_test_day_populates_the_manager,
		_test_the_summary_names_what_the_day_planned,
		_test_finished_instances_are_dropped,
		_test_successor_replaces_its_parent,
		_test_excitement_sums_over_instances,
		_test_an_event_waits_until_she_is_near_it,
		_test_an_event_that_has_run_does_not_run_again,
		_test_a_running_event_comes_back_where_it_got_to,
		_test_a_set_piece_is_one_plan_owed_to_her_walk,
		_test_a_day_started_through_the_manager_is_planned_on_its_streets,
		_test_a_streamed_pursuer_resumes_the_chase,
		_test_a_row_warned_down_her_line_arrives_at_its_own_intensity,
		_test_the_first_dog_of_the_run_day_is_the_lesson,
		_test_a_moved_guard_keeps_what_he_is_in_the_middle_of,
		_test_a_day_started_twice_stands_the_same_rows,
		_test_two_walks_draw_the_same_day,
		_test_the_walk_is_handed_the_ground_the_dawn_made,
		_test_what_is_sited_on_her_walk_asks_the_ground_the_walk_carries,
		_test_a_drawn_body_is_told_to_whoever_listens,
		_test_a_car_under_a_far_body_is_recycled_by_the_city_wiring,
	]
	for test in tests:
		_build_city(t)
		await test.call(t)
		_teardown()

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

func _build_city(t: TestRunner) -> void:
	_city = Rig.build_city(t)

## **A guard moved is the same man, in the middle of what he was doing** (`move_extra()`): day 13's
## task guard following her to her roadblock keeps his warning and its clock, where a guard retired
## and made again would forget her. **And a guard walking off is never turned back**: one that left
## before he ever noticed her still answers `is_waiting()`, and the task setting him on her
## (`EventInstance.notice_her_at()`) leaves him leaving.
func _test_a_moved_guard_keeps_what_he_is_in_the_middle_of(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var at := _city.map.doorstep_world_position()
	var her := at + Vector2(200.0, 0.0)
	var guard := events.spawn_extra(EventCatalogue.task_guard(), at)
	guard.notice_her_at(her, Tuning.WARNING_ALONE_MAX, true)
	guard.age = guard.age + 0.4
	var noticed := guard.noticed_at()
	t.check(guard.is_telegraphing() and noticed != INF, "set on her, the guard warns her")
	events.move_extra(guard, at + Vector2(64.0, 0.0))
	t.check(is_instance_valid(guard) and not guard.is_finished
			and guard.global_position.is_equal_approx(at + Vector2(64.0, 0.0))
			and guard.is_telegraphing() and guard.noticed_at() == noticed
			and guard.is_standing_for_its_notice(),
			"moved, he is the same man, still warning her on the same clock (noticed at %.2f, %.2f)"
			% [noticed, guard.noticed_at()])
	var walking := events.spawn_extra(EventCatalogue.task_guard(), at)
	walking.leave_for_a_completed_task()
	t.check(walking.is_leaving and walking.is_waiting(),
			"a guard who left before he noticed her still answers waiting")
	walking.notice_her_at(her, Tuning.WARNING_ALONE_MAX, true)
	t.check(walking.is_leaving and not walking.is_telegraphing(),
			"and set on her, he walks on rather than warning her")
	for instance: EventInstance in [guard, walking]:
		events.retire(instance)

## **The day-3 lesson's dog is a row of its own**, `charging_dog_tutorial`, so its charging counter
## and its seen and lost-day counts tell it from the up to three that day's `max_per_day` lets the
## director send (`EventDirector._teach_the_run()` hands it out; docs/TELEMETRY.md, "The page counts
## visits", and `tests/test_visit_counter.gd` for what its counter sends). What the manager makes of
## each row is named by the row alone, on the day the run is taught as on any other.
func _test_the_first_dog_of_the_run_day_is_the_lesson(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var dog := EventCatalogue.by_id("charging_dog")
	var lesson := EventCatalogue.lesson_of(dog)
	var at := _city.map.doorstep_world_position()
	_start(Tuning.RUN_TAUGHT_DAY)
	var robber := events.spawner.create(EventCatalogue.by_id("alley_robbery"), at)
	var first := events.spawner.create(lesson, at)
	var second := events.spawner.create(dog, at)
	t.check(lesson.id == "charging_dog_tutorial" and lesson != dog
			and lesson.pursuit != null and lesson.look == dog.look,
			"the lesson's dog is a row of its own, drawn and chasing as the dog does")
	t.check(first.logged_name() == "charging_dog_tutorial" and second.logged_name() == "charging_dog",
			"and seen apart (%s, %s)" % [first.logged_name(), second.logged_name()])
	t.check(EventCatalogue.lesson_of(robber.def) == robber.def,
			"no other row has a lesson's row of its own")
	for instance: EventInstance in [robber, first, second]:
		instance.queue_free()

## The page's own lifetime, and that every look a row can carry has pictures on it, are
## `tests/test_atlas_events.gd`: with one baked page for the whole catalogue there is no
## per-family group left for a rig like this one to watch come and go, and the questions that
## replace it — the manager's reference count across days and teardown, and every picture a look
## can draw resolving on the `events` page — are about `AtlasLibrary` rather than about this
## suite's city.

## **A day started twice stands the same rows on the same tiles** (PLAYTEST-119 27;
## `docs/MECHANICS.md`, "A retry is the same day"): the dawn plans before she can move, and the
## units round where she starts draw before she can either, so day 4 started a second time, after a
## walk east on the first start, plans from nothing the first start or the walk left in the city
## or the manager. That the units the walk draws are the same whatever her path is the next test's.
func _test_a_day_started_twice_stands_the_same_rows(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var home := _city.map.doorstep_world_position()
	var rig := Rig.walker(t, _city, home)
	var started: Array[String] = []
	for start in 2:
		Rig.start(_city, 4)
		events.use_player(rig)
		var placed: Array[EventPlan] = []
		for plan in events.plans():
			if plan.is_placed():
				placed.append(plan)
		started.append(_where_they_stand(placed))
		if start == 0:
			rig.global_position = home
			var each := func(_n: int) -> void:
				rig.velocity = Vector2.RIGHT * Tuning.WALK_SPEED
				rig.global_position += rig.velocity * Rig.WALK_STEP
			await PhysicsTicks.pass_ticks(t, 60, each, Rig.WALK_SCALE)
	t.check(started[0] == started[1] and started[0] != "",
			"started twice, day 4 stands the same rows on the same tiles")
	events.use_player(null)
	rig.free()

## **Two walks draw the same day** (`UnitDraw`, `EventsAhead.draw_what_comes_near()`): day 4
## started at her door with a played day's stream radius, walked east for 60 ticks through the
## manager's own tick, then started again and walked south, draws every unit the start left undrawn
## the same, row for row and tile for tile, once the rest of the day is drawn
## (`EventManager.draw_the_ground_round()`); and each walk drew some of those units before the
## rest, in an order of its own. A row handed to her walk reads as `row@walk`, wherever her walk
## has since sited it. A walk too short for the director to site anything: one long enough for a
## crew to stand on her way is in `test_event_manager_units.gd`, with what its units draw held
## against the day drawn whole. Neither covers the moments and the rows her route's bag rigs,
## which follow her walk on purpose.
func _test_two_walks_draw_the_same_day(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var home := _city.map.doorstep_world_position()
	var rig := Rig.walker(t, _city, home)
	var readings: Array[String] = []
	var drawn_on_the_walk: Array[String] = []
	for heading: Vector2 in [Vector2.RIGHT, Vector2.DOWN]:
		Rig.start(_city, 4, [], home)
		events.use_player(rig)
		rig.global_position = home
		var kept := events.walk_events().unit_draw().units().undrawn_within(Vector2.ZERO, INF)
		var each := func(_n: int) -> void:
			rig.velocity = heading * Tuning.WALK_SPEED
			rig.global_position += rig.velocity * Rig.WALK_STEP
		await PhysicsTicks.pass_ticks(t, 60, each, Rig.WALK_SCALE)
		var drawn: Array[String] = []
		for unit in kept:
			if unit.is_drawn():
				drawn.append(unit.name())
		drawn.sort()
		drawn_on_the_walk.append(", ".join(drawn))
		events.draw_the_ground_round(Vector2.ZERO, INF)
		readings.append(Rig.what_the_units_drew(_city.map, kept))
	t.check(readings[0] == readings[1] and readings[0] != "",
			"walked east and walked south, day 4's units draw the same rows on the same tiles")
	t.check(drawn_on_the_walk[0] != "" and drawn_on_the_walk[1] != ""
			and drawn_on_the_walk[0] != drawn_on_the_walk[1],
			"and each walk drew some of them on the way, not the same ones (east %s; south %s)"
					% drawn_on_the_walk)
	events.use_player(null)
	rig.free()

## **A body a draw stands is told on, tile for tile** (`EventStreaming.use_body_listener()`): the
## listener is called once for each placed plan whose row has a solid body, with
## `EventSpawner.obstructed_footprint()` of it, and for no plan without one, and **after the body is
## recorded on the map**, so a car recycled for it is rolled with the body in the record. With no
## listener a draw says nothing and still stands its rows.
func _test_a_drawn_body_is_told_to_whoever_listens(t: TestRunner) -> void:
	var told: Array[String] = []
	# Told tiles the map does not yet hold as a body's, asked as the listener is called: the body
	# is recorded before the crowd is told, so every tile told is one the map already holds.
	var not_yet_recorded: Array[Vector2i] = []
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	RunCity.events(_city).use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append(str(tiles))
		for tile in tiles:
			if not _city.map.is_obstructed(tile):
				not_yet_recorded.append(tile))
	_start(4)
	var undrawn := RunCity.events(_city).walk_events().unit_draw().units().undrawn_within(Vector2.ZERO, INF)
	told.clear()
	not_yet_recorded.clear()
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	var expected: Array[String] = []
	var placed := 0
	for unit in undrawn:
		for plan in unit.drawn():
			if not plan.is_placed():
				continue
			placed += 1
			var tiles := EventSpawner.obstructed_footprint(_city.map, plan.def, plan.position,
					plan.facing)
			if not tiles.is_empty():
				expected.append(str(tiles))
	expected.sort()
	told.sort()
	t.check(not expected.is_empty() and expected.size() < placed,
			"day 4's draw stands rows with a body and rows without one (%d of %d placed have one)"
			% [expected.size(), placed])
	t.check(told == expected,
			"the listener is told the footprint of each placed plan that has one, and no other"
			+ " (%d told, %d expected)" % [told.size(), expected.size()])
	t.check(not_yet_recorded.is_empty(),
			"and each is told after the body is recorded: the map holds every tile told as a body's"
			+ " (%d tiles it did not yet)" % not_yet_recorded.size())
	var told_so_far := told.size()
	RunCity.events(_city).use_body_listener(Callable())
	_start(4)
	var drawn_before := RunCity.events(_city).plans().size()
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	t.check(told.size() == told_so_far and RunCity.events(_city).plans().size() > drawn_before,
			"with no listener a draw tells nobody and still stands its rows")

## **The city hands the events the crowd's recycle** (`City.build()`, `EventManager.use_body_listener()`,
## `Crowd.recycle_cars_on()`): the one line that makes a car under a body placed on her walk leave.
## This suite combines the events and the crowd because that line is the only place they meet, and
## it is the whole of the feature in the game. Day 8 drawn whole with a recording listener names a
## far roadblock's lane tile; the city is built again with its own wiring, day 8 started at the
## played stream radius so that unit is still undrawn, a car stood on that tile
## (`Crowd.add_recipe_actor()`), and the draw round the start made: the car has moved.
func _test_a_car_under_a_far_body_is_recycled_by_the_city_wiring(t: TestRunner) -> void:
	var told: Array[Vector2i] = []
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	RunCity.events(_city).use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append_array(tiles))
	_start(8)
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	var period := CityMap.period()
	var candidates: Array[Vector2i] = []
	for tile in told:
		if tile.x % period in CrowdLanes.ROAD_OFFSETS \
				and _city.map.tile_to_world(tile).length() > 2.0 * Tuning.OUT_OF_SIGHT:
			candidates.append(tile)
	t.check(not candidates.is_empty(),
			"day 8's far bodies stand on a car lane (%d tiles told)" % told.size())
	# The city again, with the wiring `City.build()` made and no listener of the test's own.
	_teardown()
	_build_city(t)
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(8)
	var crowd := RunCity.crowd(_city)
	crowd.start_day(8, Rig.rng(8), Vector2.ZERO, false)
	crowd.clear()
	crowd.set_focus(Vector2.ZERO)
	# The first of the lane tiles a car may stand on (the crowd refuses a place in a junction, at a
	# crossing and the like).
	var car: CrowdAgent = null
	for lane_tile in candidates:
		var offset := lane_tile.x % period
		var placed := crowd.add_recipe_actor("car-under-a-body", CrowdAgent.Kind.CAR,
				Vector2(CrowdLanes.lane_centre(lane_tile.x / period, offset),
						float(lane_tile.y * Tuning.TILE_SIZE + 16)),
				Vector2(0.0, CrowdLanes.road_direction(true, offset)), 130.0, 1)
		if placed["error"] == "":
			car = placed["actor"]
			break
	t.check(car != null, "a car stands on a lane tile a far body will cover")
	if car == null:
		return
	var was := car.position
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	t.check(car.position.distance_to(was) > float(Tuning.TILE_SIZE),
			"the draw that stands the body takes the car under it away (moved %.0fpx)"
			% car.position.distance_to(was))

## Each of `plans` as its row and the place it was put, in order.
static func _where_they_stand(plans: Array[EventPlan]) -> String:
	var parts: Array[String] = []
	for plan in plans:
		parts.append("%s@%s" % [plan.row_id(), plan.placed_at()])
	return ";".join(parts)

func _teardown() -> void:
	_city.free()

func _start(day: int) -> void:
	Rig.start(_city, day)

func _test_day_populates_the_manager(t: TestRunner) -> void:
	_start(1)
	t.check(RunCity.events(_city).active_count() > 0, "starting a day puts events in the world")
	for instance in RunCity.events(_city).instances():
		t.check(is_instance_valid(instance), "every tracked instance is a live node")
		t.check(instance.def != null, "every tracked instance has a def")

## Before a day there is no plan to count, so the run log's `events:` line says none; once a day is
## planned it names each row the plan holds.
func _test_the_summary_names_what_the_day_planned(t: TestRunner) -> void:
	t.check(RunCity.events(_city).event_summary() == "none", "with no day planned the summary says none")
	_start(1)
	var summary := RunCity.events(_city).event_summary()
	t.check(summary != "none" and not RunCity.events(_city).plans().is_empty()
			and summary.contains(RunCity.events(_city).plans()[0].row_id()),
			"a planned day's summary names its rows (%s)" % [summary])

## A dog walker laid on a sidewalk of the day's city at a tile, as a scene recipe lays one
## (`EventScheduler.recipe_placement()`), walking six tiles along its street, and in the world:
## the one row on a day that walks a route and runs out at its end, since the director sends every
## other dog walker ahead of her (`EventDef.is_sent_ahead()`) rather than the day planning one. It
## joins the walk as a placed row does (`EventStreaming.add()`). Null on a city with no such stretch.
func _a_dog_walker_laid_in_the_world() -> EventPlan:
	var map := _city.map
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
			RunCity.events(_city).streaming.add(plan)
			RunCity.events(_city).stream_around(start)
			return plan
	return null

func _test_finished_instances_are_dropped(t: TestRunner) -> void:
	_start(1)
	_a_dog_walker_laid_in_the_world()
	# One that leaves nothing behind and runs out on its own, stepped the way the manager steps it.
	var victim: EventInstance = null
	for instance in RunCity.events(_city).instances():
		if instance.def.aftermath.on_finish == "" and _run_to_its_end(instance):
			victim = instance
			break
	t.check(victim != null, "there is an event that leaves nothing behind and runs out")
	var before := RunCity.events(_city).active_count()
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(RunCity.events(_city).active_count() == before - 1, "a finished event is dropped")
	for instance in RunCity.events(_city).instances():
		t.check(is_instance_valid(instance),
				"no freed node is left in the list after a retirement")

## Steps `instance` a second at a time, nobody told where she is, until it has run its course;
## whether it did within an hour of them.
func _run_to_its_end(instance: EventInstance) -> bool:
	for _second in 3600:
		if instance.is_finished:
			return true
		instance.step(1.0)
	return instance.is_finished

## The bug this exists for: one event finishing and spawning one successor leaves the list
## the same LENGTH, so a size comparison concluded nothing had changed — and left a freed
## node in the array while never tracking the successor at all.
##
## `finale_explosion`/`impact_crater`, the one row `aftermath.on_finish` governs: a burst that has
## run its course leaves its crater where it went off. Spawned directly, since the escape's rows are
## not a day's.
func _test_successor_replaces_its_parent(t: TestRunner) -> void:
	_start(12)
	var burst := RunCity.events(_city).spawner.spawn(EventCatalogue.by_id("finale_explosion"),
			Vector2(500, 500))
	var before := RunCity.events(_city).active_count()
	t.check(_run_to_its_end(burst), "the burst runs out on its own")
	var where := burst.global_position
	await PhysicsTicks.pass_ticks(t, 1)

	t.check(RunCity.events(_city).active_count() == before,
			"a one-for-one replacement keeps the count the same")
	var crater: EventInstance = null
	for instance in RunCity.events(_city).instances():
		t.check(is_instance_valid(instance), "no freed node survives a successor swap")
		if instance.def.id == "impact_crater":
			crater = instance
	t.check(crater != null, "the burst leaves a crater behind it")
	if crater:
		t.close_to(crater.global_position.distance_to(where), 0.0,
				"the crater starts where the burst went off", 1.0)

func _test_excitement_sums_over_instances(t: TestRunner) -> void:
	_start(5)
	var instances := RunCity.events(_city).instances()
	t.check(instances.size() > 1, "day 5 has several events to sum")

	var at: Vector2 = instances[0].global_position
	var expected := 0.0
	for instance in instances:
		expected += instance.excitement.contribution_at(at)
	t.close_to(RunCity.events(_city).sources.total_at(at), expected,
			"the manager's total is the sum of the instances' contributions")

	var far := Vector2(-10000.0, -10000.0)
	t.close_to(RunCity.events(_city).sources.total_at(far), 0.0,
			"nothing reaches a point outside every radius")

# ---------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"don't load everything upfront."* The day is still planned across the whole
# city, so every invariant stated over a day survives; what changed is when a plan becomes a
# node. These are the two properties that make that legal.

## An event is in the world exactly when the player is near it. The distances matter: the
## streaming radius has to be wider than the widest field in the catalogue, or an event would
## appear *already inside* its own outer radius and the fairness contract would be a lie.
func _test_an_event_waits_until_she_is_near_it(t: TestRunner) -> void:
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)

	var plan: EventPlan = null
	for candidate in RunCity.events(_city).plans():
		# Not mobile: a route means the reach is measured to the nearest point of it, which is a
		# different check.
		if candidate.is_placed() and candidate.path.is_empty():
			plan = candidate
			break
	t.check(plan != null, "day 1 has a stationary event somewhere in the city")
	if not plan:
		return

	var at := plan.position
	var away := at + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0)
	RunCity.events(_city).stream_around(away)
	t.check(plan.live == null, "an event across the city is not in the world")

	RunCity.events(_city).stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS - 40.0, 0.0))
	t.check(plan.live != null, "walking into reach of it puts it there")
	var arrived := plan.live
	t.check(arrived.age <= 0.0 or arrived.is_telegraphing(),
			"and it starts its telegraph on arrival, so the warning is not spent off-screen")

	# The hysteresis: a player pacing on the boundary must not rebuild it every other frame,
	# because a rebuilt instance telegraphs again and would crouch at her forever.
	RunCity.events(_city).stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS + 40.0, 0.0))
	t.check(plan.live == arrived, "stepping just past the edge does not take it away again")
	RunCity.events(_city).stream_around(away)
	t.check(plan.live == null, "walking properly away does")

	t.check(Tuning.EVENT_STREAM_RADIUS > _widest_field(),
			"an event streams in from further out (%.0f) than its own reach (%.0f), so it is "
			% [Tuning.EVENT_STREAM_RADIUS, _widest_field()]
			+ "never already on top of her when it appears")

func _widest_field() -> float:
	var widest := 0.0
	for def in EventCatalogue.all():
		widest = maxf(widest, def.outer_radius)
	return widest

## The other half, and the one a naive implementation gets wrong: an event that has already
## happened must not happen again because she walked back past it. Streaming is allowed to take
## an event away and give it back while it is *running*; it is not allowed to rewind it.
func _test_an_event_that_has_run_does_not_run_again(t: TestRunner) -> void:
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	# Every unit drawn, as a walk that comes near each would draw it, so the day's whole plan is
	# there to choose from (a unit draws as she comes near it, and she is nowhere yet).
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	_a_dog_walker_laid_in_the_world()
	var plan: EventPlan = null
	# One that leaves nothing behind and, walked up to, runs out on its own (a dog walker's route
	# ends; a parked van never does).
	for candidate in RunCity.events(_city).plans():
		if candidate.is_placed() and candidate.def.aftermath.on_finish == "" \
				and candidate.path.size() > 1:
			RunCity.events(_city).stream_around(candidate.position)
			if candidate.live != null and _run_to_its_end(candidate.live):
				plan = candidate
				break
	if not plan:
		t.check(false, "day 1 has an event that runs out on its own")
		RunCity.events(_city).stream_radius = INF
		return

	RunCity.events(_city).stream_around(plan.position)
	t.check(plan.live != null, "she walks up to it and it is there")
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(plan.spent and plan.live == null, "it runs its course and the plan is spent")

	RunCity.events(_city).stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	RunCity.events(_city).stream_around(plan.position)
	t.check(plan.live == null, "and coming back does not start it over")
	RunCity.events(_city).stream_radius = INF

## The third case, and the one that was actually wrong. *(M31.)* An event that is still
## **running** may be taken away and given back — but it has to come back where it got to, not
## where the day put it at dawn.
##
## Reported as *"dog walkers are not moving?"*, which they were: at 32px/s a dog walker covers a
## tile a second, and every time the player left its radius and came back it was rebuilt from
## `plan.position` and teleported to the top of its street. At a third of her walking speed that
## is most times, so from outside it was an event that never went anywhere.
func _test_a_running_event_comes_back_where_it_got_to(t: TestRunner) -> void:
	RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	var plan: EventPlan = null
	for candidate in RunCity.events(_city).plans():
		if candidate.is_placed() and candidate.def.mobile and candidate.path.size() > 1 \
				and not candidate.def.still_while_telegraphing:
			plan = candidate
			break
	t.check(plan != null, "day 1 has something walking down a street")
	if not plan:
		RunCity.events(_city).stream_radius = INF
		return

	RunCity.events(_city).stream_around(plan.position)
	t.check(plan.live != null, "she comes near it and it is there")
	var started := plan.live.global_position
	for i in 120:
		plan.live.step(1.0 / 60.0)
	var walked := plan.live.global_position
	t.check(started.distance_to(walked) > 1.0,
			"it covers ground while she is watching (%.0fpx in 2s)"
			% started.distance_to(walked))
	var aged := plan.live.age

	RunCity.events(_city).stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	t.check(plan.live == null, "she walks away and it leaves the world")
	RunCity.events(_city).stream_around(walked)
	t.check(plan.live != null, "she comes back and it is there again")
	if plan.live:
		t.check(plan.live.global_position.distance_to(walked) < 1.0,
				"and it is where it had got to, not back at the top of its street (%.0fpx off)"
				% plan.live.global_position.distance_to(walked))
		# The age comes back with it, so an event cannot be made immortal by being visited
		# twice — its telegraph, its pulse and its duration all carry on rather than restart.
		t.check(absf(plan.live.age - aged) < 0.01,
				"and it is as old as it was, so revisiting cannot restart its clock")
	RunCity.events(_city).stream_radius = INF

## **A set piece is one plan, owed to her walk.** Every one-shot is sited from her walk
## (`EventDef.validate()` refuses one that is not), so the day plans it as one plan with no position
## at all, which cannot be in two places because there is only ever one of it, and which nothing in
## this rig can put anywhere: there is no player here, so no walk for it to be sited from. Over a
## whole run, each day's one-shots are each a single unsited plan, never live and never spent here.
func _test_a_set_piece_is_one_plan_owed_to_her_walk(t: TestRunner) -> void:
	var owed_to_her_walk := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		_start(day)
		var by_row := {}
		for plan in RunCity.events(_city).plans():
			if plan.def.kind != GameEnums.EventKind.ONE_SHOT:
				continue
			by_row[plan.def.id] = int(by_row.get(plan.def.id, 0)) + 1
			owed_to_her_walk += 1
			t.check(not plan.is_placed() and not plan.was_live and not plan.spent,
					"day %d: '%s' is an unsited plan waiting for a walk that never happens here"
					% [day, plan.def.id])
		for id: String in by_row:
			t.check(int(by_row[id]) == 1, "day %d: '%s' is one plan, not several (%d)"
					% [day, id, by_row[id]])
	t.check(owed_to_her_walk > 0,
			"a run has a set piece to check at all (%d owed to her walk, over fourteen days)"
			% owed_to_her_walk)

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
	state.begin_day(_city.map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("m100-seals:closures:%d" % day)
	_city.start_day(state, day, closures_rng)
	var consumed: Array[String] = []
	RunCity.events(_city).start_day(DaySpec.for_day(day), Rig.rng(day), consumed)
	var streets := _city.streets()
	t.check(streets.route_tree() != null and RunCity.events(_city).walk() == streets.route_tree(),
			"the day the manager planned walks the tree the city's dawn grew")
	var held := _city.map.held_streets()
	t.check(not streets.closures().is_empty(),
			"the dawn closed streets to hold (%d)" % streets.closures().size())
	for closure in streets.closures():
		t.check(held.has(closure.segment.key()), "the street the dawn closed (%s) is held"
				% closure.segment.key())
	t.check(not streets.region_plan().walls.is_empty(),
			"the dawn grew a region wall to hold (%d segments)" % streets.region_plan().walls.size())
	for segment in streets.region_plan().walls:
		t.check(held.has(segment.key()), "the region wall's segment %s is held" % segment.key())
	# The very bodies of the dawn's region plan are the day's, not those of a plan grown again from
	# the same tree: the siting's region and the crowd's gates read the streets' plan.
	var bodies: Array[EventPlan] = streets.region_plan().wall_bodies + streets.region_plan().door_bodies
	var plans := RunCity.events(_city).plans()
	var among := 0
	for body in bodies:
		if plans.has(body):
			among += 1
	t.check(not bodies.is_empty(), "the dawn's region plan has bodies to find (%d)" % bodies.size())
	t.check(among == bodies.size(),
			"every wall and door body of the dawn's region plan is among the day's plans (%d of %d)"
			% [among, bodies.size()])


## M100, small, real, and nobody's: the wiring half of "a pursuer streamed out mid-chase comes
## back having forgotten it." `tests/test_heat.gd` already drives `EventInstance.resume()` directly
## and pins that its `from_noticed_at` argument restores the notice; the gap that shipped anyway
## was one level up — `EventPlan` had no field to hold the notice, so
## `EventStreaming.stream_in()` always called `resume()` with the default `INF` and a
## `EventDef.notice` row streamed out mid-chase came back `is_waiting()`, standing where the day
## planted it. This drives the same encounter through
## `EventStreaming.stream_in()`/`stream_out()` themselves, the only place that bug could
## actually live — the same kind of wiring question the rest of this suite exists for (see the
## class doc above).
##
## `alley_robbery` rather than a scheduled plan: it carries `EventDef.notice` cold, with no heat
## level or a particular day's roll needed to reach it, and a `EventPlan` built by hand is
## deterministic where waiting for the scheduler to place one on some day would not be.
func _test_a_streamed_pursuer_resumes_the_chase(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var plan := EventPlan.new(def, Vector2(500.0, 500.0))

	RunCity.events(_city).streaming.stream_in(plan)
	t.check(plan.live != null, "the hand-built plan streams in like any other")
	if not plan.live:
		return

	var her := plan.position + Vector2(def.notice_within() - 10.0, 0.0)
	RunCity.events(_city).world.where_she_is().tell(her)
	plan.live.step(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "she is inside the trigger, so it notices her")
	for i in 60:
		RunCity.events(_city).world.where_she_is().tell(her)
		plan.live.step(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "and a second later it is still chasing, not patrolling")
	var chase_age_before := plan.live.chase_age()

	RunCity.events(_city).streaming.stream_out(plan)
	t.check(plan.live == null, "streaming out through the manager clears the live instance")
	t.check(plan.noticed_at != INF,
			"and the plan itself remembers when it noticed her, not just the freed instance")

	RunCity.events(_city).streaming.stream_in(plan)
	t.check(plan.live != null, "streaming back in rebuilds it")
	if plan.live:
		t.check(not plan.live.is_waiting(),
				"streamed back in through EventManager it is still chasing, not waiting")
		t.close_to(plan.live.chase_age(), chase_age_before,
				"and the chase clock continued from the notice rather than restarting at it", 0.05)

## **A row warned of down her line is created with its telegraph spent, at its own intensity from
## its first frame.** *(2026-09-20: "unleashed dog still has too little influence -- needs to be more
## intense".)* `EventInstance.is_lethal_at()` refuses the whole telegraph and `_notice_damping()`
## holds the field at `EventInstance.TELEGRAPH_INTENSITY_FRACTION` through it, so a row that arrived still
## telegraphing would ride past her unable to do the one thing it is for — the kill for a `hard_fail`
## row, the noise for a loud one. The warning was the telegraph, so the thing it warned of is created
## past it.
##
## Asked of the game's own path on a real city, every `TOWARD_PLAYER` row on foot: for one that
## telegraphs, the director's warning, which the manager's own ticks put up when she walks up the
## arterial's sidewalk with the row owed her, and the instance it creates once its warning is over;
## for one that does not (`loose_dog`), the instance created at once with no warning. On its first
## frame it is not telegraphing, its field is undamped, and a lethal row is lethal at its own centre.
func _test_a_row_warned_down_her_line_arrives_at_its_own_intensity(t: TestRunner) -> void:
	var map := _city.map
	var checked: Array[String] = []
	var events := RunCity.events(_city)
	var rig: Stroller = null
	for def in EventCatalogue.all():
		if not def.comes_down_her_line():
			continue
		checked.append(def.id)
		# Nothing planned and nothing sited ahead of her, then the one row owed her from a route bag
		# holding nothing else, as a scene's recipe hands it (`EventManager.start_recipe_route()`),
		# due as soon as she is walking.
		var nothing: Array[EventPlan] = []
		events.start_recipe(nothing, DaySpec.for_day(Tuning.RUN_TAUGHT_DAY + 2),
				Tuning.RUN_TAUGHT_DAY + 2, Vector2.ZERO)
		var owed := events.start_recipe_route([def.id], [def.id], 1, 0.0)
		t.check(owed == 1, "the director owes her '%s' (%d)" % [def.id, owed])
		var her := CrowdLanes.arterial_pavement(map)
		for _tile in map.size.y / 2:
			if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
				break
			her.y += Tuning.TILE_SIZE
		if rig == null:
			rig = Rig.walker(t, _city, her)
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
				if instance.def.id == def.id and not before.has(instance):
					seen["arrived"] = instance
					seen["arrived_at"] = seen["tick"]
					seen["warnings_at_arrival"] = events.pending_warnings().size()
			if seen["arrived"] == null and seen["warned_at"] < 0:
				rig.velocity = Vector2.UP * Tuning.WALK_SPEED
				rig.global_position += rig.velocity * Rig.WALK_STEP
			else:
				rig.velocity = Vector2.ZERO
		var ticks := 0
		var limit := PhysicsTicks.ticks_for(def.telegraph_time + 10.0, Rig.WALK_SCALE)
		while seen["arrived"] == null and ticks < limit:
			await PhysicsTicks.pass_ticks(t, 1, each, Rig.WALK_SCALE)
			ticks += 1
		if not def.telegraphs:
			t.check(seen["warned_at"] < 0 and seen["arrived"] != null
					and seen["warnings_at_arrival"] == warnings_before,
					"'%s' does not telegraph: no warning goes up for it, it is created at once" % def.id)
		else:
			t.check(seen["warned_at"] >= 0 and seen["warned_at"] < seen["arrived_at"],
					"'%s' is warned of down her line on a tick before it exists (warned on %d, made on %d)"
					% [def.id, seen["warned_at"], seen["arrived_at"]])
		var arrived: EventInstance = seen["arrived"]
		t.check(arrived != null, "'%s' is sent down her line and created" % def.id)
		if not arrived:
			continue
		t.check(not arrived.is_telegraphing() and is_equal_approx(arrived.current_intensity(1.0), def.intensity),
				("'%s' is created with its telegraph spent, emitting at its own intensity rather "
				% def.id) + "than the telegraph's %.0f%%" % (EventInstance.TELEGRAPH_INTENSITY_FRACTION * 100.0))
		if def.hard_fail:
			t.check(arrived.is_lethal_at(arrived.global_position),
					"and '%s', declared hard_fail, is lethal from its first frame" % def.id)
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
	t.check(RunCity.events(_city).walk_events().ground() != null,
			"a day started through the manager carries the ground the dawn made for its walk")

## **What is sited on her walk asks the ground the walk carries** (`EventsAhead.start_day()` hands
## `WalkEvents.ground()` to the siting it makes for a plan left for her walk): a ground that counts
## its asks is handed to the walk, the director's day is started over it again, and the siting's
## one-time scans (`WalkSiting.prepare()`) ask it. A siting handed a ground of its own would leave
## the count at zero.
func _test_what_is_sited_on_her_walk_asks_the_ground_the_walk_carries(t: TestRunner) -> void:
	var asked := -1
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		_start(day)
		var left_for_her_walk := false
		for plan in RunCity.events(_city).plans():
			if plan.def.on_her_way != null and not plan.is_placed():
				left_for_her_walk = true
		if not left_for_her_walk:
			continue
		var walk := RunCity.events(_city).walk_events()
		var counting := _CountingGround.new(_city.map, null, true, RowGround.Weights.new(),
				func(_row: EventDef) -> bool: return false)
		walk.take(walk.plans(), walk.calm(), walk.doors(), walk.reach(), walk.locations(), counting)
		RunCity.events(_city).ahead.start_day(day, RunCity.events(_city).walk())
		asked = counting.asks
		break
	t.check(asked >= 0, "a day leaves a plan for her walk to site")
	t.check(asked > 0, "and the siting made for it asks the ground the walk carries (%d asks)" % asked)
