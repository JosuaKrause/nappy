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
	_test_a_retried_day_is_the_same_day(t)
	_test_the_run_is_always_taught(t)
	_test_a_paced_event_walks_a_beat(t)
	_test_a_pursuer_can_wait(t)
	_test_a_pursuer_stops_at_walls(t)


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

## Where the encounter actually starts, in px: where the director sites something that comes at her,
## or just inside the trigger for something that has been standing there.
##
## The director's own siting depends on the heading she happens to be walking
## (`Tuning.offscreen_lead(heading, closing_speed, def.offscreen_notice)`), so this asks for the
## worst case over every heading rather than one of them — `Tuning.min_offscreen_lead()`, the
## vertical axis plus the row's own notice of closing at its `pursue_speed` against `WALK_SPEED`,
## which is the least ground the contract can ever rely on. A rig checked against a more generous
## heading would pass on an encounter the game can still produce on a worse one.
func _sited_at(def: EventDef) -> float:
	if def.pursues_within > 0.0:
		return def.pursues_within - 10.0
	return Tuning.min_offscreen_lead(def.pursue_speed + Tuning.WALK_SPEED, def.offscreen_notice)

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
		if not def.pursues or def.sets_off_beside_her:
			continue
		pursuers += 1
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
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
		if not def.pursues or def.sets_off_beside_her:
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
## the director decides where it starts. If the stand-off ever grows past the least the director
## could ever site it at — `Tuning.min_offscreen_lead()`, the worst case over every heading she
## might be walking — a pursuer *backs away* through its own telegraph instead of closing, which is
## a dog that visibly reverses down the street in front of her.
##
## The relationship is asserted rather than left as a coincidence: a change to the stand-off, to
## `VIEW_HALF_EXTENT` or to `OFFSCREEN_NOTICE` has moved these numbers before without anybody
## checking they still agree.
func _test_a_pursuer_is_sited_where_it_can_be_seen(t) -> void:
	for def in EventCatalogue.all():
		# Sited beside her by construction, which is what its own stand-off rule answers.
		if not def.pursues or def.sets_off_beside_her:
			continue
		var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
		var floor_lead := Tuning.min_offscreen_lead(def.pursue_speed + Tuning.WALK_SPEED,
				def.offscreen_notice)
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
## exists (`PendingWarning`), and it is created with that telegraph spent; this walks the warning and
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
		while elapsed < def.telegraph_time + 5.0:
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
		instance.resume(def.telegraph_time, 0.0)
		arrived.append(instance)
		return true
	var warning := PendingWarning.new(def, where, arrive)
	warning.follow(her)
	return warning

## How far over the contract's floor the cyclist's warning may run, walking into him, and still be
## *shortly* before he arrives. Half a second is about three strides — enough for frame timing, and
## well short of the extra second she spent watching him close from off screen when "most of the
## time you're already gone when anything happens".
const CYCLIST_WARNING_OVER_THE_FLOOR := 0.5

