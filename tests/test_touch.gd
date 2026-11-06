extends RefCounted
## `TouchControls`' own geometry: that the pause button shows only where and when it should, that
## a finger on it presses the same real `pause` action a keyboard does, and that a press anywhere
## else — a finger or a mouse click — sets a direction, stops her, or runs it, exactly the parts a
## screenshot cannot check.
##
## Every press, lift and drag is an event pushed through the viewport (`Viewport.push_input()`, the
## route a real one takes) and a real frame let pass where the node's own `_process()` matters; what
## is read back is what the game reads: the `Input` actions `TouchControls` presses (the ones
## `Stroller` steers by), the `pause` action that reaches the tree, the knob's heading
## (`TouchControls.current_heading()`, which only the drawing reads) and the node's public answers. A headless test process is never a touch device, so a test
## that wants a device's gate hands it in (`use_touch()`), and the double-tap window runs on a clock
## the test moves by hand (`use_clock()`, as `ModeButton.use_clock()` is handed one).
##
## **The device and the scheme answer different questions.** `use_touch()` only decides which raw
## event type the node reads and whether a touch device's own emulated mouse click is ignored;
## `set_mode()` is what gives `Mode.JOYSTICK`'s focus-based aiming. See `ControlsMode`.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")
const UIScreens := preload("res://tests/ui_screens.gd")

## The hand-held clock the double-tap window is measured on, handed to `TouchControls.use_clock()`.
var _clock := UIScreens.FakeClock.new()

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
	await _test_process_mode_stays_always(t)
	await _test_the_button_shows_on_every_device_with_a_day_running(t)
	await _test_the_pause_button_sends_a_real_action_event(t)
	await _test_the_pause_button_fires_on_release_inside_and_not_outside(t)
	await _test_every_catch_is_at_least_five_percent_past_its_drawing_and_never_smaller_than_it_was(t)
	await _test_the_pause_button_tracks_its_own_touch_index(t)
	await _test_hiding_the_controls_releases_a_held_direction(t)
	await _test_a_tap_presses_the_components_of_its_heading(t)
	await _test_a_click_on_the_very_pixel_of_her_feet_stops_rather_than_pressing(t)
	await _test_a_mouse_click_within_the_stop_radius_of_her_stops_her(t)
	await _test_a_direction_stays_locked_in_with_nothing_held_down(t)
	await _test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t)
	await _test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t)
	await _test_a_tap_during_a_pause_does_nothing(t)
	await _test_a_pause_force_releases_a_held_direction(t)
	await _test_a_press_while_paused_is_never_the_first_heading(t)
	await _test_a_mouse_click_stands_in_for_a_tap(t)
	await _test_a_touch_devices_own_emulated_click_is_ignored(t)
	await _test_a_press_on_the_pause_button_is_not_also_a_direction(t)
	await _test_a_mouse_click_on_the_pause_button_is_not_also_a_direction(t)
	await _test_the_corner_is_an_ordinary_direction_press_where_the_button_is_not_drawn(t)
	await _test_no_input_path_presses_a_vector_shorter_than_one(t)
	await _test_a_keyboard_press_resets_a_clicked_heading(t)
	await _test_the_steering_half_reaches_two_thirds_toward_run(t)
	await _test_the_dead_zone_is_tighter_than_the_ring_and_only_on_steering(t)
	await _test_the_stop_band_sits_on_the_steering_edge(t)
	await _test_the_screen_cover_follows_the_scheme_in_force(t)
	await _test_a_touch_aims_from_the_steering_focus_not_from_her(t)
	await _test_current_heading_matches_a_press_through_the_steering_focus(t)
	_test_current_heading_reads_zero_while_detained(t)
	await _test_a_press_at_a_focus_centre_stops_her_on_touch(t)
	await _test_a_touch_near_her_own_position_no_longer_stops_her(t)
	await _test_a_mouse_click_still_aims_from_her_not_a_focus(t)
	await _test_a_touch_drag_updates_the_heading_and_still_presses_a_unit_vector(t)
	await _test_a_press_at_a_focus_centre_starts_a_drag_that_can_leave_and_return(t)
	await _test_a_tap_mode_drag_stops_and_resumes_crossing_her_own_stop_radius(t)
	await _test_a_double_tap_that_then_drags_keeps_running(t)
	await _test_a_mouse_drag_reaims_from_her_own_position(t)
	await _test_a_mouse_motion_without_the_button_held_does_nothing(t)
	await _test_a_tap_in_the_stop_band_stops_her_on_touch(t)
	await _test_a_drag_past_the_band_keeps_steering_from_the_same_side(t)
	await _test_a_press_on_runs_side_never_steers(t)
	await _test_a_swipe_through_the_dead_zone_lands_on_its_release(t)
	await _test_round_button_margins_and_unchanged_dead_zones(t)
	await _test_pointer_roles_hold_wherever_the_pointers_travel(t)
	await _test_a_run_button_does_not_cancel_a_double_press_latch(t)
	await _test_pause_hide_and_mode_changes_release_holds(t)
	t.get_tree().paused = was_paused
	_release_actions()

## A `TouchControls` in the tree with the double-tap clock handed in (`_clock`, a clock the test
## moves by hand) and, unless `settle` is false, two frames let pass so its own `_process()` has run
## and it shows. `settle` false is the node before its first frame: not yet drawn.
func _controls(t, settle := true) -> TouchControls:
	_clock = UIScreens.FakeClock.new()
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	controls.use_clock(_clock.read)
	t.add_child(controls)
	if settle:
		await UIScreens.frames(t)
	return controls

## Counts the `pause` actions that reach the tree, the way `main._unhandled_input()` hears one.
class PauseProbe extends Node:
	var events: Array[InputEvent] = []

	func _input(event: InputEvent) -> void:
		if event is InputEventAction and (event as InputEventAction).pressed \
				and (event as InputEventAction).action == &"pause":
			events.append(event)

func _probe(t) -> PauseProbe:
	var probe := PauseProbe.new()
	t.add_child(probe)
	return probe

## Presses on the button at its centre and lifts at `at`; whether a `pause` action reached the tree.
## `Input.parse_input_event()` buffers the action it sends, so the buffer is flushed to let the
## tree hear it before the count is read.
func _release_fires(controls: TouchControls, probe: PauseProbe, at: Vector2) -> bool:
	var before := probe.events.size()
	_finger(controls, 0, TouchControls.PAUSE_CENTRE, true)
	_finger(controls, 0, at, false)
	Input.flush_buffered_events()
	return probe.events.size() > before

## Moves the hand-held clock on, so the next press is not a double of the last one.
func _later() -> void:
	_clock.now += 10.0

func _finger(controls: TouchControls, index: int, at: Vector2, pressed: bool) -> void:
	UIScreens.push(controls, UIScreens.touch_at(at, pressed, index))

