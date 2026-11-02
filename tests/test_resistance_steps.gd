extends "res://tests/resistance_rig.gd"
## The resistance subquest's step table, touch-completion, the director's seeded dawn draws, a perform step expiring, and a finished task shown by the world: the package, the yeller leaving, the sabotage.

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
	# The tests below take the city already standing; each of the others builds its own.
	_build_city(t)
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
	if _city != null:
		_city.free()

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
	contact.use_player(_player)
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
	note_contact.use_player(player)
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
	ordinary_contact.use_player(player)
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
	outside_contact.use_player(player)
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
				contact.use_player(player)
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
		var saved_progress := GameState.resistance.progress
		var saved_sabotage := GameState.resistance.sabotage_done
		var saved_tiles := GameState.facts.completed_resistance_alley_tiles.duplicate()
		GameState.resistance.progress = Tuning.RESISTANCE_GOAL
		GameState.resistance.sabotage_done = false
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
		GameState.facts.completed_resistance_alley_tiles = saved_tiles
		GameState.resistance.progress = saved_progress
		GameState.resistance.sabotage_done = saved_sabotage)

## One attempt at `day` for the test above, with her standing at `her` and both of the director's
## views (the day's, which the siting and `ResistanceDirector.set_sight()` both read) answering `seen` for every point when the
## day starts: `[contact, its guard]` at dawn, then on a mark's day
## `[task contact, task guard]` once she reads it from the mark's own spot with nothing on screen.
## `Vector2.INF` for a guard that was not placed.
func _attempt_the_day(t, day: int, her: Vector2, seen: bool) -> Array[Vector2]:
	GameState.resistance.completed_steps = _completed_through(2 * (day - 6)) \
			if day < Tuning.RUN_LENGTH_DAYS else _all_but_the_finale()
	# A lost day gives back what the attempt recorded (`GameState.calendar.begin_day()`), the alley it read
	# its mark in included.
	GameState.facts.completed_resistance_alley_tiles = []
	var state := CityState.new()
	GameState.attempt_spend.city_state = state
	state.begin_day(_city.map.block_plans, day)
	_city.start_day(state, day, _rng(day, "closures"))
	_city.events.start_day(DaySpec.for_day(day), _rng(day, "events"), [], _city.map.doorstep_world_position())
	var player := _rig_player(t, her)
	var director := _director(t)
	director.use_player(player)
	_look_at(Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6) if seen else Rect2())
	director.set_sight(_city.events.sees)
	director.start_day(day, _rng(day, "resistance"), 300.0)
	var step := director.current_step()
	var drawn: Array[Vector2] = [director.contact_position()]
	var guard: EventInstance = director._guard if step and step.is_pickup else director._task_guard
	drawn.append(guard.global_position if guard else Vector2.INF)
	if step and step.is_pickup:
		player.global_position = director.contact_position()
		_look_at(Rect2())
		director._on_contact_completed(step.index)
		drawn.append(director.contact_position())
		var task_guard: EventInstance = director._task_guard
		drawn.append(task_guard.global_position if task_guard else Vector2.INF)
	player.free()
	director.free()
	return drawn

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
			GameState.resistance.completed_steps = _completed_through(2 * (day - 6))
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

# Playtest 19 finding 6, in the player's own words: "if it was placed but never on screen it
# should count as not placed and be placed on the next alley the player comes close to."

func _test_a_perform_step_expires_when_its_rider_is_gone(t) -> void:
	_with_clean_run(func() -> void:
		var director := _director_on_the_yeller_perform(t)
		t.check(director.current_step() != null and director.current_step().index == 2,
				"the yeller perform is active")
		var rider: EventInstance = director._rider
		t.check(rider != null, "the perform step rides on a live instance")

		rider._finish()
		director.tick(0.1)
		t.check(director.current_step() == null, "and it is gone once the rider is")
		t.check(2 in GameState.resistance.failed_steps, "recorded as failed for the run")
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

		director.tick(100.0 * timed.deadline_fraction * 0.5)
		t.check(director.current_step() != null, "on offer before the deadline")
		t.check(9001 not in GameState.resistance.failed_steps, "nothing has failed yet")

		director.tick(100.0 * timed.deadline_fraction)
		t.check(director.current_step() == null, "past the deadline it is gone")
		t.check(9001 in GameState.resistance.failed_steps, "and recorded as failed for the run")
		director.free())

