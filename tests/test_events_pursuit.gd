extends "res://tests/events_shared_city.gd"
## The chase lesson, in the three answers a player can give: into it, away at a walk, away at a
## run -- plus the mechanics a pursuer has to keep regardless of which she picks: it leaves no
## field clear to stand in, it can be kept waiting, it stops at a wall, and a hard-fail row is
## lethal by the time it actually reaches her. `_test_a_retried_day_is_the_same_day` and
## `_test_the_run_is_always_taught` sit here because both are asked against the same rig this file
## already builds for the pursuit tests.
##
## *(M35, playtest 08 finding 4: "I like the running tutorial on day 3 but I don't know how to
## solve it yet -- I died every time.")* `validate_pursuit` passed every line of itself while the
## dog was killing people, because every line of it was about **speeds and durations** and a
## pursuit is played out in **distances**. The rig below is the contract walked rather than
## asserted.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again". Extends
## `events_shared_city.gd` for `_test_a_pursuer_stops_at_walls`'s `_map()`, the one test here that
## needs a real generated city rather than a hand-built rig.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_pursuer_leaves_room_to_answer(t)
	_test_the_answer_is_priced_by_how_soon_it_is_given(t)
	_test_a_pursuer_is_sited_where_it_can_be_seen(t)
	_test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t)
	_test_the_cyclist_is_warned_shortly_before_he_arrives(t)
	_test_the_day_3_dog_keeps_its_gold_timing(t)
	_test_the_resistances_pursuers_are_fitted_to_the_dog(t)
	_test_every_pursuer_sent_from_off_screen_is_warned_first(t)
	_test_a_sent_pursuer_counts_running_before_he_is_visible(t)
	_test_a_failed_lesson_retry_leaves_the_director_running(t)
	_test_a_retried_day_is_the_same_day(t)
	_test_the_run_is_always_taught(t)
	_test_a_paced_event_walks_a_beat(t)
	_test_a_pursuer_can_wait(t)
	_test_a_pursuer_stops_at_walls(t)
	_test_the_robbers_lunge_is_further_out_than_his_catch(t)
	_test_the_robber_does_not_catch_her_through_a_wall(t)
	_test_the_robber_does_not_notice_her_through_a_wall(t)
	_test_the_robber_does_not_lunge_through_a_wall(t)
	_test_the_robber_keeps_his_stand_off_at_an_alley_mouth(t)
	_test_the_red_caret_is_measured_from_the_catch(t)
	_test_the_robber_catches_her_by_coming_round_the_corner(t)
	_test_a_clear_line_is_every_tile_the_line_crosses(t)
	_test_a_clear_line_at_a_corner_an_edge_and_its_own_start(t)


func _instance(t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

## A failed placement is retried without starving the director's independent clock.
class _RetryDirector extends EventDirector:
	var elapsed := 0.0
	func due(delta: float, _at: Vector2, _velocity: Vector2,
			_plans: Array[EventScheduler.Planned] = []) -> Array:
		elapsed += delta
		return []

class _BlockedLesson extends EventManager:
	var attempts := 0
	func _warn_down_her_heading(def: EventDef, _her: Vector2, _sited: Vector2) -> void:
		attempts += 1
		_owe_pursuer_again(def)

func _test_a_failed_lesson_retry_leaves_the_director_running(t) -> void:
	var manager := _BlockedLesson.new()
	var director := _RetryDirector.new(null)
	var body := CharacterBody2D.new()
	body.velocity = Vector2.RIGHT * Tuning.WALK_SPEED
	manager._player = body
	manager._director = director
	manager._owe_pursuer_again(EventCatalogue.by_id("charging_dog"))
	for frame in 150:
		manager._place_what_is_owed_ahead(STEP)
	t.check(manager.attempts == 2 and manager._pursuer_owed != null,
			"a blocked lesson remains owed and retries twice in 2.5s, rather than every frame")
	t.close_to(director.elapsed, 2.5, "other director events receive every elapsed frame", 0.001)
	manager.free()
	body.free()

## A sent pursuer's badge is enough notice: a sustained run can end the chase before he is seen.
## Brief runs separated by walking do not accumulate into one escape.
func _test_a_sent_pursuer_counts_running_before_he_is_visible(t) -> void:
	for id: String in ["robber_giving_chase", "van_guard_giving_chase"]:
		var pursuer := EventInstance.new()
		pursuer.setup(EventCatalogue.by_id(id), Vector2.ZERO)
		pursuer.player_running = true
		for frame in int(Tuning.PURSUIT_SHAKEN_OFF / STEP) - 1:
			pursuer.player_at = Vector2(500.0 + frame * Tuning.RUN_SPEED * STEP, 0.0)
			pursuer._process(STEP)
		t.check(not pursuer.gave_up, "%s needs the full sustained run" % id)
		pursuer.player_running = false
		pursuer._process(STEP)
		pursuer.player_running = true
		for frame in int(Tuning.PURSUIT_SHAKEN_OFF / STEP) - 1:
			pursuer.player_at += Vector2.RIGHT * Tuning.RUN_SPEED * STEP
			pursuer._process(STEP)
		t.check(not pursuer.gave_up, "%s restarts the shake-off timer after a walk" % id)
		for frame in 3:
			pursuer.player_at += Vector2.RIGHT * Tuning.RUN_SPEED * STEP
			pursuer._process(STEP)
		t.check(pursuer.gave_up, "%s is shaken off by sustained running while offscreen" % id)
		pursuer.free()

## The multiset of event ids in a plan: what the day is *made of*, with the geometry thrown away.
func _kinds_in(plans: Array[EventScheduler.Planned]) -> Dictionary:
	var counts := {}
	for plan in plans:
		counts[plan.def.id] = int(counts.get(plan.def.id, 0)) + 1
	return counts

## Walks the encounter the way it is actually played: she is walking into it when it lunges, dithers
## for `reaction` seconds, then turns and runs — accelerating, rather than changing speed instantly.
##
## Reports how close it got and how long she spent running, because those are the two numbers the
## contract is about: one is whether the answer works and the other is what it costs.
##
## The running stops being counted the moment the thing gives up, which is not fussiness: an event
## that is over still exists for several seconds while it leaves, and a rig that kept holding the
## key down through that would price the answer at whatever `departs_at` happens to be.
func _answer_rig(def: EventDef, reaction: float) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var her := Vector2(_sited_at(def), 0.0)
	# Positive is away from it, matching `_chase_rig`. She starts walking in.
	var speed := -Tuning.WALK_SPEED
	var elapsed := 0.0
	var since_the_lunge := INF
	var result := {"caught": false, "closest": INF, "running": 0.0}
	while elapsed < 14.0 and not instance.is_leaving and not result["caught"]:
		if not instance.is_telegraphing() and not instance.is_waiting() and since_the_lunge == INF:
			since_the_lunge = 0.0
		var wanted := -Tuning.WALK_SPEED
		if since_the_lunge != INF and since_the_lunge >= reaction:
			wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		if speed > Tuning.WALK_SPEED:
			result["running"] = float(result["running"]) + STEP
		her.x += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if since_the_lunge != INF:
			since_the_lunge += STEP
		result["closest"] = minf(float(result["closest"]),
				instance.global_position.distance_to(her))
		if instance.is_lethal_at(her):
			result["caught"] = true
	instance.free()
	return result

## Where the encounter actually starts, in px: where something sent at her from off screen is
## created, or just inside the trigger for something that has been standing there.
##
## A pursuer sent at her — the day-3 dog, the resistance's own two — is warned of first and created
## just out of sight (`PendingWarning`), which depends on the way it comes and on what she can see,
## so this asks for the worst case over every heading and either control scheme rather than one of
## them — `PendingWarning.least_distance()`, the view's half height, which is the least ground the
## contract can ever rely on. A rig checked against a more generous heading would pass on an
## encounter the game can still produce on a worse one.
func _sited_at(def: EventDef) -> float:
	if def.pursues_within > 0.0:
		return def.pursues_within - 10.0
	return PendingWarning.least_distance()

## Walks one answer to a pursuit and reports what happened. `player_speed` is along the line between
## them: positive is away from it, negative is into it.
func _chase_rig(def: EventDef, player_speed: float) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var from := _sited_at(def)
	var her := Vector2(from, 0.0)
	var elapsed := 0.0
	var result := {"caught": false, "gave_up": false, "lethal_while_telegraphing": false,
			"at_the_lunge": INF, "ended_at": INF}
	var was_telegraphing := true
	while elapsed < 12.0 and not instance.is_finished and not result["caught"]:
		her.x += player_speed * STEP
		instance.player_at = her
		# The break-off is a fact about *her* since playtest 14, so a rig that only moves her is
		# not running the rule. See `Tuning.PURSUIT_SHAKEN_OFF`.
		instance.player_running = player_speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if was_telegraphing and not instance.is_telegraphing():
			result["at_the_lunge"] = instance.global_position.distance_to(her)
			was_telegraphing = false
		if instance.is_lethal_at(her):
			result["caught"] = true
			result["lethal_while_telegraphing"] = was_telegraphing
		if instance.gave_up and result["ended_at"] == INF:
			result["gave_up"] = true
			result["ended_at"] = elapsed
	if result["ended_at"] == INF:
		result["ended_at"] = elapsed
	instance.free()
	return result

## A real building tile with open pavement on two adjacent sides — the outward corner every
## rectangular building has at least one of. `{}` would mean the generator changed shape rather
## than that the test picked badly.
func _a_building_corner(map: CityMap) -> Dictionary:
	for tile in map.tiles_of_type(GameEnums.TileType.BUILDING):
		var north := tile + Vector2i(0, -1)
		var east := tile + Vector2i(1, 0)
		if map.in_bounds(north) and map.in_bounds(east) \
				and map.is_walkable(north) and map.is_walkable(east):
			return {"building": tile, "north": north, "east": east}
	return {}

## The alley robber's catch is smaller than his lunge's reach (tall-osprey, 2026-10-04): he catches
## at 26px and lunges from 116px (`lunge_reach` 38), so the room between lunge and catch is 90px, and
## no other pursuer's lunge moves off its own catch.
func _test_the_robbers_lunge_is_further_out_than_his_catch(t) -> void:
	for id in ["alley_robbery", "robber_giving_chase"]:
		var def := EventCatalogue.by_id(id)
		t.close_to(def.lethal_reach(), 26.0, "'%s' catches at 26px" % id, 0.01)
		t.close_to(Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach()), 116.0,
				"'%s' lunges from 116px" % id, 0.01)
	for def in EventCatalogue.all():
		t.check(not def.lunge_is_inside_the_catch(), "'%s' does not lunge from inside its catch" % def.id)
		if def.pursues and def.id != "alley_robbery" and def.id != "robber_giving_chase":
			t.check(is_equal_approx(def.standoff_reach(), def.lethal_reach()),
					"'%s' lunges from its own catch" % def.id)
	# A `lunge_reach` inside the catch would stand the pursuer off closer than `PURSUIT_REACTION` of
	# its own approach from taking her: 10px on a 26px catch is an 88px stand-off, 62px of room, 0.48s
	# at 130px/s. `validate()` refuses it on load (asked here through the predicate, since the refusal
	# is a `push_error`, which fails the whole run); a lunge exactly at the catch is allowed.
	var too_short := EventCatalogue.by_id("alley_robbery").duplicate() as EventDef
	too_short.lunge_reach = 10.0
	t.check(too_short.lunge_is_inside_the_catch(), "a 10px lunge on a 26px catch is inside it")
	too_short.lunge_reach = too_short.lethal_reach()
	t.check(not too_short.lunge_is_inside_the_catch(), "a lunge exactly at the catch is not")
	too_short.lunge_reach = 0.0
	t.check(not too_short.lunge_is_inside_the_catch(), "and 0 means the catch")

