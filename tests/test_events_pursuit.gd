extends RefCounted
## The chase lesson, in the three answers a player can give: into it, away at a walk, away at a
## run -- plus the mechanics a pursuer has to keep regardless of which she picks: it leaves no
## field clear to stand in, it can be kept waiting, it stops at a wall, and a hard-fail row is
## lethal by the time it actually reaches her. A live event is stood on open ground or on a hand-built
## map, with the navigator of that map where a wall matters, and told where she is by a
## `WhereSheIs` the case moves; no city is generated here.
##
## *(M35, playtest 08 finding 4: "I like the running tutorial on day 3 but I don't know how to
## solve it yet -- I died every time.")* `validate_pursuit` passed every line of itself while the
## dog was killing people, because every line of it was about **speeds and durations** and a
## pursuit is played out in **distances**. The rig below is the contract walked rather than
## asserted.

const STEP := 1.0 / 60.0

## A 48x48 map of sidewalk with one building block, tiles 10 to 17 across and down, cut by an alley
## two tiles wide from the block's north face to its south face: the wall, the corner and the alley
## mouth the wall cases chase and hide round, with open ground south of it for a straight run.
func _map() -> CityMap:
	var map := CityMap.new(Vector2i(48, 48))
	map.fill_rect(Rect2i(0, 0, 48, 48), GameEnums.TileType.SIDEWALK)
	map.fill_rect(Rect2i(10, 10, 8, 8), GameEnums.TileType.BUILDING)
	map.fill_rect(Rect2i(13, 10, 2, 8), GameEnums.TileType.ALLEY)
	return map

func run(t: TestRunner) -> void:
	_test_a_pursuer_leaves_room_to_answer(t)
	_test_the_answer_is_priced_by_how_soon_it_is_given(t)
	_test_a_pursuer_is_sited_where_it_can_be_seen(t)
	_test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t)
	_test_the_day_3_dog_keeps_its_gold_timing(t)
	_test_the_resistances_pursuers_are_fitted_to_the_dog(t)
	_test_a_sent_pursuer_counts_running_before_he_is_visible(t)
	_test_a_paced_event_walks_a_beat(t)
	_test_a_pursuer_can_wait(t)
	_test_every_waiting_charger_warns_by_radius(t)
	_test_a_warning_is_not_counted_as_a_chase(t)
	_test_a_pursuer_stops_at_walls(t)
	_test_the_robbers_lunge_is_further_out_than_his_catch(t)
	_test_the_robber_does_not_catch_her_through_a_wall(t)
	_test_the_robber_does_not_notice_her_through_a_wall(t)
	_test_the_robber_does_not_lunge_through_a_wall(t)
	_test_a_late_notice_is_answered_by_his_warning(t)
	_test_the_robber_keeps_his_stand_off_at_an_alley_mouth(t)
	_test_the_red_caret_is_measured_from_the_catch(t)
	_test_the_robber_catches_her_by_coming_round_the_corner(t)


## A bare instance of `def` at `at`, in the tree, its frames stepped by the test (`_advance()`), on
## `map` with a navigator of its own when one is given, as `EventInstance.setup()` is handed them,
## and on open ground otherwise.
func _instance(t: TestRunner, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array(), map: CityMap = null,
		where: WhereSheIs = null) -> EventInstance:
	var instance := EventInstance.new(ToldEvents.on(EventBus))
	var surroundings := EventSurroundings.new().on(map) \
			.moving_by(Navigator.new(map) if map else null)
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, at, path, Vector2.RIGHT, surroundings)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## A sent pursuer's badge is enough notice: a sustained run can end the chase before he is seen.
## Brief runs separated by walking do not accumulate into one escape.
func _test_a_sent_pursuer_counts_running_before_he_is_visible(t: TestRunner) -> void:
	for id: String in ["robber_giving_chase", "van_guard_giving_chase", "policeman_giving_chase",
			"guardsman_giving_chase"]:
		var pursuer_where := WhereSheIs.nowhere()
		var pursuer := EventInstance.new()
		pursuer.setup(EventCatalogue.by_id(id), Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
				EventSurroundings.new().hearing(pursuer_where))
		pursuer_where.tell(pursuer_where.at(), Vector2.INF, Rect2(), true)
		for frame in int(Tuning.PURSUIT_SHAKEN_OFF / STEP) - 1:
			pursuer_where.tell(Vector2(500.0 + frame * Tuning.RUN_SPEED * STEP, 0.0),
					Vector2.INF, Rect2(), pursuer_where.is_running())
			pursuer.step(STEP)
		t.check(not pursuer.has_given_up(), "%s needs the full sustained run" % id)
		pursuer_where.tell(pursuer_where.at())
		pursuer.step(STEP)
		pursuer_where.tell(pursuer_where.at(), Vector2.INF, Rect2(), true)
		for frame in int(Tuning.PURSUIT_SHAKEN_OFF / STEP) - 1:
			pursuer_where.tell(pursuer_where.at() + Vector2.RIGHT * Tuning.RUN_SPEED * STEP,
					Vector2.INF, Rect2(), pursuer_where.is_running())
			pursuer.step(STEP)
		t.check(not pursuer.has_given_up(), "%s restarts the shake-off timer after a walk" % id)
		for frame in 3:
			pursuer_where.tell(pursuer_where.at() + Vector2.RIGHT * Tuning.RUN_SPEED * STEP,
					Vector2.INF, Rect2(), pursuer_where.is_running())
			pursuer.step(STEP)
		t.check(pursuer.has_given_up(), "%s is shaken off by sustained running while offscreen" % id)
		pursuer.free()

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
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	var her := Vector2(_sited_at(def), 0.0)
	# Positive is away from it, matching `_chase_rig`. She starts walking in.
	var speed := -Tuning.WALK_SPEED
	var elapsed := 0.0
	var since_the_lunge := INF
	var result := {"caught": false, "closest": INF, "running": 0.0}
	while elapsed < 14.0 and not instance.is_on_its_way_out() and not result["caught"]:
		if not instance.is_telegraphing() and not instance.is_waiting() and since_the_lunge == INF:
			since_the_lunge = 0.0
		var wanted := -Tuning.WALK_SPEED
		if since_the_lunge != INF and since_the_lunge >= reaction:
			wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		if speed > Tuning.WALK_SPEED:
			result["running"] = float(result["running"]) + STEP
		her.x += speed * STEP
		instance_where.tell(her, Vector2.INF, Rect2(), speed > Tuning.WALK_SPEED)
		instance.step(STEP)
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
## them — `SpawnSiting.least_distance()`, the view's half height, which is the least ground the
## contract can ever rely on. A rig checked against a more generous heading would pass on an
## encounter the game can still produce on a worse one.
func _sited_at(def: EventDef) -> float:
	if def.notice_within() > 0.0:
		return def.notice_within() - 10.0
	return SpawnSiting.least_distance()

## Walks one answer to a pursuit and reports what happened. `player_speed` is along the line between
## them: positive is away from it, negative is into it.
func _chase_rig(def: EventDef, player_speed: float) -> Dictionary:
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT,
			EventSurroundings.new().hearing(instance_where))
	var from := _sited_at(def)
	var her := Vector2(from, 0.0)
	var elapsed := 0.0
	var result := {"caught": false, "gave_up": false, "lethal_while_telegraphing": false,
			"at_the_lunge": INF, "ended_at": INF}
	var was_telegraphing := true
	while elapsed < 12.0 and not instance.is_gone() and not result["caught"]:
		her.x += player_speed * STEP
		instance_where.tell(her, Vector2.INF, Rect2(), instance_where.is_running())
		# The break-off is a fact about *her* since playtest 14, so a rig that only moves her is
		# not running the rule. See `Tuning.PURSUIT_SHAKEN_OFF`.
		instance_where.tell(instance_where.at(), Vector2.INF, Rect2(),
				player_speed > Tuning.WALK_SPEED)
		instance.step(STEP)
		elapsed += STEP
		if was_telegraphing and not instance.is_telegraphing() and not instance.is_waiting():
			result["at_the_lunge"] = instance.global_position.distance_to(her)
			was_telegraphing = false
		if instance.is_lethal_at(her):
			result["caught"] = true
			result["lethal_while_telegraphing"] = was_telegraphing
		if instance.has_given_up() and result["ended_at"] == INF:
			result["gave_up"] = true
			result["ended_at"] = elapsed
	if result["ended_at"] == INF:
		result["ended_at"] = elapsed
	result["waiting"] = instance.is_waiting()
	instance.free()
	return result

