@warning_ignore_start("untyped_declaration")
extends RefCounted
## EventManager against a real generated City.
##
## Everything else in the event tests runs on plain data. This one builds an actual city
## and runs a day through it, because the bugs that live here are wiring bugs: an instance
## that is freed but left in the list, a successor that is spawned but never tracked. Both
## of those are invisible to a data-level test and both happened.

const Rig := preload("res://tests/event_manager_rig.gd")

var _city: City

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	# Every test builds a city and a run of its own, so none leans on what an earlier one left
	# behind: the scars a fire writes, the streaming radius, the day a test started.
	var tests: Array[Callable] = [
		_test_day_populates_the_manager,
		_test_finished_instances_are_dropped,
		_test_successor_replaces_its_parent,
		_test_excitement_sums_over_instances,
		_test_an_event_waits_until_she_is_near_it,
		_test_an_event_that_has_run_does_not_run_again,
		_test_a_running_event_comes_back_where_it_got_to,
		_test_a_set_piece_is_one_plan_owed_to_her_walk,
		_test_a_day_started_through_the_manager_alone_still_carries_seals,
		_test_a_streamed_pursuer_resumes_the_chase,
		_test_a_row_warned_down_her_line_arrives_at_its_own_intensity,
		_test_the_first_dog_of_the_run_day_is_the_lesson,
		_test_a_moved_guard_keeps_what_he_is_in_the_middle_of,
		_test_a_day_started_twice_stands_the_same_rows,
	]
	for test in tests:
		_build_city(t)
		await test.call(t)
		_teardown()

func _build_city(t: TestRunner) -> void:
	_city = Rig.build_city(t)

## **A guard moved is the same man, in the middle of what he was doing** (`move_extra()`): day 13's
## task guard following her to her roadblock keeps his warning and its clock, where a guard retired
## and made again would forget her. **And a guard walking off is never turned back**: one that left
## before he ever noticed her still answers `is_waiting()`, and the task setting him on her
## (`EventInstance.notice_her_at()`) leaves him leaving.
func _test_a_moved_guard_keeps_what_he_is_in_the_middle_of(t: TestRunner) -> void:
	var events := _city.events
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
	var events := _city.events
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
## `docs/MECHANICS.md`, "A retry is the same day"): the dawn draws every location before she can
## move (`LocationDraw.draw_all()`), so day 4 started a second time, after a walk east on the first
## start, plans from nothing the first start or the walk left in the city or the manager.
func _test_a_day_started_twice_stands_the_same_rows(t: TestRunner) -> void:
	var events := _city.events
	events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var home := _city.map.doorstep_world_position()
	var rig := Rig.walker(t, _city, home)
	var started: Array[String] = []
	for start in 2:
		Rig.start(_city, 4)
		events.use_player(rig)
		var placed: Array[EventScheduler.Planned] = []
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

## Each of `plans` as its row and the place it was put, in order.
static func _where_they_stand(plans: Array[EventScheduler.Planned]) -> String:
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
	t.check(_city.events.active_count() > 0, "starting a day puts events in the world")
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "every tracked instance is a live node")
		t.check(instance.def != null, "every tracked instance has a def")

func _test_finished_instances_are_dropped(t: TestRunner) -> void:
	_start(1)
	# One that leaves nothing behind and runs out on its own, stepped the way the manager steps it.
	var victim: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.aftermath.on_finish == "" and _run_to_its_end(instance):
			victim = instance
			break
	t.check(victim != null, "there is an event that leaves nothing behind and runs out")
	var before := _city.events.active_count()
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(_city.events.active_count() == before - 1, "a finished event is dropped")
	for instance in _city.events.instances():
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
	var burst := _city.events.spawner.spawn(EventCatalogue.by_id("finale_explosion"),
			Vector2(500, 500))
	var before := _city.events.active_count()
	t.check(_run_to_its_end(burst), "the burst runs out on its own")
	var where := burst.global_position
	await PhysicsTicks.pass_ticks(t, 1)

	t.check(_city.events.active_count() == before,
			"a one-for-one replacement keeps the count the same")
	var crater: EventInstance = null
	for instance in _city.events.instances():
		t.check(is_instance_valid(instance), "no freed node survives a successor swap")
		if instance.def.id == "impact_crater":
			crater = instance
	t.check(crater != null, "the burst leaves a crater behind it")
	if crater:
		t.close_to(crater.global_position.distance_to(where), 0.0,
				"the crater starts where the burst went off", 1.0)

func _test_excitement_sums_over_instances(t: TestRunner) -> void:
	_start(5)
	var instances := _city.events.instances()
	t.check(instances.size() > 1, "day 5 has several events to sum")

	var at: Vector2 = instances[0].global_position
	var expected := 0.0
	for instance in instances:
		expected += instance.excitement.contribution_at(at)
	t.close_to(_city.events.sources.total_at(at), expected,
			"the manager's total is the sum of the instances' contributions")

	var far := Vector2(-10000.0, -10000.0)
	t.close_to(_city.events.sources.total_at(far), 0.0,
			"nothing reaches a point outside every radius")

