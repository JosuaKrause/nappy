extends "res://tests/resistance_rig.gd"
## Day 9's door: the task is done by crossing it, not by standing at it, and what the guard and the hut do about a crossing.
##
## Every attempt builds its city in a run of its own (`_build_city_in_a_new_run()`) and plays day 9
## on it, so no test leans on a guard, a crossing or a hold an earlier one left. What the director and the
## checkpoints have done is read from the street: the door the arrow ends on (`_door_position()`), the
## guard and the robber among the city's live instances (`_guard_after_her()`, `_robber_after_her()`),
## the hand a gatehouse's guard raises (`_a_guard_warns_her()`) and `_a_guard_is_after_her()`. She is put down at the start of a walk the way the game puts her down
## (`Stroller.teleport_to()`: an outright move, which the next look at her compares nothing across).

func run(t) -> void:
	_test_day_nine_is_done_by_crossing_the_door_not_by_standing_at_it(t)
	await _test_standing_at_the_door_completes_nothing(t)
	_test_a_crossing_taken_back_does_not_do_day_nine(t)
	_test_a_crossing_held_behind_another_door_counts_only_with_its_guard(t)
	_test_a_hut_ends_the_guard_the_walk_under_sets_and_sends_nobody(t)
	_test_day_nine_completes_when_she_is_let_through_after_the_inspection(t)
	await _test_the_frames_see_a_crossing(t)
	_free_city()

## Day 9 on a city of its own, every door in the world: `[director with the task active, her rig]`,
## her handed to the city's events as the game does. Frees what an earlier attempt left standing.
func _day_nine(t) -> Array:
	_build_city_in_a_new_run(t)
	_city.events.stream_radius = INF
	var read := _read_the_mark_on(t, 9, SEED)
	var player: Stroller = read[2]
	_city.events.use_player(player)
	return [read[0], player]

func _end_the_attempt(director: ResistanceDirector, player: Stroller) -> void:
	player.free()
	director.free()

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
	var crossings := 0
	var gatehouse := Vector2.INF
	for direction: float in [1.0, -1.0]:
		var day := _day_nine(t)
		var director: ResistanceDirector = day[0]
		var player: Stroller = day[1]
		var events := _city.events
		var walks_told: Array[String] = []
		events.trace = RunTrace.recording(walks_told)
		var step := director.current_step()
		t.check(step != null and step.target_kind == ResistanceSteps.TargetKind.DOOR,
				"day 9's mark puts the crossing on offer")
		if step == null or _door_position(director) == Vector2.INF:
			_end_the_attempt(director, player)
			continue
		var house := director.contact_position()
		t.check(gatehouse == Vector2.INF or house.distance_to(gatehouse) < 0.5,
				"the arrow ends on the same gatehouse every time the day is played (%s)" % house)
		gatehouse = house
		var at_a_house := false
		for body in _city.streets.region_plan().door_bodies:
			if body.def.redetains and body.position.distance_to(house) < 0.5:
				at_a_house = true
		t.check(at_a_house and director.red_arrow_target() == house,
				"and on a gatehouse of today's district doors")
		# Another door's line first: nothing — and that crossing is seen happening, so the check
		# is not vacuous.
		var walked_before := _walks_under(walks_told)
		for body in _city.streets.region_plan().door_bodies:
			if body.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED \
					and body.position.distance_to(_door_position(director)) > 200.0:
				_walk_through(body.position, body.facing, direction, player)
				break
		t.check(_walks_under(walks_told) > walked_before,
				"another district door's line was walked through")
		t.check(not director.contact().is_done, "crossing another district door completes nothing")
		# **Only one walk-under guard exists at a time**, and that other door has just set one
		# on her: left alone, the named crossing below spawns nobody and the check on a guard
		# after her passes on this first one. So he is finished first and the named crossing
		# has to set a guard of its own.
		var first_guard := _guard_after_her(events)
		t.check(first_guard != null and first_guard.def.id == "door_guard",
				"the other door's walk under set its own guard on her")
		if first_guard:
			first_guard.give_up_the_chase()
		_walk_through(_door_position(director), _door_axis(director), direction, player)
		if director.contact().is_done:
			crossings += 1
		t.check(_robber_after_her(events) == null
				and _warning_for(events, "robber_giving_chase") == null,
				"walking under the named door's boom sends no robber after her, nor warns of one")
		var guard := _guard_after_her(events)
		t.check(guard != null and guard != first_guard and guard.def.id == "door_guard"
				and _a_guard_is_after_her(events),
				"the named door's own, new guard is after her instead")
		if guard:
			t.check(guard.global_position.distance_to(_door_position(director))
					< Tuning.STREET_WIDTH * Tuning.TILE_SIZE
					and guard.global_position.distance_to(first_guard.global_position
							if first_guard else Vector2.INF) > 100.0,
					"and he steps out of the named door's hut, not the other door's (%.0fpx from it, %.0fpx from the other's)"
					% [guard.global_position.distance_to(_door_position(director)),
					guard.global_position.distance_to(first_guard.global_position
							if first_guard else Vector2.INF)])
		_end_the_attempt(director, player)
	t.check(crossings == 2,
			"walking through the named door completes the task, in either direction (%d of 2)"
			% crossings)