## A building tile with open pavement on two adjacent sides — the outward corner every
## rectangular building has at least one of. `{}` would mean the hand-built map has none rather
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
## at 26px and lunges from 116px (`PursuitSpec.lunge_reach()` 38), so the room between lunge and
## catch is 90px, and no pursuer but the robber and the ones read off him moves its lunge off
## its own catch.
func _test_the_robbers_lunge_is_further_out_than_his_catch(t: TestRunner) -> void:
	# The robber, and the pursuer on foot a torn poster sends, who is the task robber's chase in a
	# uniform (`EventCatalogue._policeman_giving_chase()`).
	var robbers := ["alley_robbery", "robber_giving_chase", "policeman_giving_chase",
			"guardsman_giving_chase"]
	for def in CatalogueRows.every():
		t.check(not def.lunge_is_inside_the_catch(), "'%s' does not lunge from inside its catch" % def.id())
		if def.pursues() and not robbers.has(def.id()):
			t.check(is_equal_approx(def.standoff_reach(), def.lethal_reach()),
					"'%s' lunges from its own catch" % def.id())
	# A `PursuitSpec.lunge_reach()` inside the catch would stand the pursuer off closer than
	# `PURSUIT_REACTION` of its own approach from taking her: 10px on a 26px catch is an 88px
	# stand-off, 62px of room, 0.48s at 130px/s. `validate()` refuses it on load (asked here
	# through the predicate, since the refusal is a `push_error`, which fails the whole run); a
	# lunge exactly at the catch is allowed.
	var robbery := EventCatalogue.by_id("alley_robbery")
	var lunging := robbery.redraft()
	lunging.pursuit(robbery.pursuit().lunging_from(10.0))
	var too_short := lunging.build()
	t.check(too_short.lunge_is_inside_the_catch(), "a 10px lunge on a 26px catch is inside it")
	lunging.pursuit(robbery.pursuit().lunging_from(robbery.lethal_reach()))
	var at_the_catch := lunging.build()
	t.check(not at_the_catch.lunge_is_inside_the_catch(), "a lunge exactly at the catch is not")
	lunging.pursuit(robbery.pursuit().lunging_from(0.0))
	var from_nowhere := lunging.build()
	t.check(not from_nowhere.lunge_is_inside_the_catch(), "and 0 means the catch")

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
func _test_a_pursuer_leaves_room_to_answer(t: TestRunner) -> void:
	var pursuers := 0
	for def in CatalogueRows.every():
		# A pursuer that sets off beside her, or charges at once at a door, is never sited by the
		# director, so this rig's geometry is not its own; `tests/test_checkpoints.gd` walks
		# `door_guard` at a door instead.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance_traps.gd`.
		if not def.pursues() or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) or def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
			continue
		pursuers += 1
		var standoff := PursuitSpec.standoff(def.chase_speed(), def.standoff_reach())
		t.check(standoff > def.core_within(),
				"'%s' holds off outside the radius that ends the day" % def.id())
		# One that waits for her charges on its warning's clock, not at its stand-off; it is walked
		# in `_test_every_waiting_charger_warns_by_radius`.
		if def.notice_within() > 0.0:
			continue

		# Into it. The geometry the day-3 lesson actually produces, and the one that killed a run
		# three times: it keeps its distance while it is only telegraphing, however far she walks in.
		var walked_in := _chase_rig(def, -Tuning.WALK_SPEED)
		t.close_to(walked_in["at_the_lunge"], standoff,
				"walking into '%s' still leaves the whole stand-off when it goes lethal" % def.id(),
				8.0)
		t.check(not walked_in["lethal_while_telegraphing"],
				"and nothing '%s' does during its own telegraph can end the day" % def.id())

		# Away from it at a walk. Walking has to lose, or the mechanic teaches nothing.
		var walked_off := _chase_rig(def, Tuning.WALK_SPEED)
		t.check(walked_off["caught"], "walking away from '%s' is not enough" % def.id())
		t.check(not walked_off["gave_up"],
				"so '%s' never has to give up on somebody walking" % def.id())

		# Away from it at a run. Running has to win, and it has to *end* it: the price of the right
		# answer is fourteen points a second, so a chase that runs its full clock however well it is
		# played is a toll rather than a lesson. Both facts follow from the speed clauses alone —
		# nothing slower than the pursuer can open the gap and nothing faster can fail to — which is
		# why `PURSUIT_SHAKEN_OFF` is stated as a rate and there is no distance to get wrong.
		var ran := _chase_rig(def, Tuning.RUN_SPEED)
		t.check(not ran["caught"], "running away from '%s' works" % def.id())
		t.check(ran["gave_up"],
				"and '%s' breaks off rather than tailing her for the whole chase" % def.id())
		t.check(ran["ended_at"] < def.telegraphs_for() + def.lasts_for(),
				"which ends '%s' early: %.1fs against a %.1fs chase"
				% [def.id(), ran["ended_at"], def.telegraphs_for() + def.lasts_for()])
		var cost: float = ran["ended_at"] * Baby.EXCITEMENT_FROM_RUNNING
		t.check(cost < Tuning.METER_MAX * 0.6,
				"and running from '%s' costs %.0f of a %.0f meter rather than the day"
				% [def.id(), cost, Tuning.METER_MAX])
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
## front of her and holds its distance by backing off — so the gap closes at its chase speed
## plus `WALK_SPEED` and the stand-off is worth about a third of the `PURSUIT_REACTION` it was
## bought with. A player answers during the **telegraph**, where the dog is visible and closing
## for two and a half seconds, and that answer is cheap; the lunge is the worst case rather than
## the expected one. Widening it means a wider stand-off, and a wider stand-off is a dog that
## visibly reverses.
func _test_the_answer_is_priced_by_how_soon_it_is_given(t: TestRunner) -> void:
	for def in CatalogueRows.every():
		# Sited beside her rather than by the director — see `_test_a_pursuer_leaves_room_to_answer`.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance_traps.gd`.
		if not def.pursues() or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) or def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
			continue
		# One that waits for her charges on its warning's clock and is walked in
		# `_test_every_waiting_charger_warns_by_radius`.
		if def.notice_within() > 0.0:
			continue
		var at_once := _answer_rig(def, 0.0)
		t.check(not at_once["caught"],
				"'%s' can be answered at the lunge (closest %.0fpx)" % [def.id(), at_once["closest"]])
		t.check(at_once["closest"] > def.core_within(),
				"and answering it clears the %.0fpx that ends the day by %.0fpx"
				% [def.core_within(), at_once["closest"] - def.core_within()])

		# The price is the about-turn plus being visibly outrun, and nothing else. A chase that ran
		# its clock however well it was played would cost `PURSUIT_TIME` here instead.
		var turn := (Tuning.WALK_SPEED + Tuning.RUN_SPEED) / Tuning.ACCELERATION
		t.check(at_once["running"] < Tuning.PURSUIT_SHAKEN_OFF + turn + 0.5,
				"and it costs %.1fs of running rather than the %.1fs chase"
				% [at_once["running"], def.lasts_for()])
		t.check(at_once["running"] * Baby.EXCITEMENT_FROM_RUNNING < Tuning.METER_MAX * 0.3,
				"which is %.0f of a %.0f meter"
				% [at_once["running"] * Baby.EXCITEMENT_FROM_RUNNING, Tuning.METER_MAX])

		# Answering during the telegraph — what a player who reads the cue actually does — is cheaper
		# still, and that gradient is the reason the break-off is a rate rather than a clock.
		# One that warns by radius is never charged at all: she is out of its radius before its
		# stand-off (`EventInstance.warns_by_radius()`).
		var early := _chase_rig(def, Tuning.RUN_SPEED)
		t.check((early["gave_up"] or (def.notice_within() > 0.0 and early["waiting"]))
				and not early["caught"],
				"running from '%s' the moment it appears shakes it off" % def.id())

		# And doing nothing still loses, which is the whole reason any of this is a mechanic.
		t.check(_answer_rig(def, 1.0)["caught"],
				"'%s' still catches somebody who leaves it far too long" % def.id())

		# Reported, not asserted: the widest reaction at the lunge that still survives. See above.
		var window := 0.0
		for i in 12:
			var reaction := i * 0.05
			if _answer_rig(def, reaction)["caught"]:
				break
			window = reaction
		t.check(window > 0.0,
				"the window to answer '%s' at the lunge itself is %.2fs" % [def.id(), window])

