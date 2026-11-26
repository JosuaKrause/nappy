class_name RouteWaypoints
extends RefCounted
## **Where day 1's tutorial route turns, in order**: the junction box of each junction it passes
## (`TutorialRoute.junctions()`, the one it leaves the doorstep's street at first), then the
## tutorial park. Worked out once from the route and the map at the walk's start, for the hint that
## points her along it (`WayToParkWatcher`). A junction is reached when she stands in its box.

var _points: Array[Vector2] = []
var _boxes: Array[Rect2i] = []
var _route: TutorialRoute

func _init(route: TutorialRoute, map: CityMap) -> void:
	_route = route
	for junction in route.junctions():
		var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		_boxes.append(box)
		_points.append(map.tile_rect_to_world(box).get_center())
	_points.append(map.tile_rect_to_world(CityMap.block_rect(route.park_block())).get_center())

## How many points the route turns at, the park's last.
func count() -> int:
	return _points.size()

## The `index`th point, in the world.
func point(index: int) -> Vector2:
	return _points[index]

## Whether she has come to the `index`th point standing on `tile`: inside its junction box, or
## for the last, inside the tutorial park.
func has_reached(index: int, tile: Vector2i) -> bool:
	if index < _boxes.size():
		return _boxes[index].has_point(tile)
	return _route.has_in_its_park(tile)
