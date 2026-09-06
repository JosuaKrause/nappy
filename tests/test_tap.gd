extends RefCounted
## `TapControls`' own geometry and its wiring to a rig — the parts a screenshot cannot check: that
## the pressed direction matches the press's own unit vector, that it stays locked in with nothing
## held down, and that a double press needs both its windows before it reads as a modifier rather
## than a new direction.

func run(t) -> void:
	# Several tests below toggle the tree's own pause, the same guard `test_touch.gd` takes for
	# the same reason: whatever this suite runs under must not be left paused for the next one.
	var was_paused: bool = t.get_tree().paused
	_test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t)
	_test_is_double_tap_needs_both_windows(t)
	_test_set_direction_presses_the_components_of_the_heading(t)
	_test_set_direction_on_her_own_position_stops_rather_than_pressing(t)
	_test_a_tap_within_the_stop_radius_stops_her(t)
	_test_a_direction_stays_locked_in_with_nothing_held_down(t)
	_test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t)
	_test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t)
	_test_a_tap_during_a_pause_does_nothing(t)
	_test_a_pause_force_releases_a_held_direction(t)
	_test_a_mouse_click_stands_in_for_a_tap(t)
	_test_a_touch_devices_own_emulated_click_is_ignored(t)
	t.get_tree().paused = was_paused
	_release_actions()

func _rig_at(position: Vector2) -> Node2D:
	var rig := Node2D.new()
	rig.global_position = position
	rig.add_to_group("player")
	return rig

func _test_heading_to_is_the_unit_vector_and_zero_for_a_tap_on_herself(t) -> void:
	var direction := TapControls.heading_to(Vector2(0.0, 100.0), Vector2.ZERO)
	t.close_to(direction.length(), 1.0, "the heading is a unit vector")
	t.check(direction.is_equal_approx(Vector2.DOWN), "pointing straight at the target")
	t.check(TapControls.heading_to(Vector2(10.0, 10.0), Vector2(10.0, 10.0)) == Vector2.ZERO,
			"a tap on her own position has no line to walk")

func _test_is_double_tap_needs_both_windows(t) -> void:
	t.check(TapControls.is_double_tap(0.1, 10.0), "soon and close reads as a double tap")
	t.check(not TapControls.is_double_tap(1.0, 10.0), "close but late is a new single tap")
	t.check(not TapControls.is_double_tap(0.1, 400.0),
			"soon but far away is a new direction, not a modifier on the old one")

func _test_set_direction_presses_the_components_of_the_heading(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.set_direction(Vector2(100.0, -100.0), false)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("move_up"),
			"a diagonal press presses both components of its own unit vector")
	t.check(not Input.is_action_pressed("run"), "a single press does not hold run")

	tap.set_direction(Vector2(-100.0, -100.0), true)
	t.check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),
			"a new press the other way releases the axis it no longer wants")
	t.check(Input.is_action_pressed("run"), "a double press holds run")

	tap.free()
	rig.free()

## `set_direction()`'s own fallback for the degenerate case: a target exactly on top of her has no
## heading to compute, and it now stops her rather than doing nothing — see the class doc for why
## that is strictly more useful and is what was asked for.
func _test_set_direction_on_her_own_position_stops_rather_than_pressing(t) -> void:
	# Leftover state from the previous test's own double press, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(Vector2(50.0, 50.0))
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking first, so there is something for landing on her to let go of")

	tap.set_direction(Vector2(50.0, 50.0), false)
	t.check(not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
			and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down")
			and not Input.is_action_pressed("run"),
			"landing exactly on her own position stops her rather than pressing nothing")
	t.check(not tap._walking, "and she is no longer walking")

	tap.free()
	rig.free()

## **The generous radius, not the exact pixel.** *(2026-09-06: "also, to stop her just click on
## her".)* `STOP_RADIUS` is wide enough to catch a press on the pram, which rides up to
## `PRAM_DISTANCE` off to one side of her, not only a press on her own exact world position.
func _test_a_tap_within_the_stop_radius_stops_her(t) -> void:
	var rig := _rig_at(Vector2(200.0, 200.0))
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	var transform: Transform2D = tap.get_viewport().get_canvas_transform()

	tap._on_tap(transform * Vector2(500.0, 200.0), 0.0)
	t.check(Input.is_action_pressed("move_right"), "walking first, so a stop has something to undo")

	# 30px off her own position -- within STOP_RADIUS (48px), covering the pram at PRAM_DISTANCE
	# (34px) as well as her own PLAYER_BODY_RADIUS (14px).
	tap._on_tap(transform * Vector2(230.0, 200.0), 1.0)
	t.check(not Input.is_action_pressed("move_right") and not tap._walking,
			"a press near her, not only exactly on her, stops her")

	# Well outside the radius sets a direction instead.
	tap._on_tap(transform * Vector2(500.0, 200.0), 2.0)
	t.check(Input.is_action_pressed("move_right") and tap._walking,
			"a press outside the stop radius sets a direction instead")

	tap.free()
	rig.free()

