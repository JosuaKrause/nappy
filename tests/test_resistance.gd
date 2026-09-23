extends RefCounted
## The resistance subquest: the step table, touch-completion, a task activated the same day its
## mark is touched, the four placement kinds a perform step may use, the seeded guard, the
## expiring step, and the sabotage silencing the city.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

## Maps for a sweep that asks about a *rule* rather than a *layout* — the same distinction and the
## same name `tests/test_routes.gd` and `tests/test_regions.gd` use: "no scheduled placement ever
## lands near the doorstep" is enforced by construction the same way on every city, so a second
## city tests the same guarantee against different noise rather than a different shape of it.
const RULE_SEEDS := 3

func run(t) -> void:
	_test_step_table(t)
	_test_step_selection(t)
	_test_days_ten_and_eleven_offer_no_mark(t)
	_test_the_finale_needs_the_legwork(t)
	_test_touching_completes_a_pickup(t)
	_test_walking_away_leaves_it_untouched(t)
	_test_a_perform_contact_rides_on_its_instance(t)
	_test_a_perform_contact_sees_its_rider_finish(t)
	_test_touching_the_mark_activates_the_same_days_task(t)
	_test_placement_is_deterministic(t)
	_test_the_guard_is_seeded(t)
	_test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t)
	_test_a_mark_within_notice_radius_does_not_move(t)
	_test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t)
	_test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t)
	_test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t)
	_test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t)
	_test_the_guard_moves_with_the_mark_and_faces_away_from_her(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	_test_a_perform_contact_is_never_relocated(t)
	_test_the_contact_rides_onto_the_first_look_alike_she_reaches(t)
	_test_a_perform_step_expires_when_its_rider_is_gone(t)
	_test_a_timed_step_expires(t)
	_test_completing_the_package_makes_the_pram_heavier(t)
	_test_starting_a_day_resets_the_package_flag(t)
	_test_completing_the_yeller_step_sends_only_its_rider_away(t)
	_test_a_pacing_yeller_leaves_away_from_her_on_either_half_of_its_beat(t)
	_test_a_completed_tasks_rider_does_not_vanish_while_she_is_watching(t)
	_test_an_ordinary_departure_still_gives_up_at_six_seconds(t)
	_test_a_lost_day_still_offers_the_mark_and_then_the_yeller_on_retry(t)
	_test_the_sabotage_silences_the_city(t)
	_test_the_burnt_shell_task_rides_the_recorded_scar(t)
	_test_the_burnt_shell_task_falls_back_with_no_recorded_scar(t)
	_test_the_door_task_sits_at_a_region_door(t)
	_test_the_door_task_never_borders_the_home_block(t)
	_test_the_swing_task_sits_at_an_open_playground(t)
	_test_the_red_arrow_only_ever_points_at_a_one_place_task(t)
	if _city != null:
		_city.free()

# ---------------------------------------------------------------- step table ---

func _test_step_table(t) -> void:
	var steps := ResistanceSteps.all()
	# Not `size() == 15`: `ResistanceSteps._build()` is a literal array, so a count of it is that
	# array restated and adding a task would mean editing both in lockstep. The guard here is only
	# that there is something to check, which is what stops the sweep below passing vacuously.
	t.check(not steps.is_empty(), "there is a step table to check")

	var previous_index := 0
	var previous_day := 0
	var available_performs := 0
	for step in steps:
		t.check(step.index == previous_index + 1, "step indices run consecutively from 1")
		t.check(step.day >= previous_day, "steps unlock in calendar order")
		if step.available:
			t.check(step.placement.size() > 0 or step.district >= 0
					or step.target_kind in [ResistanceSteps.TargetKind.DOOR,
							ResistanceSteps.TargetKind.PARK_SWING],
					"step %d knows where it goes" % step.index)
		if step.is_pickup:
			t.check(not step.grants_progress, "a pickup does not grant progress")
			t.check(step.task_event_id == "", "a pickup sits on a tile, not a rider")
			# A task is one day: the entry right after a pickup is the perform it unlocks, on
			# the same day, which is what lets `ResistanceDirector._on_contact_completed()`
			# activate it by `step.index + 1` alone.
			var perform := ResistanceSteps.by_index(step.index + 1)
			t.check(perform != null and not perform.is_pickup and perform.day == step.day,
					"step %d's mark unlocks a perform step on the same day" % step.index)
		elif not step.needs_goal and step.available:
			t.check(step.task_event_id != "" or step.target_kind in [
					ResistanceSteps.TargetKind.DOOR, ResistanceSteps.TargetKind.PARK_SWING],
					"perform step %d names what it rides on or how it finds its own place"
					% step.index)
			available_performs += 1

		previous_index = step.index
		previous_day = step.day

	t.check(available_performs > Tuning.RESISTANCE_GOAL,
			"there are more built perform steps than the goal needs, so one task can be missed")
	t.check(steps[steps.size() - 1].needs_goal, "the finale is the last step")
	t.check(steps[steps.size() - 1].day == Tuning.RUN_LENGTH_DAYS, "and it is on the last day")

func _test_step_selection(t) -> void:
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(1, none, none, false) == null,
			"nothing is on offer before the resistance exists")

	var first := ResistanceSteps.for_day(6, none, none, false)
	t.check(first != null and first.index == 1 and first.is_pickup,
			"day 6 offers the first chalk mark")

	# The perform half is never offered at dawn — only `_on_contact_completed()` activates it,
	# the same day the mark that unlocks it is touched — so `for_day()` says nothing about it
	# even once the mark is done.
	var done: Array[int] = [1]
	t.check(ResistanceSteps.for_day(6, done, none, false) == null,
			"day 6's mark done leaves nothing further for for_day() to offer that day")

	var second := ResistanceSteps.for_day(7, done, none, false)
	t.check(second != null and second.index == 3 and second.is_pickup,
			"day 7 offers its own mark")

	# A day's own mark, once failed, is gone for the rest of the run the same way a completed
	# one is — `for_day()` treats the two alike, since either way the day has nothing further
	# to offer.
	var failed: Array[int] = [3]
	t.check(ResistanceSteps.for_day(7, done, failed, false) == null,
			"a failed mark is never offered again")
	var later := ResistanceSteps.for_day(8, done, failed, false)
	t.check(later != null and later.index == 5, "but the run carries on to the next task's mark")

func _test_days_ten_and_eleven_offer_no_mark(t) -> void:
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(10, none, none, false) == null,
			"day 10 (warn the neighbor) waits on a later slice and offers no mark")
	t.check(ResistanceSteps.for_day(11, none, none, false) == null,
			"day 11 (silence a mast) waits on a later slice and offers no mark either")
	# But the day after either one still finds its own task — an unavailable day never blocks
	# the calendar behind it.
	var next := ResistanceSteps.for_day(12, none, none, false)
	t.check(next != null and next.index == 11, "day 12 offers the swing's own mark regardless")

func _test_the_finale_needs_the_legwork(t) -> void:
	var done: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14]
	var none: Array[int] = []
	t.check(ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, false) == null,
			"the finale is not offered to a player who has not earned it")
	var finale := ResistanceSteps.for_day(Tuning.RUN_LENGTH_DAYS, done, none, true)
	t.check(finale != null and finale.needs_goal, "and is offered to one who has")

# --------------------------------------------------------------------- touch ---

var _player: Stroller
var _contact: ContactPoint

