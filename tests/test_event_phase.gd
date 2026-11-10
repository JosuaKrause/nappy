@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The event's stored phase and the one warning clock: `EventInstance.Phase` changed only by
## `transition()`, every row's telegraph and every waiting row's notice moving through it, a notice
## carried across a stream-out exactly as far run (held time included), and `Warning` itself — the
## clock an event's notice, a door crossing and a badge up alone all run on.

const STEP := 0.1

func run(t) -> void:
	_test_a_warning_starts_holds_and_runs_out(t)
	_test_a_warning_ticks_into_its_action_or_is_called_off(t)
	_test_a_row_with_no_wait_is_in_its_telegraph_then_active(t)
	_test_a_waiting_row_notices_warns_and_waits_again(t)
	_test_a_departure_and_a_finish_are_phases(t)
	_test_a_dog_shaken_off_mid_telegraph_is_telegraphing_until_its_clock_runs(t)
	_test_a_held_notice_comes_back_as_far_run(t)
	_test_a_hunting_copy_does_not_share_its_rows_pursuit(t)
	_test_a_badge_up_alone_points_and_counts_down(t)
	_test_a_live_event_answers_for_its_row(t)

# ------------------------------------------------------------------- the clock ---

func _test_a_warning_starts_holds_and_runs_out(t) -> void:
	var warning := Warning.new()
	t.check(not warning.is_running() and warning.elapsed(5.0) == 0.0,
			"a warning not started is not running and has run for nothing")
	warning.start(1.0, 2.0)
	t.check(warning.is_running(), "started, it runs")
	t.close_to(warning.elapsed(2.5), 1.5, "it has run for the clock since its start")
	t.check(not warning.has_run(2.5), "and has not run its two seconds by then")
	warning.hold(0.5)
	t.close_to(warning.elapsed(3.0), 1.5, "a held half second does not count")
	t.check(not warning.has_run(3.0), "so at 3.0 it still has half a second to run")
	t.close_to(warning.left(3.0), 0.5, "which is what is left")
	t.check(warning.has_run(3.5), "and at 3.5 it has run")
	t.close_to(warning.started_at(), 1.5, "its start, held time counted back in, is 1.5")
	warning.stop()
	t.check(not warning.is_running() and warning.started_at() == INF, "stopped, it is not running")

func _test_a_warning_ticks_into_its_action_or_is_called_off(t) -> void:
	var ran := [0]
	var off := [false]
	var warning := Warning.new()
	warning.cancel_if = func() -> bool: return off[0]
	warning.on_expired = func() -> void: ran[0] += 1
	warning.start(0.0, 1.0)
	t.check(warning.tick(0.5) == Warning.Outcome.RUNNING, "half way, it is running")
	t.check(warning.tick(1.0) == Warning.Outcome.RAN_OUT and ran[0] == 1,
			"at its length it runs out into its action, once")
	t.check(warning.tick(1.5) == Warning.Outcome.NOT_RUNNING and ran[0] == 1,
			"and is not running after it")
	warning.start(2.0, 1.0)
	off[0] = true
	t.check(warning.tick(2.2) == Warning.Outcome.CALLED_OFF and ran[0] == 1,
			"called off, it never reaches its action")

# ------------------------------------------------------------------- the phase ---

func _test_a_row_with_no_wait_is_in_its_telegraph_then_active(t) -> void:
	var def := EventCatalogue.by_id("cyclist")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.phase == EventInstance.Phase.WARNING and instance.is_telegraphing(),
			"a row with no wait starts in its telegraph")
	var before := int(floor(instance.telegraphs_for() / STEP)) - 1
	for i in before:
		instance.step(STEP)
	t.check(instance.is_telegraphing(),
			"and is still in it a step before the %.2fs it says it telegraphs for"
			% instance.telegraphs_for())
	for i in int(ceil(instance.telegraphs_for() / STEP)) + 1 - before:
		instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.ACTIVE and not instance.is_telegraphing(),
			"and is active once its telegraph has run")
	instance.free()

func _test_a_waiting_row_notices_warns_and_waits_again(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT, null, null,
			instance_where)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"a row that waits starts waiting")
	instance_where.tell(Vector2(def.notice.within - 10.0, 0.0))
	instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.WARNING and not instance.is_waiting(),
			"inside its one radius it notices her and warns")
	t.check(instance.noticed_at() != INF, "and its notice has a start")
	instance_where.tell(Vector2(def.notice.within + 40.0, 0.0))
	instance.step(STEP)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"back outside its radius, it waits again")
	t.check(instance.noticed_at() == INF, "with no notice left")
	instance_where.tell(Vector2(def.notice.within - 10.0, 0.0))
	var frames := 0
	while instance.phase == EventInstance.Phase.WARNING or frames == 0:
		instance.step(STEP)
		frames += 1
		if frames > 200:
			break
	t.check(instance.phase == EventInstance.Phase.ACTIVE,
			"staying inside, it charges once its warning has run (%d frames)" % frames)
	t.close_to(frames * STEP, def.pursuit.warns_for, "after its own warning", 2.0 * STEP)
	instance.free()

