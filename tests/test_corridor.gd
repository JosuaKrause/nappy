@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `Corridor`, the ground today's routes run through, here only for the view a whole street is in
## (`view_of()`, inbox #1185 in gentle-owl): on the route, route-adjacent (beside the routes, where day 13's dawn
## stands its roadblocks and the task's swap takes a section), or off the route. Checked on a
## corridor made of a tree whose routes are set by hand (`tests/fake_route_tree.gd`): a route east
## along the street from junction (2, 2) to (4, 2), which crosses the junctions (2, 2), (3, 2) and
## (4, 2).

func run(t) -> void:
	_test_each_street_is_in_one_of_the_three_views(t)
	_test_ground_beyond_the_streets_is_told_its_view(t)

func _corridor() -> Corridor:
	var tree := FakeRouteTree.new(CityMap.new()).set_routes(
			[Vector3i(2, 2, 0), Vector3i(3, 2, 0)] as Array[Vector3i],
			[Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)] as Array[Vector2i])
	return Corridor.of(tree)

static func _street(key: Vector3i) -> StreetNetwork.Segment:
	return StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0)

func _test_each_street_is_in_one_of_the_three_views(t) -> void:
	var corridor := _corridor()
	t.check(corridor.view_of(_street(Vector3i(2, 2, 0))) == PlacementView.View.ON_THE_ROUTE,
			"a street a route runs along is on the route, both its sidewalks")
	t.check(corridor.view_of(_street(Vector3i(3, 2, 1))) == PlacementView.View.ROUTE_ADJACENT
			and corridor.view_of(_street(Vector3i(3, 1, 1))) == PlacementView.View.ROUTE_ADJACENT
			and corridor.view_of(_street(Vector3i(4, 2, 0))) == PlacementView.View.ROUTE_ADJACENT,
			"a street running south or north from a junction the route crosses, or on east past its "
			+ "end, is route-adjacent")
	t.check(corridor.view_of(_street(Vector3i(6, 6, 0))) == PlacementView.View.OFF_THE_ROUTE
			and corridor.view_of(_street(Vector3i(2, 3, 1))) == PlacementView.View.OFF_THE_ROUTE,
			"and a street none of whose junctions a route crosses, even one a block away, is off the route")
	t.check(Corridor.of(null).view_of(_street(Vector3i(2, 2, 0))) == PlacementView.View.OFF_THE_ROUTE,
			"a corridor with no tree has every street off the route")

## Ground beyond the streets (`view_of_ground()`) is in the view of the nearest of its tiles to the
## routes: a rect reaching over a route street's tiles is on the route, one reaching only a street
## beside the routes route-adjacent, one inside a block off the route.
func _test_ground_beyond_the_streets_is_told_its_view(t) -> void:
	var corridor := _corridor()
	var route_tile := _street(Vector3i(2, 2, 0)).tile_rect().get_center()
	var beside_tile := _street(Vector3i(3, 2, 1)).tile_rect().get_center()
	var block := Rect2i(Vector2i(6, 6) * CityMap.period() + Vector2i.ONE * Tuning.STREET_WIDTH,
			Vector2i(2, 2))
	t.check(corridor.view_of_ground(Rect2i(route_tile, Vector2i(2, 2)))
			== PlacementView.View.ON_THE_ROUTE, "ground reaching a route street is on the route")
	t.check(corridor.view_of_ground(Rect2i(beside_tile, Vector2i(2, 2)))
			== PlacementView.View.ROUTE_ADJACENT, "ground reaching only a street beside it is route-adjacent")
	t.check(corridor.view_of_ground(block) == PlacementView.View.OFF_THE_ROUTE,
			"and ground inside a block far off is off the route")