# ---------------------------------------------------- the world near you (M27) ---
# Playtest 04: *"don't load everything upfront."* The day is still planned across the whole
# city, so every invariant stated over a day survives; what changed is when a plan becomes a
# node. These are the two properties that make that legal.

## An event is in the world exactly when the player is near it. The distances matter: the
## streaming radius has to be wider than the widest field in the catalogue, or an event would
## appear *already inside* its own outer radius and the fairness contract would be a lie.
func _test_an_event_waits_until_she_is_near_it(t: TestRunner) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)

	var plan: EventScheduler.Planned = null
	for candidate in _city.events.plans():
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
	_city.events.stream_around(away)
	t.check(plan.live == null, "an event across the city is not in the world")

	_city.events.stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS - 40.0, 0.0))
	t.check(plan.live != null, "walking into reach of it puts it there")
	var arrived := plan.live
	t.check(arrived.age <= 0.0 or arrived.is_telegraphing(),
			"and it starts its telegraph on arrival, so the warning is not spent off-screen")

	# The hysteresis: a player pacing on the boundary must not rebuild it every other frame,
	# because a rebuilt instance telegraphs again and would crouch at her forever.
	_city.events.stream_around(at + Vector2(Tuning.EVENT_STREAM_RADIUS + 40.0, 0.0))
	t.check(plan.live == arrived, "stepping just past the edge does not take it away again")
	_city.events.stream_around(away)
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
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	var plan: EventScheduler.Planned = null
	# One that leaves nothing behind and, walked up to, runs out on its own (a dog walker's street
	# ends; a parked van never does).
	for candidate in _city.events.plans():
		if candidate.is_placed() and candidate.def.aftermath.on_finish == "" \
				and candidate.path.size() > 1:
			_city.events.stream_around(candidate.position)
			if candidate.live != null and _run_to_its_end(candidate.live):
				plan = candidate
				break
	if not plan:
		t.check(false, "day 1 has an event that runs out on its own")
		_city.events.stream_radius = INF
		return

	_city.events.stream_around(plan.position)
	t.check(plan.live != null, "she walks up to it and it is there")
	await PhysicsTicks.pass_ticks(t, 1)
	t.check(plan.spent and plan.live == null, "it runs its course and the plan is spent")

	_city.events.stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	_city.events.stream_around(plan.position)
	t.check(plan.live == null, "and coming back does not start it over")
	_city.events.stream_radius = INF

## The third case, and the one that was actually wrong. *(M31.)* An event that is still
## **running** may be taken away and given back — but it has to come back where it got to, not
## where the day put it at dawn.
##
## Reported as *"dog walkers are not moving?"*, which they were: at 32px/s a dog walker covers a
## tile a second, and every time the player left its radius and came back it was rebuilt from
## `plan.position` and teleported to the top of its street. At a third of her walking speed that
## is most times, so from outside it was an event that never went anywhere.
func _test_a_running_event_comes_back_where_it_got_to(t: TestRunner) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(1)
	var plan: EventScheduler.Planned = null
	for candidate in _city.events.plans():
		if candidate.is_placed() and candidate.def.mobile and candidate.path.size() > 1 \
				and not candidate.def.still_while_telegraphing:
			plan = candidate
			break
	t.check(plan != null, "day 1 has something walking down a street")
	if not plan:
		_city.events.stream_radius = INF
		return

	_city.events.stream_around(plan.position)
	t.check(plan.live != null, "she comes near it and it is there")
	var started := plan.live.global_position
	for i in 120:
		plan.live.step(1.0 / 60.0)
	var walked := plan.live.global_position
	t.check(started.distance_to(walked) > 1.0,
			"it covers ground while she is watching (%.0fpx in 2s)"
			% started.distance_to(walked))
	var aged := plan.live.age

	_city.events.stream_around(plan.position + Vector2(Tuning.EVENT_STREAM_RADIUS * 4.0, 0.0))
	t.check(plan.live == null, "she walks away and it leaves the world")
	_city.events.stream_around(walked)
	t.check(plan.live != null, "she comes back and it is there again")
	if plan.live:
		t.check(plan.live.global_position.distance_to(walked) < 1.0,
				"and it is where it had got to, not back at the top of its street (%.0fpx off)"
				% plan.live.global_position.distance_to(walked))
		# The age comes back with it, so an event cannot be made immortal by being visited
		# twice — its telegraph, its pulse and its duration all carry on rather than restart.
		t.check(absf(plan.live.age - aged) < 0.01,
				"and it is as old as it was, so revisiting cannot restart its clock")
	_city.events.stream_radius = INF

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
		for plan in _city.events.plans():
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

