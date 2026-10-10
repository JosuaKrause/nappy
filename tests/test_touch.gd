extends RefCounted
## `TouchControls`' own geometry: that the pause button shows only where and when it should, that
## a finger on it presses the same real `pause` action a keyboard does, and that a press anywhere
## else — a finger or a mouse click — sets a direction, stops her, or runs it, exactly the parts a
## screenshot cannot check.
##
## `_touch` is read once into a member exactly the way `QuitOption.available()` and `hud._debug`
## are — a headless test process is never a touch device, so a gate asked of `TouchInput` at each
## use site would leave this whole class asserted by nothing.
##
## **`_touch` and `_mode` answer different questions, and a test that wants `Mode.JOYSTICK`'s own
## focus-based aiming has to set `_mode` — setting `_touch` no longer does anything to it.** `_touch`
## only decides which raw event type `_input()` reads and whether a touch device's own emulated
## mouse click is ignored; every test below that calls `_on_tap()`/`_on_drag()` directly bypasses
## `_input()` entirely, so `_touch` was never anything but a mode selector for those, back when the
## two were the same flag. See `ControlsMode` and `TouchControls.set_mode()`.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
	_test_process_mode_stays_always(t)
	_test_the_button_shows_on_every_device_with_a_day_running(t)
	_test_the_pause_button_sends_a_real_action_event(t)
	_test_the_pause_button_fires_on_release_inside_and_not_outside(t)
	_test_every_catch_is_at_least_five_percent_past_its_drawing_and_never_smaller_than_it_was(t)
	_test_the_pause_button_tracks_its_own_touch_index(t)
	_test_hiding_the_controls_releases_a_held_direction(t)
	_test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t)
	_test_is_double_tap_needs_both_windows(t)
	_test_set_direction_presses_the_components_of_the_heading(t)
	_test_set_direction_on_her_own_position_stops_rather_than_pressing(t)
	_test_a_mouse_click_within_the_stop_radius_of_her_stops_her(t)
	_test_a_direction_stays_locked_in_with_nothing_held_down(t)
	_test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t)
	_test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t)
	_test_a_tap_during_a_pause_does_nothing(t)
	_test_a_pause_force_releases_a_held_direction(t)
	_test_a_press_while_paused_is_never_the_first_heading(t)
	_test_a_mouse_click_stands_in_for_a_tap(t)
	_test_a_touch_devices_own_emulated_click_is_ignored(t)
	_test_a_press_on_the_pause_button_is_not_also_a_direction(t)
	_test_a_mouse_click_on_the_pause_button_is_not_also_a_direction(t)
	_test_the_corner_is_an_ordinary_direction_press_where_the_button_is_not_drawn(t)
	_test_no_input_path_presses_a_vector_shorter_than_one(t)
	_test_a_keyboard_press_resets_a_clicked_heading(t)
	_test_the_steering_half_reaches_two_thirds_toward_run(t)
	_test_the_dead_zone_is_tighter_than_the_ring_and_only_on_steering(t)
	_test_the_stop_band_sits_on_the_steering_edge(t)
	_test_a_touch_aims_from_the_steering_focus_not_from_her(t)
	_test_current_heading_matches_a_press_through_the_steering_focus(t)
	_test_current_heading_reads_zero_while_detained(t)
	_test_a_press_at_a_focus_centre_stops_her_on_touch(t)
	_test_a_touch_near_her_own_position_no_longer_stops_her(t)
	_test_a_mouse_click_still_aims_from_her_not_a_focus(t)
	_test_a_touch_drag_updates_the_heading_and_still_presses_a_unit_vector(t)
	_test_a_press_at_a_focus_centre_starts_a_drag_that_can_leave_and_return(t)
	_test_a_tap_mode_drag_stops_and_resumes_crossing_her_own_stop_radius(t)
	_test_a_double_tap_that_then_drags_keeps_running(t)
	_test_a_mouse_drag_reaims_from_her_own_position(t)
	_test_a_mouse_motion_without_the_button_held_does_nothing(t)
	_test_a_tap_in_the_stop_band_stops_her_on_touch(t)
	_test_a_drag_past_the_band_keeps_steering_from_the_same_side(t)
	_test_a_press_on_runs_side_never_steers(t)
	_test_a_swipe_through_the_dead_zone_lands_on_its_release(t)
	_test_round_button_margins_and_unchanged_dead_zones(t)
	_test_a_rig_word_names_the_side(t)
	_test_pointer_roles_hold_wherever_the_pointers_travel(t)
	_test_a_run_button_does_not_cancel_a_double_press_latch(t)
	_test_pause_hide_and_mode_changes_release_holds(t)
	t.get_tree().paused = was_paused
	_release_actions()

func _controls(t) -> TouchControls:
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_process(false)
	return controls

## **Carried over from the code being replaced, bought with a played session.** A `PAUSABLE` node
## stops running the instant the tree pauses, which is one frame too late to let go of whatever
## direction was pressed when the pause landed — see `_release_all()`. `_ready()` sets this
## explicitly rather than trusting it stays true across a rewrite.
func _test_process_mode_stays_always(t) -> void:
	var controls := _controls(t)
	t.check(controls.process_mode == Node.PROCESS_MODE_ALWAYS,
			"the merged controls still process through a pause, the same as the stick did")
	controls.free()

func _rig_at(t, position: Vector2) -> Node2D:
	var rig := Node2D.new()
	rig.global_position = position
	rig.add_to_group("player")
	t.add_child(rig)
	return rig

## **One gate, and it is the same for every device.** *(2026-09-06: "I specifically said that now
## all controls are treated the same across platforms so the buttons should show in *every*
## environment.")* A phone mid-pause should not see the button, because `get_tree().paused` is what
## the title, the pause and the between-days summary all set and none of the three has anything for
## a press to reach — but a keyboard-and-mouse desktop sees it exactly as a phone does, since there
## is one control scheme now rather than one chosen by device.
func _test_the_button_shows_on_every_device_with_a_day_running(t) -> void:
	var controls := _controls(t)

	controls._touch = false
	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not controls.visible, "no device sees the button while the tree is paused")

	controls._touch = false
	t.get_tree().paused = false
	controls._process(0.0)
	t.check(controls.visible, "a desktop with no touch hardware shows it too, once a day is running")

	controls._touch = true
	t.get_tree().paused = false
	controls._process(0.0)
	t.check(controls.visible, "and a touch device shows it exactly the same way")

	controls.free()

## **The pause is not a held action, and firing it needs a real propagated event, not polled
## state.** `main._unhandled_input()` reads `event.is_action_pressed("pause")` off the event
## itself, so `Input.action_press(&"pause")` — the mechanism a held direction uses — would set
## polled state and be heard by nothing, the same trap `AutoScreenshot._tap()`'s own comment names
## for `--press`. Checked directly on `_send_pause_action()`'s own returned event, so this does not
## depend on when the tree gets around to propagating anything — nothing else in this suite does
## either.
func _test_the_pause_button_sends_a_real_action_event(t) -> void:
	var controls := _controls(t)
	var event := controls._send_pause_action()
	t.check(event is InputEventAction, "a real InputEventAction, not bare polled state")
	t.check(event.action == &"pause" and event.pressed,
			"shaped exactly as main._unhandled_input reads a press")
	Input.action_release(&"pause")
	controls.free()