func _build_pickup(t, step_index: int) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)
	_player.global_position = Vector2.ZERO

	_contact = ContactPoint.new()
	_contact.setup(ResistanceSteps.by_index(step_index), Vector2.ZERO)
	t.add_child(_contact)
	_contact.set_physics_process(false)

func _teardown_contact() -> void:
	_contact.free()
	_player.free()

func _test_touching_completes_a_pickup(t) -> void:
	_build_pickup(t, 1)
	var completed: Array[int] = []
	_contact.completed.connect(func(index: int) -> void: completed.append(index))

	t.check(not _contact.is_done, "not done before she arrives")
	_contact._physics_process(STEP)
	t.check(_contact.is_done, "touching it completes it, instantly — there is no hold")
	t.check(completed == [1], "and reports which step it was, once")
	_teardown_contact()

func _test_walking_away_leaves_it_untouched(t) -> void:
	_build_pickup(t, 1)
	_player.global_position = Vector2(500.0, 0.0)
	_contact._physics_process(STEP)
	t.check(not _contact.is_done, "out of reach, nothing happens")
	_teardown_contact()

## The shared plumbing every task needs: a contact that rides on an `EventInstance` rather
## than sitting on a bare tile, and follows it if it moves.
func _test_a_perform_contact_rides_on_its_instance(t) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	_player.add_child(camera)
	t.add_child(_player)
	_player.set_physics_process(false)

	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2(300.0, 0.0))
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(2), instance, Vector2.ZERO)
	t.add_child(contact)
	contact.set_physics_process(false)

	_player.global_position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(not contact.is_done, "out of reach of where the rider is now")

	# The rider moves; the contact follows it rather than staying where it started.
	instance.position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(contact.is_done, "and completes once she reaches wherever the rider has gone")

	contact.free()
	instance.free()
	_player.free()

func _test_a_perform_contact_sees_its_rider_finish(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("roadblock"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(ResistanceSteps.by_index(14), instance, Vector2(90.0, 0.0))
	t.add_child(contact)
	contact.set_physics_process(false)

	t.check(contact.rider_alive(), "the rider starts alive")
	instance._finish()
	t.check(not contact.rider_alive(), "and rider_alive() sees it end")

	contact.free()
	instance.free()

# ------------------------------------------------------------------ director ---

var _city: City

## Freed rather than left standing: `City.build()` adds an `EventManager` child that acquires the
## "events" `AtlasLibrary` group in its own `_enter_tree()` and only gives it back in
## `_exit_tree()` (`src/events/event_manager.gd`). This suite calls `_build_city()` many times
## over, so a `_city` never freed between two calls would leave every earlier one standing —
## sixteen abandoned `City` nodes in a suite that only ever needs the latest, each holding "events"
## resident for the rest of the process. `run()` frees whichever one is still around after the
## last call.
func _build_city(t) -> void:
	if _city != null:
		_city.free()
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [SEED, day, stream])
	return rng

func _with_clean_run(action: Callable) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_failed := GameState.failed_resistance_steps.duplicate()
	var saved_progress := GameState.resistance_progress
	var saved_package := GameState.resistance_carrying_package
	GameState.completed_resistance_steps = []
	GameState.failed_resistance_steps = []
	GameState.resistance_progress = 0
	GameState.resistance_carrying_package = false
	action.call()
	GameState.completed_resistance_steps = saved_completed
	GameState.failed_resistance_steps = saved_failed
	GameState.resistance_progress = saved_progress
	GameState.resistance_carrying_package = saved_package

func _completed_through(last_index: int) -> Array[int]:
	var done: Array[int] = []
	done.assign(range(1, last_index + 1))
	return done

## Day 6's mark, started and touched — the shape most of this suite's perform-step tests now
## need, since `start_day()` alone only ever offers a mark (`ResistanceSteps.for_day()`). Returns
## the director with step 2 (the yeller perform) already active.
func _director_on_the_yeller_perform(t) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance"), 300.0)
	director._on_contact_completed(1)
	return director

## The whole design rests on the run being learnable: the alley that was safe on day 9 has
## to be safe on day 9 every time you replay that run — and the same is true of a perform
## step's own placement.
func _test_placement_is_deterministic(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var first := _director(t)
		first.start_day(6, _rng(6, "resistance"), 300.0)
		var where := first.contact_position()
		t.check(where != Vector2.INF, "day 6 puts a mark somewhere")
		t.check(_city.map.tile_type_at_world(where) == GameEnums.TileType.ALLEY,
				"and the chalk mark is in an alley")

		var second := _director(t)
		second.start_day(6, _rng(6, "resistance"), 300.0)
		t.close_to(second.contact_position().distance_to(where), 0.0,
				"and it is in the same alley every time", 0.01)

		first.free()
		second.free())

## A task is one day: touching the mark activates the perform it unlocks in the same
## `start_day()`'s own RNG and guard state, without waiting for a `start_day()` that would not
## come until tomorrow.
func _test_touching_the_mark_activates_the_same_days_task(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(director.current_step() != null and director.current_step().index == 1,
				"day 6 starts on the mark")
		director._on_contact_completed(1)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"touching it activates the yeller perform the same day")
		t.check(director.contact_position() != Vector2.INF,
				"and it rides on a live instance rather than a bare tile")
		director.free())

## *Always guarded* has to mean a survivable band, not a guaranteed lost day: a robber sits
## somewhere between 66px (30 + `ContactPoint.REACH`) and 176px (140 + `ContactPoint.REACH`)
## of every mark, seeded so the distance is the same every time this day is replayed.
func _test_the_guard_is_seeded(t) -> void:
	_seen_guard_distances = []
	_with_clean_run(func() -> void:
		var before := _director(t)
		before.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(before.current_step() == null, "nothing is offered before day 6")
		before.free()

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH
		var search := max_distance + 40.0

		for day in [6, 7, 8, 9]:
			GameState.completed_resistance_steps = _completed_through(2 * (day - 6))
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var at := director.contact_position()
			var guard := _find_robbery_near(at, search)
			t.check(guard != null, "day %d's mark is guarded" % day)
			var distance := guard.global_position.distance_to(at) if guard else -1.0
			if guard:
				t.check(distance >= min_distance - 0.5 and distance <= max_distance + 0.5,
						"day %d's guard sits in the 66-176px band" % day)
				_seen_guard_distances.append(distance)
			director.free()

			var replay := _director(t)
			replay.start_day(day, _rng(day, "resistance"), 300.0)
			var replay_guard := _find_robbery_near(replay.contact_position(), search)
			if guard and replay_guard:
				t.close_to(replay_guard.global_position.distance_to(replay.contact_position()),
						distance, "day %d's guard distance replays the same way" % day, 0.5)
			replay.free())

	var all_equal := true
	for distance in _seen_guard_distances:
		if not is_equal_approx(distance, _seen_guard_distances[0]):
			all_equal = false
	t.check(_seen_guard_distances.size() >= 2 and not all_equal,
			"the guard distance is not the same every day")

var _seen_guard_distances: Array[float] = []

func _find_robbery_near(at: Vector2, within: float) -> EventInstance:
	if at == Vector2.INF:
		return null
	for instance in _city.events.instances():
		if instance.def.id != "alley_robbery":
			continue
		if instance.global_position.distance_to(at) <= within:
			return instance
	return null

# ------------------------------------------------------------- re-placement ---
# Playtest 19 finding 6, in the player's own words: "if it was placed but never on screen it
# should count as not placed and be placed on the next alley the player comes close to."

