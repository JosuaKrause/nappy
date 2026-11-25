extends RefCounted
## **`ViewShake`, the small eased shake of her view for an explosion close by**: plain arithmetic
## over its own clock, stepped by hand as `Stroller._update_camera()` steps it each physics tick.

const TICK := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_a_full_shake_stays_small_and_dies_away(t)
	_test_a_weaker_shake_does_not_cut_a_stronger_short(t)
	_test_nothing_heard_shakes_nothing(t)
	_test_the_share_falls_with_distance(t)

## A shake at full strength never swings the view further than `ViewShake.MOST_PX` on either axis,
## does swing it, grows no wider as it goes, and is still once `ViewShake.SECONDS` have passed.
func _test_a_full_shake_stays_small_and_dies_away(t: TestRunner) -> void:
	var shake := ViewShake.new()
	shake.start(1.0)
	var widest := 0.0
	var first_half := 0.0
	var second_half := 0.0
	var ticks := ceili(ViewShake.SECONDS / TICK)
	for i in ticks:
		var offset := shake.step(TICK)
		var swing := maxf(absf(offset.x), absf(offset.y))
		widest = maxf(widest, swing)
		if i < ticks / 2:
			first_half = maxf(first_half, swing)
		else:
			second_half = maxf(second_half, swing)
	t.check(widest > 0.5 and widest <= ViewShake.MOST_PX + 0.001,
			"it swings the view, at most %.1fpx (%.2fpx)" % [ViewShake.MOST_PX, widest])
	t.check(second_half < first_half, "and dies away (%.2fpx, then %.2fpx)"
			% [first_half, second_half])
	t.check(shake.step(TICK) == Vector2.ZERO, "still once its time has passed")

## A quiet bang during a loud one's shake leaves the loud one running; a loud one during a quiet
## one starts afresh at its own size.
func _test_a_weaker_shake_does_not_cut_a_stronger_short(t: TestRunner) -> void:
	var loud := ViewShake.new()
	loud.start(1.0)
	loud.step(TICK)
	var quiet_after := ViewShake.new()
	quiet_after.start(1.0)
	quiet_after.step(TICK)
	quiet_after.start(0.1)
	t.check(loud.step(TICK) == quiet_after.step(TICK),
			"a weaker shake does not cut a stronger one short")
	var growing := ViewShake.new()
	growing.start(0.1)
	growing.step(TICK)
	growing.start(1.0)
	var fresh := ViewShake.new()
	fresh.start(1.0)
	t.check(growing.step(TICK) == fresh.step(TICK), "a stronger one starts afresh")

## An explosion whose field does not reach her shakes nothing.
func _test_nothing_heard_shakes_nothing(t: TestRunner) -> void:
	var shake := ViewShake.new()
	shake.start(0.0)
	t.check(shake.step(TICK) == Vector2.ZERO, "a bang she cannot hear does not shake her view")

## The share is full on top of the explosion, falls in a straight line and is none at the reach and beyond.
func _test_the_share_falls_with_distance(t: TestRunner) -> void:
	t.check(ViewShake.share_at(0.0, 1000.0) == 1.0, "on top of it, the full share")
	t.check(is_equal_approx(ViewShake.share_at(250.0, 1000.0), 0.75), "a quarter of the way out, three quarters")
	t.check(ViewShake.share_at(1000.0, 1000.0) == 0.0 and ViewShake.share_at(1500.0, 1000.0) == 0.0,
			"none at its reach and beyond")
