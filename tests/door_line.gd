class_name DoorLine
extends RefCounted
## **The line across a street that a district door stands on**, stated for the suites that hold a
## placement to "his run at her never crosses a door": the line through the door body's centre
## across its facing, within the body's own reach along it. Stated here from the body's public
## answers (position, facing, `obstructs_radius`), so a suite checks the siting against a geometry
## that is not the controller's own detection. A helper, not a suite: the runner loads only `test_*.gd`.

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