## Same shape `_build_pickup` uses for a bare `ContactPoint` — a real `Stroller`, physics off,
## dropped straight into `player` group by its own `_ready()` so `ResistanceDirector` finds it
## the same way it would in the running game.
func _rig_player(t, at: Vector2) -> Stroller:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)
	player.global_position = at
	return player

## The world position of an `ALLEY` tile more than `min_distance` from `at`, or `Vector2.INF`
## if the test city has none. Used to put her far enough from the mark that the re-placement
## rule has to fire.
func _alley_farther_than(min_distance: float, at: Vector2) -> Vector2:
	for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
		var world := _city.map.tile_to_world(tile)
		if world.distance_to(at) > min_distance:
			return world
	return Vector2.INF

func _test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		t.check(mark_at != Vector2.INF, "day 6 places the mark")

		# She stands exactly on a distant alley — the nearest reachable one to her is itself,
		# at distance 0, which is what makes the assertion below exact rather than approximate.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)

		Telemetry.begin_memory_log()
		director._process(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"an unseen mark moves to the alley she has just come near")

		var moved := false
		for line in Telemetry.current_log().lines:
			if line.contains("contact") and line.contains("moved to") \
					and line.contains("never seen"):
				moved = true
		t.check(moved, "and a contact telemetry line records the move")
		Telemetry.end_run()

		player.free()
		director.free())

## Built from `_two_nearby_alleys()` (a real pair, not wherever day 6's own roll happened to put
## the mark) so "there really is a nearer alley on offer" holds by construction rather than by
## the luck of which tile the day's RNG chose: the mark is forced onto `other`, and she stands
## exactly on `nearer_tile`, which is nearer to her than the mark is by definition, and still
## within `NOTICE_RADIUS` of it (`_two_nearby_alleys()`'s own doc).
func _test_a_mark_within_notice_radius_does_not_move(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var pair := _two_nearby_alleys()
		if pair.is_empty():
			t.check(true, "skipped: the test city has no two alleys close enough to test this")
			return
		var player_at: Vector2 = pair[0]
		var other_tile: Vector2i = pair[2]

		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		director._contact.global_position = _city.map.tile_to_world(other_tile)
		var mark_at := director.contact_position()
		var player := _rig_player(t, player_at)

		director._process(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"within NOTICE_RADIUS of her own mark, nothing moves — not even to a nearer alley")

		player.free()
		director.free())

## M177, playtest 116's own day-6 shape: a mark on offer at (24,149), on screen from the doorstep
## at (80,84) — fifteen tiles away — moved to (65,83) two seconds in and was marked *seen* 0.4s
## later, so a fifteen-tile-distant alley froze it for the rest of the day. Forcing `_sight` to
## always answer true reproduces "on screen" without a viewport; standing at `far_alley` (beyond
## `NOTICE_RADIUS`, so certainly beyond the far narrower `SEEN_DISTANCE`) reproduces the distance.
## A single frame is enough to show the old bug is gone: the old rule pinned the mark on this exact
## frame, and the new one still relocates it.
func _test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		director.set_sight(func(_p: Vector2) -> bool: return true)

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"on screen but far outlasts nothing: it still relocates to the alley she has come near")

		player.free()
		director.free())

## The other half of the same rule: near enough, for long enough, that walking away is a choice.
func _test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		director.set_sight(func(_p: Vector2) -> bool: return true)

		# Within SEEN_DISTANCE the whole time, never merely "on screen".
		var near_at := mark_at + Vector2(ResistanceDirector.SEEN_DISTANCE - 20.0, 0.0)
		var player := _rig_player(t, near_at)

		# One frame short of the dwell window: not seen yet.
		director._process(ResistanceDirector.SEEN_DWELL_SECONDS - STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"within SEEN_DISTANCE the whole time, so it has not moved regardless of being seen yet")

		# The dwell completes on this frame.
		director._process(STEP)

		# Walk her far away — seen does not chase, but it also does not relocate any more.
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		player.global_position = far_alley
		director._process(STEP)
		t.check(director.contact_position().distance_to(mark_at) < 0.5,
				"seen after the dwell window completes, so it stays put however far she walks after")

		player.free()
		director.free())

# ----------------------------------------------------------- alley avoidance ---
# M177: "a mark does not return to an alley a step was already taken from while another is
# within reach." Day 6 of playtest 116's own run put step 3's mark back on the exact alley step 1
# had been completed at on day 4 — the same rule, exercised here over the new day numbering.

## The dawn placement (`_place()` -> `_pick_reachable()`) skips an alley `GameState.
## completed_resistance_alley_tiles` already names, as long as some other alley is reachable —
## which a full generated city always has plenty of for a pickup's placement.
func _test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.completed_resistance_alley_tiles.clear()

		var first := _director(t)
		first.start_day(6, _rng(6, "resistance"), 300.0)
		var used_tile := _city.map.world_to_tile(first.contact_position())
		first.free()

		GameState.completed_resistance_alley_tiles.append(used_tile)
		GameState.completed_resistance_steps = _completed_through(2)
		var second := _director(t)
		second.start_day(7, _rng(7, "resistance"), 300.0)
		t.check(second.current_step() != null and second.current_step().index == 3,
				"day 7 offers the second mark")
		var second_tile := _city.map.world_to_tile(second.contact_position())
		t.check(second_tile != used_tile,
				"a fresh mark avoids the alley a completed step used, another being in reach")
		second.free()

		GameState.completed_resistance_alley_tiles = saved_tiles)

## The two ALLEY tiles closest together in the built test city — `[player_at, nearer, other]`,
## `player_at` sitting exactly on `nearer` so it is always the globally nearest one to itself, and
## `other` confirmed within `ResistanceDirector.NOTICE_RADIUS` of it. Empty if the city has no pair
## that close, which the relocation test below skips on rather than asserting through.
func _two_nearby_alleys() -> Array:
	var alleys := _city.map.tiles_of_type(GameEnums.TileType.ALLEY)
	for tile in alleys:
		var at := _city.map.tile_to_world(tile)
		for other in alleys:
			if other == tile:
				continue
			if at.distance_to(_city.map.tile_to_world(other)) <= ResistanceDirector.NOTICE_RADIUS:
				return [at, tile, other]
	return []

## The relocation rule (`_nearest_alley_within()`) applies the same avoidance, with the same
## fallback: marking the nearest alley to a chosen spot as "used" sends an unseen, far-relocating
## mark to some other alley still in reach instead, rather than to `Vector2.INF`.
func _test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var pair := _two_nearby_alleys()
		if pair.is_empty():
			t.check(true, "skipped: the test city has no two alleys close enough to test this")
			return
		var player_at: Vector2 = pair[0]
		var nearer_tile: Vector2i = pair[1]

		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.completed_resistance_alley_tiles.clear()
		GameState.completed_resistance_alley_tiles.append(nearer_tile)

		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		# Force the mark far from the chosen pair, regardless of where day 6's own roll put it —
		# this test is about the avoidance, not about replaying a particular placement.
		director._contact.global_position = \
				player_at + Vector2(ResistanceDirector.NOTICE_RADIUS + 200.0, 0.0)

		var player := _rig_player(t, player_at)
		director._process(STEP)
		var new_tile := _city.map.world_to_tile(director.contact_position())
		t.check(new_tile != nearer_tile,
				"a relocated mark avoids the alley a completed step used, another being in reach")

		player.free()
		director.free()
		GameState.completed_resistance_alley_tiles = saved_tiles)

