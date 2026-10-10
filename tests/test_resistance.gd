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
	_test_touching_a_tasks_body_from_any_side_completes_it(t)
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
	_test_a_mark_under_a_covered_corner_is_not_noticed(t)
	_test_nothing_appears_or_vanishes_under_a_covered_corner(t)
	_test_a_fresh_mark_avoids_an_alley_a_completed_step_used(t)
	_test_a_relocated_mark_avoids_an_alley_a_completed_step_used(t)
	_test_the_guard_moves_with_the_mark_into_its_new_alley(t)
	_test_a_relocation_never_retires_a_guard_in_view_or_awake(t)
	_test_the_guard_never_lands_inside_a_building(t)
	_test_a_guard_with_nowhere_walkable_is_no_guard_at_all(t)
	_test_a_mark_only_ever_sits_at_an_alley_mouth(t)
	_test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t)
	_test_a_long_alleys_robber_stands_two_thirds_in_past_his_trigger(t)
	_test_reading_a_mark_never_lands_her_in_his_catch(t)
	_test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t)
	_test_no_alley_robbery_stands_near_the_doorstep(t)
	_test_playtest_55_seed_has_no_spawn_kill(t)
	_test_a_walled_alley_escapes_no_other_check(t)
	_test_a_walled_alley_never_gets_the_chalk_mark_or_its_guard(t)
	_test_a_perform_contact_is_never_relocated(t)
	_test_the_contact_rides_onto_the_first_look_alike_she_reaches(t)
	_test_the_step_completes_on_the_look_alike_she_hands_it_to(t)
	_test_a_task_that_rides_on_a_row_stands_unguarded_until_it_is_handed_over(t)
	_test_the_van_task_stands_unguarded_until_it_is_handed_over(t)
	_test_the_roadblock_keeps_a_waiting_guard(t)
	_test_every_guarded_target_sends_a_robber_from_off_screen(t)
	_test_the_handover_sets_a_robber_on_her_from_off_screen(t)
	_test_the_van_handover_sets_a_guard_on_her_from_off_screen(t)
	_test_a_trap_rechecks_the_camera_when_its_warning_expires(t)
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
	_test_every_front_the_fire_catches_on_has_a_door_on_a_sidewalk(t)
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
	_test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t)
	_test_an_arrow_exists_on_every_task_day(t)
	_test_the_arrow_chooses_by_walking_distance_not_straight_line(t)
	_test_the_arrow_switches_as_another_target_becomes_closer(t)
	_test_the_arrow_moves_at_four_tiles_closer_and_not_at_three(t)
	_test_the_arrow_leaves_a_freed_instance_at_once(t)
	_test_a_single_target_arrow_stays_on_its_contact(t)
	_test_day_eleven_answers_at_any_live_mast(t)
	_test_every_arrow_ends_on_its_item_and_its_touch_can_be_made(t)
	_test_the_swings_touch_is_the_ellipse_at_its_base(t)
	_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it(t)
	_test_day_nine_completes_when_she_is_let_through_after_the_inspection(t)
	_test_a_queued_mast_is_never_generated_inside_a_lethal_field(t)
	_test_a_task_is_placed_near_its_mark(t)
	_test_day_eleven_puts_up_a_mast_near_the_mark_when_none_is_near(t)
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
## wording is not the player's: about as long as day 6's own mark, the item's own reference for
## "short", one sentence, and still saying where the thing is and where to take it.
func _test_day_eights_mark_is_about_as_long_as_the_shortest_other_mark(t) -> void:
	var day6 := ResistanceSteps.by_index(1).brief
	var day8 := ResistanceSteps.by_index(5).brief
	t.check(day8.length() <= day6.length() * 1.5,
			"day 8's mark (%d chars, %s) is about as long as day 6's (%d chars)"
			% [day8.length(), day8, day6.length()])
	t.check("burnt building" in day8, "and it still says where to take it")
	t.check("stroller" in day8, "and where what she takes is")
	t.check(day8.count(".") == 1 and day8.ends_with("."), "in one sentence")

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

## feathery-marmot, "touching the van completes the task" — *"the arrow correctly points to the van
## but touching the van doesn't solve the task"* (minty-hedgehog, statement 3). The contact rides
## the van and a roadblock, here at an offset to the east of the body, which a touch of a body does
## not read — `ContactPoint.touches_the_body()` measures from the body's own centre — and she walks
## up to the body from sixteen bearings until she is pressed against it, her edge a pixel off its
## outline, found from the row's own `GroundShape` along the instance's own axis: every bearing
## completes the task. A touch counted only within `ContactPoint.REACH` of one point beside the body
## would leave pressing against its far side completing nothing. And standing two
## pixels past `ContactPoint.REACH` beyond the farthest she can be stopped from its centre (its
## furthest reach and her own body), on any side, completes nothing.
func _test_touching_a_tasks_body_from_any_side_completes_it(t) -> void:
	for id: String in ["delivery_van", "roadblock"]:
		var step := _perform_on(7 if id == "delivery_van" else 13)
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(id), Vector2.ZERO)
		t.add_child(instance)
		instance.set_process(false)
		var player := _rig_player(t, Vector2.ZERO)
		var shape := instance.def.shape
		var axis := instance.solid_axis()
		var offset := Vector2.RIGHT * (instance.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS
				+ ContactPoint.REACH * 0.5)
		var pressed_done := 0
		var far_done := 0
		var bearings := 16
		for i in bearings:
			var bearing := Vector2.RIGHT.rotated(TAU * float(i) / float(bearings))
			# Out along the bearing until her centre is a pixel past being stopped by the body.
			var pressed := 0.0
			while shape.distance_to_spine((bearing * pressed).rotated(-axis.angle())) \
					- shape.radius < Tuning.PLAYER_BODY_RADIUS + 1.0:
				pressed += 0.5
			var far := instance.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS \
					+ ContactPoint.REACH + 2.0
			for r: float in [pressed, far]:
				var contact := ContactPoint.new()
				contact.ride(step, instance, offset)
				t.add_child(contact)
				contact.set_physics_process(false)
				player.global_position = bearing * r
				contact._physics_process(STEP)
				if contact.is_done and r == pressed:
					pressed_done += 1
				elif contact.is_done:
					far_done += 1
				contact.free()
		t.check(pressed_done == bearings,
				"%s: pressed against its body from any side completes the task (%d of %d bearings)"
				% [id, pressed_done, bearings])
		t.check(far_done == 0,
				"%s: and a step more than a reach off its body completes nothing (%d of %d bearings)"
				% [id, far_done, bearings])
		player.free()
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
## the task that reading the mark then places with her at the same spot both times, come out the
## same. Day 9's door stands unguarded behind a mark's own guard; day 13's roadblock is the one task
## with a guard of its own; day 14's front door is the one task offered at dawn, and stands
## unguarded, since its trap comes to her once she has handed the key over.
func _test_the_dawn_draws_ignore_where_the_last_attempt_left_her(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_progress := GameState.resistance_progress
		var saved_sabotage := GameState.sabotage_done
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.resistance_progress = Tuning.RESISTANCE_GOAL
		GameState.sabotage_done = false
		for day in [9, 13, Tuning.RUN_LENGTH_DAYS]:
			var first := _attempt_the_day(t, day, _city.map.doorstep_world_position(), false)
			var retry := _attempt_the_day(t, day, first[0], true)
			var dawn_guarded: bool = day != Tuning.RUN_LENGTH_DAYS
			t.check(first[0] != Vector2.INF and (first[1] != Vector2.INF) == dawn_guarded,
					"day %d: the contact is placed, %s (%s, %s)" % [day,
					"and its guard" if dawn_guarded else "with no guard", first[0], first[1]])
			if day == 13:
				t.check(first.size() == 4 and first[2] != Vector2.INF and first[3] != Vector2.INF,
						"day 13: the roadblock and its own guard are placed once the mark is read")
			elif day == 9:
				t.check(first.size() == 4 and first[2] != Vector2.INF and first[3] == Vector2.INF,
						"day 9: the door is placed once the mark is read, with no guard of its own")
			for i in first.size():
				t.check(first[i].distance_to(retry[i]) < 0.5 or first[i] == retry[i],
						"day %d: draw %d comes out the same wherever the last attempt left her (%s, %s)"
						% [day, i, first[i], retry[i]])
		GameState.completed_resistance_alley_tiles = saved_tiles
		GameState.resistance_progress = saved_progress
		GameState.sabotage_done = saved_sabotage)

## One attempt at `day` for the test above, with her standing at `her` and both of the director's
## tests about her view (`ResistanceDirector.set_sight()`) answering `seen` for every point when the
## day starts: `[contact, its guard]` at dawn, then on a mark's day
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
	var on_screen := func(_p: Vector2) -> bool: return seen
	director.set_sight(on_screen, on_screen)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var step := director.current_step()
	var drawn: Array[Vector2] = [director.contact_position()]
	var guard: EventInstance = director._guard if step and step.is_pickup else director._task_guard
	drawn.append(guard.global_position if guard else Vector2.INF)
	if step and step.is_pickup:
		player.global_position = director.contact_position()
		var nothing := func(_p: Vector2) -> bool: return false
		director.set_sight(nothing, nothing)
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
## stands at least 62px (26 + `ContactPoint.REACH`) from every mark, in the mark's own alley —
## within 96px of where `_guard_spot()` says he stands, two-thirds through it or at a courtyard's
## inner end — and the distance is the same every time this day is replayed.
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
						"day %d's guard stands at least 62px from the mark" % day)
				var spot := director._guard_spot(at)
				t.check(spot == Vector2.INF or guard.global_position.distance_to(spot) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
						"day %d's guard stands two-thirds through the mark's alley, or at its courtyard's inner end" % day)
				_seen_guard_distances.append(distance)
			director.free()

			var replay := _director(t)
			replay.start_day(day, _rng(day, "resistance"), 300.0)
			var replay_guard: EventInstance = replay._guard
			if guard and replay_guard and is_instance_valid(replay_guard):
				t.close_to(replay_guard.global_position.distance_to(replay.contact_position()),
						distance, "day %d's guard distance replays the same way" % day, 0.5)
			replay.free())

	# Not "the distance differs from day to day": a mark stands at its alley's mouth and its guard
	# two-thirds through the alley ("Mouth only"; "Two-thirds wins"), so every one-block alley puts
	# him the same distance from the mark by design. What is checked is that each day placed one.
	t.check(_seen_guard_distances.size() >= 2,
			"the guard was placed on more than one day (%d)" % _seen_guard_distances.size())

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
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
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

## The test city's through-alley tiles — see `_through_alley_tiles()`.
func _through_alleys() -> Array[Vector2i]:
	return _through_alley_tiles(_city.map)

## Every `ALLEY` tile of `map` that lies in a through-alley (`CityMap.alley_rects`), in
## `CityMap.tiles_of_type()`'s own order: the marks whose robber stands at the alley's far end,
## rather than in a courtyard past a passage. The director never needs the split; the sweeps here
## ask each kind its own question.
static func _through_alley_tiles(map: CityMap) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
		for rect in map.alley_rects:
			if rect.has_point(tile):
				tiles.append(tile)
				break
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
## `_nearest_alley_within()` needs to still offer a candidate (never a tile she can currently
## see, brisk-wombat's "the mark and its robber never appear in front of her"); standing
## at `far_alley` (beyond `NOTICE_RADIUS`, so certainly beyond the far narrower `SEEN_DISTANCE`)
## reproduces the distance. A single frame is enough to show the old bug is gone: the old rule
## pinned the mark on this exact frame, and the new one still relocates it.
func _test_an_onscreen_but_far_mark_is_not_seen_and_still_relocates(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		# The mark's own picture on screen and nothing else: its corners are 23px from its centre,
		# and its guard stands at least 62px from it, so a relocation is never held back for him.
		var near_the_mark := func(p: Vector2) -> bool: return p.distance_to(mark_at) < 30.0
		director.set_sight(near_the_mark, near_the_mark)

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
		var on_that_tile := func(p: Vector2) -> bool: return p.distance_to(raw_nearest) < 0.5
		director.set_sight(on_that_tile, on_that_tile)

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
## directly against `_draw_guard_position()`, the draw the roadblock's guard uses, with
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
## part of his 22x44px body on it either. The guard the roadblock's task sets at its contact when
## she reads the mark (`for_mark` false), asked of a contact just past the edge of her screen,
## never shows either.
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
		var through := _through_alley_tiles(map)
		for i in range(0, through.size(), 2):
			var her := map.tile_to_world(through[i])
			var screen := func(p: Vector2) -> bool:
				return absf(p.x - her.x) <= Tuning.VIEW_HALF_EXTENT.x \
						and absf(p.y - her.y) <= Tuning.VIEW_HALF_EXTENT.y
			director.set_sight(screen, screen)
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

## **A mark under a corner the joystick's controls cover is not in sight**, so its dwell does not run
## (dappled-swan, inbox #581: "use that everywhere where visibility is concerned -- for the other
## mode those rectangles *do* count"). She stands within `SEEN_DISTANCE` of the mark with it down and
## to her left, under the left corner, for longer than `SEEN_DWELL_SECONDS`, asked through the day's
## own visible area as `main` wires it: in the joystick scheme it is not noticed, in the tap scheme it
## is.
func _test_a_mark_under_a_covered_corner_is_not_noticed(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		for joystick: bool in [true, false]:
			var director := _director(t)
			director.start_day(6, _rng(6, "resistance"), 300.0)
			var mark_at := director.contact_position()
			# Camera look-ahead puts this nearby mark beneath the narrower focal-disc corner.
			# Keep her within the 150px notice distance independently of the camera centre.
			var her := mark_at + Vector2(135.0, -50.0)
			var view := VisibleView.around(her + Vector2(45.0, 0.0), joystick)
			t.check(view.sees(mark_at) != joystick,
					"the actual camera view covers the mark only in joystick mode")
			_city.events.visible_view().look(view.view, joystick)
			director.set_sight(_city.events.sees, _city.events.on_screen)
			var player := _rig_player(t, her)
			for i in ceili((ResistanceDirector.SEEN_DWELL_SECONDS + 0.5) / STEP):
				director._process(STEP)
			t.check(mark_at.distance_to(her) <= ResistanceDirector.SEEN_DISTANCE
					and director._seen != joystick,
					"%s scheme: a mark %.0fpx off under the left corner is %s"
					% ["joystick" if joystick else "tap", mark_at.distance_to(her),
					"not noticed" if joystick else "noticed"])
			player.free()
			director.free())

## **Nothing the resistance places or removes appears or vanishes under a covered corner** *(olive-
## hedgehog, inbox #598, the player: "off screen is not the same as visible -- the corners get
## removed for visible not for off screen" · "I don't want any pop in")*. Joystick scheme, asked
## through the day's own view as `main` wires it (`EventManager.sees()` for the notice,
## `EventManager.on_screen()` for placing and removing):
##
## - **A relocation whose only candidate lies under the bottom-left corner is refused.** Each alley
##   mouth of the test city in turn is made the only candidate, its mark's picture laid at several
##   places inside the corner, and every case kept where it is the answer both with no screen test
##   at all (legal ground, within `NOTICE_RADIUS`) and with the visible area alone (its guard's spot
##   is under the corner or out of the view too) — the case `main`'s wiring has to refuse.
## - **The neighbor taken with the raid stays while they stand under that corner**, and is taken
##   once the camera is off them.
func _test_nothing_appears_or_vanishes_under_a_covered_corner(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var events := _city.events
		var scale := Tuning.VIEW_HALF_EXTENT * 2.0 / ScreenOrientation.DESIGN_SIZE
		var corner := VisibleView.covered_left()
		var corner_at := corner.position * scale
		var corner_size := corner.size * scale
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var refused := 0
		var all_mouths := director._alley_mouths().duplicate()
		for tile: Vector2i in all_mouths:
			var mark := _city.map.tile_to_world(tile)
			var only: Array[Vector2i] = [tile]
			director._mouths = only
			director._mouths_of = _city.map
			# The mark's centre at these shares of the corner, its whole picture inside it.
			for share: Vector2 in [Vector2(0.2, 0.8), Vector2(0.5, 0.5), Vector2(0.8, 0.8),
					Vector2(0.2, 0.2), Vector2(0.8, 0.2)]:
				var view_at := mark - corner_at - share * corner_size
				var her := view_at + Tuning.VIEW_HALF_EXTENT
				events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), true)
				director.set_sight(Callable(), Callable())
				if director._nearest_alley_within(her).distance_to(mark) > 0.5:
					continue
				director.set_sight(events.sees, events.sees)
				if director._nearest_alley_within(her).distance_to(mark) > 0.5:
					continue
				refused += 1
				director.set_sight(events.sees, events.on_screen)
				t.check(director._nearest_alley_within(her) == Vector2.INF,
						"the only alley mouth, %s, under the covered corner is refused (%s of it)"
						% [tile, share])
		var none: Array[Vector2i] = []
		director._mouths = none
		t.check(refused > 0, "relocations under the covered corner were asked (%d)" % refused)
		director.free()

		var late := _director_on_the_neighbor(t)
		var walker := late._rider
		t.check(walker != null, "the neighbor is walking home")
		if walker:
			walker.is_parked = true
			late._process(STEP)
			t.check(late._taken_neighbor == walker, "reaching the door first, they are to be taken")
			var at := walker.global_position
			var view_at := at - corner_at - corner_size * 0.5
			events.visible_view().look(Rect2(view_at, Tuning.VIEW_HALF_EXTENT * 2.0), true)
			t.check(events.on_screen(at) and not events.sees(at),
					"the neighbor stands in the view, under the covered corner")
			late.set_sight(events.sees, events.on_screen)
			late._process(STEP)
			t.check(late._taken_neighbor == walker and is_instance_valid(walker)
					and not walker.is_finished,
					"under the covered corner, the neighbor is not taken where they are drawn")
			events.visible_view().look(Rect2(at + Vector2(Tuning.VIEW_HALF_EXTENT.x * 4.0, 0.0),
					Tuning.VIEW_HALF_EXTENT * 2.0), true)
			late._process(STEP)
			t.check(late._taken_neighbor == null, "once the camera is off them, they are taken")
		late.free())