## Standing at the named gatehouse, or on the door's line under the boom, completes nothing: her
## touch is the manager's own frame with her put down there (the hold a gatehouse starts needs
## its seconds to run before it lets her through, so one frame is only the touch).
func _test_standing_at_the_door_completes_nothing(t) -> void:
	for direction: float in [1.0, -1.0]:
		var day := _day_nine(t)
		var director: ResistanceDirector = day[0]
		var player: Stroller = day[1]
		if _door_position(director) == Vector2.INF:
			t.check(false, "day 9's door is named")
			_end_the_attempt(director, player)
			continue
		var here := director.contact_position() if direction > 0.0 else _door_position(director)
		player.teleport_to(here)
		await _step_a_frame(t)
		t.check(not director.contact().is_done,
				"standing at the gatehouse or under the boom completes nothing (%s)"
				% ("gatehouse" if direction > 0.0 else "boom"))
		_end_the_attempt(director, player)

## Review 4 of PR #781, day 9: **a walked crossing counts only once it stands.** Under the named
## door's raised boom the crossing starts its warning
## (`CheckpointController._start_the_crossing_warning()`, `CheckpointController.CROSSING_WARNING`); she steps
## back across the line halfway through it, so the crossing is called off and no guard comes,
## and the task is not done either, however long she then waits: `door_crossed` is sent only
## when the warning has run with her still across. Walked through and staying across, the same
## door then does the task, with its guard after her.
func _test_a_crossing_taken_back_does_not_do_day_nine(t) -> void:
	for direction: float in [1.0, -1.0]:
		var day := _day_nine(t)
		var director: ResistanceDirector = day[0]
		var player: Stroller = day[1]
		var events := _city.events
		if _door_position(director) == Vector2.INF:
			t.check(false, "day 9's door is named")
			_end_the_attempt(director, player)
			continue
		var at := _door_position(director)
		var axis := _door_axis(director)
		_step_to(player, at - axis * 40.0 * direction, true)
		_step_to(player, at + axis * 40.0 * direction)
		t.check(_a_guard_warns_her(events), "walking under the named boom starts its warning")
		for i in int(round(CheckpointController.CROSSING_WARNING * 0.5 / STEP)):
			events.checkpoints.watch_the_door_lines(STEP)
		t.check(not director.contact().is_done,
				"halfway through the crossing's warning the task is not done yet")
		_step_to(player, at - axis * 40.0 * direction)
		t.check(not _a_guard_warns_her(events), "stepping back across calls the crossing off")
		for i in int(ceil(CheckpointController.CROSSING_WARNING * 2.0 / STEP)):
			events.checkpoints.watch_the_door_lines(STEP)
		var guard_before := _guard_after_her(events)
		t.check(not director.contact().is_done and not _a_guard_is_after_her(events),
				"a crossing taken back does not do the task, and sets no guard on her")
		_walk_through(at, axis, direction, player)
		var guard := _guard_after_her(events)
		t.check(director.contact().is_done and guard != null and guard != guard_before
				and _a_guard_is_after_her(events),
				"walked through and staying across, the same door does the task, its guard after her")
		_end_the_attempt(director, player)