func _test_the_guard_moves_with_the_mark_and_faces_away_from_her(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH
		var guards: Array[EventInstance] = []
		for instance in _city.events.instances():
			if instance.def.id == "alley_robbery" and not instance.is_finished:
				guards.append(instance)
		t.check(guards.size() == 1, "exactly one live guard exists once the mark has moved (%d)"
				% guards.size())

		var guard: EventInstance = guards[0]
		var distance := guard.global_position.distance_to(new_at)
		t.check(distance >= min_distance - 0.5 and distance <= max_distance + 0.5,
				"the new guard sits in the same 66-176px band as any other")

		var facing_away := (new_at - player.global_position).normalized()
		var to_guard := (guard.global_position - new_at).normalized()
		t.check(facing_away.dot(to_guard) >= -0.01,
				"and his bearing from the mark is on the half facing away from her")

		player.free()
		director.free())

## `docs/DECISIONS.md`, M100, "The guard robber is placed inside a building, where he is stuck for ever":
## `ResistanceDirector._draw_guard_position` redraws a bearing until the point is walkable, never
## on a held segment or the home block, rejecting rather than repairing — checked directly, over
## many seeds and many marks, rather than through a live guard instance: the geometry is the same
## draw whichever mark it is asked from, and this reaches far more of it than the seeded-run tests
## above sample. No `_city` is needed for the draw itself, so the director here is never added to
## the scene tree and is freed by hand.
func _test_the_guard_never_lands_inside_a_building(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	var unguarded := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-sweep:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			for _attempt in 3:
				checked += 1
				var guard_at := director._draw_guard_position(rng, mark, Vector2.INF,
						min_distance, max_distance)
				if guard_at == Vector2.INF:
					unguarded += 1
					continue
				var guard_tile := map.world_to_tile(guard_at)
				t.check(map.is_walkable(guard_tile),
						"seed %d: the guard for the mark at %s stands on walkable ground"
						% [seed_value, tile])
				t.check(not map.is_held_at(guard_tile) and not map.is_on_home_block(guard_tile),
						"seed %d: the guard for the mark at %s is not on held or home-block ground"
						% [seed_value, tile])
				var inside_a_building := false
				for rect in map.building_rects:
					if rect.has_point(guard_tile):
						inside_a_building = true
						break
				t.check(not inside_a_building,
						"seed %d: the guard for the mark at %s never stands inside a footprint"
						% [seed_value, tile])
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws, %d found no ground)"
			% [checked, unguarded])

## The stated fallback, exercised directly: a mark with nowhere walkable in its whole band draws
## `TRAP_DRAW_LIMIT` times and gives up rather than settling for a building — "no trap is better
## than a trap in a wall". Built from a real map's own tile grid, with every tile in the band
## forced to `BUILDING` first, so the draw genuinely has nowhere to land rather than merely being
## unlucky.
func _test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t) -> void:
	var map := CityGenerator.generate(13)
	var director := ResistanceDirector.new()
	director.setup(null, map)
	var mark_tile := Vector2i(20, 20)
	var mark := map.tile_to_world(mark_tile)
	# 8 tiles (256px) comfortably clears the 176px band's own far edge on every side.
	for dy in range(-8, 9):
		for dx in range(-8, 9):
			map.set_tile(mark_tile + Vector2i(dx, dy), GameEnums.TileType.BUILDING)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var guard_at := director._draw_guard_position(rng, mark, Vector2.INF, 60.0, 176.0)
	t.check(guard_at == Vector2.INF,
			"a band with no walkable ground anywhere in it draws no guard at all")
	director.free()

## Item 4: the spawn kill named at the top of M100's queue has no fix of its own — items 1
## through 3 are supposed to make it impossible by construction, and this is what proves it.
## Nothing named `alley_robbery` — the catalogue's own placement, from `first_day` 8, or the
## resistance's guard trap, from `TRAP_FIRST_DAY` (6) — ever stands within lethal reach of the
## doorstep, over `RULE_SEEDS` seeds and every day either kind can appear.
##
## `reach` is computed from the row's own `inner_radius` (30px, the always-lethal zone around
## whichever one of them it is) and the trap's own `min_distance` (66px, how close a guard is
## ever placed to its mark) rather than a literal — the two named constants this bug was always
## about, added together as a generous rather than exact bound.
##
## **M125: six seeds cut to `RULE_SEEDS` (3).** Measured, this loop alone was 55.5s of the suite's
## ~65s: `EventScheduler.build_day()` schedules the whole city to answer a question about one row,
## once per (seed, day). The exclusion this checks is enforced at placement time the same way on
## every city — "impossible by construction" is a property of the construction, not of any one
## city's shape — so it is a rule sweep, not a layout sweep, and keeps the full day range (4..14,
## every day either kind can appear) while halving the seeds.
func _test_no_alley_robbery_stands_near_the_doorstep(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var reach: float = robbery.inner_radius + min_distance
	var checked := 0
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		var map := CityGenerator.generate(seed_value)
		var doorstep := map.doorstep_world_position()
		var consumed: Array[String] = []
		for day in range(4, 15):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var events_rng := RandomNumberGenerator.new()
			events_rng.seed = hash("%d:events:%d" % [seed_value, day])
			for plan in EventScheduler.build_day(day, events_rng, map, consumed, [], [], tree):
				if plan.def.id != "alley_robbery" or not plan.is_placed():
					continue
				checked += 1
				t.check(plan.position.distance_to(doorstep) > reach,
						("seed %d day %d: no scheduled alley_robbery stands within lethal reach " +
						"of the doorstep") % [seed_value, day])

			var director := ResistanceDirector.new()
			director.setup(null, map)
			var mark_rng := RandomNumberGenerator.new()
			mark_rng.seed = hash("%d:mark:%d" % [seed_value, day])
			var mark_at := director._place(ResistanceSteps.by_index(1), mark_rng)
			if mark_at != Vector2.INF:
				checked += 1
				t.check(mark_at.distance_to(doorstep) > reach,
						"seed %d day %d: the chalk mark is not within lethal reach of the doorstep"
						% [seed_value, day])
				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d" % [seed_value, day])
				var guard_at := director._draw_guard_position(guard_rng, mark_at, Vector2.INF,
						min_distance, max_distance)
				if guard_at != Vector2.INF:
					checked += 1
					t.check(guard_at.distance_to(doorstep) > reach,
							"seed %d day %d: the guard trap is not within lethal reach of the doorstep"
							% [seed_value, day])
			director.free()
	t.check(checked > 0, "some (seed, day) actually placed something to check (%d)" % checked)

## The reported run, replayed at the same seed and day — no longer byte-for-byte, since the
## calendar this test's own day sits in has moved (`Tuning.REGION_WALL_FIRST_DAY` 7 → 9, and the
## mark on offer at day 7 with nothing touched yet is now the second one, index 3, the van's own
## mark, rather than the first). What is still checked is the general shape the bug was: seed
## 291862120, day 7, the M78 "never-seen mark follows her" rule (`_track_sight_and_reposition`)
## relocating a mark she starts the day standing near, and the guard redrawn for the new mark
## landing nowhere lethal. Built through the real pipeline — `City.start_day`, then
## `EventManager.start_day`, then `ResistanceDirector.start_day` — rather than the data-level
## sweep above, so the M78 relocation actually runs the way it does in a played day.
func _test_playtest_55_seed_has_no_spawn_kill(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 291862120
		var day := 7
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = INF

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)

		var doorstep := city.map.doorstep_world_position()
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("%d:events:%d" % [seed_value, day])
		var consumed: Array[String] = []
		city.events.start_day(day, events_rng, consumed, doorstep)

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)
		var resistance_rng := RandomNumberGenerator.new()
		resistance_rng.seed = hash("%d:resistance:%d" % [seed_value, day])
		# No steps completed yet, which is what actually offers day 7's own chalk mark (index 3)
		# — a player who has not yet been near it, exactly the reported run's own shape.
		director.start_day(day, resistance_rng, 300.0)
		t.check(director.current_step() != null and director.current_step().index == 3,
				"seed %d day %d: day 7's chalk mark is still on offer, as in the reported run"
				% [seed_value, day])

		var player := _rig_player(t, doorstep)
		director._process(STEP)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var reach: float = robbery.inner_radius + min_distance

		var mark_at := director.contact_position()
		if mark_at != Vector2.INF:
			t.check(mark_at.distance_to(doorstep) > reach,
					("seed %d day %d: the (possibly relocated) chalk mark is not within lethal " +
					"reach of the doorstep") % [seed_value, day])

		var robbers_checked := 0
		for instance in city.events.instances():
			if instance.def.id != "alley_robbery":
				continue
			robbers_checked += 1
			t.check(instance.global_position.distance_to(doorstep) > reach,
					("seed %d day %d: no alley_robbery instance (guard or scheduled) stands " +
					"within lethal reach of the doorstep") % [seed_value, day])
		t.check(robbers_checked > 0,
				"seed %d day %d: the reported run's guard exists to check (%d found)"
				% [seed_value, day, robbers_checked])

		player.free()
		director.free()
		city.free())

