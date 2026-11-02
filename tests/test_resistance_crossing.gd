extends "res://tests/resistance_rig.gd"
## Day 9's door: the task is done by crossing it, not by standing at it, and what the guard and the hut do about a crossing.

func run(t) -> void:
	_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it(t)
	_test_a_crossing_taken_back_does_not_do_day_nine(t)
	_test_a_crossing_held_behind_another_door_counts_only_with_its_guard(t)
	_test_a_hut_ends_the_guard_the_walk_under_sets_and_sends_nobody(t)
	_test_day_nine_completes_when_she_is_let_through_after_the_inspection(t)
	if _city != null:
		_city.free()

## feathery-marmot, day 9 — *"Cross at this district door"* · *"Should trigger on the action not on a
## proximity test"* · *"No it should choose one"*. On the test city's day 9, its mark read: the
## arrow ends on one of the named door's gatehouses, the same one every time the day is replayed;
## standing at that gatehouse, or on the door's line under the boom, completes nothing; walking
## through the door's line (`CheckpointController.watch_the_door_lines()`, its `door_crossed`)
## completes it, in either direction; and walking through another door's line does not. Walked
## under the boom, the crossing sends no robber from off screen: the door's own guard is its price.
## *(2026-10-04, the player, asked whether both should come at once: "(a)" — under the boom only the
## guard, the robber only after an inspected crossing.)*
func _test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
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
				if body.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED and body.position.distance_to(director._door_at) > 200.0:
					_walk_through(body.position, body.facing, direction, player)
					break
			t.check(_city.events.walks_under_a_boom() > walked_before,
					"another district door's line was walked through")
			t.check(not director._contact.is_done, "crossing another district door completes nothing")
			# **Only one walk-under guard exists at a time**, and that other door has just set one
			# on her: left alone, the named crossing below spawns nobody and the check on a guard
			# after her passes on this first one. So he is finished first and the named crossing
			# has to set a guard of its own.
			var first_guard := _city.events.checkpoints._guard_after_her
			t.check(first_guard != null and first_guard.def.id == "door_guard",
					"the other door's walk under set its own guard on her")
			if first_guard:
				first_guard.give_up_the_chase()
			_walk_through(director._door_at, director._door_axis, direction, player)
			if director._contact.is_done:
				crossings += 1
			t.check(director._trap == null
					and _warning_for(_city.events, "robber_giving_chase") == null,
					"walking under the named door's boom sends no robber after her, nor warns of one")
			var guard := _city.events.checkpoints._guard_after_her
			t.check(guard != null and guard != first_guard and guard.def.id == "door_guard"
					and not guard.is_finished and not guard.is_leaving,
					"the named door's own, new guard is after her instead")
			if guard:
				t.check(guard.global_position.distance_to(director._door_at)
						< Tuning.STREET_WIDTH * Tuning.TILE_SIZE
						and guard.global_position.distance_to(first_guard.global_position
								if first_guard else Vector2.INF) > 100.0,
						"and he steps out of the named door's hut, not the other door's (%.0fpx from it, %.0fpx from the other's)"
						% [guard.global_position.distance_to(director._door_at),
						guard.global_position.distance_to(first_guard.global_position
								if first_guard else Vector2.INF)])
			player.free()
			director.free()
		t.check(crossings == 2,
				"walking through the named door completes the task, in either direction (%d of 2)"
				% crossings)
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.attempt_spend.city_state = saved_state