## Reviews 5 and 6 of PR #781, day 9 at two doors: **a walked crossing counts only if she is still
## across that door's line when a guard is set on her for it.** She walks under another door A's
## raised boom (A's warning starts) and then, inside A's 2s, under the named door B or not, which
## starts no warning of its own while A's runs (`CheckpointController._held_crossings`). Every
## combination is walked: B not crossed, crossed and stayed across, or crossed and taken back; A
## then stayed across or taken back before its 2s. A's guard comes exactly when she stays across
## A, and the task is done exactly when she is across both when he comes. She is put down between
## the two doors, so the step is not seen as a walk across anything.
func _test_a_crossing_held_behind_another_door_counts_only_with_its_guard(t) -> void:
	for a_stays: bool in [true, false]:
		for b_walk: String in ["none", "stays", "back"]:
			var day := _day_nine(t)
			var director: ResistanceDirector = day[0]
			var player: Stroller = day[1]
			var events := _city.events
			var b_at := _door_position(director)
			var b_axis := _door_axis(director)
			var a_at := Vector2.INF
			var a_axis := Vector2.ZERO
			# Another door's boom with the named door well to one side of its line, so that she
			# can be across A's line while she stands at B.
			for body in _city.streets.region_plan().door_bodies:
				if body.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED and body.position.distance_to(b_at) > 200.0 \
						and absf((b_at - body.position).dot(body.facing)) > 100.0:
					a_at = body.position
					a_axis = body.facing
					break
			t.check(b_at != Vector2.INF and a_at != Vector2.INF, "day 9 names a door and has another")
			if b_at == Vector2.INF or a_at == Vector2.INF:
				_end_the_attempt(director, player)
				continue
			var name := "A %s, B %s" % ["stayed across" if a_stays else "taken back", {
					"none": "not crossed", "stays": "stayed across", "back": "taken back"}[b_walk]]
			# Across A toward B's side of A's line, so that standing at B she is still across A.
			var a_dir := signf((b_at - a_at).dot(a_axis))
			_step_to(player, a_at - a_axis * 40.0 * a_dir, true)
			_step_to(player, a_at + a_axis * 40.0 * a_dir)
			t.check(_a_guard_warns_her(events), "%s: walking under A's boom starts its warning" % name)
			if b_walk != "none":
				_step_to(player, b_at - b_axis * 40.0, true)
				_step_to(player, b_at + b_axis * 40.0)
				t.check(not director.contact().is_done,
						"%s: under the named door while A's warning runs, nothing is done yet" % name)
				if b_walk == "back":
					_step_to(player, b_at - b_axis * 40.0)
			if not a_stays:
				_step_to(player, a_at + a_axis * 40.0 * a_dir, true)
				_step_to(player, a_at - a_axis * 40.0 * a_dir)
			for i in int(ceil(CheckpointController.CROSSING_WARNING * 2.0 / STEP)):
				events.checkpoints.watch_the_door_lines(STEP)
			var chased := _a_guard_is_after_her(events)
			var done_expected := a_stays and b_walk == "stays"
			t.check(chased == a_stays and director.contact().is_done == done_expected,
					"%s: A's guard %s and the task is %s" % [name,
					"comes" if a_stays else "does not come", "done" if done_expected else "not done"])
			_end_the_attempt(director, player)