## The other half of the same rule: near enough, for long enough, that walking away is a choice.
func _test_a_mark_seen_for_the_dwell_time_within_range_never_moves_again(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		var mark_at := director.contact_position()
		var everywhere := func(_p: Vector2) -> bool: return true
		director.set_sight(everywhere, everywhere)

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
func _test_the_guard_moves_with_the_mark_into_its_new_alley(t) -> void:
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
		var spot := director._guard_spot(new_at)
		t.check(spot != Vector2.INF, "the relocated mark's own alley is found")
		t.check(guard.global_position.distance_to(spot) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
				"the new guard stands in that alley, two-thirds through it or at its courtyard's " +
				"inner end, not in a band around the mark")

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
		var near_him := func(p: Vector2) -> bool: return p.distance_to(feet) < 40.0
		director.set_sight(near_him, near_him)
		director._process(STEP)
		t.check(director.contact_position().distance_to(old_at) < 0.5,
				"with him on her screen, the mark stays where it is")
		t.check(not guard.is_finished, "and he is not retired in front of her")

		var nothing := func(_p: Vector2) -> bool: return false
		director.set_sight(nothing, nothing)
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

## feathery-marmot, "a mark only ever sits at an alley's mouth" — *"Mouth only"* (the player,
## 2026-10-03, quiet-yak, inbox #486, asked whether a mark may sit in the middle of its alley). Over six cities, forty dawn
## draws each (`_place()`, the call `start_day()` makes) and a relocation asked from every
## twentieth alley tile and from a point 300px off it in four directions (`_nearest_alley_within()`,
## the call every move makes): every mark lands on a mouth, found here independently of the
## director — a through-alley's end tile along its long axis, or a passage tile beside ground that
## is neither alley nor courtyard. Before, the dawn draw was uniform over every alley tile, an end
## tile one draw in four, and a relocation took the nearest alley tile of any kind.
func _test_a_mark_only_ever_sits_at_an_alley_mouth(t) -> void:
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	GameState.completed_resistance_alley_tiles = []
	var mark_step := ResistanceSteps.by_index(1)
	var drawn := 0
	var drawn_at_a_mouth := 0
	var moved := 0
	var moved_to_a_mouth := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mark-mouth:%d" % seed_value)
		for _draw in 40:
			var at := director._place(mark_step, rng)
			if at == Vector2.INF:
				continue
			drawn += 1
			if _is_a_mouth(map, map.world_to_tile(at)):
				drawn_at_a_mouth += 1
		var alleys := map.tiles_of_type(GameEnums.TileType.ALLEY)
		for i in range(0, alleys.size(), 20):
			var origin := map.tile_to_world(alleys[i])
			for offset: Vector2 in [Vector2.ZERO, Vector2(300, 0), Vector2(-300, 0),
					Vector2(0, 300), Vector2(0, -300)]:
				var to := director._nearest_alley_within(origin + offset)
				if to == Vector2.INF:
					continue
				moved += 1
				if _is_a_mouth(map, map.world_to_tile(to)):
					moved_to_a_mouth += 1
		director.free()
	GameState.completed_resistance_alley_tiles = saved_tiles
	t.check(drawn > 0 and drawn_at_a_mouth == drawn,
			"every dawn mark is drawn at an alley's mouth (%d of %d)" % [drawn_at_a_mouth, drawn])
	t.check(moved > 0 and moved_to_a_mouth == moved,
			"and every relocation lands on one (%d of %d)" % [moved_to_a_mouth, moved])

## An alley's mouth, worked out from the map alone: the end tile of a through-alley along its long
## axis, or a courtyard passage's tile beside walkable ground that is neither alley nor courtyard.
static func _is_a_mouth(map: CityMap, tile: Vector2i) -> bool:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			var vertical := rect.size.y >= rect.size.x
			var along := tile.y - rect.position.y if vertical else tile.x - rect.position.x
			var length := rect.size.y if vertical else rect.size.x
			return along == 0 or along == length - 1
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var type := map.tile_at(tile + step)
		if map.is_walkable(tile + step) and type != GameEnums.TileType.ALLEY \
				and type != GameEnums.TileType.COURTYARD:
			return true
	return false

## feathery-marmot, "the robber stands two-thirds through the alley" — *"the robber should be
## 2/3rds through the alley not pressed against the edge of it"* (minty-hedgehog, statement 3) and,
## for an alley too short for that and 176px from the mark both, *"Two-thirds wins"* (quiet-yak, inbox #471).
## Over every through-alley tile of six cities, the guard `_guard_position()` stands for a mark
## (the placement `_maybe_set_a_trap()` and every relocation make) is on the alley's own axis,
## two-thirds of its length from the edge nearer the mark — or, where that point is within 62px of
## the mark (his catch and the touch reach), 62px past the mark. Every alley here is one block
## long, so this is the short case on every mark: he stands two-thirds in although that is under
## 176px from the mark, which the test counts so it is not vacuous. Before, he stood at the far end
## tile or up to three tiles in from it, at least 176px from the mark where the alley allowed.
func _test_the_chalk_mark_guard_stands_two_thirds_through_its_alley(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var checked := 0
	var under_the_trigger := 0
	var distances: Array[float] = []
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("guard-two-thirds:%d" % seed_value)
		for tile in _through_alley_tiles(map):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			# The alley's two end tiles in the mark's own row or column, nearer first; its edges
			# are half a tile beyond them.
			var ends := director._alley_ends(mark)
			t.check(ends.size() == 2, "seed %d: the mark at %s has its alley's two ends"
					% [seed_value, tile])
			if ends.size() != 2:
				continue
			var guard_at := director._guard_position(rng, mark, true, Vector2.INF, false)
			if guard_at == Vector2.INF:
				continue
			checked += 1
			var axis := (ends[1] - ends[0]).normalized()
			var near_edge := ends[0] - axis * Tuning.TILE_SIZE * 0.5
			var length := ends[0].distance_to(ends[1]) + Tuning.TILE_SIZE
			var two_thirds := near_edge + axis * length * 2.0 / 3.0
			var catch_floor := mark + axis * min_distance
			var expected := two_thirds
			if (two_thirds - near_edge).dot(axis) < (catch_floor - near_edge).dot(axis):
				expected = catch_floor
			t.check(guard_at.distance_to(expected) < 0.5,
					("seed %d: the guard for the mark at %s stands two-thirds through its alley, " +
					"or 62px past the mark where that is nearer (%s, wanted %s)")
					% [seed_value, tile, guard_at, expected])
			t.check(guard_at.distance_to(mark) >= min_distance - 0.5,
					"seed %d: and never within %.0fpx of the mark at %s"
					% [seed_value, min_distance, tile])
			if guard_at.distance_to(mark) < max_distance:
				under_the_trigger += 1
			distances.append(mark.distance_to(guard_at))
		director.free()
	t.check(checked > 0, "some mark was actually checked (%d)" % checked)
	t.check(under_the_trigger > 0,
			("the short case is met: two-thirds wins under %.0fpx of the mark on %d of %d marks")
			% [max_distance, under_the_trigger, checked])
	var all_equal := true
	for distance in distances:
		if not is_equal_approx(distance, distances[0]):
			all_equal = false
	t.check(distances.size() >= 2 and not all_equal,
			"the guard's own distance from the mark still varies from mark to mark")

## The long case of the same rule: where an alley is long enough for its two-thirds point to be
## 176px or more from the mark (his 140px `pursues_within` and `ContactPoint.REACH`), he stands
## there, and walking in from the mark's own end to read it and back out never wakes him. No city
## has an alley that long — every one is a block, 8 tiles — so the test carves one, 16 tiles, into a
## generated map's own grid and registers it as a through-alley, and reads a mark on its first
## tile.
func _test_a_long_alleys_robber_stands_two_thirds_in_past_his_trigger(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var map := CityGenerator.generate(13)
	var rect := Rect2i()
	for x in range(4, map.size.x - 6):
		var candidate := Rect2i(Vector2i(x, 4), Vector2i(Tuning.ALLEY_WIDTH_TILES, 16))
		var clear := true
		for alley in map.alley_rects:
			if alley.intersects(candidate.grow(1)):
				clear = false
		for tile in map.rect_tiles(candidate.grow(1)):
			if map.is_on_home_block(tile) or map.is_held_at(tile) or map.is_closed(tile):
				clear = false
				break
		if clear:
			rect = candidate
			break
	t.check(rect.has_area(), "there is ground on the test map to carve a long alley into")
	if not rect.has_area():
		return
	for tile in map.rect_tiles(rect):
		map.set_tile(tile, GameEnums.TileType.ALLEY)
	map.alley_rects.append(rect)
	var director := ResistanceDirector.new()
	director.setup(null, map)
	var mark := map.tile_to_world(rect.position)
	var length := float(rect.size.y * Tuning.TILE_SIZE)
	var near_edge := mark - Vector2(0.0, Tuning.TILE_SIZE * 0.5)
	var guard_at := director._guard_position(RandomNumberGenerator.new(), mark, true,
			Vector2.INF, false)
	t.check(guard_at.distance_to(near_edge + Vector2.DOWN * length * 2.0 / 3.0) < 0.5,
			"in a %.0fpx alley he stands two-thirds through it (%s)" % [length, guard_at])
	t.check(guard_at.distance_to(mark) >= max_distance,
			"which is %.0fpx from the mark, past his own trigger and the touch reach (%.0fpx)"
			% [guard_at.distance_to(mark), max_distance])
	var outside := near_edge + Vector2.UP * Tuning.TILE_SIZE
	var touch := mark + Vector2.UP * (ContactPoint.REACH - 2.0)
	t.check(_stays_asleep_walking_in_and_out(robbery, guard_at, outside, touch),
			"and walking in from the mark's own end to read it and back out never wakes him")
	director.free()

## The floor the player's "Two-thirds wins" left standing: reading a mark never lands her inside
## his catch (`EventDef.lethal_reach()`). Over every through-alley tile of six cities, she walks in
## from a tile and a half outside the alley's near end to `ContactPoint.REACH` less two pixels short
## of the mark and back out, past a still robber where `_guard_position()` stands him, and is never
## within his catch of him. Whether he wakes on the way is counted and not held: in a one-block alley
## reading the mark may wake him, and that is the player's choice.
func _test_reading_a_mark_never_lands_her_in_his_catch(t) -> void:
	var robbery := EventCatalogue.by_id("alley_robbery")
	var checked := 0
	var asleep := 0
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("mark-catch:%d" % seed_value)
		for tile in _through_alley_tiles(map):
			if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
				continue
			var mark := map.tile_to_world(tile)
			var ends := director._alley_ends(mark)
			var guard_at := director._guard_position(rng, mark, true, Vector2.INF, false)
			if ends.is_empty() or guard_at == Vector2.INF:
				continue
			checked += 1
			var axis := (ends[1] - ends[0]).normalized()
			var outside := ends[0] - axis * Tuning.TILE_SIZE * 1.5
			var touch := mark - axis * (ContactPoint.REACH - 2.0)
			var nearest := INF
			var steps := ceili(outside.distance_to(touch) / 4.0)
			for s in steps + 1:
				nearest = minf(nearest, outside.lerp(touch, float(s) / float(steps)).distance_to(guard_at))
			t.check(nearest > robbery.lethal_reach(),
					("seed %d: reading the mark at %s from its own end comes no nearer than %.0fpx " +
					"to him, outside his %.0fpx catch") % [seed_value, tile, nearest,
					robbery.lethal_reach()])
			if _stays_asleep_walking_in_and_out(robbery, guard_at, outside, touch):
				asleep += 1
		director.free()
	t.check(checked > 0, "some guarded mark was actually checked (%d, %d left him asleep)"
			% [checked, asleep])

## A mark in a courtyard's passage — the `ALLEY` ground with no far end of its own — has its robber
## at the courtyard's inner end. *(2026-09-27, the player: "robber at inner end of the courtyard is
## fine. I encountered it in game and it worked well for me. you just have to lure the robber out
## first.")* Over six cities, for every passage tile: `_far_alley_mouth()` is the courtyard tile
## farthest from the mark, found here independently from `CityMap.courtyard_rects`; the guard the
## director draws stands inside that courtyard, within `FAR_END_REACH_IN` of that tile; and he is
## never within his catch (`EventDef.lethal_reach()`) of any point she can touch the mark from,
## `ContactPoint.REACH` around it. He may still wake as she reads it. Both the dawn draw and the
## relocation reach passage tiles, so the sweep is not vacuous.
func _test_a_courtyard_marks_guard_stands_at_the_courtyards_inner_end(t) -> void:
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	GameState.completed_resistance_alley_tiles = []
	var robbery := EventCatalogue.by_id("alley_robbery")
	var min_distance: float = robbery.inner_radius + ContactPoint.REACH
	var max_distance: float = robbery.pursues_within + ContactPoint.REACH
	var passages := 0
	var guarded := 0
	var drawn_in_a_passage := 0
	var relocated_to_a_passage := 0
	var mark_step := ResistanceSteps.by_index(1)
	for seed_value in [4242, 90210, 2295276695, 314159, 271828, 555555]:
		var map := CityGenerator.generate(seed_value)
		var director := ResistanceDirector.new()
		director.setup(null, map)
		var through := _through_alley_tiles(map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("courtyard-inner-end:%d" % seed_value)
		for tile in map.tiles_of_type(GameEnums.TileType.ALLEY):
			if tile in through:
				continue
			passages += 1
			var mark := map.tile_to_world(tile)
			var court := Rect2i()
			for rect in map.courtyard_rects:
				if _passage_leads_into(map, tile, rect):
					court = rect
			t.check(court.has_area(), "seed %d: the passage at %s leads into a courtyard"
					% [seed_value, tile])
			var farthest := -1.0
			for y in range(court.position.y, court.end.y):
				for x in range(court.position.x, court.end.x):
					farthest = maxf(farthest, mark.distance_to(map.tile_to_world(Vector2i(x, y))))
			var far := director._far_alley_mouth(mark)
			t.check(far != Vector2.INF and absf(mark.distance_to(far) - farthest) < 0.5
					and court.has_point(map.world_to_tile(far)),
					"seed %d: the mark at %s has the courtyard's farthest tile as its inner end"
					% [seed_value, tile])
			var guard_at := director._draw_guard_position_near_far_mouth(rng, mark, far,
					min_distance, max_distance, [], Vector2.INF, 0.0, false)
			if guard_at == Vector2.INF:
				continue
			guarded += 1
			t.check(court.has_point(map.world_to_tile(guard_at))
					and guard_at.distance_to(far) <= ResistanceDirector.FAR_END_REACH_IN + 0.5,
					"seed %d: the guard for the mark at %s stands at the courtyard's inner end"
					% [seed_value, tile])
			t.check(guard_at.distance_to(mark) - ContactPoint.REACH > robbery.lethal_reach(),
					"seed %d: and no touch of the mark at %s lands her inside his %.0fpx catch"
					% [seed_value, tile, robbery.lethal_reach()])
			var nearest := director._nearest_alley_within(mark)
			if nearest != Vector2.INF and map.world_to_tile(nearest) not in through:
				relocated_to_a_passage += 1
		for _draw in 40:
			var at := director._place(mark_step, rng)
			if at != Vector2.INF and map.world_to_tile(at) not in through:
				drawn_in_a_passage += 1
		director.free()
	GameState.completed_resistance_alley_tiles = saved_tiles
	t.check(passages > 0 and guarded == passages,
			"every courtyard passage mark is guarded (%d of %d)" % [guarded, passages])
	t.check(drawn_in_a_passage > 0 and relocated_to_a_passage > 0,
			"marks are drawn (%d) and relocated (%d) into courtyard passages"
			% [drawn_in_a_passage, relocated_to_a_passage])

## Whether the passage `tile` is on runs straight into `court` — the courtyard it opens onto.
func _passage_leads_into(map: CityMap, tile: Vector2i, court: Rect2i) -> bool:
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var at := tile
		while map.tile_at(at) == GameEnums.TileType.ALLEY:
			at += step
		if court.has_point(at):
			return true
	return false

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
## `reach` is computed from the row's own `inner_radius` (26px, the always-lethal zone around
## whichever one of them it is) and the trap's own `min_distance` (62px, how close a guard is
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
				# `for_mark`) is `_guard_position()`'s alley placement — two-thirds through a
				# through-alley, the courtyard's inner end past a passage — not the check above:
				# checked here too, since standing him in the alley rather than in a band around
				# the mark is a different placement with no guarantee it inherits this one's.
				var mark_guard_rng := RandomNumberGenerator.new()
				mark_guard_rng.seed = hash("%d:far-guard:%d" % [seed_value, day])
				var mark_guard_at := director._guard_position(mark_guard_rng, mark_at, true,
						Vector2.INF, false)
				if mark_guard_at != Vector2.INF:
					checked += 1
					t.check(mark_guard_at.distance_to(doorstep) > reach,
							("seed %d day %d: the guard standing in the mark's own alley is " +
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
				# `for_mark`) is `_guard_position()`'s alley placement instead — two-thirds
				# through a through-alley, the courtyard's inner end past a passage — checked here
				# too, since it is a different placement with no guarantee it inherits this one's
				# own walled-alley refusal.
				if step.is_pickup:
					var mark_guard_rng := RandomNumberGenerator.new()
					mark_guard_rng.seed = hash("%d:far-guard:%d:%d:%d"
							% [seed_value, day, step.index, trial])
					var mark_guard_at := director._guard_position(mark_guard_rng, at, true,
							Vector2.INF, false)
					if mark_guard_at != Vector2.INF:
						var mark_guard_tile := city.map.world_to_tile(mark_guard_at)
						t.check(not city.map.is_in_walled_alley(mark_guard_tile, walled_alleys),
								("seed %d day %d step %d trial %d: the guard standing in the " +
								"mark's own alley is not inside a walled alley either")
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

## *(grassy-goose, inbox #556, asked which tasks switch to a robber arriving off screen: "Every
## guarded target (Recommended)", the option that keeps the roadblock's own guard.)* The roadblock
## is guarded exactly where it waits, like a chalk mark, and touching it sends nobody after her.
func _test_the_roadblock_keeps_a_waiting_guard(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var director := _director(t)
		director.start_day(13, _rng(13, "resistance"), 300.0)
		var mark_guard: EventInstance = director._guard
		director._on_contact_completed(15)
		var step := director.current_step()
		t.check(step != null and step.index == 16, "the roadblock perform is active")
		# feathery-marmot: a roadblock is touched from any side of its band, so its guard's band is
		# measured from the band's own centre with the whole of that touch — never nearer it than his
		# catch past the furthest point she can touch it from.
		var robbery := EventCatalogue.by_id("alley_robbery")
		var rider: EventInstance = director._rider
		if rider and director._task_guard:
			var touched_within := rider.def.solid_reach() + Tuning.PLAYER_BODY_RADIUS \
					+ ContactPoint.REACH
			var from_body := director._task_guard.global_position.distance_to(rider.body_position())
			t.check(from_body >= robbery.inner_radius + touched_within - 0.5,
					("the roadblock's guard stands %.0fpx from its band's centre, outside his catch " +
					"of everywhere it is touched from (%.0fpx)")
					% [from_body, robbery.inner_radius + touched_within])
		t.check(ResistanceDirector.keeps_a_waiting_guard(step)
				and not ResistanceDirector.sets_a_trap_on_her(step),
				"the roadblock's trap does not come to her")
		t.check(director._task_guard != null and is_instance_valid(director._task_guard),
				"it is guarded where it waits, like a mark, with its own fresh guard")
		if mark_guard:
			t.check(director._guard == mark_guard and not mark_guard.is_finished,
					"and the mark's own guard stays untouched, not retired for it")
			t.check(director._task_guard != mark_guard,
					"the perform's own guard is a distinct instance from the mark's")
		director._on_contact_completed(16)
		t.check(director._trap == null, "and touching it sends nobody after her")
		director.free())

## *(grassy-goose, inbox #556: "the robber should spawn in off-screen already pursuing when I touch
## the goal"; asked which tasks: "Every guarded target (Recommended)".)* The burnt building's door
## (day 8), the district door (day 9), a mast's foot (day 11), the swing (day 12) and the last
## night's front door: no robber waits at any of them — activating the task, or offering the last
## night's at dawn, adds none to the street — and doing it sends `robber_giving_chase` from off
## screen on the same terms as the man shouting's note, checked on each target's own ground (a
## door on a facade, a crossing in a region wall, a mast's foot, a swing in a park, the station's
## door): warned first, then just off screen, on legal ground, with a way at her that
## never runs through a district door, awake from his first frame, and catching her where she stands
## if she does nothing. Day 9's is measured from where the inspection lets her out, 54px past the
## door's line beside the gatehouse that held her, on each side in turn
## (`EventManager._release_finished_door_detentions()`), since that is where she stands when it
## sends him. Planned through the real day order (`City.start_day()`, then the events), since the
## door, the mast and the station's door are today's own plans.
func _test_every_guarded_target_sends_a_robber_from_off_screen(t) -> void:
	for day: int in [8, 9, 11, 12, Tuning.RUN_LENGTH_DAYS]:
		_build_city(t)
		var saved_scars := GameState.scars.duplicate(true)
		var saved_day := GameState.day
		var saved_state := GameState.city_state
		var saved_sabotage := GameState.sabotage_done
		var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
		GameState.scars.clear()
		GameState.day = day
		_with_clean_run(func() -> void:
			var finale := day == Tuning.RUN_LENGTH_DAYS
			GameState.completed_resistance_steps = _all_but_the_finale() if finale \
					else _completed_through(2 * (day - 6))
			GameState.resistance_progress = Tuning.RESISTANCE_GOAL if finale else 0
			GameState.sabotage_done = false
			var state := CityState.new()
			GameState.city_state = state
			state.begin_day(_city.map.block_plans, day)
			_city.start_day(state, day, _rng(day, "closures"))
			_city.events.start_day(day, _rng(day, "events"), [], _city.map.doorstep_world_position())
			var before := _robbers_on_the_street()
			var director := _director(t)
			director.start_day(day, _rng(day, "resistance"), 300.0)
			var offered := director.current_step()
			if offered and offered.is_pickup:
				director._on_contact_completed(offered.index)
			var task := director.current_step()
			t.check(task != null and not task.is_pickup,
					"day %d: the task is on offer" % day)
			if task == null:
				director.free()
				return
			t.check(ResistanceDirector.sets_a_trap_on_her(task)
					and not ResistanceDirector.keeps_a_waiting_guard(task),
					"day %d: a task whose trap comes to her" % day)
			var marks_guard := 1 if director._guard else 0
			t.check(director._task_guard == null
					and _robbers_on_the_street() == before + marks_guard,
					"day %d: no robber waits at the task (%d before dawn, %d now, the mark's %d)"
					% [day, before, _robbers_on_the_street(), marks_guard])
			t.check(director._trap == null, "day %d: nobody is sent before she does it" % day)

			var front_door := ResistanceDirector.is_at_a_front_door(task)
			if day == 9:
				_check_day_nines_trap_from_where_she_is_let_out(t, director, task)
				director.free()
				return
			# A door on a facade (the burnt building's, the station's) stands on the building's own
			# ground-floor tile, which nobody can stand on: she touches it from the sidewalk tile
			# straight below, inside its `DOOR_REACH`.
			var her := director.contact_position()
			if not _city.map.is_walkable(_city.map.world_to_tile(her)):
				her += Vector2(0.0, Tuning.TILE_SIZE)
			t.check(_city.map.is_walkable(_city.map.world_to_tile(her))
					and her.distance_to(director.contact_position()) <= director._contact.reach,
					"day %d: she stands on open ground within the touch's reach" % day)
			director.set_sight(_the_screen_round(her), _the_screen_round(her))
			var player := _rig_player(t, her)
			director._contact.complete_now()
			_check_the_trap_comes_from_off_screen(t, director, her, "robber_giving_chase",
					"day %d" % day, front_door)
			player.free()
			director.free())
		GameState.scars = saved_scars
		GameState.day = saved_day
		GameState.city_state = saved_state
		GameState.sabotage_done = saved_sabotage
		GameState.completed_resistance_alley_tiles = saved_tiles

## Day 9 let through the named door: she stands where the inspection sets her down — the gatehouse
## the arrow names, `obstructs_radius + PLAYER_BODY_RADIUS + CHECKPOINT_RELEASE_MARGIN` (54px) along
## the street past the door's line — first on one side, through the director's own `door_crossed`
## answer to an inspection, then on the other, sending the trap again from there. From each, the
## trap owes everything `_check_the_trap_comes_from_off_screen()` asks, his run at her through the
## door's line included.
func _check_day_nines_trap_from_where_she_is_let_out(t, director: ResistanceDirector,
		task: ResistanceSteps.Step) -> void:
	var hut: EventScheduler.Planned = null
	for body in _city.region_plan().door_bodies:
		if body.def.redetains and body.position.distance_to(director.contact_position()) < 0.5:
			hut = body
	t.check(hut != null and director._door_at != Vector2.INF,
			"day 9: the arrow names a gatehouse of the named door")
	if hut == null or director._door_at == Vector2.INF:
		return
	var out := hut.def.obstructs_radius + Tuning.PLAYER_BODY_RADIUS \
			+ Tuning.CHECKPOINT_RELEASE_MARGIN
	var player := _rig_player(t, hut.position)
	for side: float in [1.0, -1.0]:
		var her := hut.position + hut.facing * side * out
		t.check(_city.map.is_walkable(_city.map.world_to_tile(her)),
				"day 9: the ground she is let out onto is open (%s)" % _city.map.world_to_tile(her))
		player.global_position = her
		director.set_sight(_the_screen_round(her), _the_screen_round(her))
		director._trap = null
		if director._contact.is_done:
			director._set_the_trap_on_her(task)
		else:
			director._on_door_crossed(director._door_at, director._door_axis, true)
			t.check(director._contact.is_done, "day 9: an inspected crossing completes the task")
		var label := "day 9, let out %.0fpx along the street from the gatehouse" % (side * out)
		if _warning_for(_city.events, "robber_giving_chase") == null:
			_check_no_start_was_passed_over(t, director, her, label)
			continue
		_check_the_trap_comes_from_off_screen(t, director, her, "robber_giving_chase", label)
	player.free()

## When a done task sends nobody (`_set_the_trap_on_her()` found no start), none of the fixed starts
## — just out of sight straight above, straight below, and either side along her street
## (`_fixed_starts()`) — was legal ground whose run at her keeps out of the region's wall and doors,
## so the director passed over none it could have taken.
func _check_no_start_was_passed_over(t, director: ResistanceDirector, her: Vector2,
		label: String) -> void:
	var def := EventCatalogue.by_id("robber_giving_chase")
	var view := VisibleView.around(her)
	var boundary := director._boundary_bodies_near(her,
			ResistanceDirector.beside_distance(view, def, her))
	for candidate in _fixed_starts(def, her):
		t.check(not (ResistanceDirector.is_legal_ground(_city.map,
				_city.map.world_to_tile(candidate), director._walled_alleys())
				and not ResistanceDirector._runs_through_the_boundary(candidate, her, boundary)),
				"%s: nobody is sent, and no start %v off her was passed over" % [label, candidate - her])

## The four starts `_draw_arrival_position()` tries before any drawn bearing: just out of sight
## straight above and below her and either side along her street, with the camera on her.
static func _fixed_starts(def: EventDef, her: Vector2) -> Array[Vector2]:
	var view := VisibleView.around(her)
	var starts: Array[Vector2] = []
	for way: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		starts.append(PendingWarning.just_out_of_sight(view, def, her, way))
	return starts

## Runs the warning the trap row `row_id` is under to its end, frame by frame, with her standing at
## `her`, the way `EventManager._physics_process` runs it. Returns how long it was up, or `INF` when
## none was.
func _run_the_traps_warning(row_id: String, her: Vector2) -> float:
	var warning := _warning_for(_city.events, row_id)
	if warning == null:
		return INF
	while _city.events.pending_warnings().has(warning) and warning.shown < 5.0:
		_city.events._run_the_warnings(STEP, her)
	return warning.shown

## Camera smoothing can move the view while she stands still through a badge. The actual
## warning callback must place the entire drawing outside that new view in either input scheme.
func _test_a_trap_rechecks_the_camera_when_its_warning_expires(t) -> void:
	var saved_completed := GameState.completed_resistance_steps.duplicate()
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	for joystick: bool in [false, true]:
		GameState.completed_resistance_steps = []
		GameState.completed_resistance_alley_tiles = saved_tiles.duplicate()
		_build_city(t)
		var director := _director(t)
		director.start_day(6, _rng(6, "resistance"), 300.0)
		director._on_contact_completed(1)
		var her := director.contact_position()
		var player := Node2D.new()
		t.add_child(player)
		player.position = her
		player.add_to_group("player")
		var view := _city.events.visible_view()
		view.look(Rect2(her - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0), joystick)
		director.set_sight(_city.events.sees, _city.events.on_screen)
		director._set_the_trap_on_her(director.current_step())
		var warning := _warning_for(_city.events, "robber_giving_chase")
		t.check(warning != null and director._trap == null,
				"camera-only movement starts with a real warning and no trap")
		if warning != null:
			var initial := warning.place
			var bearing := (initial - her).normalized()
			view.look(Rect2(her + bearing * 30.0 - Tuning.VIEW_HALF_EXTENT,
					Tuning.VIEW_HALF_EXTENT * 2.0), joystick)
			_city.events._run_the_warnings(warning.left * 0.5, her)
			t.check(warning.place == initial and director._trap == null,
					"camera movement neither moves the badge nor creates its trap early")
			_city.events._run_the_warnings(warning.left + STEP, her)
			var trap: EventInstance = director._trap
			t.check(trap != null, "the shifted camera still leaves legal ground for the trap")
			if trap != null:
				trap.player_at = her
				var drawing := trap.drawn_rect_now()
				t.check(view.view.intersects(Rect2(initial + drawing.position, drawing.size)),
						"the camera moved far enough to expose a trap at the initial badge position")
				t.check(not view.view.intersects(Rect2(trap.position + drawing.position, drawing.size)),
						"warning expiry keeps the actual drawing outside the moved WHOLE camera")
				t.check((trap.position - her).normalized().is_equal_approx(bearing),
						"the trap keeps the badge's bearing when the camera moves")
		player.free()
		director.free()
	GameState.completed_resistance_steps = saved_completed
	GameState.completed_resistance_alley_tiles = saved_tiles

## A `_sight` answering the unrotated 640x360 screen round `her`.
func _the_screen_round(her: Vector2) -> Callable:
	return func(at: Vector2) -> bool:
		var off := (at - her).abs()
		return off.x <= Tuning.VIEW_HALF_EXTENT.x and off.y <= Tuning.VIEW_HALF_EXTENT.y

## What every trap owes from the moment it is sent, on the real city. **Warned first**: the moment she
## does it a warning for `row_id` is up with nothing in the world, and stays up alone for the row's own
## `EventDef.warned_for()`, at most `Tuning.WARNING_ALONE_MAX`; run out with her standing where she
## did it, `director._trap` is then a `row_id` started **just off screen** (everything he draws
## outside the camera's view about her) — above or below her, or beside her along her street, or at a
## front door from across the street, below her — on legal ground, never waiting, already chasing
## (amendment 7: "the proximity rule is only for standing robbers"), and coming at her from his first
## frame. **His run at her never crosses a
## district door's line**, asked here of each door body the way `EventManager._watch_the_door_lines()`
## asks it of her own steps (`EventManager.where_she_crossed()`), not through the director's own
## refusal. **A straight walkable run at her is a preference, not a guarantee**
## (`_draw_arrival_position()`'s own doc: with none from any start, the first legal one stands in):
## so with one — or from across the street, with his own walk at her (`_his_walk_reaches_her()`) — he
## catches her where she stands, and without one none of the fixed starts (`_fixed_starts()`) had one
## on legal ground either, so the director passed over no clear start it could have taken. Measured
## per target by `tests/probes/grassy_goose_target_traps.gd`. Returns where he started, or `INF`.
func _check_the_trap_comes_from_off_screen(t, director: ResistanceDirector, her: Vector2,
		row_id: String, label: String, front_door := false) -> Vector2:
	var warning := _warning_for(_city.events, row_id)
	t.check(warning != null and director._trap == null,
			"%s: the moment she does it, %s's warning is up with nothing in the world" % [label, row_id])
	if warning == null:
		return Vector2.INF
	t.check(warning.left <= Tuning.WARNING_ALONE_MAX + 0.001,
			"%s: for %.2fs alone, at most a second" % [label, warning.left])
	var shown := _run_the_traps_warning(row_id, her)
	var chaser: EventInstance = director._trap
	t.check(chaser != null and chaser.def.id == row_id,
			"%s: %s is sent after her once it is over (%.2fs)" % [label, row_id, shown])
	if chaser == null:
		return Vector2.INF
	var start := chaser.global_position
	var view := VisibleView.around(her)
	var beside := ResistanceDirector.beside_distance(view, chaser.def, her)
	var dist := start.distance_to(her)
	var boundary := director._boundary_bodies_near(her, beside)
	var sideways := absf(start.y - her.y) < 0.5
	var across := front_door and start.y > her.y and dist <= beside + 0.5 \
			and director._his_walk_reaches_her(start, her, beside, boundary)
	var cone := absf(absf((start - her).angle()) - PI / 2.0) <= ResistanceDirector.ARRIVAL_CONE + 0.01
	t.check(cone or sideways or across,
			"%s: above or below her within the cone, beside her, or across the street (%.1fpx, at %v)"
			% [label, dist, start - her])
	t.check(not chaser.is_telegraphing(), "%s: already chasing, with no closing-in first" % label)
	t.check(PendingWarning.is_out_of_sight(view, chaser.def, her, start),
			"%s: wholly out of sight the frame he exists" % label)
	var through_a_door := false
	var plan := _city.region_plan()
	for body: EventScheduler.Planned in plan.door_bodies if plan else []:
		if EventManager.where_she_crossed(body.position, body.facing, body.def.obstructs_radius,
				start, her) != Vector2.INF:
			through_a_door = true
	t.check(not through_a_door,
			"%s: his run at her from %s never crosses a district door's line"
			% [label, _city.map.world_to_tile(start)])
	t.check(ResistanceDirector.is_legal_ground(_city.map, _city.map.world_to_tile(start),
			director._walled_alleys()), "%s: on walkable ground nothing refuses" % label)
	var clear := director._a_clear_run(start, her)
	if not clear and not across:
		for candidate in _fixed_starts(chaser.def, her):
			t.check(not (ResistanceDirector.is_legal_ground(_city.map,
					_city.map.world_to_tile(candidate), director._walled_alleys())
					and director._a_clear_run(candidate, her)
					and not ResistanceDirector._runs_through_the_boundary(candidate, her, boundary)),
					"%s: with no clear run from %s, none from %v off her either"
					% [label, _city.map.world_to_tile(start), candidate - her])
	t.check(not chaser.is_waiting(), "%s: never waiting, even before his first frame" % label)
	chaser.player_at = her
	chaser._process(STEP)
	var closed := start.distance_to(her) - chaser.global_position.distance_to(her)
	t.check(closed > chaser.def.pursue_speed * STEP * 0.9 or (across and closed > 0.0),
			"%s: and coming at her%s from his first frame" % [label,
			"" if across else " at his own speed"])
	if not clear and not across:
		return start
	var caught := false
	var elapsed := 0.0
	while elapsed < chaser.def.telegraph_time + chaser.def.duration \
			and not chaser.is_finished and not caught:
		chaser.player_at = her
		chaser._process(STEP)
		elapsed += STEP
		caught = chaser.is_lethal_at(her)
	t.check(caught, "%s: and, with a %s, reaches her where she stands (%.1fs)"
			% [label, "walk from across the street" if across and not clear else "clear run",
			elapsed])
	return start

## Every robber or guard standing or running in the test city: the alley robber and the two the
## director can send after her.
func _robbers_on_the_street() -> int:
	var count := 0
	var ids := ["alley_robbery", "robber_giving_chase", "van_guard_giving_chase"]
	for instance in _city.events.instances():
		if instance.def.id in ids and not instance.is_finished:
			count += 1
	return count

## Whether `at` would actually be in sight with the camera on `her` and led toward `at` the way
## `Stroller` leads it when she faces what she is walking toward — the worst-case lead, since a
## start behind her would only pull the camera the other way. Asked of the tap scheme's
## `VisibleView`, whose whole view is what `EventManager.on_screen()` answers in either scheme — the
## test the director places against (`ResistanceDirector.set_sight()`, as `main` wires it): the
## joystick's covered corners only ever take ground out of sight, so a point out of the whole view
## is out of both.
func _is_really_on_screen(_t, her: Vector2, at: Vector2) -> bool:
	var bearing := at - her
	var lead := Vector2.ZERO
	if bearing.length() > 0.001:
		var dir := bearing.normalized()
		lead = Vector2(dir.x, dir.y * Stroller.OBLIQUE_Y) * Stroller.CAMERA_LOOK_AHEAD
	return VisibleView.around(her + lead).sees(at)

## *(PLAYTEST-71: "maybe spawn the robber in pursuing mode offscreen when she interacts with the
## yeller so it runs towards her from offscreen"; "we need a version of the robber that is not
## frozen when spawned"; M226: warned first, "1s warning should be enough".)* Handing the note over
## puts up one `robber_giving_chase`'s warning with nothing in the world, and once it is over sets
## him on her just out of sight, on legal ground, never waiting, and coming at her from the first
## frame he is stepped — everything `_check_the_trap_comes_from_off_screen()` asks.
##
## **Swept over `RULE_SEEDS` cities rather than trusted on one.** Every seed's handover replays to
## the same place, and the man she handed it to keeps shouting rather than leaving at once (M205).
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
				director.set_sight(_the_screen_round(her), _the_screen_round(her))
				var player := _rig_player(t, her)
				director._contact._physics_process(STEP)
				t.check(director._contact.is_done, "seed %d: she hands the note over" % seed_value)
				var start := _check_the_trap_comes_from_off_screen(t, director, her,
						"robber_giving_chase", "seed %d" % seed_value)
				if start != Vector2.INF:
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
## package over puts up one `van_guard_giving_chase`'s warning and then sets him on her, on the same
## terms as the robber. The van itself is a one-place task's own rider and never leaves when the
## package is picked up — `_on_contact_completed()` only sends the man shouting's own rider away by
## name.
func _test_the_van_handover_sets_a_guard_on_her_from_off_screen(t) -> void:
	var starts: Array[Vector2] = []
	var saved_tiles := GameState.completed_resistance_alley_tiles.duplicate()
	for attempt in 2:
		_build_city(t)
		GameState.completed_resistance_alley_tiles = saved_tiles.duplicate()
		_with_clean_run(func() -> void:
			var director := _director_on_the_van_perform(t)
			var her := director.contact_position()
			director.set_sight(_the_screen_round(her), _the_screen_round(her))
			var player := _rig_player(t, her)
			director._contact._physics_process(STEP)
			t.check(director._contact.is_done, "she hands the package over")
			var start := _check_the_trap_comes_from_off_screen(t, director, her,
					"van_guard_giving_chase", "the van")
			if start != Vector2.INF:
				if not starts.is_empty():
					t.close_to(start.distance_to(starts[0]), 0.0,
							"the same handover sends him from the same place", 0.01)
				starts.append(start)
			player.free()
			director.free())
	GameState.completed_resistance_alley_tiles = saved_tiles

## **He is warned of before he exists, the warning is short, and he arrives chasing.** *(Amendment 7
## of M226, the player: "why would the robber walk towards her when it spawns as pursuing robber? the
## proximity rule is only for standing robbers.")* A bare robber walked from each start the director
## draws — just off screen straight above and below her and at the edges of
## `ResistanceDirector.ARRIVAL_CONE`, and the along-her-street start beside her — the moment he is
## created there, his badge already spent and his telegraph with it:
##
## - **standing where she did it**, she is caught;
## - **walking into him**, she is caught, and turning to run `Tuning.PURSUIT_REACTION` after his badge
##   rises gets her away;
## - **walking away** is caught from every start, beside her included — no pursuer gives up on a
##   walker (amendment 8: `Tuning.PURSUIT_TIME` is a long cap), so walking has to lose;
## - **running** shakes him off while still unseen, before its cost can make an awake baby cry.
##
## The tall-osprey floor (standing still, a robber lunges no sooner than `Tuning.PURSUIT_MIN_NOTICE`
## after he appears) is a standing robber's, a mark's guard waiting in his alley, whom this build does
## not touch; a sent one has no closing-in for it to bound.
func _test_the_robber_after_her_is_announced_before_he_can_catch_her(t) -> void:
	_assert_a_trap_row_is_announced_before_it_can_catch_her(t, "robber_giving_chase")

## The same contract for the van's own guard: walks the guard's own row and asserts the same
## relationships rather than assuming the robber's numbers carry over unchecked.
func _test_the_van_guard_after_her_is_announced_before_he_can_catch_her(t) -> void:
	_assert_a_trap_row_is_announced_before_it_can_catch_her(t, "van_guard_giving_chase")

## Shared between the man shouting's row and the van's: each of this suite's two callers passes
## its own catalogue id, since the contract this checks is the same row-independent relationship
## for both.
func _assert_a_trap_row_is_announced_before_it_can_catch_her(t, id: String) -> void:
	var def := EventCatalogue.by_id(id)
	t.check(def.warns_before_it_exists() and def.warned_for() <= Tuning.WARNING_ALONE_MAX
			and def.arrives_chasing,
			"he is warned of before he exists, for %.2fs alone, and arrives chasing" % def.warned_for())
	var her := Vector2.ZERO
	var view_on_her := VisibleView.around(her)
	var edge_of_cone := ResistanceDirector.ARRIVAL_CONE - 0.001
	var starts: Array[Vector2] = [
			PendingWarning.just_out_of_sight(view_on_her, def, her, Vector2.DOWN),
			PendingWarning.just_out_of_sight(view_on_her, def, her, Vector2.UP),
			PendingWarning.just_out_of_sight(view_on_her, def, her, Vector2.DOWN.rotated(edge_of_cone)),
			PendingWarning.just_out_of_sight(view_on_her, def, her, Vector2.UP.rotated(-edge_of_cone)),
			PendingWarning.just_out_of_sight(view_on_her, def, her, Vector2.RIGHT)]
	for start in starts:
		t.check(PendingWarning.is_out_of_sight(view_on_her, def, her, start),
				"from %v: wholly off screen the frame he exists" % start)
		var stood := _walk_the_trap(def, start, 0.0)
		t.check(stood["caught_at"] < INF,
				"from %v: standing still is caught (%.2fs)" % [start, stood["caught_at"]])
		var into := _walk_the_trap(def, start, Tuning.WALK_SPEED)
		t.check(into["caught_at"] < INF, "from %v: walking into him is caught" % start)
		# The badge went up `warned_for()` before he exists, so a turn `PURSUIT_REACTION` after the
		# badge is that much less after he appears.
		var turned := _walk_the_trap(def, start, Tuning.WALK_SPEED,
				maxf(0.0, Tuning.PURSUIT_REACTION - def.warned_for()))
		t.check(turned["caught_at"] == INF and turned["gave_up"],
				"from %v: walking into him and turning to run %.1fs after the badge gets away"
				% [start, Tuning.PURSUIT_REACTION])
		var away := _walk_the_trap(def, start, -Tuning.WALK_SPEED)
		t.check(away["caught_at"] < INF,
				"from %v (%.0fpx): walking straight away is caught (%.2fs)"
				% [start, start.length(), away["caught_at"]])
		var ran := _walk_the_trap(def, start, -Tuning.RUN_SPEED)
		t.check(ran["caught_at"] == INF and ran["gave_up"] and not ran["cried"],
				"from %v: running shakes him off before either catch or crying" % start)
		if is_zero_approx(start.x):
			t.check(ran["first_seen"] == INF,
					"from %v: the immediate run escapes while he remains offscreen" % start)
		t.check(ran["excitement"] > 0.0 and ran["excitement"] < Tuning.METER_MAX * 0.3,
				"from %v: the actual awake Baby pays an affordable %.2f points for running"
				% [start, ran["excitement"]])

## Walks her at `speed` along the line to `start` — positive toward him, negative away — against a
## bare instance of `def` (`robber_giving_chase` or `van_guard_giving_chase`) created at `start`
## from her, the moment his warning is over, as `EventManager.spawn_warned()` creates him: already
## chasing. A walk is under way when he appears (the handover does not stop her); a run
## gets up to speed at `Tuning.ACCELERATION`. `turn_to_run_after`, if given, reverses her into a run
## away from him that many seconds after he appears. The real Baby charges this run, awake at zero
## excitement with no world noise or recovery; crying ends the attempt rather than counting as escape.
func _walk_the_trap(def: EventDef, start: Vector2, speed: float, turn_to_run_after := INF) -> Dictionary:
	var bearing := start.normalized()
	var robber := EventInstance.new()
	robber.setup(def, start)
	robber.came_under_a_warning = true
	if def.arrives_chasing:
		robber.resume(EventManager.age_when_warned(def), 0.0)
	var stroller := Stroller.new()
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby._stroller = stroller
	var result := {"caught_at": INF, "at_the_lunge": INF, "lunged_at": INF, "gave_up": false,
			"ended": false, "first_seen": INF, "cried": false, "excitement": 0.0}
	var her := Vector2.ZERO
	var velocity := speed if absf(speed) <= Tuning.WALK_SPEED else 0.0
	var elapsed := 0.0
	var was_telegraphing := true
	while elapsed < def.telegraph_time + def.duration + 1.0:
		var wanted := speed
		if elapsed >= turn_to_run_after:
			wanted = -Tuning.RUN_SPEED
		velocity = move_toward(velocity, wanted, Tuning.ACCELERATION * STEP)
		her += bearing * velocity * STEP
		stroller.position = her
		stroller.velocity = bearing * velocity
		baby._physics_process(STEP)
		robber.player_at = her
		robber.player_running = absf(velocity) > Tuning.WALK_SPEED
		var box := robber.drawn_box()
		var in_sight := VisibleView.around(her).sees_any(
				Rect2(robber.global_position + box.position, box.size))
		if in_sight and result["first_seen"] == INF:
			result["first_seen"] = elapsed
		robber._process(STEP)
		elapsed += STEP
		var offset := robber.global_position - her
		if was_telegraphing and not robber.is_telegraphing():
			result["at_the_lunge"] = offset.length()
			result["lunged_at"] = elapsed
			was_telegraphing = false
		if robber.is_lethal_at(her):
			result["caught_at"] = elapsed
			break
		if baby.state == GameEnums.BabyState.CRYING:
			result["cried"] = true
			break
		if robber.gave_up or robber.is_finished or robber.is_leaving:
			result["gave_up"] = robber.gave_up
			result["ended"] = true
			break
	result["excitement"] = baby.excitement
	stroller.free()
	robber.free()
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
## second one that day. It stands on the open tile nearest 600px east of the rider, never inside
## a building: a source deep in a building is shut out by the wall even at its own position
## (`CityMap.wall_between()`), and nothing the city places ever stands there.
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
				DevRig.nearest_walkable(_city.map, rider.global_position + Vector2(600.0, 0.0)))
		t.check(_city.map.is_walkable(_city.map.world_to_tile(decoy.global_position))
				and decoy.global_position.distance_to(rider.global_position) > 400.0,
				"the look-alike stands on open ground, well away from the one she reached")

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
	# On ground day 3's fire can actually catch on (`AT_THE_FRONT`, a building behind it), since a
	# real scar is only ever recorded there and the arrow ends on that building.
	var doorstep := _city.map.doorstep_world_position()
	var near_fronts: Array[Vector2i] = []
	var far_fronts: Array[Vector2i] = []
	for tile in EventScheduler._open_ground_for(EventCatalogue.by_id("burning_building"),
			_city.map, {}):
		var distance := _city.map.tile_to_world(tile).distance_to(doorstep)
		if distance < Tuning.EVENT_STREAM_RADIUS:
			near_fronts.append(tile)
		elif distance > Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS:
			far_fronts.append(tile)
	t.check(not near_fronts.is_empty(), "home has fronts within streaming range")
	t.check(not far_fronts.is_empty(), "and fronts beyond it")
	if near_fronts.is_empty() or far_fronts.is_empty():
		return
	_ride_a_recorded_scar(t, near_fronts[near_fronts.size() / 2], "a scar near home")
	# The case a real run makes most: a dusk fire is sited at least `EVENT_STREAM_RADIUS` from
	# where she finished day 3, so its shell is not in the world when she reads day 8's mark.
	_ride_a_recorded_scar(t, far_fronts[far_fronts.size() / 2], "a scar beyond streaming range")

## Records a day-3 scar at `site`, plans day 8 around the doorstep, reads day 8's mark there, and
## checks the task rides that scar: the one shell at it, put in the world even when the scar is
## farther than the streaming radius, kept there when she walks away, no second scar recorded, and
## the arrow and the contact on the door of the building behind it.
func _ride_a_recorded_scar(t, site: Vector2i, label: String) -> void:
	_with_clean_run(func() -> void:
		var saved_scars := GameState.scars.duplicate()
		var doorstep := _city.map.doorstep_world_position()
		var scar_at := _city.map.tile_to_world(site)
		GameState.scars = [{"id": "burnt_shell", "position": scar_at, "since_day": 3}]
		# `_place_scars()` plans a `burnt_shell` at `scar_at` for the day; it is in the world only
		# if `scar_at` is inside the streaming radius of the doorstep.
		_city.events.start_day(8, _rng(8, "events"), [], doorstep)

		var director := _director(t)
		director.start_day(8, _rng(8, "resistance"), 300.0)
		director._on_contact_completed(5)
		t.check(director.current_step() != null and director.current_step().index == 6,
				"%s: touching day 8's mark activates the burnt-shell perform" % label)
		t.check(director._rider != null and director._rider.def.id == "burnt_shell",
				"%s: riding a burnt_shell instance" % label)
		if director._rider == null:
			director.free()
			GameState.scars = saved_scars
			return
		t.check(director._rider.global_position.distance_to(scar_at) < 1.0,
				"%s: the one standing at the run's own recorded scar" % label)
		t.check(GameState.scars.size() == 1,
				"%s: and no second scar is recorded for the task (%s)" % [label, GameState.scars])
		_check_the_task_is_at_the_burnt_buildings_door(t, director)

		# She walks off across the city: the shell stays under its contact.
		_city.events.stream_around(scar_at + Vector2(1.0, 1.0) * 4.0
				* (Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_STREAM_HYSTERESIS))
		# `instances()` rather than `rider_alive()` alone: a streamed-out instance is only queued
		# for deletion, and still valid until the frame ends.
		t.check(director._contact.rider_alive()
				and _city.events.instances().has(director._rider),
				"%s: the shell stays in the world when she walks far away from it" % label)
		# And back: still one shell there, so its field is counted once.
		_city.events.stream_around(scar_at)
		var shells := 0
		for instance in _city.events.instances():
			if instance.def.id == "burnt_shell" \
					and instance.global_position.distance_to(scar_at) < 1.0:
				shells += 1
		t.check(shells == 1, "%s: one shell at the scar, not two (%d)" % [label, shells])
		_check_a_touch_from_the_near_half_of_the_sidewalk(t, director)

		director.free()
		GameState.scars = saved_scars)

## Day 8's red arrow ends on the burnt building's door, and the task's contact stands there too:
## *"or better to the door but the acceptance radius centered at the door should have a large
## enough radius for half the sidewalk to be covered"* (sandy-egret). The shell has no body and
## draws nothing, so its own position is bare sidewalk. The door is read off the building behind the
## shell (the lot `City` draws burnt) independently of `Building.way_in_local_x()`: its entrance
## door's column centre when it has one, half a tile up its ground floor.
func _check_the_task_is_at_the_burnt_buildings_door(t, director: ResistanceDirector) -> void:
	var tip := director.red_arrow_target()
	t.check(tip != Vector2.INF, "day 8's task earns the red arrow")
	if tip == Vector2.INF or director._rider == null:
		return
	t.check(tip == director.contact_position(),
			"the arrow's tip %s is where the task's contact stands %s"
			% [tip, director.contact_position()])
	var shell_tile := _city.map.world_to_tile(director._rider.global_position)
	var behind: Building = null
	for building in _city._buildings:
		if building.lot.has_point(shell_tile + Vector2i.UP):
			behind = building
	t.check(behind != null, "the shell at %s has a building behind it" % shell_tile)
	if behind == null:
		return
	var lot := _city.map.tile_rect_to_world(behind.lot)
	var size := float(Tuning.TILE_SIZE)
	t.close_to(tip.y, lot.end.y - size * 0.5,
			"the tip is half a tile up that building's ground floor", 0.01)
	var door_col := behind.entrance_door_col()
	if door_col >= 0:
		t.close_to(tip.x, lot.position.x + (door_col + 0.5) * size,
				"and on its entrance door, column %d of %s" % [door_col, behind.lot], 0.01)
	else:
		t.check(tip.x >= lot.position.x and tip.x <= lot.end.x,
				"and on its own front, which has no entrance door (%s)" % behind.lot)

## The contact at the door completes from the near half of the sidewalk in front of it — the whole
## tile below the door, out to its bottom corners — and not from its far half or past it. Called
## last, since the touch that completes it hands the task over; the two corner touches are asked of
## copies of the contact, with its own position and reach, so they hand nothing over.
func _check_a_touch_from_the_near_half_of_the_sidewalk(t, director: ResistanceDirector) -> void:
	var contact := director._contact
	var door := director.contact_position()
	if contact == null or door == Vector2.INF:
		t.check(false, "day 8's task has a contact to touch")
		return
	var foot := door + Vector2.DOWN * Tuning.TILE_SIZE * 0.5
	var sidewalk := float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
	var near := foot + Vector2.DOWN * (sidewalk * 0.5 - 4.0)
	var far := foot + Vector2.DOWN * (sidewalk * 0.5 + 4.0)
	var past := foot + Vector2.DOWN * (sidewalk + Tuning.TILE_SIZE * 0.5)
	t.check(_city.map.tile_at(_city.map.world_to_tile(near)) == GameEnums.TileType.SIDEWALK
			and _city.map.tile_at(_city.map.world_to_tile(far)) == GameEnums.TileType.SIDEWALK,
			"the two halves in front of the door at %s are sidewalk" % door)
	var player := _rig_player(t, past)
	contact._player = player
	contact._physics_process(STEP)
	t.check(not contact.is_done, "a touch from past the sidewalk, %.0fpx from the door, does not"
			% door.distance_to(past))
	player.global_position = far
	contact._physics_process(STEP)
	t.check(not contact.is_done, "nor one from the far half, %.0fpx from the door"
			% door.distance_to(far))
	for side in [-1.0, 1.0]:
		var corner := foot + Vector2(side * (Tuning.TILE_SIZE * 0.5 - 1.0),
				sidewalk * 0.5 - 1.0)
		var copy := ContactPoint.new()
		copy.ride(contact.step, contact._rider, contact._rider_offset)
		copy.reach = contact.reach
		t.add_child(copy)
		copy.set_physics_process(false)
		copy._player = player
		player.global_position = corner
		copy._physics_process(STEP)
		t.check(copy.is_done,
				("a touch from a bottom corner of the tile below the door, %.1fpx from it, " +
				"completes it") % door.distance_to(corner))
		copy.free()
	player.global_position = near
	contact._physics_process(STEP)
	t.check(contact.is_done, "a touch from the near half, %.0fpx from the door, completes it"
			% door.distance_to(near))
	player.free()

## Every front day 3's fire can catch on, and so every place day 8's task can end, has a way in on
## the building behind it (`City.way_in_behind()`): its entrance door's column when it has one, and
## always ground the touch is measured over — a sidewalk tile straight below it, the near half
## `ResistanceDirector.DOOR_REACH` is sized to.
func _test_every_front_the_fire_catches_on_has_a_door_on_a_sidewalk(t) -> void:
	_build_city(t)
	var size := float(Tuning.TILE_SIZE)
	var fronts := EventScheduler._open_ground_for(EventCatalogue.by_id("burning_building"),
			_city.map, {})
	var on_a_door := 0
	var wrong: Array[Vector2i] = []
	for tile in fronts:
		var way := _city.way_in_behind(_city.map.tile_to_world(tile))
		var behind: Building = null
		for building in _city._buildings:
			if building.lot.has_point(tile + Vector2i.UP):
				behind = building
		if behind == null or way == Vector2.INF:
			wrong.append(tile)
			continue
		var lot := _city.map.tile_rect_to_world(behind.lot)
		var below := _city.map.world_to_tile(way) + Vector2i.DOWN
		var ok := absf(way.y - (lot.end.y - size * 0.5)) < 0.01 \
				and _city.map.tile_at(below) == GameEnums.TileType.SIDEWALK
		var door_col := behind.entrance_door_col()
		if door_col >= 0:
			on_a_door += 1
			ok = ok and absf(way.x - (lot.position.x + (door_col + 0.5) * size)) < 0.01
		if not ok:
			wrong.append(tile)
	t.check(on_a_door > fronts.size() / 2,
			"most fronts have an entrance door behind them (%d of %d)" % [on_a_door, fronts.size()])
	t.check(wrong.is_empty(),
			"every front's way in is on its building's door, over a sidewalk (%d are not, first %s)"
			% [wrong.size(), wrong.slice(0, 3)])

## A run with no recorded `burnt_shell` scar (a `--day 8` start, or a day 3 that never burned)
## still sends her to a burnt building: the shell stands on a front day 3's fire could have caught
## on, the scar is recorded there, and the building behind it is burnt at once — *"Take what's in
## the stroller to the burnt building"* never leads to bare sidewalk.
func _test_the_burnt_shell_task_falls_back_with_no_recorded_scar(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var saved_scars := GameState.scars.duplicate()
		GameState.scars.clear()
		var burnt_before := 0
		var conditions: Array[int] = []
		for building in _city._buildings:
			conditions.append(building.condition)
			if building.condition == Building.Condition.BURNT:
				burnt_before += 1

		var director := _director(t)
		director.start_day(8, _rng(8, "resistance"), 300.0)
		t.check(GameState.scars.is_empty(), "nothing is burnt for the task before her mark is read")
		director._on_contact_completed(5)
		t.check(director.current_step() != null and director.current_step().index == 6,
				"touching day 8's mark still activates the burnt-shell perform")
		t.check(director._rider != null and director._rider.def.id == "burnt_shell",
				"riding a burnt_shell instance placed for the task")
		t.check(director.contact_position() != Vector2.INF, "somewhere reachable")
		if director._rider == null:
			director.free()
			GameState.scars = saved_scars
			return

		var shell := director._rider.global_position
		var shell_tile := _city.map.world_to_tile(shell)
		var fronts := EventScheduler._open_ground_for(EventCatalogue.by_id("burning_building"),
				_city.map, {})
		t.check(shell_tile in fronts,
				"the shell stands at %s, a front day 3's fire could have caught on" % shell_tile)
		var recorded := 0
		for scar: Dictionary in GameState.scars:
			if String(scar["id"]) == "burnt_shell" \
					and (scar["position"] as Vector2).distance_to(shell) < 1.0:
				recorded += 1
		t.check(GameState.scars.size() == 1 and recorded == 1,
				"the scar is recorded where the shell stands, and nothing else (%s)"
				% [GameState.scars])
		var behind: Building = null
		var burnt_now := 0
		for building in _city._buildings:
			if building.lot.has_point(shell_tile + Vector2i.UP):
				behind = building
			if building.condition == Building.Condition.BURNT:
				burnt_now += 1
		t.check(behind != null and behind.condition == Building.Condition.BURNT,
				"the building behind the shell is burnt the moment the task is on offer")
		t.check(burnt_now == burnt_before + 1,
				"and no other building is (%d burnt, %d before)" % [burnt_now, burnt_before])
		_check_the_task_is_at_the_burnt_buildings_door(t, director)
		_check_a_touch_from_the_near_half_of_the_sidewalk(t, director)

		director.free()
		for i in _city._buildings.size():
			_city._buildings[i].condition = conditions[i] as Building.Condition
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
		for body in _city.region_plan().door_bodies:
			if body.def.redetains and body.position.distance_to(at) < 0.5:
				on_a_door = true
				break
		t.check(on_a_door, "exactly on a gatehouse of one of today's own region doors")

		director.free())

## M221, "a failed day leaves no chalk mark behind", on a mark whose next step is placed by
## `_begin_step()` running a second time in the same `_on_contact_completed()` call (day 9's door,
## which every task day shares). The player,
## asked whether a read mark should vanish at once or stay: "Stays crossed, until the day ends" —
## so the mark's own touched `ContactPoint` and its guard both stay standing through the rest of
## the attempt, the task expiring included, and both are let go — the contact freed outright, the
## guard's own tracking reference dropped — the moment the day is retried or a new one starts,
## which is what stops either from piling up.
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
					"the mark's own guard stays too, not retired for the door")
			t.check(director._guard == mark_guard, "still tracked as the mark's own")
		t.check(director._task_guard == null,
				"the door stands no guard of its own: its trap comes to her once she crosses")

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
## alleys -- once it is checked it shouldn't appear anywhere else."* A read mark stays, crossed
## through, until the day ends (*"Stays crossed, until the day ends"*), so this asks what answers
## the report: exactly one mark's touched picture is standing once she has read it, across several
## ordinary days in a row, none of them failed or retried.
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
				and director.contact_position().distance_to(foot) < 0.5,
				"the contact stands on the foot of a live mast")
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
		var lead := PendingWarning.least_distance()
		if warning:
			t.check(CrowdLanes.corridor_at(warning.place.x) == _city.map.main_road,
					"pointing up the main road")
			t.check(warning.left <= Tuning.WARNING_ALONE_MAX,
					"for at most a second alone (%.2fs)" % warning.left)
			# She walks along the road while it is coming: the badge keeps its offset from her.
			var was := warning.place - her
			her.y += Tuning.WALK_SPEED * 0.5
			_city.events._run_the_warnings(STEP, her)
			t.check((warning.place - her).is_equal_approx(was),
					"and it holds still against her rather than coming sooner or jumping")
		# The rest of the warning, frame by frame, the way `EventManager._physics_process` runs it.
		while warning and _city.events.pending_warnings().has(warning) \
				and warning.shown < Tuning.WARNING_ALONE_MAX + 5.0:
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
			t.check(PendingWarning.is_out_of_sight(VisibleView.around(her), front.def, her,
					front.global_position)
					and absf(front.global_position.x - warning.place.x) < 1.0
					and signf(front.global_position.y - her.y) == signf(warning.place.y - her.y),
					"its front truck is created just out of sight, up the lane the badge pointed")
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

## Every built perform step earns the red arrow, the "any instance" ones (the man shouting, a
## roadblock) included. A mark never earns one, whichever task it unlocks.
func _test_the_red_arrow_points_at_every_task_and_never_at_a_mark(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var mark_only := _director(t)
		mark_only.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(mark_only.red_arrow_target() == Vector2.INF, "a mark never earns the red arrow")
		mark_only.free()

		var yeller := _director_on_the_yeller_perform(t)
		t.check(yeller.red_arrow_target() != Vector2.INF
				and yeller.red_arrow_target() == yeller._rider.global_position,
				"the yeller is any instance and earns the arrow too, on the man shouting")
		yeller.free()

		GameState.completed_resistance_steps = _completed_through(2)
		var van := _director(t)
		van.start_day(7, _rng(7, "resistance"), 300.0)
		van._on_contact_completed(3)
		# M222, "the red arrow for the van does not end on the van", and feathery-marmot, "Never
		# besides the item!": the contact stands on the van and the arrow's tip is the van itself.
		t.check(van._rider != null, "the package's van is a rider, not a bare point")
		t.check(van.red_arrow_target() != Vector2.INF
				and van.red_arrow_target() == van._rider.global_position
				and van.red_arrow_target() == van.contact_position(),
				"the package's van is one place, so it earns the arrow, exactly on the van's body")
		var task := van.current_step()
		van._contact._complete()
		t.check(task != null and van.red_arrow_target() == Vector2.INF,
				"and it goes out once she has reached it")
		van.free())

## plush-moose: an arrow exists on every task day, the any-instance days (6 and 13) and day 11's
## masts included, from the moment the mark is read, and the last night's from dawn.
func _test_an_arrow_exists_on_every_task_day(t) -> void:
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var saved_progress := GameState.resistance_progress
	var saved_sabotage := GameState.sabotage_done
	_build_city(t)
	_with_clean_run(func() -> void:
		for day: int in range(6, Tuning.RUN_LENGTH_DAYS + 1):
			GameState.scars = []
			GameState.resistance_progress = Tuning.RESISTANCE_GOAL \
					if day == Tuning.RUN_LENGTH_DAYS else 0
			GameState.sabotage_done = false
			var read := _read_the_mark_on(t, day, SEED) if day != Tuning.RUN_LENGTH_DAYS \
					else _start_the_finale(t, SEED)
			var director: ResistanceDirector = read[0]
			var step := director.current_step()
			t.check(step != null and not step.is_pickup,
					"day %d: the task is on offer" % day)
			t.check(director.red_arrow_target() != Vector2.INF,
					"day %d: and it has the red arrow" % day)
			(read[2] as Stroller).free()
			director.free())
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	GameState.resistance_progress = saved_progress
	GameState.sabotage_done = saved_sabotage

## A tile with a straight run of walkable tiles that nothing blocks today — no closure, no soft
## seal, no body standing — `before` tiles to its left and `after` to its right, for building a
## constructed case, or (-1, -1).
func _open_run_for(before: int, after: int) -> Vector2i:
	var map := _city.map
	for y in range(8, map.size.y - 8):
		for x in range(before + 1, map.size.x - after - 1):
			var open := true
			for dx in range(-before, after + 1):
				var tile := Vector2i(x + dx, y)
				if not map.is_walkable(tile) or map.is_closed(tile) or map.is_obstructed(tile) \
						or map.is_soft_sealed(tile):
					open = false
					break
			if open:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

## Day 6 on the test city with every man shouting retired, so the ones a test puts in are the only
## ones, and a rig of her on an open run: `[director, her rig, tile]`, the tile the run is centred
## on.
func _yeller_arrow_case(t, before: int, after: int) -> Array:
	var director := _director_on_the_yeller_perform(t)
	for instance in _city.events.instances():
		if instance.def.id == "homeless_yeller":
			_city.events.retire(instance)
	director._rider = null
	var tile := _open_run_for(before, after)
	var player := _rig_player(t, _city.map.tile_to_world(tile))
	return [director, player, tile]

func _put_a_yeller(tile: Vector2i) -> EventInstance:
	return _city.events.spawn_extra(EventCatalogue.by_id("homeless_yeller"),
			_city.map.tile_to_world(tile))

## plush-moose, "closest here always means path closeness not crow closeness": a wall of standing
## bodies between her and the man who is nearer as the crow flies sends the arrow to the farther
## one she can walk to sooner. The wall goes up after the arrow has chosen, in the live record of
## bodies (`CityMap.obstruct_tiles()`), so this is also the arrow reading what blocks her now.
func _test_the_arrow_chooses_by_walking_distance_not_straight_line(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 8)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var near_by_crow := _put_a_yeller(here + Vector2i(6, 0))
			var near_by_path := _put_a_yeller(here + Vector2i(-14, 0))
			t.check(player.global_position.distance_to(near_by_crow.global_position)
					< player.global_position.distance_to(near_by_path.global_position),
					"the one beyond the wall is the nearer as the crow flies")
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) < 1.0,
					"with nothing between them the arrow points at the nearer one")
			# A wall of bodies three tiles beyond her, far longer than the hold.
			var wall: Array[Vector2i] = []
			for dy in range(-30, 31):
				wall.append(here + Vector2i(3, dy))
			var owner := get_instance_id()
			_city.map.obstruct_tiles(owner, wall)
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near_by_path.global_position) < 1.0,
					"behind a wall the arrow points at the one she can walk to sooner")
			t.check(director.pointable_objective() == director.red_arrow_target(),
					"and the protest cue points at the same chosen objective as the arrow")
			t.check(director.red_arrow_target().distance_to(near_by_crow.global_position) > 100.0,
					"and not at the nearer as the crow flies")
			_city.map.release_obstruction(owner)
		player.free()
		director.free())

