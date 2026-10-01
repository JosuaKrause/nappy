class_name ScenerySprite
extends Node2D
## A persistent placement whose renderer commands are released outside the retained view.
## Visibility remains the owner's gameplay fact (for example an emptied street-tree pit).

var scenery_resident := true

func set_scenery_resident(resident: bool) -> void:
	if scenery_resident == resident:
		return
	scenery_resident = resident
	if not resident:
		RenderingServer.canvas_item_clear(get_canvas_item())
	queue_redraw()

## Conservative fallback for street-kit panels, their shadows, and the 256px border structures.
func scenery_bounds() -> Rect2:
	return Rect2(global_position - Vector2(256, 256), Vector2(512, 512))
