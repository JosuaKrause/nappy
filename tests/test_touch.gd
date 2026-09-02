extends RefCounted
## The on-screen stick, and the two things a screenshot cannot show: that it disappears on the
## platforms and the screens it must, and that a finger on it presses the same actions a keyboard
## does.
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
	t.get_tree().paused = was_paused
	_release_move_actions()

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

## However a check above failed or passed, the four movement actions are global `Input` state —
## nothing about them is scoped to this suite's own nodes — so a failure that returns early must
## not leave a direction pressed for whatever test runs next.
func _release_move_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