## PLAYTEST-57, "a chalk mark behind a barrier": `144s-attempt1-asked-1.png` shows the
## resistance's mark on an alley's paving behind a roadblock band across its mouth. Reproduced at
## `Tuning.REGION_WALL_FIRST_DAY` — the first day a wall can stand at all — rather than the
## reported run's own day 7, which predates the wall now that the doors arrive three task days
## later (day 9 rather than day 7). `RegionPlanner.plan_day` walls several crossing alleys on this
## day, off today's tree, and **every one of their tiles passed all three checks
## `_pick_reachable()` had before this fix** — `is_closed()` (about a `RoadClosure`, which this is
## not), `is_held_at()` (about a `StreetNetwork` segment, which an alley is never on) and
## `is_on_home_block()`. None of the three ever looks at a region wall, which is the whole of the
## escape. `CityMap.is_in_walled_alley()` is the fourth check that closes it.
func _test_a_walled_alley_escapes_no_other_check(t) -> void:
	var seed_value := 2199579682
	var day := Tuning.REGION_WALL_FIRST_DAY
	var map := CityGenerator.generate(seed_value)
	var tree := RouteTree.for_day(map, day)
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	t.check(not region_plan.alley_walls.is_empty(),
			"seed %d day %d walls at least one crossing alley, or this test checks nothing"
			% [seed_value, day])

	var checked := 0
	for rect in region_plan.alley_walls:
		for tile in map.rect_tiles(rect):
			checked += 1
			t.check(not map.is_closed(tile) and not map.is_held_at(tile) \
					and not map.is_on_home_block(tile),
					("seed %d day %d: %s is inside a walled alley, and none of is_closed(), " +
					"is_held_at() or is_on_home_block() catches it — that gap is the reported bug")
					% [seed_value, day, tile])
			t.check(map.is_in_walled_alley(tile, region_plan.alley_walls),
					"seed %d day %d: %s is refused by the check that closes the gap"
					% [seed_value, day, tile])
	t.check(checked > 0, "some walled-alley tile was actually checked (%d)" % checked)

## The same reported seed, through the real pipeline `_test_playtest_55_seed_has_no_spawn_kill`
## uses — `City.start_day`, then `ResistanceDirector.start_day` — swept over many RNG draws per
## step rather than trusting the one draw the reported run happened to make, at
## `Tuning.REGION_WALL_FIRST_DAY` for the same reason `_test_a_walled_alley_escapes_no_other_check`
## moved off day 7: neither the mark nor its guard, from `TRAP_FIRST_DAY`, may ever land inside a
## walled-off crossing alley, on any draw.
func _test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t) -> void:
	_with_clean_run(func() -> void:
		var seed_value := 2199579682
		var day := Tuning.REGION_WALL_FIRST_DAY
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))

		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)
		var walled_alleys := city.region_plan().alley_walls
		t.check(not walled_alleys.is_empty(),
				"seed %d day %d walls at least one crossing alley, or this test checks nothing"
				% [seed_value, day])

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH
		var max_distance: float = robbery.pursues_within + ContactPoint.REACH

		var attempts := 0
		for step in ResistanceSteps.all():
			if step.district >= 0 or not step.available or not step.is_pickup:
				continue   # the finale sits in a district, and only a mark ever sits in an alley
			for trial in 20:
				attempts += 1
				var mark_rng := RandomNumberGenerator.new()
				mark_rng.seed = hash("%d:mark:%d:%d:%d" % [seed_value, day, step.index, trial])
				var at := director._place(step, mark_rng)
				if at == Vector2.INF:
					continue
				var tile := city.map.world_to_tile(at)
				t.check(not city.map.is_in_walled_alley(tile, walled_alleys),
						"seed %d day %d step %d trial %d: the mark is not inside a walled alley"
						% [seed_value, day, step.index, trial])

				var guard_rng := RandomNumberGenerator.new()
				guard_rng.seed = hash("%d:guard:%d:%d:%d" % [seed_value, day, step.index, trial])
				var guard_at := director._draw_guard_position(guard_rng, at, Vector2.INF,
						min_distance, max_distance, walled_alleys)
				if guard_at == Vector2.INF:
					continue
				var guard_tile := city.map.world_to_tile(guard_at)
				t.check(not city.map.is_in_walled_alley(guard_tile, walled_alleys),
						"seed %d day %d step %d trial %d: the guard is not inside a walled alley either"
						% [seed_value, day, step.index, trial])
		t.check(attempts > 0, "some (step, trial) actually placed something to check (%d)" % attempts)

		director.free()
		city.free())

func _test_a_perform_contact_is_never_relocated(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		t.check(director.current_step() != null and not director.current_step().is_pickup,
				"the yeller perform is active, riding on it rather than sitting on a mark")
		var at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		t.check(director.contact_position().distance_to(at) < 0.5,
				"a perform contact is never subject to the mark's own re-placement rule")

		player.free()
		director.free())

## Overturn, 2026-09-13 (`docs/NARRATIVE.md`, "The contact is whichever look-alike she reaches
## first"): a second live `homeless_yeller` — a look-alike the day's own scheduler could equally
## have placed, spawned directly here rather than through it — stands well clear of the seeded
## rider. She is put within reach of the *decoy* rather than the rider `_begin_step()` rolled, and
## the contact rides onto it instead of waiting for her to find the one it was seeded on.
func _test_the_contact_rides_onto_the_first_look_alike_she_reaches(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		var perform := director.current_step()
		t.check(perform != null and perform.index == 2, "the yeller perform is active")
		var seeded_at := director.contact_position()
		var seeded_rider: EventInstance = director._rider

		var decoy_at := director._place(perform, _rng(6, "decoy"))
		t.check(decoy_at.distance_to(seeded_at) > ContactPoint.REACH * 4.0,
				"the decoy lands well clear of the seeded rider, or this test checks nothing")
		var decoy := _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"), decoy_at)

		var player := _rig_player(t, decoy_at)
		director._process(STEP)
		t.check(director.contact_position().distance_to(decoy_at) < 0.5,
				"the contact rides onto the look-alike she actually reached, not the seeded one")
		t.check(director._rider == decoy and director._rider != seeded_rider,
				"and the director's own rider is now the decoy")

		var completed: Array[int] = []
		director._contact.completed.connect(func(index: int) -> void: completed.append(index))
		director._contact._physics_process(STEP)
		t.check(completed == [2], "touching the retargeted contact completes step 2 itself")

		player.free()
		director.free())