## lilac-marmot (inbox #651), day 9's walk under the named boom and then a hut: *"Let's not send the
## robber in that case and stop the chase. It's a fair cheat getting through the barrier is hard
## enough. Well earned if the player pulls it off."* She walks under the named door's raised boom
## (the task is done, one `door_guard` steps out of the hut nearer to her), then steps into a hut of
## that door: the hold ends the guard's chase
## (`CheckpointController._end_the_guard_for_a_hold()`), and nobody else is sent — no robber
## warned of or set on her, no second guard.
func _test_a_hut_ends_the_guard_the_walk_under_sets_and_sends_nobody(t) -> void:
	for direction: float in [1.0, -1.0]:
		var day := _day_nine(t)
		var director: ResistanceDirector = day[0]
		var player: Stroller = day[1]
		var events := _city.events
		if _door_position(director) == Vector2.INF:
			t.check(false, "day 9's door is named")
			_end_the_attempt(director, player)
			continue
		events.stream_around(player.global_position)
		_walk_through(_door_position(director), _door_axis(director), direction, player)
		t.check(director.contact().is_done, "walking under the named boom does the task")
		var guard := _guard_after_her(events)
		t.check(guard != null and guard.def.id == "door_guard" and _a_guard_is_after_her(events)
				and not guard.gave_up,
				"and sets the door's guard after her")
		t.check(_robber_after_her(events) == null and _warning_for(events, "robber_giving_chase") == null,
				"and no robber")
		var hut := _hut_of_the_named_door(director)
		t.check(hut != null, "the named door has a hut to step into")
		if guard and hut:
			player.teleport_to(hut.global_position)
			events.checkpoints.check_detentions()
			t.check(hut.is_chatting(), "stepping into the hut is a hold")
			t.check(guard.gave_up and (guard.is_leaving or guard.is_finished),
					"the hold ends the walk under's guard: he gives up")
			t.check(_robber_after_her(events) == null and _warning_for(events, "robber_giving_chase") == null,
					"no robber is warned of or set on her for it")
			var pursuers := 0
			for instance in events.instances():
				if instance.def.id == "door_guard" and not instance.is_finished \
						and not instance.is_leaving:
					pursuers += 1
			t.check(pursuers == 0 and _door_guards(events).all(func(each: EventInstance) -> bool: return each == guard),
					"and nobody else is sent: no second guard is after her")
			t.check(director.contact().is_done, "the task stays done")
			# **The moment day 9 sends the robber is the end of the hold**: the inspection
			# lets her through (`CheckpointController._release_finished_holds()`,
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
			events.checkpoints.check_detentions()
			# She stood at the hut's own centre, so which side she is put down on is not measured
			# here; only the release moves her, so being moved is being let through.
			t.check(player.global_position.distance_to(before) > 1.0,
					"and the inspection lets her through")
			_run_the_traps_warning("robber_giving_chase", player.global_position)
			t.check(_robber_after_her(events) == null and _warning_for(events, "robber_giving_chase") == null,
					"no robber is warned of or set on her by the inspected crossing")
			pursuers = 0
			for instance in events.instances():
				if instance.def.id in ["door_guard", "robber_giving_chase"] \
						and not instance.is_finished and not instance.is_leaving:
					pursuers += 1
			t.check(pursuers == 0, "and no guard or robber is live after her")
			t.check(director.contact().is_done, "the task stays done")
		_end_the_attempt(director, player)

