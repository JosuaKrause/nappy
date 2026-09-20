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
	_test_the_raid_hunts_past_its_own_threshold(t)
	_test_the_roadblock_hunts_past_its_own_threshold(t)
	_test_a_day_is_a_function_of_its_heat(t)
	_test_the_patrol_presses_more_and_louder(t)
	_test_the_patrol_investigates_past_the_threshold(t)
	_test_it_patrols_while_it_waits(t)
	_test_a_patrol_that_never_notices_drives_off_its_route(t)
	_test_the_patrol_chases_once_it_notices(t)
	_test_the_guard_leaves_the_barrier_standing_and_catches_at_a_mans_reach(t)
	_test_a_streamed_patrol_resumes_where_it_left_off(t)
	_test_a_streamed_patrol_mid_chase(t)
	_test_a_hot_day_places_more_patrols(t)
	_test_every_pursues_within_row_resumes_the_notice(t)

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

func _cold_raid() -> EventDef:
	return EventCatalogue.by_id("night_raid")

## The raid's own hot shape, named rather than left to the generic `HUNTS` loop above: untouched
## below `Tuning.HEAT_HUNTS_LEVEL`, then pursuing and lethal past it — and still `SCRIPTED` for
## day 10 whatever the heat, since heat moves what a row does and never when it is allowed to
## appear.
##
## The pursuit numbers `EventCatalogue.heated()` writes in are not restated here: a check that
## read `HEAT_HUNTS_SPEED` back off the row it was just assigned to could only ever say somebody
## changed that constant. What the hot row has to *satisfy* is checked instead — `validate()`
## here, and the stand-off/trigger/field ordering in the generic `HUNTS` loop above.
func _test_the_raid_hunts_past_its_own_threshold(t) -> void:
	var cold := _cold_raid()
	t.check(cold.heat_response == EventDef.HeatResponse.HUNTS,
			"the raid answers to the resistance, the lethal way")
	t.check(cold.kind == GameEnums.EventKind.SCRIPTED and cold.available_on(10),
			"the raid is scripted for day 10")
	for level in EventCatalogue.heat_levels():
		var hot := EventCatalogue.heated(cold, level)
		t.check(hot.validate(), "the raid is fair at heat %d" % level)
		t.check(hot.kind == GameEnums.EventKind.SCRIPTED and hot.available_on(10),
				"heat %d: the raid still only ever appears on day 10" % level)
		t.check(hot.max_per_day == cold.max_per_day and hot.intensity == cold.intensity,
				"heat %d: hunting moves neither population nor intensity" % level)
		if level < Tuning.HEAT_HUNTS_LEVEL:
			t.check(not hot.pursues and not hot.hard_fail and hot.duration == cold.duration,
					"heat %d: below its own threshold the raid is untouched" % level)
			continue
		t.check(hot.pursues and hot.hard_fail,
				"heat %d: at or past its threshold the raid hunts and kills" % level)

func _cold_roadblock() -> EventDef:
	return EventCatalogue.by_id("roadblock")

## The roadblock's own hot shape, named rather than left to the generic `HUNTS` loop above: below
## `Tuning.HEAT_HUNTS_LEVEL` it is the band it always was — untouched, still merely `costly` — and
## at or above it its guards leave the post: `pursues` and `hard_fail` turn on for the same body,
## and neither when it may appear nor its population nor its intensity moves, since heat sets what
## a row does and never when it is allowed to. The pursuit numbers themselves are left to
## `validate()` and to the generic loop's ordering check, for the reason given on the raid above.
func _test_the_roadblock_hunts_past_its_own_threshold(t) -> void:
	var cold := _cold_roadblock()
	t.check(cold.heat_response == EventDef.HeatResponse.HUNTS,
			"the roadblock answers to the resistance, the lethal way")
	t.check(not cold.hard_fail, "cold, it is still only a closed street")
	for level in EventCatalogue.heat_levels():
		var hot := EventCatalogue.heated(cold, level)
		t.check(hot.validate(), "the roadblock is fair at heat %d" % level)
		t.check(hot.first_day == cold.first_day,
				"heat %d: hunting moves what it does, never when it may appear" % level)
		t.check(hot.max_per_day == cold.max_per_day and hot.intensity == cold.intensity,
				"heat %d: hunting moves neither its population nor its intensity" % level)
		if level < Tuning.HEAT_HUNTS_LEVEL:
			t.check(not hot.pursues and not hot.hard_fail,
					"heat %d: below its own threshold the roadblock is still just a band" % level)
			continue
		t.check(hot.pursues and hot.hard_fail,
				"heat %d: at or past its threshold its guards leave the post and it kills" % level)
		# **What kills is a man, at a man's reach**, and the band it stands at no longer has
		# anything to do with it. Asked as the two facts that make that true rather than as the
		# number: the catch is the same one the escape's masked man uses, and it is well inside
		# the reach the band's own body would have forced if the barrier were the killer — which
		# is exactly the arrangement this row used to be in.
		t.check(hot.lethal_reach() == EventCatalogue.by_id("masked_pursuer").inner_radius,
				"heat %d: it catches at a masked man's own reach (%.0fpx)"
				% [level, hot.lethal_reach()])
		t.check(hot.lethal_reach() < hot.obstructs_radius + Tuning.PLAYER_BODY_RADIUS,
				("heat %d: and well inside the %.0fpx the band's own body would have forced, "
						+ "which is only possible because the man leaves it behind")
				% [level, hot.obstructs_radius + Tuning.PLAYER_BODY_RADIUS])
		t.check(hot.body_stays_behind,
				"heat %d: and the barrier he leaves stays where it was built" % level)
		t.check(hot.lethal_reach() <= hot.inner_radius,
				"heat %d: the catch is inside the field's own core, so it is never silent" % level)

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