func _finger_drag(controls: TouchControls, index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = at
	UIScreens.push(controls, event)

func _click(controls: TouchControls, at: Vector2, pressed: bool) -> void:
	UIScreens.push(controls, UIScreens.mouse_at(at, pressed))

## A whole press and lift of the left button at `at`, a fresh tap and not a double of the last.
func _click_once(controls: TouchControls, at: Vector2) -> void:
	_later()
	_click(controls, at, true)
	_click(controls, at, false)

## The left button held and moving to `at`.
func _mouse_drag(controls: TouchControls, at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = at
	UIScreens.push(controls, motion)

## A screen point under the viewport's canvas transform for a world point: where a click lands on it.
func _screen(controls: TouchControls, world: Vector2) -> Vector2:
	return controls.get_viewport().get_canvas_transform() * world

## A whole double tap with the left button at the screen point `at`: two presses and lifts at one
## moment, inside the window and the distance a double tap needs, and a fresh pair and not a double
## of the last tap.
func _double_click(controls: TouchControls, at: Vector2) -> void:
	_later()
	for _i in 2:
		_click(controls, at, true)
		_click(controls, at, false)

## What the four movement actions add up to: the vector `Stroller` steers by.
func _pressed() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

## The other focus from `steering`: where Run's half is.
func _run_focus(steering: Vector2) -> Vector2:
	return TouchControls.FOCUS_LEFT if steering == TouchControls.FOCUS_RIGHT else TouchControls.FOCUS_RIGHT

## The x of the steering half's edge in the design box: two thirds of the way from the steering focus
## to Run's (the player's "I wouldn't go all the way", 2026-10-10).
func _edge(steering: Vector2) -> float:
	return lerpf(steering.x, _run_focus(steering).x, 2.0 / 3.0)

## Whether a fresh finger landing at the design point `at` holds Run, lifted again afterwards.
func _a_press_holds_run(controls: TouchControls, at: Vector2) -> bool:
	_later()
	_finger(controls, 7, at, true)
	var held := Input.is_action_pressed("run")
	_finger(controls, 7, at, false)
	return held

## A finger on the steering half well away from Run, lifted again: she walks the way it points. Leaves
## her walking, so that a stop has something to undo.
func _walk_first(controls: TouchControls, steering: Vector2) -> bool:
	var away := -signf(_run_focus(steering).x - steering.x)
	_later()
	_finger(controls, 0, steering + Vector2(away * 150.0, 0.0), true)
	_finger(controls, 0, steering + Vector2(away * 150.0, 0.0), false)
	return _held_any_move()

func _held_any_move() -> bool:
	return Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") \
			or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")

## **Carried over from the code being replaced, bought with a played session.** A `PAUSABLE` node
## stops running the instant the tree pauses, which is one frame too late to let go of whatever
## direction was pressed when the pause landed — see `_release_all()`. `_ready()` sets this
## explicitly rather than trusting it stays true across a rewrite.
func _test_process_mode_stays_always(t) -> void:
	var controls := await _controls(t)
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
	var controls := await _controls(t)

	controls.use_touch(false)
	t.get_tree().paused = true
	await UIScreens.frames(t)
	t.check(not controls.visible, "no device sees the button while the tree is paused")

	controls.use_touch(false)
	t.get_tree().paused = false
	await UIScreens.frames(t)
	t.check(controls.visible, "a desktop with no touch hardware shows it too, once a day is running")

	controls.use_touch(true)
	t.get_tree().paused = false
	await UIScreens.frames(t)
	t.check(controls.visible, "and a touch device shows it exactly the same way")

	controls.free()

## **The pause is not a held action, and firing it needs a real propagated event, not polled
## state.** `main._unhandled_input()` reads `event.is_action_pressed("pause")` off the event
## itself, so `Input.action_press(&"pause")` — the mechanism a held direction uses — would set
## polled state and be heard by nothing, the same trap `AutoScreenshot._tap()`'s own comment names
## for `--press`. Heard here by a node in the tree, the way `main` hears it: a press and a lift on
## the button, the buffered input flushed, and what reaches the tree is the event.
func _test_the_pause_button_sends_a_real_action_event(t) -> void:
	var controls := await _controls(t)
	var probe := _probe(t)
	_finger(controls, 0, TouchControls.PAUSE_CENTRE, true)
	_finger(controls, 0, TouchControls.PAUSE_CENTRE, false)
	Input.flush_buffered_events()
	t.check(probe.events.size() == 1 and probe.events[0] is InputEventAction,
			"a real InputEventAction, not bare polled state")
	var event := probe.events[0] as InputEventAction
	t.check(event.action == &"pause" and event.pressed,
			"shaped exactly as the main scene reads a pause press")
	probe.free()
	controls.free()
	_release_actions()

## **Fires on a clean tap, not on touch-down — and a thumb that lands wrong can slide off and lift
## for free.** The button waits for the matching release, and only counts one still over the
## button — pressed once a day at most, a false fire costs more than a missed one. Asked of the
## real press and lift, and of whether a `pause` action reaches the tree (`_release_fires()`).
func _test_the_pause_button_fires_on_release_inside_and_not_outside(t) -> void:
	var controls := await _controls(t)
	var probe := _probe(t)
	t.check(_release_fires(controls, probe, TouchControls.PAUSE_CENTRE),
			"releasing on the button fires it")
	t.check(not _release_fires(controls, probe, TouchControls.PAUSE_CENTRE + Vector2(500.0, 0.0)),
			"and releasing well outside it cancels rather than firing")
	probe.free()
	controls.free()
	_release_actions()

## **A catch is the larger of what it was and 1.05 times its drawn radius** *(2026-10-10, the player:
## "why does the button reach decrease anything??? the 5% should go over the visible size making the
## area *larger*!")*. Pause drew 26px and caught at 46px before the 5% margin, which asked for 27.3px
## and shrank the catch to a third of its area; the margin must never take reach away. The release
## that fires pause asks the same geometry, so it is pinned alongside the press. Run's whole half
## catches a press, so what is pinned is that both the drawn disc and 1.05 times its radius lie on
## that half whichever side steers.
func _test_every_catch_is_at_least_five_percent_past_its_drawing_and_never_smaller_than_it_was(t) -> void:
	var controls := await _controls(t)
	var probe := _probe(t)
	var drawn := TouchControls.PAUSE_RADIUS
	var old_catch := 46.0
	t.check(TouchControls.PAUSE_CATCH_RADIUS >= drawn * 1.05,
			"pause catches at least 5%% beyond its drawn %.0fpx (catch %.1fpx)"
			% [drawn, TouchControls.PAUSE_CATCH_RADIUS])
	t.check(TouchControls.PAUSE_CATCH_RADIUS >= old_catch,
			"and never less than the 46px it caught at before the margin (catch %.1fpx)"
			% TouchControls.PAUSE_CATCH_RADIUS)
	for probe_offset: Vector2 in [Vector2(old_catch - 0.5, 0.0), Vector2(0.0, -(old_catch - 0.5)),
			Vector2(drawn * 1.05 + 1.0, 0.0), Vector2(-30.0, 30.0)]:
		t.check(_release_fires(controls, probe, TouchControls.PAUSE_CENTRE + probe_offset),
				"a release %.1fpx from the pause button's centre still fires it" % probe_offset.length())
	t.check(not _release_fires(controls, probe,
			TouchControls.PAUSE_CENTRE + Vector2(old_catch + 1.0, 0.0)),
			"and one past the catch does not")
	for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
		controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
		var steering := TouchControls.FOCUS_RIGHT if side == ControlsMode.Side.RIGHT \
				else TouchControls.FOCUS_LEFT
		var run := _run_focus(steering)
		for step in 16:
			var around := Vector2.from_angle(TAU * step / 16.0)
			t.check(_a_press_holds_run(controls,
					run + around * TouchControls.RUN_RADIUS * ButtonGeometry.CATCH_SCALE),
					"a press on Run's disc and 1.05 times its radius holds Run (steering %s, step %d)"
					% [steering, step])
	probe.free()
	controls.free()
	_release_actions()

## **The touch index is grabbed on press and let go on release, whichever way the release
## resolves.** Seen through what a second finger does: while one holds the button, a press on the
## button from another is no longer the button's and becomes a direction like any other; only the
## holding finger's lift can fire it; and once it lifts, fired or not, the button catches again.
func _test_the_pause_button_tracks_its_own_touch_index(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	var probe := _probe(t)
	t.check(not _held_any_move(), "nothing held at first")

	_finger(controls, 0, TouchControls.PAUSE_CENTRE, true)
	t.check(not _held_any_move(), "landing on the button grabs it rather than aiming")
	_later()
	_finger(controls, 1, TouchControls.PAUSE_CENTRE, true)
	t.check(_held_any_move(), "a second finger on it meets a button already held: just a direction")
	_finger(controls, 1, TouchControls.PAUSE_CENTRE + Vector2(-400.0, 0.0), false)
	Input.flush_buffered_events()
	t.check(probe.events.is_empty(), "and only the holding finger's lift can fire it")

	_finger(controls, 0, TouchControls.PAUSE_CENTRE + Vector2(500.0, 0.0), false)
	Input.flush_buffered_events()
	t.check(probe.events.is_empty(), "lifting the holder off the button does not fire it")
	_release_actions()
	_later()
	_finger(controls, 2, TouchControls.PAUSE_CENTRE, true)
	t.check(not _held_any_move(),
			"and releasing lets go of the index again, whether it fired or not: the button catches anew")
	_finger(controls, 2, TouchControls.PAUSE_CENTRE, false)
	Input.flush_buffered_events()
	t.check(probe.events.size() == 1, "and that fresh hold fires on its own clean lift")

	probe.free()
	controls.free()
	rig.free()
	_release_actions()

## **A finger still down when the day ends must not carry into the day after it.** Nothing here
## has a way to be told the tree is about to pause mid-gesture — the summary just sets it — so it
## is this node's own job to let go of everything the instant a pause lands, on every device, not
## only where the button is drawn.
func _test_hiding_the_controls_releases_a_held_direction(t) -> void:
	var controls := await _controls(t)
	controls.use_touch(false)
	var rig := _rig_at(t, Vector2.ZERO)

	_click_once(controls, _screen(controls, Vector2(100.0, 0.0)))
	t.check(Input.is_action_pressed("move_right"), "a direction is held")

	t.get_tree().paused = true
	await UIScreens.frames(t)
	t.check(not Input.is_action_pressed("move_right"),
			"and lets go of it rather than carrying it into tomorrow, even with no button drawn")

	t.get_tree().paused = false
	controls.free()
	rig.free()

func _test_a_tap_presses_the_components_of_its_heading(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)

	_click_once(controls, _screen(controls, Vector2(100.0, -100.0)))
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up"),
			"a diagonal press presses both components of its own unit vector")
	t.check(not Input.is_action_pressed("run"), "a single press does not hold run")

	_double_click(controls, _screen(controls, Vector2(-100.0, -100.0)))
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a new press the other way releases the axis it no longer wants")
	t.check(Input.is_action_pressed("run"), "a double press holds run")

	controls.free()
	rig.free()

## The degenerate case of a click: one on the very pixel of her feet (`TAP_STOP_RADIUS`'s circle is
## centred above them, so it does not catch it) has no heading to compute, and stops her rather than
## doing nothing.
func _test_a_click_on_the_very_pixel_of_her_feet_stops_rather_than_pressing(t) -> void:
	# Leftover state from the previous test's own double press, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2(50.0, 50.0))
	var controls := await _controls(t)

	_double_click(controls, _screen(controls, Vector2(100.0, 0.0)))
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking first, so there is something for landing on her to let go of")

	_click_once(controls, _screen(controls, Vector2(50.0, 50.0)))
	t.check(not _held_any_move() and not Input.is_action_pressed("run"),
			"landing exactly on her own position stops her rather than pressing nothing")
	t.check(_pressed() == Vector2.ZERO, "and she is no longer walking")

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
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.TAP)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_click_once(controls, transform * Vector2(500.0, 200.0))
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# 6px off the centre of her sprite (200, 177 -- TAP_STOP_CENTRE_LIFT above her feet at
	# 200, 200) -- within TAP_STOP_RADIUS (8px) of the middle of her, not of her feet.
	_click_once(controls, transform * Vector2(206.0, 177.0))
	t.check(not Input.is_action_pressed("move_right") and not _held_any_move(),
			"a click near the centre of her sprite, not only near her feet, stops her")

	_click_once(controls, transform * Vector2(500.0, 200.0))
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the two boundary clicks below have something to undo")

	# 20px straight below her feet -- 43px from the lifted centre. This is playtest 35 finding 1
	# itself: "right now I can click below her to stop."
	_click_once(controls, transform * Vector2(200.0, 220.0))
	t.check(Input.is_action_pressed("move_down"), "a click below her feet does not stop her")

	_click_once(controls, transform * Vector2(500.0, 200.0))
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the upper-body click below has something to undo")

	# 30px straight above her feet -- her chest -- 7px from the lifted centre and therefore
	# within TAP_STOP_RADIUS, where a circle centred on her feet would miss it entirely.
	_click_once(controls, transform * Vector2(200.0, 170.0))
	t.check(not Input.is_action_pressed("move_right") and not _held_any_move(),
			"and a click on her chest, 30px above her feet, stops her too")

	_click_once(controls, transform * Vector2(500.0, 200.0))
	t.check(Input.is_action_pressed("move_right"),
			"walking again, so the pram click below has something to undo")

	# The west-facing pram's live centre remains outside TAP_STOP_RADIUS of the lifted stop centre:
	# the pram is not her, even with the hand touching the handle.
	var pram_centre := Vector2(200.0, 200.0) + Vector2(
			-Stroller.PRAM_HORIZONTAL_DISTANCE, Stroller.PRAM_VERTICAL_LIFT)
	_click_once(controls, transform * pram_centre)
	t.check(Input.is_action_pressed("move_left"),
			"a click on the pram is not a click on her any more -- it sets a direction instead")

	controls.free()
	rig.free()
	_release_actions()