## Step 4's cost is deferred and total rather than local: picking the package up does not cost the
## street it happened on, it makes every street after it dearer for the rest of the day.
func _test_completing_the_package_makes_the_pram_heavier(t) -> void:
	_with_clean_run(func() -> void:
		var somewhere := _city.map.tile_to_world(Vector2i(10, 10))
		var before := _city.decay_multiplier(somewhere)

		var director := _director(t)
		director._on_contact_completed(4)
		t.check(GameState.resistance.carrying_package, "picking up the package sets the flag")

		var after := _city.decay_multiplier(somewhere)
		t.close_to(after, before * City.RESISTANCE_PACKAGE_DECAY_MULTIPLIER,
				"and every street after it decays slower for the rest of the day", 0.001)
		director.free())

func _test_starting_a_day_resets_the_package_flag(t) -> void:
	_with_clean_run(func() -> void:
		GameState.resistance.carrying_package = true
		var director := _director(t)
		director.start_day(1, _rng(1, "resistance"), 300.0)
		t.check(not GameState.resistance.carrying_package,
				"a fresh attempt at a day has not picked it up yet")
		director.free())

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
		t.check(rider.excitement.contribution_at(rider.global_position) > 0.0,
				"and still charges her, since he has not started leaving yet")
		t.check(not decoy.is_leaving and decoy.excitement.contribution_at(decoy.global_position) > 0.0,
				"a look-alike she never reached is left exactly alone, still shouting")

		director.tick(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS - STEP)
		t.check(not rider.is_leaving,
				"and still hasn't, a frame short of the full linger")

		director.tick(2.0 * STEP)
		t.check(rider.is_leaving,
				"and stops shouting and leaves once he has lingered that long")
		t.close_to(rider.excitement.contribution_at(rider.global_position), 0.0,
				"and contributes nothing to the meter the same frame", 0.001)
		t.check(not decoy.is_leaving, "a look-alike she never reached is still left exactly alone")
		t.check(decoy.excitement.contribution_at(decoy.global_position) > 0.0,
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
		# half (walking west) — `route.advance(0.0)` reads `_path_travelled` back into a
		# heading and a position without covering any further ground.
		instance._path_travelled = 350.0 if on_the_second_half else 50.0
		instance.route.advance(0.0)
		var walking := instance._heading
		t.check((walking.x < 0.0) == on_the_second_half,
				"set up walking %s" % ("west, the second half" if on_the_second_half
						else "east, the first half"))
		# Sited ahead of him on his own heading — where "the way it was going" would walk him
		# straight at her if nothing turned him round.
		instance.excitement.set_player_at(instance.position + walking * 40.0)

		instance.leave_for_a_completed_task()

		t.check(instance.is_leaving, "he leaves (%s half)"
				% ("second" if on_the_second_half else "first"))
		t.check(instance._heading.dot(walking) < -0.99,
				"and turns to walk away from her rather than along the beat (%s half)"
						% ("second" if on_the_second_half else "first"))
		instance.free()

## Contribution stops the instant he leaves, and he walks rather than vanishing. He does **not**
## pop out of existence mid-screen at `EventDeparture.LEAVING_GIVES_UP` (6.0s) while she is still
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
	instance.excitement.set_player_at(Vector2(20.0, 0.0))
	t.check(instance.current_intensity() > 0.0, "shouting, before the task is done")

	instance.leave_for_a_completed_task()
	t.check(instance.is_leaving, "he stops the instant she hands him the note")
	t.close_to(instance.excitement.contribution_at(instance.global_position), 0.0,
			"and contributes nothing the same frame", 0.001)

	var before := instance.global_position
	var before_distance := before.distance_to(instance.player_at)
	instance.departure.leave(EventDeparture.LEAVING_GIVES_UP)
	t.check(not instance.is_finished,
			"still leaving past the backstop's own six seconds, since she is still watching")
	t.close_to(instance.excitement.contribution_at(instance.global_position), 0.0,
			"and still contributes nothing")
	t.check(instance.global_position.distance_to(instance.player_at) > before_distance,
			"farther away than when he started, not stalled")

	# She still has not moved. At `departs_at` (60px/s) from 20px away, he clears
	# `Tuning.OUT_OF_SIGHT` (420px) in well under ten more seconds.
	instance.departure.leave(10.0)
	t.check(instance.is_finished, "gone once he is actually out of sight, not before")
	instance.free()

## The departure's sight rule (`EventDeparture._must_clear_sight`) is set by `leave_for_a_completed_task()`. An ordinary
## departure — `_be_done()` reached on its own, with nothing routing it through the resistance —
## still gives up at the plain six-second backstop, watched or not: this changes nothing about it.
func _test_an_ordinary_departure_still_gives_up_at_six_seconds(t) -> void:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("homeless_yeller"), Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	instance.excitement.set_player_at(Vector2(20.0, 0.0))

	instance._be_done()
	t.check(instance.is_leaving, "an ordinary departure starts leaving the same way")

	instance.departure.leave(EventDeparture.LEAVING_GIVES_UP - 0.1)
	t.check(not instance.is_finished, "not gone yet, just under six seconds in")
	instance.departure.leave(0.2)
	t.check(instance.is_finished, "gone at the six-second backstop, watched or not")
	instance.free()

## "A task is only complete if it is done on the day that won" — `GameState.calendar.finish_day()` gives
## a lost day's resistance work back, and the retry starts at the mark again, not straight at the
## task: a task is one day, so there is no dawn shortcut into the middle of it the way the old
## two-beat design had.
func _test_a_lost_day_still_offers_the_mark_and_then_the_yeller_on_retry(t) -> void:
	var saved_seed := GameState.header.run_seed
	var saved_day := GameState.header.day
	var saved_nerves := GameState.header.nerves
	_with_clean_run(func() -> void:
		GameState.header.run_seed = SEED
		GameState.header.day = 6
		GameState.header.nerves = Tuning.STARTING_NERVES
		GameState.calendar.begin_day()

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
		attempt.tick(ResistanceDirector.NOTE_HANDOVER_LINGER_SECONDS + STEP)
		t.check(rider != null and rider.is_leaving,
				"and sends him away once he has lingered that long")
		attempt.free()

		t.check(GameState.calendar.finish_day(GameEnums.DayResult.LOST_CRYING),
				"losing the day continues the run")
		t.check(1 not in GameState.resistance.completed_steps
				and 2 not in GameState.resistance.completed_steps,
				"and gives both halves of the day's task back")
		t.check(GameState.header.day == 6, "and the retry is the same day")

		var retry := _director(t)
		retry.start_day(6, _rng(6, "resistance"), 300.0)
		t.check(retry.current_step() != null and retry.current_step().index == 1,
				"the retry starts at the mark again, not straight at the task")
		retry._on_contact_completed(1)
		t.check(retry._rider != null and retry._rider != rider,
				"and once touched again it rides a fresh rider, not the one that already walked off")
		t.check(not retry._rider.is_leaving, "and it is shouting, not leaving")
		retry.free())

	GameState.header.run_seed = saved_seed
	GameState.header.day = saved_day
	GameState.header.nerves = saved_nerves

## The sabotage is what puts the city's power out, and the masts go with it. Not at the door she
## touched: the hand-over takes minutes, so every mast is still speaking until the blackout, which
## comes once she is far enough from the station (`Blackout`) — and then the field each one has been
## holding near itself since day 5 goes with it, `EventManager.silence_all_masts()`: a mast has an
## edge like any other row's, so what stops is everywhere a mast actually stands, not the whole map.
func _test_the_sabotage_silences_the_city(t) -> void:
	_with_clean_run(func() -> void:
		GameState.resistance.completed_steps = _completed_through(8)
		GameState.resistance.progress = Tuning.RESISTANCE_GOAL
		GameState.resistance.sabotage_done = false
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
		_city.events.start_day(DaySpec.for_day(Tuning.RUN_LENGTH_DAYS),
				_rng(Tuning.RUN_LENGTH_DAYS, "events"), [], site.foot)
		var mast_plan: EventScheduler.Planned = null
		for plan in _city.events.plans():
			if plan.mast_id == site.id and plan.def.id == "loudspeaker":
				mast_plan = plan
		t.check(mast_plan != null and mast_plan.live != null,
				"the mast at her focus is live from the day it was started")
		var mast := mast_plan.live
		for i in int(round((mast.def.telegraph_time + 0.2) / STEP)):
			mast.step(STEP)
		var nearby := site.foot + Vector2(50.0, 0.0)
		t.check(mast.excitement.contribution_at(nearby) > 0.0,
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

		t.check(GameState.resistance.sabotage_done, "completing it does the sabotage")
		t.check(quiet.is_empty() and not mast.silenced,
				"and the masts are still speaking at the door: they stop with the power")
		var lot := _city.map.tile_rect_to_world(CityMap.blocks_tile_rect(_city.map.power_station))
		_city.blackout.update(Vector2(lot.get_center().x,
				lot.end.y + Blackout.BLACKOUT_DISTANCE + 8.0))
		t.check(quiet.size() == 1, "far enough away, the city goes quiet, once")
		t.check(mast.silenced, "the mast is marked silenced")
		t.close_to(mast.excitement.contribution_at(nearby), 0.0,
				"the mast contributes nothing afterwards")
		GameState.resistance.sabotage_done = false
		_city.blackout.update(Vector2(lot.get_center().x, lot.end.y))

		EventBus.city_went_quiet.disconnect(handler)
		director.free())

# Day 8's burnt shell (`TargetKind.SCAR`), day 9's crossing (`TargetKind.DOOR`) and day 12's
# swing (`TargetKind.PARK_SWING`) each find their own place rather than riding a freshly spawned
# `EventInstance` the way an ordinary perform step does.