## M100: "a rig driving `EventManager` before `City.start_day` seals nothing." Every rig in this
## suite, this one included, drives `EventManager.start_day` before `_city.start_day()` has grown a
## tree, so `_city.streets().route_tree()` and `region_plan()` answer null; `DayPlanner._plan_a_day()`
## then grows its own tree and plan from the same `RouteTree.for_day(map, day)` the city grows at
## dawn, so `SealPlanner.plan_day` and `RegionPlanner.plan_day` are handed a real tree and the
## catalogue's placements are stated against the same one: one tree for the day, and its seals and
## walls planned.
##
## Comparing "the manager alone" against "the manager after the city's own `start_day`" is the
## check, rather than counting seals directly: `RouteTree.for_day(map, day)` is deterministic and
## `SealPlanner`'s own RNG stream (`RunState.calendar.day_rng(day, "seals")`) does not depend on `_city`
## either, so every segment the fallback holds has to be held the real way too — a rig that skips
## `City.start_day` must not come out with less of it. **Not exact equality**: `_city.streets().closures()`
## only ever has something to read once `City.start_day()` has run (see the comment in
## `EventManager.start_day` above `_map.clear_day_holds()`), so the "after" run legitimately holds
## a little more, one closure's own segment. See `tests/test_checkpoints.gd`'s
## `_test_the_manager_actually_places_the_door_structure()` for the same `City.start_day` calling
## convention, written against this exact gap before it had a fix.
func _test_a_day_started_through_the_manager_alone_still_carries_seals(t: TestRunner) -> void:
	var day := Tuning.REGION_WALL_FIRST_DAY  # so a region wall or door is in play, not only seals.
	_start(day)
	var alone := _city.map.held_streets().keys()
	t.check(alone.size() > 0,
			"a day started through the manager alone still holds some ground (%d segments)"
			% alone.size())

	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	var closures_rng := RandomNumberGenerator.new()
	closures_rng.seed = hash("m100-seals:closures:%d" % day)
	_city.start_day(state, day, closures_rng)
	_start(day)
	var after_city := _city.map.held_streets()

	for key in alone:
		t.check(after_city.has(key),
				"everything the manager's own fallback tree holds, City.start_day holds too")


## M100, small, real, and nobody's: the wiring half of "a pursuer streamed out mid-chase comes
## back having forgotten it." `tests/test_heat.gd` already drives `EventInstance.resume()` directly
## and pins that its `from_noticed_at` argument restores the notice; the gap that shipped anyway
## was one level up — `EventScheduler.Planned` had no field to hold the notice, so
## `EventStreaming.stream_in()` always called `resume()` with the default `INF` and a
## `EventDef.notice` row streamed out mid-chase came back `is_waiting()`, standing where the day
## planted it. This drives the same encounter through
## `EventStreaming.stream_in()`/`stream_out()` themselves, the only place that bug could
## actually live — the same kind of wiring question the rest of this suite exists for (see the
## class doc above).
##
## `alley_robbery` rather than a scheduled plan: it carries `EventDef.notice` cold, with no heat
## level or a particular day's roll needed to reach it, and a `Planned` built by hand is
## deterministic where waiting for the scheduler to place one on some day would not be.
func _test_a_streamed_pursuer_resumes_the_chase(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var plan := EventScheduler.Planned.new(def, Vector2(500.0, 500.0))

	_city.events.streaming.stream_in(plan)
	t.check(plan.live != null, "the hand-built plan streams in like any other")
	if not plan.live:
		return

	var her := plan.position + Vector2(def.notice_within() - 10.0, 0.0)
	_city.events.world.where_she_is().tell(her)
	plan.live.step(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "she is inside the trigger, so it notices her")
	for i in 60:
		_city.events.world.where_she_is().tell(her)
		plan.live.step(1.0 / 60.0)
	t.check(not plan.live.is_waiting(), "and a second later it is still chasing, not patrolling")
	var chase_age_before := plan.live.chase_age()

	_city.events.streaming.stream_out(plan)
	t.check(plan.live == null, "streaming out through the manager clears the live instance")
	t.check(plan.noticed_at != INF,
			"and the plan itself remembers when it noticed her, not just the freed instance")

	_city.events.streaming.stream_in(plan)
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
	var events := _city.events
	var rig: Stroller = null
	for def in EventCatalogue.all():
		if not def.comes_down_her_line():
			continue
		checked.append(def.id)
		# Nothing planned and nothing sited ahead of her, then the one row owed her from a route bag
		# holding nothing else, as a scene's recipe hands it (`EventManager.start_recipe_route()`),
		# due as soon as she is walking.
		var nothing: Array[EventScheduler.Planned] = []
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
	for id in ["cyclist", "loose_dog"]:
		t.check(checked.has(id), "'%s' is among the rows sent down her line (%s)"
				% [id, ", ".join(checked)])