## **There is no arrival any more.** A direction pressed once stays held, unrenewed, however long
## `_process()` is asked to run — the whole of what "she walks it until the next press" means.
func _test_a_direction_stays_locked_in_with_nothing_held_down(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds the direction and, on a double press, run")

	rig.global_position = Vector2(500.0, 0.0)
	for _i in 100:
		tap._process(0.016)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking well past where a target used to sit still holds the same direction")

	tap.free()
	rig.free()

## **The test a screenshot cannot be**: `_on_tap()`'s own reverse of the transform `DangerEdge` and
## `HomeArrow` already read forwards. Constructed from the viewport's own real
## `get_canvas_transform()` rather than an assumed identity, so this would still catch a camera
## offset or a rotation the way a hard-coded expectation would not.
func _test_a_tap_maps_its_screen_position_through_the_viewports_canvas_transform(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	var world_target := Vector2(120.0, -40.0)
	var screen_position: Vector2 = tap.get_viewport().get_canvas_transform() * world_target
	tap._on_tap(screen_position, 0.0)
	t.check(Input.is_action_pressed("move_right"),
			"a tap's own screen position maps back to the world position it was aimed at")

	tap.free()
	rig.free()

## The double-tap windows again, now through the real entry point rather than the pure function
## directly -- a close tap soon after runs, and either window failing on its own falls back to a
## fresh single tap.
func _test_a_close_quick_second_tap_runs_and_a_far_or_late_one_does_not(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	var transform: Transform2D = tap.get_viewport().get_canvas_transform()

	tap._on_tap(transform * Vector2(100.0, 0.0), 10.0)
	t.check(not Input.is_action_pressed("run"), "the first tap of a run only walks")

	tap._on_tap(transform * Vector2(100.0, 0.0), 10.2)
	t.check(Input.is_action_pressed("run"), "soon and on the same spot reads as a double tap")

	tap._on_tap(transform * Vector2(500.0, 500.0), 10.4)
	t.check(not Input.is_action_pressed("run"),
			"soon but far away is a new direction, not a double tap on the old one")

	tap._on_tap(transform * Vector2(500.0, 500.0), 12.0)
	t.check(not Input.is_action_pressed("run"), "close but late is also a new single tap")

	tap.free()
	rig.free()

## Paused for any reason -- Esc, the day ending, the title -- a tap does nothing, the same as every
## one of those screens already leaving the stick's own controls drawing nothing.
func _test_a_tap_during_a_pause_does_nothing(t) -> void:
	# Leftover state from the previous test's own tap, not this one's concern to leave held.
	_release_actions()
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)
	t.get_tree().paused = true

	tap._on_tap(tap.get_viewport().get_canvas_transform() * Vector2(50.0, 0.0), 0.0)
	t.check(not Input.is_action_pressed("move_right") and not tap._walking,
			"a tap during a pause does nothing at all")

	tap.free()
	rig.free()

## A direction left pressed into whatever comes next is the same leak
## `TouchControls._release_all()` already guards its own controls against on every kind of hiding.
func _test_a_pause_force_releases_a_held_direction(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	tap.set_direction(Vector2(100.0, 0.0), true)
	t.check(Input.is_action_pressed("move_right") and Input.is_action_pressed("run"),
			"walking holds a direction and, on a double press, run")

	t.get_tree().paused = true
	tap._process(0.016)
	t.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("run"),
			"Esc or any other pause force-releases whatever was held")
	t.check(not tap._walking, "and abandons the direction rather than merely pausing mid-stride")

	tap.free()
	rig.free()

## "On non-mobile we can try clicking with the mouse instead of tapping" -- a left click reaches
## `_on_tap()` exactly the way a finger's own `InputEventScreenTouch` does. This suite's own process
## is always a debug build, the same as every other dev-only path in this project, so the gate
## itself is not what this checks; only that a click is read at all.
func _test_a_mouse_click_stands_in_for_a_tap(t) -> void:
	# Leftover pause from the previous test's own pause check, not this one's concern.
	t.get_tree().paused = false
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	t.add_child(tap)

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = tap.get_viewport().get_canvas_transform() * Vector2(100.0, 0.0)
	tap._input(click)
	t.check(Input.is_action_pressed("move_right"), "a left click walks exactly as a tap would")

	# A right click, or the release half of a left one, is not a tap.
	var release := click.duplicate()
	release.pressed = false
	tap._input(release)
	var other_button := InputEventMouseButton.new()
	other_button.button_index = MOUSE_BUTTON_RIGHT
	other_button.pressed = true
	other_button.position = tap.get_viewport().get_canvas_transform() * Vector2(-100.0, 0.0)
	tap._input(other_button)
	t.check(not Input.is_action_pressed("move_left"), "only a left click's own press is a tap")

	tap.free()
	rig.free()

## **The gate that makes the mouse stand-in safe on a real touch device.** Godot emulates a mouse
## click from every real touch by default (`input_devices/pointing/emulate_mouse_from_touch`), so
## without `not _touch` a single tap would fire `_on_tap()` twice, once through each event, at the
## same place and the same instant -- close enough on both windows to read as its own double tap.
## This is the bug a first version of `--tap` actually hit: a lone `--tap` on a screenshot rig run
## with `--touch` came back running, not walking.
func _test_a_touch_devices_own_emulated_click_is_ignored(t) -> void:
	var rig := _rig_at(Vector2.ZERO)
	t.add_child(rig)
	var tap := TapControls.new()
	tap._touch = true
	t.add_child(tap)

	var touch := InputEventScreenTouch.new()
	touch.position = tap.get_viewport().get_canvas_transform() * Vector2(100.0, 0.0)
	touch.pressed = true
	tap._input(touch)
	t.check(not Input.is_action_pressed("run"), "the real touch alone only walks")

	# The engine's own emulated click, same place, same instant -- exactly what a real touch device
	# would also deliver right behind the touch above.
	var emulated := InputEventMouseButton.new()
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.position = touch.position
	tap._input(emulated)
	t.check(not Input.is_action_pressed("run"),
			"a touch device's own emulated click is not read as a second, doubling tap")

	tap.free()
	rig.free()

func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
