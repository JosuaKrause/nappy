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
	_test_a_mouse_click_stands_in_for_a_tap(t)
	_test_a_touch_devices_own_emulated_click_is_ignored(t)
	_test_a_press_on_the_pause_button_is_not_also_a_direction(t)
	_test_a_mouse_click_on_the_pause_button_is_not_also_a_direction(t)
	_test_the_corner_is_an_ordinary_direction_press_where_the_button_is_not_drawn(t)
	_test_no_input_path_presses_a_vector_shorter_than_one(t)
	_test_nearer_focus_is_picked_on_each_half(t)
	_test_is_on_a_focus_catches_the_stop_radius_around_either_point(t)
	_test_a_touch_aims_from_the_nearer_focus_not_from_her(t)
	_test_a_press_at_a_focus_centre_stops_her_on_touch(t)
	_test_a_touch_near_her_own_position_no_longer_stops_her(t)
	_test_a_mouse_click_still_aims_from_her_not_a_focus(t)
	_test_a_touch_drag_updates_the_heading_and_still_presses_a_unit_vector(t)
	_test_a_stop_press_does_not_start_a_drag(t)
	_test_a_double_tap_that_then_drags_keeps_running(t)
	_test_a_mouse_drag_reaims_from_her_own_position(t)
	_test_a_mouse_motion_without_the_button_held_does_nothing(t)
	_test_is_in_stop_band_catches_the_middle_and_only_the_middle(t)
	_test_a_tap_in_the_stop_band_stops_her_on_touch(t)
	_test_a_drag_that_crosses_the_band_stops_her_rather_than_steering_her(t)
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
	controls.queue_free()

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

	controls.queue_free()

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
	controls.queue_free()

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

	controls.queue_free()
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
	controls.queue_free()
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

	controls.queue_free()
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

	controls.queue_free()
	rig.free()

## **The generous radius, not the exact pixel — and `Mode.TAP` only now.** *(2026-09-06: "also,
## to stop her just click on her".)* `STOP_RADIUS` is wide enough to catch a click on the pram,
## which rides up to `PRAM_DISTANCE` off to one side of her, not only a click on her own exact
## world position. *(2026-09-07: "mouse click doesn't have the band and will keep the click the
## player to stop behavior".)* Replaces the old, device-agnostic version of this test rather than
## sitting beside it — the `Mode.JOYSTICK` half of what it asserted is now
## `_test_a_touch_near_her_own_position_no_longer_stops_her`, further down.
func _test_a_mouse_click_within_the_stop_radius_of_her_stops_her(t) -> void:
	var rig := _rig_at(t, Vector2(200.0, 200.0))
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.TAP
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	controls._on_tap(transform * Vector2(500.0, 200.0), 0.0)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# 30px off her own position -- within STOP_RADIUS (48px), covering the pram at PRAM_DISTANCE
	# (34px) as well as her own PLAYER_BODY_RADIUS (14px).
	controls._on_tap(transform * Vector2(230.0, 200.0), 1.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"a click near her, not only exactly on her, stops her")

	# Well outside the radius sets a direction instead.
	controls._on_tap(transform * Vector2(500.0, 200.0), 2.0)
	t.check(Input.is_action_pressed("move_right") and controls._walking,
			"a click outside the stop radius sets a direction instead")

	controls.queue_free()
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

	controls.queue_free()
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

	controls.queue_free()
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

	controls.queue_free()
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
	controls.queue_free()
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
	controls.queue_free()
	rig.free()

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

	controls.queue_free()
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

	controls.queue_free()
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
	controls.queue_free()
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
	controls.queue_free()
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

	controls.queue_free()
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

	controls.queue_free()
	rig.free()