## **There is no arrival any more.** A direction pressed once stays held, unrenewed, however long
## `_process()` is asked to run — the whole of what "she walks it until the next press" means.
func _test_a_direction_stays_locked_in_with_nothing_held_down(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)

	_double_click(controls, _screen(controls, Vector2(100.0, 0.0)))
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds the direction and, on a double press, run")

	rig.global_position = Vector2(500.0, 0.0)
	await UIScreens.frames(t, 30)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking well past where a target used to sit still holds the same direction")

	controls.free()
	rig.free()
	_release_actions()

## **The test a screenshot cannot be**: `_on_tap()`'s own reverse of the transform `DangerEdge` and
## `HomeArrow` already read forwards. Constructed from the viewport's own real
## `get_canvas_transform()` rather than an assumed identity, so this would still catch a camera
## offset or a rotation the way a hard-coded expectation would not.
func _test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	var viewport := controls.get_viewport()
	var before := viewport.canvas_transform
	# A camera that has moved the view: a screen point is no longer the world point under it.
	viewport.canvas_transform = Transform2D(0.0, Vector2(50.0, 70.0))

	var world_target := Vector2(120.0, -40.0)
	var screen_position: Vector2 = viewport.get_canvas_transform() * world_target
	_click_once(controls, screen_position)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up")
			and not Input.is_action_pressed("move_down"),
			"a tap's own screen position maps back to the world position it was aimed at")

	viewport.canvas_transform = before
	controls.free()
	rig.free()
	_release_actions()

## The double-tap windows again, now through the real entry point rather than the pure function
## directly -- a close tap soon after runs, and either window failing on its own falls back to a
## fresh single tap.
func _test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_clock.now = 10.0
	_click(controls, transform * Vector2(100.0, 0.0), true)
	t.check(not Input.is_action_pressed("run"), "the first tap of a run only walks")

	_clock.now = 10.2
	_click(controls, transform * Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("run"), "soon and on the same spot reads as a double tap")

	_clock.now = 10.4
	_click(controls, transform * Vector2(500.0, 500.0), true)
	t.check(not Input.is_action_pressed("run"),
			"soon but far away is a new direction, not a double tap on the old one")

	_clock.now = 12.0
	_click(controls, transform * Vector2(500.0, 500.0), true)
	t.check(not Input.is_action_pressed("run"), "close but late is also a new single tap")

	controls.free()
	rig.free()
	_release_actions()

## Paused for any reason -- Esc, the day ending, the title -- a tap does nothing, the same as every
## one of those screens already leaving the controls drawing nothing.
func _test_a_tap_during_a_pause_does_nothing(t) -> void:
	# Leftover state from the previous test's own tap, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	t.get_tree().paused = true

	_click_once(controls, controls.get_viewport().get_canvas_transform() * Vector2(50.0, 0.0))
	t.check(not Input.is_action_pressed("move_right") and not _held_any_move(),
			"a tap during a pause does nothing at all")

	t.get_tree().paused = false
	controls.free()
	rig.free()
	_release_actions()

