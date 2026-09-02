extends RefCounted
## The heat: what completing resistance tasks does to the city, and the contracts that keep the
## escalation from being a difficulty dial nobody checked.
##
## **The load-bearing test in here is the first one.** Every fairness contract in the game is
## asserted on load, from data — so a row that gets worse with the resistance and is only ever
## validated cold has its contract stated about precisely the harmless version of itself. Progress
## is a bounded integer, so the whole set of shapes exists and all of it is checkable.

const SEED := 8817
const STEP := 1.0 / 60.0

var _map: CityMap

func run(t) -> void:
	_map = CityGenerator.generate(SEED)
	_test_every_shape_of_every_row_is_fair(t)
	_test_a_row_that_answers_to_nothing_is_untouched(t)
	_test_heat_is_derived_once_and_kept(t)
	_test_the_ladder_has_a_top(t)
	_test_a_hunts_row_wakes_up_at_its_own_threshold(t)
	_test_a_day_is_a_function_of_its_heat(t)
	_test_the_patrol_presses_more_and_louder(t)
	_test_the_patrol_investigates_past_the_threshold(t)
	_test_it_patrols_while_it_waits(t)
	_test_a_patrol_that_never_notices_drives_off_its_route(t)
	_test_the_patrol_chases_once_it_notices(t)
	_test_a_streamed_patrol_resumes_where_it_left_off(t)
	_test_a_streamed_patrol_mid_chase(t)
	_test_a_hot_day_places_more_patrols(t)

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

# ------------------------------------------------------------- the contracts ---

## Every row, at every level the resistance can reach, satisfies the contract it satisfies cold.
##
## `EventDef.validate()` pushes an error rather than returning quietly on the interesting failures,
## so a break here shows up twice — as a failed check and as the boot error `tools/check.sh` fails
## on. That is deliberate: this is the one property whose absence is invisible in play until the
## day somebody dies to an unfair event they could not have seen coming.
func _test_every_shape_of_every_row_is_fair(t) -> void:
	for def in EventCatalogue.all():
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(def, level)
			t.check(hot.validate(), "'%s' is fair at heat %d" % [def.id, level])
			t.check(hot.id == def.id, "heat does not change what '%s' is" % def.id)

## The non-lethal rung stays non-lethal, and it is checked over the response rather than over the
## one row that carries it: the whole instruction this came from is that the ladder has two rungs
## and only the top one kills, so a second `PRESSES` row added later inherits the promise.
func _test_the_ladder_has_a_top(t) -> void:
	for def in EventCatalogue.all():
		if def.heat_response != EventDef.HeatResponse.PRESSES:
			continue
		for level in EventCatalogue.heat_levels():
			t.check(not EventCatalogue.heated(def, level).hard_fail,
					"'%s' presses without ever becoming lethal (heat %d)" % [def.id, level])

