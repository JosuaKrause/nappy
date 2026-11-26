class_name BackToRouteWatcher
extends HintWatcher
## **Back to the tutorial route**: each time she starts to leave day 1's route before she has
## reached the park, a bubble points at the nearest tile of it, and stays while she is off it. It
## shows every time, and she may walk on regardless (gentle-owl #1253). Armed again once she is back
## on the route.

## Seconds she is off the route before the bubble goes up, so a corner cut does not flash one.
const OFF_ROUTE_SECONDS := 0.6
## How far, in tiles, the nearest tile of the route is looked for.
const SEARCH_TILES := 16

var _streets: DayStreets
var _map: CityMap
var _off_for := 0.0
var _armed := true
var _reached_the_park := false
var _way := Vector2.ZERO

func _init(streets: DayStreets, map: CityMap) -> void:
	_streets = streets
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

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var route := _streets.tutorial_route()
	if route == null:
		_reached_the_park = false
		_armed = true
		_off_for = 0.0
		return false
	if _reached_the_park:
		return false
	var tile := _map.world_to_tile(frame.position())
	if route.has_in_its_park(tile):
		_reached_the_park = true
		return false
	if route.runs_over(tile):
		_off_for = 0.0
		_armed = true
		return false
	_off_for += frame.delta()
	if _off_for < OFF_ROUTE_SECONDS or not _armed:
		return false
	_way = _toward_the_route(route, tile)
	return _way != Vector2.ZERO

## Overrides HintWatcher.direction.
func direction(frame: HintFrame) -> Vector2:
	var route := _streets.tutorial_route()
	var here := _map.world_to_tile(frame.position())
	var way := _toward_the_route(route, here) if route != null else Vector2.ZERO
	return way if way != Vector2.ZERO else _way

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

## Overrides HintWatcher.still_applies.
func still_applies(frame: HintFrame) -> bool:
	var route := _streets.tutorial_route()
	if route == null:
		return false
	var tile := _map.world_to_tile(frame.position())
	return not _reached_the_park and not route.runs_over(tile) \
			and not route.has_in_its_park(tile)

## The unit vector to the nearest tile of the route, searched in rings out from `tile`; zero when
## none lies within `SEARCH_TILES`.
func _toward_the_route(route: TutorialRoute, tile: Vector2i) -> Vector2:
	for ring in range(1, SEARCH_TILES + 1):
		var best := Vector2i(-1, -1)
		var best_distance := INF
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) != ring:
					continue
				var candidate := tile + Vector2i(x, y)
				if route.runs_over(candidate) and Vector2(x, y).length() < best_distance:
					best = candidate
					best_distance = Vector2(x, y).length()
		if best_distance < INF:
			return Vector2(best - tile).normalized()
	return Vector2.ZERO
