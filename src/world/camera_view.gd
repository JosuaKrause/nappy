class_name CameraView
extends RefCounted
## The world rectangle a camera shows: its viewport's size at its zoom, turned with the camera (a
## camera turned a quarter shows the world rect the other way round, the phone's rotated
## presentation), centred where the camera looks once its limits have clamped it. One place works
## it out, for whoever prepares the scenery a view is about to draw (`DayDirector` round her,
## `Main` round the opening shot's park).

## The world rect `camera`, in the tree, shows in a viewport of `viewport_size`.
static func shown_by(camera: Camera2D, viewport_size: Vector2) -> Rect2:
	camera.force_update_scroll()
	var size := viewport_size / camera.zoom
	var angle := camera.global_rotation
	var world_size := Vector2(absf(cos(angle)) * size.x + absf(sin(angle)) * size.y,
			absf(sin(angle)) * size.x + absf(cos(angle)) * size.y)
	return Rect2(camera.get_screen_center_position() - world_size * 0.5, world_size)