## **A pursuer has to be sited where it actually closes on her rather than backing away.**
##
## Two things have to agree and neither knows about the other: the stand-off is where it stops, and
## the warning decides where it starts. If the stand-off ever grows past the least it could ever be
## created at — `SpawnSiting.least_distance()`, the worst case over every heading she might be
## walking and either control scheme — a pursuer *backs away* through its own telegraph instead of
## closing, which is a dog that visibly reverses down the street in front of her.
##
## The relationship is asserted rather than left as a coincidence: a change to the stand-off or to
## `VIEW_HALF_EXTENT` has moved these numbers before without anybody checking they still agree.
func _test_a_pursuer_is_sited_where_it_can_be_seen(t: TestRunner) -> void:
	for def in CatalogueRows.every():
		# Sited beside her by construction, which is what its own stand-off rule answers.
		# One that arrives chasing has no closing-in to a stand-off for this rig to walk; the
		# resistance's sent robber and guard are walked in `tests/test_resistance_traps.gd`.
		if not def.pursues() or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) or def.starts_by(PursuitSpec.Start.CHARGES_AT_ONCE):
			continue
		var standoff := PursuitSpec.standoff(def.chase_speed(), def.standoff_reach())
		var floor_lead := SpawnSiting.least_distance()
		t.check(standoff < floor_lead,
				"'%s' stands off at %.0fpx, inside the %.0fpx it is sited at even on the worst axis"
				% [def.id(), standoff, floor_lead])
		if def.notice_within() > 0.0:
			# A place, not a moment: the director never sites it, so what has to hold is that its
			# trigger is outside its stand-off — which `validate_pursuit` also checks, from the
			# other side and for a different reason.
			t.check(def.notice_within() > standoff,
					"'%s' notices her before it has stopped coming" % def.id())
			continue
		t.check(_sited_at(def) >= standoff,
				"'%s' is sited at %.0fpx, at or beyond the %.0fpx it stops at, so it closes rather "
				% [def.id(), _sited_at(def), standoff] + "than backing away through its own telegraph")

## **A row declared lethal has to actually get the chance to be lethal.** *(2026-09-07: "also a
## biker hit should be lethal.")* `cyclist` ends the day (`ends_the_day()`), but
## `EventInstance.is_lethal_at()` returns false for the whole of `is_telegraphing()` — so a
## `TOWARD_PLAYER` row that reached her before its own telegraph ended would ride straight through,
## declared lethal and never once able to fire. Such a row's telegraph is its warning, run before it
## exists (`PendingWarning`, at most `Tuning.WARNING_ALONE_MAX`), and it is created with that
## telegraph spent; this walks the warning and
## the arrival together, at the instance level, rather than trusting the construction.
##
## Walks every lethal `TOWARD_PLAYER` row in the catalogue rather than naming `cyclist`, so a
## second row of the same shape is covered by construction rather than by remembering to add it.
func _test_a_hard_fail_toward_player_row_is_lethal_by_the_time_it_reaches_her(t: TestRunner) -> void:
	var checked := 0
	for def in CatalogueRows.every():
		if not def.comes_toward_her() or not def.ends_the_day():
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
			arrived[0].step(STEP)
			if arrived[0].is_lethal_at(her):
				was_lethal = true
				break
		t.check(was_lethal,
				"'%s' is declared lethal and its warning is over by the time it reaches her"
				% def.id())
		for instance in arrived:
			instance.free()
	t.check(checked > 0, "there is at least one lethal TOWARD_PLAYER row to check ('cyclist')")

## A warning for `def` coming down her line from `direction`, on open ground, put up with her at
## `her` — the construction `EventsAhead._warn_down_her_line()` makes, with creation done the way
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
		instance.restore(EventSave.new(EventSpawner.age_when_warned(def), 0.0))
		arrived.append(instance)
		return true
	var warning := PendingWarning.new(def, where, arrive)
	warning.put_up(her)
	return warning

