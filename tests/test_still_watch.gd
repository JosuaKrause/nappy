extends RefCounted
## `StillWatch._feed()`, the pure stillness heuristic behind `--quit-when-still`: positions and
## deltas in, a trigger out, armed only once she has moved and frozen rather than reset while
## inactive (paused, or the day not running). No `City`, `Stroller` or running day anywhere here —
## a bare `StillWatch.new()` off the tree drives it directly, the same way `tests/test_auto_screenshot
## .gd` calls `AutoScreenshot._parse_script()` without ever adding that node to a tree either.
##
## Every step below uses a `0.25` delta rather than the more obvious `0.1`: ten additions of `0.1`
## land on `0.9999999999999999` in double precision, one tick short of the `1.0` hold this suite
## means to cross, and `0.25` is exactly representable so four ticks land on exactly `1.0` with no
## such trap.
##
## `StillWatch` is a `Node`, not `RefCounted`, so every instance is freed explicitly or the suite
## reports it leaked at shutdown.

const _TICK := 0.25

func run(t) -> void:
	_test_the_opening_stand_never_triggers(t)
	_test_a_move_past_the_radius_arms_it_without_triggering(t)
	_test_holding_still_after_the_move_triggers_at_the_hold(t)
	_test_a_further_move_restarts_the_hold_from_the_new_spot(t)
	_test_jitter_inside_the_radius_does_not_reset_the_hold(t)
	_test_inactive_frames_freeze_the_hold_instead_of_resetting_it(t)

func _watch(hold_seconds := 1.0) -> StillWatch:
	var w := StillWatch.new()
	w._seconds = hold_seconds
	return w

## Standing exactly where she started — the doorstep, before she has ever moved — must never
## trigger, however long it is held: the flag is armed only once she has actually gone somewhere.
func _test_the_opening_stand_never_triggers(t: Object) -> void:
	var w := _watch()
	var triggered := false
	for i in 40:
		triggered = w._feed(Vector2.ZERO, _TICK, true) or triggered
	t.check(not triggered, "ten seconds at the start before any move never arms the flag")
	w.free()

## The frame she moves past the radius is recognised as a move, not read as an instant trigger.
func _test_a_move_past_the_radius_arms_it_without_triggering(t: Object) -> void:
	var w := _watch()
	w._feed(Vector2.ZERO, _TICK, true)
	var moved := Vector2(StillWatch.STILL_RADIUS + 1.0, 0.0)
	var triggered := w._feed(moved, _TICK, true)
	t.check(not triggered, "the frame she moves is not itself a trigger")
	t.check(w._armed, "moving past the radius arms the detector")
	w.free()

## The hold counts from the move, and fires the instant it reaches the given number of seconds.
func _test_holding_still_after_the_move_triggers_at_the_hold(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var triggered := false
	for i in 3:
		triggered = w._feed(Vector2(10, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s of holding still is short of a 1.0s hold")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the fourth tick reaches exactly 1.0s and fires")
	w.free()

## A second move mid-hold restarts the countdown from the new spot rather than finishing at the
## hold's own total counted across two different places she stood.
func _test_a_further_move_restarts_the_hold_from_the_new_spot(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	for i in 2:
		w._feed(Vector2(10, 0), _TICK, true)
	w._feed(Vector2(40, 0), _TICK, true)
	var triggered := false
	for i in 3:
		triggered = w._feed(Vector2(40, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s at the new spot is short of a fresh 1.0s hold")
	triggered = w._feed(Vector2(40, 0), _TICK, true)
	t.check(triggered, "1.0s at the new spot fires, counted from when she arrived there")
	w.free()

## Sub-radius wobble — the slide's own settling against a wall, not a real move — never resets the
## hold that is already counting.
func _test_jitter_inside_the_radius_does_not_reset_the_hold(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var jitter := StillWatch.STILL_RADIUS * 0.5
	var triggered := false
	for i in 3:
		var wobble := Vector2(10 + (jitter if i % 2 == 0 else -jitter), 0)
		triggered = w._feed(wobble, _TICK, true) or triggered
	t.check(not triggered, "three ticks of sub-radius wobble have not reached the hold yet")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the fourth tick fires — the wobble never reset the count")
	w.free()

## `active` false — the day not running, or the tree paused — freezes the hold rather than
## resetting it: resuming afterward picks the count back up from where it left off.
func _test_inactive_frames_freeze_the_hold_instead_of_resetting_it(t: Object) -> void:
	var w := _watch(1.0)
	w._feed(Vector2.ZERO, _TICK, true)
	w._feed(Vector2(10, 0), _TICK, true)
	var triggered := false
	for i in 20:
		triggered = w._feed(Vector2(10, 0), _TICK, false) or triggered
	t.check(not triggered, "inactive frames never advance the hold, however many of them there are")
	for i in 3:
		triggered = w._feed(Vector2(10, 0), _TICK, true) or triggered
	t.check(not triggered, "0.75s active since the move is still short of the hold")
	triggered = w._feed(Vector2(10, 0), _TICK, true)
	t.check(triggered, "the hold resumes once active again, counted from before the pause")
	w.free()