## **Fires on a clean tap, not on touch-down — and a thumb that lands wrong can slide off and lift
## for free.** The button waits for the matching release, and only counts one still over the
## button — pressed once a day at most, a false fire costs more than a missed one.
##
## Asserted on `_pause_fires()` directly, the pure geometry question `_on_touch()`'s release branch
## asks before ever touching `Input`. **A first version of this test asserted
## `Input.is_action_pressed("pause")` after driving a real press/release sequence and failed**:
## `Input.parse_input_event()` queues the event for the engine's own next flush rather than
## updating anything a test can poll synchronously, so that was never a safe way to ask this
## question — `_send_pause_action()`'s own test above is what proves the event it eventually sends
## is shaped correctly, and this is kept to the one thing that is safe to assert synchronously.
func _test_the_pause_button_fires_on_release_inside_and_not_outside(t) -> void:
	t.check(TouchControls._pause_fires(TouchControls.PAUSE_CENTRE),
			"releasing on the button fires it")
	t.check(not TouchControls._pause_fires(TouchControls.PAUSE_CENTRE + Vector2(500.0, 0.0)),
			"and releasing well outside it cancels rather than firing")

## **A catch is the larger of what it was and 1.05 times its drawn radius** *(2026-10-10, the player:
## "why does the button reach decrease anything??? the 5% should go over the visible size making the
## area *larger*!")*. Pause drew 26px and caught at 46px before the 5% margin, which asked for 27.3px
## and shrank the catch to a third of its area; the margin must never take reach away. The release
## that fires pause asks the same geometry, so it is pinned alongside the press. Run's whole half
## catches a press, so what is pinned is that both the drawn disc and 1.05 times its radius lie on
## that half whichever side steers.
func _test_every_catch_is_at_least_five_percent_past_its_drawing_and_never_smaller_than_it_was(t) -> void:
	var drawn := TouchControls.PAUSE_RADIUS
	var old_catch := 46.0
	t.check(TouchControls.PAUSE_CATCH_RADIUS >= drawn * 1.05,
			"pause catches at least 5%% beyond its drawn %.0fpx (catch %.1fpx)"
			% [drawn, TouchControls.PAUSE_CATCH_RADIUS])
	t.check(TouchControls.PAUSE_CATCH_RADIUS >= old_catch,
			"and never less than the 46px it caught at before the margin (catch %.1fpx)"
			% TouchControls.PAUSE_CATCH_RADIUS)
	for probe: Vector2 in [Vector2(old_catch - 0.5, 0.0), Vector2(0.0, -(old_catch - 0.5)),
			Vector2(drawn * 1.05 + 1.0, 0.0), Vector2(-30.0, 30.0)]:
		t.check(TouchControls._pause_fires(TouchControls.PAUSE_CENTRE + probe),
				"a release %.1fpx from the pause button's centre still fires it" % probe.length())
	t.check(not TouchControls._pause_fires(TouchControls.PAUSE_CENTRE + Vector2(old_catch + 1.0, 0.0)),
			"and one past the catch does not")
	for steering: Vector2 in [TouchControls.FOCUS_LEFT, TouchControls.FOCUS_RIGHT]:
		var run := TouchControls.run_focus_for(steering)
		for step in 16:
			var around := Vector2.from_angle(TAU * step / 16.0)
			t.check(TouchControls.is_on_run_side(
					run + around * TouchControls.RUN_RADIUS * ButtonGeometry.CATCH_SCALE, steering),
					"Run's disc and 1.05 times its radius lie on Run's half (steering %s, step %d)"
					% [steering, step])

## **The touch index is grabbed on press and let go on release, whichever way the release
## resolves.** A synchronous check on the node's own state rather than on anything `Input`
## propagates or polls, for the same reason the geometry test above is.
func _test_the_pause_button_tracks_its_own_touch_index(t) -> void:
	var controls := _controls(t)
	controls.visible = true
	t.check(controls._pause_touch == -1, "nothing held at first")

	controls._input(_touch_event(0, TouchControls.PAUSE_CENTRE, true))
	t.check(controls._pause_touch == 0, "landing on the button grabs its touch index")

	controls._input(_touch_event(0, TouchControls.PAUSE_CENTRE + Vector2(500.0, 0.0), false))
	t.check(controls._pause_touch == -1,
			"and releasing lets go of the index again, whether it fired or not")

	controls.free()
	Input.action_release(&"pause")

## **A finger still down when the day ends must not carry into the day after it.** Nothing here
## has a way to be told the tree is about to pause mid-gesture — the summary just sets it — so it
## is this node's own job to let go of everything the instant a pause lands, on every device, not
## only where the button is drawn.
func _test_hiding_the_controls_releases_a_held_direction(t) -> void:
	var controls := _controls(t)
	controls._touch = false
	var rig := _rig_at(t, Vector2.ZERO)

	controls.set_direction(Vector2(100.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"), "a direction is held")

	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not Input.is_action_pressed("move_right"),
			"and lets go of it rather than carrying it into tomorrow, even with no button drawn")

	t.get_tree().paused = false
	controls.free()
	rig.free()

func _test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t) -> void:
	var direction := TouchControls.heading_to(Vector2(0.0, 100.0), Vector2.ZERO)
	t.close_to(direction.length(), 1.0, "the heading is a unit vector")
	t.check(direction.is_equal_approx(Vector2.DOWN), "pointing straight at the target")
	t.check(TouchControls.heading_to(Vector2(10.0, 10.0), Vector2(10.0, 10.0)) == Vector2.ZERO,
			"a tap on her own position has no line to walk")

func _test_is_double_tap_needs_both_windows(t) -> void:
	t.check(TouchControls.is_double_tap(0.1, 10.0), "soon and close reads as a double tap")
	t.check(not TouchControls.is_double_tap(1.0, 10.0), "close but late is a new single tap")
	t.check(not TouchControls.is_double_tap(0.1, 400.0),
			"soon but far away is a new direction, not a modifier on the old one")

func _test_set_direction_presses_the_components_of_the_heading(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	controls.set_direction(Vector2(100.0, -100.0), false)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up"),
			"a diagonal press presses both components of its own unit vector")
	t.check(not Input.is_action_pressed("run"), "a single press does not hold run")

	controls.set_direction(Vector2(-100.0, -100.0), true)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a new press the other way releases the axis it no longer wants")
	t.check(Input.is_action_pressed("run"), "a double press holds run")

	controls.free()
	rig.free()

## `set_direction()`'s own fallback for the degenerate case: a target exactly on top of her has no
## heading to compute, and it now stops her rather than doing nothing — see the class doc for why
## that is strictly more useful and is what was asked for.
func _test_set_direction_on_her_own_position_stops_rather_than_pressing(t) -> void:
	# Leftover state from the previous test's own double press, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2(50.0, 50.0))
	var controls := _controls(t)

	controls.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking first, so there is something for landing on her to let go of")

	controls.set_direction(Vector2(50.0, 50.0), false)
	t.check(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down")
			and not Input.is_action_pressed("run"),
			"landing exactly on her own position stops her rather than pressing nothing")
	t.check(not controls._walking, "and she is no longer walking")

	controls.free()
	rig.free()