## **The one encounter in the game with a right answer, walked three ways.** *(M35, playtest 08
## finding 4: "I like the running tutorial on day 3 but I don't know how to solve it yet — I died
## every time.")*
##
## `validate_pursuit` passed every line of itself while the dog was killing people, because every
## line of it was about **speeds and durations** and a pursuit is played out in **distances**. This
## is the same contract walked rather than asserted, and the three walks are the three answers a
## player can give: into it, away from it at a walk, and away from it at a run. What each one has to
## produce is different, and the first one is the one that was broken — she is *sited walking into
## it*, because the director puts it where she was already going.
##
## *(M36 turned it from a test about the dog into a test about the **catalogue**, because there are
## two pursuers now and the second one arrives as a place rather than a moment. Everything below is
## true of both; what differs is only where she is standing when it starts.)*
func _test_a_pursuer_leaves_room_to_answer(t) -> void:
	var pursuers := 0
	for def in EventCatalogue.all():
		# A pursuer that sets off beside her is never sited by the director, so this rig's geometry
		# is not its own; `tests/test_checkpoints.gd` walks `door_guard` at a door instead.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance.gd`.
		if not def.pursues or def.sets_off_beside_her or def.arrives_chasing:
			continue
		pursuers += 1
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
		t.check(standoff > def.inner_radius,
				"'%s' holds off outside the radius that ends the day" % def.id)

		# Into it. The geometry the day-3 lesson actually produces, and the one that killed a run
		# three times: it keeps its distance while it is only telegraphing, however far she walks in.
		var walked_in := _chase_rig(def, -Tuning.WALK_SPEED)
		t.close_to(walked_in["at_the_lunge"], standoff,
				"walking into '%s' still leaves the whole stand-off when it goes lethal" % def.id,
				8.0)
		t.check(not walked_in["lethal_while_telegraphing"],
				"and nothing '%s' does during its own telegraph can end the day" % def.id)

		# Away from it at a walk. Walking has to lose, or the mechanic teaches nothing.
		var walked_off := _chase_rig(def, Tuning.WALK_SPEED)
		t.check(walked_off["caught"], "walking away from '%s' is not enough" % def.id)
		t.check(not walked_off["gave_up"],
				"so '%s' never has to give up on somebody walking" % def.id)

		# Away from it at a run. Running has to win, and it has to *end* it: the price of the right
		# answer is fourteen points a second, so a chase that runs its full clock however well it is
		# played is a toll rather than a lesson. Both facts follow from the speed clauses alone —
		# nothing slower than the pursuer can open the gap and nothing faster can fail to — which is
		# why `PURSUIT_SHAKEN_OFF` is stated as a rate and there is no distance to get wrong.
		var ran := _chase_rig(def, Tuning.RUN_SPEED)
		t.check(not ran["caught"], "running away from '%s' works" % def.id)
		t.check(ran["gave_up"],
				"and '%s' breaks off rather than tailing her for the whole chase" % def.id)
		t.check(ran["ended_at"] < def.telegraph_time + def.duration,
				"which ends '%s' early: %.1fs against a %.1fs chase"
				% [def.id, ran["ended_at"], def.telegraph_time + def.duration])
		var cost: float = ran["ended_at"] * Tuning.EXCITEMENT_FROM_RUNNING
		t.check(cost < Tuning.METER_MAX * 0.6,
				"and running from '%s' costs %.0f of a %.0f meter rather than the day"
				% [def.id, cost, Tuning.METER_MAX])
	t.check(pursuers >= 2, "there is more than one kind of thing that comes after her")

