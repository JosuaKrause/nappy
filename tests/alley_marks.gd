extends RefCounted
## **Where a chalk mark stands in its alley and where its guard stands, worked out from the map
## alone**, for the resistance suites: the test's own statement of the rules the director places by
## (`docs/CITY.md`, the alleys; `ResistanceDirector`'s placement docs), so a sweep grades the director
## against a rule it does not run. A helper, not a suite: the runner loads only `test_*.gd`.

## An alley's mouth, worked out from the map alone: the end tile of a through-alley along its long
## axis, or a courtyard passage's tile beside walkable ground that is neither alley nor courtyard.
static func is_a_mouth(map: CityMap, tile: Vector2i) -> bool:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			var vertical := rect.size.y >= rect.size.x
			var along := tile.y - rect.position.y if vertical else tile.x - rect.position.x
			var length := rect.size.y if vertical else rect.size.x
			return along == 0 or along == length - 1
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var type := map.tile_at(tile + step)
		if map.is_walkable(tile + step) and type != GameEnums.TileType.ALLEY \
				and type != GameEnums.TileType.COURTYARD:
			return true
	return false

## The tile a mark stands on for the alley whose mouth is `mouth`: one step in from it along a
## through-alley's long axis (`CityMap.alley_rects`), and for a courtyard's passage the next
## walkable alley or courtyard tile away from the street. `mouth` itself where no tile lies in from it.
static func mark_tile_of_mouth(map: CityMap, mouth: Vector2i) -> Vector2i:
	for rect in map.alley_rects:
		if not rect.has_point(mouth):
			continue
		var step := Vector2i.ZERO
		if rect.size.y >= rect.size.x:
			step = Vector2i.DOWN if mouth.y == rect.position.y else Vector2i.UP
		else:
			step = Vector2i.RIGHT if mouth.x == rect.position.x else Vector2i.LEFT
		var inner := mouth + step
		return inner if rect.has_point(inner) else mouth
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var inner := mouth + step
		var type := map.tile_at(inner)
		if (type == GameEnums.TileType.ALLEY or type == GameEnums.TileType.COURTYARD) \
				and map.is_walkable(inner):
			return inner
	return mouth

## A through-alley's two end tiles along its long axis, in the row or column of `tile`, as world
## points, the one nearer `at` first; empty when `tile` is in no through-alley (a courtyard's passage
## or no alley at all).
static func through_ends(map: CityMap, tile: Vector2i, at: Vector2) -> Array[Vector2]:
	var ends: Array[Vector2] = []
	for rect in map.alley_rects:
		if not rect.has_point(tile):
			continue
		var a: Vector2
		var b: Vector2
		if rect.size.y >= rect.size.x:
			a = map.tile_to_world(Vector2i(tile.x, rect.position.y))
			b = map.tile_to_world(Vector2i(tile.x, rect.end.y - 1))
		else:
			a = map.tile_to_world(Vector2i(rect.position.x, tile.y))
			b = map.tile_to_world(Vector2i(rect.end.x - 1, tile.y))
		if at.distance_to(a) <= at.distance_to(b):
			ends.append(a)
			ends.append(b)
		else:
			ends.append(b)
			ends.append(a)
		return ends
	return ends

## Where the guard of a mark at `mark` (on `tile`) in a through-alley stands before anything refuses
## his ground: **two-thirds of the alley's length from the edge nearer the mark**, plus the tile the
## mark stands in from its mouth, or `min_distance` past the mark along the alley where that is
## nearer; `Vector2.INF` for a mark in no through-alley.
static func expected_guard_spot(map: CityMap, tile: Vector2i, mark: Vector2,
		min_distance: float) -> Vector2:
	var ends := through_ends(map, tile, mark)
	if ends.size() != 2:
		return Vector2.INF
	var axis := (ends[1] - ends[0]).normalized()
	var near_edge := ends[0] - axis * Tuning.TILE_SIZE * 0.5
	var length := ends[0].distance_to(ends[1]) + Tuning.TILE_SIZE
	var tile_in := clampf((mark - near_edge).dot(axis) - Tuning.TILE_SIZE * 0.5, 0.0,
			Tuning.TILE_SIZE)
	var two_thirds := near_edge + axis * (length * 2.0 / 3.0 + tile_in)
	var catch_floor := mark + axis * min_distance
	if (two_thirds - near_edge).dot(axis) < (catch_floor - near_edge).dot(axis):
		return catch_floor
	return two_thirds

## The courtyard a mark at `tile` leads into: the courtyard it stands in (a one-tile passage puts the
## mark on the courtyard's first tile), or the one a longer passage runs straight into. An empty rect
## for a mark in a through-alley.
static func courtyard_of(map: CityMap, tile: Vector2i) -> Rect2i:
	for rect in map.alley_rects:
		if rect.has_point(tile):
			return Rect2i()
	for court in map.courtyard_rects:
		if court.has_point(tile):
			return court
	for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var at := tile
		while map.tile_at(at) == GameEnums.TileType.ALLEY:
			at += step
		for court in map.courtyard_rects:
			if court.has_point(at):
				return court
	return Rect2i()

## The courtyard tile `court` holds that is farthest from `mark` (the first in row order among
## equals), as a world point: where the guard of a mark in a courtyard's passage stands, or as near
## it as the courtyard allows.
static func courtyard_inner_end(map: CityMap, court: Rect2i, mark: Vector2) -> Vector2:
	var farthest := Vector2.INF
	var farthest_distance := -1.0
	for y in range(court.position.y, court.end.y):
		for x in range(court.position.x, court.end.x):
			var world := map.tile_to_world(Vector2i(x, y))
			if mark.distance_to(world) > farthest_distance:
				farthest_distance = mark.distance_to(world)
				farthest = world
	return farthest