## A direction left pressed into whatever comes next is the same leak `_release_all()` already
## guards its own controls against on every kind of hiding.
func _test_a_pause_force_releases_a_held_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)

	_double_click(controls, _screen(controls, Vector2(100.0, 0.0)))
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds a direction and, on a double press, run")

	t.get_tree().paused = true
	await UIScreens.frames(t)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"Esc or any other pause force-releases whatever was held")
	t.check(_pressed() == Vector2.ZERO,
			"and abandons the direction rather than merely pausing mid-stride")

	t.get_tree().paused = false
	controls.free()
	rig.free()
	_release_actions()

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
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.TAP)
	_finger(controls, 0, _screen(controls, Vector2(100.0, 0.0)), true)
	_finger(controls, 0, _screen(controls, Vector2(100.0, 0.0)), false)
	t.check(Input.is_action_pressed("move_right"), "walking east before the pause")
	t.get_tree().paused = true
	await UIScreens.frames(t) # the day ending force-releases the held direction, same as ever
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"standing once the day has ended")

	_finger(controls, 0, Vector2(500.0, 0.0), true)
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"the press that dismisses the screen sets no heading")

	t.get_tree().paused = false
	await UIScreens.frames(t)
	_finger_drag(controls, 0, Vector2(502.0, 1.0))
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"and the finger's own drift, once the next day is running, is not read as her first "
			+ "heading: the press that dismissed the screen is never tracked for a later drag")

	_finger(controls, 0, Vector2(502.0, 1.0), false)
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
	var controls := await _controls(t)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_click(controls, transform * Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right"), "a left click walks exactly as a tap would")

	# A right click, or the release half of a left one, is not a tap.
	_click(controls, transform * Vector2(100.0, 0.0), false)
	var other_button := InputEventMouseButton.new()
	other_button.button_index = MOUSE_BUTTON_RIGHT
	other_button.pressed = true
	other_button.position = transform * Vector2(-100.0, 0.0)
	UIScreens.push(controls, other_button)
	t.check(not Input.is_action_pressed("move_left"), "only a left click's own press is a tap")

	controls.free()
	rig.free()
	_release_actions()

## **The gate that makes the mouse stand-in safe on a real touch device.** Godot emulates a mouse
## click from every real touch by default (`input_devices/pointing/emulate_mouse_from_touch`), so
## without `not _touch` a single tap would fire `_on_tap()` twice, once through each event, at the
## same place and the same instant -- close enough on both windows to read as its own double tap.
## This is the bug a first version of `--tap` actually hit: a lone `--tap` on a screenshot rig run
## with `--touch` came back running, not walking.
func _test_a_touch_devices_own_emulated_click_is_ignored(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	controls.use_touch(true)

	var at: Vector2 = controls.get_viewport().get_canvas_transform() * Vector2(100.0, 0.0)
	_finger(controls, 0, at, true)
	t.check(not Input.is_action_pressed("run"), "the real touch alone only walks")

	# The engine's own emulated click, same place, same instant -- exactly what a real touch device
	# would also deliver right behind the touch above.
	_click(controls, at, true)
	t.check(not Input.is_action_pressed("run"),
			"a touch device's own emulated click is not read as a second, doubling tap")

	controls.free()
	rig.free()
	_release_actions()

## **The cost the no-UI decision was protecting, now paid deliberately.** *(2026-09-06: "and then
## it also needs the pause button in the top right".)* A touch press that lands on the button,
## while it is showing, must not also lock in a direction toward the corner.
func _test_a_press_on_the_pause_button_is_not_also_a_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	var probe := _probe(t)

	_finger(controls, 0, TouchControls.PAUSE_CENTRE, true)
	t.check(not _held_any_move(), "the press is caught by the button and is not read as a "
			+ "direction toward the corner")

	_finger(controls, 0, TouchControls.PAUSE_CENTRE, false)
	Input.flush_buffered_events()
	t.check(probe.events.size() == 1, "and the button it caught fires on the lift")
	probe.free()
	controls.free()
	rig.free()
	_release_actions()

## **A left click on a visible pause button presses it, not the corner underneath it.** The button
## is drawn on every device now, so a desktop mouse click has to be checked against it exactly as a
## finger's press already was — see `_on_pointer()`'s own doc for why the mouse path was folded
## into the same function that already tracked a touch index.
func _test_a_mouse_click_on_the_pause_button_is_not_also_a_direction(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	controls.use_touch(false)
	var probe := _probe(t)

	_click(controls, TouchControls.PAUSE_CENTRE, true)
	t.check(not _held_any_move(), "a click on the button is not read as a direction toward the corner")

	_click(controls, TouchControls.PAUSE_CENTRE, false)
	Input.flush_buffered_events()
	t.check(probe.events.size() == 1, "and releasing on it lets go of the button's own hold, firing it")

	_later()
	_click(controls, TouchControls.PAUSE_CENTRE, true)
	t.check(not _held_any_move(), "so the button catches a second click: its hold was let go")

	probe.free()
	controls.free()
	rig.free()
	_release_actions()

## **Only while the button is actually drawn.** `visible` is the gate, not the device — a press in
## the same corner while the button is hidden (paused, or before the first `_process()` call) is an
## ordinary direction press, not a dead zone nobody can walk into.
func _test_the_corner_is_an_ordinary_direction_press_where_the_button_is_not_drawn(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t, false) # before its first frame: not drawn yet
	controls.use_touch(false)

	_click(controls, TouchControls.PAUSE_CENTRE, true)
	t.check(_held_any_move(), "a press in the corner sets a direction when no button is drawn there")

	controls.free()
	rig.free()
	_release_actions()

## *(2026-09-06: "there is no way to walk slowly -- that is intentional -- there should only ever
## be one speed (plus a second via running)".)* The drag stick was the one input path that could
## press a partial vector — `offset.limit_length(STICK_RADIUS) / STICK_RADIUS` walked her at less
## than `Tuning.WALK_SPEED` whenever a thumb rested short of the stick's own rim, which is exactly
## the gap every pursuit lead time in `src/autoload/tuning.gd` is computed assuming cannot exist.
## With the stick deleted, a press's heading is the only vector any press can produce, and it is
## always normalised — so this asks the real entry point, a click across a full circle of targets,
## whether the actions it ends up pressing ever combine to less than a unit vector.
func _test_no_input_path_presses_a_vector_shorter_than_one(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)

	for degrees in range(0, 360, 15):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(float(degrees)))
		_click_once(controls, _screen(controls, direction * 200.0))
		var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		t.check(pressed.length() >= 1.0 - 0.001,
				"a press at %d degrees still presses a full unit vector (got length %.4f)"
						% [degrees, pressed.length()])

	controls.free()
	rig.free()
	_release_actions()

## PLAYTEST-57: *"arrow keys should reset any mouse click position. when pressing awsd or arrow
## keys right now the last pressed mouse position is still active resulting in incorrect /
## drifting movement."* A click locks a heading in by pressing `move_*` actions synthetically, and
## `Stroller` reads the same four actions through `Input.get_vector()`, which sums over whoever is
## pressing them — so without the reset, a key held after a click would add to the click rather
## than replace it. The resulting vector has to be the key's alone.
func _test_a_keyboard_press_resets_a_clicked_heading(t) -> void:
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	controls.use_touch(false)

	_click(controls, controls.get_viewport().get_canvas_transform() * Vector2(0.0, -100.0), true)
	t.check(Input.is_action_pressed("move_up"), "the click itself walks north first")

	# The real trap this fix survives: the engine updates an action's own polled state before
	# dispatching the event that changed it to any node's `_input()` -- reproduced by hand here,
	# since an event pushed through the viewport never reaches `Input.parse_input_event()`'s own
	# queue, so nothing would otherwise mark `move_right` pressed at all. See
	# `_yield_to_the_keyboard()`'s own doc for why the fix cannot simply release every `move_*`
	# action it finds pressed.
	Input.action_press(&"move_right")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	UIScreens.push(controls, key)

	var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	t.check(pressed.is_equal_approx(Vector2.RIGHT),
			("the key's own direction alone, not the click's north added to the key's east "
			+ "(got %s)") % pressed)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.RIGHT),
			"the drawn focus knob reads the key's own heading now, not the stale click's north")

	controls.free()
	rig.free()
	_release_actions()