## **The day-3 dog keeps its gold timing, in the player's terms.** *(PLAYTEST-145: "the pursuit dog
## timing from the day 3 lesson is the correct timing ... this is the gold timing with warning time
## and onscreen pursuing time seen as correct"; inbox #598: "the chase is what happens on screen" ·
## "off screen doesn't count toward the timing it only counts towards the warning timing" · "0.53 is
## a good warning time -- the chase on screen didn't change at all".)* Per answer, the **warning** is
## the time from the first warning she can see (the badge) to the dog first visible (anything it
## draws in view), and the **chase** is from its lunge to the catch. Its numbers stay as built — a
## half-second badge alone (`warned_for()`), a 4.5s approach (`telegraphs_for()`) and a chase at
## 130px/s that does not give up on a walker (`Tuning.PURSUIT_TIME`, a long cap; amendment 8: "pursuers
## should never (or a long time) stop pursuing if she walks") — and so does what she meets: walked as
## she meets it (`M207Lead.gold()`, the probe's own walk, straight down her line), the warning is the
## half-second badge in all three answers and the chase is the lesson's own, 0.35s walking into it,
## 0.60s standing and 2.05s walking away, which loses; running away the moment she is warned escapes
## it, which is the lesson. A later change to its placement, to the camera or to its numbers fails
## here.
func _test_the_day_3_dog_keeps_its_gold_timing(t: TestRunner) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	# Amendment 8 of M226: "pursuers should never (or a long time) stop pursuing if she walks".
	t.check(Tuning.PURSUIT_TIME >= 30.0, "which is a long cap, not an end a walk outlasts (%.0fs)"
			% Tuning.PURSUIT_TIME)
	var sent := EventSpawner.as_warned(dog)
	t.check(sent.warns_before_it_exists() and is_equal_approx(sent.warned_for(), dog.warned_for())
			and sent.warned_for() <= Tuning.WARNING_ALONE_MAX,
			"sent at her, it is warned first for its own half second, within the one-second ceiling")
	var chases := {M207Lead.Answer.TOWARD: 0.35, M207Lead.Answer.STAND: 0.60,
			M207Lead.Answer.AWAY: 2.05}
	var edge := DangerEdge.new()
	for encounter in M207Lead.gold_encounters():
		var def: EventDef = encounter["def"]
		if def.id() != "charging_dog":
			continue
		for answer: M207Lead.Answer in M207Lead.GOLD_ANSWERS:
			var how := "%s, answer %d" % [encounter["how"], answer]
			var met := M207Lead.gold(encounter, answer, edge)
			if answer == M207Lead.Answer.RUN:
				# Amendment 8 of M226: walking cannot outlast it, so running is what escapes.
				t.check(not met["caught"] and str(met["ends"]).begins_with("gave up"),
						"%s: running away the moment she is warned escapes it (%s)" % [how, met["ends"]])
				continue
			t.close_to(met["seen_at"], dog.warned_for(),
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
func _test_the_resistances_pursuers_are_fitted_to_the_dog(t: TestRunner) -> void:
	var dog := EventCatalogue.by_id("charging_dog")
	var edge := DangerEdge.new()
	for id: String in ["robber_giving_chase", "van_guard_giving_chase"]:
		var def := EventCatalogue.by_id(id)
		t.check(def.warns_before_it_exists() and def.starts_by(PursuitSpec.Start.ARRIVES_CHASING),
				"'%s' is warned of before it exists and arrives chasing" % id)
		t.check(is_equal_approx(def.warned_for(), dog.warned_for())
				and is_equal_approx(def.lasts_for(), dog.lasts_for()),
				"'%s' reads the dog's own %.1fs badge and %.1fs chase (%.1f, %.1f)"
				% [id, dog.warned_for(), dog.lasts_for(), def.warned_for(), def.lasts_for()])
		for encounter in M207Lead.gold_encounters():
			var encountered: EventDef = encounter["def"]
			if encountered.id() != id or encounter["heading"] != Vector2.UP:
				continue
			for answer: M207Lead.Answer in M207Lead.ANSWERS:
				var met := M207Lead.gold(encounter, answer, edge)
				t.close_to(met["created_at"], def.warned_for(),
						"'%s': its badge is alone for the dog's half second" % id, 2.0 * STEP)
				t.check(met["chase_at"] <= met["created_at"] + 2.0 * STEP,
						"'%s', answer %d: chasing from the frame he exists" % [id, answer])
				t.check(met["caught"], "'%s' from above, answer %d: caught (%s)"
						% [id, answer, met["ends"]])
	edge.free()

## **A beat rather than a journey.** *(M36, playtest 09: "who is the person killing me? It didn't
## move… if it's the homeless person it needs to walk up and down the sidewalk.")*
##
## The thing that could go quietly wrong is not the turning round, it is what a paced event does at
## the end of its path: everything else in the catalogue that reaches one is **over**, and since M35
## it leaves. A fixture that walks must do neither, or the man shouting outside the home block would
## stroll off down the street eight seconds into every day.
func _test_a_paced_event_walks_a_beat(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("homeless_yeller")
	var path := PackedVector2Array([Vector2.ZERO, Vector2(256.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	var out := 256.0 / def.speed()
	_advance(instance, out - 0.2)
	t.close_to(instance.position.x, 256.0, "it walks to the far end of its beat", 8.0)
	t.check(instance.facing_now().x > 0.0, "facing the way it is going")

	_advance(instance, out)
	t.close_to(instance.position.x, 0.0, "and back again", 8.0)
	t.check(instance.facing_now().x < 0.0, "facing the other way on the way back")
	t.check(not instance.is_gone() and not instance.is_on_its_way_out(),
			"a fixture that moves neither finishes nor leaves at the end of its path")

	# And it is still there four beats later, which is most of a day.
	_advance(instance, out * 8.0)
	t.check(not instance.is_gone(), "and it is still there a day later")
	instance.free()

## **A pursuer can be a place before it is a moment.** *(M36, playtest 09: "a robber should increase
## excitement on sight and getting close to them should be day ending", and "if you get close they
## should start moving towards you".)*
##
## Three states, and the two that are new are the ones worth asserting: while it is **waiting** it
## emits at full strength and cannot end the day, and its telegraph and its chase are both measured
## from the moment it **notices** rather than from the moment the day put it there. A robbery whose
## telegraph ran at dawn, four streets away, would arrive with no notice in it at all.
func _test_a_pursuer_can_wait(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	t.check(def.notice_within() > 0.0, "the robber waits")
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), null, instance_where)

	# Standing there, all day, at full strength.
	instance_where.tell(Vector2(def.notice_within() + 40.0, 0.0))
	_advance(instance, 30.0)
	t.check(instance.is_waiting(), "he is still standing there half a minute later")
	t.check(not instance.is_gone(), "and his duration has not been running")
	t.close_to(instance.position.x, 0.0, "he has not moved", 0.5)
	t.close_to(instance.current_intensity(), def.peak(),
			"he is loud from the moment she can see him, not damped to a telegraph", 0.05)
	t.check(not instance.is_lethal_at(instance_where.at()), "and he cannot end the day yet")
	t.check(instance.source().contribution_at(Vector2(def.heard_within() - 10.0, 0.0)) > 0.0,
			"his field reaches the far end of the alley")

	# She steps inside the trigger: the notice starts *now*.
	instance_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	instance.step(STEP)
	t.check(not instance.is_waiting(), "he notices her")
	t.check(instance.is_telegraphing(), "and the notice starts when he does, not at dawn")
	t.check(not instance.is_lethal_at(instance_where.at()),
			"still not lethal during the notice")

	# Standing there, inside his radius, he walks up to her stand-off and charges once his warning
	# has run (`PursuitSpec.warns_for()`).
	_advance(instance, def.pursuit().warns_for() + 0.1)
	t.check(not instance.is_telegraphing() and not instance.is_waiting(),
			"then, his warning having run with her still inside his radius, he charges")
	instance.free()

## **Every pursuer that waited for her warns by its one radius, on a clock, and the contract is
## walked.** *(Inbox #764 in minty-lemur, the player: a warning happens when she comes close; she can turn around;
## inbox #748: guards lift a hand, only the robber walks; inbox #788 in minty-lemur: "We should do one radius and
## warn inside it for 2s. If the player leaves the radius nothing happens and the warning stops. If
## they stay within the charge starts.")* The dog that waited (any day past `RUN_TAUGHT_DAY`), the
## hunting roadblock's guard and the alley robber notice her inside `EventDef.notice_within()`
## and warn for their row's `PursuitSpec.warns_for()` (`EventInstance.warns_by_radius()`,
## `notice_time()`). Each is walked here from the catalogue (`_waiting_pursuers()`), so a row
## that starts waiting for her is walked without anybody listing it:
##
## - **Walking in** is warned for the whole of `PursuitSpec.warns_for()`, nothing lethal in it,
##   and then charged and caught. The rows that stand do not move while they warn; the robber
##   walks at her no faster than his notice walk and holds at his stand-off.
## - **Standing just inside the radius** is charged once the warning has run, and caught.
## - **Baiting works**: standing just inside, she turns 0.3s after it charges, runs, and gets away,
##   and it gives up. **Running the moment it charges** shakes it off; **walking away once it
##   charges** is caught.
## - **Walking or running away from the warning** is never charged, and once she is out of its
##   radius it waits again; the robber stops where his walk had got him.
##
## The numbers each walk produced are printed rather than asserted. The door guard and the man out
## of a vehicle set off beside her and are walked in `tests/test_checkpoints.gd` and
## `tests/test_pursuer_on_foot.gd`.
func _test_every_waiting_charger_warns_by_radius(t: TestRunner) -> void:
	var rows := _waiting_pursuers(func(_def: EventDef) -> bool: return true)
	var ids := {}
	for def in rows:
		ids[def.id()] = true
	t.check(ids.has("charging_dog") and ids.has("roadblock") and ids.has("alley_robbery"),
			"the waiting dog, the hunting roadblock's guard and the alley robber are walked (%s)"
			% ", ".join(ids.keys()))
	for def in rows:
		var walks := def.pursuit().walk_speed() > 0.0
		var name := "'%s' (%s)" % [def.id(), "walks" if walks else "stands"]
		t.check(def.pursuit().warns_for() >= Tuning.OFFSCREEN_WARNING_MIN,
				"%s warns for %.1fs before it charges" % [name, def.pursuit().warns_for()])
		var walked_in := _standing_rig(t, def, -Tuning.WALK_SPEED)
		t.check(absf(float(walked_in["notice_lasted"]) - def.pursuit().warns_for()) <= 2.0 * STEP
				and walked_in["caught"] and not walked_in["lethal_while_telegraphing"],
				"walking into %s she is warned %.2fs, nothing lethal in it, then charged and caught"
				% [name, walked_in["notice_lasted"]])
		if walks:
			t.check(walked_in["moved_in_notice"] > 0.5 and walked_in["moved_in_notice"]
					<= def.pursuit().walk_speed() * walked_in["notice_lasted"] + 0.5,
					"%s walks at her through its warning, no faster than %.0fpx/s (moved %.1fpx)"
					% [name, def.pursuit().walk_speed(), walked_in["moved_in_notice"]])
		else:
			t.check(walked_in["stood"], "%s holds its ground while she walks in (moved %.1fpx)"
					% [name, walked_in["moved_in_notice"]])
		var stood := _standing_rig(t, def, 0.0, INF, 10.0, 20.0)
		t.check(stood["caught"] and not stood["lethal_while_telegraphing"]
				and absf(float(stood["notice_lasted"]) - def.pursuit().warns_for()) <= 2.0 * STEP,
				"standing just inside %s's radius she is charged after %.2fs of warning, and caught"
				% [name, stood["notice_lasted"]])
		var baited := _standing_rig(t, def, 0.0, 0.3)
		t.check(not baited["caught"] and baited["gave_up"],
				"baiting %s works: standing in its radius, turning 0.3s after its charge and running "
				% name + "gets away (closest %.0fpx, its catch %.0fpx)"
				% [baited["closest"], def.lethal_reach()])
		var answered := _standing_rig(t, def, 0.0, 0.0)
		t.check(not answered["caught"] and answered["gave_up"],
				"running from %s the moment it charges shakes it off (closest %.0fpx)"
				% [name, answered["closest"]])
		var ran_inside := _run_inside_the_warning_rig(t, def)
		t.check(ran_inside["stayed_inside"] and ran_inside["charged"] and ran_inside["caught"]
				and not ran_inside["gave_up_warning"],
				"running inside %s's radius as it warns does not call it off: she stands after, " % name
				+ "and it charges once its warning has run and catches her (ran %.1fs, %.0fpx at most)"
				% [ran_inside["ran_for"], ran_inside["farthest"]])
		var again := _back_inside_rig(t, def)
		t.check(again["waited"] and absf(float(again["second_warning"]) - def.pursuit().warns_for()) <= 2.0 * STEP,
				"leaving %s's radius %.2fs into its warning and coming back, its clock starts " % [name,
				again["first_warning"]] + "again from zero: charged %.2fs after she is back inside"
				% again["second_warning"])
		var charged_then_walked := _standing_rig(t, def, 0.0, 0.0, 10.0, 40.0,
				INF, Tuning.WALK_SPEED)
		t.check(charged_then_walked["caught"] and not charged_then_walked["gave_up"],
				"walking away from %s once it charges still loses (caught %.1fs after the charge)"
				% [name, charged_then_walked["after_the_lunge"]])
		for speed: float in [Tuning.WALK_SPEED, Tuning.RUN_SPEED]:
			var left := _standing_rig(t, def, speed, INF, 10.0, 12.0)
			t.check(left["noticed"] and not left["caught"] and left["at_the_lunge"] == INF
					and left["waited_again_at"] != INF,
					"leaving %s's warning at %.0fpx/s is never charged, and it waits again once she "
					% [name, speed] + "is %.0fpx away" % left["waited_again_at"])
			t.check(left["moved_after_waiting"] < 0.5,
					"and it stays where it stopped (moved %.1fpx after)" % left["moved_after_waiting"])
		print(("[test_events_pursuit] %s, one radius %.0fpx, warns %.1fs: walked in, warned %.2fs "
				+ "and charged at %.0fpx; stood, charged at %.0fpx; baited, closest %.0fpx%s; "
				+ "answered at the charge, closest %.0fpx; walked away from the charge, caught %.2fs "
				+ "after it") % [name, def.notice_within(), def.pursuit().warns_for(), walked_in["notice_lasted"],
				walked_in["at_the_lunge"], stood["at_the_lunge"], baited["closest"],
				", caught" if baited["caught"] else ", got away", answered["closest"],
				charged_then_walked["after_the_lunge"]])

## **A warning she walks out of is not a chase**, so the page's `dog-chased` (`EventBus.pursuit_began`,
## docs/TELEMETRY.md, "The page counts visits") is sent at the charge and never for a warning alone.
func _test_a_warning_is_not_counted_as_a_chase(t: TestRunner) -> void:
	var def := EventCatalogue.by_id("charging_dog").for_day(Tuning.RUN_TAUGHT_DAY + 1)
	var standoff := PursuitSpec.standoff(def.chase_speed(), def.standoff_reach())
	var began: Array[String] = []
	var listen := func(id: String) -> void: began.append(id)
	EventBus.pursuit_began.connect(listen)
	var dog_where := WhereSheIs.nowhere()
	var dog := _instance(t, def, Vector2.ZERO, PackedVector2Array(), null, dog_where)
	dog_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(dog, def.pursuit().warns_for() * 0.5)
	t.check(dog.is_telegraphing() and began.is_empty(), "warning her, it has not begun a chase")
	dog_where.tell(Vector2(def.notice_within() + 10.0, 0.0))
	_advance(dog, 0.5)
	t.check(dog.is_waiting() and began.is_empty(), "and walked out of, it never did")
	dog_where.tell(Vector2(def.notice_within() - 10.0, 0.0))
	_advance(dog, 0.2)
	t.check(dog.is_telegraphing() and began.is_empty(), "back inside, it warns again, still no chase")
	dog_where.tell(Vector2(standoff - 2.0, 0.0))
	_advance(dog, def.pursuit().warns_for())
	t.check(not dog.is_telegraphing() and began == ["charging_dog"],
			"it begins one at its charge, once its warning has run (%s)" % str(began))
	EventBus.pursuit_began.disconnect(listen)
	dog.free()

## **She leaves while he warns and comes back** (review 4 of PR #781): she stands 10px inside his
## radius until three quarters of his warning has run, steps 20px outside it (measured from where he
## notices from, `body_position()`, which a robber's warning walk moves) until he waits again, then
## steps back 10px inside and stands. Reports how long the first warning ran, whether he waited
## again, and how long after she was back inside he charged (`INF` if never).
func _back_inside_rig(t: TestRunner, def: EventDef) -> Dictionary:
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), null, instance_where)
	var result := {"first_warning": 0.0, "waited": false, "second_warning": INF}
	var stand_at := func(off: float) -> void:
		instance_where.tell(instance.body_position() + Vector2(0.0, def.notice_within() + off))
	stand_at.call(-10.0)
	var elapsed := 0.0
	while elapsed < def.pursuit().warns_for() * 0.75 and not instance.is_gone():
		instance.step(STEP)
		if instance.is_telegraphing():
			elapsed += STEP
	result["first_warning"] = elapsed
	stand_at.call(20.0)
	for i in 30:
		instance.step(STEP)
		if instance.is_waiting():
			result["waited"] = true
			break
	stand_at.call(-10.0)
	var back := 0.0
	while back < def.pursuit().warns_for() * 3.0 and not instance.is_gone():
		instance.step(STEP)
		back += STEP
		if not instance.is_waiting() and not instance.is_telegraphing():
			result["second_warning"] = back
			break
	instance.free()
	return result

## **She runs inside his radius while he warns, then stands** (review 4 of PR #781): she stands
## half his radius out and to one side, he notices her, she runs across in front of him for half a
## second (her real acceleration, so `PURSUIT_SHAKEN_OFF` is passed with room), staying inside his
## radius, then stops and stands. Reports whether she stayed inside, whether he gave up while he
## warned, whether he charged and whether he caught her.
func _run_inside_the_warning_rig(t: TestRunner, def: EventDef) -> Dictionary:
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), null, instance_where)
	var her := Vector2(-def.notice_within() * 0.3, def.notice_within() * 0.5)
	var speed := 0.0
	var ran_for := 0.0
	var noticed_for := -1.0
	var result := {"stayed_inside": true, "gave_up_warning": false, "charged": false,
			"caught": false, "ran_for": 0.0, "farthest": 0.0}
	var elapsed := 0.0
	while elapsed < 10.0 and not instance.is_gone() and not result["caught"]:
		if noticed_for >= 0.0 and noticed_for < 0.5:
			speed = move_toward(speed, Tuning.RUN_SPEED, Tuning.ACCELERATION * STEP)
		else:
			speed = move_toward(speed, 0.0, Tuning.ACCELERATION * STEP)
		her.x += speed * STEP
		instance_where.tell(her, Vector2.INF, Rect2(), speed > Tuning.WALK_SPEED)
		if instance_where.is_running():
			ran_for += STEP
		var was_telegraphing := instance.is_telegraphing()
		instance.step(STEP)
		elapsed += STEP
		if instance.is_telegraphing() or noticed_for >= 0.0:
			noticed_for = maxf(noticed_for, 0.0) + STEP
		var off := instance.body_position().distance_to(her)
		result["farthest"] = maxf(float(result["farthest"]), off)
		if noticed_for >= 0.0 and off > def.notice_within():
			result["stayed_inside"] = false
		if was_telegraphing and (instance.has_given_up() or instance.is_on_its_way_out()):
			result["gave_up_warning"] = true
		if was_telegraphing and instance.is_chasing():
			result["charged"] = true
		if instance.is_lethal_at(her):
			result["caught"] = true
	result["ran_for"] = ran_for
	instance.free()
	return result