## **The answer is priced by how soon it is given, and the rig has to turn round to find out.**
## *(Playtest 10, finding 13: "the running tutorial dog is impossible to escape at the moment",
## clarified as "the issue was that the dog kept following for too long".)*
##
## The three walks above hold a constant speed from the first frame, and all three passed while a
## player was reporting the encounter as unplayable — because nobody can turn round in nought
## seconds and nothing said she had to. Reversing a walk into a run takes
## `(WALK_SPEED + RUN_SPEED) / ACCELERATION` = 0.37s, and the thing keeps coming through all of it.
##
## What is asserted is the shape rather than any one number: **it can be answered, answering sooner
## costs strictly less, and doing nothing still loses.** The cost is bounded by
## `PURSUIT_SHAKEN_OFF` plus the about-turn rather than by the chase clock, which is the whole
## difference between a lesson and a toll.
##
## **The measured number this reports rather than asserts is the window at the lunge**, and it is
## the open half of finding 13. She is walking *into* the thing at that instant — it is sited in
## front of her and holds its distance by backing off — so the gap closes at `pursue_speed +
## WALK_SPEED` and the stand-off is worth about a third of the `PURSUIT_REACTION` it was bought
## with. A player answers during the **telegraph**, where the dog is visible and closing for two and
## a half seconds, and that answer is cheap; the lunge is the worst case rather than the expected
## one. Widening it means a wider stand-off, and a wider stand-off is a dog that visibly reverses.
func _test_the_answer_is_priced_by_how_soon_it_is_given(t) -> void:
	for def in EventCatalogue.all():
		# Sited beside her rather than by the director — see `_test_a_pursuer_leaves_room_to_answer`.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance.gd`.
		if not def.pursues or def.sets_off_beside_her or def.arrives_chasing:
			continue
		var at_once := _answer_rig(def, 0.0)
		t.check(not at_once["caught"],
				"'%s' can be answered at the lunge (closest %.0fpx)" % [def.id, at_once["closest"]])
		t.check(at_once["closest"] > def.inner_radius,
				"and answering it clears the %.0fpx that ends the day by %.0fpx"
				% [def.inner_radius, at_once["closest"] - def.inner_radius])

		# The price is the about-turn plus being visibly outrun, and nothing else. A chase that ran
		# its clock however well it was played would cost `PURSUIT_TIME` here instead.
		var turn := (Tuning.WALK_SPEED + Tuning.RUN_SPEED) / Tuning.ACCELERATION
		t.check(at_once["running"] < Tuning.PURSUIT_SHAKEN_OFF + turn + 0.5,
				"and it costs %.1fs of running rather than the %.1fs chase"
				% [at_once["running"], def.duration])
		t.check(at_once["running"] * Tuning.EXCITEMENT_FROM_RUNNING < Tuning.METER_MAX * 0.3,
				"which is %.0f of a %.0f meter"
				% [at_once["running"] * Tuning.EXCITEMENT_FROM_RUNNING, Tuning.METER_MAX])

		# Answering during the telegraph — what a player who reads the cue actually does — is cheaper
		# still, and that gradient is the reason the break-off is a rate rather than a clock.
		var early := _chase_rig(def, Tuning.RUN_SPEED)
		t.check(early["gave_up"] and not early["caught"],
				"running from '%s' the moment it appears shakes it off" % def.id)

		# And doing nothing still loses, which is the whole reason any of this is a mechanic.
		t.check(_answer_rig(def, 1.0)["caught"],
				"'%s' still catches somebody who leaves it far too long" % def.id)

		# Reported, not asserted: the widest reaction at the lunge that still survives. See above.
		var window := 0.0
		for i in 12:
			var reaction := i * 0.05
			if _answer_rig(def, reaction)["caught"]:
				break
			window = reaction
		t.check(window > 0.0,
				"the window to answer '%s' at the lunge itself is %.2fs" % [def.id, window])

## **A pursuer has to be sited where it actually closes on her rather than backing away.**
##
## Two things have to agree and neither knows about the other: the stand-off is where it stops, and
## the warning decides where it starts. If the stand-off ever grows past the least it could ever be
## created at — `PendingWarning.least_distance()`, the worst case over every heading she might be
## walking and either control scheme — a pursuer *backs away* through its own telegraph instead of
## closing, which is a dog that visibly reverses down the street in front of her.
##
## The relationship is asserted rather than left as a coincidence: a change to the stand-off or to
## `VIEW_HALF_EXTENT` has moved these numbers before without anybody checking they still agree.
func _test_a_pursuer_is_sited_where_it_can_be_seen(t) -> void:
	for def in EventCatalogue.all():
		# Sited beside her by construction, which is what its own stand-off rule answers.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance.gd`.
		if not def.pursues or def.sets_off_beside_her or def.arrives_chasing:
			continue
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
		var floor_lead := PendingWarning.least_distance()
		t.check(standoff < floor_lead,
				"'%s' stands off at %.0fpx, inside the %.0fpx it is sited at even on the worst axis"
				% [def.id, standoff, floor_lead])
		if def.pursues_within > 0.0:
			# A place, not a moment: the director never sites it, so what has to hold is that its
			# trigger is outside its stand-off — which `validate_pursuit` also checks, from the
			# other side and for a different reason.
			t.check(def.pursues_within > standoff,
					"'%s' notices her before it has stopped coming" % def.id)
			continue
		t.check(_sited_at(def) >= standoff,
				"'%s' is sited at %.0fpx, at or beyond the %.0fpx it stops at, so it closes rather "
				% [def.id, _sited_at(def), standoff] + "than backing away through its own telegraph")

## **A row declared lethal has to actually get the chance to be lethal.** *(2026-09-07: "also a
## biker hit should be lethal.")* `cyclist` carries `hard_fail = true`, but
## `EventInstance.is_lethal_at()` returns false for the whole of `is_telegraphing()` — so a
## `TOWARD_PLAYER` row that reached her before its own telegraph ended would ride straight through,
## declared lethal and never once able to fire. Such a row's telegraph is its warning, run before it
## exists (`PendingWarning`, at most `Tuning.WARNING_ALONE_MAX`), and it is created with that
## telegraph spent; this walks the warning and
## the arrival together, at the instance level, rather than trusting the construction.
##
## Walks every `hard_fail` `TOWARD_PLAYER` row in the catalogue rather than naming `cyclist`, so a
## second row of the same shape is covered by construction rather than by remembering to add it.
func _test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.spawn_mode != EventDef.SpawnMode.TOWARD_PLAYER or not def.hard_fail:
			continue
		checked += 1
		var arrived: Array[EventInstance] = []
		var warning := _warned_down_her_line(def, Vector2.ZERO, Vector2.RIGHT, arrived)
		var her := Vector2.ZERO
		var was_lethal := false
		var elapsed := 0.0
		while elapsed < def.warned_for() + 5.0:
			her.x += Tuning.WALK_SPEED * STEP
			elapsed += STEP
			if arrived.is_empty():
				warning.tick(STEP, her)
				continue
			arrived[0]._process(STEP)
			if arrived[0].is_lethal_at(her):
				was_lethal = true
				break
		t.check(was_lethal,
				"'%s' is declared hard_fail and its warning is over by the time it reaches her"
				% def.id)
		for instance in arrived:
			instance.free()
	t.check(checked > 0, "there is at least one hard_fail TOWARD_PLAYER row to check ('cyclist')")

## A warning for `def` coming down her line from `direction`, on open ground, put up with her at
## `her` — the construction `EventManager._warn_down_her_line()` makes, with creation done the way
## `EventManager.spawn_warned()` does it: its telegraph spent. What it creates is appended to
## `arrived`, for the caller to tick and free.
static func _warned_down_her_line(def: EventDef, her: Vector2, direction: Vector2,
		arrived: Array[EventInstance]) -> PendingWarning:
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.down_her_line(null, def, at, direction)
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var path := PendingWarning.route_down_her_line(null, place, at, direction)
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		instance.resume(EventManager.age_when_warned(def), 0.0)
		arrived.append(instance)
		return true
	var warning := PendingWarning.new(def, where, arrive)
	warning.put_up(her)
	return warning