## plush-moose, "might switch if another closest one comes close": as she walks the arrow moves to
## whichever target has become closer on foot, with a hold of `ARROW_HOLD_TILES` so two about-as-
## near ones do not make it flicker, and the tick moves it by itself.
func _test_the_arrow_switches_as_another_target_becomes_closer(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 15)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var west := _put_a_yeller(here + Vector2i(-6, 0))
			var east := _put_a_yeller(here + Vector2i(14, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
					"standing at the start the arrow points at the closer one")
			# Walking east: the other becomes closer by more than the hold, and the tick moves it.
			player.global_position = _city.map.tile_to_world(here + Vector2i(8, 0))
			director._process(ResistanceDirector.ARROW_RETARGET_SECONDS)
			t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
					"walking toward the other one, the arrow switches to it")
			# Back to a spot about as near to both: it stays where it is.
			player.global_position = _city.map.tile_to_world(here + Vector2i(4, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
					"about as near to both, it does not flicker back")
			# Ignoring the task and walking on west: it goes back to the first.
			player.global_position = _city.map.tile_to_world(here + Vector2i(-4, 0))
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(west.global_position) < 1.0,
					"walking away from the task the arrow jumps to the closest on the other side")
		player.free()
		director.free())

## The hold's margin, as the docs state it: another target exactly `ARROW_HOLD_TILES` (four) tiles
## closer on foot takes the arrow, and one three tiles closer does not. Each case puts the arrow on
## the east man first, then stands her where the walking lengths differ by that much, measured from
## the fields themselves so a case the city's ground does not give is a failure, not a pass.
func _test_the_arrow_moves_at_four_tiles_closer_and_not_at_three(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 10, 18)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			for case: Array in [[14, ResistanceDirector.ARROW_HOLD_TILES, true],
					[13, ResistanceDirector.ARROW_HOLD_TILES - 1, false]]:
				var east_at: int = case[0]
				var west := _put_a_yeller(here + Vector2i(-6, 0))
				var east := _put_a_yeller(here + Vector2i(east_at, 0))
				player.global_position = _city.map.tile_to_world(here + Vector2i(east_at - 1, 0))
				director._settle_the_arrow()
				t.check(director.red_arrow_target().distance_to(east.global_position) < 1.0,
						"beside the east man the arrow is on him")
				player.global_position = _city.map.tile_to_world(here + Vector2i(2, 0))
				var tile := _city.map.world_to_tile(player.global_position)
				var to_west := director._arrow_nearest.length_at(tile)
				var to_east := director._arrow_own.length_at(tile)
				t.check(director._arrow_nearest.nearest_at(tile) == west.get_instance_id()
						and to_east - to_west == case[1],
						"the west man is %d tiles closer on foot (%d against %d)"
						% [case[1], to_west, to_east])
				director.retarget_the_arrow()
				var moved := director.red_arrow_target().distance_to(west.global_position) < 1.0
				t.check(moved == case[2], "%d tiles closer %s the arrow"
						% [case[1], "moves" if case[2] else "does not move"])
				_city.events.retire(west)
				_city.events.retire(east)
		player.free()
		director.free())

