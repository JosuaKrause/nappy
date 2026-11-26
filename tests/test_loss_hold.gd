extends RefCounted
## `LossHold`: the beat a lost day holds before its summary. Its framing is pure geometry, checked
## on plain values; its timing and its skip are watched through real physics frames on a bare
## `Camera2D` standing for hers (the viewport's current camera), so the camera it makes current,
## the camera it hands back and what it says when it ends are what the game sees.

const VIEW := Vector2(1280.0, 720.0)
const ZOOM := 2.0

func run(t: TestRunner) -> void:
	await _test_two_near_things_keep_her_own_zoom_and_the_midpoint(t)
	await _test_a_far_cause_zooms_out_until_both_fit(t)
	await _test_a_cause_too_far_to_frame_keeps_her_in_the_picture(t)
	await _test_a_turned_view_frames_along_its_own_axes(t)
	await _test_the_beat_eases_holds_and_gives_the_view_back(t)
	await _test_a_loss_no_one_thing_caused_holds_on_her(t)
	await _test_a_tap_ends_the_beat_at_once(t)

## Where `world` falls on a screen centred on `centre` at `zoom`, turned by `turned`, in screen
## px from its middle.
func _on_screen(world: Vector2, centre: Vector2, zoom: float, turned: float) -> Vector2:
	return (world - centre).rotated(-turned) * zoom

## The framing the beat eases to for her at `her` and a cause at `cause`, read off the camera it
## makes current once the ease is over: `{"centre": Vector2, "zoom": float}`. Her own camera is
## turned by `turned` radians.
func _framed(t: TestRunner, her: Vector2, cause: Vector2, turned: float) -> Dictionary:
	var hers := _her_camera(t, her)
	hers.ignore_rotation = false
	hers.rotation = turned
	var hold := _hold(t)
	hold.begin(hers, her, cause, VIEW)
	var arrived := int(ceil(LossHold.EASE_SECONDS * float(Engine.physics_ticks_per_second))) + 2
	for _frame in arrived:
		await t.get_tree().physics_frame
	var camera := t.get_viewport().get_camera_2d()
	var framing := {"centre": camera.global_position, "zoom": camera.zoom.x}
	t.get_viewport().push_input(_press_key())
	t.get_tree().paused = false
	hold.free()
	hers.free()
	return framing

func _test_two_near_things_keep_her_own_zoom_and_the_midpoint(t: TestRunner) -> void:
	var her := Vector2(1000.0, 1000.0)
	var cause := Vector2(1100.0, 1040.0)
	var framing := await _framed(t, her, cause, 0.0)
	t.close_to(framing["zoom"], ZOOM, "both in view already: her own zoom")
	var centre: Vector2 = framing["centre"]
	t.check(centre.is_equal_approx((her + cause) * 0.5), "centred halfway between them (%s)" % centre)

func _test_a_far_cause_zooms_out_until_both_fit(t: TestRunner) -> void:
	var her := Vector2(1000.0, 1000.0)
	var cause := Vector2(1000.0 + 560.0, 1200.0)
	var framing := await _framed(t, her, cause, 0.0)
	var zoom: float = framing["zoom"]
	var centre: Vector2 = framing["centre"]
	t.check(zoom < ZOOM and zoom >= ZOOM * LossHold.FARTHEST_ZOOM, "zoomed out to fit (%s)" % zoom)
	for point: Vector2 in [her, cause]:
		var seen := _on_screen(point, centre, zoom, 0.0).abs()
		t.check(seen.x <= VIEW.x * 0.5 - LossHold.MARGIN + 0.5
				and seen.y <= VIEW.y * 0.5 - LossHold.MARGIN + 0.5,
				"%s stands inside the margin (%s)" % [point, seen])

func _test_a_cause_too_far_to_frame_keeps_her_in_the_picture(t: TestRunner) -> void:
	var her := Vector2(1000.0, 1000.0)
	var cause := Vector2(6000.0, 1000.0)
	var framing := await _framed(t, her, cause, 0.0)
	var zoom: float = framing["zoom"]
	var centre: Vector2 = framing["centre"]
	t.close_to(zoom, ZOOM * LossHold.FARTHEST_ZOOM, "no further out than the farthest zoom")
	var seen := _on_screen(her, centre, zoom, 0.0).abs()
	t.check(seen.x <= VIEW.x * 0.5 - LossHold.MARGIN + 0.5 and seen.y <= VIEW.y * 0.5,
			"and she is still in the picture, inside the margin (%s)" % seen)
	t.check(centre.x > her.x, "the picture leans toward the cause as far as it can (%s)" % centre)

func _test_a_turned_view_frames_along_its_own_axes(t: TestRunner) -> void:
	var her := Vector2(1000.0, 1000.0)
	# Apart along the world's y: with the view turned a quarter, that is the screen's long side.
	var cause := Vector2(1000.0, 1000.0 + 900.0)
	var straight: Dictionary = await _framed(t, her, cause, 0.0)
	var turned_view: Dictionary = await _framed(t, her, cause, PI * 0.5)
	var straight_zoom: float = straight["zoom"]
	var turned_zoom: float = turned_view["zoom"]
	t.check(turned_zoom > straight_zoom, "a turned view has the long side to spare (%s against %s)"
			% [turned_zoom, straight_zoom])
	var centre: Vector2 = turned_view["centre"]
	var seen := _on_screen(cause, centre, turned_zoom, PI * 0.5).abs()
	t.check(seen.x <= VIEW.x * 0.5 and seen.y <= VIEW.y * 0.5, "and the cause is on screen (%s)" % seen)