## Every pursuer that waits for her, in each state it is met in: every catalogue row on every day
## of a run (`EventDef.for_day()`, which is where the dog's trigger switches on past
## `Tuning.RUN_TAUGHT_DAY`) at every heat (`EventCatalogue.heated()`, which is where the roadblock's
## guard starts to pursue), kept where it pursues and waits (`EventDef.waits_for_her()`) and
## `keep` says yes, once per distinct set of the numbers the walk reads. One that sets off
## beside her or arrives chasing has no trigger to be sited inside.
func _waiting_pursuers(keep: Callable) -> Array[EventDef]:
	var rows: Array[EventDef] = []
	var seen := {}
	for row in CatalogueRows.every():
		for level in range(0, Tuning.RESISTANCE_GOAL + 1):
			for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
				var def := EventCatalogue.heated(row, level).for_day(day)
				if not def.pursues() or def.notice_within() <= 0.0 or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) \
						or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING) or not keep.call(def):
					continue
				var key := "%s|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f|%s" % [def.id(), def.notice_within(),
						def.telegraphs_for(), def.chase_speed(), def.lasts_for(), def.lethal_reach(),
						def.pursuit().walk_speed(), def.pursuit().stands_for_its_notice()]
				if seen.has(key):
					continue
				seen[key] = true
				rows.append(def)
	return rows