## **Pure geometry, no viewport needed** — the same shape `heading_to()`/`is_double_tap()` are
## tested in. *(2026-09-06, the player: "define two points equally apart from the border on each
## side ... whichever is closer to the touch".)*
func _test_nearer_focus_is_picked_on_each_half(t) -> void:
	t.check(TouchControls.nearer_focus(Vector2(100.0, 200.0)) == TouchControls.FOCUS_LEFT,
			"the left half of the design box picks the left focus")
	t.check(TouchControls.nearer_focus(Vector2(1200.0, 500.0)) == TouchControls.FOCUS_RIGHT,
			"and the right half picks the right focus")
	t.check(TouchControls.nearer_focus(TouchControls.FOCUS_LEFT) == TouchControls.FOCUS_LEFT,
			"a press right on a focus picks that one")
	t.check(TouchControls.nearer_focus(TouchControls.FOCUS_RIGHT) == TouchControls.FOCUS_RIGHT,
			"and the other focus, right on it")

## *(2026-09-06, the player: "tapping in their center ... should stop the player still".)*
func _test_is_on_a_focus_catches_the_stop_radius_around_either_point(t) -> void:
	t.check(TouchControls.is_on_a_focus(TouchControls.FOCUS_LEFT), "dead on the left focus stops")
	t.check(TouchControls.is_on_a_focus(TouchControls.FOCUS_RIGHT), "dead on the right focus stops")
	t.check(TouchControls.is_on_a_focus(TouchControls.FOCUS_LEFT + Vector2(10.0, 0.0)),
			"and near enough to it (within STOP_RADIUS) stops too")
	t.check(not TouchControls.is_on_a_focus(Vector2(640.0, 360.0)),
			"exactly between the two, past both radii, is neither")

## Pure geometry, no viewport needed — the same shape `is_on_a_focus()` is tested in.
## *(2026-09-07: "there should be a narrow band in the middle of the screen (size of the stop
## circle) that stops the player".)*
func _test_is_in_stop_band_catches_the_middle_and_only_the_middle(t) -> void:
	t.check(TouchControls.is_in_stop_band(Vector2(640.0, 0.0)), "dead centre, at any height, stops")
	t.check(TouchControls.is_in_stop_band(Vector2(640.0, 719.0)), "even right at the bottom edge")
	t.check(TouchControls.is_in_stop_band(Vector2(640.0 + TouchControls.STOP_RADIUS, 360.0)),
			"and STOP_RADIUS to either side, at the diameter's own edge")
	t.check(not TouchControls.is_in_stop_band(
			Vector2(640.0 + TouchControls.STOP_RADIUS + 1.0, 360.0)),
			"but just past that edge is an ordinary direction press")
	t.check(not TouchControls.is_in_stop_band(TouchControls.FOCUS_LEFT),
			"and neither focus itself is anywhere near the middle band")

## **The reach the two focal points exist to fix.** *(2026-09-06, the player: "right now the
## finger needs to reach over half the phone to be able to input an up or down direction".)* A
## press west of a focus walks west, and above it walks north, no matter where she is standing —
## the whole point of the two fixed points is that the direction no longer depends on where she is.
func _test_a_touch_aims_from_the_nearer_focus_not_from_her(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK

	# West of the left focus, in the design box `_on_tap()` reads a non-rotated press in directly.
	controls._on_tap(TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), 0.0)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a press west of the left focus walks west, regardless of where she is standing")
	t.check(not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and not north or south, since the press is due west of the focus")

	# Above (smaller y) the right focus.
	controls._on_tap(TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), 1.0)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and a press above the right focus walks north")

	controls.queue_free()
	rig.free()