func _test_a_perform_step_expires_when_its_rider_is_gone(t) -> void:
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"the yeller perform is active")
		var rider: EventInstance = director._rider
		t.check(rider != null, "the perform step rides on a live instance")

		rider._finish()
		director._process(0.1)
		t.check(director.current_step() == null, "and it is gone once the rider is")
		t.check(2 in GameState.failed_resistance_steps, "recorded as failed for the run")
		director.free())

## No task built this slice carries a deadline — the two that do, warning the neighbor and
## silencing a mast, wait on a later slice (`ResistanceSteps._build()`'s own comment says why) —
## so this drives `_process()`'s own deadline-expiry code directly, on a step built for the test
## alone, to prove the mechanism a later slice's tasks will use still works.
func _test_a_timed_step_expires(t) -> void:
	_with_clean_run(func() -> void:
		var timed := ResistanceSteps.Step.new()
		timed.index = 9001
		timed.day = 6
		timed.title = "A timed step, for this test alone"
		timed.deadline_fraction = 0.5

		var director := _director(t)
		director._step = timed
		director._day = 6
		director._day_length = 100.0
		director._elapsed = 0.0
		director._contact = ContactPoint.new()
		director._contact.setup(timed, Vector2.ZERO)
		t.add_child(director._contact)
		director._contact.set_physics_process(false)

		director._process(100.0 * timed.deadline_fraction * 0.5)
		t.check(director.current_step() != null, "on offer before the deadline")
		t.check(9001 not in GameState.failed_resistance_steps, "nothing has failed yet")

		director._process(100.0 * timed.deadline_fraction)
		t.check(director.current_step() == null, "past the deadline it is gone")
		t.check(9001 in GameState.failed_resistance_steps, "and recorded as failed for the run")
		director.free())

## Step 4's cost is deferred and total rather than local: picking the package up does not cost the
## street it happened on, it makes every street after it dearer for the rest of the day.
func _test_completing_the_package_makes_the_pram_heavier(t) -> void:
	_with_clean_run(func() -> void:
		var somewhere := _city.map.tile_to_world(Vector2i(10, 10))
		var before := _city.decay_multiplier(somewhere)

		var director := _director(t)
		director._on_contact_completed(4)
		t.check(GameState.resistance_carrying_package, "picking up the package sets the flag")

		var after := _city.decay_multiplier(somewhere)
		t.close_to(after, before * Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER,
				"and every street after it decays slower for the rest of the day", 0.001)
		director.free())

func _test_starting_a_day_resets_the_package_flag(t) -> void:
	_with_clean_run(func() -> void:
		GameState.resistance_carrying_package = true
		var director := _director(t)
		director.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(not GameState.resistance_carrying_package,
				"a fresh attempt at a day has not picked it up yet")
		director.free())

# --------------------------------------------------------- a finished task, shown by the world ---
# A finished task is shown by the world and never by text: the man shouting she actually reached
# stops shouting and walks off screen, the same departure `EventInstance._be_done()` gives any
# finished event. `EventInstance.leave_for_a_completed_task()` is the wrapper the director calls.

## The look-alike she never reached is a second live `homeless_yeller`, spawned directly rather
## than waiting for the scheduler to place one, so the test does not depend on the seed placing a
## second one that day.
func _test_completing_the_yeller_step_sends_only_its_rider_away(t) -> void:
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"the yeller perform is active")
		var rider: EventInstance = director._rider
		t.check(rider != null and not rider.is_leaving, "the seeded rider is shouting, not leaving")

		var decoy := _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"),
				rider.global_position + Vector2(600.0, 0.0))

		director._on_contact_completed(2)

		t.check(rider.is_leaving, "the one she reached stops shouting and leaves")
		t.close_to(rider.contribution_at(rider.global_position), 0.0,
				"and contributes nothing to the meter the same frame", 0.001)
		t.check(not decoy.is_leaving, "a look-alike she never reached is left exactly alone")
		t.check(decoy.contribution_at(decoy.global_position) > 0.0,
				"still shouting, still emitting")

		director.free())

## `EventDef.paces` folds a beat back and forth over its path, so "the way it was going" mid-beat
## means something different on each half — walking out toward the far end, or already turned
## round and walking back. `_be_done()`'s own rule ("something on a route carries on the way it
## was going") would carry him at her on whichever half has him walking toward where she is
## standing; `leave_for_a_completed_task()` turns him to leave away from her regardless.
func _test_a_pacing_yeller_leaves_away_from_her_on_either_half_of_its_beat(t) -> void:
	for on_the_second_half in [false, true]:
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO,
				PackedVector2Array([Vector2.ZERO, Vector2(200.0, 0.0)]))
		t.add_child(instance)
		instance.set_process(false)

		# 50px is the beat's first half (walking east); 350px is past the 200px turn, the second
		# half (walking west) — `_advance_along_path(0.0)` reads `_path_travelled` back into a
		# heading and a position without covering any further ground.
		instance._path_travelled = 350.0 if on_the_second_half else 50.0
		instance._advance_along_path(0.0)
		var walking := instance._heading
		t.check((walking.x < 0.0) == on_the_second_half,
				"set up walking %s" % ("west, the second half" if on_the_second_half
						else "east, the first half"))
		# Sited ahead of him on his own heading — where "the way it was going" would walk him
		# straight at her if nothing turned him round.
		instance.set_player_at(instance.position + walking * 40.0)

		instance.leave_for_a_completed_task()

		t.check(instance.is_leaving, "he leaves (%s half)"
				% ("second" if on_the_second_half else "first"))
		t.check(instance._heading.dot(walking) < -0.99,
				"and turns to walk away from her rather than along the beat (%s half)"
						% ("second" if on_the_second_half else "first"))
		instance.free()

## Contribution stops the instant he leaves, and he walks rather than vanishing. He does **not**
## pop out of existence mid-screen at `EventInstance.LEAVING_GIVES_UP` (6.0s) while she is still
## standing right there watching — that backstop is for a departure nobody could be watching (a
## headless rig, a streamed-out day), not for one that starts with her in reach. He only finishes
## once he has actually walked far enough away.
func _test_a_completed_tasks_rider_does_not_vanish_while_she_is_watching(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO,
			PackedVector2Array([Vector2.ZERO, Vector2(200.0, 0.0)]))
	t.add_child(instance)
	instance.set_process(false)
	# She stands still for the whole test — the case that used to pop him out of existence
	# mid-screen at the backstop.
	instance.set_player_at(Vector2(20.0, 0.0))
	t.check(instance.current_intensity() > 0.0, "shouting, before the task is done")

	instance.leave_for_a_completed_task()
	t.check(instance.is_leaving, "he stops the instant she hands him the note")
	t.close_to(instance.contribution_at(instance.global_position), 0.0,
			"and contributes nothing the same frame", 0.001)

	var before := instance.global_position
	var before_distance := before.distance_to(instance.player_at)
	instance._leave(EventInstance.LEAVING_GIVES_UP)
	t.check(not instance.is_finished,
			"still leaving past the backstop's own six seconds, since she is still watching")
	t.close_to(instance.contribution_at(instance.global_position), 0.0,
			"and still contributes nothing")
	t.check(instance.global_position.distance_to(instance.player_at) > before_distance,
			"farther away than when he started, not stalled")

	# She still has not moved. At `departs_at` (60px/s) from 20px away, he clears
	# `Tuning.OUT_OF_SIGHT` (420px) in well under ten more seconds.
	instance._leave(10.0)
	t.check(instance.is_finished, "gone once he is actually out of sight, not before")
	instance.free()

