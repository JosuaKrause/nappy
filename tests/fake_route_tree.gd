class_name FakeRouteTree
extends RouteTree
## A stand-in for the day's route tree whose answers a check sets: the streets her routes run
## along and the junctions they cross, on the city's whole lattice (`StreetNetwork`), so a
## `Corridor` is made of it (`Corridor.of()`) without growing a tree on a city. Every street not set
## is one turning off the routes; nothing is a gap or a set piece's site. The real tree's own logic is
## checked in `tests/test_route_tree.gd`. A helper, not a suite: the runner loads only `test_*.gd`.

var _fake_network := StreetNetwork.new()
var _fake_depths := {}
var _fake_junctions: Array[Vector2i] = []

## A tree on a grid over `map`, the ground the corridor answers about.
func _init(map: CityMap) -> void:
	grid = ReachabilityGrid.build(map)
	for segment in _fake_network.segments():
		_fake_depths[segment.key()] = 1

## Sets the streets her routes run along (`StreetNetwork.Segment.key()`) and the junctions they cross.
func set_routes(streets: Array[Vector3i], junctions: Array[Vector2i]) -> FakeRouteTree:
	for key in streets:
		_fake_depths[key] = 0
	_fake_junctions = junctions
	return self

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