## *(2026-10-10, the player: "instead of splitting the in middle we can move it closer to
## the run button; although I wouldn't go all the way".)* The steering half reaches two thirds of
## the way to Run's focus, mirrored for either side, and stops short of Run's own disc. Asked of real
## presses: a finger landing half a pixel past the edge holds Run, one short of it does not.
func _test_the_steering_half_reaches_two_thirds_toward_run(t) -> void:
	var left := TouchControls.FOCUS_LEFT
	var right := TouchControls.FOCUS_RIGHT
	t.check(is_equal_approx(_edge(left), left.x + (right.x - left.x) * 2.0 / 3.0),
			"with the left side steering, the edge is two thirds of the way to the right focus "
			+ "(got %.2f)" % _edge(left))
	t.check(is_equal_approx(_edge(right), right.x - (right.x - left.x) * 2.0 / 3.0),
			"and mirrored with the right side steering (got %.2f)" % _edge(right))
	t.check(_edge(left) + TouchControls.RING_RADIUS < right.x - TouchControls.RUN_RADIUS,
			"the stop band ends short of Run's painted disc: not all the way")
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
		controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
		var steering := right if side == ControlsMode.Side.RIGHT else left
		var edge := _edge(steering)
		var toward_run := signf(_run_focus(steering).x - steering.x)
		t.check(not _a_press_holds_run(controls, Vector2(edge - toward_run * 0.5, 300.0)),
				"half a pixel short of the edge is still steering's (side %d)" % side)
		t.check(_a_press_holds_run(controls, Vector2(edge + toward_run * 0.5, 300.0)),
				"half a pixel past it is Run's (side %d)" % side)
		t.check(not _a_press_holds_run(controls, Vector2(640.0, 480.0)),
				"the middle of the screen now belongs to steering, on either side (side %d)" % side)
		t.check(_a_press_holds_run(controls, _run_focus(steering))
				and not _a_press_holds_run(controls, steering),
				"Run's own focus is on Run's side, and the steering focus is not (side %d)" % side)
		_release_actions()
	controls.free()
	rig.free()
	_release_actions()

## The dead zone surrounds the steering focus only, tighter than the ring drawn around it.
## *(2026-10-10, the player: "decrease the deadzone of the joystick (which makes the player stop)
## smaller/tighter".)* A finger landing in it stops her; just outside it, still inside the ring, it
## steers; and Run's focus has no dead zone, a press there being Run's and leaving her walking.
func _test_the_dead_zone_is_tighter_than_the_ring_and_only_on_steering(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var left := TouchControls.FOCUS_LEFT
	t.check(TouchControls.DEAD_ZONE_RADIUS < TouchControls.RING_RADIUS,
			"the dead zone is tighter than the ring drawn around it")

	t.check(_walk_first(controls, left), "walking first, so a stop has something to undo")
	_later()
	_finger(controls, 0, left, true)
	t.check(not _held_any_move(), "dead on the steering focus stops")
	_finger(controls, 0, left, false)

	_walk_first(controls, left)
	_later()
	_finger(controls, 0, left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 0.99, true)
	t.check(not _held_any_move(), "just inside the dead zone stops")
	_finger(controls, 0, left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 0.99, false)

	_release_actions()
	_later()
	_finger(controls, 0, left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 1.01, true)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("run"),
			"just outside it, still inside the ring, steers")
	_finger(controls, 0, left + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 1.01, false)

	_walk_first(controls, left)
	t.check(_a_press_holds_run(controls, TouchControls.FOCUS_RIGHT) and _held_any_move(),
			"Run's focus has no dead zone: a press there holds Run and leaves her walking")
	t.check(is_equal_approx(TouchControls.TAP_STOP_RADIUS * 2.0, TouchControls.DEAD_ZONE_RADIUS),
			"tap mode's stop circle covers the dead zone on screen at the camera's zoom of 2, "
			+ "nothing bigger (playtest 34 finding 5): 8 world px, 16 on screen")
	# **A named exception to the private-member rule** (minty-quail, tests through public seams): the
	# knob is a `draw_circle()` straight onto the control, with no drawer handed in to record it and no
	# pixels to read headless (the dummy renderer draws none), and its two numbers have no reader but
	# that draw, so the behaviour route cannot hold "the running knob stays inside the ring".
	t.check(TouchControls._FOCUS_KNOB_OFFSET + TouchControls._FOCUS_KNOB_RADIUS * 1.3
			< TouchControls.RING_RADIUS, "the walking knob, running, stays inside the ring")
	controls.free()
	rig.free()
	_release_actions()

## *(2026-09-07: "there should be a narrow band in the middle of the screen (size of the stop circle)
## that stops the player".)* The band moved to the steering half's edge and kept the ring's diameter
## as its width. A finger landing in the half of it on the steering side stops her; the half beyond
## the edge is Run's, so a fresh finger there holds Run, and only a steering drag that wanders in is
## stopped by it; just past the band's width, either way, it steers on.
func _test_the_stop_band_sits_on_the_steering_edge(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
		controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
		var steering := TouchControls.FOCUS_RIGHT if side == ControlsMode.Side.RIGHT \
				else TouchControls.FOCUS_LEFT
		var edge := _edge(steering)
		var toward_run := signf(_run_focus(steering).x - steering.x)
		var width := TouchControls.RING_RADIUS
		# At the edge, a hair on the steering side of it: the edge itself belongs to steering, but a
		# point on it is not representable exactly in the single-precision positions a press carries.
		var at_the_edge := edge - toward_run * 0.01
		for at: Vector2 in [Vector2(at_the_edge, 0.0), Vector2(at_the_edge, 719.0),
				Vector2(at_the_edge, 360.0), Vector2(edge - toward_run * width * 0.99, 360.0)]:
			_walk_first(controls, steering)
			_later()
			_finger(controls, 0, at, true)
			t.check(not _held_any_move(),
					"a press at %s, in the band on the steering side, stops her (side %d)" % [at, side])
			_finger(controls, 0, at, false)
		_walk_first(controls, steering)
		t.check(_a_press_holds_run(controls, Vector2(edge + toward_run * width * 0.99, 360.0))
				and _held_any_move(),
				"the half of the band beyond the edge is Run's: a fresh press holds Run (side %d)" % side)
		_finger(controls, 0, steering + Vector2(-toward_run * 150.0, 0.0), true)
		_finger_drag(controls, 0, Vector2(edge + toward_run * width * 0.99, 360.0))
		t.check(not _held_any_move(),
				"but a steering drag carried into that half of the band stops (side %d)" % side)
		_finger_drag(controls, 0, Vector2(edge + toward_run * width * 1.01, 360.0))
		t.check(_held_any_move(), "and carried past its width steers again (side %d)" % side)
		_finger(controls, 0, steering, false)
		_release_actions()
		for at: Vector2 in [Vector2(edge - toward_run * width * 1.01, 360.0), Vector2(640.0, 360.0)]:
			_later()
			_finger(controls, 0, at, true)
			t.check(_held_any_move(),
					"a press at %s, past the band's width or in the middle of the screen, steers "
					% at + "(side %d)" % side)
			_finger(controls, 0, at, false)
			_release_actions()
	controls.free()
	rig.free()
	_release_actions()

## What the world is told the controls cover (`TouchControls.covering`, which `main` hands to
## everything that asks what she can see): nothing under the tap scheme, where the whole view counts,
## and under the joystick each corner's painted ring or Run disc and never its invisible catch,
## whichever side the title chose to steer.
func _test_the_screen_cover_follows_the_scheme_in_force(t) -> void:
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.TAP)
	t.check(not controls.covering.in_force, "the tap scheme covers nothing: the whole view counts")
	var design := ScreenOrientation.DESIGN_SIZE
	for side: ControlsMode.Side in [ControlsMode.Side.LEFT, ControlsMode.Side.RIGHT]:
		controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
		var cover := controls.covering
		t.check(cover.in_force and cover.design_size == design,
				"the joystick is in force over the design box (side %d)" % side)
		var left_top := TouchControls.FOCUS_LEFT.y - TouchControls.RUN_RADIUS
		t.check(cover.left == Rect2(0.0, left_top, TouchControls.FOCUS_LEFT.x + TouchControls.RUN_RADIUS,
				design.y - left_top),
				"the left corner reaches the painted disc's far edge and the screen's, whichever "
				+ "side steers (%s)" % cover.left)
		var right_left := TouchControls.FOCUS_RIGHT.x - TouchControls.RUN_RADIUS
		t.check(cover.right == Rect2(right_left, left_top, design.x - right_left, design.y - left_top),
				"and the right corner mirrors it (%s)" % cover.right)
	controls.set_mode(ControlsMode.Mode.TAP)
	t.check(not controls.covering.in_force, "back on the tap scheme the cover is out of force again")
	controls.free()
	_release_actions()