## The lethal rung: below its own threshold a `HUNTS` row is untouched, and at or above it, it
## pursues, keeps `hard_fail`, and its derived numbers satisfy the pursuit contract measured from
## its own data. Checked over the response rather than over the one row that carries it, the same
## shape `_test_the_ladder_has_a_top` uses, so a second `HUNTS` row added later inherits the promise
## without anybody having to remember to extend this loop.
func _test_a_hunts_row_wakes_up_at_its_own_threshold(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.heat_response != EventDef.HeatResponse.HUNTS:
			continue
		checked += 1
		for level in EventCatalogue.heat_levels():
			var hot := EventCatalogue.heated(def, level)
			var should_hunt := level >= Tuning.HEAT_HUNTS_LEVEL
			t.check(hot.pursues == should_hunt,
					"'%s' heat %d: it hunts iff at or past its own threshold" % [def.id, level])
			# Population and intensity are `PRESSES`'s axes, never this one's — at every level,
			# not only below the threshold, since a `HUNTS` row has nothing else to move.
			t.check(hot.max_per_day == def.max_per_day and hot.intensity == def.intensity,
					"'%s' heat %d: hunting moves neither population nor intensity"
					% [def.id, level])
			if not should_hunt:
				continue
			t.check(hot.hard_fail, "'%s' heat %d: the lethal rung stays lethal" % [def.id, level])
			# The pursuit contract restated as the distances it is actually played over: the
			# stand-off she is owed, then the trigger, then the edge of the field — each strictly
			# inside the next, which is what `Tuning.validate_pursuit` also checks at boot.
			var standoff := Tuning.pursuit_standoff(hot.pursue_speed, hot.inner_radius)
			t.check(standoff < hot.pursues_within and hot.pursues_within <= hot.outer_radius,
					"'%s' heat %d: stand-off %.0f < trigger %.0f <= field %.0f"
					% [def.id, level, standoff, hot.pursues_within, hot.outer_radius])
	t.check(checked > 0, "and there is a HUNTS row to check")

# ------------------------------------------------------------- the derivation ---

## A row that answers to nothing is the *same object* at every level, not merely an equal one.
## Identity rather than equality because the cost of getting this wrong is not a wrong number, it
## is a duplicate `Resource` per candidate placement per day.
func _test_a_row_that_answers_to_nothing_is_untouched(t) -> void:
	var untouched := 0
	for def in EventCatalogue.all():
		if def.heat_response != EventDef.HeatResponse.NONE:
			continue
		untouched += 1
		for level in EventCatalogue.heat_levels():
			t.check(EventCatalogue.heated(def, level) == def,
					"'%s' answers to nothing, so heat %d hands back the row itself"
					% [def.id, level])
	t.check(untouched > 0, "most of the catalogue answers to nothing")

func _test_heat_is_derived_once_and_kept(t) -> void:
	for def in EventCatalogue.all():
		# Cold is always the row itself, whatever the row answers to: level zero is *no* heat
		# rather than a little of it.
		t.check(EventCatalogue.heated(def, 0) == def,
				"'%s' at heat 0 is the catalogue's own row" % def.id)
		if def.heat_response == EventDef.HeatResponse.NONE:
			continue
		t.check(EventCatalogue.heated(def, 1) == EventCatalogue.heated(def, 1),
				"'%s' is derived once at a level and kept" % def.id)
		t.check(EventCatalogue.heated(def, 1) != def,
				"'%s' answers to heat, so heat gives back something else" % def.id)
		# Progress can reach five over the five tasks while four is what qualifies, so the top of
		# the ladder has to be a ceiling rather than a number the arithmetic runs past.
		t.check(EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL + 1).intensity
						== EventCatalogue.heated(def, Tuning.RESISTANCE_GOAL).intensity,
				"'%s' cannot be heated past the goal" % def.id)

# --------------------------------------------------------------------- a day ---

## A planned day is a function of its arguments and heat is one of them: same seed, same day, same
## heat, same city. This is what lets a rig plan a hot day without a run having happened.
func _test_a_day_is_a_function_of_its_heat(t) -> void:
	var day := 9
	var consumed: Array[String] = []
	var first := EventScheduler.build_day(day, _rng(day), _map, consumed.duplicate(),
			[], [], null, Tuning.RESISTANCE_GOAL)
	var second := EventScheduler.build_day(day, _rng(day), _map, consumed.duplicate(),
			[], [], null, Tuning.RESISTANCE_GOAL)
	t.check(first.size() == second.size(),
			"a hot day planned twice is the same day (%d vs %d)" % [first.size(), second.size()])
	for i in mini(first.size(), second.size()):
		t.check(first[i].def.id == second[i].def.id and first[i].position == second[i].position,
				"placement %d of a hot day is where it was" % i)
	# And nothing in the heated catalogue can plan a day that has no park left to walk to — the
	# guarantee `_ensure_one_usable_park` makes cold has to survive the escalation.
	t.check(not first.is_empty(), "a hot day places events at all")

