class_name WayToParkWatcher
extends HintWatcher
## **The way to the park**, day 1's first lesson: when play starts, and each time she comes to a
## junction the tutorial route turns at, the bubble points her along the route to the next one,
## until she is in the park (curly-moose #819: a direction to a park on day 1). The route is handed
## at each walk's start (`begin_walk()`), so a retried day 1 shows it from the start again.

var _map: CityMap
var _waypoints: RouteWaypoints = null
var _next := 0
var _armed := false

func _init(map: CityMap) -> void:
	_map = map

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WAY_TO_PARK

## Overrides HintWatcher.begin_walk.
func begin_walk(route: TutorialRoute) -> void:
	_waypoints = RouteWaypoints.new(route, _map) if route != null else null
	_next = 0
	_armed = route != null

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	if _waypoints == null or _next >= _waypoints.count():
		return false
	var tile := _map.world_to_tile(frame.position())
	if _waypoints.has_reached(_waypoints.count() - 1, tile):
		_next = _waypoints.count()
		return false
	if _waypoints.has_reached(_next, tile):
		_next += 1
		_armed = true
	return _armed

## Overrides HintWatcher.direction.
func direction(frame: HintFrame) -> Vector2:
	if _waypoints == null or _next >= _waypoints.count():
		return Vector2.ZERO
	return (_waypoints.point(_next) - frame.position()).normalized()

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false
