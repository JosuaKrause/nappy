class_name FakeRouteTree
extends RouteTree
## A stand-in for the day's route tree whose answers a check sets: the streets her routes run
## along and the junctions they cross, on the city's whole lattice (`StreetNetwork`), so a
## `Corridor` is made of it (`Corridor.of()`) without growing a tree on a city. Every street not set
## is one turning off the routes; nothing is a gap. The real tree's own logic is
## checked in `tests/test_route_tree.gd`. A helper, not a suite: the runner loads only `test_*.gd`.

var _fake_network := StreetNetwork.new()
var _fake_depths := {}
var _fake_junctions: Array[Vector2i] = []
var _fake_cells_ahead := {}
var _fake_carried := {}

## A tree on a grid over `map`, the ground the corridor answers about.
func _init(map: CityMap) -> void:
	_map = map
	_grid = ReachabilityGrid.build(map)
	for segment in _fake_network.segments():
		_fake_depths[segment.key()] = 1

## Sets the streets her routes run along (`StreetNetwork.Segment.key()`) and the junctions they cross.
func set_routes(streets: Array[Vector3i], junctions: Array[Vector2i]) -> FakeRouteTree:
	for key in streets:
		_fake_depths[key] = 0
	_fake_junctions = junctions
	return self

## Sets the cells her way ahead runs over, as `cell -> how far she walks to reach it`
## (`RouteTree.cells_ahead()`), whatever `at` and `heading` are asked.
func set_cells_ahead(cells: Dictionary) -> FakeRouteTree:
	_fake_cells_ahead = cells
	return self

## Sets the tiles the tree carries a route along (`RouteTree.branches_on()`, `carries_a_route()`).
func set_carried_tiles(tiles: Array[Vector2i]) -> FakeRouteTree:
	for tile in tiles:
		_fake_carried[tile] = true
	return self

## One branch on every tile set, none elsewhere.
##
## Overrides RouteTree.branches_on.
func branches_on(tile: Vector2i) -> Array[int]:
	var found: Array[int] = []
	if _fake_carried.has(tile):
		found.append(0)
	return found

## Whether the tile is one set.
##
## Overrides RouteTree.carries_a_route.
func carries_a_route(tile: Vector2i) -> bool:
	return _fake_carried.has(tile)

## The cells set that lie no further than `limit`.
##
## Overrides RouteTree.cells_ahead.
func cells_ahead(_at: Vector2, _heading: Vector2, limit: float) -> Dictionary:
	var found := {}
	for cell: Vector2i in _fake_cells_ahead:
		if float(_fake_cells_ahead[cell]) <= limit:
			found[cell] = _fake_cells_ahead[cell]
	return found

## Whether the cells set hold the cell of `position`, true with none set.
##
## Overrides RouteTree.is_ahead.
func is_ahead(_at: Vector2, _heading: Vector2, position: Vector2) -> bool:
	if _fake_cells_ahead.is_empty():
		return true
	return _fake_cells_ahead.has(_cell_of(position))

## Overrides RouteTree.network.
func network() -> StreetNetwork:
	return _fake_network

## Overrides RouteTree.junctions.
func junctions() -> Array[Vector2i]:
	return _fake_junctions

## Overrides RouteTree.node_depths.
func node_depths() -> Dictionary:
	return {}

## Overrides RouteTree.segment_depths.
func segment_depths() -> Dictionary:
	return _fake_depths

## Overrides RouteTree.gaps.
func gaps() -> Array[Vector3i]:
	return []

