extends RefCounted
## The rotated presentation for a portrait touch window — see `ScreenOrientation`.
##
## The one thing that can break silently: the stick, the run button and the pause button all
## grab a touch by comparing its position to a fixed constant, so a rotation that draws the
## controls in the right place while the remap it needs is missing, wrong, or falls out of sync
## with the draw transform would pass every visual screenshot check and still put a thumb's press
## under the wrong control. This suite proves the remap by construction: a touch sent at the
## exact screen position `ScreenOrientation.to_presented_space()` says a design-space point ends
## up at, while rotated, must be read back by `TouchControls` as that same design-space point.

const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

func run(t) -> void:
	_test_wants_rotation_only_for_a_portrait_touch_window(t)
	_test_content_scale_size_matches_the_rotated_or_unrotated_design_box(t)
	_test_the_transform_sends_the_design_centre_to_the_rotated_centre(t)
	_test_the_transform_round_trips(t)
	_test_a_rotated_touch_still_grabs_the_stick(t)
	_test_a_rotated_touch_still_holds_the_run_button(t)
	_test_a_rotated_touch_still_fires_the_pause_button(t)
	_release_actions()

func _controls(t) -> TouchControls:
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_process(false)
	controls.visible = true
	return controls

## **Only a touch device in a portrait window rotates.** A narrow desktop window is portrait too,
## and `export_presets.cfg`'s own retired rotate overlay used to gate its message on
## `(hover: none) and (pointer: coarse)` alongside `(orientation: portrait)` for exactly the
## reason repeated here: nobody resizing a desktop window narrower than it is tall asked for a
## sideways game.
func _test_wants_rotation_only_for_a_portrait_touch_window(t: Node) -> void:
	t.check(not ScreenOrientation.wants_rotation(Vector2(1280.0, 720.0), true),
			"a landscape window does not rotate even on a touch device")
	t.check(not ScreenOrientation.wants_rotation(Vector2(400.0, 900.0), false),
			"a narrow window with no touch hardware is left alone")
	t.check(ScreenOrientation.wants_rotation(Vector2(400.0, 900.0), true),
			"a portrait window on a touch device rotates")

func _test_content_scale_size_matches_the_rotated_or_unrotated_design_box(t: Node) -> void:
	t.check(Vector2(ScreenOrientation.content_scale_size(false)) == ScreenOrientation.DESIGN_SIZE,
			"unrotated presents at the project's own 1280x720")
	t.check(Vector2(ScreenOrientation.content_scale_size(true)) == ScreenOrientation.ROTATED_SIZE,
			"rotated presents at the swapped 720x1280 -- the box a real touch then arrives in")

## Rotating about the centre of one box onto the centre of the other is the simplest thing that
## can be wrong in either direction (swapped axes, a stray translation) and still look plausible,
## so it is worth its own check before the round trip below is trusted.
func _test_the_transform_sends_the_design_centre_to_the_rotated_centre(t: Node) -> void:
	var mapped := ScreenOrientation.to_presented_space(ScreenOrientation.DESIGN_SIZE * 0.5, true)
	t.check(mapped.is_equal_approx(ScreenOrientation.ROTATED_SIZE * 0.5),
			"the centre of the 1280x720 box lands on the centre of the 720x1280 one")

## **A relationship, not a value**: whatever `rotation_transform()` actually is, going out and
## back must be the identity, for several points including ones outside the design box (where a
## touch on the letterboxed edge of a non-16:9 window would land).
func _test_the_transform_round_trips(t: Node) -> void:
	for point in [Vector2(130.0, 500.0), Vector2(1150.0, 500.0), Vector2(1250.0, 30.0),
			Vector2.ZERO, Vector2(-40.0, 800.0)]:
		var there := ScreenOrientation.to_presented_space(point, true)
		var back := ScreenOrientation.to_design_space(there, true)
		t.check(back.is_equal_approx(point),
				"round-tripping %s through the rotation lands back on itself" % point)

## **The test that proves the thing a screenshot cannot**: a touch at the screen position the
## stick is actually drawn at while rotated must still grab the stick, and must still read the
## deflection in the same direction a keyboard's `move_up` would.
func _test_a_rotated_touch_still_grabs_the_stick(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var design_touch := TouchControls.STICK_CENTRE + Vector2(0.0, -1.0)
	var screen_touch := ScreenOrientation.to_presented_space(design_touch, true)
	controls._input(_touch_event(0, screen_touch, true))
	t.check(Input.is_action_pressed("move_up"),
			"a rotated touch at the stick's own screen position still presses move_up")

	var design_drag := TouchControls.STICK_CENTRE + Vector2(0.0, -TouchControls.STICK_RADIUS)
	var screen_drag := ScreenOrientation.to_presented_space(design_drag, true)
	controls._input(_drag_event(0, screen_drag))
	t.close_to(Input.get_action_strength("move_up"), 1.0,
			"a full deflection at its own rotated screen position still reads full strength")

	controls._input(_touch_event(0, ScreenOrientation.to_presented_space(Vector2.ZERO, true),
			false))
	controls.queue_free()

func _test_a_rotated_touch_still_holds_the_run_button(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var screen_run := ScreenOrientation.to_presented_space(TouchControls.RUN_CENTRE, true)
	controls._input(_touch_event(0, screen_run, true))
	t.check(Input.is_action_pressed("run"),
			"a rotated touch at the run button's own screen position holds run")

	controls._input(_touch_event(0, screen_run, false))
	t.check(not Input.is_action_pressed("run"), "and releasing there lets go of it again")
	controls.queue_free()

func _test_a_rotated_touch_still_fires_the_pause_button(t: Node) -> void:
	var controls := _controls(t)
	controls.rotated = true

	var screen_pause := ScreenOrientation.to_presented_space(TouchControls.PAUSE_CENTRE, true)
	controls._input(_touch_event(0, screen_pause, true))
	t.check(controls._pause_touch == 0,
			"a rotated touch at the pause button's own screen position grabs its index")

	controls._input(_touch_event(0, screen_pause, false))
	t.check(controls._pause_touch == -1, "and releasing there lets the index go again")

	# The geometry the release itself asks is answered in design space (`_pause_fires` is a pure
	# function over the space `TouchControls` keeps everything else in) -- the remap above is
	# what has to hand it the right point, which is exactly what this whole suite is checking.
	t.check(TouchControls._pause_fires(TouchControls.PAUSE_CENTRE),
			"the pure geometry check underneath is untouched by rotation")

	controls.queue_free()
	Input.action_release(&"pause")

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

## Global `Input` state, same reason `test_touch.gd` cleans it up: nothing here is scoped to this
## suite's own nodes.
func _release_actions() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")
	Input.action_release(&"pause")
