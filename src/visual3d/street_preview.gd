extends Node3D
## Camera, lighting, and small presentation controls for the standalone city art preview.
##
## The camera is orthographic so a later visual adapter can map 2D x/y to x/z without a
## perspective vanishing point. Pausing the scene also pauses the cosmetic paper motion.

var _day14 := false
var _city: Node3D
var _state_label: Label
var _capture_path := ""
var _capture_late := false

const ORTHO_PITCH_DEGREES := 65.0
const MAP_Z_COMPENSATION := 1.0 / sin(deg_to_rad(ORTHO_PITCH_DEGREES))
const CAMERA_DISTANCE := 34.22

## Keeps a future visual adapter's x/y map coordinates legible after the camera compresses z.
static func map_2d_to_world(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.0, point.y * MAP_Z_COMPENSATION)

func _ready() -> void:
	# The shell stays responsive while the model subtree pauses, so SPACE can resume the preview.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var camera: Camera3D = get_node("Camera3D") as Camera3D
	var pitch := deg_to_rad(ORTHO_PITCH_DEGREES)
	camera.position = Vector3(0.0, sin(pitch) * CAMERA_DISTANCE, cos(pitch) * CAMERA_DISTANCE)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	_city = get_node("CityModels") as Node3D
	_state_label = get_node("Overlay/State") as Label
	_read_capture_flag()
	_apply_day(_capture_late)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_D:
		_apply_day(not _day14)
	elif event.keycode == KEY_SPACE:
		get_tree().paused = not get_tree().paused

func _read_capture_flag() -> void:
	const prefix := "--preview-capture="
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	for index in arguments.size():
		var argument: String = arguments[index]
		if argument.begins_with(prefix):
			_capture_path = argument.trim_prefix(prefix)
		elif argument == "--preview-late":
			_capture_late = true
	if _capture_path.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		return
	# Let each pose settle before saving; the final stage exits the preview after the stills are written.
	get_tree().create_timer(1.0).timeout.connect(_capture_stage.bind("early"))
	get_tree().create_timer(3.0).timeout.connect(_capture_stage.bind("late"))
	get_tree().create_timer(4.0).timeout.connect(_capture_stage.bind("turn"))

func _capture_stage(stage: String) -> void:
	if stage == "late":
		_apply_day(true)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var stem := _capture_path.trim_suffix(".png")
	var error: Error = image.save_png("%s-%s.png" % [stem, stage])
	if error != OK:
		push_error("preview capture failed (%s): %s" % [stage, error])
	if stage == "turn":
		get_tree().quit()

func _apply_day(day14: bool) -> void:
	_day14 = day14
	if is_instance_valid(_city):
		_city.call("set_day14", _day14)
	if is_instance_valid(_state_label):
		_state_label.text = "DAY 14  ·  WEATHERED" if _day14 else "DAY 1  ·  FRESH"
