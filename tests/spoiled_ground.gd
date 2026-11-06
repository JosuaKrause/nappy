class_name SpoiledGround
extends RefCounted
## **A copy of the scheduler's spoil rule, kept in the tests on purpose**: a calm area is spoiled when
## the field of some event the day placed reaches it. It is stated from the plans' public answers
## (`Planned.is_placed()`, `EventDef.field_reach()`) so the suites that hold the scheduler to "the
## day leaves an open calm area clean" judge the day against a definition that is not the
## scheduler's own, and it must be kept in step with `EventScheduler._reaches_rect()` by hand. A
## playground and a scar (`AMBIENT`) and a permanent body do not count. The scheduler's own
## `_is_spoiled()` only chooses which calm ground the walkability repair keeps a route to, and no
## suite builds a day where that choice binds, so nothing here would fail if it always answered no.
## A helper, not a suite: the runner loads only `test_*.gd`.

## Whether some placed event of `planned` has its field reaching `rect`, in tiles of `map`.
static func by(map: CityMap, planned: Array[EventScheduler.Planned], rect: Rect2i) -> bool:
	var lot := map.tile_rect_to_world(rect)
	for plan in planned:
		if plan.def.kind == GameEnums.EventKind.AMBIENT or not plan.is_placed() or plan.permanent:
			continue
		var grown := lot.grow(plan.def.field_reach())
		if grown.has_point(plan.position):
			return true
		for point in plan.path:
			if grown.has_point(point):
				return true
	return false