## **The generous radius, not the exact pixel — and `Mode.TAP` only now.** *(2026-09-06: "also,
## to stop her just click on her".)* `TAP_STOP_RADIUS` catches a pointer that does not land on the
## same world pixel as her twice, but — unlike the wider, doubled number it replaced — not a click
## on the side-view pram, whose centre stays outside the lifted stop circle. *(Playtest 34 finding 6:
## "if I click on the stroller it shouldn't stop only when I click on the body of the player.")*
## Replaces the old, device-agnostic version of this test rather than sitting beside it — the
## `Mode.JOYSTICK` half of what it asserted is now
## `_test_a_touch_near_her_own_position_no_longer_stops_her`, further down.
##
## **Also the regression test for playtest 35 finding 1**: the circle is centred `TAP_STOP_CENTRE_LIFT`
## (23px) above her feet, not on them, so a click straight below her feet does not stop her and a
## click on her shoulders does.
func _test_a_mouse_click_within_the_stop_radius_of_her_stops_her(t) -> void:
	var rig := _rig_at(t, Vector2(200.0, 200.0))
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.TAP
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	controls._on_tap(transform * Vector2(500.0, 200.0), 0.0)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# 15px off the centre of her sprite (200, 177 -- TAP_STOP_CENTRE_LIFT above her feet at
	# 200, 200) -- within TAP_STOP_RADIUS (16px) of the middle of her, not of her feet.
	controls._on_tap(transform * Vector2(215.0, 177.0), 1.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"a click near the centre of her sprite, not only near her feet, stops her")

	controls._on_tap(transform * Vector2(500.0, 200.0), 2.0)
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the two boundary clicks below have something to undo")

	# 20px straight below her feet -- 43px from the lifted centre. This is playtest 35 finding 1
	# itself: "right now I can click below her to stop."
	controls._on_tap(transform * Vector2(200.0, 220.0), 3.0)
	t.check(Input.is_action_pressed("move_down") and controls._walking,
			"a click below her feet does not stop her")

	controls._on_tap(transform * Vector2(500.0, 200.0), 4.0)
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the upper-body click below has something to undo")

	# 38px straight above her feet -- her shoulders -- 15px from the lifted centre and therefore
	# within TAP_STOP_RADIUS, where a circle centred on her feet would miss it entirely.
	controls._on_tap(transform * Vector2(200.0, 162.0), 5.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"and a click on her shoulders, 38px above her feet, stops her too")

	controls._on_tap(transform * Vector2(500.0, 200.0), 6.0)
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the pram click below has something to undo")

	# The west-facing pram's live centre remains outside TAP_STOP_RADIUS of the lifted stop centre:
	# the pram is not her, even with the hand touching the handle.
	var pram_centre := Vector2(200.0, 200.0) + Vector2(
			-Stroller.PRAM_HORIZONTAL_DISTANCE, Stroller.PRAM_VERTICAL_LIFT)
	controls._on_tap(transform * pram_centre, 7.0)
	t.check(Input.is_action_pressed("move_left") and controls._walking,
			"a click on the pram is not a click on her any more -- it sets a direction instead")

	controls.free()
	rig.free()

## **There is no arrival any more.** A direction pressed once stays held, unrenewed, however long
## `_process()` is asked to run — the whole of what "she walks it until the next press" means.
func _test_a_direction_stays_locked_in_with_nothing_held_down(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	controls.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds the direction and, on a double press, run")

	rig.global_position = Vector2(500.0, 0.0)
	for _i in 100:
		controls._process(0.016)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking well past where a target used to sit still holds the same direction")

	controls.free()
	rig.free()

## **The test a screenshot cannot be**: `_on_tap()`'s own reverse of the transform `DangerEdge` and
## `HomeArrow` already read forwards. Constructed from the viewport's own real
## `get_canvas_transform()` rather than an assumed identity, so this would still catch a camera
## offset or a rotation the way a hard-coded expectation would not.
func _test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	var world_target := Vector2(120.0, -40.0)
	var screen_position: Vector2 = controls.get_viewport().get_canvas_transform() * world_target
	controls._on_tap(screen_position, 0.0)
	t.check(Input.is_action_pressed("move_right"),
			"a tap's own screen position maps back to the world position it was aimed at")

	controls.free()
	rig.free()

## The double-tap windows again, now through the real entry point rather than the pure function
## directly -- a close tap soon after runs, and either window failing on its own falls back to a
## fresh single tap.
func _test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	controls._on_tap(transform * Vector2(100.0, 0.0), 10.0)
	t.check(not Input.is_action_pressed("run"), "the first tap of a run only walks")

	controls._on_tap(transform * Vector2(100.0, 0.0), 10.2)
	t.check(Input.is_action_pressed("run"), "soon and on the same spot reads as a double tap")

	controls._on_tap(transform * Vector2(500.0, 500.0), 10.4)
	t.check(not Input.is_action_pressed("run"),
			"soon but far away is a new direction, not a double tap on the old one")

	controls._on_tap(transform * Vector2(500.0, 500.0), 12.0)
	t.check(not Input.is_action_pressed("run"), "close but late is also a new single tap")

	controls.free()
	rig.free()

## Paused for any reason -- Esc, the day ending, the title -- a tap does nothing, the same as every
## one of those screens already leaving the controls drawing nothing.
func _test_a_tap_during_a_pause_does_nothing(t) -> void:
	# Leftover state from the previous test's own tap, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	t.get_tree().paused = true

	controls._on_tap(controls.get_viewport().get_canvas_transform() * Vector2(50.0, 0.0), 0.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"a tap during a pause does nothing at all")

	t.get_tree().paused = false
	controls.free()
	rig.free()

## A direction left pressed into whatever comes next is the same leak `_release_all()` already
## guards its own controls against on every kind of hiding.
func _test_a_pause_force_releases_a_held_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	controls.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds a direction and, on a double press, run")

	t.get_tree().paused = true
	controls._process(0.016)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"Esc or any other pause force-releases whatever was held")
	t.check(not controls._walking, "and abandons the direction rather than merely pausing mid-stride")

	t.get_tree().paused = false
	controls.free()
	rig.free()

## **"Her direction is zero when a run starts."** *(PLAYTEST-67, "The first press walks her": "Right
## now it always starts already walking (probably from clicking the button) same with exiting
## pause or any other screen".)* The title screen's own disc, the summary's own continue and the
## pause's own continue all dismiss a screen through the same shape: a press that lands while
## `get_tree().paused` is true, acknowledged two frames later by the screen that read it
## (`TitleScreen._acknowledge_and_begin()`, `DaySummary._acknowledge_and_continue()`,
## `PauseScreen._acknowledge_and_resume()`). **The leak this guards against:** `_on_pointer()` used
## to arm `_drag_pointer_index` for that press regardless of whether `_on_tap()` did anything with
## it, so a finger or a mouse button still down once the tree is running again generated an
## ordinary `InputEventScreenDrag`/`InputEventMouseMotion` for the same pointer, and `_on_drag()`
## read it as her first heading — which is exactly *"probably from clicking the button."* `_rig`
## already known (a real walk on an earlier day) is what makes the leak reachable at all here —
## the day summary's own continue button keeps one running `TouchControls` across days rather than
## rebuilding it the way a restart does, unlike a fresh title screen's own `_rig`, which starts
## null and cannot be steered by a drag until a first ordinary press resolves it. Compare
## `_test_a_tap_during_a_pause_does_nothing`, the plain press-while-paused case this builds on.
func _test_a_press_while_paused_is_never_the_first_heading(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.TAP
	controls.set_direction(Vector2(100.0, 0.0), false)
	t.get_tree().paused = true
	controls._process(0.0) # the day ending force-releases the held direction, same as ever
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"standing once the day has ended")

	controls._input(_touch_event(0, Vector2(500.0, 0.0), true))
	t.check(controls._drag_pointer_index == -1,
			"the press that dismisses the screen is never tracked for a later drag")

	t.get_tree().paused = false
	controls._input(_drag_event(0, Vector2(502.0, 1.0)))
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"and the finger's own drift, once the next day is running, is not read as her first heading")

	controls._input(_touch_event(0, Vector2(502.0, 1.0), false))
	t.get_tree().paused = false
	controls.free()
	rig.free()
	_release_actions()