## Walks her along +y from where `def` stands, starting `from` px from it (or `inside` px inside its
## trigger), at `player_speed` (positive is away, negative into it, zero standing), for at most
## `seconds`; when `reaction` is finite she turns, `reaction` seconds after it charges, toward
## `then_speed` (a run unless given), accelerating as she really does. With `stop_at` she stops
## walking in once she is that far from the charger itself — from a roadblock guard's post, which is
## nearer her than the band she noticed him from. In the tree, since a roadblock's guard steps out to
## his post beside its band on the frame he notices her.
##
## Reports whether it noticed her, where and how long into its warning it charged (`INF` if never),
## how far it moved while it warned, whether it caught her and whether anything was lethal while it
## warned, and, for a warning that ended with her out of its radius, how far away she was then and
## how far it moved after.
func _standing_rig(t: TestRunner, def: EventDef, player_speed: float, reaction := INF, inside := 10.0,
		seconds := 40.0, from := INF, then_speed := Tuning.RUN_SPEED, stop_at := -1.0) -> Dictionary:
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), null, instance_where)
	var start := from if from != INF else def.notice_within() - inside
	var her := Vector2(0.0, start)
	var speed := player_speed
	var elapsed := 0.0
	var since_the_lunge := INF
	var held_at := Vector2.INF
	var waited_at := Vector2.INF
	var result := {"caught": false, "gave_up": false, "lethal_while_telegraphing": false,
			"at_the_lunge": INF, "ended_at": INF, "moved_in_notice": 0.0, "stood": false,
			"closest": INF, "noticed_at": INF, "notice_lasted": INF, "noticed": false,
			"waited_again_at": INF, "moved_after_waiting": 0.0, "after_the_lunge": INF,
			"from": start if stop_at < 0.0 else stop_at}
	var noticed := false
	while elapsed < seconds and not instance.is_gone() and not instance.is_on_its_way_out() \
			and not result["caught"]:
		if since_the_lunge != INF and since_the_lunge >= reaction:
			speed = move_toward(speed, then_speed, Tuning.ACCELERATION * STEP)
		if stop_at >= 0.0 and speed < 0.0 \
				and instance.global_position.distance_to(her) + speed * STEP <= stop_at:
			speed = 0.0
		her.y += speed * STEP
		instance_where.tell(her, Vector2.INF, Rect2(), speed > Tuning.WALK_SPEED)
		instance.step(STEP)
		elapsed += STEP
		if since_the_lunge != INF:
			since_the_lunge += STEP
		if instance.is_telegraphing():
			if not noticed:
				result["noticed_at"] = elapsed
			noticed = true
			if held_at == Vector2.INF:
				held_at = instance.global_position
			result["moved_in_notice"] = maxf(float(result["moved_in_notice"]),
					instance.global_position.distance_to(held_at))
		elif noticed and instance.is_waiting() and since_the_lunge == INF:
			if waited_at == Vector2.INF:
				waited_at = instance.global_position
				result["waited_again_at"] = instance.body_position().distance_to(her)
			result["moved_after_waiting"] = maxf(float(result["moved_after_waiting"]),
					instance.global_position.distance_to(waited_at))
		elif noticed and since_the_lunge == INF:
			since_the_lunge = 0.0
			result["at_the_lunge"] = instance.global_position.distance_to(her)
			result["notice_lasted"] = elapsed - float(result["noticed_at"])
		result["closest"] = minf(float(result["closest"]), instance.global_position.distance_to(her))
		if instance.is_lethal_at(her):
			result["caught"] = true
			result["lethal_while_telegraphing"] = instance.is_telegraphing()
			if since_the_lunge != INF:
				result["after_the_lunge"] = since_the_lunge
	result["gave_up"] = instance.has_given_up()
	result["ended_at"] = elapsed
	result["noticed"] = noticed
	result["stood"] = noticed and float(result["moved_in_notice"]) < 0.5
	instance.free()
	return result

## **The robber stops at walls.** A pursuing `EventInstance` moves by setting its own position, and
## nothing in the event system has ever collided with the city — harmless while every mobile row
## travelled a route the scheduler had already checked, and not harmless the moment something
## steers freely at the player.
##
## A building corner of the hand-built map, chased round: she walks from its north face to its east
## face, and a dog aimed straight at wherever she currently is would cut across the building itself to
## follow her —
## exactly the shape of the bug. The pursuit's step through the navigator (`EventPursuit`,
## `Navigator.step()`) is the fix, and this is what it has to hold true of every frame regardless
## of the geometry, which is why the check runs the whole walk rather than sampling the end of it.
func _test_a_pursuer_stops_at_walls(t: TestRunner) -> void:
	var map := _map()
	var corner := _a_building_corner(map)
	t.check(not corner.is_empty(), "the hand-built map has a building corner to chase round")
	if corner.is_empty():
		return
	var north: Vector2i = corner["north"]
	var east: Vector2i = corner["east"]

	var def := EventCatalogue.by_id("charging_dog")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, map.tile_to_world(north) + Vector2(-96.0, 0.0), PackedVector2Array(),
			Vector2.RIGHT,
			EventSurroundings.new().on(map) \
				.moving_by(Navigator.new(map)) \
				.hearing(instance_where))
	t.add_child(instance)
	instance.set_process(false)

	# Clear the telegraph with her held far off, so what follows is about the wall and not about
	# the stand-off.
	instance_where.tell(map.tile_to_world(north) + Vector2(-4000.0, 0.0))
	_advance(instance, def.telegraphs_for() + 0.1)
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
		instance_where.tell(her)
		instance.step(STEP)
		elapsed += STEP
		var tile := map.world_to_tile(instance.global_position)
		checked += 1
		t.check(map.is_walkable(tile),
				"the pursuer never stands on the building at %s (t=%.2fs)" % [tile, elapsed])
	t.check(checked > 0, "the walk round the corner actually ran")
	instance.free()