## When the instance the arrow points at goes — freed as it streams out, the way
## `EventManager._stream_out()` frees it — asking for the arrow is still a read that answers a
## real place (the contact's own, never a freed one's and never (0, 0)), and the next frame points
## the arrow at a target that is still there.
func _test_the_arrow_leaves_a_freed_instance_at_once(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		var made := _yeller_arrow_case(t, 15, 15)
		var director: ResistanceDirector = made[0]
		var player: Stroller = made[1]
		var here: Vector2i = made[2]
		t.check(here.x >= 0, "the test city has an open run to build the case on")
		if here.x >= 0:
			var near := _put_a_yeller(here + Vector2i(-4, 0))
			var far := _put_a_yeller(here + Vector2i(12, 0))
			# The contact rides the far one, as it rides a live man shouting all day.
			director._rider = far
			director._contact.ride(director._step, far, Vector2.ZERO)
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(near.global_position) < 1.0,
					"the arrow is on the nearer man")
			_city.events._instances.erase(near)
			near.free()
			var asked := director.red_arrow_target()
			t.check(asked == director.contact_position() and asked != Vector2.ZERO,
					"asked after he is freed, it answers the contact's own place (%s)" % asked)
			t.check(director._arrow_nearest_next == null,
					"and asking started no sweep: it is a read")
			director._process(STEP)
			t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
					"the next frame the arrow is on a man still there")
			director._settle_the_arrow()
			t.check(director.red_arrow_target().distance_to(far.global_position) < 1.0,
					"and stays there once the sweep without the freed one is done")
		player.free()
		director.free())