func _test_a_press_at_a_focus_centre_stops_her_on_touch(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls.set_direction(Vector2(100.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	controls._on_tap(TouchControls.FOCUS_LEFT, 0.0)
	t.check(not Input.is_action_pressed("move_right") and not controls._walking,
			"a press dead on a focus stops her")

	controls.queue_free()
	rig.free()

## **The world-space door is gone in `Mode.JOYSTICK`, replaced by the band.** *(2026-09-06, the
## player: "tapping in their center or on the player should stop the player still" — the finding
## M83 built this test for. 2026-09-07, overturning it: "with that we can remove tap the player to
## stop since it's the same area and if a movement accidentally goes over the player it might
## become surprising to see her stop".)* The camera sits on her, so her own screen position already
## sits on the stop band's own centre line — covering the ground twice is what made a drag crossing
## her by accident stop her by surprise. A press near her own world position, off both focal points
## and off the band, now walks toward the nearer focus instead of stopping.
func _test_a_touch_near_her_own_position_no_longer_stops_her(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	controls.set_direction(Vector2(400.0, 300.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# Well away from either focus and the middle band in design space, and within the old
	# world-space STOP_RADIUS of her -- the exact case the deleted door used to catch.
	controls._on_tap(transform * Vector2(310.0, 300.0), 1.0)
	t.check(controls._walking,
			"a press near her walks toward the nearer focus instead of stopping")
	t.check(controls._direction.is_equal_approx(TouchControls.heading_to(
			Vector2(310.0, 300.0), TouchControls.FOCUS_LEFT)),
			"toward FOCUS_LEFT specifically, the nearer of the two")

	controls.queue_free()
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

	controls.queue_free()
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

	controls.queue_free()
	rig.free()

## **A press dead on a focus stops her, and does not also start a drag** that would only re-open
## the direction the press just closed the moment the same finger moves again.
func _test_a_stop_press_does_not_start_a_drag(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT, true))
	t.check(controls._drag_pointer_index == -1, "a stop press tracks no drag")

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT, false))
	controls.queue_free()
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

	controls.queue_free()
	rig.free()

## **`Mode.TAP`'s own half of the drag.** *(2026-09-07: "although dragging a mouse should reaim as
## well".)* Its origin is her own position, not a focus — the one place the two modes keep
## disagreeing — carried through every motion event exactly as `_drag_origin_world` recorded it at
## the click that started this drag.
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

	controls.queue_free()
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

	controls.queue_free()
	rig.free()

## A press dead in the middle of the screen stops her in `Mode.JOYSTICK`, the third door into
## `_stop()` beside a press on either focus. *(2026-09-07: "there should be a narrow band in the
## middle of the screen ... that stops the player".)*
func _test_a_tap_in_the_stop_band_stops_her_on_touch(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._on_tap(TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), 0.0)
	t.check(Input.is_action_pressed("move_left"), "walking first, so a stop has something to undo")

	controls._on_tap(Vector2(640.0, 200.0), 1.0)
	t.check(not Input.is_action_pressed("move_left") and not controls._walking,
			"a press in the middle band stops her rather than steering toward either focus")

	controls.queue_free()
	rig.free()

## **A drag that wanders into the band stops her rather than steering her**, which is the whole
## reason the band exists: without it, a finger drifting past the centre line would swap which
## focus it steers from and snap the heading to somewhere else entirely. Leaving the band resumes
## steering, since the door only closes while the finger is actually standing in it.
func _test_a_drag_that_crosses_the_band_stops_her_rather_than_steering_her(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := _controls(t)
	controls._touch = true
	controls._mode = ControlsMode.Mode.JOYSTICK

	controls._input(_touch_event(0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true))
	t.check(Input.is_action_pressed("move_left"), "the press itself walks west of the focus")

	controls._input(_drag_event(0, Vector2(660.0, 480.0)))
	t.check(not Input.is_action_pressed("move_left") and not controls._walking,
			"dragging into the band stops her rather than steering her toward the right focus")

	controls._input(_drag_event(0, TouchControls.FOCUS_RIGHT + Vector2(150.0, 0.0)))
	t.check(Input.is_action_pressed("move_right") and controls._walking,
			"and dragging back out of the band resumes steering, now from the nearer focus")

	controls.queue_free()
	rig.free()

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