## "On non-mobile we can try clicking with the mouse instead of tapping" -- a left click reaches
## `_on_tap()` exactly the way a finger's own `InputEventScreenTouch` does. This suite's own process
## is always a debug build, the same as every other dev-only path in this project, so the gate
## itself is not what this checks; only that a click is read at all.
func _test_a_mouse_click_stands_in_for_a_tap(t) -> void:
	# Leftover pause from the previous test's own pause check, not this one's concern.
	t.get_tree().paused = false
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = controls.get_viewport().get_canvas_transform() * Vector2(100.0, 0.0)
	controls._input(click)
	t.check(Input.is_action_pressed("move_right"), "a left click walks exactly as a tap would")

	# A right click, or the release half of a left one, is not a tap.
	var release := click.duplicate()
	release.pressed = false
	controls._input(release)
	var other_button := InputEventMouseButton.new()
	other_button.button_index = MOUSE_BUTTON_RIGHT
	other_button.pressed = true
	other_button.position = controls.get_viewport().get_canvas_transform() * Vector2(-100.0, 0.0)
	controls._input(other_button)
	t.check(not Input.is_action_pressed("move_left"), "only a left click's own press is a tap")

	controls.free()
	rig.free()

## **The gate that makes the mouse stand-in safe on a real touch device.** Godot emulates a mouse
## click from every real touch by default (`input_devices/pointing/emulate_mouse_from_touch`), so
## without `not _touch` a single tap would fire `_on_tap()` twice, once through each event, at the
## same place and the same instant -- close enough on both windows to read as its own double tap.
## This is the bug a first version of `--tap` actually hit: a lone `--tap` on a screenshot rig run
## with `--touch` came back running, not walking.
func _test_a_touch_devices_own_emulated_click_is_ignored(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = true

	var touch := InputEventScreenTouch.new()
	touch.position = controls.get_viewport().get_canvas_transform() * Vector2(100.0, 0.0)
	touch.pressed = true
	controls._input(touch)
	t.check(not Input.is_action_pressed("run"), "the real touch alone only walks")

	# The engine's own emulated click, same place, same instant -- exactly what a real touch device
	# would also deliver right behind the touch above.
	var emulated := InputEventMouseButton.new()
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.position = touch.position
	controls._input(emulated)
	t.check(not Input.is_action_pressed("run"),
			"a touch device's own emulated click is not read as a second, doubling tap")

	controls.free()
	rig.free()

## **The cost the no-UI decision was protecting, now paid deliberately.** *(2026-09-06: "and then
## it also needs the pause button in the top right".)* A touch press that lands on the button,
## while it is showing, must not also lock in a direction toward the corner.
func _test_a_press_on_the_pause_button_is_not_also_a_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls.visible = true

	controls._input(_touch_event(0, TouchControls.PAUSE_CENTRE, true))
	t.check(controls._pause_touch == 0, "the press is caught by the button")
	t.check(not controls._walking, "and is not read as a direction toward the corner")

	controls._input(_touch_event(0, TouchControls.PAUSE_CENTRE, false))
	Input.action_release(&"pause")
	controls.free()
	rig.free()

## **A left click on a visible pause button presses it, not the corner underneath it.** The button
## is drawn on every device now, so a desktop mouse click has to be checked against it exactly as a
## finger's press already was — see `_on_pointer()`'s own doc for why the mouse path was folded
## into the same function that already tracked a touch index.
func _test_a_mouse_click_on_the_pause_button_is_not_also_a_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = false
	controls.visible = true

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = TouchControls.PAUSE_CENTRE
	controls._input(click)
	t.check(not controls._walking, "a click on the button is not read as a direction toward the corner")

	var release := click.duplicate()
	release.pressed = false
	controls._input(release)
	t.check(controls._pause_touch == -1, "and releasing on it lets go of the button's own hold")

	Input.action_release(&"pause")
	controls.free()
	rig.free()

## **Only while the button is actually drawn.** `visible` is the gate, not the device — a press in
## the same corner while the button is hidden (paused, or before the first `_process()` call) is an
## ordinary direction press, not a dead zone nobody can walk into.
func _test_the_corner_is_an_ordinary_direction_press_where_the_button_is_not_drawn(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = false

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = TouchControls.PAUSE_CENTRE
	controls._input(click)
	t.check(controls._walking, "a press in the corner sets a direction when no button is drawn there")

	controls.free()
	rig.free()

## *(2026-09-06: "there is no way to walk slowly -- that is intentional -- there should only ever
## be one speed (plus a second via running)".)* The drag stick was the one input path that could
## press a partial vector — `offset.limit_length(STICK_RADIUS) / STICK_RADIUS` walked her at less
## than `Tuning.WALK_SPEED` whenever a thumb rested short of the stick's own rim, which is exactly
## the gap every pursuit lead time in `src/autoload/tuning.gd` is computed assuming cannot exist.
## With the stick deleted, `set_direction()`'s own heading is the only vector any press can produce,
## and `heading_to()` always normalises — so this asks the real entry point, across a full circle of
## targets, whether the actions it ends up pressing ever combine to less than a unit vector.
func _test_no_input_path_presses_a_vector_shorter_than_one(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)

	for degrees in range(0, 360, 15):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(float(degrees)))
		controls.set_direction(direction * 200.0, false)
		var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		t.check(pressed.length() >= 1.0 - 0.001,
				"a press at %d degrees still presses a full unit vector (got length %.4f)"
						% [degrees, pressed.length()])

	controls.free()
	rig.free()

## PLAYTEST-57: *"arrow keys should reset any mouse click position. when pressing awsd or arrow
## keys right now the last pressed mouse position is still active resulting in incorrect /
## drifting movement."* A click locks a heading in by pressing `move_*` actions synthetically, and
## `Stroller` reads the same four actions through `Input.get_vector()`, which sums over whoever is
## pressing them — so without the reset, a key held after a click would add to the click rather
## than replace it. The resulting vector has to be the key's alone.
func _test_a_keyboard_press_resets_a_clicked_heading(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = false

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = controls.get_viewport().get_canvas_transform() * Vector2(0.0, -100.0)
	controls._input(click)
	t.check(Input.is_action_pressed("move_up"), "the click itself walks north first")

	# The real trap this fix survives: the engine updates an action's own polled state before
	# dispatching the event that changed it to any node's `_input()` — reproduced by hand here,
	# since a bare `controls._input(key)` call never reaches `Input.parse_input_event()`'s own
	# queue (nothing here is a real propagated event), so nothing would otherwise mark `move_right`
	# pressed at all. See `_yield_to_the_keyboard()`'s own doc for why the fix cannot simply release
	# every `move_*` action it finds pressed.
	Input.action_press(&"move_right")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	controls._input(key)

	var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	t.check(pressed.is_equal_approx(Vector2.RIGHT),
			("the key's own direction alone, not the click's north added to the key's east "
			+ "(got %s)") % pressed)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.RIGHT),
			"the drawn focus knob reads the key's own heading now, not the stale click's north")

	Input.action_release(&"move_right")
	controls.free()
	rig.free()

