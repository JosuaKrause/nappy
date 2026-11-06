class_name DoorLine
extends RefCounted
## **A copy of the door-line geometry of `CheckpointController._where_she_crossed()`, kept in the tests
## on purpose**: the line through a district door body's centre across its facing, within the body's
## own reach along it. It is stated from the body's public position, facing and `obstructs_radius`
## so the suites that hold a siting to "his run at her never crosses a door" judge it against a
## geometry that is not the controller's own, and it must be kept in step with the controller by
## hand. A helper, not a suite: the runner loads only `test_*.gd`.

## Whether the straight step from `was` to `here` crosses the line through `at` across `axis`, within
## `reach` of `at` along the line. Level with the line counts as the positive side.
static func crossed_by(at: Vector2, axis: Vector2, reach: float, was: Vector2, here: Vector2) -> bool:
	var before := (was - at).dot(axis)
	var after := (here - at).dot(axis)
	if (before < 0.0) == (after < 0.0):
		return false
	var crossing := was.lerp(here, before / (before - after))
	var offset := crossing - at
	return (offset - axis * offset.dot(axis)).length() <= reach
