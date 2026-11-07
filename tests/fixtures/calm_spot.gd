class_name CalmSpot
extends RefCounted
## Where a rig stands her to settle in a calm area: a tile of the area's own calm ground.
##
## A calm block's own rect is not calm ground everywhere — a courtyard's calm is the court inside a
## residential block, so the block's centre can be a building — and a rig that stands her there
## measures a pavement or a roof. The calm ground is what `ClosurePlanner.calm_area_rect()` names,
## the rect the scheduler also keeps clean.

## The calm tile of `block`'s calm ground nearest that ground's centre, as a world position, or
## `Vector2.INF` when none of it is calm today.
static func of(map: CityMap, block: Vector2i) -> Vector2:
	var rect := ClosurePlanner.calm_area_rect(map, block)
	var centre := map.tile_rect_to_world(rect).get_center()
	var best := Vector2.INF
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var tile := Vector2i(x, y)
			var at := map.tile_to_world(tile)
			if Tile.is_calm(map.tile_at(tile)) and at.distance_to(centre) < best.distance_to(centre):
				best = at
	return best