## **Pure geometry, no viewport needed** — the same shape `heading_to()`/`is_double_tap()` are
## tested in. *(2026-10-10, the player: "instead of splitting the in middle we can move it closer to
## the run button; although I wouldn't go all the way".)* The steering half reaches two thirds of
## the way to Run's focus, mirrored for either side, and stops short of Run's own disc.
func _test_the_steering_half_reaches_two_thirds_toward_run(t) -> void:
	var left := TouchControls.FOCUS_LEFT
	var right := TouchControls.FOCUS_RIGHT
	t.check(is_equal_approx(TouchControls.boundary_x(left), left.x + (right.x - left.x) * 2.0 / 3.0),
			"with the left side steering, the edge is two thirds of the way to the right focus "
			+ "(got %.2f)" % TouchControls.boundary_x(left))
	t.check(is_equal_approx(TouchControls.boundary_x(right), right.x - (right.x - left.x) * 2.0 / 3.0),
			"and mirrored with the right side steering (got %.2f)" % TouchControls.boundary_x(right))
	t.check(TouchControls.boundary_x(left) + TouchControls.RING_RADIUS
			< right.x - TouchControls.RUN_RADIUS,
			"the stop band ends short of Run's painted disc: not all the way")
	for steering: Vector2 in [left, right]:
		var edge := TouchControls.boundary_x(steering)
		var toward_run := signf(TouchControls.run_focus_for(steering).x - steering.x)
		t.check(not TouchControls.is_on_run_side(Vector2(edge - toward_run * 0.5, 300.0), steering),
				"half a pixel short of the edge is still steering's")
		t.check(TouchControls.is_on_run_side(Vector2(edge + toward_run * 0.5, 300.0), steering),
				"half a pixel past it is Run's")
		t.check(not TouchControls.is_on_run_side(Vector2(640.0, 480.0), steering),
				"the middle of the screen now belongs to steering, on either side")
		t.check(TouchControls.is_on_run_side(TouchControls.run_focus_for(steering), steering)
				and not TouchControls.is_on_run_side(steering, steering),
				"Run's own focus is on Run's side, and the steering focus is not")

## The dead zone surrounds the steering focus only, tighter than the ring drawn around it.
## *(2026-10-10, the player: "decrease the deadzone of the joystick (which makes the player stop)
## smaller/tighter".)*
func _test_the_dead_zone_is_tighter_than_the_ring_and_only_on_steering(t) -> void:
	var left := TouchControls.FOCUS_LEFT
	t.check(TouchControls.DEAD_ZONE_RADIUS < TouchControls.RING_RADIUS,
			"the dead zone is tighter than the ring drawn around it")
	t.check(TouchControls.in_dead_zone(left, left), "dead on the steering focus stops")
	t.check(TouchControls.in_dead_zone(left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 0.99, left),
			"just inside the dead zone stops")
	t.check(not TouchControls.in_dead_zone(left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 1.01,
			left), "just outside it, still inside the ring, does not")
	t.check(not TouchControls.in_dead_zone(TouchControls.FOCUS_RIGHT, left),
			"Run's focus has no dead zone")
	t.check(is_equal_approx(TouchControls.TAP_STOP_RADIUS * 2.0, TouchControls.DEAD_ZONE_RADIUS),
			"tap mode's stop circle covers the dead zone on screen at the camera's zoom of 2, "
			+ "nothing bigger (playtest 34 finding 5)")

## Pure geometry, no viewport needed. *(2026-09-07: "there should be a narrow band in the middle of
## the screen (size of the stop circle) that stops the player".)* The band moved to the steering
## half's edge and kept the ring's diameter as its width.
func _test_the_stop_band_sits_on_the_steering_edge(t) -> void:
	for steering: Vector2 in [TouchControls.FOCUS_LEFT, TouchControls.FOCUS_RIGHT]:
		var edge := TouchControls.boundary_x(steering)
		t.check(TouchControls.is_in_stop_band(Vector2(edge, 0.0), steering)
				and TouchControls.is_in_stop_band(Vector2(edge, 719.0), steering),
				"on the edge, at any height, is in the band")
		t.check(TouchControls.is_in_stop_band(Vector2(edge - TouchControls.RING_RADIUS * 0.99, 360.0),
				steering) and TouchControls.is_in_stop_band(
				Vector2(edge + TouchControls.RING_RADIUS * 0.99, 360.0), steering),
				"just inside RING_RADIUS either side of the edge is in the band")
		t.check(not TouchControls.is_in_stop_band(
				Vector2(edge - TouchControls.RING_RADIUS * 1.01, 360.0), steering),
				"just past that is an ordinary direction press; the band does not grow")
		t.check(not TouchControls.is_in_stop_band(Vector2(640.0, 360.0), steering),
				"and the middle of the screen is no longer a band")

## **The reach the focal points exist to fix.** *(2026-09-06, the player: "right now the finger
## needs to reach over half the phone to be able to input an up or down direction".)* A press west
## of the steering focus walks west, and above it walks north, no matter where she is standing —
## the direction does not depend on where she is. Either side steers the same way once the title
## has chosen it.
func _test_a_touch_aims_from_the_steering_focus_not_from_her(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT)

	# West of the left focus, in the design box `_on_tap()` reads a non-rotated press in directly.
	controls._on_tap(TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), 0.0)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a press west of the left focus walks west, regardless of where she is standing")
	t.check(not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and not north or south, since the press is due west of the focus")

	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	controls._on_tap(TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), 1.0)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and with the right side steering, a press above the right focus walks north")

	controls.free()
	rig.free()

## **The steering ring's knob shows the heading she is walking.** *(2026-09-27, playtest
## olive-koala statement 6: "the onscreen controls should show the selected direction on both sides
## always. when using hands and when using the keyboard".)* One ring steers now, so "both sides" is
## that ring: `_draw_focus_circles()` reads `current_heading()` for its knob, so a press through the
## steering focus has to move it the same way `Input.is_action_pressed()` shows the press moved.
func _test_current_heading_matches_a_press_through_the_steering_focus(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT)

	controls._on_tap(TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), 0.0)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.LEFT),
			"a press west of the left focus is what the knob now shows")

	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	controls._on_tap(TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), 1.0)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.UP),
			"and a press above the right focus, with the right side steering, the same way")

	controls.free()
	rig.free()

