extends Node3D
## Camera, lighting, and small presentation controls for the standalone city art preview.
##
## The camera is orthographic so a later visual adapter can map 2D x/y to x/z without a
## perspective vanishing point. Pausing the scene also pauses the cosmetic paper motion.

var _day14 := false
var _city: Node3D
var _state_label: Label

const ORTHO_PITCH_DEGREES := 65.0
const MAP_Z_COMPENSATION := 1.0 / sin(deg_to_rad(ORTHO_PITCH_DEGREES))

## Keeps a future visual adapter's x/y map coordinates legible after the camera compresses z.
static func map_2d_to_world(point: Vector2) -> Vector3:
	return Vector3(point.x, 0.0, point.y * MAP_Z_COMPENSATION)

func _ready() -> void:
	# The shell stays responsive while the model subtree pauses, so SPACE can resume the preview.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var camera: Camera3D = get_node("Camera3D") as Camera3D
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	_city = get_node("CityModels") as Node3D
	_state_label = get_node("Overlay/State") as Label
	_apply_day(false)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_D:
		_apply_day(not _day14)
	elif event.keycode == KEY_SPACE:
		get_tree().paused = not get_tree().paused

func _apply_day(day14: bool) -> void:
	_day14 = day14
	if is_instance_valid(_city):
		_city.call("set_day14", _day14)
	if is_instance_valid(_state_label):
		_state_label.text = "DAY 14  ·  WEATHERED" if _day14 else "DAY 1  ·  FRESH"
