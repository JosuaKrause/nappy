class_name FakeCorridor
extends Corridor
## A stand-in for the day's corridor whose answers a check sets: the streets her routes run along,
## the junctions they cross, the tiles a route runs along, the streets beside the routes and the
## street they start in, on the city's whole lattice (`StreetNetwork`), so a street rule is asked
## on a hand-drawn map without a route tree grown on a city. Every street not set is one turning
## off the routes and off the route; a tile on no street is on the routes only where its tile is
## set. What it answers from those (`walked_sidewalks()`) is the real corridor's own reading. The
## real corridor is checked in `tests/test_route_tree.gd`. A helper, not a suite: the runner loads
## only `test_*.gd`.

var _lattice := StreetNetwork.new()
var _route_streets := {}
var _beside := {}
var _route_tiles := {}
var _crossed: Array[Vector2i] = []
var _home: StreetNetwork.Segment = null

## Sets the streets her routes run along (`StreetNetwork.Segment.key()`), the junctions they cross
## and the tiles a route runs along (a walked sidewalk's, an alley's).
func set_routes(streets: Array[Vector3i], junctions: Array[Vector2i],
		tiles: Array[Vector2i]) -> FakeCorridor:
	for key in streets:
		_route_streets[key] = true
	_crossed = junctions
	for tile in tiles:
		_route_tiles[tile] = true
	return self

## Sets the streets beside the routes (`Corridor.view_of()`'s route-adjacent).
func set_beside(streets: Array[Vector3i]) -> FakeCorridor:
	for key in streets:
		_beside[key] = true
	return self

## Sets the street the routes start in (`Corridor.street_it_starts_in()`), the home street.
func set_home_street(key: Vector3i) -> FakeCorridor:
	_home = _lattice.by_key(key)
	return self

## Overrides Corridor.street_it_starts_in.
func street_it_starts_in() -> StreetNetwork.Segment:
	return _home

## Overrides Corridor.depth.
func depth(tile: Vector2i) -> int:
	var segment := _lattice.segment_containing(tile)
	if segment:
		return 0 if _route_streets.has(segment.key()) else 1
	return 0 if _route_tiles.has(tile) else DEEP

## Overrides Corridor.carries_a_route.
func carries_a_route(tile: Vector2i) -> bool:
	return _route_tiles.has(tile)

## Overrides Corridor.route_junctions.
func route_junctions() -> Array[Vector2i]:
	return _crossed

## Overrides Corridor.view_of.
func view_of(segment: StreetNetwork.Segment) -> int:
	if _route_streets.has(segment.key()):
		return PlacementView.View.ON_THE_ROUTE
	if _beside.has(segment.key()):
		return PlacementView.View.ROUTE_ADJACENT
	return PlacementView.View.OFF_THE_ROUTE