## `_leaving_must_clear_sight` is set only by `leave_for_a_completed_task()`. An ordinary
## departure — `_be_done()` reached on its own, with nothing routing it through the resistance —
## still gives up at the plain six-second backstop, watched or not: this changes nothing about it.
func _test_an_ordinary_departure_still_gives_up_at_six_seconds(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	instance.set_player_at(Vector2(20.0, 0.0))

	instance._be_done()
	t.check(instance.is_leaving, "an ordinary departure starts leaving the same way")

	instance._leave(EventInstance.LEAVING_GIVES_UP - 0.1)
	t.check(not instance.is_finished, "not gone yet, just under six seconds in")
	instance._leave(0.2)
	t.check(instance.is_finished, "gone at the six-second backstop, watched or not")
	instance.free()

## "A task is only complete if it is done on the day that won" — `GameState.finish_day()` gives
## a lost day's resistance work back, and the retry starts at the mark again, not straight at the
## task: a task is one day, so there is no dawn shortcut into the middle of it the way the old
## two-beat design had.
func _test_a_lost_day_still_offers_the_mark_and_then_the_yeller_on_retry(t) -> void:
	var saved_seed := GameState.run_seed
	var saved_day := GameState.day
	var saved_nerves := GameState.nerves
	_with_clean_run(func() -> void:
		GameState.run_seed = SEED
		GameState.day = 6
		GameState.nerves = Tuning.STARTING_NERVES
		GameState.begin_day()

		var attempt := _director(t)
		attempt.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(attempt.current_step() != null and attempt.current_step().index == 1,
				"the first attempt starts at the mark")
		attempt._on_contact_completed(1)
		t.check(attempt.current_step() != null and attempt.current_step().index == 2,
				"touching it activates the yeller perform the same day")
		var rider: EventInstance = attempt._rider
		attempt._on_contact_completed(2)
		t.check(rider != null and rider.is_leaving, "completing it sends the rider away")
		attempt.free()

		t.check(GameState.finish_day(GameEnums.DayResult.LOST_CRYING),
				"losing the day continues the run")
		t.check(1 not in GameState.completed_resistance_steps
				and 2 not in GameState.completed_resistance_steps,
				"and gives both halves of the day's task back")
		t.check(GameState.day == 6, "and the retry is the same day")

		var retry := _director(t)
		retry.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(retry.current_step() != null and retry.current_step().index == 1,
				"the retry starts at the mark again, not straight at the task")
		retry._on_contact_completed(1)
		t.check(retry._rider != null and retry._rider != rider,
				"and once touched again it rides a fresh rider, not the one that already walked off")
		t.check(not retry._rider.is_leaving, "and it is shouting, not leaving")
		retry.free())

	GameState.run_seed = saved_seed
	GameState.day = saved_day
	GameState.nerves = saved_nerves

## The whole subquest pays out in quiet. On the last walk home every mast stops, and the field
## each one has been holding near itself since day 5 goes with it — `EventManager.
## silence_all_masts()`, not the deleted `city_wide` floor: a mast has an edge like any other
## row's, so what the sabotage silences is everywhere a mast actually stands, not the whole map.
func _test_the_sabotage_silences_the_city(t) -> void:
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(8)
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		GameState.sabotage_done = false
		t.check(GameState.sabotage_available(), "the finale is on offer")

		# A live mast, the way day 5 onwards leaves one — planned for real, at one of
		# `MastSites.compute()`'s own sites, rather than a `spawn_extra` stand-in: silencing reads
		# `Planned.mast_id`, which only a real plan carries.
		var site := MastSites.compute(_city.map)[0]
		_city.events.stream_radius = INF
		_city.events.start_day(Tuning.RUN_LENGTH_DAYS,
				_rng(Tuning.RUN_LENGTH_DAYS, "events"), [], site.foot)
		var mast_plan: EventScheduler.Planned = null
		for plan in _city.events.plans():
			if plan.mast_id == site.id and plan.def.id == "loudspeaker":
				mast_plan = plan
		t.check(mast_plan != null and mast_plan.live != null,
				"the mast at her focus is live from the day it was started")
		var mast := mast_plan.live
		for i in int(round((mast.def.telegraph_time + 0.2) / STEP)):
			mast._process(STEP)
		var nearby := site.foot + Vector2(50.0, 0.0)
		t.check(mast.contribution_at(nearby) > 0.0,
				"the mast reaches its own nearby sidewalk while it is on")

		var quiet: Array[bool] = []
		var handler := func() -> void: quiet.append(true)
		EventBus.city_went_quiet.connect(handler)

		var director := _director(t)
		director.start_day(Tuning.RUN_LENGTH_DAYS,
				_rng(Tuning.RUN_LENGTH_DAYS, "resistance"), 300.0)
		t.check(director.current_step() != null, "the last night has a contact")
		director._on_contact_completed(15)

		t.check(GameState.sabotage_done, "completing it does the sabotage")
		t.check(quiet.size() == 1, "and the city goes quiet, once")
		t.check(mast.silenced, "the mast is marked silenced")
		t.close_to(mast.contribution_at(nearby), 0.0,
				"the mast contributes nothing afterwards")

		EventBus.city_went_quiet.disconnect(handler)
		director.free())

# ------------------------------------------------------------ placement kinds ---
# Day 8's burnt shell (`TargetKind.SCAR`), day 9's crossing (`TargetKind.DOOR`) and day 12's
# swing (`TargetKind.PARK_SWING`) each find their own place rather than riding a freshly spawned
# `EventInstance` the way an ordinary perform step does.

func _test_the_burnt_shell_task_rides_the_recorded_scar(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_scars := GameState.scars.duplicate()
		var sidewalks := _city.map.tiles_of_type(GameEnums.TileType.SIDEWALK)
		var scar_at := _city.map.tile_to_world(sidewalks[sidewalks.size() / 2])
		GameState.scars = [{"id": "burnt_shell", "position": scar_at, "since_day": 3}]
		# `_find_scar_instance()` reads live instances off `_city.events`, which only exist once
		# the day's own events have actually been built — `_place_scars()` is what turns the
		# recorded scar into a live `burnt_shell` instance at `scar_at`.
		_city.events.start_day(8, _rng(8, "events"), [], _city.map.doorstep_world_position())

		var director := _director(t)
		director.start_day(8, _rng(8, "resistance"), 300.0)
		director._on_contact_completed(5)
		t.check(director.current_step() != null and director.current_step().index == 6,
				"touching day 8's mark activates the burnt-shell perform")
		t.check(director._rider != null and director._rider.def.id == "burnt_shell",
				"riding a burnt_shell instance")
		# Under a tile's own width, not exactly 0 — `_find_scar_instance()`'s own doc says why:
		# the scheduler's own placement of the solid shape can nudge it a few pixels off the
		# coordinate the scar was recorded at.
		t.check(director._rider.global_position.distance_to(scar_at) < Tuning.TILE_SIZE,
				"the one standing at the run's own recorded scar")

		director.free()
		GameState.scars = saved_scars)