## **The reach the focal points exist to fix.** *(2026-09-06, the player: "right now the finger
## needs to reach over half the phone to be able to input an up or down direction".)* A press west
## of the steering focus walks west, and above it walks north, no matter where she is standing —
## the direction does not depend on where she is. Either side steers the same way once the title
## has chosen it.
func _test_a_touch_aims_from_the_steering_focus_not_from_her(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT)

	# West of the left focus, in the design box a non-rotated press is read in directly.
	_later()
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a press west of the left focus walks west, regardless of where she is standing")
	t.check(not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and not north or south, since the press is due west of the focus")

	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	_later()
	_finger(controls, 0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), true)
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"and with the right side steering, a press above the right focus walks north")

	controls.free()
	rig.free()
	_release_actions()

## **The steering ring's knob shows the heading she is walking.** *(2026-09-27, playtest
## olive-koala statement 6: "the onscreen controls should show the selected direction on both sides
## always. when using hands and when using the keyboard".)* One ring steers now, so "both sides" is
## that ring: `_draw_focus_circles()` reads `current_heading()` for its knob, so a press through the
## steering focus has to move it the same way `Input.is_action_pressed()` shows the press moved.
func _test_current_heading_matches_a_press_through_the_steering_focus(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT)

	_later()
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.LEFT),
			"a press west of the left focus is what the knob now shows")

	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	_later()
	_finger(controls, 0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), true)
	t.check(TouchControls.current_heading().is_equal_approx(Vector2.UP),
			"and a press above the right focus, with the right side steering, the same way")

	controls.free()
	rig.free()
	_release_actions()

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
	# presses `move_right` directly, on its own, rather than through a click (which
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
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), true)
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	_later()
	_finger(controls, 0, TouchControls.FOCUS_LEFT, true)
	t.check(not Input.is_action_pressed("move_right") and not _held_any_move(),
			"a press dead on a focus stops her")

	controls.free()
	rig.free()
	_release_actions()

## **The world-space door is gone in `Mode.JOYSTICK`, replaced by the band.** *(2026-09-06, the
## player: "tapping in their center or on the player should stop the player still" — the finding
## M83 built this test for. 2026-09-07, overturning it: "with that we can remove tap the player to
## stop since it's the same area and if a movement accidentally goes over the player it might
## become surprising to see her stop".)* A press near her own world position, off the dead zone and
## off the band, walks away from the steering focus instead of stopping.
func _test_a_touch_near_her_own_position_no_longer_stops_her(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), true)
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")
	_later()

	# Well away from the dead zone and the band in design space, and within world-space reach of
	# her -- the exact case the deleted door used to catch.
	_finger(controls, 0, transform * Vector2(310.0, 300.0), true)
	t.check(_held_any_move(), "a press near her steers from the focus instead of stopping")
	var from_the_focus := (Vector2(310.0, 300.0)
			- transform.affine_inverse() * TouchControls.FOCUS_LEFT).normalized()
	t.check(_pressed().is_equal_approx(from_the_focus),
			"measured from the left focus, the steering focus, not from her (%s, not %s)"
			% [_pressed(), from_the_focus])

	controls.free()
	rig.free()
	_release_actions()

## **`Mode.TAP` aims from her regardless of the device that sent the click.** *(2026-09-06, the
## player: "that two focal point mode should only exist for the touch enabled version not the mouse
## version where the direction uses the player as reference" — read now as the mode, not the
## hardware, the player asked to keep separate: see `docs/DECISIONS.md` under M88.)* Driven through
## `_input()` rather than `_on_tap()` directly, so this also exercises the hardware routing a mouse
## click takes on a non-touch device (`_touch = false`) — the two are independent, and both are set
## explicitly here so the test does not lean on either one's default.
func _test_a_mouse_click_still_aims_from_her_not_a_focus(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.use_touch(false)
	controls.set_mode(ControlsMode.Mode.TAP)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_click(controls, transform * (rig.global_position + Vector2(200.0, 0.0)), true)
	t.check(Input.is_action_pressed("move_right"),
			"a mouse click still aims from her own position, not from a focus, even here")

	controls.free()
	rig.free()
	_release_actions()

## **A held finger keeps re-aiming, and the direction it presses is still a full unit vector at
## every step** — the same guarantee `_test_no_input_path_presses_a_vector_shorter_than_one` holds
## for a single press, now asked of the drag that replaces the stick, since a drag is the other new
## path that could in principle press a partial vector and does not. *(2026-09-07: "dragging the
## finger doesn't work anymore but should".)*
func _test_a_touch_drag_updates_the_heading_and_still_presses_a_unit_vector(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0)) # far from either focus, on purpose
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(Input.is_action_pressed("move_left"), "the press itself walks west of the focus")

	for degrees in range(0, 360, 30):
		var offset := Vector2.RIGHT.rotated(deg_to_rad(float(degrees))) * 150.0
		_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + offset)
		var pressed := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		t.check(pressed.length() >= 1.0 - 0.001,
				"a drag at %d degrees around the focus still presses a full unit vector (got %.4f)"
						% [degrees, pressed.length()])

	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0))
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"),
			"the last drag step, due east of the focus, is what is currently held, so the same "
			+ "finger is tracked for the drag")

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(150.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right"),
			"and the direction locks in as it stood, unrenewed by the release itself")
	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + Vector2(0.0, -150.0))
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up"),
			"lifting the finger stops tracking the drag: its later motion re-aims nothing")

	controls.free()
	rig.free()
	_release_actions()

## **A press dead on a focus stops her, and now also starts a tracked drag** — the rule that used
## to be deleted was "a stop does not start a drag," not the stop itself. *(Playtest 34 finding 8:
## "when I start dragging from the center of the joystick nothing happens it should behave the same
## as if I move to the center and back stop while I'm in the center and move when I'm back.")*
func _test_a_press_at_a_focus_centre_starts_a_drag_that_can_leave_and_return(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	_finger(controls, 0, TouchControls.FOCUS_LEFT, true)
	t.check(not _held_any_move(), "a press dead on a focus still stops her")

	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0))
	t.check(Input.is_action_pressed("move_left"),
			"dragging out of the centre starts walking that way: the same finger is tracked, "
			+ "where it used to be dropped entirely")

	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT)
	t.check(not _held_any_move() and not Input.is_action_pressed("move_left"),
			"and dragging back into the centre stops her again, live")

	_finger(controls, 0, TouchControls.FOCUS_LEFT, false)
	controls.free()
	rig.free()
	_release_actions()

