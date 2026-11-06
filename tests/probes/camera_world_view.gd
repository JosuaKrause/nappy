extends RefCounted
## The world rectangle a viewport's camera shows, read off the engine's canvas transform: what the
## ground-frame probes hold the coverage they check against, so a camera that was moved without the
## residency being told shows up as a difference between the two.

## The rectangle of the world `viewport` draws now, corner to corner of its visible rect.
static func of(viewport: Viewport) -> Rect2:
	var inverse := viewport.get_canvas_transform().affine_inverse()
	var size := viewport.get_visible_rect().size
	var rect := Rect2(inverse * Vector2.ZERO, Vector2.ZERO)
	for corner: Vector2 in [Vector2(size.x, 0), size, Vector2(0, size.y)]:
		rect = rect.expand(inverse * corner)
	return rect
