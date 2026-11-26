class_name CameraFocus
extends CrowdFocus
## The crowd's focus source while a camera other than hers is the view: the patch of simulated
## streets stands where that camera looks (`OpeningShot`'s), so the cars and walkers are the ones
## in the picture and none is simulated round a door the camera has left. Handed to
## `Crowd.use_focus()` for the shot's length; `StrollerFocus` comes back when she is handed to the
## crowd at play's start.
##
## A camera that has left the tree is no longer asked: the last place it looked is kept, so a tick
## that runs between the camera's end and the next focus source asks a point and not a freed node.

var _camera: Camera2D
var _last := Vector2.ZERO

func _init(camera: Camera2D) -> void:
	_camera = camera
	_last = camera.global_position

## Overrides CrowdFocus.where.
func where() -> Vector2:
	if is_instance_valid(_camera) and _camera.is_inside_tree():
		_last = _camera.get_screen_center_position()
	return _last