## The cell centres of the day's longest route, from the doorstep end out: the walk she takes, as
## `tests/test_route_bag.gd` walks it.
func _longest_route_points() -> Array[Vector2]:
	var longest: Array = []
	for branch in _city.route_tree().branches:
		for route: Array in branch.routes:
			if route.size() > longest.size():
				longest = route
	var points: Array[Vector2] = []
	for i in range(longest.size() - 1, -1, -1):
		points.append(EventScheduler.WalkSiting._cell_centre(_city.map, longest[i]))
	return points

## Walks her down the day's longest route, the events placing what is owed ahead of her as they do
## in play, until the mast reading day 11's mark rigged onto her route is put down — a mast that is
## not in `at_the_mark`, the ids the day had when she read it: its mast id, or "" if the walk ends
## first.
func _walk_until_the_route_mast(at_the_mark: Dictionary, player: Stroller) -> String:
	var path := _longest_route_points()
	_city.events._find_player()
	if path.size() < 2:
		return ""
	var index := 0
	var direction := 1
	player.global_position = path[0]
	var walked := 0.0
	var step := 0.1
	while walked < 600.0:
		for plan in _city.events.plans():
			if plan.def.id == ResistanceDirector.MAST_ROW and plan.mast_id != "" \
					and not at_the_mark.has(plan.mast_id):
				return plan.mast_id
		var next: Vector2 = path[index + direction] if index + direction >= 0 \
				and index + direction < path.size() else Vector2.INF
		if next == Vector2.INF:
			direction = -direction
			continue
		var toward := next - player.global_position
		if toward.length() < Tuning.WALK_SPEED * step:
			player.global_position = next
			index += direction
			continue
		player.velocity = toward.normalized() * Tuning.WALK_SPEED
		_city.events._place_what_is_owed_ahead(step)
		player.global_position += player.velocity * step
		walked += step
	return ""

