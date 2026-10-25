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
	var steps := int(ceil(def.telegraph_time / STEP)) + 1
	for i in steps:
		instance._process(STEP)
	t.check(instance.phase == EventInstance.Phase.ACTIVE and not instance.is_telegraphing(),
			"and is active once its telegraph has run")
	instance.free()

func _test_a_waiting_row_notices_warns_and_waits_again(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"a row that waits starts waiting")
	instance.player_at = Vector2(def.notice.within - 10.0, 0.0)
	instance._process(STEP)
	t.check(instance.phase == EventInstance.Phase.WARNING and not instance.is_waiting(),
			"inside its one radius it notices her and warns")
	t.check(instance.noticed_at() != INF, "and its notice has a start")
	instance.player_at = Vector2(def.notice.within + 40.0, 0.0)
	instance._process(STEP)
	t.check(instance.phase == EventInstance.Phase.WAITING and instance.is_waiting(),
			"back outside its radius, it waits again")
	t.check(instance.noticed_at() == INF, "with no notice left")
	instance.player_at = Vector2(def.notice.within - 10.0, 0.0)
	var frames := 0
	while instance.phase == EventInstance.Phase.WARNING or frames == 0:
		instance._process(STEP)
		frames += 1
		if frames > 200:
			break
	t.check(instance.phase == EventInstance.Phase.ACTIVE,
			"staying inside, it charges once its warning has run (%d frames)" % frames)
	t.close_to(frames * STEP, def.pursuit.warns_for, "after its own warning", 2.0 * STEP)
	instance.free()

func _test_a_departure_and_a_finish_are_phases(t) -> void:
	var def := EventCatalogue.by_id("dog_walker")
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array([Vector2.ZERO, Vector2(40.0, 0.0)]))
	instance.player_at = Vector2(0.0, 2000.0)
	var frames := 0
	while not instance.is_leaving and frames < 400:
		instance._process(STEP)
		frames += 1
	t.check(instance.phase == EventInstance.Phase.LEAVING and instance.is_leaving,
			"off the end of its route it is leaving (%d frames)" % frames)
	t.check(instance.current_intensity() == 0.0, "and emits nothing while it goes")
	instance._finish()
	t.check(instance.phase == EventInstance.Phase.DONE and instance.is_finished
			and not instance.is_leaving, "finished, it is done, and only done")
	instance.free()

## **A telegraph is a promise about the clock, not the phase.** The day-3 lesson dog spends its
## 4.5s telegraph closing on her; once it is 1.5s in (`Tuning.PURSUIT_MIN_NOTICE`), running for
## `Tuning.PURSUIT_SHAKEN_OFF` shakes it off and it trots away while its telegraph is still running.
## It goes on answering `is_telegraphing()` until its clock runs out, as everything that reads it —
## the alert over her head, `event_activated`, its pictures — has always seen it.
func _test_a_dog_shaken_off_mid_telegraph_is_telegraphing_until_its_clock_runs(t) -> void:
	var def := EventCatalogue.by_id("charging_dog")
	var dog := EventInstance.new()
	dog.setup(def, Vector2.ZERO)
	var her := Vector2(400.0, 0.0)
	var clock := 0.0
	while not dog.is_leaving and clock < def.telegraph_time:
		if clock >= 1.2:
			dog.player_running = true
			her += Vector2(Tuning.RUN_SPEED * STEP, 0.0)
		dog.player_at = her
		dog._process(STEP)
		clock += STEP
	t.check(dog.is_leaving and dog.chase_age() < def.telegraph_time,
			"run from 1.2s, the lesson dog gives up %.1fs into its %.1fs telegraph"
			% [dog.chase_age(), def.telegraph_time])
	t.check(dog.is_telegraphing(), "and is still telegraphing as it leaves")
	# She follows it at 100px, so it stays in her sight and in the world while its clock runs.
	while dog.chase_age() < def.telegraph_time - 2.0 * STEP and not dog.is_finished:
		dog.player_at = dog.global_position + Vector2(100.0, 0.0)
		dog._process(STEP)
		t.check(dog.is_telegraphing(), "every frame until its clock runs out (%.1fs)" % dog.chase_age())
	while dog.chase_age() < def.telegraph_time + STEP and not dog.is_finished:
		dog.player_at = dog.global_position + Vector2(100.0, 0.0)
		dog._process(STEP)
	t.check(not dog.is_finished and dog.is_leaving, "still in the world, leaving")
	t.check(not dog.is_telegraphing(), "and not once its %.1fs have run" % def.telegraph_time)
	dog.free()

## A notice that was held for a while (a held lunge, a charger behind a wall at its warning's last
## moment, the masked man's wait) is carried across a stream-out held time and all, so the instance
## put back is exactly as far into its notice as the one taken away.
func _test_a_held_notice_comes_back_as_far_run(t) -> void:
	var def := EventCatalogue.by_id("alley_robbery")
	var first := EventInstance.new()
	first.setup(def, Vector2.ZERO)
	first.player_at = Vector2(def.notice.within - 10.0, 0.0)
	first._process(STEP)
	for i in 5:
		first._process(STEP)
	first._notice.hold(0.3)
	var into := first.chase_age()
	var second := EventInstance.new()
	second.setup(def, Vector2.ZERO)
	second.resume(first.age, 0.0, first.noticed_at())
	t.close_to(second.chase_age(), into, "streamed back in, it is as far into its notice", 0.0001)
	t.check(second.phase == EventInstance.Phase.WARNING, "and still warning")
	first.free()
	second.free()

## `at_heat()` gives a hunting copy its own `PursuitSpec`, never the cold row's `hunts_as` itself,
## so the copy's speed is not written onto the row every other copy is made from.
func _test_a_hunting_copy_does_not_share_its_rows_pursuit(t) -> void:
	var cold := EventCatalogue.by_id("roadblock")
	var hot := EventCatalogue.heated(cold, Tuning.RESISTANCE_GOAL)
	t.check(cold.pursuit == null and cold.hunts_as != null, "the cold roadblock does not pursue")
	t.check(hot.pursuit != null and hot.pursuit != cold.hunts_as,
			"its hunting copy pursues with a spec of its own")
	t.check(is_equal_approx(hot.pursuit.speed, Tuning.HEAT_HUNTS_SPEED)
			and is_equal_approx(cold.hunts_as.speed, 0.0),
			"at the ladder's speed, leaving the row's spec as it was")
	t.check(hot.notice != null and is_equal_approx(hot.notice.within, Tuning.HEAT_HUNTS_WITHIN),
			"noticing her at the ladder's distance")