## An alley mouth on the hand-built map, as the corner the robber reaches round: a building tile with
## alley ground on one side (`d1`, where he stands) and walkable ground on a perpendicular side
## (`d2`, the sidewalk she walks), with the tile between the two (the mouth, `d1 + d2`) walkable too,
## so the corner is one he can come round. `corner` is the building's own vertex shared by all four
## tiles; from it the building lies toward `-d1` and `-d2`. `{}` would mean the map's
## alley does not open onto a street rather than that the search picked badly.
func _an_alley_mouth(map: CityMap) -> Dictionary:
	var sides: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	for tile in map.tiles_of_type(GameEnums.TileType.BUILDING):
		for d1 in sides:
			if map.tile_at(tile + d1) != GameEnums.TileType.ALLEY:
				continue
			for d2: Vector2i in [Vector2i(d1.y, d1.x), Vector2i(-d1.y, -d1.x)]:
				if map.is_walkable(tile + d2) and map.is_walkable(tile + d1 + d2):
					return {"building": tile, "d1": Vector2(d1), "d2": Vector2(d2),
							"corner": map.tile_to_world(tile) + Vector2(d1 + d2) * 16.0}
	return {}

## The alley robber on `map`, past his notice and chasing, so what follows is about the line between
## the two of them and not about the notice. He is set up on `map` with its navigator as
## `EventInstance.setup()` is handed them, at a walkable tile with a clear straight run east to her,
## since the notice asks for a clear line; each check moves him from there. He hears where she is
## from `where`, which a check goes on telling.
func _a_chasing_robber(t: TestRunner, map: CityMap, where: WhereSheIs) -> EventInstance:
	var def := EventCatalogue.by_id("alley_robbery")
	var run := def.notice_within() - 10.0
	var origin := Vector2.INF
	for tile_y in range(map.size_in_tiles().y / 2, map.size_in_tiles().y - 2):
		for tile_x in range(2, map.size_in_tiles().x - 2):
			var at := map.tile_to_world(Vector2i(tile_x, tile_y))
			if map.is_walkable(Vector2i(tile_x, tile_y)) \
					and _sampled_line_is_walkable(map, at, at + Vector2(run, 0.0), 0.1):
				origin = at
				break
		if origin != Vector2.INF:
			break
	t.check(origin != Vector2.INF, "the map has a clear %.0fpx run to start the robber on" % run)
	var instance := _instance(t, def, origin, PackedVector2Array(), map, where)
	where.tell(origin + Vector2(run, 0.0))
	instance.step(STEP)
	_advance(instance, def.pursuit().warns_for() + 0.1)
	return instance