## A tile beside `foot` she can stand on to touch the mast there, as `_place_at_a_mast()` asks it.
func _beside_the_mast(director: ResistanceDirector, foot: Vector2) -> Vector2:
	var foot_tile := _city.map.world_to_tile(foot)
	for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var tile := foot_tile + side
		if ResistanceDirector.is_legal_ground(_city.map, tile, director._walled_alleys()) \
				and not _city.map.is_obstructed(tile):
			return _city.map.tile_to_world(tile)
	return Vector2.INF

## Day 11, through the real rig: reading the mark rigs a mast onto her route, and walking the
## day's route puts it down. Then **any live mast answers the task** *(the player: "why limit
## artificially to two arbitrary masts")* — the one near the mark, the routed one and a third one
## besides — and touching the third, which is neither, completes the task, silences that mast and
## scars its foot, and leaves the other two lit. Asking for the arrow along the way is a read.
func _test_day_eleven_answers_at_any_live_mast(t) -> void:
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	_build_city(t)
	_with_clean_run(func() -> void:
		GameState.scars = []
		var read := _read_the_mark_on(t, 11, SEED)
		var director: ResistanceDirector = read[0]
		var player: Stroller = read[2]
		var step := director.current_step()
		var near := director._mast_id
		t.check(step != null and near != "", "day 11's task is on offer at the mast near the mark")
		var before := [director._arrow_key, director._mast_id, director.contact_position()]
		var asked := director.red_arrow_target()
		t.check(asked == director.contact_position() and director._arrow_nearest_next == null
				and [director._arrow_key, director._mast_id, director.contact_position()] == before,
				"asking for the arrow chooses nothing, sweeps nothing and moves no contact")
		var at_the_mark := {}
		for plan in _city.events.plans():
			if plan.mast_id != "":
				at_the_mark[plan.mast_id] = true
		var routed := _walk_until_the_route_mast(at_the_mark, player)
		t.check(routed != "", "walking the day's route puts the rigged mast down on seed %d" % SEED)
		if routed == "" or step == null:
			player.free()
			director.free()
			return
		var keys: Array = []
		for target in director._arrow_candidates(step):
			keys.append(target["key"])
		var third := ""
		for key: String in keys:
			if key != near and key != routed \
					and _beside_the_mast(director, _city.events.mast_foot(key)) != Vector2.INF:
				third = key
		t.check(near in keys and routed in keys and third != "",
				"the near mast, the routed one and a third all answer (%s)" % [keys])
		if third == "":
			player.free()
			director.free()
			return
		var third_foot := _city.events.mast_foot(third)
		var near_foot := _city.events.mast_foot(near)
		player.global_position = _beside_the_mast(director, third_foot)
		t.check(director.red_arrow_target().distance_to(near_foot) < 1.0
				and director._mast_id == near,
				"before the next choice the arrow and task still point at the near mast")
		director._process(STEP)
		t.check(director.red_arrow_target().distance_to(third_foot) < 1.0
				and director._mast_id == third,
				"following her between masts moves the task to the one she actually touches")
		director._contact._physics_process(STEP)
		t.check(step.index in GameState.completed_resistance_steps,
				"touching the third mast completes the task")
		var silenced := {}
		for plan in _city.events.plans():
			if plan.mast_id in [near, routed, third]:
				silenced[plan.mast_id] = plan.silenced
		t.check(silenced.get(third, false) and not silenced.get(near, true)
				and not silenced.get(routed, true),
				"and silences the mast she touched, not the near or the routed one (%s)" % silenced)
		var scarred := []
		for scar: Dictionary in GameState.scars:
			if String(scar["id"]) == EventScheduler.SILENCED_MAST:
				scarred.append(scar["position"])
		t.check(scarred.size() == 1 and (scarred[0] as Vector2).distance_to(third_foot) < 1.0,
				"and the one scar is that mast's foot")
		player.free()
		director.free())
	GameState.scars = saved_scars
	GameState.city_state = saved_state