## **Zero while she is detained, even with a key still held.** Found in review of #412:
## `current_heading()` did not gate on `Stroller.is_detained()`, so a key held through a
## conversation or a capture kept swinging the knob toward it even though
## `Stroller._physics_process()` itself already ignores `Input.get_vector()` for exactly that
## reason (`_detained_for > 0.0`) — the one thing `current_heading()`'s own doc promises never
## happens, disagreeing with what she is actually doing. A bare `Stroller.new()` is enough:
## `detain()` and `is_detained()` touch only `_detained_for`, no `@onready` node this rig — never
## added to the tree — would have nothing to resolve.
func _test_current_heading_reads_zero_while_detained(t) -> void:
	var stroller := Stroller.new()
	# A clean slate rather than trusting whatever the previous test left pressed: this test
	# presses `move_right` directly, on its own, rather than through `set_direction()` (which
	# resets both axes itself), so it is the one test in this file that would otherwise read
	# whatever a neighbour's own leftover diagonal happened to be.
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)
	Input.action_press(&"move_right")

	t.check(TouchControls.current_heading().is_equal_approx(Vector2.RIGHT),
			"not detained, so the held key is what the knob would draw, same as everywhere else")
	t.check(TouchControls.current_heading(stroller).is_equal_approx(Vector2.RIGHT),
			"and passing a rig that says it is not detained changes nothing")

	stroller.detain(5.0)
	t.check(TouchControls.current_heading(stroller).is_equal_approx(Vector2.ZERO),
			"detained, so the knob reads stopped no matter what is still held")

	Input.action_release(&"move_right")
	stroller.free()

func _test_a_press_at_a_focus_centre_stops_her_on_touch(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls.set_direction(Vector2(100.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	controls._on_tap(TouchControls.FOCUS_LEFT, 0.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"a press dead on a focus stops her")

	controls.free()
	rig.free()

## **The world-space door is gone in `Mode.JOYSTICK`, replaced by the band.** *(2026-09-06, the
## player: "tapping in their center or on the player should stop the player still" — the finding
## M83 built this test for. 2026-09-07, overturning it: "with that we can remove tap the player to
## stop since it's the same area and if a movement accidentally goes over the player it might
## become surprising to see her stop".)* A press near her own world position, off the dead zone and
## off the band, walks away from the steering focus instead of stopping.
func _test_a_touch_near_her_own_position_no_longer_stops_her(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	controls.set_direction(Vector2(400.0, 300.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# Well away from the dead zone and the band in design space, and within world-space reach of
	# her -- the exact case the deleted door used to catch.
	controls._on_tap(transform * Vector2(310.0, 300.0), 1.0)
	t.check(controls._walking,
			"a press near her steers from the focus instead of stopping")
	t.check(controls._direction.is_equal_approx(TouchControls.heading_to(
			Vector2(310.0, 300.0), TouchControls.FOCUS_LEFT)),
			"measured from FOCUS_LEFT, the steering focus")

	controls.free()
	rig.free()

## **`Mode.TAP` aims from her regardless of the device that sent the click.** *(2026-09-06, the
## player: "that two focal point mode should only exist for the touch enabled version not the mouse
## version where the direction uses the player as reference" — read now as the mode, not the
## hardware, the player asked to keep separate: see `docs/DECISIONS.md` under M88.)* Driven through
## `_input()` rather than `_on_tap()` directly, so this also exercises the hardware routing a mouse
## click takes on a non-touch device (`_touch = false`) — the two are independent, and both are set
## explicitly here so the test does not lean on either one's default.
func _test_a_mouse_click_still_aims_from_her_not_a_focus(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = false
	controls._mode = ControlsMode.Mode.TAP
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = transform * (rig.global_position + Vector2(200.0, 0.0))
	controls._input(click)
	t.check(Input.is_action_pressed("move_right"),
			"a mouse click still aims from her own position, not from a focus, even here")

	controls.free()
	rig.free()

## **A held finger keeps re-aiming, and the direction it presses is still a full unit vector at
## every step** — the same guarantee `_test_no_input_path_presses_a_vector_shorter_than_one` holds
## for a single press, now asked of the drag that replaces the stick, since a drag is the other new
## path that could in principle press a partial vector and does not. *(2026-09-07: "dragging the
## finger doesn't work anymore but should".)*
func _test_a_touch_drag_updates_the_heading_and_still_presses_a_unit_vector(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true))
	t.check(Input.is_action_pressed("move_left"), "the press itself walks west of the focus")
	t.check(controls._drag_pointer_index == 0, "and the same finger is now tracked for the drag")

	for degrees in range(0, 360, 30):
		var offset := Vector2.RIGHT.rotated(deg_to_rad(float(degrees))) * 150.0
		controls._input(_drag_event(0, TouchControls.FOCUS_LEFT + offset))
		var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		t.check(pressed.length() >= 1.0 - 0.001,
				"a drag at %d degrees around the focus still presses a full unit vector (got %.4f)"
						% [degrees, pressed.length()])

	controls._input(_drag_event(0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0)))
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"),
			"the last drag step, due east of the focus, is what is currently held")

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), false))
	t.check(controls._drag_pointer_index == -1, "lifting the finger stops tracking the drag")
	t.check(Input.is_action_pressed("move_right"),
			"and the direction locks in as it stood, unrenewed by the release itself")

	controls.free()
	rig.free()

## **A press dead on a focus stops her, and now also starts a tracked drag** — the rule that used
## to be deleted was "a stop does not start a drag," not the stop itself. *(Playtest 34 finding 8:
## "when I start dragging from the center of the joystick nothing happens it should behave the same
## as if I move to the center and back stop while I'm in the center and move when I'm back.")*
func _test_a_press_at_a_focus_centre_starts_a_drag_that_can_leave_and_return(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT, true))
	t.check(not controls._walking, "a press dead on a focus still stops her")
	t.check(controls._drag_pointer_index == 0,
			"but the same finger is now tracked, where it used to be dropped entirely")

	controls._input(_drag_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0)))
	t.check(controls._walking and Input.is_action_pressed("move_left"),
			"dragging out of the centre starts walking that way")

	controls._input(_drag_event(0, TouchControls.FOCUS_LEFT))
	t.check(not controls._walking and not Input.is_action_pressed("move_left"),
			"and dragging back into the centre stops her again, live")

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT, false))
	controls.free()
	rig.free()

## **`Mode.TAP`'s one door gets the same live crossing `Mode.JOYSTICK`'s two get** — the general
## reading of finding 8's "crossing the boundary either way changes it live" applied to the door
## `_near_her()` answers rather than only to a focus.
func _test_a_tap_mode_drag_stops_and_resumes_crossing_her_own_stop_radius(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := _controls(t)
	controls._touch = false
	controls._mode = ControlsMode.Mode.TAP
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = transform * Vector2(500.0, 300.0)
	controls._input(click)
	t.check(Input.is_action_pressed("move_right"), "the click itself walks east of her")

	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	# Within TAP_STOP_RADIUS (16px) of the centre of her sprite (300, 277 -- TAP_STOP_CENTRE_LIFT
	# above her feet at 300, 300), not of her feet.
	motion.position = transform * Vector2(310.0, 280.0)
	controls._input(motion)
	t.check(not controls._walking and not Input.is_action_pressed("move_right"),
			"dragging back near the centre of her stops her live")

	motion.position = transform * Vector2(500.0, 300.0)
	controls._input(motion)
	t.check(controls._walking and Input.is_action_pressed("move_right"),
			"and dragging back out resumes steering")

	var release := click.duplicate()
	release.pressed = false
	release.position = transform * Vector2(500.0, 300.0)
	controls._input(release)
	controls.free()
	rig.free()

## **A double tap that then drags holds `run` the same way a double tap already does.**
## *(2026-09-07: "A double press that then drags holds run the same way a double press already
## does".)*
func _test_a_double_tap_that_then_drags_keeps_running(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true))
	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), false))
	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true))
	t.check(Input.is_action_pressed("run"), "the double tap itself runs")

	controls._input(_drag_event(0, TouchControls.FOCUS_LEFT + Vector2(0.0, -150.0)))
	t.check(Input.is_action_pressed("run"), "and dragging afterward keeps holding run")
	t.check(Input.is_action_pressed("move_up"), "while the heading itself keeps updating")

	controls.free()
	rig.free()