## **He catches her only by touching her.** *(freckled-goose, #544: "Even then the distance would
## not physically connect so counting it as caught would be unfair. Only if the Robert touches the
## player should it end instantly".)* The catch the player met: him in the alley hugging the
## building, her on the sidewalk round its corner, 22px apart — inside his 26px catch — with the
## building's corner between them. She stands 14px off the building's face (`PLAYER_BODY_RADIUS`,
## where the building holds her) and is not inside the mouth.
func _test_the_robber_does_not_catch_her_through_a_wall(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	t.check(not mouth.is_empty(), "the hand-built map has an alley opening onto a street")
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance := _a_chasing_robber(t, map, WhereSheIs.nowhere())
	t.check(not instance.is_telegraphing() and not instance.is_waiting(), "he is chasing")
	instance.position = corner + d1 * 1.0 - d2 * 7.0
	var behind_the_wall := corner - d1 * 4.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	var reach := instance.row().lethal_reach()
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
func _a_waiting_robber(t: TestRunner, map: CityMap, mouth: Dictionary, back: float,
		where: WhereSheIs = null) -> EventInstance:
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var at := corner + d1 * 16.0 - d2 * back
	return _instance(t, EventCatalogue.by_id("alley_robbery"), at, PackedVector2Array(), map,
			where)

## **He notices her only along a clear line.** *(leafy-puffin, inbox #648, asked whether noticing
## her should need a clear line: "yes noticing needs a clear line".)* He waits in the alley 40px
## back from the mouth; she stands on the sidewalk round the building's corner, well inside his
## `EventDef.notice_within()` of 180px in a straight line but with the building between them,
## and he goes on waiting and is drawn looking the way he was sited, not tracking her round the
## corner. She steps in front of the mouth, nearer still, the line between them clear, and on
## that frame he notices her and is drawn facing her. What is checked is what his look is handed:
## the line to her, which is nothing while the building hides her, and his facing once he has
## noticed her; that his look turns him by the line is `tests/test_event_views.gd`'s.
func _test_the_robber_does_not_notice_her_through_a_wall(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance_where := WhereSheIs.nowhere()
	var instance := _a_waiting_robber(t, map, mouth, 40.0, instance_where)
	var looking := instance.facing_now().normalized()
	var round_the_corner := corner - d1 * 60.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(instance.global_position.distance_to(round_the_corner) < instance.row().notice_within(),
			"round the corner she is inside his notice in a straight line (%.1fpx)"
			% instance.global_position.distance_to(round_the_corner))
	t.check(not _sampled_line_is_walkable(map, instance.global_position, round_the_corner),
			"with the building between them")
	instance_where.tell(round_the_corner)
	_advance(instance, 1.0)
	t.check(instance.is_waiting(), "he does not notice her through the building")
	t.check(instance.sight_line_to_her() == Vector2.ZERO
			and instance.facing_now().normalized().is_equal_approx(looking),
			"and is not drawn turned toward her: his look is handed no line to her")
	var in_the_mouth := corner + d1 * 16.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(_sampled_line_is_walkable(map, instance.global_position, in_the_mouth),
			"in front of the mouth nothing stands between them")
	instance_where.tell(in_the_mouth)
	instance.step(STEP)
	t.check(not instance.is_waiting(), "and there he notices her")
	t.check(instance.facing_now().normalized().is_equal_approx(
			(in_the_mouth - instance.global_position).normalized()), "and is drawn facing her")
	instance.free()

## **His charge needs a clear line too.** *(mossy-beaver, inbox #650: "how would that even work? how
## can it pursue without noticing? obviously it needs a clear line".)* He notices her down the alley,
## the line clear; she steps round the building's corner, inside his radius with the building
## between them, and stays there past his whole warning: he goes on warning and does not charge
## through the building. She steps in front of the mouth, the line clear and she still inside his
## radius, and he charges.
func _test_the_robber_does_not_lunge_through_a_wall(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var instance_where := WhereSheIs.nowhere()
	var instance := _a_waiting_robber(t, map, mouth, 40.0, instance_where)
	var def := instance.row()
	var start := instance.global_position
	var down_the_alley := start + d2 * (def.notice_within() - 20.0)
	t.check(_sampled_line_is_walkable(map, start, down_the_alley),
			"down the alley's line, inside his radius, nothing stands between them")
	instance_where.tell(down_the_alley)
	instance.step(STEP)
	t.check(not instance.is_waiting() and instance.is_telegraphing(), "he notices her there")
	var round_the_corner := corner - d1 * 60.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	t.check(not _sampled_line_is_walkable(map, instance.global_position, round_the_corner),
			"round the corner the building stands between them")
	instance_where.tell(round_the_corner)
	_advance(instance, def.pursuit().warns_for() + 0.5)
	t.check(instance.is_telegraphing() and instance.global_position.distance_to(round_the_corner)
			<= def.notice_within(),
			"past his whole warning, inside his radius, he does not charge through the building")
	var in_the_mouth := corner + d1 * 16.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	instance_where.tell(in_the_mouth)
	_advance(instance, 0.1)
	t.check(not instance.is_telegraphing() and not instance.is_waiting(),
			"in front of the mouth, the line clear, he charges")
	instance.free()

## **A late notice is answered by the warning, not by a stand-off.** The robber waits 20, 40, 60 and
## 90px back in the alley; she steps in front of the mouth, the line clear, so he notices her already
## near him. **Running off the moment he warns** (0.3s later), on along the sidewalk, she is never
## charged: she is out of his radius before his warning has run, and he waits again (running counts
## toward shaking him off only once he has charged); **standing there**, he charges once his warning
## has run and catches her.
func _test_a_late_notice_is_answered_by_his_warning(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var def := EventCatalogue.by_id("alley_robbery")
	for back: float in [20.0, 40.0, 60.0, 90.0]:
		for answer: String in ["run", "stand"]:
			var instance_where := WhereSheIs.nowhere()
			var instance := _a_waiting_robber(t, map, mouth, back, instance_where)
			var her := corner + d1 * 16.0 + d2 * Tuning.PLAYER_BODY_RADIUS
			instance_where.tell(her, Vector2.INF, Rect2(), instance_where.is_running())
			instance.step(STEP)
			t.check(not instance.is_waiting(), "%dpx in: he notices her in the mouth" % int(back))
			var speed := 0.0
			var elapsed := 0.0
			var charged := false
			var caught := false
			while elapsed < 8.0 and not caught and not instance.is_gone():
				if answer == "run" and elapsed >= 0.3:
					speed = move_toward(speed, Tuning.RUN_SPEED, Tuning.ACCELERATION * STEP)
				her += Navigator.new(map).step(her, d1 * speed * STEP, Mover.lattice())
				instance_where.tell(her, Vector2.INF, Rect2(), speed > Tuning.WALK_SPEED)
				instance.step(STEP)
				elapsed += STEP
				charged = charged or instance.is_chasing()
				caught = instance.is_lethal_at(her)
				if answer == "run" and instance.is_waiting():
					break
			if answer == "run":
				t.check(not charged and not caught and instance.is_waiting() and not instance.has_given_up(),
						"%dpx in: running off as he warns, she is out of his radius first: never "
						% int(back) + "charged, and he waits again rather than giving up")
			else:
				t.check(charged and caught,
						"%dpx in: standing in the mouth, he charges once his warning has run" % int(back))
			instance.free()

## **A walk past an alley mouth is warned before it is charged, and never through the corner.**
## The robber waits in the alley 20, 40, 60 and 90px back from the mouth; she walks along the
## sidewalk toward it at `WALK_SPEED`, 14px off the building's face, and on past. The building hides
## her until she is nearly at the mouth, so he notices her only once the line between them is clear;
## where he charges, it is no sooner than his whole warning (`PursuitSpec.warns_for()`) after he
## noticed her, she still inside his radius; where she walks out of his radius first, he never
## charges and waits again; the print says how many depths charge. And he never catches her
## through the corner: every frame that catches has a clear sampled line.
func _test_the_robber_keeps_his_stand_off_at_an_alley_mouth(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d1: Vector2 = mouth["d1"]
	var d2: Vector2 = mouth["d2"]
	var def := EventCatalogue.by_id("alley_robbery")
	var charged := 0
	for back: float in [20.0, 40.0, 60.0, 90.0]:
		var instance_where := WhereSheIs.nowhere()
		var instance := _instance(t, def, corner + d1 * 16.0 - d2 * back, PackedVector2Array(),
				map, instance_where)
		var her := corner - d1 * 300.0 + d2 * Tuning.PLAYER_BODY_RADIUS
		var elapsed := 0.0
		var noticed_at := INF
		var lunged_at := INF
		var lunge_range := INF
		var caught_at := INF
		var through_a_wall := 0
		var noticed_through_a_wall := false
		while elapsed < 15.0 and caught_at == INF and not instance.is_gone():
			her += d1 * Tuning.WALK_SPEED * STEP
			instance_where.tell(her)
			var was_waiting := instance.is_waiting()
			instance.step(STEP)
			elapsed += STEP
			if was_waiting and not instance.is_waiting():
				noticed_at = elapsed
				noticed_through_a_wall = not _sampled_line_is_walkable(map,
						instance.global_position, her)
			if lunged_at == INF and not instance.is_waiting() and not instance.is_telegraphing():
				lunged_at = elapsed
				lunge_range = instance.global_position.distance_to(her)
			if instance.is_lethal_at(her):
				caught_at = elapsed
				if not _sampled_line_is_walkable(map, instance.global_position, her):
					through_a_wall += 1
		print("[test_events_pursuit] robber %dpx into the alley, walked past: %s" % [int(back),
				("charged at %.0fpx, caught %.2fs later" % [lunge_range, caught_at - lunged_at])
				if lunged_at != INF else "never charged, waiting again: %s" % instance.is_waiting()])
		if lunged_at == INF:
			t.check(caught_at == INF and instance.is_waiting(),
					"%dpx in: never charged, he never catches her and waits again" % int(back))
		else:
			charged += 1
			t.check(lunged_at - noticed_at >= def.pursuit().warns_for() - 2.0 * STEP
					and lunge_range <= def.notice_within(),
					"%dpx in: he charges %.2fs after he noticed her, his whole warning, she %.0fpx off"
					% [int(back), lunged_at - noticed_at, lunge_range])
		t.check(not noticed_through_a_wall,
				"%dpx in: he notices her only once nothing stands between them" % int(back))
		t.check(through_a_wall == 0, "%dpx in: and he never catches her through the corner" % int(back))
		instance.free()
	print("[test_events_pursuit] a walk past the alley mouth is charged at %d of 4 depths" % charged)

## **The doubled red caret projects the catch, not the field's core.** `will_be_lethal()` asks
## whether a pursuer's course puts her inside the radius that ends the day; for the hunting
## roadblock that is his 28px reach (`lethal_reach()`), not the band's 86px core, which every other
## row's catch already is. His course passes 20px from her: red. 50px, beyond his reach and inside
## the core: not red. Both points sit on a quarter-second step of the projection, so neither answer
## depends on where its samples fall.
func _test_the_red_caret_is_measured_from_the_catch(t: TestRunner) -> void:
	var hot := EventCatalogue.heated(EventCatalogue.by_id("roadblock"), EventDef.HEAT_HUNTS_LEVEL)
	t.check(hot.pursues() and hot.ends_the_day() and hot.lethal_reach() < hot.core_within(),
			"the hunting roadblock catches inside its field's core (%.0fpx < %.0fpx)"
			% [hot.lethal_reach(), hot.core_within()])
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, hot, Vector2.ZERO, PackedVector2Array(), null, instance_where)
	instance_where.tell(Vector2(hot.notice_within() - 10.0, 0.0))
	instance.step(STEP)
	t.check(not instance.is_waiting(), "the guard notices her")
	var heading := instance.facing_now()
	var ahead := instance.global_position + heading * hot.chase_speed() * 0.5
	var across := heading.orthogonal()
	t.check(instance.source().will_be_lethal(ahead + across * 20.0), "his course 20px from her reads red")
	t.check(not instance.source().will_be_lethal(ahead + across * 50.0),
			"his course 50px from her, beyond his reach, does not")
	instance.free()

## **To catch her round a corner he has to come round it.** She stands on the sidewalk just round
## the building from him, inside his catch in a straight line, and he chases: he slides along the
## building's face (his step through the navigator, `Navigator.step()`) and catches her only once
## the line between them clears the building's corner, never through it. Every frame of the chase is
## checked against a line sampled a quarter pixel at a time, a second answer to the question the
## map's own line (`WorldMap.clear_line()`) asks, so a frame that catches through the corner fails it
## wherever it falls.
func _test_the_robber_catches_her_by_coming_round_the_corner(t: TestRunner) -> void:
	var map := _map()
	var mouth := _an_alley_mouth(map)
	if mouth.is_empty():
		return
	var corner: Vector2 = mouth["corner"]
	var d2: Vector2 = mouth["d2"]
	var d1: Vector2 = mouth["d1"]
	var instance_where := WhereSheIs.nowhere()
	var instance := _a_chasing_robber(t, map, instance_where)
	var start := corner + d1 * 1.0 - d2 * 7.0
	instance.position = start
	var her := corner - d1 * 4.0 + d2 * Tuning.PLAYER_BODY_RADIUS
	instance_where.tell(her)
	var elapsed := 0.0
	var caught := false
	var through_a_wall := 0
	while elapsed < 2.0 and not caught and not instance.is_gone():
		if instance.is_lethal_at(her):
			caught = true
			if not _sampled_line_is_walkable(map, instance.global_position, her):
				through_a_wall += 1
		instance.step(STEP)
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
