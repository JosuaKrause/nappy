class_name NarrowTargetPool
extends RefCounted
## The tiles a narrow task's contact may stand on: the pool of a day whose target is one named place
## (`ResistanceSteps.narrow_target_on()` names the step), computed from the city's map and the
## day's region plan. It is half of a route guarantee (`docs/CITY.md`, "Guarantees"): the closures
## and the day's route rules keep one tile of it reachable from home, and the director draws the
## contact from the same tiles.

## Every tile `step`'s contact may stand on, before any of today's refusals — the pool
## `ResistanceDirector._place_contact()` draws from, and the pool the day's planning keeps one reachable
## tile of. One function for both, so the tiles the planning protects are the tiles the director
## picks among. `region_plan` is today's (`DayStreets.region_plan()`); only a `DOOR` reads it.
##
## - **`DOOR`**: the middle tile of each of today's region-wall doors, **less any door whose own
##   segment borders the home block**. `RegionPlanner._union_atoms()` only atomises the one street
##   the doorstep notch opens onto, so the block's other bordering segments can become doors like
##   any other; the director places a door with `allow_held`, which skips `is_held_at()` — the half
##   of "nothing on the home block" that covers those streets (`CityMap.is_on_home_block`'s own doc
##   names `is_held_at` as the other half) — so the filter here is what keeps such a door out.
## - **`PARK_SWING`**: the swing of the one park the city chose for the task
##   (`CityGenerator.swing_park()`), which is forced open on the task's day whatever its arc has
##   reached (`CityState.purpose_of()`), at the point `City._dress_block()` draws the frame
##   (`CityMap.swing_position()`). Empty while that park is not open — on any other day, or once
##   she has taken it.
## - **`STATION_DOOR`**: the pavement tiles in front of the power station's front door
##   (`CityMap.power_station_door_tiles()`), where she stands to reach it — the same tiles the day's
##   corridor grows its spur to (`RouteTree.for_day`). Empty on a city with no station, which
##   `CityGenerator.validation_problems()` refuses.
static func tiles(step: ResistanceSteps.Step, map: CityMap,
		region_plan: RegionPlan) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	if not step or not map:
		return found
	if step.target_kind == ResistanceSteps.TargetKind.STATION_DOOR:
		return map.rect_tiles(map.power_station_door_tiles()) if map.has_power_station() else found
	if step.target_kind == ResistanceSteps.TargetKind.DOOR:
		if not region_plan:
			return found
		var home_border := {}
		for segment in map.street_network().around_blocks(Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
			home_border[segment.key()] = true
		for segment in region_plan.door_segments():
			if home_border.has(segment.key()):
				continue
			var rect := segment.tile_rect()
			found.append(rect.position + rect.size / 2)
		return found
	if step.target_kind == ResistanceSteps.TargetKind.PARK_SWING:
		var park := CityGenerator.swing_park(map)
		var layout: BlockLayout = map.layout_of(park)
		if layout and layout.playground_rect() in map.playground_rects():
			found.append(map.world_to_tile(map.swing_position(layout.playground_rect())))
	return found
