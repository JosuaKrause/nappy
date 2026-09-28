extends RefCounted
## The resistance subquest: the step table, touch-completion, a task activated the same day its
## mark is touched, the four placement kinds a perform step may use, the seeded guard, the
## expiring step, and the sabotage putting the city's masts out once she has walked away.

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
	_test_day_eights_mark_is_about_as_long_as_the_shortest_other_mark(t)
	_test_step_selection(t)
	_test_the_finale_needs_the_legwork(t)
	_test_touching_completes_a_pickup(t)
	_test_walking_away_leaves_it_untouched(t)
	_test_the_chalk_mark_pictures_are_baked_on_decoration(t)
	_test_a_perform_contact_rides_on_its_instance(t)
	_test_the_notes_handover_completes_at_his_inner_radius_not_reach(t)
	_test_a_perform_contact_sees_its_rider_finish(t)
	_test_touching_the_mark_activates_the_same_days_task(t)
	_test_placement_is_deterministic(t)
	_test_the_dawn_draws_ignore_where_the_last_attempt_left_her(t)
	_test_the_guard_is_seeded(t)
	_test_an_unseen_mark_moves_to_the_nearest_alley_she_comes_near(t)
	_test_a_mark_within_notice_radius_does_not_move(t)
	_test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t)
	_test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t)
	_test_a_guard_never_lands_within_his_own_reach_of_her(t)
	_test_a_relocated_mark_and_its_guard_are_placed_off_screen(t)
	_test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t)
	_test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t)
	_test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t)
	_test_the_guard_moves_with_the_mark_to_the_alleys_far_end(t)
	_test_a_relocation_never_retires_a_guard_in_view_or_awake(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_the_chalk_mark_guard_stands_at_the_alleys_far_end(t)
	_test_the_mark_is_reachable_from_its_own_end(t)
	_test_a_mark_is_never_in_a_courtyard_passage(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	_test_a_perform_contact_is_never_relocated(t)
	_test_the_contact_rides_onto_the_first_look_alike_she_reaches(t)
	_test_the_step_completes_on_the_look_alike_she_hands_it_to(t)
	_test_a_task_that_rides_on_a_row_stands_unguarded_until_it_is_handed_over(t)
	_test_the_van_task_stands_unguarded_until_it_is_handed_over(t)
	_test_the_burnt_shell_and_the_roadblock_keep_a_waiting_guard(t)
	_test_the_handover_sets_a_robber_on_her_from_off_screen(t)
	_test_the_van_handover_sets_a_guard_on_her_from_off_screen(t)
	_test_the_robber_after_her_is_announced_before_he_can_catch_her(t)
	_test_the_van_guard_after_her_is_announced_before_he_can_catch_her(t)
	_test_the_robber_after_her_is_never_the_schedulers(t)
	_test_the_van_guard_after_her_is_never_the_schedulers(t)
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
	_test_a_completed_marks_own_contact_and_guard_survive_to_the_day_end(t)
	_test_a_read_mark_does_not_pile_up_across_several_ordinary_days(t)
	_test_the_door_task_never_borders_the_home_block(t)
	_test_the_swing_task_sits_at_an_open_playground(t)
	_test_day_twelves_park_is_forced_open_whatever_its_state(t)
	_test_the_mast_task_silences_one_mast_for_the_rest_of_the_run(t)
	_test_the_mast_task_favors_the_near_mast(t)
	_test_the_neighbor_leaves_for_work_until_the_raid(t)
	_test_day_ten_sends_her_to_the_neighbor_walking_home(t)
	_test_the_raid_waits_at_her_building_with_the_doorstep_open(t)
	_test_the_raid_seals_her_street_door(t)
	_test_the_sealed_door_stands_after_a_reload(t)
	_test_a_lost_day_ten_restores_the_ordinary_door(t)
	_test_the_neighbor_window_is_boarded_from_day_eleven(t)
	_test_the_market_is_found_gone(t)
	_test_the_park_closes_in_front_of_her_and_stays_taken(t)
	_test_the_column_comes_down_the_main_road(t)
	_test_the_red_arrow_only_ever_points_at_a_one_place_task(t)
	_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground(t)
	_test_a_mark_is_never_placed_in_an_alley_she_cannot_reach(t)
	_test_a_relocated_mark_is_never_placed_in_an_alley_she_cannot_reach(t)
	_test_the_narrow_targets_are_reachable_on_their_day(t)
	_test_pick_reachable_only_replaces_the_candidate_the_new_check_rejects(t)
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
		t.check(step.placement.size() > 0 or ResistanceSteps.sits_on_a_bare_point(step),
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
		elif not step.needs_goal:
			t.check(step.task_event_id != "" or ResistanceSteps.sits_on_a_bare_point(step),
					"perform step %d names what it rides on or how it finds its own place"
					% step.index)
			available_performs += 1

		previous_index = step.index
		previous_day = step.day

	t.check(available_performs > Tuning.RESISTANCE_GOAL,
			"there are more built perform steps than the goal needs, so one task can be missed")
	t.check(steps[steps.size() - 1].needs_goal, "the finale is the last step")
	t.check(steps[steps.size() - 1].day == Tuning.RUN_LENGTH_DAYS, "and it is on the last day")

## rosy-raven, "day 8's task text is short" — *"yeah, day 8th hint needs to be fixed. it's too
## long"* (olive-koala, statement 3; the same 79-character line
## `docs/todo/2026-09-09-M100/day-8s-mark-line-runs-off.md` already found running off the HUD's
## own teaching line, which does not wrap). A relationship rather than a literal, since the exact
## wording is this branch's own choice, not the player's: about as long as day 6's own mark, the
## item's own reference for "short", and still saying where to take it.
func _test_day_eights_mark_is_about_as_long_as_the_shortest_other_mark(t) -> void:
	var day6 := ResistanceSteps.by_index(1).brief
	var day8 := ResistanceSteps.by_index(5).brief
	t.check(day8.length() <= day6.length() * 1.5,
			"day 8's mark (%d chars, %s) is about as long as day 6's (%d chars), not the old 79"
			% [day8.length(), day8, day6.length()])
	t.check("burnt building" in day8, "and it still says where to take it")

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

func _test_the_finale_needs_the_legwork(t) -> void:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if not step.needs_goal:
			done.append(step.index)
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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

## `ContactPoint._draw_chalk()` reads `MARK` untouched and `MARK_TOUCHED` once `is_done` from the
## baked `decoration` group instead of stroking a circle and two lines — headless never calls
## `_draw()` (the **verify** skill), so this is the same region-table check
## `tests/test_atlas_leaf_consumers.gd` runs for every other consumer that switched from code or a
## loaded texture to an `AtlasLibrary` region: a name the bake never wrote would otherwise sit
## silent until somebody looked at a screenshot.
func _test_the_chalk_mark_pictures_are_baked_on_decoration(t) -> void:
	for name: StringName in [ContactPoint.MARK, ContactPoint.MARK_TOUCHED]:
		t.check(AtlasLibrary.has_region(name), "%s is a baked region" % name)
		t.check(AtlasLibrary.group_of(name) == ContactPoint.ATLAS_GROUP,
				"%s is on the '%s' group" % [name, ContactPoint.ATLAS_GROUP])

## The shared plumbing every task needs: a contact that rides on an `EventInstance` rather
## than sitting on a bare tile, and follows it if it moves.
func _test_a_perform_contact_rides_on_its_instance(t) -> void:
	_player = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

	# The rider moves; the contact follows it rather than staying where it started. Index 2's own
	# `completes_at_inner_radius` (M205) still completes on the first tick she is in reach -- it
	# only changes which radius that reach is measured against, not whether it is instant.
	instance.position = Vector2.ZERO
	contact._physics_process(STEP)
	t.check(contact.is_done, "and completes once she reaches wherever the rider has gone")

	contact.free()
	instance.free()
	_player.free()

## M205, "the note costs, and the ordinary day" -- fails before the fix: the old code completed
## the instant `ContactPoint.REACH` (36px) was reached, which sits inside a rider's 45px
## `inner_radius`, so a note handed over on the way past landed only the last few pixels of his
## full-strength field before he left. A fork proposed fixing that with a dwell -- standing
## inside `inner_radius` for a couple of seconds before it completes -- and the player rejected
## it outright: "the player should stand for 2.5s? no way. the moment the player touches the
## inner circle it counts as delivered." So this pins the simpler fix instead: day 6's note
## completes on the very first tick she is within his `inner_radius`, even short of `REACH`,
## while an ordinary step at the identical distance does not complete at all, and stepping short
## of `inner_radius` altogether does not complete either.
func _test_the_notes_handover_completes_at_his_inner_radius_not_reach(t) -> void:
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	player.set_physics_process(false)

	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var step := ResistanceSteps.by_index(2)
	t.check(step.completes_at_inner_radius, "day 6's note is the one step this applies to")
	t.check(ContactPoint.REACH < instance.def.inner_radius,
			"the case this test distinguishes -- REACH sits inside inner_radius -- or the checks " +
			"below prove nothing")

	# Between REACH (36px) and inner_radius (45px): outside the ordinary REACH check, but inside
	# the wider circle the note actually uses.
	var between := (ContactPoint.REACH + instance.def.inner_radius) * 0.5
	player.global_position = Vector2.RIGHT * between

	var note_contact := ContactPoint.new()
	note_contact.ride(step, instance, Vector2.ZERO)
	t.add_child(note_contact)
	note_contact.set_physics_process(false)
	note_contact._physics_process(STEP)
	t.check(note_contact.is_done,
			"one tick inside inner_radius completes it, even though REACH alone would not have")
	note_contact.free()

	# The identical distance, on an ordinary step that never sets `completes_at_inner_radius`:
	# REACH is what it checks, and this distance sits outside it.
	var ordinary_step := ResistanceSteps.Step.new()
	t.check(not ordinary_step.completes_at_inner_radius,
			"a bare Step defaults to the ordinary REACH check")
	var ordinary_contact := ContactPoint.new()
	ordinary_contact.ride(ordinary_step, instance, Vector2.ZERO)
	t.add_child(ordinary_contact)
	ordinary_contact.set_physics_process(false)
	ordinary_contact._physics_process(STEP)
	t.check(not ordinary_contact.is_done,
			"the same distance does not complete an ordinary step's REACH check")
	ordinary_contact.free()

	# Outside inner_radius altogether: too far for the note either.
	player.global_position = Vector2.RIGHT * (instance.def.inner_radius + 5.0)
	var outside_contact := ContactPoint.new()
	outside_contact.ride(step, instance, Vector2.ZERO)
	t.add_child(outside_contact)
	outside_contact.set_physics_process(false)
	outside_contact._physics_process(STEP)
	t.check(not outside_contact.is_done, "outside inner_radius, the note is not delivered either")
	outside_contact.free()

	instance.free()
	player.free()

func _test_a_perform_contact_sees_its_rider_finish(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("roadblock"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var contact := ContactPoint.new()
	contact.ride(_perform_on(13), instance, Vector2(90.0, 0.0))
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
func _build_city(t, seed_value := SEED) -> void:
	if _city != null:
		_city.free()
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(seed_value))

func _director(t) -> ResistanceDirector:
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.set_process(false)
	director.setup(_city, _city.map)
	return director

func _rng(day: int, stream: String, seed_value := SEED) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
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

## The perform step on `day` — named by its day rather than by its index, so a task added earlier
## in the calendar does not renumber every test after it.
func _perform_on(day: int) -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.day == day and not step.is_pickup and not step.needs_goal:
			return step
	return null

func _completed_through(last_index: int) -> Array[int]:
	var done: Array[int] = []
	done.assign(range(1, last_index + 1))
	return done

## Day 6's mark, started and touched — the shape most of this suite's perform-step tests now
## need, since `start_day()` alone only ever offers a mark (`ResistanceSteps.for_day()`). Returns
## the director with step 2 (the yeller perform) already active.
func _director_on_the_yeller_perform(t, seed_value := SEED) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(6, _rng(6, "resistance", seed_value), 300.0)
	director._on_contact_completed(1)
	return director

## Day 7's mark, started and touched — the van's own perform step, active. Mirrors
## `_director_on_the_yeller_perform()` for the one-place task the van's chasing guard rides on.
func _director_on_the_van_perform(t) -> ResistanceDirector:
	var director := _director(t)
	director.start_day(7, _rng(7, "resistance"), 300.0)
	director._on_contact_completed(3)
	return director

## "Deterministic from the run seed and the day" (`ResistanceDirector`'s class doc) holds on a
## retry too: `main.gd` starts the resistance before it resets her, so at dawn her position and the
## camera are still the previous attempt's. Each day is started twice on the same city — once with
## her at the doorstep and nothing on screen, once with her standing on the first attempt's own
## contact, where a lost day often leaves her, and everything on screen — and the dawn guard, and
## on day 9 the door and its guard that reading the mark then places with her at the same spot both
## times, come out the same. Day 9 is a mark's own guard; day 14's front door is a task guarded
## from dawn.
func _test_the_dawn_draws_ignore_where_the_last_attempt_left_her(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_progress := GameState.resistance_progress
		var saved_sabotage := GameState.sabotage_done
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		GameState.sabotage_done = false
		for day in [9, Tuning.RUN_LENGTH_DAYS]:
			var first := _attempt_the_day(t, day, _city.map.doorstep_world_position(), false)
			var retry := _attempt_the_day(t, day, first[0], true)
			t.check(first[0] != Vector2.INF and first[1] != Vector2.INF,
					"day %d: the contact and its guard are placed (%s, %s)" % [day, first[0], first[1]])
			for i in first.size():
				t.check(first[i].distance_to(retry[i]) < 0.5 or first[i] == retry[i],
						"day %d: draw %d comes out the same wherever the last attempt left her (%s, %s)"
						% [day, i, first[i], retry[i]])
		GameState.completed_resistance_alley_tiles = saved_tiles
		GameState.resistance_progress = saved_progress
		GameState.sabotage_done = saved_sabotage)

## One attempt at `day` for the test above, with her standing at `her` and `_sight` answering
## `seen` for every point when the day starts: `[contact, its guard]` at dawn, then on a mark's day
## `[task contact, task guard]` once she reads it from the mark's own spot with nothing on screen.
## `Vector2.INF` for a guard that was not placed.
func _attempt_the_day(t, day: int, her: Vector2, seen: bool) -> Array[Vector2]:
	GameState.completed_resistance_steps = _completed_through(2 * (day - 6)) \
			if day < Tuning.RUN_LENGTH_DAYS else _all_but_the_finale()
	# A lost day gives back what the attempt recorded (`GameState.begin_day()`), the alley it read
	# its mark in included.
	GameState.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
	var player := _rig_player(t, her)
	var director := _director(t)
	director.set_sight(func(_p: Vector2) -> bool: return seen)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var step := director.current_step()
	var drawn: Array[Vector2] = [director.contact_position()]
	var guard: EventInstance = director._guard if step and step.is_pickup else director._task_guard
	drawn.append(guard.global_position if guard else Vector2.INF)
	if step and step.is_pickup:
		player.global_position = director.contact_position()
		director.set_sight(func(_p: Vector2) -> bool: return false)
		director._on_contact_completed(step.index)
		drawn.append(director.contact_position())
		var task_guard: EventInstance = director._task_guard
		drawn.append(task_guard.global_position if task_guard else Vector2.INF)
	player.free()
	director.free()
	return drawn

func _all_but_the_finale() -> Array[int]:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if not step.needs_goal:
			done.append(step.index)
	return done

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

## *Always guarded* has to mean a survivable placement, not a guaranteed lost day: a robber
## stands at least 66px (30 + `ContactPoint.REACH`) from every mark, and within 96px of the
## alley's own far mouth (`_draw_guard_position_near_far_mouth()`'s own reach), seeded so the
## distance is the same every time this day is replayed.
func _test_the_guard_is_seeded(t) -> void:
	_seen_guard_distances = []
	_with_clean_run(func() -> void:
		var before := _director(t)
		before.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(before.current_step() == null, "nothing is offered before day 6")
		before.free()

		var robbery := EventCatalogue.by_id("alley_robbery")
		var min_distance: float = robbery.inner_radius + ContactPoint.REACH

		for day in [6, 7, 8, 9]:
			GameState.completed_resistance_steps = _completed_through(2 * (day - 6))
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var at := director.contact_position()
			# The director's own `_guard`, not a proximity search over `_city.events.instances()`:
			# this loop never retires a day's guard before the next iteration spawns another, so a
			# search by distance alone can pick up an earlier day's stale robber instead of the one
			# this day's trap actually set — which is what a search radius wide enough to catch a
			# station-shrunk city's tighter geometry made real. Reading the tracked instance is
			# precedented by `_test_the_burnt_shell_task_rides_the_recorded_scar`'s `director._rider`.
			var guard: EventInstance = director._guard
			t.check(guard != null and is_instance_valid(guard), "day %d's mark is guarded" % day)
			var distance := guard.global_position.distance_to(at) if guard else -1.0
			if guard:
				t.check(distance >= min_distance - 0.5,
						"day %d's guard stands at least 66px from the mark" % day)
				var far := director._far_alley_mouth(at)
				t.check(far == Vector2.INF or guard.global_position.distance_to(far) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
						"day %d's guard stands within reach of the alley's far mouth" % day)
				_seen_guard_distances.append(distance)
			director.free()

			var replay := _director(t)
			replay.start_day(day, _rng(day, "resistance"), 300.0)
			var replay_guard: EventInstance = replay._guard
			if guard and replay_guard and is_instance_valid(replay_guard):
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

## The world position of a through-alley tile more than `min_distance` from `at`, or `Vector2.INF`
## if the test city has none. Used to put her far enough from the mark that the re-placement
## rule has to fire.
func _alley_farther_than(min_distance: float, at: Vector2) -> Vector2:
	for tile in _through_alleys():
		var world := _city.map.tile_to_world(tile)
		if world.distance_to(at) > min_distance:
			return world
	return Vector2.INF

## The test city's through-alley tiles — the only ground a mark is placed on or relocated to
## (`ResistanceDirector._through_alley_tiles()`).
func _through_alleys() -> Array[Vector2i]:
	var director := ResistanceDirector.new()
	director.setup(null, _city.map)
	var tiles := director._through_alley_tiles().duplicate()
	director.free()
	return tiles

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
## later, so a fifteen-tile-distant alley froze it for the rest of the day. `_sight` answering
## true near `mark_at` alone reproduces "on screen" there without a viewport, while leaving
## `far_alley` — the relocation target, over `NOTICE_RADIUS` away — answering false, the ground
## `_nearest_alley_within()` needs to still offer a candidate since brisk-wombat's fix (never a
## tile she can currently see, "the mark and its robber never appear in front of her"); standing
## at `far_alley` (beyond `NOTICE_RADIUS`, so certainly beyond the far narrower `SEEN_DISTANCE`)
## reproduces the distance. A single frame is enough to show the old bug is gone: the old rule
## pinned the mark on this exact frame, and the new one still relocates it.
func _test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		director.set_sight(func(p: Vector2) -> bool: return p.distance_to(mark_at) < 100.0)

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, mark_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		t.check(director.contact_position().distance_to(far_alley) < 0.5,
				"on screen but far outlasts nothing: it still relocates to the alley she has come near")

		player.free()
		director.free())

## brisk-wombat, "the mark and its robber never appear in front of her" — the mark's own half:
## *"I just had one appear out of nowhere while I was walking through an alley."* `_nearest_alley_
## within()`'s own nearest candidate to `here` is, by construction, wherever she is standing or
## right beside it, which is on screen more often than not, so the search has to actively refuse
## whatever `_is_visible()` calls seen rather than pick the plain nearest blind. `raw_nearest`
## names exactly that plain-nearest tile (asked with no `_sight` set at all, so nothing is ever
## "seen"); hiding only that one tile from a mocked `_sight` is what makes the assertion below
## discriminate the refusal — the search has to find some other candidate still in `NOTICE_RADIUS`
## rather than the one nearest tile it would otherwise answer.
func _test_a_relocated_mark_never_lands_where_she_can_see_it_appear(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		t.check(far_alley != Vector2.INF, "the test city has an alley far from the mark")
		var player := _rig_player(t, far_alley)

		var raw_nearest := director._nearest_alley_within(far_alley)
		t.check(raw_nearest.distance_to(far_alley) < 0.5,
				"with no screen test at all, the nearest reachable alley is the one she stands on")
		director.set_sight(func(p: Vector2) -> bool: return p.distance_to(raw_nearest) < 0.5)

		director._process(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
		t.check(new_at.distance_to(raw_nearest) > 0.5,
				"but never to the one tile she could see it appear on")

		player.free()
		director.free())

## brisk-wombat's other half: *"a robber also appeared out of nowhere and instakilled me."* A
## guard's own band is drawn relative to the mark alone, with no idea where she is standing, so a
## mark relocating right up to where she stands (or a dawn placement near a wandering player)
## could put him inside his own `pursues_within`, or worse `inner_radius` (a `hard_fail` with no
## warning), of wherever she actually is unless the draw is also asked to refuse that. Checked
## directly against `_draw_guard_position()`, the shared draw every guarded contact uses, with
## `her` forced onto the mark itself — the closest a real guard's own band ever gets to her.
func _test_a_guard_never_lands_within_his_own_reach_of_her(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-keeps-off-her:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			for _attempt in 3:
				checked += 1
				var guard_at := director._draw_guard_position(rng, mark, Vector2.INF,
						min_distance, max_distance, [], mark, robbery.pursues_within)
				if guard_at == Vector2.INF:
					continue
				t.check(guard_at.distance_to(mark) > robbery.pursues_within,
						"seed %d: the guard for the mark at %s never lands within his own reach of her"
						% [seed_value, tile])
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws)" % checked)

## brisk-wombat, both halves: *"I just had one appear out of nowhere while I was walking through an
## alley and then a robber also appeared out of nowhere and instakilled me."* She stands on every
## other through-alley tile of two cities; the screen is the unrotated 640x360 world px around her
## (`Tuning.VIEW_HALF_EXTENT`). Wherever `_nearest_alley_within()` relocates the mark, no part of
## its 32px picture is on that screen, and the guard `_move_the_mark()` stands for it
## (`_guard_position()`, as `_maybe_set_a_trap()` calls it for a relocation) exists and shows no
## part of his 22x44px body on it either. The guard a task sets at its contact when she reads the
## mark (`for_mark` false), asked of a contact just past the edge of her screen, never shows either.
## Every box is measured here from the screen's own edges rather than through the director's
## `_box_shows()`, so the test does not ask the code whether the code is right.
func _test_a_relocated_mark_and_its_guard_are_placed_off_screen(t) -> void:
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	GameState.completed_resistance_alley_tiles = []
	var relocations := 0
	var tasks := 0
	for seed_value in [4242, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("off-screen:%d" % seed_value)
		var through := director._through_alley_tiles()
		for i in range(0, through.size(), 2):
			var her := map.tile_to_world(through[i])
			director.set_sight(func(p: Vector2) -> bool:
				return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
						and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y)
			var mark := director._nearest_alley_within(her)
			if mark != Vector2.INF:
				relocations += 1
				t.check(not _box_on_screen(mark, Vector2(16.0, 16.0), her),
						"seed %d: from %s, no part of the relocated mark at %s is on screen"
						% [seed_value, through[i], map.world_to_tile(mark)])
				var guard_at := director._guard_position(rng, mark, true, her, true)
				t.check(guard_at != Vector2.INF,
						"seed %d: the mark relocated to %s is guarded"
						% [seed_value, map.world_to_tile(mark)])
				if guard_at != Vector2.INF:
					t.check(not _box_on_screen(guard_at + Vector2(0.0, -22.0),
							Vector2(11.0, 22.0), her),
							"seed %d: from %s, no part of the relocated mark's guard at %s is on screen"
							% [seed_value, through[i], map.world_to_tile(guard_at)])
			var contact := her + Vector2(Tuning.VIEW_HALF_EXTENT.x + 40.0, 0.0)
			var task_guard := director._guard_position(rng, contact, false, her, true)
			if task_guard != Vector2.INF:
				tasks += 1
				t.check(not _box_on_screen(task_guard + Vector2(0.0, -22.0), Vector2(11.0, 22.0),
						her), "seed %d: a task's guard at %s is not on screen from %s"
						% [seed_value, map.world_to_tile(task_guard), through[i]])
		director.free()
	GameState.completed_resistance_alley_tiles = saved_tiles
	t.check(relocations > 0 and tasks > 0,
			"marks were relocated (%d) and task guards drawn (%d)" % [relocations, tasks])

## Whether a box `half` either side of `centre` overlaps the unrotated screen around `her`.
func _box_on_screen(centre: Vector2, half: Vector2, her: Vector2) -> bool:
	return absf(centre.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x + half.x \
			and absf(centre.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y + half.y

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

## The two through-alley tiles closest together in the built test city — `[player_at, nearer,
## other]`, `player_at` sitting exactly on `nearer` so it is always the globally nearest one to
## itself, and `other` confirmed within `ResistanceDirector.NOTICE_RADIUS` of it. Empty if the city has no pair
## that close, which the relocation test below skips on rather than asserting through.
func _two_nearby_alleys() -> Array:
	var alleys := _through_alleys()
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

## M213, "the robber guarding a chalk mark always spawns at the alley's other end from the mark":
## a relocated mark's fresh guard follows the same rule as the dawn draw, standing at the far
## mouth of whichever alley the mark relocated to, or as near it as the alley allows, rather than
## in a band around the mark itself.
func _test_the_guard_moves_with_the_mark_to_the_alleys_far_end(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()
		var old_guard: EventInstance = director._guard

		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)

		director._process(STEP)
		var new_at := director.contact_position()
		t.check(new_at.distance_to(old_at) > 0.5, "the mark actually moved")
		t.check(old_guard != null and old_guard.is_finished,
				"the old guard is retired, not left standing over the spot the mark left")

		var guards: Array[EventInstance] = []
		for instance in _city.events.instances():
			if instance.def.id == "alley_robbery" and not instance.is_finished:
				guards.append(instance)
		t.check(guards.size() == 1, "exactly one live guard exists once the mark has moved (%d)"
				% guards.size())

		var guard: EventInstance = guards[0]
		var far_mouth := director._far_alley_mouth(new_at)
		t.check(far_mouth != Vector2.INF, "the relocated mark's own alley is found")
		t.check(guard.global_position.distance_to(far_mouth) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
				"the new guard stands at the alley's far mouth, not in a band around the mark")

		player.free()
		director.free())

## A robber never vanishes where she can see him or out of a chase: an unread mark's relocation,
## which retires the guard over the old spot, waits while any part of him is on her screen or he
## is awake, and goes ahead once neither holds. She stands on an alley past `NOTICE_RADIUS` of the
## mark, where the relocation would otherwise fire on the first frame.
func _test_a_relocation_never_retires_a_guard_in_view_or_awake(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var old_at := director.contact_position()
		var guard: EventInstance = director._guard
		t.check(guard != null, "day 6's mark is guarded")
		if guard == null:
			director.free()
			return
		var far_alley := _alley_farther_than(ResistanceDirector.NOTICE_RADIUS, old_at)
		var player := _rig_player(t, far_alley)

		var feet := guard.global_position
		director.set_sight(func(p: Vector2) -> bool: return p.distance_to(feet) < 40.0)
		director._process(STEP)
		t.check(director.contact_position().distance_to(old_at) < 0.5,
				"with him on her screen, the mark stays where it is")
		t.check(not guard.is_finished, "and he is not retired in front of her")

		director.set_sight(func(_p: Vector2) -> bool: return false)
		guard._noticed_at = 0.0
		director._process(STEP)
		t.check(director.contact_position().distance_to(old_at) < 0.5,
				"off her screen but awake, the mark still stays where it is")
		t.check(not guard.is_finished, "and he is not retired out of his chase")

		guard._noticed_at = INF
		director._process(STEP)
		t.check(director.contact_position().distance_to(old_at) > 0.5,
				"asleep and out of her sight, the mark moves")
		t.check(guard.is_finished, "and he is retired with it")
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

## M213, "the robber guarding a chalk mark always spawns at the alley's other end from the mark":
## over every through-alley tile of six cities, `_draw_guard_position_near_far_mouth()` stands him
## within `FAR_END_REACH_IN` of `_far_alley_mouth()`, never nearer the mark than `max_distance`
## where the alley has room beyond it, and on the far end itself where it has not — the same sweep
## `_test_the_guard_never_lands_inside_a_building` runs, checked for position instead of legality.
## The item's own "a test states the distance from the mark to him over many seeds" is the
## varies-from-mark-to-mark check at the end.
func _test_the_chalk_mark_guard_stands_at_the_alleys_far_end(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	var distances: Array[float] = []
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-far-end:%d" % seed_value)
		for tile in director._through_alley_tiles():
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			var far := director._far_alley_mouth(mark)
			t.check(far != Vector2.INF, "seed %d: the mark at %s has a far end" % [seed_value, tile])
			if far == Vector2.INF:
				continue
			for _attempt in 3:
				var guard_at := director._draw_guard_position_near_far_mouth(rng, mark, far,
						min_distance, max_distance, [], Vector2.INF, 0.0, false)
				if guard_at == Vector2.INF:
					continue
				checked += 1
				t.check(guard_at.distance_to(far) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
						("seed %d: the guard for the mark at %s stands within reach of the " +
						"alley's far end") % [seed_value, tile])
				if mark.distance_to(far) >= max_distance:
					t.check(guard_at.distance_to(mark) >= max_distance - 0.5,
							("seed %d: the alley past the mark at %s has room, so he stands " +
							"beyond %.0fpx of it") % [seed_value, tile, max_distance])
				else:
					t.check(guard_at.distance_to(far) < 0.5,
							("seed %d: the alley past the mark at %s is shorter than %.0fpx, so " +
							"he stands on its far end") % [seed_value, tile, max_distance])
				t.check(guard_at.distance_to(mark) >= min_distance - 0.5,
						"seed %d: and never within %.0fpx of the mark at %s"
						% [seed_value, min_distance, tile])
				distances.append(mark.distance_to(guard_at))
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d draws)" % checked)
	var all_equal := true
	for distance in distances:
		if not is_equal_approx(distance, distances[0]):
			all_equal = false
	t.check(distances.size() >= 2 and not all_equal,
			"the guard's own distance from the mark still varies from mark to mark")

## M213, "the mark is reachable" — *"It's impossible to get the mark on most days. Let's always
## place the river at the other end of the alley"* (PLAYTEST-142 statement 5; "river" is dictation
## for *robber*). Over every through-alley tile of six cities, she walks in from a tile and a half
## outside the alley's near end, up to `ContactPoint.REACH` less two pixels short of the mark on its
## near side — close enough to read it — and back out the same way, past a bare `alley_robbery` at
## the director's own far-end draw. The same marks and the same walk are asked of the whole-circle
## 66-176px band around the mark, which is how a mark's guard stood without the far-end rule, so
## the test says what the rule buys rather than only that some mark can be reached.
##
## **Every mark, not most**: a through-alley's far end is at least four tiles (128px) from any mark
## in it, so a touch from the near side is past his `pursues_within` (140px) wherever he stands at
## that end — see `_draw_guard_position_near_far_mouth()`. The band leaves him asleep on well under
## that share of the same marks, which is what keeps this test from passing without the rule.
func _test_the_mark_is_reachable_from_its_own_end(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	var band_asleep := 0
	var far_end_asleep := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var band_rng := RandomNumberGenerator.new()
		band_rng.seed = hash("mark-reachable-band:%d" % seed_value)
		var far_end_rng := RandomNumberGenerator.new()
		far_end_rng.seed = hash("mark-reachable-far-end:%d" % seed_value)
		for tile in director._through_alley_tiles():
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			var ends := director._alley_ends(mark)
			if ends.is_empty():
				continue
			var near: Vector2 = ends[0]
			var far: Vector2 = ends[1]
			var band_at := director._draw_guard_position(band_rng, mark, Vector2.INF, min_distance,
					max_distance)
			var far_end_at := director._draw_guard_position_near_far_mouth(far_end_rng, mark, far,
					min_distance, max_distance, [], Vector2.INF, 0.0, false)
			if band_at == Vector2.INF or far_end_at == Vector2.INF:
				continue
			checked += 1
			var axis := (far - near).normalized()
			var outside := near - axis * Tuning.TILE_SIZE * 1.5
			var touch := mark - axis * (ContactPoint.REACH - 2.0)
			if _stays_asleep_walking_in_and_out(robbery, band_at, outside, touch):
				band_asleep += 1
			if _stays_asleep_walking_in_and_out(robbery, far_end_at, outside, touch):
				far_end_asleep += 1
		director.free()
	t.check(checked > 0, "some guarded mark was actually checked (%d)" % checked)
	var band_rate := float(band_asleep) / float(maxi(checked, 1))
	t.check(far_end_asleep == checked,
			("walking in from the mark's own end to read it and back out leaves him asleep on " +
			"every mark (%d of %d)") % [far_end_asleep, checked])
	t.check(band_rate < 0.75,
			("and the whole-circle band around the mark leaves him asleep on only %.0f%% of the " +
			"same marks (%d of %d), so the walk tells the two apart")
			% [band_rate * 100.0, band_asleep, checked])

## M213's "always" holds for every mark because no mark is ever in a courtyard's passage — the
## `ALLEY` ground with no far end to stand a robber at (`ResistanceDirector._through_alley_tiles()`).
## Over six cities: the passages exist (so the sweep is not vacuous), no dawn draw of a mark lands
## on one, and no relocation from beside one answers one.
func _test_a_mark_is_never_in_a_courtyard_passage(t) -> void:
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	GameState.completed_resistance_alley_tiles = []
	var mark_step := ResistanceSteps.by_index(1)
	var passages := 0
	var draws := 0
	var relocations := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var through := director._through_alley_tiles()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("no-passage:%d" % seed_value)
		for _draw in 20:
			var at := director._place(mark_step, rng)
			if at == Vector2.INF:
				continue
			draws += 1
			t.check(map.world_to_tile(at) in through,
					"seed %d: the mark drawn at %s is in a through-alley"
					% [seed_value, map.world_to_tile(at)])
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if tile in through:
				continue
			passages += 1
			var nearest := director._nearest_alley_within(map.tile_to_world(tile))
			if nearest == Vector2.INF:
				continue
			relocations += 1
			t.check(map.world_to_tile(nearest) in through,
					"seed %d: a mark relocating from the passage at %s lands in a through-alley"
					% [seed_value, tile])
		director.free()
	GameState.completed_resistance_alley_tiles = saved_tiles
	t.check(passages > 0, "the cities have courtyard passages to keep marks out of (%d)" % passages)
	t.check(draws > 0 and relocations > 0,
			"marks were drawn (%d) and relocated (%d)" % [draws, relocations])

## Walks her from `near` to `mark` and back out, in 8px steps, past a bare `alley_robbery` at
## `guard_at`, and answers whether he stayed asleep the whole way — the question
## `_test_the_mark_is_reachable_from_its_own_end` asks of both draws, over the same walk.
func _stays_asleep_walking_in_and_out(robbery: EventDef, guard_at: Vector2, near: Vector2,
		mark: Vector2) -> bool:
	var robber := EventInstance.new()
	robber.setup(robbery, guard_at)
	var woke := false
	var froms: Array[Vector2] = [near, mark]
	var tos: Array[Vector2] = [mark, near]
	for leg_index in froms.size():
		var from: Vector2 = froms[leg_index]
		var to: Vector2 = tos[leg_index]
		var steps := ceili(from.distance_to(to) / 8.0)
		for s in steps + 1:
			var at := from.lerp(to, float(s) / float(maxi(steps, 1)))
			robber.player_at = at
			robber._process(STEP)
			if not robber.is_waiting():
				woke = true
	robber.free()
	return not woke

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
				# The real placement a chalk mark's own guard actually uses (`_maybe_set_a_trap()`,
				# `for_mark`) is `_draw_guard_position_near_far_mouth()`, not the check above —
				# checked here too, since standing him at the far mouth rather than in a band
				# around the mark is a different draw with no guarantee it inherits this one's.
				var far := director._far_alley_mouth(mark_at)
				if far != Vector2.INF:
					var far_guard_rng := RandomNumberGenerator.new()
					far_guard_rng.seed = hash("%d:far-guard:%d" % [seed_value, day])
					var far_guard_at := director._draw_guard_position_near_far_mouth(
							far_guard_rng, mark_at, far, min_distance, max_distance, [],
							Vector2.INF, 0.0, false)
					if far_guard_at != Vector2.INF:
						checked += 1
						t.check(far_guard_at.distance_to(doorstep) > reach,
								("seed %d day %d: the guard standing at the alley's far mouth is " +
								"not within lethal reach of the doorstep either") % [seed_value, day])
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
			if step.needs_goal or not step.is_pickup:
				continue   # the finale sits at the station's door, and only a mark sits in an alley
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
				if guard_at != Vector2.INF:
					var guard_tile := city.map.world_to_tile(guard_at)
					t.check(not city.map.is_in_walled_alley(guard_tile, walled_alleys),
							("seed %d day %d step %d trial %d: the guard is not inside a walled " +
							"alley either") % [seed_value, day, step.index, trial])
				# The real placement a chalk mark's own guard uses (`_maybe_set_a_trap()`'s
				# `for_mark`) is `_draw_guard_position_near_far_mouth()` instead — checked here
				# too, since it draws from a different band with no guarantee it inherits this
				# one's own walled-alley refusal.
				if step.is_pickup:
					var far := director._far_alley_mouth(at)
					if far != Vector2.INF:
						var far_guard_rng := RandomNumberGenerator.new()
						far_guard_rng.seed = hash("%d:far-guard:%d:%d:%d"
								% [seed_value, day, step.index, trial])
						var far_guard_at := director._draw_guard_position_near_far_mouth(
								far_guard_rng, at, far, min_distance, max_distance, walled_alleys,
								Vector2.INF, 0.0, false)
						if far_guard_at != Vector2.INF:
							var far_guard_tile := city.map.world_to_tile(far_guard_at)
							t.check(not city.map.is_in_walled_alley(far_guard_tile, walled_alleys),
									("seed %d day %d step %d trial %d: the guard standing at the " +
									"alley's far mouth is not inside a walled alley either")
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
		# Step 2's own `completes_at_inner_radius` (M205) still fires on the first tick she is
		# standing on the retargeted contact, exactly as an ordinary REACH-based step would.
		director._contact._physics_process(STEP)
		t.check(completed == [2], "touching the retargeted contact completes step 2 itself")

		player.free()
		director.free())

## *(2026-09-13, PLAYTEST-71: "not the first yeller she reaches but the first yeller she interacts
## with. so the task is always solved by going to any yeller she notices.")* Coming within the
## director's reach of one look-alike moves the contact onto him, and walking on again leaves him
## behind: the step completes on whichever one she then hands the note to. Two look-alikes besides
## the seeded rider, so the first one she comes near is a retarget rather than the rider the step
## already had — a walk that only ever touched the seeded one could pass with the rule deleted.
func _test_the_step_completes_on_the_look_alike_she_hands_it_to(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		var perform := director.current_step()
		t.check(perform != null and perform.index == 2, "the yeller perform is active")
		var seeded: EventInstance = director._rider
		var yeller := EventCatalogue.by_id("homeless_yeller")
		var first_at := director._place(perform, _rng(6, "first look-alike"))
		var second_at := director._place(perform, _rng(6, "second look-alike"))
		var apart := ContactPoint.REACH * 4.0
		t.check(first_at.distance_to(seeded.global_position) > apart
				and second_at.distance_to(seeded.global_position) > apart
				and first_at.distance_to(second_at) > apart,
				"the three look-alikes stand well clear of each other, or this walk checks nothing")
		var first := _city.events.spawn_extra(yeller, first_at)
		var second := _city.events.spawn_extra(yeller, second_at)
		var completed: Array[int] = []
		director._contact.completed.connect(func(index: int) -> void: completed.append(index))

		# Near the first — inside the director's reach of him, outside `ContactPoint.REACH` of the
		# note — so she has come near him without handing it over.
		var near := director._reach_distance(first) - 4.0
		t.check(near > ContactPoint.REACH, "there is ground near him that is not the handover")
		var player := _rig_player(t, first_at + Vector2(near, 0.0))
		director._process(STEP)
		director._contact._physics_process(STEP)
		t.check(director._rider == first, "coming near the first look-alike moves the contact onto him")
		t.check(completed.is_empty(), "and nothing is handed over from where she stands")

		# Out again, well clear of all three.
		player.global_position = first_at + Vector2(ResistanceDirector.NOTICE_RADIUS, 0.0)
		director._process(STEP)
		director._contact._physics_process(STEP)
		t.check(completed.is_empty(), "walking on from him hands nothing over")

		# And onto the second, whom she hands it to.
		player.global_position = second_at
		director._process(STEP)
		director._contact._physics_process(STEP)
		t.check(completed == [2], "the step completes on the second look-alike, the one she hands it to")
		t.check(director._rider == second, "whose contact it is")
		# He does not leave the instant she hands it over (M205): he keeps shouting, and charging
		# her, for `NOTE_HANDOVER_LINGER_SECONDS` first.
		t.check(not second.is_leaving and not first.is_leaving and not seeded.is_leaving,
				"nobody leaves the instant she hands it over — he keeps shouting first")
		director._process(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS + STEP)
		t.check(second.is_leaving and not first.is_leaving and not seeded.is_leaving,
				"and once he has lingered that long, he is the one who leaves; the one she walked " +
				"past keeps shouting")

		player.free()
		director.free())

## The man shouting's task is not guarded where it waits: activating the yeller perform stands
## no robber anywhere — the chalk mark's own guard is the only one on the street — and no robber is
## sent after her until she hands it over.
func _test_a_task_that_rides_on_a_row_stands_unguarded_until_it_is_handed_over(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_guard: EventInstance = director._guard
		t.check(mark_guard != null, "the chalk mark is still guarded")
		var robbers_before := _robbers_on_the_street()
		director._on_contact_completed(1)
		t.check(director.current_step() != null and director.current_step().index == 2
				and ResistanceDirector.sets_a_trap_on_her(director.current_step()),
				"the yeller perform is active, and it is a task whose trap comes to her")
		t.check(_robbers_on_the_street() == robbers_before,
				"activating it stands no robber at the task (%d before, %d after)"
				% [robbers_before, _robbers_on_the_street()])
		t.check(director._guard == mark_guard, "the only guard is still the mark's own")
		t.check(director._trap == null, "and nobody is sent after her before the handover")
		director.free())

## The van's task is not guarded where it waits either — the same contract as the man shouting's,
## on a one-place task rather than an any-instance one.
func _test_the_van_task_stands_unguarded_until_it_is_handed_over(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(7, _rng(7, "resistance"), 300.0)
		var mark_guard: EventInstance = director._guard
		t.check(mark_guard != null, "day 7's mark is still guarded")
		var robbers_before := _robbers_on_the_street()
		director._on_contact_completed(3)
		t.check(director.current_step() != null and director.current_step().index == 4
				and ResistanceDirector.sets_a_trap_on_her(director.current_step()),
				"the van perform is active, and it is a task whose trap comes to her")
		t.check(_robbers_on_the_street() == robbers_before,
				"activating it stands no guard at the van (%d before, %d after)"
				% [robbers_before, _robbers_on_the_street()])
		t.check(director._guard == mark_guard, "the only guard is still the mark's own")
		t.check(director._trap == null, "and nobody is sent after her before the handover")
		director.free())

## *(PLAYTEST-144, statement 18, its own reading rather than the player's words: "the burnt shell
## and the roadblock go back to their waiting guard as the smallest reading", filed as "open to the
## player".)* Both are guarded exactly where they wait, like a chalk mark, and handing either over
## sends nobody after her.
func _test_the_burnt_shell_and_the_roadblock_keep_a_waiting_guard(t) -> void:
	_build_city(t)
	var saved_scars := GameState.scars.duplicate()
	GameState.scars.clear()
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(8, _rng(8, "resistance"), 300.0)
		var mark_guard: EventInstance = director._guard
		director._on_contact_completed(5)
		var step := director.current_step()
		t.check(step != null and step.index == 6, "the burnt-shell perform is active")
		t.check(not ResistanceDirector.sets_a_trap_on_her(step),
				"the burnt shell's trap does not come to her")
		t.check(director._task_guard != null and is_instance_valid(director._task_guard),
				"it is guarded where it waits, like a mark, with its own fresh guard")
		if mark_guard:
			t.check(director._guard == mark_guard and not mark_guard.is_finished,
					"and the mark's own guard stays untouched, not retired for it")
			t.check(director._task_guard != mark_guard,
					"the perform's own guard is a distinct instance from the mark's")
		director._on_contact_completed(6)
		t.check(director._trap == null, "and handing it over sends nobody after her")
		director.free())
	GameState.scars = saved_scars

	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(13, _rng(13, "resistance"), 300.0)
		var mark_guard: EventInstance = director._guard
		director._on_contact_completed(15)
		var step := director.current_step()
		t.check(step != null and step.index == 16, "the roadblock perform is active")
		t.check(not ResistanceDirector.sets_a_trap_on_her(step),
				"the roadblock's trap does not come to her")
		t.check(director._task_guard != null and is_instance_valid(director._task_guard),
				"it is guarded where it waits, like a mark, with its own fresh guard")
		if mark_guard:
			t.check(director._guard == mark_guard and not mark_guard.is_finished,
					"and the mark's own guard stays untouched, not retired for it")
			t.check(director._task_guard != mark_guard,
					"the perform's own guard is a distinct instance from the mark's")
		director._on_contact_completed(16)
		t.check(director._trap == null, "and handing it over sends nobody after her")
		director.free())

## Every robber or guard standing or running in the test city: the alley robber and the two the
## director can send after her.
func _robbers_on_the_street() -> int:
	var count := 0
	var ids := ["alley_robbery", "robber_giving_chase", "van_guard_giving_chase"]
	for instance in _city.events.instances():
		if instance.def.id in ids and not instance.is_finished:
			count += 1
	return count

## Whether `at` would actually render on screen with the camera on `her` and led toward `at` the
## way `Stroller` leads it when she faces what she is walking toward — the worst-case lead, since a
## start behind her would only pull the camera the other way. Built the same way `_walk_the_trap()`
## drives `DangerEdge` under a synthetic camera, but asking `DangerEdge.is_on_screen()` directly
## rather than the badge's own smoothed approach, since a spawn is a single frame with no earlier
## position to smooth from. This is `ResistanceDirector.set_sight()`'s own production predicate —
## the real screen extent, rotation-aware — not the axis-aligned `VIEW_HALF_EXTENT` box a bare
## `_sight` callable elsewhere in this suite approximates it with.
func _is_really_on_screen(t, her: Vector2, at: Vector2) -> bool:
	var viewport: Viewport = t.get_viewport()
	var saved_canvas := viewport.canvas_transform
	var bearing := at - her
	var lead := Vector2.ZERO
	if bearing.length() > 0.001:
		var dir := bearing.normalized()
		lead = Vector2(dir.x, dir.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	viewport.canvas_transform = Transform2D(0.0, Vector2(2.0, 2.0), 0.0,
			ScreenOrientation.DESIGN_SIZE * 0.5 - (her + lead) * 2.0)
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.size = ScreenOrientation.DESIGN_SIZE
	var on_screen := edge.is_on_screen(at)
	edge.free()
	viewport.canvas_transform = saved_canvas
	return on_screen

## *(PLAYTEST-71: "maybe spawn the robber in pursuing mode offscreen when she interacts with the
## yeller so it runs towards her from offscreen"; "we need a version of the robber that is not
## frozen when spawned".)* Handing the note over sets one `robber_giving_chase` on her:
## `Tuning.TRAP_ARRIVAL_DISTANCE` from her (or the along-her-street `beside_distance()`, on
## whichever seed's geometry leaves no clear run above or below), on legal ground, past the badge
## line, never waiting, and coming at her from the first frame he is stepped, with a clear run at
## her so he actually arrives rather than standing against a wall.
##
## **Swept over `RULE_SEEDS` cities rather than trusted on one**, and checked against the game's
## own real screen test rather than only the derived badge-line arithmetic: this also asks
## `DangerEdge.is_on_screen()`, the exact rotation-aware predicate `ResistanceDirector.set_sight()`
## is wired to in play, whether the spawn point would actually render. Every seed's handover
## replays to the same place.
func _test_the_handover_sets_a_robber_on_her_from_off_screen(t) -> void:
	var seeds: Array[int] = [4242, 90210, 2295276695, 291862120, 314159, 555555]
	for seed_value: int in seeds.slice(0, RULE_SEEDS):
		# An array rather than a `Vector2`, because a lambda captures a local by value and the
		# first attempt's start has to reach the second.
		var starts: Array[Vector2] = []
		# The mark's own alley is recorded as used when it is touched, and a used alley is avoided
		# on the next draw — so each attempt starts from the same record, or the replay is a
		# different day.
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		for attempt in 2:
			_build_city(t, seed_value)
			GameState.completed_resistance_alley_tiles = saved_tiles.duplicate()
			_with_clean_run(func() -> void:
				var director := _director_on_the_yeller_perform(t, seed_value)
				var rider: EventInstance = director._rider
				var her := director.contact_position()
				director.set_sight(func(at: Vector2) -> bool:
					var off := (at - her).abs()
					return off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y)
				var player := _rig_player(t, her)
				director._contact._physics_process(STEP)
				t.check(director._contact.is_done, "seed %d: she hands the note over" % seed_value)
				var robber: EventInstance = director._trap
				t.check(robber != null and robber.def.id == "robber_giving_chase",
						"seed %d: and a robber is sent after her the moment she does" % seed_value)
				if robber:
					var start := robber.global_position
					var beside := ResistanceDirector.beside_distance(robber.def)
					var dist := start.distance_to(her)
					t.check(absf(dist - Tuning.TRAP_ARRIVAL_DISTANCE) <= 0.5 or absf(dist - beside) <= 0.5,
							("seed %d: from TRAP_ARRIVAL_DISTANCE (%.0f) or the beside distance " +
							"(%.0f) away (got %.1f)") % [seed_value, Tuning.TRAP_ARRIVAL_DISTANCE,
							beside, dist])
					t.check(not _is_really_on_screen(t, her, start),
							"seed %d: never actually on screen the frame he spawns" % seed_value)
					t.check(ResistanceDirector.is_past_the_badge_line(start - her, robber.def),
							"seed %d: far enough past the edge of the view for the badge to rise"
							% seed_value)
					t.check(ResistanceDirector.is_legal_ground(_city.map,
							_city.map.world_to_tile(start), director._walled_alleys()),
							"seed %d: on walkable ground nothing refuses" % seed_value)
					t.check(director._a_clear_run(start, her),
							"seed %d: with a straight run at her that stays on walkable ground"
							% seed_value)
					t.check(not robber.is_waiting(),
							"seed %d: never waiting, even before his first frame" % seed_value)
					robber.player_at = her
					robber._process(STEP)
					t.check(start.distance_to(her) - robber.global_position.distance_to(her)
							> robber.def.pursue_speed * STEP * 0.9,
							"seed %d: and coming at her at his own speed from his first frame"
							% seed_value)
					# Standing where she handed it over, she is caught: he arrives, and doing
					# nothing about him still loses.
					var caught := false
					var elapsed := 0.0
					while elapsed < robber.def.telegraph_time + robber.def.duration \
							and not robber.is_finished and not caught:
						robber.player_at = her
						robber._process(STEP)
						elapsed += STEP
						caught = robber.is_lethal_at(her)
					t.check(caught, "seed %d: and reaches her where she stands (%.1fs)"
							% [seed_value, elapsed])
					if not starts.is_empty():
						t.close_to(start.distance_to(starts[0]), 0.0,
								"seed %d: the same handover sends him from the same place"
								% seed_value, 0.01)
					starts.append(start)
				# He does not leave the instant she hands it over (M205): he keeps shouting, and
				# charging her, for `NOTE_HANDOVER_LINGER_SECONDS` first — unaffected by the
				# robber's own clock, which is all this loop has advanced.
				t.check(not rider.is_leaving,
						"seed %d: the man she handed it to keeps shouting, not leaving instantly"
						% seed_value)
				player.free()
				director.free())
		GameState.completed_resistance_alley_tiles = saved_tiles

## Mirrors `_test_the_handover_sets_a_robber_on_her_from_off_screen` for the van: handing the
## package over sets one `van_guard_giving_chase` on her, on the same terms as the robber — same
## distance, same badge line, same off-screen legal ground, same first-frame pursuit. The van
## itself is a one-place task's own rider and never leaves when the package is picked up —
## `_on_contact_completed()` only sends the man shouting's own rider away by name.
func _test_the_van_handover_sets_a_guard_on_her_from_off_screen(t) -> void:
	var starts: Array[Vector2] = []
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	for attempt in 2:
		_build_city(t)
		GameState.completed_resistance_alley_tiles = saved_tiles.duplicate()
		_with_clean_run(func() -> void:
			var director := _director_on_the_van_perform(t)
			var her := director.contact_position()
			director.set_sight(func(at: Vector2) -> bool:
				var off := (at - her).abs()
				return off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y)
			var player := _rig_player(t, her)
			director._contact._physics_process(STEP)
			t.check(director._contact.is_done, "she hands the package over")
			var guard: EventInstance = director._trap
			t.check(guard != null and guard.def.id == "van_guard_giving_chase",
					"and a guard is sent after her the moment she does")
			if guard:
				var start := guard.global_position
				# Above or below her at `Tuning.TRAP_ARRIVAL_DISTANCE` by preference; on a street
				# that runs sideways with no clear run above or below (about a quarter of
				# handovers for this row, `_draw_arrival_position()`'s own doc; measured by
				# `tests/probes/m137_trap_arrival.gd`), he comes along her own street instead, at
				# `beside_distance()` — either is a legal draw, so this checks for whichever the
				# real city actually gave him rather than assuming the common case.
				var dist := start.distance_to(her)
				var beside := ResistanceDirector.beside_distance(guard.def)
				t.check(absf(dist - Tuning.TRAP_ARRIVAL_DISTANCE) <= 0.5 or absf(dist - beside) <= 0.5,
						"from TRAP_ARRIVAL_DISTANCE (%.0f) or the beside distance (%.0f) away (got %.1f)"
						% [Tuning.TRAP_ARRIVAL_DISTANCE, beside, dist])
				t.check(not _is_really_on_screen(t, her, start),
						"never actually on screen the frame he spawns")
				t.check(ResistanceDirector.is_past_the_badge_line(start - her, guard.def),
						"which is far enough past the edge of the view for the badge to rise")
				t.check(ResistanceDirector.is_legal_ground(_city.map,
						_city.map.world_to_tile(start), director._walled_alleys()),
						"on walkable ground nothing refuses")
				t.check(director._a_clear_run(start, her),
						"with a straight run at her that stays on walkable ground")
				t.check(not guard.is_waiting(), "never waiting, even before his first frame")
				guard.player_at = her
				guard._process(STEP)
				t.check(start.distance_to(her) - guard.global_position.distance_to(her)
						> guard.def.pursue_speed * STEP * 0.9,
						"and coming at her at his own speed from his first frame")
				# Standing where she handed it over, she is caught: he arrives, and doing
				# nothing about him still loses.
				var caught := false
				var elapsed := 0.0
				while elapsed < guard.def.telegraph_time + guard.def.duration \
						and not guard.is_finished and not caught:
					guard.player_at = her
					guard._process(STEP)
					elapsed += STEP
					caught = guard.is_lethal_at(her)
				t.check(caught, "and reaches her where she stands (%.1fs)" % elapsed)
				if not starts.is_empty():
					t.close_to(start.distance_to(starts[0]), 0.0,
							"the same handover sends him from the same place", 0.01)
				starts.append(start)
			player.free()
			director.free())
	GameState.completed_resistance_alley_tiles = saved_tiles

## **He is announced before he can end her day, the warning is short, and walking away still
## loses.** The distance's own derivation as relationships first, then a bare robber walked from
## each start the director draws — `Tuning.TRAP_ARRIVAL_DISTANCE` straight above and below her and
## at the edge of `ResistanceDirector.arrival_cone()`, and the along-her-street start beside her —
## with the real `DangerEdge` measuring him under a camera at the game's own zoom 2 over the
## 1280x720 box, led toward him by the camera's own look-ahead, the worst case for the badge.
## Walked, not asserted from the numbers:
##
## - **standing where she handed it over**, the badge is up before he is on screen, he lunges no
##   sooner than `Tuning.PURSUIT_MIN_NOTICE` after he appears, and she is caught;
## - **walking into him**, the badge still comes first and his lunge leaves her the whole stand-off
##   (`Tuning.pursuit_standoff()`), and turning to run `Tuning.PURSUIT_REACTION` after the badge
##   rises gets her away;
## - **walking away** loses from above or below, which is what his chase length is for — and from
##   beside her it outlasts him, the cost of that start, held here so the director's doc stays true;
## - **running** the moment the badge shows ends it.
func _test_the_robber_after_her_is_announced_before_he_can_catch_her(t) -> void:
	_assert_a_trap_row_is_announced_before_it_can_catch_her(t, "robber_giving_chase")

## The same contract for the van's own guard: walks the guard's own row and asserts the same
## relationships rather than assuming the robber's numbers carry over unchecked — see
## `_van_guard_giving_chase()`'s own doc for why they do, and this is what checks it.
func _test_the_van_guard_after_her_is_announced_before_he_can_catch_her(t) -> void:
	_assert_a_trap_row_is_announced_before_it_can_catch_her(t, "van_guard_giving_chase")

## Shared between the man shouting's row and the van's: each of this suite's two callers passes
## its own catalogue id, since the contract this checks is the same row-independent relationship
## for both — which is what caught `Tuning.TRAP_ARRIVAL_DISTANCE` two pixels short for the van's
## own tighter catch before this constant moved to cover both; see that constant's own doc and
## `_van_guard_giving_chase()`'s.
func _assert_a_trap_row_is_announced_before_it_can_catch_her(t, id: String) -> void:
	var def := EventCatalogue.by_id(id)
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.lethal_reach())
	var walker_closes := def.pursue_speed - Tuning.WALK_SPEED
	t.check((Tuning.TRAP_ARRIVAL_DISTANCE - def.lethal_reach()) / walker_closes
			<= def.telegraph_time + def.duration - 0.5,
			"a walker who leaves the moment he appears is caught with half a second of chase to spare")
	t.check(Tuning.TRAP_ARRIVAL_DISTANCE
			>= standoff + def.pursue_speed * Tuning.PURSUIT_MIN_NOTICE,
			"standing still, he reaches his stand-off no sooner than the least notice")
	t.check(def.telegraph_time < Tuning.PURSUIT_MIN_NOTICE + 1.0,
			"his notice is the least one owed plus a small margin (%.1fs)" % def.telegraph_time)
	var cone := ResistanceDirector.arrival_cone(def)
	t.check(cone > deg_to_rad(10.0),
			"there is a cone above and below her to start him in (%.1f degrees)" % rad_to_deg(cone))
	t.check(not ResistanceDirector.is_past_the_badge_line(
			Vector2.RIGHT * Tuning.TRAP_ARRIVAL_DISTANCE, def),
			"and none beside her at that distance, where the view is wide enough to show him")
	var edge_of_cone := cone - 0.001
	var starts: Array[Vector2] = [Vector2.DOWN * Tuning.TRAP_ARRIVAL_DISTANCE,
			Vector2.UP * Tuning.TRAP_ARRIVAL_DISTANCE,
			Vector2.DOWN.rotated(edge_of_cone) * Tuning.TRAP_ARRIVAL_DISTANCE,
			Vector2.UP.rotated(-edge_of_cone) * Tuning.TRAP_ARRIVAL_DISTANCE,
			Vector2.RIGHT * ResistanceDirector.beside_distance(def)]
	for start in starts:
		var beside := is_zero_approx(start.y)
		var stood := _walk_the_trap(t, def, start, 0.0)
		t.check(stood["announced_at"] < stood["on_screen_at"],
				"from %v: the badge is up (%.2fs) before he is on screen (%.2fs)"
				% [start, stood["announced_at"], stood["on_screen_at"]])
		t.check(stood["lunged_at"] >= Tuning.PURSUIT_MIN_NOTICE,
				"from %v: standing still, he lunges %.2fs after he appears, no sooner than %.1fs"
				% [start, stood["lunged_at"], Tuning.PURSUIT_MIN_NOTICE])
		t.check(stood["caught_at"] < INF,
				"from %v: and standing still is caught (%.2fs)" % [start, stood["caught_at"]])

		var into := _walk_the_trap(t, def, start, Tuning.WALK_SPEED)
		t.check(into["caught_at"] < INF and into["announced_at"] < into["caught_at"],
				"from %v: walking into him, the badge still comes first" % start)
		t.close_to(into["at_the_lunge"], standoff,
				"from %v: and his lunge leaves her the whole stand-off" % start, 8.0)
		var turned := _walk_the_trap(t, def, start, Tuning.WALK_SPEED, Tuning.PURSUIT_REACTION)
		t.check(turned["caught_at"] == INF and turned["gave_up"],
				"from %v: walking into him and turning to run %.1fs after the badge gets away"
				% [start, Tuning.PURSUIT_REACTION])

		var away := _walk_the_trap(t, def, start, -Tuning.WALK_SPEED)
		if beside:
			t.check(away["caught_at"] == INF,
					"from %v, beside her: walking directly away outlasts him, as documented" % start)
		else:
			t.check(away["caught_at"] < INF,
					"from %v: walking away from him is not enough (%s)"
					% [start, "caught at %.2fs" % away["caught_at"] if away["caught_at"] < INF
					else "he gave up first"])

		var ran := _walk_the_trap(t, def, start, -Tuning.RUN_SPEED)
		t.check(ran["caught_at"] == INF and ran["gave_up"],
				"from %v: running from him ends it" % start)

## A duck-typed event source for `DangerEdge.setup()`: the one question it asks of one.
class _Robbers extends Node:
	var live: Array[EventInstance] = []

	func instances() -> Array[EventInstance]:
		return live

## Walks her at `speed` along the line to `start` — positive toward him, negative away — against a
## bare instance of `def` (`robber_giving_chase` or `van_guard_giving_chase`) started at `start`
## from her, with `DangerEdge` measuring under a camera on her, led toward him the way `Stroller`
## leads it when she faces him.
## A walk is under way when he appears (the handover does not stop her); a run is started only once
## the badge is up, the moment a player could first answer it, and gets up to speed at
## `Tuning.ACCELERATION`. `turn_to_run_after`, if given, reverses her into a run away from him that
## many seconds after the badge rises.
func _walk_the_trap(t, def: EventDef, start: Vector2, speed: float,
		turn_to_run_after := INF) -> Dictionary:
	var bearing := start.normalized()
	var viewport: Viewport = t.get_viewport()
	var saved_canvas := viewport.canvas_transform
	var her_node := Node2D.new()
	t.add_child(her_node)
	var source := _Robbers.new()
	var robber := EventInstance.new()
	robber.setup(def, start)
	source.live.append(robber)
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.size = ScreenOrientation.DESIGN_SIZE
	edge.setup(source, her_node)
	var lead := Vector2(bearing.x, bearing.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	var result := {"announced_at": INF, "on_screen_at": INF, "caught_at": INF,
			"at_the_lunge": INF, "lunged_at": INF, "gave_up": false}
	var her := Vector2.ZERO
	var velocity := speed if absf(speed) <= Tuning.WALK_SPEED else 0.0
	var elapsed := 0.0
	var was_telegraphing := true
	while elapsed < def.telegraph_time + def.duration + 1.0:
		var announced: bool = result["announced_at"] < INF
		var wanted := speed if announced or absf(speed) <= Tuning.WALK_SPEED else 0.0
		if announced and elapsed - float(result["announced_at"]) >= turn_to_run_after:
			wanted = -Tuning.RUN_SPEED
		velocity = move_toward(velocity, wanted, Tuning.ACCELERATION * STEP)
		her += bearing * velocity * STEP
		her_node.global_position = her
		robber.player_at = her
		robber.player_running = absf(velocity) > Tuning.WALK_SPEED
		robber._process(STEP)
		elapsed += STEP
		viewport.canvas_transform = Transform2D(0.0, Vector2(2.0, 2.0), 0.0,
				ScreenOrientation.DESIGN_SIZE * 0.5 - (her + lead) * 2.0)
		edge._process(STEP)
		if result["announced_at"] == INF and not edge._coming.is_empty():
			result["announced_at"] = elapsed
		var offset := robber.global_position - her
		var in_view := offset - lead
		if result["on_screen_at"] == INF and absf(in_view.x) <= Tuning.VIEW_HALF_EXTENT.x \
				and absf(in_view.y) <= Tuning.VIEW_HALF_EXTENT.y:
			result["on_screen_at"] = elapsed
		if was_telegraphing and not robber.is_telegraphing():
			result["at_the_lunge"] = offset.length()
			result["lunged_at"] = elapsed
			was_telegraphing = false
		if robber.is_lethal_at(her):
			result["caught_at"] = elapsed
			break
		if robber.gave_up or robber.is_finished or robber.is_leaving:
			result["gave_up"] = robber.gave_up
			break
	viewport.canvas_transform = saved_canvas
	edge.free()
	source.free()
	robber.free()
	her_node.free()
	return result

## Spawned only by the director: no day of the run, at any heat, offers the row to the scheduler's
## roll, its stream or its budget — `EventCatalogue.available_on()` is the pool all three draw from —
## and a day the scheduler actually plans, on the first day a task can be handed over, carries none.
func _test_the_robber_after_her_is_never_the_schedulers(t) -> void:
	_assert_a_trap_row_is_never_the_schedulers(t, "robber_giving_chase")

## The same guarantee for the van's own guard: a second `SCRIPTED`/`scripted_day 0` row director-
## spawned at the handover, so it needs the same "the roll, the stream and the budget never reach
## it" check the robber's own row gets, rather than assuming a second row of the same shape is
## automatically exempt.
func _test_the_van_guard_after_her_is_never_the_schedulers(t) -> void:
	_assert_a_trap_row_is_never_the_schedulers(t, "van_guard_giving_chase")

func _assert_a_trap_row_is_never_the_schedulers(t, id: String) -> void:
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for heat in EventCatalogue.heat_levels():
			for def in EventCatalogue.available_on(day, heat):
				t.check(def.id != id,
						"day %d at heat %d does not offer '%s'" % [day, heat, id])
	var map := CityGenerator.generate(SEED)
	var consumed: Array[String] = []
	var plans := EventScheduler.build_day(ResistanceDirector.TRAP_FIRST_DAY,
			_rng(ResistanceDirector.TRAP_FIRST_DAY, "events"), map, consumed)
	t.check(not plans.is_empty(), "the day planned something to look through (%d)" % plans.size())
	for plan in plans:
		t.check(plan.def.id != id,
				"day %d's own plan places no '%s'" % [ResistanceDirector.TRAP_FIRST_DAY, id])

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
## Split into two moments (M205, "he keeps shouting for a bit"): the instant the note changes
## hands, and once `ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS` has actually elapsed. He does
## not leave the first moment — he stays and keeps shouting, still charging her, until the second.
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

		t.check(not rider.is_leaving,
				"the one she reached keeps shouting the instant the note is handed over")
		t.check(rider.contribution_at(rider.global_position) > 0.0,
				"and still charges her, since he has not started leaving yet")
		t.check(not decoy.is_leaving and decoy.contribution_at(decoy.global_position) > 0.0,
				"a look-alike she never reached is left exactly alone, still shouting")

		director._process(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS - STEP)
		t.check(not rider.is_leaving,
				"and still hasn't, a frame short of the full linger")

		director._process(2.0 * STEP)
		t.check(rider.is_leaving,
				"and stops shouting and leaves once he has lingered that long")
		t.close_to(rider.contribution_at(rider.global_position), 0.0,
				"and contributes nothing to the meter the same frame", 0.001)
		t.check(not decoy.is_leaving, "a look-alike she never reached is still left exactly alone")
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
		t.check(rider != null and not rider.is_leaving,
				"completing it keeps him shouting first, not sent away yet")
		attempt._process(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS + STEP)
		t.check(rider != null and rider.is_leaving,
				"and sends him away once he has lingered that long")
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

## The sabotage is what puts the city's power out, and the masts go with it. Not at the door she
## touched: the hand-over takes minutes, so every mast is still speaking until the blackout, which
## comes once she is far enough from the station (`Blackout`) — and then the field each one has been
## holding near itself since day 5 goes with it, `EventManager.silence_all_masts()`: a mast has an
## edge like any other row's, so what stops is everywhere a mast actually stands, not the whole map.
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
		# The real day order, `City.start_day()` first: it is what holds today's region plan, and
		# without it the director cannot tell a region door's own bodies from the wall's
		# (`ResistanceDirector._ensure_reachability()`), counts every door shut, and finds the
		# station's front door — and everything else outside the home's region — out of reach.
		var state := CityState.new()
		state.begin_day(_city.map.block_plans, Tuning.RUN_LENGTH_DAYS)
		_city.start_day(state, Tuning.RUN_LENGTH_DAYS, _rng(Tuning.RUN_LENGTH_DAYS, "closures"))
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
		var finale := director.current_step()
		t.check(finale != null, "the last night has a contact")
		t.check(finale != null and finale.needs_goal, "and it is the finale's own")
		var door := _city.map.power_station_door_position()
		t.check(director.contact_position().distance_to(door) <= Tuning.TILE_SIZE,
				"the contact stands on the pavement in front of the power station's front door")
		t.check(director.red_arrow_target() == director.contact_position(),
				"and the red arrow points at it")
		director._on_contact_completed(finale.index if finale else -1)

		t.check(GameState.sabotage_done, "completing it does the sabotage")
		t.check(quiet.is_empty() and not mast.silenced,
				"and the masts are still speaking at the door: they stop with the power")
		var lot := _city.map.tile_rect_to_world(CityMap.blocks_tile_rect(_city.map.power_station))
		_city.blackout.update(Vector2(lot.get_center().x,
				lot.end.y + Tuning.BLACKOUT_DISTANCE + 8.0))
		t.check(quiet.size() == 1, "far enough away, the city goes quiet, once")
		t.check(mast.silenced, "the mast is marked silenced")
		t.close_to(mast.contribution_at(nearby), 0.0,
				"the mast contributes nothing afterwards")
		GameState.sabotage_done = false
		_city.blackout.update(Vector2(lot.get_center().x, lot.end.y))

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
		var doorstep := _city.map.doorstep_world_position()
		# Within `EVENT_STREAM_RADIUS` (900px) of the focus `_city.events.start_day()` is given
		# below — `EventManager.stream_around()` only materialises a live instance for a planned
		# event that close, scars included, so a scar recorded further out would never become the
		# live instance `_find_scar_instance()` is looking for and this test would be exercising
		# the no-recorded-scar fallback by accident. A flat "the middle sidewalk tile" picked
		# whichever one that landed to be past 900px from home on a station-reshaped city, which
		# is what turned this into the fallback path rather than the recorded-scar one it names.
		var near_sidewalks: Array[Vector2i] = []
		for tile in _city.map.tiles_of_type(GameEnums.TileType.SIDEWALK):
			if _city.map.tile_to_world(tile).distance_to(doorstep) < Tuning.EVENT_STREAM_RADIUS:
				near_sidewalks.append(tile)
		t.check(not near_sidewalks.is_empty(), "home has sidewalks within streaming range")
		var scar_at := _city.map.tile_to_world(near_sidewalks[near_sidewalks.size() / 2])
		GameState.scars = [{"id": "burnt_shell", "position": scar_at, "since_day": 3}]
		# `_find_scar_instance()` reads live instances off `_city.events`, which only exist once
		# the day's own events have actually been built — `_place_scars()` is what turns the
		# recorded scar into a live `burnt_shell` instance at `scar_at`.
		_city.events.start_day(8, _rng(8, "events"), [], doorstep)

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

## M221, "a failed day leaves no chalk mark behind" — reproduced by touching a mark whose very
## next step is itself a guarded task (day 9's door: `_begin_step()` runs a second time in the
## same `_on_contact_completed()` call, and the guarded-perform shape is shared by every task day
## but the man shouting's and the van's). The player, asked whether a read mark should vanish at
## once or stay: "Stays crossed, until the day ends" — so the mark's own touched `ContactPoint`
## and its guard both stay standing through the rest of the attempt (item 3 and item 4 of the
## review of #414), and both are let go — the contact freed outright, the guard's own tracking
## reference dropped — the moment the day is retried or a new one starts, which is what stops
## either from piling up.
func _test_a_completed_marks_own_contact_and_guard_survive_to_the_day_end(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var closure_state := CityState.new()
		closure_state.begin_day(_city.map.block_plans, 9)
		_city.start_day(closure_state, 9, _rng(9, "closures"))
		_city.events.start_day(9, _rng(9, "events"), [], _city.map.doorstep_world_position())

		var director := _director(t)
		director.start_day(9, _rng(9, "resistance"), 300.0)
		var mark_contact: ContactPoint = director._contact
		var mark_guard: EventInstance = director._guard
		t.check(mark_contact != null, "day 9's mark has its own contact before it is touched")

		# The same signal a real touch fires (`ContactPoint._complete()`, already connected to
		# `_on_contact_completed()` by `_begin_step()`), so `is_done` is set the way play sets it
		# rather than skipped by calling the handler directly.
		mark_contact._complete()
		t.check(director.current_step() != null and director.current_step().index == 8,
				"touching it activates the door perform the same day")

		t.check(not mark_contact.is_queued_for_deletion() and is_instance_valid(mark_contact),
				"the mark's own touched ContactPoint stays standing, crossed through")
		t.check(mark_contact.is_done, "showing chalk_mark_touched.svg")
		t.check(director._read_mark == mark_contact, "tracked as the day's own read mark")
		t.check(director._contact != mark_contact, "the perform's own contact is a fresh one")

		if mark_guard:
			t.check(not mark_guard.is_finished and is_instance_valid(mark_guard),
					"the mark's own guard stays too, not retired for the door's own guard")
			t.check(director._guard == mark_guard, "still tracked as the mark's own")
			t.check(director._task_guard != mark_guard,
					"the door's own guard, if any, is a fresh instance rather than the mark's own")

		# The door's task expiring (its deadline, or its rider gone) ends the task, not the day:
		# the read mark stays standing.
		director._expire("expired for the test")
		t.check(is_instance_valid(mark_contact) and not mark_contact.is_queued_for_deletion(),
				"the read mark still stands once the task it unlocked has expired")

		# The day is retried (the same shape a new day takes): the read mark is freed outright,
		# and the old guard's own EventInstance — freed for real by `EventManager.clear()` in the
		# real game, which this bare director rig has none of to ask — is at least no longer
		# tracked as today's.
		director.start_day(9, _rng(9, "resistance"), 300.0)
		t.check(mark_contact.is_queued_for_deletion(), "the read mark is freed at the day's end")
		if mark_guard:
			t.check(director._guard != mark_guard, "and the old guard is no longer tracked as today's")

		director.free())

## velvet-plover, "a mark she has read is gone from every alley" — *"the mark now shows in all
## alleys -- once it is checked it shouldn't appear anywhere else."* The player has since decided
## a read mark stays, crossed through, until the day ends rather than vanish at once, so this asks
## the claim that still answers the report: at most one mark's own touched picture is ever
## standing anywhere, across several ordinary days in a row, none of them failed or retried.
func _test_a_read_mark_does_not_pile_up_across_several_ordinary_days(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		# Day 6's mark is index 1, day 7's is 3, day 8's is 5 (`_test_step_selection`'s own
		# numbering) — each is a pickup, activated and then completed in turn.
		for entry in [[6, 1], [7, 3], [8, 5]]:
			var day: int = entry[0]
			var mark_index: int = entry[1]
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var before := _live_chalk_marks()
			t.check(before == 1, "day %d: exactly one mark stands before it is read (%d)"
					% [day, before])
			director._on_contact_completed(mark_index)
			var after := _live_chalk_marks()
			t.check(after == 1,
					"day %d: reading it leaves it standing, crossed through, alone (%d)"
					% [day, after])
		director.free())

## Every live, not-yet-freed `ContactPoint` under `_city` whose own step is a pickup — the chalk
## mark's own shape, since a perform's contact rides invisibly on its rider and draws nothing
## (`ContactPoint._draw()`) and so is never "a mark shown in an alley" in the player's sense.
func _live_chalk_marks() -> int:
	var count := 0
	for child in _city.find_children("*", "", true, false):
		if child is ContactPoint and child.step != null and child.step.is_pickup \
				and not child.is_queued_for_deletion():
			count += 1
	return count

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
		var state := CityState.new()
		state.begin_day(_city.map.block_plans, 12)
		_city.map.repaint(state)
		t.check(not _city.map.playgrounds.is_empty(),
				"the test city has at least one open playground, or this test checks nothing")

		var director := _director(t)
		director.start_day(12, _rng(12, "resistance"), 300.0)
		director._on_contact_completed(_perform_on(12).index - 1)
		t.check(director.current_step() != null
				and director.current_step().index == _perform_on(12).index,
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
		var park := CityGenerator.swing_park(_city.map)
		var layout: BlockLayout = _city.map.block_layouts.get(park)
		t.check(layout != null and _city.map.world_to_tile(_city.map.swing_position(
				layout.playground)) == _city.map.world_to_tile(at),
				"and it is the park the city chose for day 12")

		director.free())

## **Day 12's park is forced open whatever its state** (PLAYTEST-119): every city has one park
## chosen for the swing, whose arc ends requisitioned; on day 12 it is a park — calm, with its
## playground, the only swing the task may go to — even when its arc took it days before, and on
## the days either side it is whatever its arc says. Once she has reached the swing it is taken,
## and it stays taken.
func _test_day_twelves_park_is_forced_open_whatever_its_state(t) -> void:
	var day := ResistanceSteps.swing_day()
	t.check(day == 12, "the swing is day 12's task")
	var forced := 0
	for seed_value in [SEED, 181000, 283947, 299785, 307704]:
		var map := CityGenerator.generate(seed_value)
		var park := CityGenerator.swing_park(map)
		t.check(park.x >= 0, "seed %d: the city chose a park for the swing" % seed_value)
		if park.x < 0:
			continue
		var plan: BlockPlan = map.block_plans[park]
		t.check(plan.starting_purpose() == GameEnums.BlockPurpose.PARK
				and plan.steps[plan.steps.size() - 1].purpose == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: a park whose arc ends requisitioned" % seed_value)
		var state := CityState.new()
		state.begin_day(map.block_plans, day - 1)
		var before := state.purpose_of(map.block_plans, park)
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		if before != GameEnums.BlockPurpose.PARK:
			forced += 1
		t.check(state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.PARK
				and park in map.calm_blocks,
				"seed %d: on day 12 it is an open park (it was %s the day before)"
				% [seed_value, GameEnums.BlockPurpose.keys()[before]])
		var step := _perform_on(day)
		var pool := ResistanceSteps.target_candidates(step, map, null)
		var layout: BlockLayout = map.block_layouts[park]
		t.check(pool.size() == 1 and pool[0] == map.world_to_tile(map.swing_position(
				layout.playground)), "seed %d: its swing is the task's only place" % seed_value)
		t.check(state.take(map.block_plans, park, day)
				and state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: reaching the swing takes it" % seed_value)
		state.begin_day(map.block_plans, day + 1)
		t.check(state.purpose_of(map.block_plans, park) == GameEnums.BlockPurpose.REQUISITIONED,
				"seed %d: and it stays taken" % seed_value)
		var untaken := CityState.new()
		untaken.begin_day(map.block_plans, day + 1)
		t.check(not untaken.is_forced_open(park), "seed %d: open only on its own day" % seed_value)
	t.check(forced > 0, "some city's park was requisitioned before day 12 and forced open (%d)"
			% forced)

## Day 11: touching the mark sends her, by the red arrow, to the foot of one live mast; reaching it
## silences that mast now and on every later day, through the scar it leaves — planned through the
## real day order, since the masts are the day's own plans.
func _test_the_mast_task_silences_one_mast_for_the_rest_of_the_run(t) -> void:
	_build_city(t)
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	GameState.scars.clear()
	GameState.day = 11
	_with_clean_run(func() -> void:
		var day := 11
		var state := CityState.new()
		state.begin_day(_city.map.block_plans, day)
		_city.start_day(state, day, _rng(day, "closures"))
		_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
		var director := _director(t)
		director.start_day(day, _rng(day, "resistance"), 300.0)
		var mark := director.current_step()
		t.check(mark != null and mark.is_pickup, "day 11 offers a mark")
		director._on_contact_completed(mark.index if mark else -1)
		var task := director.current_step()
		t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.MAST,
				"touching it sends her to a mast")
		var mast_id := director._mast_id
		var foot := _city.events.mast_foot(mast_id)
		t.check(mast_id != "" and foot != Vector2.INF
				and director.contact_position().distance_to(foot) <= Tuning.TILE_SIZE + 0.5,
				"the contact stands beside the foot of a live mast")
		t.check(director.red_arrow_target() == director.contact_position(),
				"and the red arrow points at it")

		director._on_contact_completed(task.index if task else -1)
		var silenced_today := true
		for plan in _city.events.plans():
			if plan.mast_id == mast_id and not plan.silenced:
				silenced_today = false
		t.check(silenced_today, "reaching it silences that mast today")
		var others_live := false
		for plan in _city.events.plans():
			if plan.mast_id != "" and plan.mast_id != mast_id and not plan.silenced:
				others_live = true
		t.check(others_live, "and only that mast")

		# The next morning, planned from the run's own scars.
		var tomorrow := EventScheduler._place_masts(day + 1, _city.map, 0,
				PackedVector2Array(), GameState.scars)
		var quiet_tomorrow := false
		var live_tomorrow := false
		for plan in tomorrow:
			if plan.mast_id == mast_id:
				quiet_tomorrow = plan.silenced
			elif not plan.silenced:
				live_tomorrow = true
		t.check(quiet_tomorrow, "it is still silenced the next day")
		t.check(live_tomorrow, "while the others speak")
		director.free())
	GameState.scars = saved_scars
	GameState.day = saved_day

## `_weighted_mast_index()` is the draw `_place_at_a_mast()` makes among the masts already found
## reachable, so this reaches the weighting rule directly, over two tiles at fixed, known
## distances from her, rather than through a live day 11 — whose own reachable masts a small test
## city can offer as few as one of (`docs/DECISIONS.md`, M181, day 11's mast in the map's corner),
## too few to compare a near draw against a far one. No `_city` is needed for the draw itself, the
## same bare-map rig `_test_the_guard_never_lands_inside_a_building()` uses.
##
## Two tiles 2 and 10 tiles from her (64px, 320px): weight is `1/d^2`, so the near tile outweighs
## the far one 25 to 1, drawn clearly more often over many rolls and still, sometimes, not drawn.
func _test_the_mast_task_favors_the_near_mast(t) -> void:
	var map := CityGenerator.generate(SEED)
	var director := ResistanceDirector.new()
	t.add_child(director)
	director.setup(null, map)
	var doorstep_tile := map.world_to_tile(map.doorstep_world_position())
	var near_tile := doorstep_tile + Vector2i(2, 0)
	var far_tile := doorstep_tile + Vector2i(10, 0)
	var beside: Array[Vector2i] = [near_tile, far_tile]
	var player := _rig_player(t, map.tile_to_world(doorstep_tile))

	var draws := 300
	var near_drawn := 0
	var far_drawn := 0
	for i in draws:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mast weight test %d" % i)
		var index := director._weighted_mast_index(beside, rng)
		if index == 0:
			near_drawn += 1
		elif index == 1:
			far_drawn += 1
	t.check(near_drawn > far_drawn * 3,
			("the 2-tile mast is drawn clearly more often than the 10-tile one (%d vs %d of %d " +
			"draws)") % [near_drawn, far_drawn, draws])
	t.check(far_drawn > 0, "and the 10-tile mast can still be drawn (%d of %d draws)"
			% [far_drawn, draws])

	# The same draw with nobody in the tree falls back to the doorstep, exactly where she is
	# standing above — so it favors the near tile exactly as strongly.
	player.free()
	var fallback_near := 0
	var fallback_far := 0
	for i in draws:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mast weight fallback test %d" % i)
		var index := director._weighted_mast_index(beside, rng)
		if index == 0:
			fallback_near += 1
		elif index == 1:
			fallback_far += 1
	t.check(fallback_near > fallback_far * 3,
			("with no player in the tree, the doorstep fallback favors the near tile just as " +
			"clearly (%d vs %d of %d draws)") % [fallback_near, fallback_far, draws])

	director.free()

## On the mornings before day 10 the neighbor walks out of her building beside her and off along
## her street, away from her, with nothing pointing at them; from day 10 on there is no morning
## figure — on day 10 they are out in the city, and after it they are gone.
func _test_the_neighbor_leaves_for_work_until_the_raid(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var door := _city.map.doorstep_world_position()
		for day in [1, 5, ResistanceHappenings.NEIGHBOR_DAY - 1]:
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var neighbor := director._happenings.morning_neighbor
			t.check(neighbor != null and neighbor.def.id == "neighbor",
					"day %d: the neighbor leaves her building in the morning" % day)
			if neighbor:
				t.check(neighbor.global_position.distance_to(door) < 2.0 * Tuning.TILE_SIZE,
						"day %d: out of her own door, beside her" % day)
				t.check(neighbor.path.size() >= 2 and neighbor.path[neighbor.path.size() - 1]
						.distance_to(door) > 4.0 * Tuning.TILE_SIZE,
						"day %d: and walking off along her street" % day)
				t.check(director.red_arrow_target() == Vector2.INF,
						"day %d: and nothing points at them" % day)
				_city.events.retire(neighbor)
			director.free()
		for day in [ResistanceHappenings.NEIGHBOR_DAY, ResistanceHappenings.NEIGHBOR_DAY + 1, 13]:
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			t.check(director._happenings.morning_neighbor == null,
					"day %d: no neighbor leaves for work" % day)
			director.free())

## A day-10 director with the mark touched: the neighbor out in the city, walking home. Planned
## through the real day order, since the walk is stated over the day's own closures and bodies.
func _director_on_the_neighbor(t) -> ResistanceDirector:
	var day := ResistanceHappenings.NEIGHBOR_DAY
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var mark := director.current_step()
	t.check(mark != null and mark.is_pickup, "day 10 offers a mark")
	director._on_contact_completed(mark.index if mark else -1)
	return director

## Day 10: the red arrow points at the neighbor, out in the city and walking home along a real walk
## that ends at her doorstep, about `Tuning.NEIGHBOR_WALK_HOME_SECONDS` of their walk away. Reached
## first, the neighbor runs and the task counts; reaching the door first, they are taken — the task
## is failed, and from the next day the wanted notice crosses their face out.
func _test_day_ten_sends_her_to_the_neighbor_walking_home(t) -> void:
	_build_city(t)
	var saved_day := GameState.day
	_with_clean_run(func() -> void:
		var director := _director_on_the_neighbor(t)
		var task := director.current_step()
		t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.NEIGHBOR,
				"touching it sends her to the neighbor")
		var neighbor := director._rider
		t.check(neighbor != null and neighbor.def.id == "neighbor" and neighbor.def.mobile,
				"who is out in the city, walking")
		t.check(neighbor != null and neighbor.def.shape != null,
				"with the row's own shape, which a copy has to carry by hand")
		if neighbor:
			var door := _city.map.doorstep_world_position()
			t.check(neighbor.path[neighbor.path.size() - 1].distance_to(door) < 1.0,
					"home, to her own door")
			var length := 0.0
			for i in range(1, neighbor.path.size()):
				length += neighbor.path[i - 1].distance_to(neighbor.path[i])
			var seconds := length / neighbor.def.speed
			t.check(absf(seconds - Tuning.NEIGHBOR_WALK_HOME_SECONDS)
					<= (ResistanceDirector.NEIGHBOR_WALK_BAND_TILES + 2) * Tuning.TILE_SIZE
					/ neighbor.def.speed,
					"a walk of about %.0fs (%.0fs)" % [Tuning.NEIGHBOR_WALK_HOME_SECONDS, seconds])
			t.check(director.red_arrow_target() == director.contact_position(),
					"and the red arrow points at them")
		director._on_contact_completed(task.index if task else -1)
		t.check(neighbor != null and neighbor.is_leaving, "warned, the neighbor runs")
		t.check(task != null and task.index in GameState.completed_resistance_steps,
				"and the task counts")
		GameState.day = ResistanceHappenings.NEIGHBOR_DAY + 1
		t.check(not GameState.neighbor_was_taken(), "a warned neighbor is not taken")
		GameState.day = ResistanceHappenings.NEIGHBOR_DAY
		director.free()

		GameState.completed_resistance_steps = []
		var late := _director_on_the_neighbor(t)
		var walker := late._rider
		t.check(walker != null, "the neighbor is walking home again on the retry")
		if walker:
			walker.is_parked = true
		late._process(STEP)
		var warning := ResistanceSteps.warning_step()
		t.check(warning.index in GameState.failed_resistance_steps,
				"reaching the door first, the neighbor is taken and the task is lost")
		t.check(late.current_step() == null and late.red_arrow_target() == Vector2.INF,
				"and nothing points anywhere any more")
		GameState.day = ResistanceHappenings.NEIGHBOR_DAY + 1
		t.check(GameState.neighbor_was_taken(), "from the next day the neighbor is taken")
		late.free())
	GameState.day = saved_day

## Day 10's raid: vans at her building and a patrol, arriving only once she is out of sight of her
## door, and never on her own sidewalk — the doorstep stays reachable along it.
func _test_the_raid_waits_at_her_building_with_the_doorstep_open(t) -> void:
	var saved_scars := GameState.scars.duplicate(true)
	GameState.scars.clear()
	_build_city(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	happenings.tick(STEP, door, Vector2.ZERO, Callable())
	t.check(happenings.raid.is_empty(), "nothing arrives while she is at her door")
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO,
			func(_at: Vector2) -> bool: return true)
	t.check(happenings.raid.is_empty(), "or while any of it would be on screen")
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO,
			Callable())
	var vans := 0
	var patrols := 0
	var door_tile := _city.map.world_to_tile(door)
	for instance in happenings.raid:
		if instance.def.id == "night_raid":
			vans += 1
			t.check(not instance.def.pursues, "a van at her door does not hunt")
			for tile in EventManager.obstructed_footprint(_city.map, instance.def,
					instance.global_position, Vector2.RIGHT):
				t.check(tile.y > door_tile.y + Tuning.SIDEWALK_WIDTH - 1,
						"a van's body is off her own sidewalk (%s)" % tile)
		elif instance.def.id == "police_patrol":
			patrols += 1
			t.check(instance.def.shape != null, "the patrol car keeps its shape")
	t.check(vans == 2 and patrols == 1, "two vans and a patrol at her building (%d, %d)"
			% [vans, patrols])
	for instance in happenings.raid:
		_city.events.retire(instance)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY + 1)
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO,
			Callable())
	t.check(happenings.raid.is_empty(), "and only on day 10")
	GameState.scars = saved_scars

## Her street door: ordinary at day 10's start, sealed live the moment the raid actually arrives
## (PLAYTEST-131), and the scar it leaves is what every later day and a reloaded save read it
## from (`City._sync_home_door()`, `_test_the_sealed_door_stands_after_a_reload()` below).
func _test_the_raid_seals_her_street_door(t) -> void:
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	GameState.scars.clear()
	GameState.day = ResistanceHappenings.NEIGHBOR_DAY
	# After `GameState.scars` is cleared: `_build_city()`'s own `City.build()` reads it once, at
	# boot, exactly as a resumed run's own boot does (`_door_texture_for_today()`'s own doc).
	_build_city(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	t.check(_city._home_door.texture == AtlasLibrary.region(City.DOOR_TEXTURE),
			"the door is ordinary at day 10's start")
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO,
			Callable())
	t.check(_city._home_door.texture == AtlasLibrary.region(City.SEALED_DOOR_TEXTURE),
			"and sealed the moment the raid arrives, out of her sight")
	var sealed := false
	for scar in GameState.scars:
		if String(scar["id"]) == City.SEALED_DOOR_SCAR:
			sealed = true
	t.check(sealed, "which leaves a scar for every later day to read")
	for instance in happenings.raid:
		_city.events.retire(instance)
	GameState.scars = saved_scars
	GameState.day = saved_day

## Sealed on day 11 and after a save/load: `City.build()` reads `GameState.scars` once, at boot,
## which is what a resumed or reloaded run's own boot does — see `main.gd`'s two `_city.build()`
## call sites, both after `GameState` has already loaded.
func _test_the_sealed_door_stands_after_a_reload(t) -> void:
	var saved_scars := GameState.scars.duplicate(true)
	GameState.scars = [{"id": City.SEALED_DOOR_SCAR, "position": Vector2.ZERO, "since_day": 10}]
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	t.check(city._home_door.texture == AtlasLibrary.region(City.SEALED_DOOR_TEXTURE),
			"a boot whose scars already carry the seal starts the door sealed")
	city.free()
	GameState.scars = saved_scars

## A lost day 10 gives the scar back (`GameState._give_back_what_the_attempt_spent()`) and the
## next dawn's own `_sync_home_door()` puts the ordinary door back, exactly the restore every
## other scar already gets.
func _test_a_lost_day_ten_restores_the_ordinary_door(t) -> void:
	var saved_scars := GameState.scars.duplicate(true)
	var saved_day := GameState.day
	GameState.scars.clear()
	GameState.day = ResistanceHappenings.NEIGHBOR_DAY
	_build_city(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	var door := _city.map.doorstep_world_position()
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO,
			Callable())
	t.check(_city._home_door.texture == AtlasLibrary.region(City.SEALED_DOOR_TEXTURE),
			"sealed once the raid arrives")
	for instance in happenings.raid:
		_city.events.retire(instance)
	# The loss: the attempt's own scar is given back, the same way
	# `GameState._give_back_what_the_attempt_spent()` restores every scar a lost day left.
	GameState.scars.clear()
	var state := CityState.new()
	state.begin_day(_city.map.block_plans, ResistanceHappenings.NEIGHBOR_DAY)
	_city.start_day(state, ResistanceHappenings.NEIGHBOR_DAY,
			_rng(ResistanceHappenings.NEIGHBOR_DAY, "closures"))
	t.check(_city._home_door.texture == AtlasLibrary.region(City.DOOR_TEXTURE),
			"a lost day 10 restores the ordinary door")
	GameState.scars = saved_scars
	GameState.day = saved_day

## The neighbor's boarded window: absent before day 11, set on the one home-block building the
## door notch stands in front of from day 11's morning on — the third floor nearest the door,
## down the hall from her own door (PLAYTEST-131), always there since M185 fixes that building's
## own height at `City.HOME_BUILDING_WALL_ROWS` (4) wall rows or more — the same cell every later
## day and on a fresh load of the same seed. `SEED` (4242) is the seed PLAYTEST-134 found with
## only two wall rows before the fix.
func _test_the_neighbor_window_is_boarded_from_day_eleven(t) -> void:
	_build_city(t)
	var happenings := ResistanceHappenings.new()
	happenings.setup(_city, _city.map)
	var building := _city._home_door_building()
	t.check(building != null, "the door notch stands in front of exactly one home-block building")
	t.check(building.wall_tiles() >= 4,
			"seed %d: her own building has at least four wall rows (%d)" % [SEED, building.wall_tiles()])

	happenings.start_day(ResistanceHappenings.MARKET_DAY - 1)
	t.check(building.neighbor_window_col == -1, "unboarded the day before")

	happenings.start_day(ResistanceHappenings.MARKET_DAY)
	var col := building.neighbor_window_col
	t.check(col >= 0, "boarded from day 11's morning on")
	t.check(building.neighbor_window_row() == 3,
			"seed %d: on the third floor" % SEED)

	happenings.start_day(ResistanceHappenings.MARKET_DAY + 3)
	t.check(building.neighbor_window_col == col, "the same cell on every later day")

	var reloaded: City = CITY_SCENE.instantiate()
	t.add_child(reloaded)
	reloaded.build(CityGenerator.generate(SEED))
	reloaded.board_neighbor_window()
	var reloaded_building := reloaded._home_door_building()
	t.check(reloaded_building.neighbor_window_col == col, "and the same cell on a fresh load")
	reloaded.free()

## Plans `day` on the test city through the real day order with `state` as the run's own
## `GameState.city_state`, which the happenings read, and hands back a director for it.
func _director_on_day(t, day: int, state: CityState) -> ResistanceDirector:
	GameState.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	return director

## Day 11: the market is found gone — a commercial block whose arc was waiting to board up is
## boarded now, out of her sight, with the market stalls at its frontage gone from the day's plan,
## and it stays boarded. Nothing happens before she has walked a while; with nothing on her way by
## `Tuning.MARKET_GONE_BY`, the nearest block she cannot see goes.
func _test_the_market_is_found_gone(t) -> void:
	_build_city(t)
	var saved_state := GameState.city_state
	var saved_day := GameState.day
	GameState.day = ResistanceHappenings.MARKET_DAY
	_with_clean_run(func() -> void:
		var state := CityState.new()
		var director := _director_on_day(t, ResistanceHappenings.MARKET_DAY, state)
		var happenings := director._happenings
		var door := _city.map.doorstep_world_position()
		var candidates := ResistanceHappenings.market_candidates(_city.map, state)
		t.check(not candidates.is_empty(),
				"the test city has a block waiting to board up, or this test checks nothing")
		happenings.tick(STEP, door, Vector2.ZERO, Callable())
		t.check(happenings.market_block.x < 0, "nothing is gone before she has walked anywhere")
		happenings._elapsed = Tuning.MARKET_GONE_BY
		happenings._walked = EventDirector.ON_HER_WAY_AFTER
		happenings.tick(STEP, door, Vector2.ZERO, Callable())
		var block := happenings.market_block
		t.check(block in candidates, "by then a block waiting to board up is gone (%s)" % block)
		if block.x >= 0:
			var frontage := happenings._frontage_of(block)
			t.check(ResistanceHappenings._distance_to_rect(door, frontage) >= Tuning.OUT_OF_SIGHT,
					"out of her sight")
			t.check(state.purpose_of(_city.map.block_plans, block)
					== GameEnums.BlockPurpose.BOARDED_UP, "boarded up now")
			var shuttered := 0
			for building in _city._buildings:
				if _city._block_of(building.lot) == block:
					t.check(building.condition == Building.Condition.BOARDED,
							"every building of it shuttered")
					shuttered += 1
			t.check(shuttered > 0, "and it has buildings to shutter")
			for plan in _city.events.plans():
				if plan.def.id == "market_stall" and frontage.has_point(plan.position):
					t.check(plan.spent or (plan.live and plan.live.is_finished),
							"no market stall of it is left in the day")
			state.begin_day(_city.map.block_plans, ResistanceHappenings.MARKET_DAY + 1)
			t.check(state.purpose_of(_city.map.block_plans, block)
					== GameEnums.BlockPurpose.BOARDED_UP, "and it stays boarded")
		happenings.tick(STEP, door, Vector2.ZERO, Callable())
		t.check(happenings.market_block == block, "and the market is gone once")
		director.free())
	GameState.city_state = saved_state
	GameState.day = saved_day

## Day 12: reaching the swing takes the park. It stops being calm for the city at once, its
## ground closes from the edges in over `Tuning.PARK_CLOSING_SECONDS` until no calm tile of it is
## left and the swing frame is gone with the playground, and it is requisitioned from then on.
func _test_the_park_closes_in_front_of_her_and_stays_taken(t) -> void:
	_build_city(t)
	var saved_state := GameState.city_state
	var saved_day := GameState.day
	var day := ResistanceSteps.swing_day()
	GameState.day = day
	_with_clean_run(func() -> void:
		var state := CityState.new()
		var director := _director_on_day(t, day, state)
		var park := CityGenerator.swing_park(_city.map)
		var mark := director.current_step()
		director._on_contact_completed(mark.index if mark else -1)
		var task := director.current_step()
		t.check(task != null and task.target_kind == ResistanceSteps.TargetKind.PARK_SWING,
				"day 12 sends her to the swing")
		t.check(park in _city.map.calm_blocks, "whose park is calm until she reaches it")
		director._on_contact_completed(task.index if task else -1)
		t.check(state.purpose_of(_city.map.block_plans, park)
				== GameEnums.BlockPurpose.REQUISITIONED, "reaching the swing takes the park")
		t.check(not (park in _city.map.calm_blocks), "and the city stops counting it as calm")
		var layout: BlockLayout = _city.map.block_layouts[park]
		var happenings := director._happenings
		t.check(happenings.is_closing(), "its ground starts to close")
		var calm_left := func() -> int:
			var count := 0
			for tile in _city.map.rect_tiles(layout.open_rect):
				if Tile.is_calm(_city.map.tile_at(tile)):
					count += 1
			return count
		var before: int = calm_left.call()
		happenings.tick(Tuning.PARK_CLOSING_SECONDS * 0.5, Vector2.INF, Vector2.ZERO, Callable())
		var halfway: int = calm_left.call()
		t.check(halfway > 0 and halfway < before,
				"a ring at a time, from the edges in (%d of %d left half way)" % [halfway, before])
		happenings.tick(Tuning.PARK_CLOSING_SECONDS * 0.5 + 0.1, Vector2.INF, Vector2.ZERO,
				Callable())
		t.check(calm_left.call() == 0 and not happenings.is_closing(),
				"until none of it is calm")
		var frame_left := false
		for prop in _city._props:
			var frame := prop as Prop
			if frame and frame.kind == Prop.Kind.PLAYGROUND_FRAME and not frame.is_queued_for_deletion() \
					and _city.map.tile_rect_to_world(layout.open_rect).has_point(frame.position):
				frame_left = true
		t.check(not frame_left, "and the swing frame is gone with it")
		state.begin_day(_city.map.block_plans, day + 1)
		t.check(state.purpose_of(_city.map.block_plans, park)
				== GameEnums.BlockPurpose.REQUISITIONED, "it stays taken")
		director.free())
	GameState.city_state = saved_state
	GameState.day = saved_day

## Day 13: the column. The convoys start that morning; the column is `Tuning.COLUMN_TRUCKS` trucks
## in one lane of the main road, warned of first: its badge goes up with no truck in the world, its
## place in the lane just off screen level with her, and the trucks arrive there once the row's
## telegraph is over, coming toward the point level with her. The rear one stops out of her sight —
## beyond her, or short of her where nothing beyond will do — on a street rather than a junction,
## where its barricade still leaves her a way home; the trucks ahead of it leave nothing. It comes
## once she nears the main road, or at `Tuning.COLUMN_BY` wherever she is, and once.
func _test_the_column_comes_down_the_main_road(t) -> void:
	var convoy := EventCatalogue.by_id("military_convoy")
	t.check(convoy.first_day == ResistanceHappenings.COLUMN_DAY,
			"the convoys start on day 13 (%d)" % convoy.first_day)
	_build_city(t)
	var saved_state := GameState.city_state
	var saved_day := GameState.day
	GameState.day = ResistanceHappenings.COLUMN_DAY
	_with_clean_run(func() -> void:
		var state := CityState.new()
		var director := _director_on_day(t, ResistanceHappenings.COLUMN_DAY, state)
		var happenings := director._happenings
		var map := _city.map
		var door := map.doorstep_world_position()
		var spine := happenings._spine_x()
		var far_from_it := Vector2(spine + Tuning.COLUMN_WITHIN * 2.0, door.y)
		happenings._walked = EventDirector.ON_HER_WAY_AFTER
		happenings.tick(STEP, far_from_it, Vector2.ZERO, Callable())
		t.check(happenings.column.is_empty(), "nothing comes while she is far from the main road")
		var her := Vector2(spine - Tuning.STREET_WIDTH * 0.5 * Tuning.TILE_SIZE + Tuning.TILE_SIZE,
				map.size.y * Tuning.TILE_SIZE * 0.5)
		happenings.tick(STEP, her, Vector2.ZERO, Callable())
		t.check(happenings.column.is_empty(),
				"near it, the column's warning goes up with no truck in the world yet")
		var warning := _warning_for(_city.events, "military_convoy")
		t.check(warning != null, "and its badge has somewhere to point")
		var lead := Tuning.offscreen_lead(Vector2.UP, convoy.speed + Tuning.WALK_SPEED,
				convoy.offscreen_notice)
		if warning:
			t.check(CrowdLanes.corridor_at(warning.place.x) == _city.map.main_road,
					"pointing up the main road")
			# She walks a block along the road while it is coming: the place keeps its distance.
			var was := absf(warning.place.y - her.y)
			her.y += CityMap.period() * Tuning.TILE_SIZE * 0.5
			_city.events._run_the_warnings(STEP, her)
			t.close_to(absf(warning.place.y - her.y), was,
					"and it moves with her rather than coming sooner", 1.0)
		# The rest of the warning, frame by frame, the way `EventManager._physics_process` runs it.
		var pointed := warning.place if warning else Vector2.INF
		while warning and _city.events.pending_warnings().has(warning) \
				and warning.shown < convoy.telegraph_time + 5.0:
			pointed = warning.place
			_city.events._run_the_warnings(STEP, her)
		var trucks := happenings.column
		t.check(trucks.size() == Tuning.COLUMN_TRUCKS,
				"once the warning is over, a column of %d trucks comes (%d)"
				% [Tuning.COLUMN_TRUCKS, trucks.size()])
		var edge := minf(her.y, map.size.y * Tuning.TILE_SIZE - her.y) - Tuning.TILE_SIZE
		var leaving := 0
		for i in trucks.size():
			var truck := trucks[i]
			t.check(truck.def.id == "military_convoy" and truck.path.size() == 2,
					"each is the catalogue's own truck on a path")
			t.check(CrowdLanes.corridor_at(truck.path[0].x) == map.main_road
					and is_equal_approx(truck.path[0].x, truck.path[1].x),
					"in one lane of the main road")
			t.check(truck.path[0].distance_to(her) >= minf(lead, edge) - 1.0,
					"far enough up the road (%.0fpx)" % truck.path[0].distance_to(her))
			if truck.def.spawns_on_finish != "":
				leaving += 1
				var stop := truck.path[1]
				t.check(i == trucks.size() - 1, "only the rear truck leaves anything")
				t.check(stop.distance_to(her) >= Tuning.OUT_OF_SIGHT,
						"and it stops out of her sight")
				t.check(StreetNetwork.segment_containing(map.world_to_tile(stop)) != null,
						"on a street, not a junction")
		t.check(leaving == 1, "one barricade's worth, from the rear truck (%d)" % leaving)
		# **Where the front truck is created and how long after the badge it can reach her, on the
		# real siting.** Its forward reach (395px) is deeper than the view is from her, so standing
		# by its road she may be inside its field from its first frame: what she is owed is the
		# warning before it existed, at least the row's own minimum (`EventDef.minimum_telegraph()`),
		# from the badge to the first frame its field reaches her.
		if warning and not trucks.is_empty():
			var front := trucks[0]
			t.check(PendingWarning.is_off_screen(front.global_position - her,
					warning.closing_speed(), warning.def.offscreen_notice)
					and front.global_position.distance_to(pointed) < 1.0,
					"its front truck is created just off screen, where the badge pointed")
			var to_reach := 0.0
			while front.contribution_at(her) <= 0.0 and to_reach < 10.0:
				front.player_at = her
				front._process(STEP)
				to_reach += STEP
			t.check(warning.shown + to_reach + 0.001 >= warning.def.minimum_telegraph(),
					("and from the badge to the earliest its field reaches her is %.2fs, at least "
					% (warning.shown + to_reach))
					+ "the %.2fs it is owed" % warning.def.minimum_telegraph())
		happenings.tick(STEP, her, Vector2.ZERO, Callable())
		t.check(happenings.column.size() == Tuning.COLUMN_TRUCKS, "and it comes once")
		for truck in trucks:
			_city.events.retire(truck)

		director.start_day(ResistanceHappenings.COLUMN_DAY, _rng(13, "resistance"), 300.0)
		happenings._elapsed = Tuning.COLUMN_BY
		happenings.tick(STEP, far_from_it, Vector2.ZERO, Callable())
		_city.events._run_the_warnings(convoy.telegraph_time + STEP, far_from_it)
		t.check(happenings.column.size() == Tuning.COLUMN_TRUCKS,
				"at COLUMN_BY it comes wherever she is")
		for truck in happenings.column:
			_city.events.retire(truck)
		director.free())
	GameState.city_state = saved_state
	GameState.day = saved_day

## The warning `events` has up for the row `id`, or null.
func _warning_for(events: EventManager, id: String) -> PendingWarning:
	for warning in events.pending_warnings():
		if warning.def.id == id:
			return warning
	return null

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
		# M222, "the red arrow for the van does not end on the van": the touch point
		# (`contact_position()`) sits at `_reachable_offset()`'s clearance beside the van's own
		# body, where she can actually reach it — the arrow's tip is the van's body itself
		# (`van._rider.global_position`), not that touch point.
		t.check(van._rider != null, "the package's van is a rider, not a bare point")
		t.check(van.red_arrow_target() != Vector2.INF
				and van.red_arrow_target() == van._rider.global_position
				and van.red_arrow_target() != van.contact_position(),
				"the package's van is one place, so it earns the arrow, exactly on the van's body")
		var task := van.current_step()
		van._contact._complete()
		t.check(task != null and van.red_arrow_target() == Vector2.INF,
				"and it goes out once she has reached it")
		van.free())

# ------------------------------------------------------ M188: reachable targets ---
# The route rig (M184, a rig walks the route) found a mark and two contacts standing on ground
# `_pick_reachable()`/`_reachable_offset()` never checked was clear of a solid body —
# `CityMap.is_obstructed()`, filled by `EventManager.start_day()` from the day's whole plan before
# this director ever places anything (`main.gd`'s own day order: `_city.events.start_day()` runs
# before `_resistance.start_day()`). Both now refuse obstructed ground.

## The same three seeds `tests/probes/m184_route_timing.gd` times days 6-13 against.
const REACHABILITY_SWEEP_SEEDS: Array[int] = [4242, 90210, 1234567]
const REACHABILITY_SWEEP_DAYS := [6, 7, 8, 9, 10, 11, 12, 13]

## `GameState.day_rng()`'s own hash, built without touching the `GameState.run_seed` global this
## sweep has no other use for — same stream a played day actually draws from, for a seed and a day
## this test chooses rather than the run's own.
func _production_rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## Every refusal `_pick_reachable()` and `_reachable_offset()` both check today — `is_held_at`
## excepted for the one task deliberately sited on held ground, the crossing at a region door
## (`_place_at_a_door()`'s own `allow_held`). `grid`/`blocked`/`reached` are one day's own
## `ReachabilityGrid.flood()` answer, built by the caller once per (seed, day) rather than per tile
## — see `_day_reachability()` — so this stays a pure predicate rather than a second place that
## builds the grid.
func _stands_on_legal_ground(map: CityMap, tile: Vector2i, walled_alleys: Array[Rect2i],
		allow_held: bool, grid: ReachabilityGrid, blocked: Dictionary, reached: Dictionary) -> bool:
	return map.is_walkable(tile) and not map.is_closed(tile) \
			and (allow_held or not map.is_held_at(tile)) and not map.is_on_home_block(tile) \
			and not map.is_in_walled_alley(tile, walled_alleys) and not map.is_obstructed(tile) \
			and grid.reaches(tile, blocked, reached)

## The day's reachability answer as `ResistanceDirector._reachable_from_home()` builds it
## (`EventScheduler.blocked_by()` over every placed, obstructing or hard-fail plan, flooded from
## home), built independently here so a sweep is not just asking the director to grade its own
## homework. A region door's own bodies are excluded, the same way `_ensure_reachability()`
## excludes them and for the same reason — see that function's own doc. `[grid, blocked, reached]`.
func _day_reachability(city: City) -> Array:
	var region_plan: RegionPlanner.RegionPlan = city.region_plan()
	var door_bodies: Array[EventScheduler.Planned] = region_plan.door_bodies if region_plan else []
	var blockers: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if not plan.is_placed() or plan in door_bodies:
			continue
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	var grid := ReachabilityGrid.build(city.map)
	var blocked := EventScheduler.blocked_by(city.map, blockers)
	return [grid, blocked, grid.flood([city.map.home_rect.position], blocked)]

## Every mark and every contact a task activates stands on walkable, unobstructed ground — swept
## over days 6-13 and the seeds the route rig timed, through the real day order (`City.start_day()`,
## then `EventManager.start_day()`, then `ResistanceDirector.start_day()`, then one `_process()`
## tick with her standing at the doorstep) so `CityMap.obstructed_tiles` is the day's real record
## rather than an empty one, and a mark that only moves once she is actually in the world is
## checked where she would actually find it.
##
## **The one `_process()` tick is load-bearing, not a nicety.** A `--day 9 --seed 4242 --route
## mark,task,calm,home --no-title` boot of the real game showed this directly: day 9's mark rolled
## legal ground at dawn (108,67), but she starts at the doorstep, more than `NOTICE_RADIUS` from
## it, so `_track_sight_and_reposition()` relocates it on the very first frame — before this sweep
## ever existed, straight onto an obstructed tile, (79,90), that `_pick_reachable()`'s own dawn
## check never had a chance to refuse because the draw itself was never the problem. A sweep that
## only asked `start_day()` was asking a question the real game never actually asks: `main.gd`'s
## own order (`_resistance.start_day()`, then `_player.reset_at(start_at)`, then the tree's first
## `_process()`) means a played mark is always checked here at frame 0, standing wherever the
## relocation left it, not wherever the dawn roll did. Skipping it also drew the day's RNG stream
## one guard-placement short of a real day: `_move_the_mark()` re-rolls the guard through the same
## `_rng` the day's later placements share, so a sweep that never relocated the mark answered
## every placement *after* it — the task's own `_reachable_offset()` included — from a stream a
## real boot never sees, which is why an earlier sweep's own "moved" list did not match the route
## rig's real cases at all.
##
## **Each day is asked fresh**, the same "no history, just this day" state `--day N`
## (`DevFlags.day_override()`) boots into — `GameState.start_run()` runs before `GameState.day` is
## set, so a rig timing day 9 alone never played days 6-8 first — matching every other single-day
## placement test in this file (`_test_the_door_task_sits_at_a_region_door` and others call
## `director.start_day()` for one chosen day with no days before it either).
##
## Days 10 and 11 offer no mark (`ResistanceSteps._build()`'s own comment on the later slice they
## wait on) and are swept anyway rather than skipped, so the loop's own day range reads as "days
## 6-13" without a silent gap; `current_step() == null` there is expected and checked nothing.
##
## Named cases this sweep carries (`docs/TODO.md`, M188): day 9 seed 4242 (a mark relocated onto
## obstructed ground, and then — once that was fixed — onto ground the day's own obstruction sealed
## off from home), days 7 and 8 seed 90210 (a contact's offset landing inside a building), and day 7
## seed 1234567 (a mark on good ground the day's whole obstruction seals off from home, item 3) are
## all within this sweep's own days and seeds, so the general loop below checks them along with
## everything else rather than as a separate case.
func _test_every_mark_and_contact_stands_on_walkable_unobstructed_ground(t) -> void:
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		var checked := 0
		for seed_value in REACHABILITY_SWEEP_SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day in REACHABILITY_SWEEP_DAYS:
				GameState.completed_resistance_steps = []
				GameState.failed_resistance_steps = []
				GameState.completed_resistance_alley_tiles.clear()
				var closure_state := CityState.new()
				closure_state.begin_day(city.map.block_plans, day)
				city.start_day(closure_state, day, _production_rng(seed_value, day, "closures"))
				city.events.start_day(day, _production_rng(seed_value, day, "events"), [],
						city.map.doorstep_world_position())

				var director := ResistanceDirector.new()
				t.add_child(director)
				director.set_process(false)
				director.setup(city, city.map)
				director.start_day(day, _production_rng(seed_value, day, "resistance"),
						Tuning.day_length(day))
				# `main.gd`'s own order: the player is placed at the doorstep only after
				# `_resistance.start_day()` returns, and the tree's first `_process()` runs after
				# that — so a mark checked before this tick is checked somewhere she never sees.
				var player := _rig_player(t, city.map.doorstep_world_position())
				director._process(STEP)

				var region_plan: RegionPlanner.RegionPlan = city.region_plan()
				var walled_alleys: Array[Rect2i] = region_plan.alley_walls if region_plan else []
				var reachability := _day_reachability(city)
				var grid: ReachabilityGrid = reachability[0]
				var blocked: Dictionary = reachability[1]
				var reached: Dictionary = reachability[2]
				var mark_step := director.current_step()
				if mark_step != null:
					checked += 1
					var mark_tile := city.map.world_to_tile(director.contact_position())
					t.check(_stands_on_legal_ground(city.map, mark_tile, walled_alleys, false,
							grid, blocked, reached),
							("seed %d day %d: step %d's mark stands on walkable, unobstructed, " +
							"reachable ground at %s") % [seed_value, day, mark_step.index, mark_tile])

					director._on_contact_completed(mark_step.index)
					var task_step := director.current_step()
					if task_step != null:
						checked += 1
						var task_tile := city.map.world_to_tile(director.contact_position())
						var allow_held := ResistanceSteps.stands_on_held_ground(task_step)
						t.check(_stands_on_legal_ground(city.map, task_tile, walled_alleys,
								allow_held, grid, blocked, reached),
								("seed %d day %d: step %d's contact stands on walkable, " +
								"unobstructed, reachable ground at %s") % [seed_value, day,
								task_step.index, task_tile])
				player.free()
				director.free()
			city.free()
		GameState.completed_resistance_alley_tiles = saved_tiles
		t.check(checked > 0, "the sweep actually checked something (%d)" % checked))

## downy-otter, "a mark should never be placed in an alley that is not reachable (ie sealed off)"
## (olive-koala, statement 9). The claim above already holds — `_pick_reachable()` redraws
## against `_reachable_from_home()`, closures and hard seals alike, with a nearest-legal fallback
## — but `_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground` only ever asked it
## of the three seeds `tests/probes/m184_route_timing.gd` times, tied to that probe on purpose
## (its own doc). This asks the mark half alone, over four more seeds — deliberately not
## overlapping that test's own three, which is the item's own "a test over many seeds states it"
## — reusing `_day_reachability()`/`_stands_on_legal_ground()` rather than a second implementation
## of either. A full-city-generation sweep is the expensive kind (M125's own finding, cut from six
## seeds to three for the same reason), so this stays at four rather than growing further.
const MARK_REACHABILITY_SWEEP_SEEDS: Array[int] = [2295276695, 291862120, 314159, 555555]

func _test_a_mark_is_never_placed_in_an_alley_she_cannot_reach(t) -> void:
	_with_clean_run(func() -> void:
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		var checked := 0
		for seed_value in MARK_REACHABILITY_SWEEP_SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day in REACHABILITY_SWEEP_DAYS:
				GameState.completed_resistance_steps = []
				GameState.failed_resistance_steps = []
				GameState.completed_resistance_alley_tiles.clear()
				var closure_state := CityState.new()
				closure_state.begin_day(city.map.block_plans, day)
				city.start_day(closure_state, day, _production_rng(seed_value, day, "closures"))
				city.events.start_day(day, _production_rng(seed_value, day, "events"), [],
						city.map.doorstep_world_position())

				var director := ResistanceDirector.new()
				t.add_child(director)
				director.set_process(false)
				director.setup(city, city.map)
				director.start_day(day, _production_rng(seed_value, day, "resistance"),
						Tuning.day_length(day))
				# `main.gd`'s own order: she is placed and ticks once before this checks anything —
				# see `_test_every_mark_and_contact_stands_on_walkable_unobstructed_ground`'s own
				# doc for why the tick is load-bearing.
				var player := _rig_player(t, city.map.doorstep_world_position())
				director._process(STEP)

				var mark_step := director.current_step()
				if mark_step != null and mark_step.is_pickup:
					checked += 1
					var region_plan: RegionPlanner.RegionPlan = city.region_plan()
					var walled_alleys: Array[Rect2i] = \
							region_plan.alley_walls if region_plan else []
					var reachability := _day_reachability(city)
					var grid: ReachabilityGrid = reachability[0]
					var blocked: Dictionary = reachability[1]
					var reached: Dictionary = reachability[2]
					var mark_tile := city.map.world_to_tile(director.contact_position())
					t.check(_stands_on_legal_ground(city.map, mark_tile, walled_alleys, false,
							grid, blocked, reached),
							("seed %d day %d: the mark stands on walkable, unobstructed, " +
							"reachable ground at %s, never a sealed or closed alley")
							% [seed_value, day, mark_tile])
				player.free()
				director.free()
			city.free()
		GameState.completed_resistance_alley_tiles = saved_tiles
		t.check(checked > 0, "the sweep actually checked something (%d)" % checked))

## downy-otter, "a mark is never placed in an alley she cannot reach" (*"also a mark should never
## be placed in an alley that is not reachable (ie sealed off)"*, olive-koala statement 9), on the
## relocation path: `_nearest_alley_within()` asks `_reachable_from_home()` over the flood
## `_ensure_reachability()` builds once and caches for the day. Asked here from every tenth
## sidewalk tile of two cities, over every mark day, the way a mark relocating mid-walk is placed,
## and every answer is checked two ways: against `_day_reachability()`, the same rule the director
## keeps (every obstructing or lethal plan's disc and the day's closures), built afresh; and against
## a plain walk from the doorstep over walkable ground minus `CityMap.closed_tiles`,
## `soft_sealed_tiles` and `obstructed_tiles` — the per-tile record of where a body stands, a
## second source the director's discs do not read. Two seeds and a tenth of the sidewalks keep the
## cost down: `_nearest_alley_within()` is linear in the alley count per call.
##
## **What this does not cover**: a region door counts as a way through, for the director and for
## the tile walk alike, so a mark reachable only by crossing a district door passes here. Whether
## that is "not reachable" in the player's sense is open (statement 8: *"the go through a door
## task is silly when you have to go through a door to even reach the mark"*).
func _test_a_relocated_mark_is_never_placed_in_an_alley_she_cannot_reach(t) -> void:
	var seeds: Array[int] = [4242, 2295276695]
	var checked := 0
	for seed_value in seeds:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		for day in REACHABILITY_SWEEP_DAYS:
			var closure_state := CityState.new()
			closure_state.begin_day(city.map.block_plans, day)
			city.start_day(closure_state, day, _production_rng(seed_value, day, "closures"))
			city.events.start_day(day, _production_rng(seed_value, day, "events"), [],
					city.map.doorstep_world_position())

			var director := ResistanceDirector.new()
			t.add_child(director)
			director.set_process(false)
			director.setup(city, city.map)
			director.start_day(day, _production_rng(seed_value, day, "resistance"),
					Tuning.day_length(day))
			var mark_step := director.current_step()
			if mark_step == null or not mark_step.is_pickup:
				director.free()
				continue

			var region_plan: RegionPlanner.RegionPlan = city.region_plan()
			var walled_alleys: Array[Rect2i] = region_plan.alley_walls if region_plan else []
			var reachability := _day_reachability(city)
			var grid: ReachabilityGrid = reachability[0]
			var blocked: Dictionary = reachability[1]
			var reached: Dictionary = reachability[2]

			var by_tiles := {}
			for tiles: Dictionary in [city.map.closed_tiles, city.map.soft_sealed_tiles,
					city.map.obstructed_tiles]:
				for tile: Vector2i in tiles:
					by_tiles[tile] = true
			var walk := city.map.walk_field(
					city.map.world_to_tile(city.map.doorstep_world_position()), by_tiles)

			var sidewalks := city.map.tiles_of_type(GameEnums.TileType.SIDEWALK)
			for i in sidewalks.size():
				if i % 10 != 0:
					continue
				var here := city.map.tile_to_world(sidewalks[i])
				var nearest := director._nearest_alley_within(here)
				if nearest == Vector2.INF:
					continue
				checked += 1
				var nearest_tile := city.map.world_to_tile(nearest)
				t.check(_stands_on_legal_ground(city.map, nearest_tile, walled_alleys, false,
						grid, blocked, reached),
						("seed %d day %d: the alley a relocation from %s answers with is " +
						"walkable, unobstructed and reachable from home, never sealed off")
						% [seed_value, day, sidewalks[i]])
				t.check(city.map.distance_at(walk, nearest_tile) >= 0,
						("seed %d day %d: and a walk from the doorstep around every closure, seal " +
						"and body reaches it (%s, from %s)")
						% [seed_value, day, nearest_tile, sidewalks[i]])
			director.free()
		city.free()
	t.check(checked > 0, "some relocation target was actually checked (%d)" % checked)

## Cities whose narrow targets the day's own seals and bodies could ring, found by
## `tests/probes/m181_resistance_targets.gd`'s wide run: each had a last-night destination cut off
## from home before the day kept a route to it. Chosen for what they would catch rather than for
## luck: the guarantee is a rule about every day, and these are days the rule has work to do on.
const NARROW_TARGET_SEEDS: Array[int] = [196838, 355218, 323542, 252271]

## **The day keeps a route to its narrow resistance target** (`docs/CITY.md`, "Guarantees"): day
## 9's door, day 12's swing and the power station's front door, planned through the real day
## order —
## `City.start_day()`, `EventManager.start_day()`, then the director's own `_place()` of the day's
## step — and asked of an independent flood (`_day_reachability()`). Two things per day: some tile
## of the pool is legal, unobstructed and reachable from home, and the tile the director actually
## picks is one of them.
##
## The finale's day plans at full heat, since the finale is only offered once the goal is met and
## the heat is what the scheduler reads; days 9 and 12 plan cold, each asked fresh as `--day N`
## boots it.
##
## **Day 12 owes a second park as well**: some calm area other than the swing's, clean — no field
## the day planned reaching its ground — and reachable from home under the same flood, which is
## where she settles the baby once the swing's park is taken.
func _test_the_narrow_targets_are_reachable_on_their_day(t) -> void:
	_with_clean_run(func() -> void:
		var checked := 0
		for seed_value in NARROW_TARGET_SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day: int in [9, 12, Tuning.RUN_LENGTH_DAYS]:
				var step := ResistanceSteps.narrow_target_on(day)
				t.check(step != null, "day %d has a narrow resistance target" % day)
				if not step:
					continue
				GameState.resistance_progress = Tuning.RESISTANCE_GOAL if step.needs_goal else 0
				var state := CityState.new()
				state.begin_day(city.map.block_plans, day)
				city.start_day(state, day, _production_rng(seed_value, day, "closures"))
				city.events.start_day(day, _production_rng(seed_value, day, "events"), [],
						city.map.doorstep_world_position())
				var region_plan: RegionPlanner.RegionPlan = city.region_plan()
				var pool := ResistanceSteps.target_candidates(step, city.map, region_plan)
				var walled: Array[Rect2i] = region_plan.alley_walls if region_plan else []
				var allow_held := ResistanceSteps.stands_on_held_ground(step)
				var reachability := _day_reachability(city)
				var grid: ReachabilityGrid = reachability[0]
				var blocked: Dictionary = reachability[1]
				var reached: Dictionary = reachability[2]
				var reachable := 0
				for tile in pool:
					if _stands_on_legal_ground(city.map, tile, walled, allow_held, grid, blocked,
							reached):
						reachable += 1
				checked += 1
				t.check(reachable > 0,
						("seed %d day %d: some tile of step %d's target is legal, unobstructed " +
						"and reachable from home (%d of %d)")
						% [seed_value, day, step.index, reachable, pool.size()])
				if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
					t.check(_a_second_clean_park_is_reached(city, grid, blocked, reached),
							"seed %d day 12: a clean calm area besides the swing's is reachable"
							% seed_value)

				var director := ResistanceDirector.new()
				t.add_child(director)
				director.set_process(false)
				director.setup(city, city.map)
				var at := director._place(step, _production_rng(seed_value, day, "resistance"))
				var at_tile := city.map.world_to_tile(at) if at != Vector2.INF else Vector2i(-1, -1)
				t.check(at != Vector2.INF and _stands_on_legal_ground(city.map, at_tile, walled,
						allow_held, grid, blocked, reached),
						"seed %d day %d: step %d's contact stands on reachable ground at %s"
						% [seed_value, day, step.index, at_tile])
				director.free()
			city.free()
		t.check(checked > 0, "the sweep actually checked some day (%d)" % checked))

## Whether some calm area other than the day's swing park has calm ground reached under
## `_day_reachability()`'s flood and no field of the day's catalogue on it — the rows the day rolled
## (every one of them given a role) and the masts, which is what `_ensure_one_usable_park()` counts
## as spoiling; the seals and the region wall are the street's, and it does not.
func _a_second_clean_park_is_reached(city: City, grid: ReachabilityGrid, blocked: Dictionary,
		reached: Dictionary) -> bool:
	var swing := CityGenerator.swing_park(city.map)
	var catalogue: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if plan.role != GameEnums.BlockerRole.NONE or plan.mast_id != "":
			catalogue.append(plan)
	for block in city.map.calm_blocks:
		if block == swing:
			continue
		var rect := ClosurePlanner.calm_area_rect(city.map, block)
		if EventScheduler._is_spoiled(city.map, catalogue, rect):
			continue
		for tile in city.map.rect_tiles(rect):
			if Tile.is_calm(city.map.tile_at(tile)) and grid.reaches(tile, blocked, reached):
				return true
	return false

## The first `RandomNumberGenerator.seed` whose first `randi_range(0, pool_size - 1)` answers
## `wanted_index` — found by trying seeds in order rather than inverted by hand, since nothing here
## needs a *particular* seed, only one that reproduces a chosen draw so the next test can control
## which pool entry a fresh RNG picks.
func _seed_that_draws(pool_size: int, wanted_index: int) -> int:
	for seed_value in range(1, 100000):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		if rng.randi_range(0, pool_size - 1) == wanted_index:
			return seed_value
	return -1

## **A placement that is valid today stays exactly where it is; only a candidate the new check
## rejects is replaced.** `_pick_reachable()` draws one index over the whole pool exactly as it did
## before `is_obstructed()` was ever checked, and only asks the question of the tile the draw
## actually landed on — so a pool with nothing obstructed in it, or a draw that lands on a tile
## that never was, answers exactly what a bare `pool[rng.randi_range(...)]` would.
##
## Proven directly rather than inferred from a sweep's own before/after numbers: two real, legal
## alley tiles as the whole pool, one seed engineered to draw each index first
## (`_seed_that_draws()`). Neither candidate obstructed draws candidate_a exactly; candidate_a
## obstructed replaces it with candidate_b, the pool's only other legal tile, never a third,
## nonexistent one; and the seed that would have drawn candidate_b anyway still draws it,
## unmoved by an obstruction on a *different* candidate it was never going to answer with.
func _test_pick_reachable_only_replaces_the_candidate_the_new_check_rejects(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		# Neither candidate this test picks may already be "used" (M177) — an unrelated leftover
		# would shrink the pool below the two entries every check below assumes.
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.completed_resistance_alley_tiles.clear()

		var legal: Array[Vector2i] = []
		for tile in _city.map.tiles_of_type(GameEnums.TileType.ALLEY):
			if _city.map.is_walkable(tile) and not _city.map.is_closed(tile) \
					and not _city.map.is_held_at(tile) and not _city.map.is_on_home_block(tile):
				legal.append(tile)
			if legal.size() >= 2:
				break
		t.check(legal.size() >= 2, "the test city has at least two legal alley candidates")
		if legal.size() < 2:
			GameState.completed_resistance_alley_tiles = saved_tiles
			return

		var candidate_a: Vector2i = legal[0]
		var candidate_b: Vector2i = legal[1]
		var candidates: Array[Vector2i] = [candidate_a, candidate_b]
		var seed_for_a := _seed_that_draws(candidates.size(), 0)
		var seed_for_b := _seed_that_draws(candidates.size(), 1)

		var director := _director(t)
		var rng_a := RandomNumberGenerator.new()
		rng_a.seed = seed_for_a
		t.check(director._pick_reachable(candidates, rng_a) == _city.map.tile_to_world(candidate_a),
				"neither candidate obstructed: the draw lands exactly where it always would")

		var obstruction: Array[Vector2i] = [candidate_a]
		_city.map.obstruct_tiles(self.get_instance_id(), obstruction)
		var rng_a2 := RandomNumberGenerator.new()
		rng_a2.seed = seed_for_a
		t.check(director._pick_reachable(candidates, rng_a2) == _city.map.tile_to_world(candidate_b),
				"candidate_a obstructed: the same draw is replaced by the pool's only other " +
				"legal candidate")

		var rng_b := RandomNumberGenerator.new()
		rng_b.seed = seed_for_b
		t.check(director._pick_reachable(candidates, rng_b) == _city.map.tile_to_world(candidate_b),
				"a draw whose own candidate was never obstructed still lands exactly there, " +
				"unmoved by an obstruction on the other one")

		_city.map.release_obstruction(self.get_instance_id())
		GameState.completed_resistance_alley_tiles = saved_tiles
		director.free())