## A single-target task keeps its arrow on its contact exactly, retargeting or not.
func _test_a_single_target_arrow_stays_on_its_contact(t) -> void:
	_build_city(t)
	_with_clean_run(func() -> void:
		GameState.completed_resistance_steps = _completed_through(2)
		var van := _director(t)
		van.start_day(7, _rng(7, "resistance"), 300.0)
		van._on_contact_completed(3)
		van.retarget_the_arrow()
		t.check(van.red_arrow_target() == van.contact_position()
				and van.red_arrow_target() != Vector2.INF,
				"the van has the one arrow, on its contact")
		van.free())

## feathery-marmot, "the arrow ends on the item" — *"the red arrows should point to the actual item
## -- however, the radius of acceptance should be big enough to be possible to do"* · *"No! Never
## besides the item!"*. On three cities, each one-place task with a bare point or a body is
## planned in the real day order and put on offer: day 7's van, day 9's district door, day 11's
## mast, day 12's swing and the last night's station door. Its arrow ends on the item itself — the
## van's centre, one of the door's two gatehouses, the mast's foot, the swing's base
## (`CityMap.swing_position()`), the station door's point on its facade — and the task is completed
## from some standable, reachable tile near it (day 9 is crossed instead, and its own test is
## below). Before, the arrow ended beside the mast (32px), on the swing's tile centre, on a pavement
## tile in front of the station door and on the middle of the district door's street.
func _test_every_arrow_ends_on_its_item_and_its_touch_can_be_made(t) -> void:
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var saved_progress := GameState.resistance_progress
	var saved_sabotage := GameState.sabotage_done
	var checked := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		_build_city(t, seed_value)
		_with_clean_run(func() -> void:
			for day: int in [7, 9, 11, 12, Tuning.RUN_LENGTH_DAYS]:
				GameState.scars = []
				GameState.resistance_progress = Tuning.RESISTANCE_GOAL \
						if day == Tuning.RUN_LENGTH_DAYS else 0
				GameState.sabotage_done = false
				var read := _read_the_mark_on(t, day, seed_value) if day != Tuning.RUN_LENGTH_DAYS \
						else _start_the_finale(t, seed_value)
				var director: ResistanceDirector = read[0]
				var player: Stroller = read[2]
				var step := director.current_step()
				var arrow := director.red_arrow_target()
				if step == null or step.is_pickup or arrow == Vector2.INF:
					t.check(false, "seed %d day %d: the task is on offer with its arrow"
							% [seed_value, day])
				else:
					checked[0] += 1
					var item := _the_item_of(director, step)
					t.check(item != Vector2.INF and arrow.distance_to(item) < 0.5,
							"seed %d day %d: the arrow ends on the item itself (%s, item %s)"
							% [seed_value, day, arrow, item])
					if step.target_kind != ResistanceSteps.TargetKind.DOOR:
						t.check(_touched_from_standable_ground(director, item),
								"seed %d day %d: and the task is touched from ground she can stand on"
								% [seed_value, day])
				player.free()
				director.free())
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	GameState.resistance_progress = saved_progress
	GameState.sabotage_done = saved_sabotage
	t.check(checked[0] > 0, "some task was put on offer (%d)" % checked[0])