func _test_a_departure_and_a_finish_are_phases(t) -> void:
	var def := EventCatalogue.by_id("dog_walker")
	var instance_where := WhereSheIs.nowhere()
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(40.0, 0.0)]),
			Vector2.RIGHT, null, null, instance_where)
	instance_where.tell(Vector2(0.0, 2000.0))
	var frames := 0
	while not instance.is_leaving and frames < 400:
		instance.step(STEP)
		frames += 1
	t.check(instance.phase == EventInstance.Phase.LEAVING and instance.is_leaving
			and instance.is_on_its_way_out() and not instance.is_gone(),
			"off the end of its route it is leaving (%d frames)" % frames)
	t.check(instance.current_intensity() == 0.0, "and emits nothing while it goes")
	var leaving_ticks := 0
	while not instance.is_finished and leaving_ticks < 400:
		instance.step(STEP)
		leaving_ticks += 1
	t.check(instance.phase == EventInstance.Phase.DONE and instance.is_finished
			and instance.is_gone() and not instance.is_leaving and not instance.is_on_its_way_out(),
			"finished, it is done, and only done")
	instance.free()

## **A telegraph is a promise about the clock, not the phase.** The day-3 lesson dog spends its
## 4.5s telegraph closing on her; once it is 1.5s in (`Tuning.PURSUIT_MIN_NOTICE`), running for
## `Tuning.PURSUIT_SHAKEN_OFF` shakes it off and it trots away while its telegraph is still running.
## It goes on answering `is_telegraphing()` until its clock runs out, as everything that reads it —
## the alert over her head, `event_activated`, its pictures — has always seen it.
func _test_a_dog_shaken_off_mid_telegraph_is_telegraphing_until_its_clock_runs(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var dog_where := WhereSheIs.nowhere()
	var dog := EventInstance.new()
	dog.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT, null, null, dog_where)
	var her := Vector2(400.0, 0.0)
	var clock := 0.0
	while not dog.is_leaving and clock < def.telegraph_time:
		if clock >= 1.2:
			dog_where.tell(dog_where.at(), Vector2.INF, Rect2(), true)
			her += Vector2(Tuning.RUN_SPEED * STEP, 0.0)
		dog_where.tell(her, Vector2.INF, Rect2(), dog_where.is_running())
		dog.step(STEP)
		clock += STEP
	t.check(dog.is_leaving and dog.chase_age() < def.telegraph_time,
			"run from 1.2s, the lesson dog gives up %.1fs into its %.1fs telegraph"
			% [dog.chase_age(), def.telegraph_time])
	t.check(dog.is_telegraphing(), "and is still telegraphing as it leaves")
	t.check(dog.has_given_up(), "having given up: she shook it off, its clock did not run out")
	# She follows it at 100px, so it stays in her sight and in the world while its clock runs.
	while dog.chase_age() < def.telegraph_time - 2.0 * STEP and not dog.is_finished:
		dog_where.tell(dog.global_position + Vector2(100.0, 0.0), Vector2.INF, Rect2(),
				dog_where.is_running())
		dog.step(STEP)
		t.check(dog.is_telegraphing(), "every frame until its clock runs out (%.1fs)" % dog.chase_age())
	while dog.chase_age() < def.telegraph_time + STEP and not dog.is_finished:
		dog_where.tell(dog.global_position + Vector2(100.0, 0.0), Vector2.INF, Rect2(),
				dog_where.is_running())
		dog.step(STEP)
	t.check(not dog.is_finished and dog.is_leaving, "still in the world, leaving")
	t.check(not dog.is_telegraphing(), "and not once its %.1fs have run" % def.telegraph_time)
	dog.free()