## A camera standing for hers, current in the viewport.
func _her_camera(t: TestRunner, at: Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.name = "HerCamera"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.position = at
	t.add_child(camera)
	camera.make_current()
	return camera

## A hold that runs while the tree is paused, as it does under `Main`.
func _hold(t: TestRunner) -> LossHold:
	var hold := LossHold.new()
	hold.name = "LossHold"
	hold.process_mode = Node.PROCESS_MODE_ALWAYS
	t.add_child(hold)
	return hold

## Frames until `ends` counts one, at most `limit`.
func _until(t: TestRunner, ends: Array[int], limit: int) -> int:
	var frames := 0
	while ends[0] == 0 and frames < limit:
		await t.get_tree().physics_frame
		frames += 1
	return frames

func _test_the_beat_eases_holds_and_gives_the_view_back(t: TestRunner) -> void:
	var her := _her_camera(t, Vector2(1000.0, 1000.0))
	var hold := _hold(t)
	var ends: Array[int] = [0]
	hold.finished.connect(func() -> void: ends[0] += 1)
	var cause := Vector2(1300.0, 1000.0)
	hold.begin(her, Vector2(1000.0, 1000.0), cause, VIEW)
	t.check(t.get_tree().paused, "the world stops on the frame of the loss")
	var camera := t.get_viewport().get_camera_2d()
	t.check(camera != null and camera.name == "LossCamera", "its own camera is the one drawing")
	var ticks := float(Engine.physics_ticks_per_second)
	var eased := int(ceil(LossHold.EASE_SECONDS * ticks)) + 2
	for _frame in eased:
		await t.get_tree().physics_frame
	var middle := (Vector2(1000.0, 1000.0) + cause) * 0.5
	t.check(camera.global_position.distance_to(middle) < 1.0,
			"the ease has arrived on her and the cause together (%s, wanted %s)"
			% [camera.global_position, middle])
	t.check(ends[0] == 0, "and it is still holding there")
	var frames := await _until(t, ends, 600)
	var wanted := int(ceil(LossHold.HOLD_SECONDS * ticks))
	t.check(ends[0] == 1 and absi(frames - wanted) <= 4,
			"it ends once, a hold after the ease (%d frames after, wanted about %d)" % [frames, wanted])
	t.check(t.get_viewport().get_camera_2d() == her, "and the view goes back to hers")
	for _frame in 5:
		await t.get_tree().physics_frame
	t.check(ends[0] == 1, "a finished beat says nothing more")
	t.get_tree().paused = false
	hold.free()
	her.free()

func _test_a_loss_no_one_thing_caused_holds_on_her(t: TestRunner) -> void:
	var her := _her_camera(t, Vector2(500.0, 500.0))
	var hold := _hold(t)
	var ends: Array[int] = [0]
	hold.finished.connect(func() -> void: ends[0] += 1)
	hold.hold_on_her()
	t.check(t.get_viewport().get_camera_2d() == her, "her own camera keeps drawing")
	var total := int(ceil((LossHold.EASE_SECONDS + LossHold.HOLD_SECONDS)
			* float(Engine.physics_ticks_per_second)))
	var frames := await _until(t, ends, 600)
	t.check(ends[0] == 1 and absi(frames - total) <= 4,
			"it holds the whole beat and ends once (%d frames, wanted about %d)" % [frames, total])
	t.get_tree().paused = false
	hold.free()
	her.free()

func _test_a_tap_ends_the_beat_at_once(t: TestRunner) -> void:
	for tap: InputEvent in [_press_mouse(), _press_touch(), _press_key()]:
		var her := _her_camera(t, Vector2.ZERO)
		var hold := _hold(t)
		var ends: Array[int] = [0]
		hold.finished.connect(func() -> void: ends[0] += 1)
		hold.begin(her, Vector2.ZERO, Vector2(200.0, 0.0), VIEW)
		for _frame in 3:
			await t.get_tree().physics_frame
		t.check(ends[0] == 0 and hold.is_running(), "a few ticks in, the beat is running")
		t.get_viewport().push_input(tap)
		t.check(ends[0] == 1 and not hold.is_running(),
				"a %s ends it on the spot" % tap.get_class())
		t.check(t.get_viewport().get_camera_2d() == her, "and gives the view back")
		t.get_tree().paused = false
		hold.free()
		her.free()

func _press_mouse() -> InputEvent:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	return press

## A finger on the phone's screen, the tap the beat names.
func _press_touch() -> InputEvent:
	var press := InputEventScreenTouch.new()
	press.position = VIEW * 0.5
	press.pressed = true
	return press

func _press_key() -> InputEvent:
	var press := InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	return press