## feathery-marmot, day 9 let through after the inspection — the ordinary way through a door
## (`CheckpointController._release_finished_holds()`, which puts her down on the far side of the
## gatehouse that held her and announces `door_crossed` with that gatehouse's position). On the test
## city's day 9, its mark read: being held at another door's gatehouse and let out completes nothing;
## being held at a gatehouse of the named door and let out on its far side completes the task, from
## either side, and sends the robber after her from where she was let out, never through the door.
## The hold is the game's own: she steps within a gatehouse's reach (`check_detentions()`), the
## conversation runs its clock out, and the release puts her down.
func _test_day_nine_completes_when_she_is_let_through_after_the_inspection(t) -> void:
	var crossings := 0
	var elsewhere := 0
	for entry_side: float in [1.0, -1.0]:
		var day := _day_nine(t)
		var director: ResistanceDirector = day[0]
		var player: Stroller = day[1]
		var events := _city.events
		if _door_position(director) == Vector2.INF:
			t.check(false, "day 9's door is named")
			_end_the_attempt(director, player)
			continue
		events.stream_around(player.global_position)
		var named := _hut_of_the_named_door(director)
		var other: EventInstance = null
		for instance in events.instances():
			if instance.def.redetains and instance.def.id == "checkpoint_hut" \
					and instance != named and (named == null or not _on_the_named_door(
							director, instance)):
				other = instance
				break
		t.check(named != null and other != null,
				"the named door's gatehouse and another door's are in the world")
		if named and other:
			for instance: EventInstance in [other, named]:
				player.teleport_to(instance.global_position
						- instance.facing_now() * 60.0 * entry_side)
				events.checkpoints.check_detentions()
				var guard_steps := int(round(EventCatalogue.CHECKPOINT_DETAIN_SECONDS / STEP)) + 10
				while instance.is_chatting() and guard_steps > 0:
					guard_steps -= 1
					for each in events.instances():
						each.step(STEP)
				events.checkpoints.check_detentions()
				if instance == other:
					if not director.contact().is_done:
						elsewhere += 1
			if director.contact().is_done:
				crossings += 1
			t.check(_robber_after_her(events) == null
					and _warning_for(events, "robber_giving_chase") != null,
					"the inspected crossing warns of the robber first, with nobody in the world")
			_run_the_traps_warning("robber_giving_chase", player.global_position)
			var trap := _robber_after_her(events)
			t.check(trap != null and trap.def.id == "robber_giving_chase",
					"the inspected crossing sends the robber after her")
			if trap:
				for body in _city.streets.region_plan().door_bodies:
					t.check(not DoorLine.crossed_by(body.position, body.facing,
							body.def.obstructs_radius, trap.global_position,
							player.global_position),
							"his run at her from %s never crosses a district door's line"
							% _city.map.world_to_tile(trap.global_position))
				# A finished pursuer is no longer in the world, so the director stops naming him.
				events.retire(trap)
				t.check(_robber_after_her(events) == null,
						"a robber retired from the world is no longer her trap")
		_end_the_attempt(director, player)
	t.check(elsewhere == 2, "being let through another door completes nothing (%d of 2)"
			% elsewhere)
	t.check(crossings == 2,
			"being let through the named door after the inspection completes it, from either side (%d of 2)"
			% crossings)

## The manager's own frames see a crossing: on day 9, she is put down beside the named boom and
## walks across its line a frame later, and the crossing starts its warning without any call
## to the checkpoints (`EventManager` runs `watch_the_door_lines()` every physics frame).
func _test_the_frames_see_a_crossing(t) -> void:
	var day := _day_nine(t)
	var director: ResistanceDirector = day[0]
	var player: Stroller = day[1]
	var events := _city.events
	var walks_told: Array[String] = []
	events.trace = RunTrace.recording(walks_told)
	if _door_position(director) == Vector2.INF:
		t.check(false, "day 9's door is named")
		_end_the_attempt(director, player)
		return
	var at := _door_position(director)
	var axis := _door_axis(director)
	var walked_before := _walks_under(walks_told)
	player.teleport_to(at - axis * 40.0)
	await _step_a_frame(t)
	t.check(not _a_guard_warns_her(events), "put down beside the boom, no crossing is warning her")
	player.global_position = at + axis * 40.0
	await _step_a_frame(t)
	t.check(_walks_under(walks_told) > walked_before
			and _a_guard_warns_her(events),
			"a frame after she walks across the named boom's line its crossing is warning her")
	_end_the_attempt(director, player)

## Whether `instance` is a body of the door day 9 names: on its cross-street line and within its reach.
func _on_the_named_door(director: ResistanceDirector, instance: EventInstance) -> bool:
	return absf((instance.global_position - _door_position(director)).dot(_door_axis(director))) < 1.0 \
			and instance.global_position.distance_to(_door_position(director)) \
			< Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5

