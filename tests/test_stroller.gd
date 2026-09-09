extends RefCounted
## `Stroller`'s legacy SVG presentation, and the one thing the illustrated opt-in owes the baseline.
##
## **The hysteresis half of this suite runs only while the legacy presentation is the live one**
## (`not DevFlags.illustrated_requested()`, which a headless test process is unless `--illustrated`
## is passed). `_update_view()` and the `_side_view` member it writes decide which family of
## drawing `_draw_mother()` and `_draw_pram()` show, and they exist for the legacy sprites alone —
## the illustrated compositor poses a body from displacement and has no such decision to make. So
## the contracts below are stated against the presentation that owns them rather than against
## whichever one happens to be running, and `_test_the_illustrated_compositor_is_opt_in()` is the
## one check that holds either way.
##
## The decision the two draw functions must never disagree about is *whether she is drawn side-on
## or front-or-back*. `Stroller._update_view()` makes it once a frame, with hysteresis rather than
## a single switching angle, into the shared `_side_view` member both read — this suite drives
## `facing` and calls `_update_view()` directly, the way `_physics_process()` does, without
## stepping physics or a canvas.

func run(t) -> void:
	_test_the_illustrated_compositor_is_opt_in(t)
	if DevFlags.illustrated_requested():
		return
	_test_the_default_facing_is_front_or_back(t)
	_test_a_slow_sweep_up_through_the_diagonal_switches_once(t)
	_test_a_slow_sweep_down_through_the_diagonal_switches_once(t)
	_test_wobbling_inside_the_band_never_switches(t)
	_test_reset_at_settles_the_view_for_the_new_facing(t)

func _rig(t) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	return rig

## The baseline is the legacy presentation, and nothing but an explicit `--illustrated` or
## `?illustrated=1` changes that — so a rig built with neither carries no `ModularPerson` child at
## all. The one check here that is asserted under both presentations, since it is the gate itself
## rather than anything downstream of it.
func _test_the_illustrated_compositor_is_opt_in(t) -> void:
	var rig := _rig(t)
	rig.reset_at(Vector2(80.0, 120.0))
	var camera := rig.get_node("Camera2D") as Camera2D
	t.check(rig.facing == Vector2.DOWN, "reset keeps the default south-facing owner heading")
	t.check((rig.get_node_or_null("ModularPerson") != null)
			== DevFlags.illustrated_requested(),
		"the illustrated compositor exists exactly when it was opted into")
	var expected_zoom := DevFlags.illustrated_zoom() if DevFlags.illustrated_requested() else 1.0
	t.check(is_equal_approx(camera.zoom.x, expected_zoom),
		"the illustrated zoom override applies only to the illustrated camera")
	rig.free()

## Before she has moved, `facing` is `Vector2.DOWN` — 90° off the horizontal axis, squarely
## inside the front-or-back half of the band — so there is nothing to settle before the first
## frame runs.
func _test_the_default_facing_is_front_or_back(t) -> void:
	var rig := _rig(t)
	t.check(not rig._side_view, "the rig starts front-or-back, matching the default facing")
	rig.free()

## A monotonic turn from due east (0°, side-on) to due south (90°, front-or-back — `facing.y > 0`
## is toward the viewer, per `_draw_mother()`) crosses the whole hysteresis band once. **The
## drawing choice must change exactly once**, and the change must land past the band's high edge
## rather than at the old single 45° cutover.
func _test_a_slow_sweep_up_through_the_diagonal_switches_once(t) -> void:
	var rig := _rig(t)
	# Settle the starting facing first, so the sweep below counts only the crossing it is
	# testing rather than the rig's default `_side_view` catching up to where the sweep begins.
	rig.facing = Vector2.RIGHT
	rig._update_view()
	var flips := 0
	var degrees_at_flip := 0.0
	var degrees := 0.5
	while degrees <= 90.0:
		rig.facing = Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees)))
		var before := rig._side_view
		rig._update_view()
		if rig._side_view != before:
			flips += 1
			degrees_at_flip = degrees
		degrees += 0.5
	t.check(flips == 1, "a slow sweep from side-on to front-or-back changes the drawing once")
	t.check(degrees_at_flip > Stroller.FRONT_OR_BACK_VIEW_ABOVE_DEGREES,
			"the switch lands past the band's high edge, not at the old 45° cutover")
	t.check(not rig._side_view, "and she ends up front-or-back, facing due south")
	rig.free()

## The same sweep run backwards: front-or-back down to side-on, switching once past the band's
## low edge.
func _test_a_slow_sweep_down_through_the_diagonal_switches_once(t) -> void:
	var rig := _rig(t)
	rig.facing = Vector2.DOWN
	rig._update_view()
	var flips := 0
	var degrees_at_flip := 90.0
	var degrees := 89.5
	while degrees >= 0.0:
		rig.facing = Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees)))
		var before := rig._side_view
		rig._update_view()
		if rig._side_view != before:
			flips += 1
			degrees_at_flip = degrees
		degrees -= 0.5
	t.check(flips == 1, "a slow sweep from front-or-back to side-on changes the drawing once")
	t.check(degrees_at_flip < Stroller.SIDE_VIEW_BELOW_DEGREES,
			"the switch lands past the band's low edge, not at the old 45° cutover")
	t.check(rig._side_view, "and she ends up side-on, facing due east")
	rig.free()

## The reported bug: a facing that drifts by float noise across the old single 45° switching
## angle. Simulated as an oscillation entirely inside the 40°-50° hysteresis band — the drawing
## must never change, which a strict `absf(facing.x) > absf(facing.y)` comparison could not
## promise.
func _test_wobbling_inside_the_band_never_switches(t) -> void:
	var rig := _rig(t)
	rig.facing = Vector2(cos(deg_to_rad(30.0)), sin(deg_to_rad(30.0)))
	rig._update_view()
	t.check(rig._side_view, "starts side-on, approaching the band from below")
	var settled := rig._side_view
	for degrees in [43.0, 47.0, 44.2, 46.8, 45.0, 43.9, 46.1, 40.1, 49.9]:
		rig.facing = Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees)))
		rig._update_view()
		t.check(rig._side_view == settled,
				"wobbling inside the 40°-50° band at %.1f° does not change the drawing" % degrees)
	rig.free()

## `reset_at()` puts her back on the doorstep, and the view has to settle for the new facing
## rather than carry a previous day's hysteresis across the teleport — there is no "last frame"
## of a day that was rewound or never started.
func _test_reset_at_settles_the_view_for_the_new_facing(t) -> void:
	var rig := _rig(t)
	rig.facing = Vector2.RIGHT
	rig._update_view()
	t.check(rig._side_view, "side-on before the reset")

	rig.reset_at(Vector2.ZERO)
	t.check(not rig._side_view, "the default reset look (due south) settles front-or-back")

	rig.reset_at(Vector2.ZERO, Vector2.LEFT)
	t.check(rig._side_view, "an explicit side-on look settles side-on immediately, not held over")
	rig.free()
