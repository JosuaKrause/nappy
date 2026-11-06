class_name SpoiledGround
extends RefCounted
## **Whether a day's plans spoil a stretch of ground**, the way a player meets it: a calm area is
## spoiled when the field of some event the day placed reaches it. Stated here from the plans' own
## public answers (`Planned.is_placed()`, `EventDef.field_reach()`), so the suites that hold the
## scheduler to "the day leaves an open calm area clean" check it against a definition that is not
## the scheduler's own. A playground and a scar (`AMBIENT`) and a permanent body do not count. A
## helper, not a suite: the runner loads only `test_*.gd`.

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
