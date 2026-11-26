extends RefCounted
## `RouteWaypoints`: day 1's tutorial route as the points the way to the park turns at, read off
## the route it is handed (a real `TutorialRoute` given its junctions and park, with a stand-in for
## whether a tile is in its park) and placed on the map's tiles.

## A route through `junctions` whose park is the park block's own rect.
class _Route extends TutorialRoute:
	func _init(junctions: Array[Vector2i], park_block: Vector2i) -> void:
		super(null, StreetNetwork.Segment.new(Vector2i(0, 0), true),
				[] as Array[StreetNetwork.Segment], junctions, park_block, Rect2i())

	## Overrides TutorialRoute.has_in_its_park.
	func has_in_its_park(tile: Vector2i) -> bool:
		return CityMap.block_rect(park_block()).has_point(tile)

func run(t: TestRunner) -> void:
	var period := CityMap.period()
	var junctions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
	var park := Vector2i(2, 1)
	var map := CityMap.new()
	var waypoints := RouteWaypoints.new(_Route.new(junctions, park), map)
	t.check(waypoints.count() == junctions.size() + 1, "a point for each junction and the park last")
	for i in junctions.size():
		var box := Rect2i(junctions[i] * period, Vector2i.ONE * Tuning.STREET_WIDTH)
		t.check(waypoints.point(i).is_equal_approx(map.tile_rect_to_world(box).get_center()),
				"junction %d is the middle of its box" % i)
		t.check(waypoints.has_reached(i, box.position) and waypoints.has_reached(i, box.end - Vector2i.ONE),
				"and is reached anywhere in the box, its corners included")
		t.check(not waypoints.has_reached(i, box.end), "and not past it")
	var last := waypoints.count() - 1
	t.check(waypoints.point(last).is_equal_approx(
			map.tile_rect_to_world(CityMap.block_rect(park)).get_center()), "the park is its middle")
	t.check(waypoints.has_reached(last, CityMap.block_rect(park).get_center())
			and not waypoints.has_reached(last, Vector2i(1, 1) * period),
			"and is reached in the park, nowhere else")