## *"I just saw a barrier turn into a mask men (the barrier disappeared and the masked man
## appeared) and the pursuit ended way too early (I got caught when I was still very visibly away
## from him)."* — and, on how it should work: *"the guard needs to be at the barrier from the
## beginning, standing. only then does it make sense for it to start pursuing. 86px is huge why is
## that the fix for the problem that the radius is too big?"*
##
## Four things, and each is one half of what the player reported.
##
## - **A cold roadblock is a barrier and nothing else**: solid, never lethal, catching nobody at
##   any distance. The guard standing at it is a drawing, which is why he costs nothing here.
## - **Nothing disappears when he sets off.** The body is still there and it is still at the place
##   the barrier was built, not wherever the man has walked to.
## - **The catch is measured from the man**, at `masked_pursuer`'s own reach — so she is taken
##   when he is on her, not when he is two and a half tiles away.
## - **The barrier catches nobody.** Standing right against it, at the distance the old lethal
##   radius would have fired from, ends nothing while the man is elsewhere.
func _test_the_guard_leaves_the_barrier_standing_and_catches_at_a_mans_reach(t) -> void:
	var reach: float = EventCatalogue.by_id("masked_pursuer").inner_radius
	var cold := _cold_roadblock()
	var post := Vector2(400.0, 0.0)

	var band := EventInstance.new()
	band.setup(cold, post)
	t.add_child(band)
	band.set_process(false)
	band.player_at = post + Vector2(cold.obstructs_radius + Tuning.PLAYER_BODY_RADIUS, 0.0)
	band._process(STEP)
	t.check(band.is_solid(), "a cold roadblock is a solid band")
	t.check(not band.is_lethal_at(band.player_at) and not band.is_lethal_at(post),
			"and it takes nobody, at its own edge or standing in it")
	band.free()

	var hot := EventCatalogue.heated(cold, Tuning.RESISTANCE_GOAL)
	var guard := EventInstance.new()
	guard.setup(hot, post)
	t.add_child(guard)
	guard.set_process(false)
	t.check(guard.is_solid(), "a hunting one is the same band until it notices her")
	t.check(not guard.has_left_its_body_behind(), "with its body still under its own feet")

	var her := post + Vector2(hot.pursues_within - 10.0, 0.0)
	guard.player_at = her
	guard._process(STEP)
	t.check(not guard.is_waiting(), "she comes inside the trigger and the guard notices her")
	t.check(guard.is_solid() and guard.has_left_its_body_behind(),
			"he sets off and the barrier stays solid behind him")
	t.check(guard.body_position().is_equal_approx(post),
			"exactly where it was built (%s against %s)" % [guard.body_position(), post])

	# His whole notice runs while he is standing where she can see him, and nothing is lethal
	# during it — that is the contract every pursuer keeps and the reason he is worth seeing.
	var frames := 0
	while guard.is_telegraphing() and frames < int(10.0 / STEP):
		t.check(not guard.is_lethal_at(guard.global_position),
				"nothing is lethal while his notice runs")
		guard.player_at = her
		guard._process(STEP)
		frames += 1
	t.check(not guard.is_telegraphing() and frames > 0,
			"his %.1fs notice runs in full and ends (%d frames)" % [hot.telegraph_time, frames])

	# The reach is a man's, measured from him.
	var on_him := guard.global_position + Vector2(reach - 1.0, 0.0)
	var just_clear := guard.global_position + Vector2(reach + 2.0, 0.0)
	t.check(guard.is_lethal_at(on_him), "he takes her at %.0fpx, a man's own reach" % reach)
	t.check(not guard.is_lethal_at(just_clear),
			"and not a pixel past it (%.0fpx is clear)" % (reach + 2.0))
	t.check(not guard.is_lethal_at(guard.global_position
			+ Vector2(hot.obstructs_radius + Tuning.PLAYER_BODY_RADIUS, 0.0)),
			"never at the %.0fpx the band's own body would have forced"
			% (hot.obstructs_radius + Tuning.PLAYER_BODY_RADIUS))

	# And the barrier he left behind is not a second killer: she can stand against it. She holds
	# still while he closes, so what this measures is him leaving rather than her drawing him off.
	var chased := 0.0
	while chased < 2.0:
		guard.player_at = her
		guard._process(STEP)
		chased += STEP
	t.check(guard.body_position().is_equal_approx(post),
			"the barrier has not followed him (%s)" % guard.body_position())
	t.check(guard.global_position.distance_to(post) > reach,
			"he has actually walked away from the post (%.0fpx)"
			% guard.global_position.distance_to(post))
	t.check(not guard.is_lethal_at(post)
			and not guard.is_lethal_at(post + Vector2(0.0, hot.obstructs_radius)),
			"and the barrier standing there takes nobody")
	guard.free()

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

