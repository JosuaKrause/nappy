class_name ButtonGeometry
extends RefCounted
## Round buttons catch at least five percent beyond their painted radius, for presses and hover
## alike, and never less than the catch they had before that margin was asked for *(2026-10-10, the
## player: "the 5% should go over the visible size making the area *larger*!")*. A button's catch is
## therefore the larger of its older, more generous catch and `CATCH_SCALE` times its painted radius.
## Joystick dead zones are steering geometry and deliberately do not use this margin. The title's
## Hard Mode checkbox is the one square target, and takes the same margin over its box and label
## through `margin_rect()`.

const CATCH_SCALE := 1.05

## The 5% margin alone: the smallest catch any round button may have.
static func margin_radius(visual_radius: float) -> float:
	return visual_radius * CATCH_SCALE

## The 5% margin of a rectangular target drawn at `drawn`: the same rectangle, `CATCH_SCALE` times
## its size each way, about its own centre.
static func margin_rect(drawn: Rect2) -> Rect2:
	var size := drawn.size * CATCH_SCALE
	return Rect2(drawn.get_center() - size * 0.5, size)

## Whether `point` is within the 5% margin of a round button painted at `center`.
static func contains(point: Vector2, center: Vector2, visual_radius: float) -> bool:
	return point.distance_squared_to(center) <= pow(margin_radius(visual_radius), 2.0)
