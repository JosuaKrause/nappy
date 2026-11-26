class_name WayToParkWatcher
extends HintWatcher
## **The way to the park**, day 1's first lesson: when play starts, and each time she comes to a
## junction the tutorial route turns at, the bubble points her along the route to the next one,
## until she is in the park (curly-moose #819: a direction to a park on day 1).

## How near a point of the route counts as having come to it: the width of its street's box.
const REACHED_WITHIN := Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5

var _streets: DayStreets
var _map: CityMap
var _route: TutorialRoute = null
var _waypoints: RouteWaypoints = null
var _next := 0
var _armed := true

func _init(streets: DayStreets, map: CityMap) -> void:
	_streets = streets
	_map = map

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.WAY_TO_PARK

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var route := _streets.tutorial_route()
	if route != _route:
		_route = route
		_waypoints = RouteWaypoints.new(route, _map) if route != null else null
		_next = 0
		_armed = true
	if _route == null:
		return false
	if _next >= _waypoints.count() or _route.has_in_its_park(_map.world_to_tile(frame.position())):
		_next = _waypoints.count()
		return false
	if frame.position().distance_to(_waypoints.point(_next)) < REACHED_WITHIN \
			and _next < _waypoints.count() - 1:
		_next += 1
		_armed = true
	return _armed

## Overrides HintWatcher.direction.
func direction(frame: HintFrame) -> Vector2:
	return (_waypoints.point(_next) - frame.position()).normalized()

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false