## The smallest honest fallback named in `ResistanceSteps._build()`'s own comment: a run with no
## recorded `burnt_shell` scar still offers day 8's task, on an ordinary placement of the same
## row rather than a step with nowhere to go.
func _test_the_burnt_shell_task_falls_back_with_no_recorded_scar(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_scars := GameState.scars.duplicate()
		GameState.scars.clear()

		var director := _director(t)
		director.start_day(8, _rng(8, "resistance"), 300.0)
		director._on_contact_completed(5)
		t.check(director.current_step() != null and director.current_step().index == 6,
				"touching day 8's mark still activates the burnt-shell perform")
		t.check(director._rider != null and director._rider.def.id == "burnt_shell",
				"riding a burnt_shell instance placed the ordinary way")
		t.check(director.contact_position() != Vector2.INF, "somewhere reachable")

		director.free()
		GameState.scars = saved_scars)

## Mirrors the real day order (`main._start_day()`: city, events, resistance) rather than
## skipping the middle step. `EventManager.start_day()` is what holds every door segment for the
## day (`CityMap.held_segments`, filled from `region_plan.doors` among other things) — with it
## never run, a bare `_pick_reachable()` call would find the door tile reachable whether or not
## `_place_at_a_door()`'s `allow_held` carve-out (`docs/DECISIONS.md`, M181) actually does
## anything, so this test would pass whether the carve-out worked or was deleted. Also asserts
## the chosen tile's segment reads held, so the test states it is exercising that case rather
## than one where the held set happens to be empty.
func _test_the_door_task_sits_at_a_region_door(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var closure_state := CityState.new()
		closure_state.begin_day(_city.map.block_plans, 9)
		_city.start_day(closure_state, 9, _rng(9, "closures"))
		var doors := _city.region_plan().doors
		t.check(not doors.is_empty(),
				"day 9 (Tuning.REGION_WALL_FIRST_DAY) has at least one door, or this test "
				+ "checks nothing")
		_city.events.start_day(9, _rng(9, "events"), [], _city.map.doorstep_world_position())

		var director := _director(t)
		director.start_day(9, _rng(9, "resistance"), 300.0)
		director._on_contact_completed(7)
		t.check(director.current_step() != null and director.current_step().index == 8,
				"touching day 9's mark activates the crossing perform")
		t.check(director._rider == null, "the crossing sits on a bare point, not a rider")

		var at := director.contact_position()
		t.check(at != Vector2.INF, "somewhere in the city")
		t.check(_city.map.is_held_at(_city.map.world_to_tile(at)),
				"the chosen tile's own segment is ground the day already holds — the case " +
				"`allow_held` exists for")
		var on_a_door := false
		for segment in doors:
			var rect := segment.tile_rect()
			if rect.position + rect.size / 2 == _city.map.world_to_tile(at):
				on_a_door = true
				break
		t.check(on_a_door, "exactly at one of today's own region doors")

		director.free())

## `allow_held` (`docs/DECISIONS.md`, M181) skips `is_held_at()` outright, and `is_held_at()` is
## the half of "nothing on the home block" that covers the streets around it, not just the lot
## `is_on_home_block()` covers — so without `_place_at_a_door()`'s own home-border filter, a door
## on one of those streets would sit through the held carve-out along with the rest. Sweeps the
## same seed set `_test_no_alley_robbery_stands_near_the_doorstep` does; several draws per city
## (`_pick_reachable()` picks uniformly among every reachable door) rather than one, because a
## single draw could miss the one candidate that borders the home block even with the filter
## deleted. Seed 2295276695 is where a home-bordering door actually exists on day 9 — measure
## again with `tools/test.sh probes/<name>.gd` naming that seed and printing `RegionPlanner.
## plan_day`'s own doors against `StreetNetwork.around_blocks` if this ever needs re-checking.
func _test_the_door_task_never_borders_the_home_block(t) -> void:
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	var day := 9
	var draws := 20
	var checked := 0
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		var closure_state := CityState.new()
		closure_state.begin_day(city.map.block_plans, day)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("%d:closures:%d" % [seed_value, day])
		city.start_day(closure_state, day, closure_rng)
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("%d:events:%d" % [seed_value, day])
		city.events.start_day(day, events_rng, [], city.map.doorstep_world_position())

		var home_border := StreetNetwork.around_blocks(
				Rect2i(city.map.home_block, Vector2i.ONE))
		var home_border_keys := {}
		for segment in home_border:
			home_border_keys[segment.key()] = true

		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)
		for draw in draws:
			var door_rng := RandomNumberGenerator.new()
			door_rng.seed = hash("%d:door:%d:%d" % [seed_value, day, draw])
			var at: Vector2 = director._place_at_a_door(door_rng)
			if at == Vector2.INF:
				continue
			checked += 1
			var segment := StreetNetwork.segment_containing(city.map.world_to_tile(at))
			var bordering := segment != null and home_border_keys.has(segment.key())
			t.check(not bordering,
					("seed %d day %d draw %d: the door task never sits on a segment bordering " +
					"the home block") % [seed_value, day, draw])
		director.free()
		city.free()
	t.check(checked > 0, "some (seed, draw) actually placed a door contact to check (%d)" % checked)

func _test_the_swing_task_sits_at_an_open_playground(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		t.check(not _city.map.playgrounds.is_empty(),
				"the test city has at least one open playground, or this test checks nothing")

		var director := _director(t)
		director.start_day(12, _rng(12, "resistance"), 300.0)
		director._on_contact_completed(11)
		t.check(director.current_step() != null and director.current_step().index == 12,
				"touching day 12's mark activates the swing perform")
		t.check(director._rider == null, "the swing sits on a bare point, not a rider")

		var at := director.contact_position()
		var on_a_swing := false
		for rect in _city.map.playgrounds:
			if _city.map.world_to_tile(_city.map.swing_position(rect)) \
					== _city.map.world_to_tile(at):
				on_a_swing = true
				break
		t.check(on_a_swing, "exactly at one open park's own swing")

		director.free())

# ----------------------------------------------------------------- red arrow ---

## Two "any instance" tasks (the man shouting, a roadblock) earn no arrow; every other built
## perform step is one place and does. A mark never earns one either way, whichever task it
## unlocks.
func _test_the_red_arrow_only_ever_points_at_a_one_place_task(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var mark_only := _director(t)
		mark_only.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(mark_only.red_arrow_target() == Vector2.INF, "a mark never earns the red arrow")
		mark_only.free()

		var yeller := _director_on_the_yeller_perform(t)
		t.check(yeller.red_arrow_target() == Vector2.INF,
				"the yeller is any instance, so it earns no arrow")
		yeller.free()

		GameState.completed_resistance_steps = _completed_through(2)
		var van := _director(t)
		van.start_day(7, _rng(7, "resistance"), 300.0)
		van._on_contact_completed(3)
		t.check(van.red_arrow_target() != Vector2.INF
				and van.red_arrow_target() == van.contact_position(),
				"the package's van is one place, so it earns the arrow, exactly at the contact")
		van.free())