## **The cyclist is warned by himself first, and arrives where the warning pointed, shortly after.**
## *(2026-09-25: "I feel the same with the biker. it gets warned too early so most of the time you're
## already gone when anything happens." · PLAYTEST-145: "the warning appears by itself with a
## reasonable position and when the time is right the object is spawned in at that location just
## offscreen" · "the biker needs to stay on the sidewalk".)*
##
## On the real map, with the warning held the way `EventManager` holds one (`warn_first()`,
## `_run_the_warnings()`) and read by a real `DangerEdge`, while she walks up her sidewalk and steps
## out onto the carriageway and back:
##
## - **the badge is up with nothing in the world**;
## - **the place stays on a sidewalk and just off screen the whole time**, and never nearer her than
##   the distance ahead it started at, so walking on does not bring him sooner;
## - **he is created no sooner than his `telegraph_time`, where the badge pointed, off screen, with
##   his telegraph spent**.
##
## Then, walked by `M207Lead.measure()` (`tests/probes/m207_warning_lead.gd`, the probe that prints
## every warned row's lead) on open ground on both axes: **from the badge to his reach, walking into
## him, is at least the contract's floor**, exactly his warning and then his approach from just off
## screen, and standing still he still reaches her no sooner than the floor. **And on the narrower
## axis that is not much more than the floor.**
func _test_the_cyclist_is_warned_shortly_before_he_arrives(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var map := _map()
	# Her own kerb-side sidewalk beside the arterial, walking north from a point where the place just
	# off screen ahead of her is on a sidewalk too rather than in the carriageway of a cross street.
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
	var created: Array[EventInstance] = []
	var where := func(at: Vector2) -> Vector2:
		return PendingWarning.down_her_line(map, def, at, Vector2.UP)
	var arrive := func(place: Vector2, at: Vector2) -> bool:
		var path := PendingWarning.route_down_her_line(map, place, at, Vector2.UP)
		var instance := EventInstance.new()
		instance.setup(def, path[0], path)
		instance.resume(def.telegraph_time, 0.0)
		created.append(instance)
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

	var ahead := Tuning.offscreen_lead(Vector2.UP, def.speed + Tuning.WALK_SPEED,
			def.offscreen_notice)
	var ground := [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	var elapsed := 0.0
	var looked := 0
	var off_its_ground := 0
	var on_screen := 0
	var moved := 0
	var nearer := 0
	var was := warning.place
	var pointed := warning.place
	var came_at := INF
	while elapsed < def.telegraph_time + 3.0:
		# North up the sidewalk, then a stride out onto the carriageway and back.
		var step := Vector2.UP
		if elapsed > 0.6 and elapsed <= 1.2:
			step = Vector2.RIGHT
		elif elapsed > 1.2 and elapsed <= 1.8:
			step = Vector2.LEFT
		her += step * Tuning.WALK_SPEED * STEP
		pointed = warning.place
		manager._run_the_warnings(STEP, her)
		elapsed += STEP
		if not created.is_empty():
			came_at = elapsed
			break
		looked += 1
		if not ground.has(map.tile_at(map.world_to_tile(warning.place))):
			off_its_ground += 1
		if not PendingWarning.is_off_screen(warning.place - her, warning.closing_speed(),
				def.offscreen_notice):
			on_screen += 1
		if warning.place != was:
			moved += 1
		if (warning.place - her).dot(Vector2.UP) < ahead - 0.5:
			nearer += 1
		was = warning.place
	t.check(looked > 0 and moved > 0,
			"it was watched (%d frames) and it moved with her (%d)" % [looked, moved])
	t.check(off_its_ground == 0,
			"and its place stayed on a sidewalk the whole time (%d frames off it)" % off_its_ground)
	t.check(on_screen == 0,
			"and just off screen the whole time (%d frames on it)" % on_screen)
	t.check(nearer == 0,
			"and never nearer her than the %.0fpx ahead it started at (%d frames nearer)"
			% [ahead, nearer])
	t.check(created.size() == 1 and came_at >= def.telegraph_time,
			"he is created once his %.2fs warning is over (%.2fs)" % [def.telegraph_time, came_at])
	if created.size() == 1:
		var bike := created[0]
		t.close_to(bike.global_position.distance_to(warning.place), 0.0,
				"where the badge pointed", 0.5)
		t.check(PendingWarning.is_off_screen(bike.global_position - her,
				def.speed + Tuning.WALK_SPEED, def.offscreen_notice),
				"off screen by his own notice")
		t.check(not bike.is_telegraphing(), "with his telegraph already spent, so he can end the day")
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
		# What the walk measures is the contract's own figure on this axis: his warning, then his
		# approach from just off screen to his reach. The horizontal axis adds only the wider view.
		var heading: Vector2 = encounter["heading"]
		var closing := row.speed + Tuning.WALK_SPEED
		var predicted := row.telegraph_time + (Tuning.offscreen_lead(heading, closing,
				row.offscreen_notice) - row.lethal_reach()) / closing
		t.close_to(toward["lead"], predicted,
				"cyclist (%s): which is his warning and then his approach from just off screen"
				% encounter["how"], 3.0 * STEP)
		var stood := M207Lead.measure(encounter, M207Lead.Answer.STAND, probe_edge)
		t.check(stood["lead"] < INF and stood["lead"] >= floor_s,
				"cyclist (%s): standing on his line she is still reached, %.2fs after the warning"
				% [encounter["how"], stood["lead"]])
		probe_edge.free()
	t.check(walked >= 2, "the cyclist was walked on both axes (%d)" % walked)
	# And the tightest of them — the contract's own figure, on the narrower axis of the view — is
	# shortly before he arrives rather than long before it.
	t.check(def.warning_time() <= def.minimum_telegraph() + CYCLIST_WARNING_OVER_THE_FLOOR,
			"his warning, %.2fs from the badge to his reach, is at most %.1fs over the %.2fs floor"
			% [def.warning_time(), CYCLIST_WARNING_OVER_THE_FLOOR, def.minimum_telegraph()])

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