## The door day 9 names, as the arrow has it: the boom (or, on a door with no boom today, the
## first gatehouse) of the district door whose segment holds the gatehouse the contact stands on
## (`region_plan().doors`, `door_bodies`), as `[position, street axis]`, or `[Vector2.INF,
## Vector2.ZERO]` where the contact is on no door. **A deliberate copy of the rule in
## `ResistanceDirector._a_gatehouse_of_the_door_at()`**, kept as an oracle: a change to one finds
## the other, since a drift turns the named-door walk red.
func _named_door(director: ResistanceDirector) -> Array:
	var house := director.contact_position()
	var region_plan := _city.streets.region_plan()
	if region_plan == null or house == Vector2.INF:
		return [Vector2.INF, Vector2.ZERO]
	for segment in region_plan.doors:
		var area := _city.map.tile_rect_to_world(segment.tile_rect())
		if not area.has_point(house):
			continue
		var boom: EventScheduler.Planned = null
		var first_house: EventScheduler.Planned = null
		for body in region_plan.door_bodies:
			if not area.has_point(body.position):
				continue
			if body.def.solid_when == EventDef.SolidWhen.WHILE_LOWERED:
				boom = body
			elif body.def.redetains and (first_house == null or body.position.x < first_house.position.x
					or (body.position.x == first_house.position.x
					and body.position.y < first_house.position.y)):
				first_house = body
		var line := boom if boom != null else first_house
		if line != null:
			return [line.position, line.facing]
	return [Vector2.INF, Vector2.ZERO]

func _door_position(director: ResistanceDirector) -> Vector2:
	return _named_door(director)[0]

func _door_axis(director: ResistanceDirector) -> Vector2:
	return _named_door(director)[1]

## Every `door_guard` in the city's instances, in the order they were put there: the guards a walked
## crossing sets on her, the one still after her last.
func _door_guards(events: EventManager) -> Array[EventInstance]:
	var found: Array[EventInstance] = []
	for instance in events.instances():
		if instance.def.id == "door_guard":
			found.append(instance)
	return found

## How many walks across a door's line the run log told of: the `checkpoint` line
## `CheckpointController.watch_the_door_lines()` writes for each, none for a release through it.
func _walks_under(told: Array[String]) -> int:
	var found := 0
	for line in told:
		if line.contains("walked through, heading"):
			found += 1
	return found

## The guard a walked crossing set on her last, in the world, or null.
func _guard_after_her(events: EventManager) -> EventInstance:
	var guards := _door_guards(events)
	return guards.back() if not guards.is_empty() else null

## Whether the guard a walked crossing set on her is still on her: in the world, neither finished
## nor leaving.
func _a_guard_is_after_her(events: EventManager) -> bool:
	var guard := _guard_after_her(events)
	return guard != null and not guard.is_finished and not guard.is_leaving

## The robber the done task has set on her, in the world and not finished, or null: his warning is
## not him, so none is named until it has run.
func _robber_after_her(events: EventManager) -> EventInstance:
	for instance in events.instances():
		if instance.def.id == "robber_giving_chase" and not instance.is_finished:
			return instance
	return null

## Whether a crossing is warning her: a gatehouse's guard has his hand raised at her
## (`EventInstance.guard_warns_her`), as the manager sets it every frame
## (`CheckpointController.warn_at_the_doors()`). Calls it first, which sets the hands and counts a
## raised one once: idempotent against the manager's own per-frame call, so a drive and not only a read.
func _a_guard_warns_her(events: EventManager) -> bool:
	events.checkpoints.warn_at_the_doors()
	for instance in events.instances():
		if instance.def.redetains and instance.guard_warns_her:
			return true
	return false

## The named door's `checkpoint_hut` in the street, or null.
func _hut_of_the_named_door(director: ResistanceDirector) -> EventInstance:
	for instance in _city.events.instances():
		if instance.def.id == "checkpoint_hut" and _on_the_named_door(director, instance):
			return instance
	return null

## One look at her: she is at `at`, and the checkpoints take their per-frame look
## (`CheckpointController.watch_the_door_lines()`). With `jump`, she is put down there first
## (`Stroller.teleport_to()`), so the step is not seen as a walk across anything.
func _step_to(player: Stroller, at: Vector2, jump := false) -> void:
	if jump:
		player.teleport_to(at)
	else:
		player.global_position = at
	_city.events.checkpoints.watch_the_door_lines(STEP)

## Walks her across a door's line at `at`, along `axis` in `direction`, in one step the way
## `CheckpointController.watch_the_door_lines()` reads a frame: from 40px on one side to 40px on
## the other, and stands there while the crossing's warning runs.
func _walk_through(at: Vector2, axis: Vector2, direction: float, player: Stroller) -> void:
	var events := _city.events
	player.teleport_to(at - axis * 40.0 * direction)
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