## **`Mode.TAP`'s own half of the drag.** *(2026-09-07: "although dragging a mouse should reaim as
## well".)* Its origin is her own position, not a focus — the one place the two modes keep
## disagreeing — read live on every motion event.
func _test_a_mouse_drag_reaims_from_her_own_position(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := _controls(t)
	controls._touch = false
	controls._mode = ControlsMode.Mode.TAP
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = transform * Vector2(500.0, 300.0)
	controls._input(click)
	t.check(Input.is_action_pressed("move_right"), "the click itself walks east of her")

	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = transform * Vector2(300.0, 100.0)
	controls._input(motion)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_right"),
			"dragging the held button re-aims from her own position, not a fixed focus")

	var release := click.duplicate()
	release.pressed = false
	release.position = transform * Vector2(300.0, 100.0)
	controls._input(release)
	t.check(controls._drag_pointer_index == -1, "releasing the button stops tracking the drag")

	controls.free()
	rig.free()

## A mouse simply moving, with no button held, is not a drag — `button_mask` is what tells the two
## apart, and every ordinary mouse movement in the game carries no mask at all.
func _test_a_mouse_motion_without_the_button_held_does_nothing(t) -> void:
	# Leftover state from the previous test's own drag, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._touch = false

	var motion := InputEventMouseMotion.new()
	motion.button_mask = 0
	motion.position = Vector2(999.0, 999.0)
	controls._input(motion)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left")
			and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"idle mouse movement never sets a direction")

	controls.free()
	rig.free()

## A press in the band at the steering half's edge stops her in `Mode.JOYSTICK`, the other door
## into `_stop()` beside the dead zone. *(2026-09-07: "there should be a narrow band in the middle of
## the screen ... that stops the player".)*
func _test_a_tap_in_the_stop_band_stops_her_on_touch(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	controls._on_tap(TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), 0.0)
	t.check(Input.is_action_pressed("move_left"), "walking first, so a stop has something to undo")

	controls._on_tap(Vector2(TouchControls.boundary_x(TouchControls.FOCUS_LEFT) - 10.0, 200.0), 1.0)
	t.check(not Input.is_action_pressed("move_left") and not controls._walking,
			"a press in the band at the steering edge stops her rather than steering")

	controls.free()
	rig.free()

## **A steering drag into the band stops her, and one carried on past it onto Run's half steers
## again from the same focus.** The sides never swap in play *(2026-10-10, the player: "we don't
## allow switching joystick and run key")*, so the pointer keeps the role its press gave it: it
## neither takes Run nor moves the ring.
func _test_a_drag_past_the_band_keeps_steering_from_the_same_side(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls.visible = true
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var edge := TouchControls.boundary_x(TouchControls.FOCUS_LEFT)

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true))
	t.check(Input.is_action_pressed("move_left"), "the press itself walks west of the focus")

	controls._input(_drag_event(0, Vector2(edge, 480.0)))
	t.check(not controls._walking, "dragging into the band stops her")

	controls._input(_drag_event(0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0)))
	t.check(controls._walking and Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_left"),
			"carried on onto Run's half, it steers again from the left focus, toward the pointer")
	t.check(not controls._run_held and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"without taking Run or moving Run's disc")

	controls._input(_touch_event(0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), false))
	t.check(controls._walking and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"and lifting there leaves her walking with the sides as they were")
	controls.free()
	rig.free()
	_release_actions()

