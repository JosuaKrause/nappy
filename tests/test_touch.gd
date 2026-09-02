extends RefCounted
## The on-screen stick and run button, and the two things a screenshot cannot show: that they
## disappear on the platforms and the screens they must, and that a finger on either presses the
## same actions a keyboard does.
##
## `_touch` is read once into a member exactly the way `QuitOption.available()` and `hud._debug`
## are — a headless test process is never a touch device, so a gate asked of `TouchInput` at each
## use site would leave this whole class asserted by nothing.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
	_test_the_stick_shows_only_on_a_touch_device_with_a_day_running(t)
	_test_the_stick_presses_the_move_actions(t)
	_test_hiding_the_stick_releases_everything_it_held(t)
	_test_the_run_button_holds_run_independently_of_the_stick(t)
	_test_hiding_the_controls_releases_the_run_button_too(t)
	_test_the_pause_button_sends_a_real_action_event(t)
	_test_the_pause_button_fires_on_release_inside_and_not_outside(t)
	_test_the_pause_button_tracks_its_own_touch_index(t)
	t.get_tree().paused = was_paused
	_release_actions()

func _controls(t) -> TouchControls:
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_process(false)
	return controls

## **Both gates, independently.** Neither a keyboard-and-mouse desktop nor a phone mid-pause should
## ever see the stick — the first because `TouchInput.available()` says there is no touch hardware
## to draw it for, the second because `get_tree().paused` is what the title, the pause and the
## between-days summary all set, and none of the three has anything for a thumb to steer.
func _test_the_stick_shows_only_on_a_touch_device_with_a_day_running(t) -> void:
	var controls := _controls(t)

	controls._touch = false
	t.get_tree().paused = false
	controls._process(0.0)
	t.check(not controls.visible, "no touch hardware means no stick, even mid-day")

	controls._touch = true
	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not controls.visible, "a touch device still gets nothing while the tree is paused")

	controls._touch = true
	t.get_tree().paused = false
	controls._process(0.0)
	t.check(controls.visible, "and it shows once both are true")

	controls.queue_free()

## The whole point of the stick: it presses `Input.get_vector`'s own four actions, with the raw
## deflection as the strength, so `Stroller` never has to learn a thumb was involved.
func _test_the_stick_presses_the_move_actions(t) -> void:
	var controls := _controls(t)
	controls.visible = true

	controls._input(_touch_event(0, TouchControls.STICK_CENTRE + Vector2(0.0, -1.0), true))
	t.check(Input.is_action_pressed("move_up"), "pressing straight up presses move_up")
	t.check(not Input.is_action_pressed("move_down"), "and not the opposite direction on that axis")
	t.check(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"nor anything on the other axis")

	# Dragging the same touch index out to the full radius is a full-strength push, the same
	# reading a fully-tilted analogue stick gives `Input.get_vector`'s own deadzone.
	controls._input(_drag_event(0,
			TouchControls.STICK_CENTRE + Vector2(0.0, -TouchControls.STICK_RADIUS)))
	t.close_to(Input.get_action_strength("move_up"), 1.0,
			"a full deflection presses at full strength")

	# A drag under a different index is not the finger that grabbed the stick.
	controls._input(_drag_event(1, TouchControls.STICK_CENTRE + Vector2(80.0, 0.0)))
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_right"),
			"a second finger dragging elsewhere does not steal the stick")

	controls._input(_touch_event(0, Vector2.ZERO, false))
	t.check(not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down")
			and not Input.is_action_pressed("move_left")
			and not Input.is_action_pressed("move_right"),
			"letting go of the stick's own finger centres it and releases every direction")

	controls.queue_free()

## **A finger still down when the day ends must not carry into the day after it.** The stick has no
## way to be told the tree is about to pause mid-gesture — the summary just sets it — so it is the
## stick's own job to let go of everything the instant it notices, on the same check that hides it.
func _test_hiding_the_stick_releases_everything_it_held(t) -> void:
	var controls := _controls(t)
	controls._touch = true
	t.get_tree().paused = false
	controls._process(0.0)

	controls._input(_touch_event(0,
			TouchControls.STICK_CENTRE + Vector2(TouchControls.STICK_RADIUS, 0.0), true))
	t.check(Input.is_action_pressed("move_right"), "the stick is holding a direction")

	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not controls.visible, "the stick disappears with the tree paused")
	t.check(not Input.is_action_pressed("move_right"),
			"and lets go of the direction rather than carrying it into tomorrow")

	controls.queue_free()

## **Never the far end of the stick's own push.** The button is a separate touch index on the
## opposite side of the screen, so both this and a full stick deflection can be held at once,
## exactly as `Shift` and an arrow key can — which is the whole reason a stick threshold was
## rejected: `Stroller` reads the stick's raw deflection, and a threshold on it would have made
## the one deliberate act in the game a gradient a thumb could cross by accident.
func _test_the_run_button_holds_run_independently_of_the_stick(t) -> void:
	var controls := _controls(t)
	controls.visible = true

	controls._input(_touch_event(0,
			TouchControls.STICK_CENTRE + Vector2(0.0, -TouchControls.STICK_RADIUS), true))
	t.check(Input.is_action_pressed("move_up") and not Input.is_action_pressed("run"),
			"the stick alone does not hold run")

	controls._input(_touch_event(1, TouchControls.RUN_CENTRE, true))
	t.check(Input.is_action_pressed("run") and Input.is_action_pressed("move_up"),
			"a second finger on the button holds run alongside the stick's own direction")

	controls._input(_touch_event(1, Vector2.ZERO, false))
	t.check(not Input.is_action_pressed("run") and Input.is_action_pressed("move_up"),
			"letting go of the button releases run and leaves the stick alone")

	controls._input(_touch_event(0, Vector2.ZERO, false))
	controls.queue_free()

## The same guarantee the stick gets, extended to the button: a thumb still holding it down when a
## day ends must not run the whole of tomorrow's opening stride for free.
func _test_hiding_the_controls_releases_the_run_button_too(t) -> void:
	var controls := _controls(t)
	controls._touch = true
	t.get_tree().paused = false
	controls._process(0.0)

	controls._input(_touch_event(0, TouchControls.RUN_CENTRE, true))
	t.check(Input.is_action_pressed("run"), "the button is holding run")

	t.get_tree().paused = true
	controls._process(0.0)
	t.check(not controls.visible, "the controls disappear with the tree paused")
	t.check(not Input.is_action_pressed("run"),
			"and run is let go of rather than carried into tomorrow")

	controls.queue_free()

## **The pause is not a held action, and firing it needs a real propagated event, not polled
## state.** `main._unhandled_input()` reads `event.is_action_pressed("pause")` off the event
## itself, so `Input.action_press(&"pause")` — the mechanism the stick and RUN use — would set
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
## for free.** The stick and RUN commit the instant a thumb lands; the pause button waits for the
## matching release, and only counts one still over the button, the opposite of the stick and RUN
## on purpose — pressed once a day at most, a false fire costs more than a missed one.
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
	controls.queue_free()

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