## Review 4 of PR #781, day 9: **a walked crossing counts only once it stands.** Under the named
## door's raised boom the crossing starts its warning
## (`CheckpointController._start_the_crossing_warning()`, `CheckpointController.CROSSING_WARNING`); she steps
## back across the line halfway through it, so the crossing is called off and no guard comes,
## and the task is not done either, however long she then waits: `door_crossed` is sent only
## when the warning has run with her still across. Walked through and staying across, the same
## door then does the task, with its guard after her.
func _test_a_crossing_taken_back_does_not_do_day_nine(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
	_with_clean_run(func() -> void:
		for direction: float in [1.0, -1.0]:
			_city.events.stream_radius = INF
			var read := _read_the_mark_on(t, 9, SEED)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var events := _city.events
			if director._door_at == Vector2.INF:
				t.check(false, "day 9's door is named")
				player.free()
				director.free()
				continue
			events.use_player(player)
			if is_instance_valid(events.checkpoints._guard_after_her):
				events.checkpoints._guard_after_her.give_up_the_chase()
			var at := director._door_at
			var axis := director._door_axis
			player.global_position = at - axis * 40.0 * direction
			events.checkpoints._last_seen_at = Vector2.INF
			events.checkpoints.watch_the_door_lines()
			player.global_position = at + axis * 40.0 * direction
			events.checkpoints.watch_the_door_lines()
			t.check(events.checkpoints._crossing != null, "walking under the named boom starts its warning")
			for i in int(round(CheckpointController.CROSSING_WARNING * 0.5 / STEP)):
				events.checkpoints.watch_the_door_lines(STEP)
			t.check(not director._contact.is_done,
					"halfway through the crossing's warning the task is not done yet")
			player.global_position = at - axis * 40.0 * direction
			events.checkpoints.watch_the_door_lines(STEP)
			t.check(events.checkpoints._crossing == null, "stepping back across calls the crossing off")
			for i in int(ceil(CheckpointController.CROSSING_WARNING * 2.0 / STEP)):
				events.checkpoints.watch_the_door_lines(STEP)
			var guard_before := events.checkpoints._guard_after_her
			t.check(not director._contact.is_done and (not is_instance_valid(guard_before)
					or guard_before.is_finished or guard_before.is_leaving),
					"a crossing taken back does not do the task, and sets no guard on her")
			_walk_through(at, axis, direction, player)
			var guard := events.checkpoints._guard_after_her
			t.check(director._contact.is_done and guard != null and guard != guard_before
					and not guard.is_finished and not guard.is_leaving,
					"walked through and staying across, the same door does the task, its guard after her")
			if guard:
				guard.give_up_the_chase()
			player.free()
			director.free()
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.attempt_spend.city_state = saved_state

## Reviews 5 and 6 of PR #781, day 9 at two doors: **a walked crossing counts only if she is still
## across that door's line when a guard is set on her for it.** She walks under another door A's
## raised boom (A's warning starts) and then, inside A's 2s, under the named door B or not, which
## starts no warning of its own while A's runs (`CheckpointController._held_crossings`). Every
## combination is walked: B not crossed, crossed and stayed across, or crossed and taken back; A
## then stayed across or taken back before its 2s. A's guard comes exactly when she stays across
## A, and the task is done exactly when she is across both when he comes. She steps between the
## two doors as a rig does (`_last_seen_at` cleared), so the step is not seen as a walk across
## anything.
func _test_a_crossing_held_behind_another_door_counts_only_with_its_guard(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
	_with_clean_run(func() -> void:
		for a_stays: bool in [true, false]:
			for b_walk: String in ["none", "stays", "back"]:
				_city.events.stream_radius = INF
				var read := _read_the_mark_on(t, 9, SEED)
				var director: ResistanceDirector = read[0]
				var player: Stroller = read[2]
				var events := _city.events
				events.use_player(player)
				if is_instance_valid(events.checkpoints._guard_after_her):
					events.checkpoints._guard_after_her.give_up_the_chase()
				var b_at := director._door_at
				var b_axis := director._door_axis
				var a_at := Vector2.INF
				var a_axis := Vector2.ZERO
				# Another door's boom with the named door well to one side of its line, so that she
				# can be across A's line while she stands at B.
				for body in _city.region_plan().door_bodies:
					if body.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED and body.position.distance_to(b_at) > 200.0 \
							and absf((b_at - body.position).dot(body.facing)) > 100.0:
						a_at = body.position
						a_axis = body.facing
						break
				t.check(b_at != Vector2.INF and a_at != Vector2.INF, "day 9 names a door and has another")
				if b_at == Vector2.INF or a_at == Vector2.INF:
					player.free()
					director.free()
					continue
				var name := "A %s, B %s" % ["stayed across" if a_stays else "taken back", {
						"none": "not crossed", "stays": "stayed across", "back": "taken back"}[b_walk]]
				# Across A toward B's side of A's line, so that standing at B she is still across A.
				var a_dir := signf((b_at - a_at).dot(a_axis))
				var step_to := func(at: Vector2, jump := false) -> void:
					player.global_position = at
					if jump:
						events.checkpoints._last_seen_at = Vector2.INF
					events.checkpoints.watch_the_door_lines(STEP)
				step_to.call(a_at - a_axis * 40.0 * a_dir, true)
				step_to.call(a_at + a_axis * 40.0 * a_dir)
				t.check(events.checkpoints._crossing != null, "%s: walking under A's boom starts its warning" % name)
				if b_walk != "none":
					step_to.call(b_at - b_axis * 40.0, true)
					step_to.call(b_at + b_axis * 40.0)
					t.check(not director._contact.is_done,
							"%s: under the named door while A's warning runs, nothing is done yet" % name)
					if b_walk == "back":
						step_to.call(b_at - b_axis * 40.0)
				if not a_stays:
					step_to.call(a_at + a_axis * 40.0 * a_dir, true)
					step_to.call(a_at - a_axis * 40.0 * a_dir)
				for i in int(ceil(CheckpointController.CROSSING_WARNING * 2.0 / STEP)):
					events.checkpoints.watch_the_door_lines(STEP)
				var guard := events.checkpoints._guard_after_her
				var chased := is_instance_valid(guard) and not guard.is_finished and not guard.is_leaving
				var done_expected := a_stays and b_walk == "stays"
				t.check(chased == a_stays and director._contact.is_done == done_expected,
						"%s: A's guard %s and the task is %s" % [name,
						"comes" if a_stays else "does not come", "done" if done_expected else "not done"])
				if chased:
					guard.give_up_the_chase()
				player.free()
				director.free()
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.attempt_spend.city_state = saved_state

## lilac-marmot (inbox #651), day 9's walk under the named boom and then a hut: *"Let's not send the
## robber in that case and stop the chase. It's a fair cheat getting through the barrier is hard
## enough. Well earned if the player pulls it off."* She walks under the named door's raised boom
## (the task is done, one `door_guard` steps out of the hut nearer to her), then steps into a hut of
## that door: the hold ends the guard's chase
## (`CheckpointController._end_the_guard_for_a_hold()`), and nobody else is sent — no robber
## warned of or set on her, no second guard.
func _test_a_hut_ends_the_guard_the_walk_under_sets_and_sends_nobody(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
	_with_clean_run(func() -> void:
		for direction: float in [1.0, -1.0]:
			_city.events.stream_radius = INF
			var read := _read_the_mark_on(t, 9, SEED)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var events := _city.events
			if director._door_at == Vector2.INF:
				t.check(false, "day 9's door is named")
				player.free()
				director.free()
				continue
			events.use_player(player)
			events.stream_around(player.global_position)
			_walk_through(director._door_at, director._door_axis, direction, player)
			t.check(director._contact.is_done, "walking under the named boom does the task")
			var guard := events.checkpoints._guard_after_her
			t.check(guard != null and guard.def.id == "door_guard" and not guard.is_finished
					and not guard.is_leaving and not guard.gave_up,
					"and sets the door's guard after her")
			t.check(director._trap == null and _warning_for(events, "robber_giving_chase") == null,
					"and no robber")
			var hut: EventInstance = null
			for instance in events.instances():
				if instance.def.id == "checkpoint_hut" and absf((instance.global_position
						- director._door_at).dot(director._door_axis)) < 1.0 \
						and instance.global_position.distance_to(director._door_at) \
						< Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5:
					hut = instance
					break
			t.check(hut != null, "the named door has a hut to step into")
			if guard and hut:
				player.global_position = hut.global_position
				events.checkpoints.check_detentions()
				t.check(hut.is_chatting(), "stepping into the hut is a hold")
				t.check(guard.gave_up and (guard.is_leaving or guard.is_finished),
						"the hold ends the walk under's guard: he gives up")
				t.check(director._trap == null and _warning_for(events, "robber_giving_chase") == null,
						"no robber is warned of or set on her for it")
				var pursuers := 0
				for instance in events.instances():
					if instance.def.id == "door_guard" and not instance.is_finished \
							and not instance.is_leaving:
						pursuers += 1
				t.check(pursuers == 0 and events.checkpoints._guard_after_her == guard,
						"and nobody else is sent: no second guard is after her")
				t.check(director._contact.is_done, "the task stays done")
				# **The moment day 9 sends the robber is the end of the hold**: the inspection
				# lets her through (`CheckpointController.release_finished_holds()`,
				# `door_crossed(…, true)`), which completes the crossing for a task done under
				# the boom only if the director's early return in `_on_door_crossed()` lets it.
				# So the hold is run out, she is released, and the warning a robber would send
				# is run out before anything is counted.
				var before := player.global_position
				var guard_steps := int(round(EventCatalogue.CHECKPOINT_DETAIN_SECONDS / STEP)) + 10
				while hut.is_chatting() and guard_steps > 0:
					guard_steps -= 1
					for instance in events.instances():
						instance.step(STEP)
				t.check(not hut.is_chatting() and guard_steps > 0, "the hold runs its clock out")
				events.checkpoints.release_finished_holds()
				# She stood at the hut's own centre, so which side she is put down on is not measured
				# here; only the release moves her, so being moved is being let through.
				t.check(player.global_position.distance_to(before) > 1.0,
						"and the inspection lets her through")
				_run_the_traps_warning("robber_giving_chase", player.global_position)
				t.check(director._trap == null and _warning_for(events, "robber_giving_chase") == null,
						"no robber is warned of or set on her by the inspected crossing")
				pursuers = 0
				for instance in events.instances():
					if instance.def.id in ["door_guard", "robber_giving_chase"] \
							and not instance.is_finished and not instance.is_leaving:
						pursuers += 1
				t.check(pursuers == 0, "and no guard or robber is live after her")
				t.check(director._contact.is_done, "the task stays done")
			player.free()
			director.free()
		_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS)
	GameState.attempt_spend.city_state = saved_state

## feathery-marmot, day 9 let through after the inspection — the ordinary way through a door
## (`CheckpointController.release_finished_holds()`, which puts her down on the far side of the
## gatehouse that held her and announces `door_crossed` with that gatehouse's position). On the test
## city's day 9, its mark read: being held at another door's gatehouse and let out completes nothing;
## being held at a gatehouse of the named door and let out on its far side completes the task, from
## either side, and sends the robber after her from where she was let out, never through the door.
func _test_day_nine_completes_when_she_is_let_through_after_the_inspection(t) -> void:
	_build_city(t)
	var saved_state := GameState.attempt_spend.city_state
	_with_clean_run(func() -> void:
		var crossings := 0
		var elsewhere := 0
		for entry_side: float in [1.0, -1.0]:
			_city.events.stream_radius = INF
			var read := _read_the_mark_on(t, 9, SEED)
			var director: ResistanceDirector = read[0]
			var player: Stroller = read[2]
			var events := _city.events
			events.use_player(player)
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
					events.checkpoints._door_entry_side[instance] = -entry_side
					events.checkpoints.release_finished_holds()
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
						t.check(CheckpointController.where_she_crossed(body.position, body.facing,
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
	GameState.attempt_spend.city_state = saved_state

## Walks her across a door's line at `at`, along `axis` in `direction`, in one step the way
## `CheckpointController.watch_the_door_lines()` reads a frame: from 40px on one side to 40px on
## the other, and stands there while the crossing's warning runs.
func _walk_through(at: Vector2, axis: Vector2, direction: float, player: Stroller) -> void:
	var events := _city.events
	events.use_player(player)
	player.global_position = at - axis * 40.0 * direction
	events.checkpoints._last_seen_at = Vector2.INF
	events.checkpoints.watch_the_door_lines()
	player.global_position = at + axis * 40.0 * direction
	events.checkpoints.watch_the_door_lines()
	# And stays across while the crossing's warning runs (`CheckpointController.CROSSING_WARNING`), so a crossing
	# that sets a guard on her has set him by the time this returns.
	for i in int(ceil(CheckpointController.CROSSING_WARNING / STEP)) + 1:
		events.checkpoints.watch_the_door_lines(STEP)

# A mark and every contact stand on ground clear of a solid body, or on the item itself, and are
# reached from such ground — `CityMap.is_obstructed()`, filled by `EventManager.start_day()` from
# the day's whole plan before this director places anything (`main.gd`'s own day order:
# `_city.events.start_day()` runs before `_resistance.start_day()`), and `_pick_reachable()`
# refuses a drawn tile with a body on it.
