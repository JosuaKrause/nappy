class_name ScenerySprite
extends Node2D
## A persistent placement whose renderer commands are released outside the retained view.
## Visibility remains the owner's gameplay fact (for example an emptied street-tree pit).

## Its standing with the scenery residency, which the city registers it with (`residence()`).
var _residence := SceneryResidence.new(self, _scenery_bounds, _apply_residence)

## What the scenery residency asks of this placement: whether its pictures are resident, the ground
## they cover, and the switch between the two.
func residence() -> SceneryResidence:
	return _residence

## Frees the placement's renderer commands once it is no longer resident, and redraws it either
## way.
func _apply_residence(resident: bool) -> void:
	if not resident:
		RenderingServer.canvas_item_clear(get_canvas_item())
	queue_redraw()

## Conservative fallback for street-kit panels, their shadows, and the 256px border structures.
func _scenery_bounds() -> Rect2:
	return Rect2(global_position - Vector2(256, 256), Vector2(512, 512))