## **The title's side holds from the first frame of play and nothing in play moves it.**
## *(2026-10-10, the player: "selecting the left one will make the left side permanently joystick
## and the right side permanently run button (permanently for the sitting). vice versa on the right
## side.")* Before any press Run is already on screen, a key picks no side, and a press anywhere
## on Run's half — on the disc or well off it, in either presentation — holds Run and never steers.
func _test_a_press_on_runs_side_never_steers(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
		var steering := TouchControls.FOCUS_RIGHT if side == ControlsMode.Side.RIGHT \
				else TouchControls.FOCUS_LEFT
		var run := TouchControls.run_focus_for(steering)
		var toward_run := signf(run.x - steering.x)
		for rotate: bool in [false, true]:
			var controls := _controls(t)
			controls.visible = true
			controls.rotated = rotate
			controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
			t.check(controls.run_button_center() == run,
					"Run is on the far side from the first frame (side=%d rotated=%s)" % [side, rotate])
			var key := InputEventKey.new()
			key.keycode = KEY_D
			key.pressed = true
			controls._input(key)
			t.check(controls.run_button_center() == run, "a key picks no side")
			controls._input(_touch_event(0, ScreenOrientation.to_presented_space(
					steering + Vector2(0.0, -100.0), rotate), true))
			controls._input(_touch_event(0, ScreenOrientation.to_presented_space(
					steering + Vector2(0.0, -100.0), rotate), false))
			t.check(controls._walking,
					"a tap above the steering focus walks (the heading's own direction under a "
					+ "rotated presentation is test_orientation's)")
			var heading := controls._direction
			var off_the_disc := Vector2(TouchControls.boundary_x(steering) + toward_run, 150.0)
			for at: Vector2 in [run, run + Vector2(0.0, -100.0), off_the_disc]:
				var pressed_at := ScreenOrientation.to_presented_space(at, rotate)
				controls._input(_touch_event(1, pressed_at, true))
				t.check(controls._run_held and controls._direction == heading
						and controls._drag_pointer_index == -1,
						"a press at %s on Run's half holds Run and never steers" % at)
				controls._input(_drag_event(1, ScreenOrientation.to_presented_space(steering, rotate)))
				t.check(controls._direction == heading,
						"and dragging that finger over the steering focus does not steer either")
				controls._input(_touch_event(1, pressed_at, false))
				t.check(controls.run_button_center() == run and controls._direction == heading,
						"releasing it leaves both the heading and the sides as they were")
			controls.free()
			_release_actions()
	rig.free()

## **A swipe through the dead zone keeps her walking toward where it lands; one that lands inside
## stops her.** *(2026-10-10, the player: "make sure swiping over it but landing outside of it
## correctly keeps the player moving in the direction of the final position".)* A fast swipe can
## lift with its last motion event inside the dead zone, so the release's own position decides.
func _test_a_swipe_through_the_dead_zone_lands_on_its_release(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var focus := TouchControls.FOCUS_LEFT

	controls._input(_touch_event(0, focus + Vector2(-150.0, 0.0), true))
	controls._input(_drag_event(0, focus + Vector2(-5.0, 2.0)))
	t.check(not controls._walking, "the swipe's last motion event is inside the dead zone")
	controls._input(_touch_event(0, focus + Vector2(150.0, 0.0), false))
	t.check(controls._walking and Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_left"),
			"lifting outside it walks toward the release point, east of the focus")
	t.check(controls._drag_pointer_index == -1, "and the drag is over")

	controls._input(_touch_event(0, focus + Vector2(0.0, -150.0), true))
	controls._input(_drag_event(0, focus + Vector2(0.0, -60.0)))
	t.check(controls._walking and Input.is_action_pressed("move_up"),
			"a second drag walks north, outside the dead zone")
	controls._input(_touch_event(0, focus + Vector2(TouchControls.DEAD_ZONE_RADIUS * 0.5, 0.0), false))
	t.check(not controls._walking and not Input.is_action_pressed("move_up"),
			"lifting inside the dead zone, with no motion event there, stops her")

	controls.free()
	rig.free()
	_release_actions()

## A rig that skips the title chooses the side with `--controls` (or `?controls=`), since nothing
## else can reach the right-steering layout without a press on the title.
func _test_a_rig_word_names_the_side(t) -> void:
	for word: String in ["joystick", "joystick-left", "joystick-right"]:
		t.check(ControlsMode.from_word(word) == ControlsMode.Mode.JOYSTICK,
				"'%s' is the joystick scheme" % word)
	t.check(ControlsMode.side_from_word("joystick-right") == ControlsMode.Side.RIGHT,
			"'joystick-right' steers from the right")
	for word: String in ["joystick", "joystick-left", "tap", ""]:
		t.check(ControlsMode.side_from_word(word) == ControlsMode.Side.LEFT,
				"'%s' steers from the left" % word)
	t.check(ControlsMode.from_word("tap") == ControlsMode.Mode.TAP, "'tap' is still the tap scheme")

## Pause's catch is its old 46px, past the 5% rim (27.3px); the dead zone does not grow at all.
func _test_round_button_margins_and_unchanged_dead_zones(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	for rotate in [false, true]:
		var controls := _controls(t)
		controls.visible = true
		controls.set_mode(ControlsMode.Mode.JOYSTICK)
		controls.rotated = rotate
		var catch_ratio := TouchControls.PAUSE_CATCH_RADIUS / TouchControls.PAUSE_RADIUS
		for ratio: float in [1.051, catch_ratio - 0.01, catch_ratio + 0.01]:
			var pause_at := ScreenOrientation.to_presented_space(TouchControls.PAUSE_CENTRE
					+ Vector2.LEFT * TouchControls.PAUSE_RADIUS * ratio, rotate)
			controls._input(_touch_event(2, pause_at, true))
			t.check((controls._pause_touch == 2) == (ratio < catch_ratio),
					"pause shares the catch for press")
			t.check(TouchControls._pause_fires(ScreenOrientation.to_design_space(pause_at, rotate))
					== (ratio < catch_ratio), "pause release uses the same catch")
			controls._input(_touch_event(2, Vector2.ZERO, false))
		var edge := TouchControls.FOCUS_LEFT + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 1.01
		controls._input(_touch_event(0, ScreenOrientation.to_presented_space(edge, rotate), true))
		t.check(controls._walking, "a press 1% beyond the dead zone still steers")
		controls._input(_touch_event(0, ScreenOrientation.to_presented_space(edge, rotate), false))
		controls.free()
		_release_actions()
	rig.free()

## A run pointer never steers and a steering pointer never takes Run, however they travel.
func _test_pointer_roles_hold_wherever_the_pointers_travel(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls.visible = true
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var left := TouchControls.FOCUS_LEFT
	var right := TouchControls.FOCUS_RIGHT
	controls._input(_touch_event(0, left + Vector2.UP * 100.0, true))
	var tap_clock := controls._last_tap_at
	controls._input(_touch_event(1, right, true))
	t.check(controls._run_held and controls._drag_pointer_index == 0
			and controls._last_tap_at == tap_clock, "Run leaves steering and double-tap clock alone")
	controls._input(_drag_event(0, Vector2(TouchControls.boundary_x(left), 480.0)))
	t.check(not controls._walking and Input.is_action_pressed("run"), "band stops while Run stays held")
	controls._input(_drag_event(0, right + Vector2.DOWN * 100.0))
	t.check(controls._walking and controls.run_button_center() == right,
			"steering onto Run's half steers without moving the disc")
	var heading := controls._direction
	controls._input(_drag_event(1, left + Vector2.UP * 100.0))
	t.check(controls._direction == heading and controls._drag_pointer_index == 0,
			"the run finger dragged onto the steering half does not steer")
	controls._input(_touch_event(2, right, true))
	controls._input(_touch_event(1, left, false))
	t.check(Input.is_action_pressed("run"), "another run finger can take over the hold")
	controls._input(_touch_event(2, right, false))
	t.check(not Input.is_action_pressed("run") and controls._walking,
			"last run release leaves steering intact")
	controls._input(_touch_event(0, right + Vector2.DOWN * 100.0, false))
	t.check(controls._walking and not controls._run_held,
			"the steering finger lifting on Run's half never took Run")
	controls.free()
	rig.free()
	_release_actions()

func _test_a_run_button_does_not_cancel_a_double_press_latch(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls.visible = true
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var at := TouchControls.FOCUS_LEFT + Vector2.UP * 100.0
	for _i in 2:
		controls._input(_click_event(at, true))
		controls._input(_click_event(at, false))
	t.check(controls._run_active and Input.is_action_pressed("run"), "mouse double click latches Run")
	controls._input(_touch_event(1, TouchControls.FOCUS_RIGHT, true))
	controls._input(_touch_event(1, Vector2.ZERO, false))
	t.check(Input.is_action_pressed("run"), "run hold release preserves the independent latch")
	controls.free()
	rig.free()
	_release_actions()

## Pause preserves the sides and locked heading, but never revives a pointer hold; a change of
## scheme or side lets go of everything.
func _test_pause_hide_and_mode_changes_release_holds(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls.visible = true
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var at := TouchControls.FOCUS_LEFT + Vector2.UP * 100.0
	controls._input(_touch_event(0, at, true))
	controls._input(_touch_event(1, TouchControls.FOCUS_RIGHT, true))
	controls.remember_before_pause()
	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not controls._run_held and controls._drag_pointer_index == -1,
			"pause cancels every pointer owner")
	t.get_tree().paused = false
	controls._process(0.0)
	controls.resume_after_pause()
	t.check(controls._walking and not Input.is_action_pressed("run")
			and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"resume restores heading and sides without the run finger")
	controls._input(_drag_event(1, at))
	t.check(controls._drag_pointer_index == -1, "old finger motion after pause cannot acquire steering")
	controls._input(_touch_event(1, TouchControls.FOCUS_RIGHT, true))
	controls.hide()
	t.check(not controls._run_held and not controls._walking, "hiding releases held input")
	controls.show()
	controls._input(_touch_event(1, TouchControls.FOCUS_RIGHT, true))
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	t.check(not controls._run_held and controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"a change of side releases Run and moves its disc")
	controls._input(_touch_event(1, TouchControls.FOCUS_LEFT, true))
	controls.set_mode(ControlsMode.Mode.TAP)
	t.check(not controls._run_held and controls.run_button_center() == Vector2.INF,
			"mode change releases Run and removes its disc")
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	t.check(controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"returning to joystick has Run on screen at once")
	controls.free()
	rig.free()
	_release_actions()

func _click_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = pressed
	return event

func _touch_event(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event

func _drag_event(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event

## However a check above failed or passed, the movement actions, `run` and `pause` are global
## `Input` state — nothing about them is scoped to this suite's own nodes — so a failure that
## returns early must not leave one pressed for whatever test runs next.
func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
	Input.action_release(&"pause")
