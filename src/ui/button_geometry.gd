class_name ButtonGeometry
extends RefCounted
## Round buttons catch five percent beyond their painted radius, for presses and hover alike.
## Joystick dead zones are steering geometry and deliberately do not use this margin.

const CATCH_SCALE := 1.05

static func contains(point: Vector2, center: Vector2, visual_radius: float) -> bool:
	return point.distance_squared_to(center) <= pow(visual_radius * CATCH_SCALE, 2.0)