# ------------------------------------------------------------ the patrol presses ---
# `police_patrol` is the first row to actually carry `PRESSES` — everything above this line was
# checked against a catalogue where the loops had nothing to bite. These are stated as
# relationships wherever the design lets them be, per CLAUDE.md's own rule about numbers with a
# short shelf life, rather than as the literal figures Tuning's comments already carry.

func _cold_patrol() -> EventDef:
	return EventCatalogue.by_id("police_patrol")

## More of them, and louder, and monotonically so across every level the resistance can reach —
## not just cold vs. full heat, which would pass even if the ladder dipped in the middle.
func _test_the_patrol_presses_more_and_louder(t) -> void:
	var cold := _cold_patrol()
	t.check(cold.heat_response == EventDef.HeatResponse.PRESSES,
			"the patrol answers to the resistance, the non-lethal way")
	var last_population := cold.max_per_day
	var last_intensity := cold.intensity
	for level in range(1, EventCatalogue.heat_levels()):
		var hot := EventCatalogue.heated(cold, level)
		t.check(hot.max_per_day >= last_population,
				"the patrol's population never drops between heat %d and %d" % [level - 1, level])
		t.check(hot.intensity >= last_intensity,
				"and neither does what it costs to stand near it (heat %d)" % level)
		last_population = hot.max_per_day
		last_intensity = hot.intensity
	var full := EventCatalogue.heated(cold, Tuning.RESISTANCE_GOAL)
	t.check(full.max_per_day > cold.max_per_day,
			"and at full heat there really are more of them (%d vs %d)"
			% [full.max_per_day, cold.max_per_day])
	t.check(full.intensity > cold.intensity,
			"and it really does cost more to stand near (%.1f vs %.1f)"
			% [full.intensity, cold.intensity])
	# The escalation moves population and intensity, deliberately not the radii: a wider field
	# would silently owe a longer telegraph than the row ships with. See M56's decision record.
	t.check(full.inner_radius == cold.inner_radius and full.outer_radius == cold.outer_radius,
			"the field itself does not widen — only what is inside it changes")

## It does not investigate below the threshold, and does at and above it — checked over every
## level rather than just the two ends, since a threshold is exactly the kind of thing an
## off-by-one hides in.
func _test_the_patrol_investigates_past_the_threshold(t) -> void:
	var cold := _cold_patrol()
	for level in EventCatalogue.heat_levels():
		var hot := EventCatalogue.heated(cold, level)
		var should_investigate := level >= Tuning.HEAT_INVESTIGATES_LEVEL
		t.check(hot.pursues == should_investigate,
				"heat %d: the patrol investigates iff it is at or past the threshold" % level)
		if should_investigate:
			t.check(hot.pursue_speed > Tuning.WALK_SPEED and hot.pursue_speed < Tuning.RUN_SPEED,
					"heat %d: and it comes at a speed strictly between a walk and a run" % level)