## **The cyclist is warned by himself first, for at most a second, and then comes into view at once
## where the warning pointed.** *(2026-09-25: "I feel the same with the biker. it gets warned too
## early so most of the time you're already gone when anything happens." · PLAYTEST-145: "the
## warning appears by itself with a reasonable position and when the time is right the object is
## spawned in at that location just offscreen" · "the biker needs to stay on the sidewalk";
## calm-kestrel, inbox #559: "show the warning for x seconds (never longer than 2s) without placing
## anything then place the object immediately off screen so it will immediately start coming on the
## screen turning off the warning ... they jump around wildly"; busy-quail, inbox #569: "1s warning
## should be enough".)*
##
## On the real map, with the warning held the way `EventManager` holds one (`warn_first()`,
## `_run_the_warnings()`) and read by a real `DangerEdge`, while she walks up her sidewalk and steps
## out onto the carriageway and back:
##
## - **the badge is up with nothing in the world**, for no more than `Tuning.WARNING_ALONE_MAX`;
## - **the badge holds still**: its place keeps the same offset from her every frame, so it moves
##   only with her own walking and never jumps to another piece of ground;
## - **he is created once his second is up, on a sidewalk, wholly out of sight, with his telegraph
##   spent**, and he comes into sight as soon as he moves — or, where the ground just out of sight is
##   a cross street's carriageway and his sidewalk is beyond it, as soon as he has ridden that far —
##   which takes the badge down.
##
## Then, walked by `M207Lead.measure()` (`tests/probes/m207_warning_lead.gd`, the probe that prints
## every warned row's lead) on open ground on both axes: **from the badge to his reach, walking into
## him, is at least the contract's floor**, exactly his second and then his approach from just out of
## sight, and standing still he still reaches her no sooner than the floor.
func _test_the_cyclist_is_warned_shortly_before_he_arrives(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	t.check(def.warned_for() <= Tuning.WARNING_ALONE_MAX,
			"his badge is up alone for %.2fs, at most %.2fs" % [def.warned_for(), Tuning.WARNING_ALONE_MAX])
	var map := _map()
	# Her own kerb-side sidewalk beside the arterial, walking north from a point where the place just
	# out of sight ahead of her is on a sidewalk too rather than in the carriageway of a cross street.
	var her := CrowdLanes.arterial_pavement(map)
	for _tile in map.size.y / 2:
		if PendingWarning.down_her_line(map, def, her, Vector2.UP) != Vector2.INF:
			break
		her.y += Tuning.TILE_SIZE
	var manager := EventManager.new()
	var player := Node2D.new()
	t.add_child(player)
	player.global_position = her
	var edge := DangerEdge.new()
	t.add_child(edge)
	edge.setup(manager, player)
	manager.visible_view().look(VisibleView.around(her).view, false)
	var created: Array[EventInstance] = []
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.down_her_line(map, def, at, Vector2.UP, VisibleView.around(at))
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var path := PendingWarning.route_down_her_line(map, place, at, Vector2.UP)
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		instance.came_under_a_warning = true
		instance.resume(EventManager.age_when_warned(def), 0.0)
		created.append(instance)
		# In the manager's own list, so the edge measures him as the game's own badge does.
		manager._instances.append(instance)
		return true
	var warning := manager.warn_first(def, her, where, arrive)
	t.check(warning != null, "the cyclist's warning goes up on the sidewalk she is walking")
	if not warning:
		manager.free()
		return
	edge._measure(STEP)
	var badged := false
	for badge in edge.announcing():
		badged = badged or badge["id"] == "cyclist"
	t.check(badged and created.is_empty(), "its badge is up with nothing in the world yet")

	var ground := [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	var offset := warning.place - her
	var elapsed := 0.0
	var looked := 0
	var jumped := 0
	var came_at := INF
	while elapsed < Tuning.WARNING_ALONE_MAX + 1.0:
		# North up the sidewalk, then a stride out onto the carriageway and back.
		var step := Vector2.UP
		if elapsed > 0.3 and elapsed <= 0.6:
			step = Vector2.RIGHT
		elif elapsed > 0.6 and elapsed <= 0.9:
			step = Vector2.LEFT
		her += step * Tuning.WALK_SPEED * STEP
		manager.visible_view().look(VisibleView.around(her).view, false)
		manager._run_the_warnings(STEP, her)
		elapsed += STEP
		if not created.is_empty():
			came_at = elapsed
			break
		looked += 1
		if not (warning.place - her).is_equal_approx(offset):
			jumped += 1
	t.check(looked > 0 and jumped == 0,
			"it was watched (%d frames) and its place kept its offset from her every frame (%d not)"
			% [looked, jumped])
	t.check(created.size() == 1 and came_at <= Tuning.WARNING_ALONE_MAX + 2.0 * STEP,
			"he is created once his %.2fs badge is over (%.2fs)" % [def.warned_for(), came_at])
	if created.size() == 1:
		var bike := created[0]
		var view := VisibleView.around(her)
		t.check(ground.has(map.tile_at(map.world_to_tile(bike.global_position))),
				"on a sidewalk")
		t.check(PendingWarning.is_out_of_sight(view, def, her, bike.global_position),
				"wholly out of sight the frame he exists")
		t.check(not bike.is_telegraphing(), "with his telegraph already spent, so he can end the day")
		var into_sight := INF
		var gone := INF
		var since := 0.0
		player.global_position = her
		while since < 1.0 and (into_sight == INF or gone == INF):
			bike._process(STEP)
			since += STEP
			edge._measure(STEP)
			var box := EventInstance.footprint_of(def)
			if into_sight == INF and manager.visible_view().sees_any(
					Rect2(bike.global_position + box.position, box.size)):
				into_sight = since
			var still_badged := false
			for badge in edge.announcing():
				still_badged = still_badged or badge["id"] == "cyclist"
			if gone == INF and not still_badged:
				gone = since
		# At once from just out of sight; where its ground is further — the carriageway of a cross
		# street just out of sight, so the far sidewalk — as soon as he has ridden the difference.
		var just_out := PendingWarning.just_out_of_sight(view, def, her, Vector2.UP)
		var further := maxf(0.0, (bike.path[0] - just_out).dot(Vector2.UP))
		t.check(into_sight <= further / def.speed + 3.0 * STEP,
				"and he comes into sight as soon as he has ridden the %.0fpx his ground put him past "
				% further + "just out of sight (%.2fs after he exists)" % into_sight)
		t.check(gone <= into_sight + 0.2,
				"and the badge goes down as he comes into sight (%.2fs, in sight at %.2fs)" % [gone, into_sight])
	for instance in created:
		instance.free()
	edge.free()
	player.free()
	manager.free()

	var walked := 0
	for encounter in M207Lead.encounters():
		var row: EventDef = encounter["def"]
		if row.id != "cyclist":
			continue
		walked += 1
		var floor_s := row.minimum_telegraph()
		var probe_edge := DangerEdge.new()
		var toward := M207Lead.measure(encounter, M207Lead.Answer.TOWARD, probe_edge)
		t.check(toward["by"] == "badge" and toward["lead"] < INF,
				"cyclist (%s): the badge warns her before he can hit her (by %s, %.2fs)"
				% [encounter["how"], toward["by"], toward["lead"]])
		t.check(toward["lead"] >= floor_s,
				"cyclist (%s): walking into him she is warned %.2fs ahead, at least the %.2fs floor"
				% [encounter["how"], toward["lead"], floor_s])
		# What the walk measures is the contract's own figure on this axis: his second, then his
		# approach from just out of sight to his reach. The horizontal axis adds only the wider view.
		var heading: Vector2 = encounter["heading"]
		var closing := row.speed + Tuning.WALK_SPEED
		var created_at := PendingWarning.down_her_line(null, row, Vector2.ZERO, heading).length()
		var predicted := row.warned_for() + (created_at - row.lethal_reach()) / closing
		t.close_to(toward["lead"], predicted,
				"cyclist (%s): which is his second and then his approach from just out of sight"
				% encounter["how"], 3.0 * STEP)
		var stood := M207Lead.measure(encounter, M207Lead.Answer.STAND, probe_edge)
		t.check(stood["lead"] < INF and stood["lead"] >= floor_s,
				"cyclist (%s): standing on his line she is still reached, %.2fs after the warning"
				% [encounter["how"], stood["lead"]])
		probe_edge.free()
	t.check(walked >= 2, "the cyclist was walked on both axes (%d)" % walked)

## **The day-3 dog keeps its gold timing, in the player's terms.** *(PLAYTEST-145: "the pursuit dog
## timing from the day 3 lesson is the correct timing ... this is the gold timing with warning time
## and onscreen pursuing time seen as correct"; inbox #598: "the chase is what happens on screen" ·
## "off screen doesn't count toward the timing it only counts towards the warning timing" · "0.53 is
## a good warning time -- the chase on screen didn't change at all".)* Per answer, the **warning** is
## the time from the first warning she can see (the badge) to the dog first visible (anything it
## draws in view), and the **chase** is from its lunge to the catch. Its numbers stay as built — a
## half-second badge alone (`offscreen_notice`), a 4.5s approach (`telegraph_time`) and a chase at
## 130px/s that does not give up on a walker (`Tuning.PURSUIT_TIME`, a long cap; amendment 8: "pursuers
## should never (or a long time) stop pursuing if she walks") — and so does what she meets: walked as
## she meets it (`M207Lead.gold()`, the probe's own walk, straight down her line), the warning is the
## half-second badge in all three answers and the chase is the lesson's own, 0.35s walking into it,
## 0.60s standing and 2.05s walking away, which loses; running away the moment she is warned escapes
## it, which is the lesson. A later change to its placement, to the camera or to its numbers fails
## here.
func _test_the_day_3_dog_keeps_its_gold_timing(t) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	t.close_to(dog.offscreen_notice, 0.5, "the day-3 dog's badge alone is half a second", 0.001)
	t.close_to(dog.telegraph_time, 4.5, "its approach is 4.5s", 0.001)
	t.close_to(dog.duration, Tuning.PURSUIT_TIME, "its chase is the pursuit's own", 0.001)
	# Amendment 8 of M226: "pursuers should never (or a long time) stop pursuing if she walks".
	t.check(Tuning.PURSUIT_TIME >= 30.0, "which is a long cap, not an end a walk outlasts (%.0fs)"
			% Tuning.PURSUIT_TIME)
	t.close_to(dog.pursue_speed, 130.0, "at 130px/s", 0.001)
	var sent := EventManager.as_warned(dog)
	t.check(sent.warns_before_it_exists() and is_equal_approx(sent.warned_for(), dog.offscreen_notice)
			and sent.warned_for() <= Tuning.WARNING_ALONE_MAX,
			"sent at her, it is warned first for its own half second, within the one-second ceiling")
	var chases := {M207Lead.Answer.TOWARD: 0.35, M207Lead.Answer.STAND: 0.60,
			M207Lead.Answer.AWAY: 2.05}
	var edge := DangerEdge.new()
	for encounter in M207Lead.gold_encounters():
		var def: EventDef = encounter["def"]
		if def.id != "charging_dog":
			continue
		for answer: M207Lead.Answer in M207Lead.GOLD_ANSWERS:
			var how := "%s, answer %d" % [encounter["how"], answer]
			var met := M207Lead.gold(encounter, answer, edge)
			if answer == M207Lead.Answer.RUN:
				# Amendment 8 of M226: walking cannot outlast it, so running is what escapes.
				t.check(not met["caught"] and str(met["ends"]).begins_with("gave up"),
						"%s: running away the moment she is warned escapes it (%s)" % [how, met["ends"]])
				continue
			t.close_to(met["seen_at"], dog.offscreen_notice,
					"%s: the warning, badge to visible, is its half second (%.2fs)" % [how, met["seen_at"]],
					0.1)
			t.check(met["caught"], "%s: and it catches her (%s)" % [how, met["ends"]])
			if met["caught"]:
				var chase: float = met["caught_at"] - met["chase_at"]
				var expected: float = chases[answer]
				if answer == M207Lead.Answer.AWAY and encounter["heading"] == Vector2.RIGHT:
					expected = 3.95
				t.close_to(chase, expected,
						"%s: the chase, lunge to catch, is the lesson's %.2fs (%.2fs)"
						% [how, expected, chase], 0.05)
	edge.free()

## **The resistance's own pursuers are warned first like the day-3 dog, and arrive chasing.** *(M137's
## timing fork, the player: "A, remove the exemption"; amendment 7 of M226: "why would the robber walk
## towards her when it spawns as pursuing robber? the proximity rule is only for standing robbers".)*
## Both read the dog's own half-second badge and `Tuning.PURSUIT_TIME` chase, and are created with no
## closing-in: from above her — the start the director prefers — standing still and walking into him
## are caught, and so is walking away. Running escapes even while he is offscreen.
func _test_the_resistances_pursuers_are_fitted_to_the_dog(t) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	var edge := DangerEdge.new()
	for id: String in ["robber_giving_chase", "van_guard_giving_chase"]:
		var def := EventCatalogue.by_id(id)
		t.check(def.warns_before_it_exists() and def.arrives_chasing,
				"'%s' is warned of before it exists and arrives chasing" % id)
		t.check(is_equal_approx(def.offscreen_notice, dog.offscreen_notice)
				and is_equal_approx(def.duration, dog.duration),
				"'%s' reads the dog's own %.1fs badge and %.1fs chase (%.1f, %.1f)"
				% [id, dog.offscreen_notice, dog.duration, def.offscreen_notice, def.duration])
		for encounter in M207Lead.gold_encounters():
			if encounter["def"].id != id or encounter["heading"] != Vector2.UP:
				continue
			for answer: M207Lead.Answer in M207Lead.ANSWERS:
				var met := M207Lead.gold(encounter, answer, edge)
				t.close_to(met["created_at"], def.offscreen_notice,
						"'%s': its badge is alone for the dog's half second" % id, 2.0 * STEP)
				t.check(met["chase_at"] <= met["created_at"] + 2.0 * STEP,
						"'%s', answer %d: chasing from the frame he exists" % [id, answer])
				t.check(met["caught"], "'%s' from above, answer %d: caught (%s)"
						% [id, answer, met["ends"]])
	edge.free()

## **Nothing comes at her from off screen unwarned.** *(PLAYTEST-145: "all offscreen events should
## work like that".)* Every pursuer that is sent rather than met — no trigger to wait on, and not
## set off beside her at a door — is warned of first: the resistance's own two by their rows, and the
## day-3 dog by the copy `EventManager.as_warned()` makes as the director sends it. Each one's badge
## alone is at most `Tuning.WARNING_ALONE_MAX`.
func _test_every_pursuer_sent_from_off_screen_is_warned_first(t) -> void:
	var sent := 0
	for def in EventCatalogue.all():
		if not def.pursues or def.pursues_within > 0.0 or def.sets_off_beside_her:
			continue
		sent += 1
		var warned := EventManager.as_warned(def)
		t.check(warned.warns_before_it_exists() and warned.warned_for() <= Tuning.WARNING_ALONE_MAX,
				"'%s' is warned first, its badge alone %.2fs, at most %.2fs"
				% [def.id, warned.warned_for(), Tuning.WARNING_ALONE_MAX])
	t.check(sent >= 3, "the dog and the resistance's two are among them (%d)" % sent)

## **A retried day is the same day.** *(M39, playtest 10 finding 5: "the tutorial dog on day 3 only
## appeared once (I died) then it didn't appear again.")*
##
## `docs/TODO.md` has claimed this since M32 and it was not true: `build_day` ran six phases off one
## RNG, and a one-shot the run had already spent was skipped *before* its `randf()` was drawn, so the
## second attempt at day 3 — the day the fire engine runs — started the recurring fill one value
## earlier and produced a different city's worth of events. The trace has `homeless_yeller` going
## from two to eight and `cyclist` from none to three between two consecutive attempts at the same
## day.
##
## **What is asserted is the day's *composition*, not every coordinate**, and the difference is the
## measurement rather than a hedge: the multiset of event **kinds** has to be identical, and a
## `dog_walker` starting three tiles further up the same street is not a different day. Eight
## shouting men where there were two is, and that is what this stops.
##
## **Two directions, because a lost day gives the fire back altogether.** *("a retry always rolls
## new -- nothing that happened on the day that got retried can influence the next repeat")* —
## whether or not she ever reached it, so the ordinary retry is the same day down to the fire
## itself; a day planned after it actually burned on a day she **won** has none of it and nothing
## else different. The second is the one M39 was written against and it is asked here with an
## explicitly spent list, since a retry can no longer produce one.
func _test_a_retried_day_is_the_same_day(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for run_seed in [4242, 90210, 1234567]:
		var map := CityGenerator.generate(run_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:events" % [run_seed, day])

		var consumed: Array[String] = []
		var first := EventScheduler.build_day(day, rng, map, consumed)
		# **Planning day 3 spends nothing**, because its one-shot is owed to her walk and is spent
		# where it becomes real — `EventScheduler._place_one_shots`. And a lost day gives back what
		# it spent (`GameState.finish_day`), so every retry is the same day down to the fire itself.
		# The other direction, the day after it burned on a day she won, is the loop below this one.
		t.check(consumed.is_empty(),
				"seed %d: planning day %d spends nothing on its own" % [run_seed, day])
		var again := RandomNumberGenerator.new()
		again.seed = rng.seed
		var second := EventScheduler.build_day(day, again, map, consumed.duplicate())

		# The one-shot itself is the one thing that must differ: it fired yesterday and is spent, so
		# the retry plans **none** of it. *(Since M50 step 2 that is "none" rather than "one fewer":
		# a set piece is offered at every site of a covering set and the whole group goes with it.)*
		#
		# **And nothing else moves at all**, which is stronger than what M39 could promise. It used
		# to allow one instance of drift, because the ground a spent one-shot freed let a placement
		# that had failed now fit; an offer costs no room since M50 step 2 — see `_room_around` —
		# so the fill is identical between attempts rather than merely close. What is *not* closed
		# is still not closed: a **scar** genuinely occupies ground and still moves what stood
		# there, which is the run's own history showing through and is the answer that should.
		var before := _kinds_in(first)
		var after := _kinds_in(second)
		var changed := 0
		for id: String in before.keys() + after.keys():
			var expected: int = 0 if id in consumed else int(before.get(id, 0))
			t.check(int(after.get(id, 0)) == expected,
					"seed %d: the retry has %d '%s' where the day had %d"
					% [run_seed, int(after.get(id, 0)), id, expected])
			changed += 1 if int(after.get(id, 0)) != expected else 0
		t.check(changed == 0,
				"seed %d: and nothing else moves at all (%d kinds did)" % [run_seed, changed])

		# And the day *after* the fire actually burned: the one-shot is gone and nothing else is.
		# This is the half of the property a retry can no longer ask, since a lost day gives the
		# fire back — and it is the half M39 was written for, so it is asked here instead.
		var spent: Array[String] = ["burning_building"]
		var third_rng := RandomNumberGenerator.new()
		third_rng.seed = rng.seed
		var third := _kinds_in(EventScheduler.build_day(day, third_rng, map, spent))
		for id: String in before.keys() + third.keys():
			var expected: int = 0 if id in spent else int(before.get(id, 0))
			t.check(int(third.get(id, 0)) == expected,
					"seed %d: a day after the fire burned has %d '%s' where the day had %d"
					% [run_seed, int(third.get(id, 0)), id, expected])

## **The day the run is taught always has something to teach it with.** *(M39, finding 5.)*
##
## `charging_dog` is weight 1.4 of a day-3 pool and `EventDirector._teach_the_run` says outright what
## happens when the dice disagree — *"if the day happened not to buy one, there is nothing to teach
## and nothing happens"* — so a player could reach act II never having been shown the one control the
## game will later require. A lesson that only happens on some seeds is not a lesson.
func _test_the_run_is_always_taught(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	for run_seed in [4242, 90210, 1234567, 31337]:
		var map := CityGenerator.generate(run_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:events" % [run_seed, day])
		var consumed: Array[String] = []
		var pursuits := 0
		for plan in EventScheduler.build_day(day, rng, map, consumed):
			pursuits += 1 if plan.def.pursues else 0
		t.check(pursuits > 0,
				"seed %d: day %d has something that has to be run from" % [run_seed, day])

## **A beat rather than a journey.** *(M36, playtest 09: "who is the person killing me? It didn't
## move… if it's the homeless person it needs to walk up and down the sidewalk.")*
##
## The thing that could go quietly wrong is not the turning round, it is what a paced event does at
## the end of its path: everything else in the catalogue that reaches one is **over**, and since M35
## it leaves. A fixture that walks must do neither, or the man shouting outside the home block would
## stroll off down the street eight seconds into every day.
func _test_a_paced_event_walks_a_beat(t) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	t.check(def.paces and def.mobile, "the man shouting walks a beat")
	t.check(def.obstructs_radius <= 0.0,
			"and has no body, because a moving wall pins her — the dog_walker decision")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(256.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	var out := 256.0 / def.speed
	_advance(instance, out - 0.2)
	t.close_to(instance.position.x, 256.0, "it walks to the far end of its beat", 8.0)
	t.check(instance._heading.x > 0.0, "facing the way it is going")

	_advance(instance, out)
	t.close_to(instance.position.x, 0.0, "and back again", 8.0)
	t.check(instance._heading.x < 0.0, "facing the other way on the way back")
	t.check(not instance.is_finished and not instance.is_leaving,
			"a fixture that moves neither finishes nor leaves at the end of its path")

	# And it is still there four beats later, which is most of a day.
	_advance(instance, out * 8.0)
	t.check(not instance.is_finished, "and it is still there a day later")
	instance.free()

## **A pursuer can be a place before it is a moment.** *(M36, playtest 09: "a robber should increase
## excitement on sight and getting close to them should be day ending", and "if you get close they
## should start moving towards you".)*
##
## Three states, and the two that are new are the ones worth asserting: while it is **waiting** it
## emits at full strength and cannot end the day, and its telegraph and its chase are both measured
## from the moment it **notices** rather than from the moment the day put it there. A robbery whose
## telegraph ran at dawn, four streets away, would arrive with no notice in it at all.
func _test_a_pursuer_can_wait(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	t.check(def.pursues_within > 0.0, "the robber waits")
	var instance := _instance(t, def, Vector2.ZERO)

	# Standing there, all day, at full strength.
	instance.player_at = Vector2(def.pursues_within + 40.0, 0.0)
	_advance(instance, 30.0)
	t.check(instance.is_waiting(), "he is still standing there half a minute later")
	t.check(not instance.is_finished, "and his duration has not been running")
	t.close_to(instance.position.x, 0.0, "he has not moved", 0.5)
	t.close_to(instance.current_intensity(), def.intensity,
			"he is loud from the moment she can see him, not damped to a telegraph", 0.05)
	t.check(not instance.is_lethal_at(instance.player_at), "and he cannot end the day yet")
	t.check(instance.contribution_at(Vector2(def.outer_radius - 10.0, 0.0)) > 0.0,
			"his field reaches the far end of the alley")

	# She steps inside the trigger: the notice starts *now*.
	instance.player_at = Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "he notices her")
	t.check(instance.is_telegraphing(), "and the notice starts when he does, not at dawn")
	t.check(not instance.is_lethal_at(instance.player_at), "still not lethal during the notice")

	_advance(instance, def.telegraph_time + 0.1)
	t.check(not instance.is_telegraphing(), "then the notice is over")
	instance.free()

## **The robber stops at walls.** A pursuing `EventInstance` moves by setting its own position, and
## nothing in the event system has ever collided with the city — harmless while every mobile row
## travelled a route the scheduler had already checked, and not harmless the moment something
## steers freely at the player.
##
## A real building corner, chased round: she walks from its north face to its east face, and a dog
## aimed straight at wherever she currently is would cut across the building itself to follow her —
## exactly the shape of the bug. `EventInstance._walkable_step` is the fix, and this is what it
## has to hold true of every frame regardless of the geometry, which is why the check runs the
## whole walk rather than sampling the end of it.
func _test_a_pursuer_stops_at_walls(t) -> void:
	var map := _map()
	var corner := _a_building_corner(map)
	t.check(not corner.is_empty(), "the sampled map has a building corner to chase round")
	if corner.is_empty():
		return
	var north: Vector2i = corner["north"]
	var east: Vector2i = corner["east"]

	var def := EventCatalogue.by_id("charging_dog")
	var instance := EventInstance.new()
	instance.setup(def, map.tile_to_world(north) + Vector2(-96.0, 0.0))
	t.add_child(instance)
	instance.set_process(false)
	instance._map = map

	# Clear the telegraph with her held far off, so what follows is about the wall and not about
	# the stand-off.
	instance.player_at = map.tile_to_world(north) + Vector2(-4000.0, 0.0)
	_advance(instance, def.telegraph_time + 0.1)
	t.check(not instance.is_telegraphing(), "the dog is chasing by the time she rounds the corner")

	# She walks from the building's north face round to its east face — the corner a straight
	# line to her would cut across — and the dog is told to chase wherever she currently is,
	# every frame, the way `EventManager` actually drives it.
	var her := map.tile_to_world(north)
	var target := map.tile_to_world(east)
	var elapsed := 0.0
	var checked := 0
	while her.distance_to(target) > 4.0 and elapsed < 15.0:
		her = her.move_toward(target, Tuning.WALK_SPEED * STEP)
		instance.player_at = her
		instance._process(STEP)
		elapsed += STEP
		var tile := map.world_to_tile(instance.global_position)
		checked += 1
		t.check(map.is_walkable(tile),
				"the pursuer never stands on the building at %s (t=%.2fs)" % [tile, elapsed])
	t.check(checked > 0, "the walk round the corner actually ran")
	instance.free()

## An alley mouth on the real map, as the corner the robber reaches round: a building tile with
## alley ground on one side (`d1`, where he stands) and walkable ground on a perpendicular side
## (`d2`, the sidewalk she walks), with the tile between the two (the mouth, `d1 + d2`) walkable too,
## so the corner is one he can come round. `corner` is the building's own vertex shared by all four
## tiles; from it the building lies toward `-d1` and `-d2`. `{}` would mean the generator stopped
## carving alleys onto streets rather than that the search picked badly.
func _an_alley_mouth(map: CityMap) -> Dictionary:
	var sides: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for tile in map.tiles_of_type(GameEnums.TileType.BUILDING):
		for d1 in sides:
			if map.tile_at(tile + d1) != GameEnums.TileType.ALLEY:
				continue
			for d2 in [Vector2i(d1.y, d1.x), Vector2i(-d1.y, -d1.x)]:
				if map.is_walkable(tile + d2) and map.is_walkable(tile + d1 + d2):
					return {"building": tile, "d1": Vector2(d1), "d2": Vector2(d2),
							"corner": map.tile_to_world(tile) + Vector2(d1 + d2) * 16.0}
	return {}

## The alley robber on `map`, past his notice and chasing, so what follows is about the line between
## the two of them and not about the notice. The notice is run on open ground and the map handed over
## after it, since the notice asks for a clear line and the origin may be anywhere on `map`.
func _a_chasing_robber(t, map: CityMap) -> EventInstance:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	_advance(instance, def.telegraph_time + 0.1)
	instance._map = map
	return instance

## **He catches her only by touching her.** *(freckled-goose, #544: "Even then the distance would
## not physically connect so counting it as caught would be unfair. Only if the Robert touches the
## player should it end instantly".)* The catch the player met: him in the alley hugging the
## building, her on the sidewalk round its corner, 22px apart — inside his 26px catch — with the
## building's corner between them. She stands 14px off the building's face (`PLAYER_BODY_RADIUS`,
## where the building holds her) and is not inside the mouth.
func _test_the_robber_does_not_catch_her_through_a_wall(t) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	t.check(not mouth.is_empty(), "the sampled map has an alley opening onto a street")
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance := _a_chasing_robber(t, map)
	t.check(not instance.is_telegraphing() and not instance.is_waiting(), "he is chasing")
	instance.position = corner + d1 * 1.0 - d2 * 7.0
	var behind_the_wall := corner - d1 * 4.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	var reach := instance.def.lethal_reach()
	t.check(instance.global_position.distance_to(behind_the_wall) < reach,
			"she is inside his catch in a straight line (%.1fpx < %.1fpx)"
			% [instance.global_position.distance_to(behind_the_wall), reach])
	t.check(map.tile_at(map.world_to_tile(instance.global_position)) == GameEnums.TileType.ALLEY,
			"he is in the alley")
	t.check(not _sampled_line_is_walkable(map, instance.global_position, behind_the_wall),
			"the building's corner is between them")
	t.check(not instance.is_lethal_at(behind_the_wall),
			"and he does not catch her with the building's corner between them")
	# The same distance on open ground still catches: her in the mouth, the line between them clear.
	var in_the_mouth := corner + d1 * 4.0 + d2 * 14.0
	t.check(instance.global_position.distance_to(in_the_mouth) < reach, "the mouth is inside his catch")
	t.check(_sampled_line_is_walkable(map, instance.global_position, in_the_mouth),
			"nothing stands between him and the mouth")
	t.check(instance.is_lethal_at(in_the_mouth), "and with nothing between them, he catches her")
	instance.free()

## Where the alley robber waits for these tests: in the middle of the alley tile, `back` px in from
## the mouth's edge, so the building's corner stands between him and the sidewalk round it.
func _a_waiting_robber(t, map: CityMap, mouth: Dictionary, back: float) -> EventInstance:
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var at := corner + d1 * 16.0 - d2 * back
	var instance := _instance(t, EventCatalogue.by_id("alley_robbery"), at)
	instance._map = map
	return instance

## **He notices her only along a clear line.** *(leafy-puffin, inbox #648, asked whether noticing
## her should need a clear line: "yes noticing needs a clear line".)* He waits in the alley 40px
## back from the mouth; she stands on the sidewalk round the building's corner, well inside his 140px
## `pursues_within` in a straight line but with the building between them, and he goes on waiting
## and goes on looking down the alley. She steps in front of the mouth, nearer still, the line
## between them clear, and on that frame he notices her and turns to face her.
func _test_the_robber_does_not_notice_her_through_a_wall(t) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance := _a_waiting_robber(t, map, mouth, 40.0)
	var looking := instance.facing_now()
	var round_the_corner := corner - d1 * 60.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(instance.global_position.distance_to(round_the_corner) < instance.def.pursues_within,
			"round the corner she is inside his notice in a straight line (%.1fpx)"
			% instance.global_position.distance_to(round_the_corner))
	t.check(not _sampled_line_is_walkable(map, instance.global_position, round_the_corner),
			"with the building between them")
	instance.player_at = round_the_corner
	_advance(instance, 1.0)
	t.check(instance.is_waiting(), "he does not notice her through the building")
	t.check(instance.facing_now().is_equal_approx(looking), "and does not turn to face her")
	var in_the_mouth := corner + d1 * 16.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(_sampled_line_is_walkable(map, instance.global_position, in_the_mouth),
			"in front of the mouth nothing stands between them")
	instance.player_at = in_the_mouth
	instance._process(STEP)
	t.check(not instance.is_waiting(), "and there he notices her")
	t.check(instance.facing_now().is_equal_approx(
			(in_the_mouth - instance.global_position).normalized()), "and turns to face her")
	instance.free()

## **His lunge needs a clear line too.** *(mossy-beaver, inbox #650: "how would that even work? how
## can it pursue without noticing? obviously it needs a clear line".)* He notices her down the alley
## outside his stand-off, the line clear; she steps round the building's corner, inside his
## stand-off with the building between them, and he does not lunge. The line clears with her in
## front of the mouth, still inside his stand-off, and he still does not lunge from there — that
## would be the **events** skill's trap, a lunge from a fraction of the stand-off; he holds his
## ground as the door guard does. She walks straight out of the alley's line, away from him, and he
## lunges as she reaches the full stand-off.
func _test_the_robber_does_not_lunge_through_a_wall(t) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance := _a_waiting_robber(t, map, mouth, 40.0)
	var def := instance.def
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
	var start := instance.global_position
	var down_the_alley := start + d2 * (standoff + 10.0)
	t.check(_sampled_line_is_walkable(map, start, down_the_alley),
			"down the alley's line, past his stand-off, nothing stands between them")
	instance.player_at = down_the_alley
	instance._process(STEP)
	t.check(not instance.is_waiting() and instance.is_telegraphing(), "he notices her there")
	var round_the_corner := corner - d1 * 60.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(instance.global_position.distance_to(round_the_corner) < standoff,
			"round the corner she is inside his stand-off")
	t.check(not _sampled_line_is_walkable(map, instance.global_position, round_the_corner),
			"with the building between them")
	instance.player_at = round_the_corner
	_advance(instance, 0.25)
	t.check(instance.is_telegraphing(), "he does not lunge through the building")
	var in_the_mouth := corner + d1 * 16.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	instance.player_at = in_the_mouth
	instance._process(STEP)
	t.check(_sampled_line_is_walkable(map, instance.global_position, in_the_mouth)
			and instance.global_position.distance_to(in_the_mouth) < standoff,
			"in front of the mouth the line is clear and she is inside his stand-off")
	t.check(instance.is_telegraphing(), "and he does not lunge from a fraction of it")
	var her := in_the_mouth
	var lunge_range := INF
	var elapsed := 0.0
	while elapsed < 1.0 and lunge_range == INF:
		her += d2 * Tuning.WALK_SPEED * STEP
		instance.player_at = her
		instance._process(STEP)
		elapsed += STEP
		if not instance.is_telegraphing():
			lunge_range = instance.global_position.distance_to(her)
	t.check(lunge_range != INF, "walking away down the alley's line, he lunges")
	t.check(lunge_range >= standoff - 2.0,
			"from his full stand-off (%.1fpx of %.1fpx)" % [lunge_range, standoff])
	instance.free()

## **A walk past an alley keeps the whole of his lunge's notice, though the wall holds both back.**
## The robber waits in the alley 20, 40, 60 and 90px back from the mouth; she walks along the
## sidewalk toward it at `WALK_SPEED`, 14px off the building's face, and on past. The building hides
## her until she is nearly at the mouth, so he notices her only once the line between them is clear,
## already inside his stand-off, and a lunge from there would leave her a fraction of it — the
## **events** skill's trap. So he holds his ground until she has walked back out to his stand-off,
## and the chase starts from there, by the lunge or by the end of his notice, whichever comes first.
## What the stand-off contract owes her is checked as walked: the notice along a clear line, the
## lunge from about the stand-off, and at least `PURSUIT_REACTION` from the lunge to the catch. And he
## still never catches her through the corner: every frame that catches has a clear sampled line.
func _test_the_robber_keeps_his_stand_off_at_an_alley_mouth(t) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var def := EventCatalogue.by_id("alley_robbery")
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach())
	for back in [20.0, 40.0, 60.0, 90.0]:
		var instance := _instance(t, def, corner + d1 * 16.0 - d2 * back)
		instance._map = map
		var her := corner - d1 * 300.0 + d2 * Tuning.PLAYER_BODY_RADIUS
		var elapsed := 0.0
		var lunged_at := INF
		var lunge_range := INF
		var caught_at := INF
		var through_a_wall := 0
		var noticed_through_a_wall := false
		while elapsed < 15.0 and caught_at == INF and not instance.is_finished:
			her += d1 * Tuning.WALK_SPEED * STEP
			instance.player_at = her
			var was_waiting := instance.is_waiting()
			instance._process(STEP)
			elapsed += STEP
			if was_waiting and not instance.is_waiting():
				noticed_through_a_wall = not _sampled_line_is_walkable(map,
						instance.global_position, her)
			if lunged_at == INF and not instance.is_waiting() and not instance.is_telegraphing():
				lunged_at = elapsed
				lunge_range = instance.global_position.distance_to(her)
			if instance.is_lethal_at(her):
				caught_at = elapsed
				if not _sampled_line_is_walkable(map, instance.global_position, her):
					through_a_wall += 1
		t.check(lunged_at != INF and caught_at != INF,
				"%dpx into the alley: he lunges and catches her as she walks past" % int(back))
		t.check(lunge_range >= standoff - 6.0,
				"%dpx in: he lunges from about his stand-off (%.1fpx of %.1fpx)"
				% [int(back), lunge_range, standoff])
		t.check(caught_at - lunged_at >= Tuning.PURSUIT_REACTION,
				"%dpx in: she has her reaction time between his lunge and his catch (%.2fs)"
				% [int(back), caught_at - lunged_at])
		t.check(not noticed_through_a_wall,
				"%dpx in: he notices her only once nothing stands between them" % int(back))
		t.check(through_a_wall == 0, "%dpx in: and he never catches her through the corner" % int(back))
		instance.free()

## **The doubled red caret projects the catch, not the field's core.** `will_be_lethal()` asks
## whether a pursuer's course puts her inside the radius that ends the day; for the hunting
## roadblock that is his 28px reach (`lethal_reach()`), not the band's 86px core, which every other
## row's catch already is. His course passes 20px from her: red. 50px, beyond his reach and inside
## the core: not red. Both points sit on a quarter-second step of the projection, so neither answer
## depends on where its samples fall.
func _test_the_red_caret_is_measured_from_the_catch(t) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), Tuning.HEAT_HUNTS_LEVEL)
	t.check(hot.pursues and hot.hard_fail and hot.lethal_reach() < hot.inner_radius,
			"the hunting roadblock catches inside its field's core (%.0fpx < %.0fpx)"
			% [hot.lethal_reach(), hot.inner_radius])
	var instance := _instance(t, hot, Vector2.ZERO)
	instance.player_at = Vector2(hot.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting(), "the guard notices her")
	var heading := instance.facing_now()
	var ahead := instance.global_position + heading * hot.pursue_speed * 0.5
	var across := heading.orthogonal()
	t.check(instance.will_be_lethal(ahead + across * 20.0), "his course 20px from her reads red")
	t.check(not instance.will_be_lethal(ahead + across * 50.0),
			"his course 50px from her, beyond his reach, does not")
	instance.free()

## **To catch her round a corner he has to come round it.** She stands on the sidewalk just round
## the building from him, inside his catch in a straight line, and he chases: he slides along the
## building's face (`_walkable_step`) and catches her only once the line between them clears the
## building's corner, never through it. Every frame of the chase is checked against a line sampled
## a quarter pixel at a time, a second answer to the question `_clear_line_to()` asks, so a frame
## that catches through the corner fails it wherever it falls.
func _test_the_robber_catches_her_by_coming_round_the_corner(t) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d2: Vector2 = mouth["d2"]
	var d1: Vector2 = mouth["d1"]
	var instance := _a_chasing_robber(t, map)
	var start := corner + d1 * 1.0 - d2 * 7.0
	instance.position = start
	var her := corner - d1 * 4.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	instance.player_at = her
	var elapsed := 0.0
	var caught := false
	var through_a_wall := 0
	while elapsed < 2.0 and not caught and not instance.is_finished:
		if instance.is_lethal_at(her):
			caught = true
			if not _sampled_line_is_walkable(map, instance.global_position, her):
				through_a_wall += 1
		instance._process(STEP)
		elapsed += STEP
	t.check(caught, "he catches her in the end")
	t.check(through_a_wall == 0, "and never with the building between them")
	t.check(instance.global_position.distance_to(start) > 4.0,
			"he had to move to do it (%.1fpx, %.2fs)" % [instance.global_position.distance_to(start),
			elapsed])
	instance.free()

## Every tile a straight line passes through, found by sampling it `per_px` times a pixel.
func _sampled_line_is_walkable(map: CityMap, from: Vector2, to: Vector2, per_px := 4.0) -> bool:
	var samples := maxi(1, ceili(from.distance_to(to) * per_px))
	for i in samples + 1:
		if not map.is_walkable(map.world_to_tile(from.lerp(to, float(i) / float(samples)))):
			return false
	return true

## **`_clear_line_to()` against the sampled line, over the real map.** Seeded segments up to a
## stand-off long from walkable ground near buildings, in every direction, each answered both by
## stepping tile boundaries and by sampling an eighth of a pixel at a time; the two have to agree.
## The guard counts how many of them crossed a building, so a sweep that only ever asked open
## ground cannot pass.
func _test_a_clear_line_is_every_tile_the_line_crosses(t) -> void:
	var map := _map()
	var rng := RandomNumberGenerator.new()
	rng.seed = 544
	var buildings := map.tiles_of_type(GameEnums.TileType.BUILDING)
	var instance := _instance(t, EventCatalogue.by_id("alley_robbery"), Vector2.ZERO)
	instance._map = map
	var asked := 0
	var blocked := 0
	var disagreed := 0
	while asked < 400:
		var near: Vector2i = buildings[rng.randi_range(0, buildings.size() - 1)]
		var from := map.tile_to_world(near) + Vector2(rng.randf_range(-64.0, 64.0),
				rng.randf_range(-64.0, 64.0))
		if not map.is_walkable(map.world_to_tile(from)):
			continue
		var to := from + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(1.0, 116.0)
		instance.position = from
		var sampled := _sampled_line_is_walkable(map, from, to, 8.0)
		asked += 1
		if not sampled:
			blocked += 1
		if instance._clear_line_to(to) != sampled:
			disagreed += 1
	t.check(blocked > 40, "the sweep crossed buildings (%d of %d)" % [blocked, asked])
	t.check(disagreed == 0, "stepping tiles and sampling agree on every line (%d did not)" % disagreed)
	instance.free()

## A 10×10 map of sidewalk with the given tiles built on, for the stepper's exact cases.
func _a_small_map(buildings: Array[Vector2i]) -> CityMap:
	var map := CityMap.new(Vector2i(10, 10))
	map.fill_rect(Rect2i(0, 0, 10, 10), GameEnums.TileType.SIDEWALK)
	for tile in buildings:
		map.set_tile(tile, GameEnums.TileType.BUILDING)
	return map

func _clear_on(t, map: CityMap, from: Vector2, to: Vector2) -> bool:
	var instance := _instance(t, EventCatalogue.by_id("alley_robbery"), from)
	instance._map = map
	var clear := instance._clear_line_to(to)
	instance.free()
	return clear

## **The cases a random sweep never lands on, each on exact binary fractions so the arithmetic is
## exact.** A 45° line through a tile vertex, (80, 80) to (112, 112) through (96, 96), crosses both
## axes at once: a building on either tile beside the vertex blocks it, the x-side one (3, 2) and
## the y-side one (2, 3) asked separately, since stepping one axis and then the other visits only one
## of them. A line ending exactly on a tile's edge, (64, 80) to (128, 80), ends on the building
## beyond the edge (4, 2), since a point on an edge is the tile it opens (`world_to_tile()` floors),
## so its last crossing, at exactly the whole of the segment, is asked. A line starting on a
## building is blocked though it crosses into open ground. A line inside one open tile is clear.
func _test_a_clear_line_at_a_corner_an_edge_and_its_own_start(t) -> void:
	var through_the_vertex := [Vector2(80.0, 80.0), Vector2(112.0, 112.0)]
	t.check(_clear_on(t, _a_small_map([]), through_the_vertex[0], through_the_vertex[1]),
			"a line through an open vertex is clear")
	t.check(not _clear_on(t, _a_small_map([Vector2i(3, 2)]), through_the_vertex[0],
			through_the_vertex[1]), "a building on the x side of the vertex blocks the line")
	t.check(not _clear_on(t, _a_small_map([Vector2i(2, 3)]), through_the_vertex[0],
			through_the_vertex[1]), "a building on the y side of the vertex blocks the line")
	t.check(not _clear_on(t, _a_small_map([Vector2i(4, 2)]), Vector2(64.0, 80.0),
			Vector2(128.0, 80.0)), "a line ending exactly on a building's edge is blocked")
	t.check(_clear_on(t, _a_small_map([Vector2i(4, 2)]), Vector2(64.0, 80.0),
			Vector2(127.5, 80.0)), "and half a pixel short of it is clear")
	t.check(not _clear_on(t, _a_small_map([Vector2i(2, 2)]), Vector2(80.0, 80.0),
			Vector2(100.0, 80.0)), "a line starting on a building is blocked")
	t.check(_clear_on(t, _a_small_map([]), Vector2(66.0, 66.0), Vector2(90.0, 90.0)),
			"a line inside one open tile is clear")
