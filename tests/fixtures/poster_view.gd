extends RefCounted
## What the posters look like from the routes she walks: shared by `tests/test_posters.gd` (the
## density floors) and `tests/probes/merry_elk_poster_density.gd` (the measurement).
##
## Walks every route of every branch of the day's route tree cell by cell. The screen at a cell is
## the `Tuning.VIEW_HALF_EXTENT` box around it, and the sheets in view are the intact ones inside.
## A sheet is *underfoot* when its front tile (the sidewalk tile she must stand on to push it
## down) is one of the route's own tiles: the only sheets she can tear by accident.

## `{"cells", "with_sheet", "view_sum", "routes", "underfoot"}`: route cells walked, those with a
## sheet in view, the sum of sheets in view over all cells, then per route the distinct sheets
## seen and the distinct sheets underfoot.
static func walk(city: City, map: CityMap) -> Dictionary:
	var fronts: Array[Vector2i] = []
	var sheets: Array[Vector2] = []
	for tile: Vector2i in GameState.posters.cells:
		if GameState.posters.has_intact_sheet(tile):
			fronts.append(tile)
			sheets.append(map.tile_to_world(tile) + Vector2(0, -Tuning.TILE_SIZE * 0.5))
	var found := {"cells": 0, "with_sheet": 0, "view_sum": 0, "routes": [], "underfoot": []}
	var tree := city.route_tree()
	if tree == null:
		return found
	for branch in tree.branches:
		for route in branch.routes:
			var seen := {}
			var under := {}
			for cell: Vector2i in route:
				var origin: Vector2i = cell * ReachabilityGrid.CELL
				var at := map.tile_to_world(origin + Vector2i.ONE)
				var here := 0
				for i in sheets.size():
					var d := (sheets[i] - at).abs()
					if d.x <= Tuning.VIEW_HALF_EXTENT.x and d.y <= Tuning.VIEW_HALF_EXTENT.y:
						here += 1
						seen[i] = true
					var f := fronts[i] - origin
					if f.x >= 0 and f.y >= 0 and f.x < ReachabilityGrid.CELL \
							and f.y < ReachabilityGrid.CELL:
						under[i] = true
				found["cells"] += 1
				found["with_sheet"] += 1 if here > 0 else 0
				found["view_sum"] += here
			(found["routes"] as Array).append(seen.size())
			(found["underfoot"] as Array).append(under.size())
	return found