## A waiting pursuer with a route runs it rather than standing at attention. Sited far from her so
## it is never noticed, a heated patrol has to actually cover ground along its path while
## `is_waiting()` stays true — the whole character of "mobile, unhurried, along a corridor" the
## row's own docstring claims, which a pursuer that merely stood still waiting would have thrown
## away the moment it started answering to heat.
func _test_it_patrols_while_it_waits(t) -> void:
	var hot := EventCatalogue.heated(_cold_patrol(), Tuning.RESISTANCE_GOAL)
	t.check(hot.pursues and hot.mobile, "the fully heated patrol is a mobile pursuer")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(4000.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(hot, path[0], path)
	t.add_child(instance)
	instance.set_process(false)
	# Nowhere near her own trigger radius, so nothing here is about noticing.
	var far := Vector2(200000.0, 200000.0)
	instance.player_at = far
	var start := instance.position
	for i in int(round(3.0 / STEP)):
		instance.player_at = far
		instance._process(STEP)
	t.check(instance.is_waiting(), "three seconds later it still has not noticed her")
	t.check(instance.position.distance_to(start) > 150.0,
			"and it has actually walked its route, not stood still (%.0fpx moved)"
			% instance.position.distance_to(start))
	instance.free()

## `_has_expired()` returns false for the whole time a pursuer is waiting, so a heated patrol that
## never notices her has to live until it drives off the end of its own route — the same "mobile
## row that reaches the end of a route it does not pace" rule every other mobile event already
## follows, arrived at through a different door. A short path so the test does not need the ninety
## seconds a scheduler-built 40-tile one would take to run out.
func _test_a_patrol_that_never_notices_drives_off_its_route(t) -> void:
	var hot := EventCatalogue.heated(_cold_patrol(), Tuning.RESISTANCE_GOAL)
	var path := PackedVector2Array([Vector2.ZERO, Vector2(300.0, 0.0)])
	var instance := EventInstance.new()
	instance.setup(hot, path[0], path)
	t.add_child(instance)
	instance.set_process(false)
	var far := Vector2(200000.0, 200000.0)
	instance.player_at = far
	var elapsed := 0.0
	while elapsed < 10.0 and not instance.is_leaving and not instance.is_finished:
		instance.player_at = far
		instance._process(STEP)
		elapsed += STEP
	t.check(instance.is_waiting(), "it never noticed her, the whole way down its route")
	t.check(instance.is_leaving or instance.is_finished,
			"and it still leaves once it drives off the end, exactly as a plain mobile row would")
	instance.free()

## Once she comes inside `pursues_within` it stops patrolling and chases, on the same contract
## every pursuer in the game is held to — the one rule to keep from the rig style in
## `tests/test_events.gd`: the player accelerates rather than snapping to `RUN_SPEED`, because a
## rig that starts at full speed passes even a pursuer with no break-off in it at all.
func _test_the_patrol_chases_once_it_notices(t) -> void:
	var hot := EventCatalogue.heated(_cold_patrol(), Tuning.RESISTANCE_GOAL)
	var instance := EventInstance.new()
	instance.setup(hot, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)

	var her := Vector2(hot.pursues_within - 10.0, 0.0)
	instance.player_at = her
	instance._process(STEP)
	t.check(not instance.is_waiting(), "she is inside the trigger, so it turns and notices her")

	# She holds still through the telegraph and the lunge, so what follows is only the chase.
	var telegraph_frames := 0
	while instance.is_telegraphing() and telegraph_frames < int(10.0 / STEP):
		instance.player_at = her
		instance._process(STEP)
		telegraph_frames += 1
	t.check(not instance.is_telegraphing(), "and the telegraph actually ends")

	# Now she runs, accelerating rather than teleporting to speed.
	var speed := 0.0
	var elapsed := 0.0
	var opened_from := instance.global_position.distance_to(her)
	while elapsed < 6.0 and not instance.gave_up and not instance.is_finished:
		speed = move_toward(speed, Tuning.RUN_SPEED, Tuning.ACCELERATION * STEP)
		her.x += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
	t.check(instance.gave_up, "running away from a fully heated patrol still works")
	var opened_to := instance.global_position.distance_to(her)
	t.check(opened_to > opened_from,
			"and the gap actually opened once she ran (%.0fpx -> %.0fpx)" % [opened_from, opened_to])
	instance.free()

## `EventInstance.resume()` restores age and distance travelled so a streamed-out event picks up
## where it left off rather than rewinding — checked here because a heated patrol is the first
## `mobile` row that is also a `pursues` one, and `resume()`'s own "if def.mobile and path.size() >
## 1: _advance_along_path(0.0)" line does not know or care whether the def pursues.
func _test_a_streamed_patrol_resumes_where_it_left_off(t) -> void:
	var hot := EventCatalogue.heated(_cold_patrol(), Tuning.RESISTANCE_GOAL)
	var path := PackedVector2Array([Vector2.ZERO, Vector2(4000.0, 0.0)])

	var first := EventInstance.new()
	first.setup(hot, path[0], path)
	t.add_child(first)
	first.set_process(false)
	var far := Vector2(200000.0, 200000.0)
	for i in int(round(3.0 / STEP)):
		first.player_at = far
		first._process(STEP)
	t.check(first.is_waiting(), "streamed out mid-patrol, still unnoticed")
	var age := first.age
	var travelled := first.path_travelled()
	var position_before := first.position
	first.free()

	# A fresh instance, exactly as `EventManager._stream_in` builds one.
	var second := EventInstance.new()
	second.setup(hot, path[0], path)
	t.add_child(second)
	second.resume(age, travelled)
	t.check(second.is_waiting(), "streamed back in, it is still only patrolling")
	t.close_to(second.position.x, position_before.x,
			"and it resumes where it left off rather than restarting its beat", 1.0)
	second.free()

## The other half of the same question, mid-chase rather than mid-patrol — and the honest answer
## rather than the hoped-for one. `resume()` restores `age` and the travelled distance, but not
## `_noticed_at`: a fresh `EventInstance` always starts with it at `INF`, so a patrol streamed out
## after it has noticed her comes back `is_waiting()` again, having forgotten the chase. That is
## safe rather than a fairness gap, because `PRESSES` never gains `hard_fail` — the worst this
## costs is a patrol that looks like it lost interest — and it is not new: `alley_robbery` has had
## the identical property since the `pursues_within` mechanic was built, just never in a position
## to be streamed out mid-chase, since a stationary pursuer's field never moves far enough from
## where the day planted it. This test pins the actual behaviour rather than the one the field
## name suggests, so the day this is fixed for every `pursues_within` row it fails here first.
func _test_a_streamed_patrol_mid_chase(t) -> void:
	var hot := EventCatalogue.heated(_cold_patrol(), Tuning.RESISTANCE_GOAL)
	var path := PackedVector2Array([Vector2.ZERO, Vector2(4000.0, 0.0)])

	var first := EventInstance.new()
	first.setup(hot, path[0], path)
	t.add_child(first)
	first.set_process(false)
	var her := Vector2(hot.pursues_within - 10.0, 0.0)
	first.player_at = her
	first._process(STEP)
	t.check(not first.is_waiting(), "she is inside the trigger, so it notices her")
	for i in int(round(1.0 / STEP)):
		first.player_at = her
		first._process(STEP)
	t.check(not first.is_waiting(), "and a second later it is still chasing, not patrolling")
	var age := first.age
	var travelled := first.path_travelled()
	first.free()

	var second := EventInstance.new()
	second.setup(hot, path[0], path)
	t.add_child(second)
	second.resume(age, travelled)
	t.check(second.is_waiting(),
			"streamed back in mid-chase it reverts to waiting — `_noticed_at` is not carried over")
	second.free()

## A day planned at full heat places more patrols than the same day cold — measured, since the
## population multiplier changing the cap does not by itself guarantee more of them actually get
## rolled and placed against everything else competing for the same budget.
func _test_a_hot_day_places_more_patrols(t) -> void:
	var day := 9
	var cold := _count_patrols(EventScheduler.build_day(day, _rng(day), _map, [], [], [], null, 0))
	var hot := _count_patrols(EventScheduler.build_day(day, _rng(day), _map, [], [], [], null,
			Tuning.RESISTANCE_GOAL))
	t.check(hot > cold, "a fully heated day places more patrols than a cold one (%d vs %d)"
			% [hot, cold])

func _count_patrols(planned: Array[EventScheduler.Planned]) -> int:
	var count := 0
	for plan in planned:
		if plan.def.id == "police_patrol":
			count += 1
	return count