## The finale on the test city in the real day order, the goal met: `[director, Vector2.INF, her
## rig]`, the shape `_read_the_mark_on()` answers, the finale having no mark.
func _start_the_finale(t, seed_value: int) -> Array:
	var day := Tuning.RUN_LENGTH_DAYS
	GameState.completed_resistance_steps = _all_but_the_finale()
	GameState.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures", seed_value))
	_city.events.start_day(day, _rng(day, "events", seed_value), [],
			_city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance", seed_value), 300.0)
	var player := _rig_player(t, _city.map.doorstep_world_position())
	return [director, Vector2.INF, player]

## Where the item a one-place task is about stands, found from the day itself rather than from the
## contact: the van's own instance, a gatehouse of today's district doors (the one nearest the
## contact, so the test asks that the contact is on one of them), the foot of the mast the task
## named, the swing frame's base, the station's door point on its facade.
func _the_item_of(director: ResistanceDirector, step: ResistanceSteps.Step) -> Vector2:
	match step.target_kind:
		ResistanceSteps.TargetKind.EVENT:
			return director._rider.global_position if director._rider else Vector2.INF
		ResistanceSteps.TargetKind.DOOR:
			var nearest := Vector2.INF
			for body in _city.region_plan().door_bodies:
				if body.def.redetains and (nearest == Vector2.INF or body.position.distance_to(
						director.contact_position()) < nearest.distance_to(director.contact_position())):
					nearest = body.position
			return nearest
		ResistanceSteps.TargetKind.MAST:
			return _city.events.mast_foot(director._mast_id)
		ResistanceSteps.TargetKind.PARK_SWING:
			var layout: BlockLayout = _city.map.block_layouts.get(CityGenerator.swing_park(_city.map))
			return _city.map.swing_position(layout.playground) if layout else Vector2.INF
		ResistanceSteps.TargetKind.STATION_DOOR:
			var door := _city.map.power_station_door_position()
			return Vector2(door.x, door.y - Tuning.TILE_SIZE)
	return Vector2.INF

## Whether some tile within three of `item` is ground she can stand on (walkable, no body,
## reachable from home) and its centre completes today's contact (`ContactPoint.would_complete_at()`).
func _touched_from_standable_ground(director: ResistanceDirector, item: Vector2,
		on: CityMap = null) -> bool:
	var map := on if on else _city.map
	var centre := map.world_to_tile(item)
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var tile := centre + Vector2i(dx, dy)
			if not map.is_walkable(tile) or map.is_obstructed(tile) \
					or not director._reachable_from_home(tile):
				continue
			if director._contact.would_complete_at(map.tile_to_world(tile)):
				return true
	return false

## feathery-marmot, day 12 — *"Not the drawn swing. Place an ellipse at its base. That's the area to
## touch"*. The swing's contact is touched by her body overlapping `ResistanceDirector.swing_base()`
## round the swing's base, the extent of the shadow the frame casts there
## (`Prop._playground_frame_shape()`): from eight bearings, standing with her edge a pixel inside the ellipse's
## outline completes it, at each side and each corner, and standing two pixels clear of it does not.
## Before, a 36px circle round the swing's tile centre counted.
func _test_the_swings_touch_is_the_ellipse_at_its_base(t) -> void:
	var contact := ContactPoint.new()
	contact.setup(_perform_on(12), Vector2(500.0, 500.0))
	contact.touch_ellipse = ResistanceDirector.swing_base()
	t.add_child(contact)
	contact.set_physics_process(false)
	var semi := ResistanceDirector.swing_base()
	var shadow := Prop._playground_frame_shape()
	t.check(is_equal_approx(semi.x, shadow.reach()) and is_equal_approx(semi.y, shadow.across()),
			"the ellipse spans the shadow the frame casts at its base (%s)" % semi)
	var touching := 0
	var clear := 0
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var edge := Vector2(cos(angle) * semi.x, sin(angle) * semi.y)
		var outward := Vector2(cos(angle) / semi.x, sin(angle) / semi.y).normalized()
		var inside := contact.global_position + edge + outward * (Tuning.PLAYER_BODY_RADIUS - 1.0)
		var outside := contact.global_position + edge + outward * (Tuning.PLAYER_BODY_RADIUS + 2.0)
		if contact.would_complete_at(inside):
			touching += 1
		if not contact.would_complete_at(outside):
			clear += 1
	t.check(touching == 8, "her body overlapping the swing's base ellipse completes it on every side and corner (%d of 8)" % touching)
	t.check(clear == 8, "and two pixels clear of it, on every side and corner, does not (%d of 8)" % clear)
	t.check(semi.x > semi.y and semi.y > 0.0, "the base is wider than it is deep, as the frame stands side-on")
	contact.free()

## feathery-marmot, day 9 — *"Cross at this district door"* · *"Should trigger on the action not on a
## proximity test"* · *"No it should choose one"*. On the test city's day 9, its mark read: the
## arrow ends on one of the named door's gatehouses, the same one every time the day is replayed;
## standing at that gatehouse, or on the door's line under the boom, completes nothing; walking
## through the door's line (`EventManager._watch_the_door_lines()`, its `door_crossed`) completes
## it, in either direction; and walking through another door's line does not. Walked under the
## boom, the crossing sends no robber from off screen: the door's own guard is its price.
## *(2026-10-04, the player, asked whether both should come at once: "(a)" — under the boom only the
## guard, the robber only after an inspected crossing.)*
func _test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it(t) -> void:
	_build_city(t)
	var saved_state := GameState.city_state
	_with_clean_run(func() -> void:
		var crossings := 0
		var gatehouse := Vector2.INF
		for direction: float in [1.0, -1.0]:
			_city.events.stream_radius = INF
			var read := _read_the_mark_on(t, 9, SEED)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var step := director.current_step()
			t.check(step != null and step.target_kind == ResistanceSteps.TargetKind.DOOR,
					"day 9's mark puts the crossing on offer")
			if step == null or director._door_at == Vector2.INF:
				player.free()
				director.free()
				continue
			var house := director.contact_position()
			t.check(gatehouse == Vector2.INF or house.distance_to(gatehouse) < 0.5,
					"the arrow ends on the same gatehouse every time the day is played (%s)" % house)
			gatehouse = house
			var at_a_house := false
			for body in _city.region_plan().door_bodies:
				if body.def.redetains and body.position.distance_to(house) < 0.5:
					at_a_house = true
			t.check(at_a_house and director.red_arrow_target() == house,
					"and on a gatehouse of today's district doors")
			for here: Vector2 in [house, director._door_at]:
				player.global_position = here
				director._contact._physics_process(STEP)
			t.check(not director._contact.is_done,
					"standing at the gatehouse or under the boom completes nothing")
			# Another door's line first: nothing — and that crossing is seen happening, so the check
			# is not vacuous.
			var walked_before := _city.events.walks_under_a_boom()
			for body in _city.region_plan().door_bodies:
				if body.def.lifts_for_traffic and body.position.distance_to(director._door_at) > 200.0:
					_walk_through(body.position, body.facing, direction, player)
					break
			t.check(_city.events.walks_under_a_boom() > walked_before,
					"another district door's line was walked through")
			t.check(not director._contact.is_done, "crossing another district door completes nothing")
			_walk_through(director._door_at, director._door_axis, direction, player)
			if director._contact.is_done:
				crossings += 1
			t.check(director._trap == null
					and _warning_for(_city.events, "robber_giving_chase") == null,
					"walking under the named door's boom sends no robber after her, nor warns of one")
			t.check(_city.events._guard_after_her != null,
					"the door's own guard is after her instead")
			player.free()
			director.free()
		t.check(crossings == 2,
				"walking through the named door completes the task, in either direction (%d of 2)"
				% crossings)
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.city_state = saved_state

## feathery-marmot, day 9 let through after the inspection — the ordinary way through a door
## (`EventManager._release_finished_door_detentions()`, which puts her down on the far side of the
## gatehouse that held her and announces `door_crossed` with that gatehouse's position). On the test
## city's day 9, its mark read: being held at another door's gatehouse and let out completes nothing;
## being held at a gatehouse of the named door and let out on its far side completes the task, from
## either side, and sends the robber after her from where she was let out, never through the door.
func _test_day_nine_completes_when_she_is_let_through_after_the_inspection(t) -> void:
	_build_city(t)
	var saved_state := GameState.city_state
	_with_clean_run(func() -> void:
		var crossings := 0
		var elsewhere := 0
		for entry_side: float in [1.0, -1.0]:
			_city.events.stream_radius = INF
			var read := _read_the_mark_on(t, 9, SEED)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var events := _city.events
			events._player = player
			events.stream_around(player.global_position)
			if director._door_at == Vector2.INF:
				t.check(false, "day 9's door is named")
				player.free()
				director.free()
				continue
			var named: EventInstance = null
			var other: EventInstance = null
			for instance in events.instances():
				if not instance.def.redetains or instance.def.id != "checkpoint_hut":
					continue
				var on_the_door := absf((instance.global_position - director._door_at).dot(
						director._door_axis)) < 1.0 and instance.global_position.distance_to(
						director._door_at) < Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5
				if on_the_door and named == null:
					named = instance
				elif not on_the_door and other == null:
					other = instance
			t.check(named != null and other != null,
					"the named door's gatehouse and another door's are in the world")
			if named and other:
				for instance: EventInstance in [other, named]:
					player.global_position = instance.global_position \
							- instance.facing_now() * 60.0 * entry_side
					events._door_entry_side[instance] = -entry_side
					events._release_finished_door_detentions(player)
					if instance == other:
						if not director._contact.is_done:
							elsewhere += 1
				if director._contact.is_done:
					crossings += 1
				t.check(director._trap == null
						and _warning_for(events, "robber_giving_chase") != null,
						"the inspected crossing warns of the robber first, with nobody in the world")
				_run_the_traps_warning("robber_giving_chase", player.global_position)
				var trap := director._trap
				t.check(trap != null and trap.def.id == "robber_giving_chase",
						"the inspected crossing sends the robber after her")
				if trap:
					for body in _city.region_plan().door_bodies:
						t.check(EventManager.where_she_crossed(body.position, body.facing,
								body.def.obstructs_radius, trap.global_position,
								player.global_position) == Vector2.INF,
								"his run at her from %s never crosses a district door's line"
								% _city.map.world_to_tile(trap.global_position))
			player.free()
			director.free()
		t.check(elsewhere == 2, "being let through another door completes nothing (%d of 2)"
				% elsewhere)
		t.check(crossings == 2,
				"being let through the named door after the inspection completes it, from either side (%d of 2)"
				% crossings)
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.city_state = saved_state

## Walks her across a door's line at `at`, along `axis` in `direction`, in one step the way
## `EventManager._watch_the_door_lines()` reads a frame: from 40px on one side to 40px on the other.
func _walk_through(at: Vector2, axis: Vector2, direction: float, player: Stroller) -> void:
	var events := _city.events
	events._player = player
	player.global_position = at - axis * 40.0 * direction
	events._last_seen_at = Vector2.INF
	events._watch_the_door_lines()
	player.global_position = at + axis * 40.0 * direction
	events._watch_the_door_lines()

# ------------------------------------------------------ M188: reachable targets ---
# A mark and every contact stand on ground clear of a solid body, or on the item itself, and are
# reached from such ground — `CityMap.is_obstructed()`, filled by `EventManager.start_day()` from
# the day's whole plan before this director places anything (`main.gd`'s own day order:
# `_city.events.start_day()` runs before `_resistance.start_day()`), and `_pick_reachable()`
# refuses a drawn tile with a body on it.

## The same three seeds `tests/probes/m184_route_timing.gd` times days 6-13 against.
## feathery-marmot, "a task's target is near its mark" — *"the van should spawn close to the mark
## not across the city"* · *"this applies to almost all tasks"* (minty-hedgehog, statement 3). On
## three cities, each day whose task is placed rather than fixed — day 6's man shouting, day 7's
## van, day 8's burnt building on a run with no day-3 fire, day 11's mast, day 13's roadblock — is
## planned the way a played day is and its mark read standing on it, the screen her view around
## her: the task lands where one of her paths first reaches the edge of a
## `ResistanceDirector.NEAR_THE_MARK` (576px) circle round her — worked out here by its own walk
## over the day's obstruction (`_edge_of_her_circle()`) — or the director says nothing on the edge
## qualified; day 11's mast is one her paths reach inside or on that circle; and a task put in the
## world is put outside her view. *("create a circle around the current player position with the
## radius of the desired distance -- then follow the path until it reaches the edge of the
## circle".)* Before, it was drawn anywhere within 576px as the crow flies.
func _test_a_task_is_placed_near_its_mark(t) -> void:
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var checked := [0]
	var fell_back := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		_build_city(t, seed_value)
		_with_clean_run(func() -> void:
			for day: int in [6, 7, 8, 11, 13]:
				GameState.scars = []
				var read := _read_the_mark_on(t, day, seed_value)
				var director: ResistanceDirector = read[0]
				var mark: Vector2 = read[1]
				var player: Stroller = read[2]
				var step := director.current_step()
				t.check(step != null and not step.is_pickup,
						"seed %d day %d: reading the mark puts its task on offer" % [seed_value, day])
				if step != null and not step.is_pickup:
					checked[0] += 1
					var mast := step.target_kind == ResistanceSteps.TargetKind.MAST
					var target := director.contact_position() if mast or director._rider == null \
							else director._rider.global_position
					var circle := _edge_of_her_circle(director, mark)
					var on_it := false
					var centre := _city.map.world_to_tile(target)
					for step_to: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT,
							Vector2i.UP, Vector2i.DOWN]:
						var tile := centre + step_to
						if circle[0].has(tile) or (mast and circle[1].has(tile)):
							on_it = true
					t.check(on_it or director._fell_back,
							("seed %d day %d: the task stands where her path reaches the circle's " +
							"edge, or nothing there qualified") % [seed_value, day])
					if director._fell_back:
						fell_back[0] += 1
					if not mast:
						t.check(not director._box_shows(target, ResistanceDirector.TASK_HALF_EXTENT),
								"seed %d day %d: and was put in the world outside her view"
								% [seed_value, day])
				player.free()
				director.free())
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	t.check(checked[0] > 0 and fell_back[0] * 3 < checked[0],
			"tasks were placed (%d), most on the edge rather than by the fallback (%d)"
			% [checked[0], fell_back[0]])

## `[edge, inside]`, each `tile -> true`: walked tile by tile from her tile at `her` over walkable
## ground the day's obstruction (`director._reach_blocked`) leaves open, going on only from a tile
## inside the `NEAR_THE_MARK` circle round her — a tile at or past its edge is where that path
## reaches the edge.
func _edge_of_her_circle(director: ResistanceDirector, her: Vector2) -> Array:
	var map := _city.map
	var start := map.world_to_tile(her)
	var centre := map.tile_to_world(start)
	var edge := {}
	var inside := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := tile + step
			if inside.has(next) or edge.has(next) or not map.is_walkable(next) \
					or director._reach_blocked.has(next):
				continue
			if map.tile_to_world(next).distance_to(centre) >= ResistanceDirector.NEAR_THE_MARK:
				edge[next] = true
			else:
				inside[next] = true
				queue.append(next)
	return [edge, inside]

## feathery-marmot, day 11 — *"Now just add a new mast close by"* (the player, 2026-10-03, quiet-yak, inbox #486, on a
## mark with no live mast near it). On three cities, day 11 is planned the way a played day is and
## its mark read standing on it: where no planned mast stands where her paths reach in the circle,
## the task goes to a mast the scheduler has just generated near her (`EventManager.queue_a_mast()`)
## — a `loudspeaker` plan under `EventScheduler.added_mast_id()`, on the edge of the circle and out
## of her view — or, where the scheduler's acceptance refused all of it, the nearest live mast.
## Reaching it silences it and records its scar; day 14's sabotage (`silence_all_masts()`) puts
## that very plan out when it is lit again; and the next day's and the last night's masts, planned
## from the scars, stand it again at its own foot, silenced. Before, the task went to the nearest of
## the city's six masts, 1,377px and 3,948px away on two of these cities.
func _test_day_eleven_puts_up_a_mast_near_the_mark_when_none_is_near(t) -> void:
	var saved_scars := GameState.scars.duplicate()
	var saved_state := GameState.city_state
	var added := [0]
	for seed_value: int in [SEED, 90210, 1234567]:
		_build_city(t, seed_value)
		_with_clean_run(func() -> void:
			GameState.scars = []
			var read := _read_the_mark_on(t, 11, seed_value)
			var director: ResistanceDirector = read[0]
			var mark: Vector2 = read[1]
			var player: Stroller = read[2]
			var circle := _edge_of_her_circle(director, mark)
			var site_near := false
			for plan in _city.events.plans():
				if plan.def.id != "loudspeaker" or plan.mast_id.begins_with("added-") or plan.silenced:
					continue
				var foot_tile := _city.map.world_to_tile(plan.position)
				# The tile she touches it from: the first beside the foot she can stand on, the
				# order `_place_at_a_mast()` asks them in.
				for side: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next := foot_tile + side
					if not ResistanceDirector.is_legal_ground(_city.map, next,
							director._walled_alleys()) or _city.map.is_obstructed(next) \
							or not director._reachable_from_home(next):
						continue
					if circle[0].has(next) or circle[1].has(next):
						site_near = true
					break
			if not site_near and director._mast_id.begins_with("added-"):
				added[0] += 1
				var foot := _city.events.mast_foot(director._mast_id)
				t.check(foot != Vector2.INF and circle[0].has(_city.map.world_to_tile(foot)),
						"seed %d: the mast put up for the task stands where her path reaches the circle's edge"
						% seed_value)
				t.check(not director._box_shows(foot, ResistanceDirector.TASK_HALF_EXTENT),
						"seed %d: and out of her view" % seed_value)
				var masts_before := _city.events.plans().filter(
						func(plan: EventScheduler.Planned) -> bool: return plan.mast_id != "").size()
				director._on_contact_completed(12)
				var scarred := false
				for scar: Dictionary in GameState.scars:
					if String(scar["id"]) == EventScheduler.SILENCED_MAST \
							and (scar["position"] as Vector2).distance_to(foot) < 1.0:
						scarred = true
				t.check(scarred, "seed %d: reaching it silences it and records its scar" % seed_value)
				# Day 14's sabotage: lit again, the added mast is put out by `silence_all_masts()`
				# with the others — it is that one mast's plan this asks about.
				var added_plan: EventScheduler.Planned = null
				for plan in _city.events.plans():
					if plan.mast_id == director._mast_id:
						added_plan = plan
				t.check(added_plan != null and masts_before > 0,
						"seed %d: the queued mast is one of the day's plans" % seed_value)
				if added_plan:
					added_plan.silenced = false
					_city.events.silence_all_masts()
					t.check(added_plan.silenced,
							"seed %d: day 14's sabotage puts out the queued mast too" % seed_value)
				var day_14 := EventScheduler._place_masts(14, _city.map, 0, PackedVector2Array(),
						GameState.scars)
				var on_day_14 := false
				for plan in day_14:
					if plan.mast_id == director._mast_id and plan.silenced:
						on_day_14 = true
				t.check(on_day_14, "seed %d: and the last night plans it, silenced, from its scar"
						% seed_value)
				var day_12 := EventScheduler._place_masts(12, _city.map, 0, PackedVector2Array(),
						GameState.scars)
				var stands_again := false
				for plan in day_12:
					if plan.mast_id == director._mast_id and plan.silenced \
							and plan.position.distance_to(foot) < 1.0:
						stands_again = true
				t.check(stands_again, "seed %d: and the next day stands it again, silenced"
						% seed_value)
			elif not site_near:
				# The scheduler may refuse every tile it was offered — its acceptance, not the
				# director's — and then the nearest live mast is the task's, which the director says.
				t.check(director._fell_back,
						"seed %d: no mast near the mark, none generated, and the nearest stands in (%s)"
						% [seed_value, director._mast_id])
			player.free()
			director.free())
	GameState.scars = saved_scars
	GameState.city_state = saved_state
	t.check(added[0] > 0, "some city had no mast near its day-11 mark, so one was put up (%d)"
			% added[0])

## feathery-marmot, day 11's queued mast — *"if there is a mast queued up that will be the next
## event to be generated"* (quiet-yak, inbox #503). On the test city's day 11, a stationary `reversing_lorry`
## (hard_fail, 175px field) is planned on a sidewalk, and the mast is queued with only the sidewalk
## inside that field to stand on: the scheduler's acceptance refuses every tile, so no mast is
## generated, as `_room_around()` refuses any row inside a lethal field ("Nothing else happens
## inside a lethal event's field"). Offered sidewalk well clear of it, the mast is generated, joins
## the day's plan under an added id, and has room by the same rule. A mast put down where the
## director pointed, as before, fails the first half.
func _test_a_queued_mast_is_never_generated_inside_a_lethal_field(t) -> void:
	_build_city(t)
	var saved_state := GameState.city_state
	_with_clean_run(func() -> void:
		var read := _read_the_mark_on(t, 11, SEED)
		var director: ResistanceDirector = read[0]
		var player: Stroller = read[2]
		var map := _city.map
		var lorry_def := EventCatalogue.by_id("reversing_lorry")
		var walled := director._walled_alleys()
		var lorry_tile := Vector2i(-1, -1)
		for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
			if ResistanceDirector.is_legal_ground(map, tile, walled) and not map.is_obstructed(tile) \
					and map.tile_to_world(tile).distance_to(map.doorstep_world_position()) > 600.0:
				lorry_tile = tile
				break
		var lorry := EventScheduler.Planned.new(lorry_def, map.tile_to_world(lorry_tile))
		lorry.role = GameEnums.BlockerRole.FRICTION
		_city.events._plans.append(lorry)
		var inside: Array[Vector2i] = []
		var clear: Array[Vector2i] = []
		for tile in map.tiles_of_type(GameEnums.TileType.SIDEWALK):
			if not ResistanceDirector.is_legal_ground(map, tile, walled) or map.is_obstructed(tile):
				continue
			var gap := map.tile_to_world(tile).distance_to(lorry.position)
			if gap > Tuning.EVENT_SPACING_ANY and gap < lorry_def.field_reach() - Tuning.TILE_SIZE:
				inside.append(tile)
			elif gap > lorry_def.field_reach() + 600.0 and gap < lorry_def.field_reach() + 900.0:
				clear.append(tile)
		t.check(not inside.is_empty() and not clear.is_empty(),
				"there is sidewalk inside the lorry's field and well clear of it (%d, %d)"
				% [inside.size(), clear.size()])
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var refused := _city.events.queue_a_mast(inside, rng)
		t.check(refused == null, "offered only ground inside a lethal field, no mast is generated")
		var placed := _city.events.queue_a_mast(clear, rng)
		t.check(placed != null and placed.mast_id.begins_with("added-")
				and placed in _city.events.plans(),
				"offered ground clear of it, a mast is generated into the day's plan")
		if placed:
			var others := _city.events.plans().filter(
					func(plan: EventScheduler.Planned) -> bool: return plan != placed)
			t.check(EventScheduler._room_around(placed, others) != -INF,
					"and it has room by the scheduler's own spacing")
		player.free()
		director.free())
	GameState.city_state = saved_state

## Plans `day` on the test city in the real day order (closures, events, resistance) for
## `seed_value`, and reads the day's mark standing on it with her screen the view around her:
## `[director with the task active, the mark's position, her rig]`.
func _read_the_mark_on(t, day: int, seed_value: int) -> Array:
	GameState.completed_resistance_steps = _completed_through(2 * (day - 6))
	GameState.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures", seed_value))
	_city.events.start_day(day, _rng(day, "events", seed_value), [],
			_city.map.doorstep_world_position())
	var director := _director(t)
	director.start_day(day, _rng(day, "resistance", seed_value), 300.0)
	var mark := director.contact_position()
	var player := _rig_player(t, mark)
	var screen := func(p: Vector2) -> bool:
		return absf(p.x - mark.x) <= Tuning.VIEW_HALF_EXTENT.x \
				and absf(p.y - mark.y) <= Tuning.VIEW_HALF_EXTENT.y
	director.set_sight(screen, screen)
	var step := director.current_step()
	if step != null and step.is_pickup:
		director._on_contact_completed(step.index)
	return [director, mark, player]

const REACHABILITY_SWEEP_SEEDS: Array[int] = [4242, 90210, 1234567]
const REACHABILITY_SWEEP_DAYS := [6, 7, 8, 9, 10, 11, 12, 13]

## `GameState.day_rng()`'s own hash, built without touching the `GameState.run_seed` global this
## sweep has no other use for — same stream a played day actually draws from, for a seed and a day
## this test chooses rather than the run's own.
func _production_rng(seed_value: int, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, day, stream])
	return rng

## Every refusal `_pick_reachable()` checks — `is_held_at`
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

## Every mark and every contact a task activates stands on walkable, unobstructed ground — day 8's,
## which stands on the burnt building's door, is touched from the ground in front of it — swept
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
## every placement *after* it — the task's own included — from a stream a
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
		var saved_scars := GameState.scars.duplicate()
		var checked := 0
		for seed_value in REACHABILITY_SWEEP_SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(seed_value))
			for day in REACHABILITY_SWEEP_DAYS:
				GameState.completed_resistance_steps = []
				GameState.failed_resistance_steps = []
				GameState.completed_resistance_alley_tiles.clear()
				# No history, like `--day N`: day 8 with no recorded scar records one for its
				# task, and a scar from another seed's city must not stand in this one's.
				GameState.scars = []
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
						# Every contact stands on its item — a door on a wall, a van or a mast on its
						# own body's tile — so what is asked is that she can touch it from ground
						# she can stand on. Day 9's is crossed instead: its gatehouse stands on the
						# door's own held pavement, which is asked as before.
						if task_step.target_kind == ResistanceSteps.TargetKind.DOOR:
							t.check(_stands_on_legal_ground(city.map, task_tile, walled_alleys,
									true, grid, blocked, reached),
									("seed %d day %d: step %d's gatehouse stands on walkable, " +
									"reachable ground at %s") % [seed_value, day, task_step.index,
									task_tile])
						else:
							t.check(_touched_from_standable_ground(director,
									director.contact_position(), city.map),
									("seed %d day %d: step %d's contact at %s is touched from " +
									"walkable, unobstructed, reachable ground") % [seed_value, day,
									task_step.index, task_tile])
				player.free()
				director.free()
			city.free()
		GameState.completed_resistance_alley_tiles = saved_tiles
		GameState.scars = saved_scars
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
## **A region door counts as a way through**, for the director and for the tile walk alike, so a
## mark reachable only by crossing a district door passes here. That is the player's own rule
## (crisp-moose, statement 2: *"the alley must be next to a path. if there is no path to it it
## shouldn't appear"*): a door always lets her through after its hold, so it is a path.
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
				# The station's contact stands on its door, on the facade, and is touched from the
				# pavement straight below it, which is the ground asked about.
				if step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR and at != Vector2.INF:
					at_tile = city.map.world_to_tile(at + Vector2.DOWN * Tuning.TILE_SIZE)
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