## **`Mode.TAP`'s one door gets the same live crossing `Mode.JOYSTICK`'s two get** — the general
## reading of finding 8's "crossing the boundary either way changes it live" applied to the door
## `_near_her()` answers rather than only to a focus.
func _test_a_tap_mode_drag_stops_and_resumes_crossing_her_own_stop_radius(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := await _controls(t)
	controls.use_touch(false)
	controls.set_mode(ControlsMode.Mode.TAP)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_click(controls, transform * Vector2(500.0, 300.0), true)
	t.check(Input.is_action_pressed("move_right"), "the click itself walks east of her")

	# Within TAP_STOP_RADIUS (8px) of the centre of her sprite (300, 277 -- TAP_STOP_CENTRE_LIFT
	# above her feet at 300, 300), not of her feet.
	_mouse_drag(controls, transform * Vector2(305.0, 280.0))
	t.check(not _held_any_move() and not Input.is_action_pressed("move_right"),
			"dragging back near the centre of her stops her live")

	_mouse_drag(controls, transform * Vector2(500.0, 300.0))
	t.check(Input.is_action_pressed("move_right"), "and dragging back out resumes steering")

	_click(controls, transform * Vector2(500.0, 300.0), false)
	controls.free()
	rig.free()
	_release_actions()

## **A double tap that then drags holds `run` the same way a double tap already does.**
## *(2026-09-07: "A double press that then drags holds run the same way a double press already
## does".)*
func _test_a_double_tap_that_then_drags_keeps_running(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), false)
	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(Input.is_action_pressed("run"), "the double tap itself runs")

	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + Vector2(0.0, -150.0))
	t.check(Input.is_action_pressed("run"), "and dragging afterward keeps holding run")
	t.check(Input.is_action_pressed("move_up"), "while the heading itself keeps updating")

	controls.free()
	rig.free()
	_release_actions()

## **`Mode.TAP`'s own half of the drag.** *(2026-09-07: "although dragging a mouse should reaim as
## well".)* Its origin is her own position, not a focus — the one place the two modes keep
## disagreeing — read live on every motion event.
func _test_a_mouse_drag_reaims_from_her_own_position(t) -> void:
	var rig := _rig_at(t, Vector2(300.0, 300.0))
	var controls := await _controls(t)
	controls.use_touch(false)
	controls.set_mode(ControlsMode.Mode.TAP)
	var transform: Transform2D = controls.get_viewport().get_canvas_transform()

	_click(controls, transform * Vector2(500.0, 300.0), true)
	t.check(Input.is_action_pressed("move_right"), "the click itself walks east of her")

	_mouse_drag(controls, transform * Vector2(300.0, 100.0))
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_right"),
			"dragging the held button re-aims from her own position, not a fixed focus")

	_click(controls, transform * Vector2(300.0, 100.0), false)
	_mouse_drag(controls, transform * Vector2(100.0, 300.0))
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_left"),
			"releasing the button stops tracking the drag")

	controls.free()
	rig.free()
	_release_actions()

## A mouse simply moving, with no button held, is not a drag — `button_mask` is what tells the two
## apart, and every ordinary mouse movement in the game carries no mask at all.
func _test_a_mouse_motion_without_the_button_held_does_nothing(t) -> void:
	# Leftover state from the previous test's own drag, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(t, Vector2.ZERO)
	var controls := await _controls(t)
	controls.use_touch(false)

	var motion := InputEventMouseMotion.new()
	motion.button_mask = 0
	motion.position = Vector2(999.0, 999.0)
	UIScreens.push(controls, motion)
	t.check(not _held_any_move(), "idle mouse movement never sets a direction")

	controls.free()
	rig.free()
	_release_actions()

