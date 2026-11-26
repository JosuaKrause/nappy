class_name BackToRouteWatcher
extends HintWatcher
## **Back to the tutorial route**: each time she starts to leave day 1's route before she has
## reached the park, a bubble points at the nearest tile of it. It shows every time, and she may
## walk on regardless (gentle-owl #1253). Armed again once she is back on the route. The route is
## handed at each walk's start (`begin_walk()`), so a retried day 1 watches it afresh.
##
## *Proposed, not asked for*, each open to the player's overturn: **the bubble stays up for as
## long as she is off the route** (the plainer alternative is a bubble that stands a few seconds
## like the others), and **it waits `OFF_ROUTE_SECONDS` before going up**, so a corner cut does not
## flash one. A higher hint replaces a lower one that is up (`HintWatch`), so the wait does not
## let the zebra's bubble win the moment both apply.

## Seconds she is off the route before the bubble goes up.
const OFF_ROUTE_SECONDS := 0.6
## How far, in tiles, the nearest tile of the route is looked for.
const SEARCH_TILES := 16

## A tile no search is ever asked from, so the first ask always searches.
const NOWHERE := Vector2i(-1000000, -1000000)
var _map: CityMap
var _route: TutorialRoute = null
var _off_for := 0.0
var _armed := true
var _reached_the_park := false
## The last answer of the search for the route, and the tile it was asked from: the search runs
## once per tile she stands on, not once a tick.
var _way := Vector2.ZERO
var _way_from := NOWHERE

func _init(map: CityMap) -> void:
	_map = map

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.BACK_TO_ROUTE

## Overrides HintWatcher.every_time.
func every_time() -> bool:
	return true

## Overrides HintWatcher.holds_while_true.
func holds_while_true() -> bool:
	return true

## Overrides HintWatcher.begin_walk.
func begin_walk(route: TutorialRoute) -> void:
	_route = route
	_off_for = 0.0
	_armed = true
	_reached_the_park = false
	_way = Vector2.ZERO
	_way_from = NOWHERE

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	if _route == null or _reached_the_park:
		return false
	var tile := _map.world_to_tile(frame.position())
	if _route.has_in_its_park(tile):
		_reached_the_park = true
		return false
	if _route.runs_over(tile):
		_off_for = 0.0
		_armed = true
		return false
	_off_for += frame.delta()
	if _off_for < OFF_ROUTE_SECONDS or not _armed:
		return false
	return _toward_the_route(tile) != Vector2.ZERO

## Overrides HintWatcher.direction.
func direction(frame: HintFrame) -> Vector2:
	if _route == null:
		return Vector2.ZERO
	return _toward_the_route(_map.world_to_tile(frame.position()))

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

## Overrides HintWatcher.still_applies.
func still_applies(frame: HintFrame) -> bool:
	if _route == null or _reached_the_park:
		return false
	var tile := _map.world_to_tile(frame.position())
	return not _route.runs_over(tile) and not _route.has_in_its_park(tile)

## The unit vector to the nearest tile of the route from `tile`, searched in rings, once per tile.
## Past `SEARCH_TILES` the search finds nothing and the last way found stands.
func _toward_the_route(tile: Vector2i) -> Vector2:
	if tile == _way_from:
		return _way
	_way_from = tile
	var found := _search(tile)
	if found != Vector2.ZERO:
		_way = found
	return _way

func _search(tile: Vector2i) -> Vector2:
	for ring in range(1, SEARCH_TILES + 1):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) != ring:
					continue
				var candidate := tile + Vector2i(x, y)
				if _route.runs_over(candidate) and Vector2(x, y).length() < best_distance:
					best = candidate
					best_distance = Vector2(x, y).length()
		if best_distance < INF:
			return Vector2(best - tile).normalized()
	return Vector2.ZERO
