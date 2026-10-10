class_name ButtonGeometry
extends RefCounted
## Round buttons catch at least five percent beyond their painted radius, for presses and hover
## alike, and never less than the catch they had before that margin was asked for *(2026-10-10, the
## player: "the 5% should go over the visible size making the area *larger*!")*. A button's catch is
## therefore the larger of its older, more generous catch and `CATCH_SCALE` times its painted radius.
## Joystick dead zones are steering geometry and deliberately do not use this margin.

const CATCH_SCALE := 1.05

## The 5% margin alone: the smallest catch any round button may have.
static func margin_radius(visual_radius: float) -> float:
	return visual_radius * CATCH_SCALE

## Whether `point` is within the 5% margin of a round button painted at `center`.
static func contains(point: Vector2, center: Vector2, visual_radius: float) -> bool:
	return point.distance_squared_to(center) <= pow(margin_radius(visual_radius), 2.0)