## A notice that was held (a held lunge with her inside its stand-off, a charger behind a wall at its
## warning's last moment, the masked man's wait) is carried across a stream-out held time and all, so
## the instance put back is exactly as far into its notice as the one taken away. The robber here is
## set on her inside his stand-off (`notice_her_at()`), which holds his lunge and so his notice's clock
## every tick (`_hold_the_notice_clock()`): a second of standing there has run none of his notice, and
## the second he waited is in the start the stream-out carries. A walk out of the stand-off cannot
## show the notice running afterwards, since he lunges the moment she is at the full stand-off.
func _test_a_held_notice_comes_back_as_far_run(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var first_where := WhereSheIs.nowhere()
	var first := EventInstance.new()
	first.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT, null, null, first_where)
	var her := Vector2(60.0, 0.0)
	t.check(her.length() < first.charge_radius(), "she stands inside the robber's stand-off")
	first.notice_her_at(her, 5.0)
	var held_steps := 10
	for i in held_steps:
		first_where.tell(her)
		first.step(STEP)
	t.check(first.phase == EventInstance.Phase.WARNING, "set on her, he is warning")
	t.close_to(first.chase_age(), 0.0, "and his notice, held every tick, has not run", 0.0001)
	t.close_to(first.noticed_at(), held_steps * STEP,
			"the second he waited is counted into the start a stream-out carries", 0.0001)
	var second := EventInstance.new()
	second.setup(def, Vector2.ZERO)
	# Put back two seconds later: the notice has run those two seconds, and the second he waited held
	# is not counted as run. Started at the age it was put back at instead, it would have run none.
	second.resume(first.age + 2.0, 0.0, first.noticed_at())
	t.close_to(second.chase_age(), 2.0, "streamed back in, it has run the two seconds since and not the held one", 0.0001)
	first.free()
	second.free()

## `at_heat()` gives a hunting copy its own `PursuitSpec`, never the cold row's own hunt's (`EventDef.hunts`),
## so the copy's speed is not written onto the row every other copy is made from.
func _test_a_hunting_copy_does_not_share_its_rows_pursuit(t) -> void:
	var cold := EventCatalogue.by_id("roadblock")
	var hot := EventCatalogue.heated(cold, Tuning.RESISTANCE_GOAL)
	t.check(cold.pursuit == null and cold.hunts.pursuit != null, "the cold roadblock does not pursue")
	t.check(hot.pursuit != null and hot.pursuit != cold.hunts.pursuit,
			"its hunting copy pursues with a spec of its own")
	t.check(is_equal_approx(hot.pursuit.speed, Tuning.HEAT_HUNTS_SPEED)
			and is_equal_approx(cold.hunts.pursuit.speed, 0.0),
			"at the ladder's speed, leaving the row's spec as it was")
	t.check(hot.notice != null and is_equal_approx(hot.notice.within, EventDef.HEAT_HUNTS_WITHIN),
			"noticing her at the ladder's distance")

# -------------------------------------------------------------- the badge alone ---

## A warning up before its thing exists points where the thing will come from, moving only with
## her, and counts down the row's own warning, on the clock above.
func _test_a_badge_up_alone_points_and_counts_down(t) -> void:
	var def := EventSpawner.as_warned(EventCatalogue.by_id("cyclist"))
	var arrived := [0]
	var where := func(her: Vector2) -> Vector2: return her + Vector2(600.0, 0.0)
	var arrive := func(_at: Vector2, _her: Vector2) -> bool:
		arrived[0] += 1
		return true
	var warning := PendingWarning.new(def, where, arrive)
	t.check(warning.row() == def, "it warns of the row it was made for")
	t.check(warning.points_at() == Vector2.INF, "and points nowhere before it is put up")
	warning.put_up(Vector2.ZERO)
	t.check(warning.points_at() == Vector2(600.0, 0.0), "put up, it points where the thing would come")
	t.close_to(warning.seconds_left(), def.warned_for(), "with the row's whole warning to run")
	warning.tick(STEP, Vector2(0.0, 50.0))
	t.check(warning.points_at() == Vector2(600.0, 50.0), "and the place moves only with her")
	t.close_to(warning.seconds_left(), def.warned_for() - STEP, "a step less to run after a step")
	var steps := 0
	while arrived[0] == 0 and steps < 100:
		warning.tick(STEP, Vector2(0.0, 50.0))
		steps += 1
	t.check(arrived[0] == 1 and warning.seconds_left() <= 0.0,
			"its thing comes once nothing is left of it")

## A live event made where it stands came under no warning, one that does not drive closes on
## nothing, and its field reaches exactly where its row's field is heard: the reach the run log's
## lines ask (`field_reaches()`) agrees with the field the meter is charged from.
func _test_a_live_event_answers_for_its_row(t) -> void:
	for id: String in ["alley_robbery", "police_patrol", "cafe_tables", "cyclist"]:
		var def := EventCatalogue.by_id(id)
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		t.check(not instance.was_warned_of(), "'%s' made where it stands came under no warning" % id)
		if not instance.drives():
			t.check(not instance.closes_on(Vector2.ZERO),
					"'%s' drives nothing, so it closes on nothing" % id)
		for distance: float in [0.0, def.heard_within() - 1.0, def.heard_within() + 1.0, 2000.0]:
			var at := Vector2(0.0, distance)
			t.check(instance.field_reaches(at) == (def.emission_at_distance(distance) > 0.0),
					"'%s' reaches %.0fpx out exactly where its row's field is heard" % [id, distance])
		instance.free()