## The other half of the same question, mid-chase rather than mid-patrol. `resume()` restores
## `age`, the travelled distance and `_noticed_at`, so a patrol streamed out after it has noticed
## her comes back still chasing rather than `is_waiting()` again, having forgotten why it was
## coming. Checked against `chase_age()` as well as `is_waiting()`, so the fix is that the chase's
## own clock picks up where it left off, not only that the flag agrees — a restored `_noticed_at`
## that disagreed with the restored `age` would still read `not is_waiting()` while timing the
## telegraph and the duration from the wrong moment. `alley_robbery` has had the same
## `pursues_within` shape since the mechanic was built, just never in a position to be streamed out
## mid-chase, since a stationary pursuer's field never moves far enough from where the day planted
## it — see `_test_every_pursues_within_row_resumes_the_notice` for the same restore checked
## against that row rather than only the patrol that surfaced the gap.
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
	var noticed_at := first._noticed_at
	first.free()

	var second := EventInstance.new()
	second.setup(hot, path[0], path)
	t.add_child(second)
	second.resume(age, travelled, noticed_at)
	t.check(not second.is_waiting(),
			"streamed back in mid-chase it is still chasing — `_noticed_at` is carried over")
	t.close_to(second.chase_age(), age - noticed_at,
			"and the chase clock resumes from the notice rather than restarting at it", 0.001)
	second.free()

## A day planned at full heat places at least as many patrols as the same day cold, and strictly
## more on at least one of several seeds — measured, since the population multiplier changing the
## cap does not by itself guarantee more of them actually get rolled and placed against everything
## else competing for the same budget.
##
## **One seed is not enough to assert `>` by itself.** The cold and hot plans roll from the same RNG
## stream up to the point their budgets actually diverge, so on a city and a day where something
## else competing for act I's tiles happens to win a few more of the shared rolls, the two plans can
## tie — this test read 7 vs 7 on `SEED` once `alley_mouse` joined that competition, which is a
## seed-specific coincidence about the roll rather than a broken relationship. `>=` on every sampled
## seed is the contract the population multiplier actually promises; `>` on at least one is what
## shows the multiplier does something rather than nothing.
func _test_a_hot_day_places_more_patrols(t) -> void:
	var day := 9
	var seeds := [8817, 4242, 2102613802, 90210, 37, 38, 39, 12345]
	var any_strictly_more := false
	for run_seed in seeds:
		var map := CityGenerator.generate(run_seed)
		var rng_seed := hash("%d:%d" % [run_seed, day])
		var cold_rng := RandomNumberGenerator.new()
		cold_rng.seed = rng_seed
		var hot_rng := RandomNumberGenerator.new()
		hot_rng.seed = rng_seed
		var cold := _count_patrols(EventScheduler.build_day(day, cold_rng, map, [], [], [], null, 0))
		var hot := _count_patrols(EventScheduler.build_day(day, hot_rng, map, [], [], [], null,
				Tuning.RESISTANCE_GOAL))
		t.check(hot >= cold,
				"seed %d: a fully heated day places at least as many patrols as a cold one (%d vs %d)"
				% [run_seed, hot, cold])
		any_strictly_more = any_strictly_more or hot > cold
	t.check(any_strictly_more,
			"and strictly more on at least one of the %d seeds sampled" % seeds.size())

func _count_patrols(planned: Array[EventScheduler.Planned]) -> int:
	var count := 0
	for plan in planned:
		if plan.def.id == "police_patrol":
			count += 1
	return count

## `resume()`'s restored notice is not particular to the heated patrol that surfaced the gap —
## `alley_robbery` carries the identical `pursues_within` shape cold, with no heat level needed to
## reach it, and this is the same restore checked against that row instead.
func _test_every_pursues_within_row_resumes_the_notice(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	t.check(def.pursues_within > 0.0, "'alley_robbery' is a waiting pursuer, cold")

	var first := EventInstance.new()
	first.setup(def, Vector2.ZERO)
	t.add_child(first)
	first.set_process(false)
	var her := Vector2(def.pursues_within - 10.0, 0.0)
	first.player_at = her
	first._process(STEP)
	t.check(not first.is_waiting(), "she is inside the trigger, so he notices her")
	var age := first.age
	var travelled := first.path_travelled()
	var noticed_at := first._noticed_at
	first.free()

	var second := EventInstance.new()
	second.setup(def, Vector2.ZERO)
	t.add_child(second)
	second.resume(age, travelled, noticed_at)
	t.check(not second.is_waiting(),
			"'alley_robbery' streamed back in mid-chase is still chasing, not waiting in the hood")
	second.free()