## A press in the band at the steering half's edge stops her in `Mode.JOYSTICK`, the other door
## into `_stop()` beside the dead zone. *(2026-09-07: "there should be a narrow band in the middle of
## the screen ... that stops the player".)*
func _test_a_tap_in_the_stop_band_stops_her_on_touch(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)

	_later()
	_click(controls, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(Input.is_action_pressed("move_left"), "walking first, so a stop has something to undo")

	_later()
	_click(controls, Vector2(_edge(TouchControls.FOCUS_LEFT) - 10.0, 200.0), true)
	t.check(not Input.is_action_pressed("move_left") and not _held_any_move(),
			"a press in the band at the steering edge stops her rather than steering")

	controls.free()
	rig.free()
	_release_actions()

## **A steering drag into the band stops her, and one carried on past it onto Run's half steers
## again from the same focus.** The sides never swap in play *(2026-10-10, the player: "we don't
## allow switching joystick and run key")*, so the pointer keeps the role its press gave it: it
## neither takes Run nor moves the ring.
func _test_a_drag_past_the_band_keeps_steering_from_the_same_side(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var edge := _edge(TouchControls.FOCUS_LEFT)

	_finger(controls, 0, TouchControls.FOCUS_LEFT + Vector2(-150.0, 0.0), true)
	t.check(Input.is_action_pressed("move_left"), "the press itself walks west of the focus")

	_finger_drag(controls, 0, Vector2(edge, 480.0))
	t.check(not _held_any_move(), "dragging into the band stops her")

	_finger_drag(controls, 0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0))
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"),
			"carried on onto Run's half, it steers again from the left focus, toward the pointer")
	t.check(not Input.is_action_pressed("run")
			and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"without taking Run or moving Run's disc")

	_finger(controls, 0, TouchControls.FOCUS_RIGHT + Vector2(0.0, -150.0), false)
	t.check(_held_any_move() and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
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
		var run := _run_focus(steering)
		var toward_run := signf(run.x - steering.x)
		for rotate: bool in [false, true]:
			var controls := await _controls(t)
			controls.rotated = rotate
			controls.set_mode(ControlsMode.Mode.JOYSTICK, side)
			t.check(controls.run_button_center() == run,
					"Run is on the far side from the first frame (side=%d rotated=%s)" % [side, rotate])
			var key := InputEventKey.new()
			key.keycode = KEY_D
			key.pressed = true
			UIScreens.push(controls, key)
			t.check(controls.run_button_center() == run, "a key picks no side")
			_later()
			_finger(controls, 0, ScreenOrientation.to_presented_space(
					steering + Vector2(0.0, -100.0), rotate), true)
			_finger(controls, 0, ScreenOrientation.to_presented_space(
					steering + Vector2(0.0, -100.0), rotate), false)
			t.check(_held_any_move(),
					"a tap above the steering focus walks (the heading's own direction under a "
					+ "rotated presentation is test_orientation's)")
			var heading := TouchControls.current_heading()
			var off_the_disc := Vector2(_edge(steering) + toward_run, 150.0)
			for at: Vector2 in [run, run + Vector2(0.0, -100.0), off_the_disc]:
				var pressed_at := ScreenOrientation.to_presented_space(at, rotate)
				_finger(controls, 1, pressed_at, true)
				t.check(Input.is_action_pressed("run") and TouchControls.current_heading() == heading,
						"a press at %s on Run's half holds Run and never steers" % at)
				_finger_drag(controls, 1, ScreenOrientation.to_presented_space(steering, rotate))
				t.check(TouchControls.current_heading() == heading,
						"and dragging that finger over the steering focus does not steer either")
				_finger(controls, 1, pressed_at, false)
				t.check(controls.run_button_center() == run
						and TouchControls.current_heading() == heading,
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
	var controls := await _controls(t)
	controls.use_touch(true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var focus := TouchControls.FOCUS_LEFT

	_finger(controls, 0, focus + Vector2(-150.0, 0.0), true)
	_finger_drag(controls, 0, focus + Vector2(-5.0, 2.0))
	t.check(not _held_any_move(), "the swipe's last motion event is inside the dead zone")
	_finger(controls, 0, focus + Vector2(150.0, 0.0), false)
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left"),
			"lifting outside it walks toward the release point, east of the focus")
	_finger_drag(controls, 0, focus + Vector2(0.0, -60.0))
	t.check(not Input.is_action_pressed("move_up"), "and the drag is over")

	_later()
	_finger(controls, 0, focus + Vector2(0.0, -150.0), true)
	_finger_drag(controls, 0, focus + Vector2(0.0, -60.0))
	t.check(Input.is_action_pressed("move_up"), "a second drag walks north, outside the dead zone")
	_finger(controls, 0, focus + Vector2(TouchControls.DEAD_ZONE_RADIUS * 0.5, 0.0), false)
	t.check(not _held_any_move() and not Input.is_action_pressed("move_up"),
			"lifting inside the dead zone, with no motion event there, stops her")

	controls.free()
	rig.free()
	_release_actions()

## Pause's catch is its old 46px, past the 5% rim (27.3px); the dead zone does not grow at all.
func _test_round_button_margins_and_unchanged_dead_zones(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var probe := _probe(t)
	for rotate in [false, true]:
		var controls := await _controls(t)
		controls.set_mode(ControlsMode.Mode.JOYSTICK)
		controls.rotated = rotate
		var catch_ratio := TouchControls.PAUSE_CATCH_RADIUS / TouchControls.PAUSE_RADIUS
		for ratio: float in [1.051, catch_ratio - 0.01, catch_ratio + 0.01]:
			var pause_at := ScreenOrientation.to_presented_space(TouchControls.PAUSE_CENTRE
					+ Vector2.LEFT * TouchControls.PAUSE_RADIUS * ratio, rotate)
			# The press is the button's when it holds no Run: a press the button does not catch
			# falls to Run's half, which this corner is on.
			_later()
			_finger(controls, 2, pause_at, true)
			t.check((not Input.is_action_pressed("run")) == (ratio < catch_ratio),
					"pause shares the catch for press")
			_finger(controls, 2, Vector2.ZERO, false)
			_release_actions()
			# The lift asks the same catch: held at the centre, lifted at the probe point.
			var before := probe.events.size()
			_finger(controls, 3, ScreenOrientation.to_presented_space(
					TouchControls.PAUSE_CENTRE, rotate), true)
			_finger(controls, 3, pause_at, false)
			Input.flush_buffered_events()
			t.check((probe.events.size() > before) == (ratio < catch_ratio),
					"pause release uses the same catch")
			_release_actions()
		var edge := TouchControls.FOCUS_LEFT + Vector2.UP * TouchControls.DEAD_ZONE_RADIUS * 1.01
		_later()
		_finger(controls, 0, ScreenOrientation.to_presented_space(edge, rotate), true)
		t.check(_held_any_move(), "a press 1% beyond the dead zone still steers")
		_finger(controls, 0, ScreenOrientation.to_presented_space(edge, rotate), false)
		controls.free()
		_release_actions()
	probe.free()
	rig.free()

## A run pointer never steers and a steering pointer never takes Run, however they travel.
func _test_pointer_roles_hold_wherever_the_pointers_travel(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var left := TouchControls.FOCUS_LEFT
	var right := TouchControls.FOCUS_RIGHT
	# Run leaves steering and the double-tap clock alone: a run finger landing between a steering
	# press and its second tap does not stand in for the first tap, so the second still doubles.
	_clock.now = 0.0
	_finger(controls, 0, left + Vector2.UP * 100.0, true)
	_clock.now = 0.1
	_finger(controls, 1, right, true)
	t.check(Input.is_action_pressed("run"), "a finger on Run holds it")
	_finger(controls, 1, right, false)
	_finger(controls, 0, left + Vector2.UP * 100.0, false)
	_clock.now = 0.3
	_finger(controls, 0, left + Vector2.UP * 100.0, true)
	t.check(Input.is_action_pressed("run"),
			"Run leaves steering and the double-tap clock alone: the second steering tap doubles")
	_finger(controls, 0, left + Vector2.UP * 100.0, false)
	_release_actions()
	_later()

	_finger(controls, 0, left + Vector2.UP * 100.0, true)
	_finger(controls, 1, right, true)
	t.check(Input.is_action_pressed("run") and _held_any_move(),
			"Run held while steering goes on")
	_finger_drag(controls, 0, Vector2(_edge(left), 480.0))
	t.check(not _held_any_move() and Input.is_action_pressed("run"),
			"band stops while Run stays held")
	_finger_drag(controls, 0, right + Vector2.DOWN * 100.0)
	t.check(_held_any_move() and controls.run_button_center() == right,
			"steering onto Run's half steers without moving the disc")
	var heading := TouchControls.current_heading()
	_finger_drag(controls, 1, left + Vector2.UP * 100.0)
	t.check(TouchControls.current_heading() == heading,
			"the run finger dragged onto the steering half does not steer")
	_later()
	_finger(controls, 2, right, true)
	_finger(controls, 1, left, false)
	t.check(Input.is_action_pressed("run"), "another run finger can take over the hold")
	_finger(controls, 2, right, false)
	t.check(not Input.is_action_pressed("run") and _held_any_move(),
			"last run release leaves steering intact")
	_finger(controls, 0, right + Vector2.DOWN * 100.0, false)
	t.check(_held_any_move() and not Input.is_action_pressed("run"),
			"the steering finger lifting on Run's half never took Run")
	controls.free()
	rig.free()
	_release_actions()

func _test_a_run_button_does_not_cancel_a_double_press_latch(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var at := TouchControls.FOCUS_LEFT + Vector2.UP * 100.0
	for _i in 2:
		_click(controls, at, true)
		_click(controls, at, false)
	t.check(Input.is_action_pressed("run"), "mouse double click latches Run")
	_finger(controls, 1, TouchControls.FOCUS_RIGHT, true)
	_finger(controls, 1, Vector2.ZERO, false)
	t.check(Input.is_action_pressed("run"), "run hold release preserves the independent latch")
	controls.free()
	rig.free()
	_release_actions()

## Pause preserves the sides and locked heading, but never revives a pointer hold; a change of
## scheme or side lets go of everything.
func _test_pause_hide_and_mode_changes_release_holds(t) -> void:
	var rig := _rig_at(t, Vector2(5000.0, 5000.0))
	var controls := await _controls(t)
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	var at := TouchControls.FOCUS_LEFT + Vector2.UP * 100.0
	_finger(controls, 0, at, true)
	_finger(controls, 1, TouchControls.FOCUS_RIGHT, true)
	var heading := TouchControls.current_heading()
	controls.remember_before_pause()
	t.get_tree().paused = true
	await UIScreens.frames(t)
	t.check(not Input.is_action_pressed("run") and not _held_any_move(),
			"pause cancels every pointer owner")
	t.get_tree().paused = false
	await UIScreens.frames(t)
	controls.resume_after_pause()
	t.check(TouchControls.current_heading().is_equal_approx(heading)
			and not Input.is_action_pressed("run")
			and controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"resume restores heading and sides without the run finger")
	# Where the old finger moves to, a steering drag would turn her toward: due east of the focus.
	_finger_drag(controls, 1, TouchControls.FOCUS_LEFT + Vector2.RIGHT * 100.0)
	_finger_drag(controls, 0, TouchControls.FOCUS_LEFT + Vector2.RIGHT * 100.0)
	t.check(TouchControls.current_heading().is_equal_approx(heading),
			"old finger motion after pause cannot acquire steering")
	_finger(controls, 1, TouchControls.FOCUS_RIGHT, true)
	controls.hide()
	t.check(not Input.is_action_pressed("run") and not _held_any_move(),
			"hiding releases held input")
	controls.show()
	_finger(controls, 1, TouchControls.FOCUS_RIGHT, true)
	controls.set_mode(ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT)
	t.check(not Input.is_action_pressed("run")
			and controls.run_button_center() == TouchControls.FOCUS_LEFT,
			"a change of side releases Run and moves its disc")
	_finger(controls, 1, TouchControls.FOCUS_LEFT, true)
	controls.set_mode(ControlsMode.Mode.TAP)
	t.check(not Input.is_action_pressed("run") and controls.run_button_center() == Vector2.INF,
			"mode change releases Run and removes its disc")
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	t.check(controls.run_button_center() == TouchControls.FOCUS_RIGHT,
			"returning to joystick has Run on screen at once")
	controls.free()
	rig.free()
	_release_actions()







## However a check above failed or passed, the movement actions, `run` and `pause` are global
## `Input` state — nothing about them is scoped to this suite's own nodes — so a failure that
## returns early must not leave one pressed for whatever test runs next.
## A touch fed through `_input` presses the pause action through buffered input, which the engine
## applies at the next frame; the buffer is flushed first so that the release is the last word and
## the press does not land after the suite is over.
func _release_actions() -> void:
	Input.flush_buffered_events()
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
	Input.action_release(&"pause")
