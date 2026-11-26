class_name RouteWaypoints
extends RefCounted
## **Where day 1's tutorial route turns, in order, as world points**: the junction at the start of
## each lesson street, then the middle of the tutorial park. Worked out once from the route and the
## map, for the hints that point her along it and back to it.

var _points: Array[Vector2] = []

func _init(route: TutorialRoute, map: CityMap) -> void:
	for street in route.lesson_streets():
		var junction := route.arrives_at(street)
		var box := Rect2i(junction * CityMap.period(),
				Vector2i.ONE * Tuning.STREET_WIDTH)
		_points.append(map.tile_rect_to_world(box).get_center())
	_points.append(map.tile_rect_to_world(CityMap.block_rect(route.park_block())).get_center())

## How many points the route turns at, the park's last.
func count() -> int:
	return _points.size()

## The `index`th point.
func point(index: int) -> Vector2:
	return _points[index]
