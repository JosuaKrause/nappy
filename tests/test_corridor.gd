extends RefCounted
## `Corridor`, the ground today's routes run through asked about a tile, here only for the street
## beside the routes (`is_beside_the_routes()`), where day 13's dawn stands its roadblocks and the
## task's swap may put one (inbox #1185), and the view a whole street is in (`view_of()`). Checked on a corridor made of a tree whose routes are set
## by hand (`tests/fake_route_tree.gd`): a route east along the street from junction (2, 2) to
## (4, 2), which crosses the junctions (2, 2), (3, 2) and (4, 2).

func run(t) -> void:
	_test_a_street_touching_a_route_junction_is_beside_the_routes(t)
	_test_a_street_a_route_runs_along_is_not_beside_them(t)
	_test_a_street_far_from_the_routes_is_not_beside_them(t)
	_test_a_junction_box_is_beside_nothing(t)
	_test_each_street_is_in_one_of_the_three_views(t)

func _corridor() -> Corridor:
	var tree := FakeRouteTree.new(CityMap.new()).set_routes(
			[Vector3i(2, 2, 0), Vector3i(3, 2, 0)] as Array[Vector3i],
			[Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)] as Array[Vector2i])
	return Corridor.of(tree)

## The middle tile of a street.
static func _on(key: Vector3i) -> Vector2i:
	var rect := StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0).tile_rect()
	return rect.get_center()

func _test_a_street_touching_a_route_junction_is_beside_the_routes(t) -> void:
	var corridor := _corridor()
	t.check(corridor.is_beside_the_routes(_on(Vector3i(3, 2, 1))),
			"a street running south from a junction the route crosses is beside the routes")
	t.check(corridor.is_beside_the_routes(_on(Vector3i(3, 1, 1))),
			"and so is one running north into it")
	t.check(corridor.is_beside_the_routes(_on(Vector3i(4, 2, 0))),
			"and one carrying on east past the route's end")

func _test_a_street_a_route_runs_along_is_not_beside_them(t) -> void:
	t.check(not _corridor().is_beside_the_routes(_on(Vector3i(2, 2, 0))),
			"a street a route runs along is on the routes, not beside them")

func _test_a_street_far_from_the_routes_is_not_beside_them(t) -> void:
	t.check(not _corridor().is_beside_the_routes(_on(Vector3i(6, 6, 0))),
			"a street none of whose junctions a route crosses is not beside the routes")
	t.check(not _corridor().is_beside_the_routes(_on(Vector3i(2, 3, 1))),
			"nor is one a block south, touching only a junction no route crosses")

func _test_a_junction_box_is_beside_nothing(t) -> void:
	var box := Vector2i(3, 2) * CityMap.period() + Vector2i.ONE * (Tuning.STREET_WIDTH / 2)
	t.check(not _corridor().is_beside_the_routes(box),
			"a tile in a junction's own box is on no street, so beside nothing")

static func _street(key: Vector3i) -> StreetNetwork.Segment:
	return StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0)

func _test_each_street_is_in_one_of_the_three_views(t) -> void:
	var corridor := _corridor()
	t.check(corridor.view_of(_street(Vector3i(2, 2, 0))) == PlacementView.View.ON_THE_ROUTE,
			"a street a route runs along is on the route, both its sidewalks")
	t.check(corridor.view_of(_street(Vector3i(3, 2, 1))) == PlacementView.View.ROUTE_ADJACENT
			and corridor.view_of(_street(Vector3i(4, 2, 0))) == PlacementView.View.ROUTE_ADJACENT,
			"a street beside the routes is route-adjacent")
	t.check(corridor.view_of(_street(Vector3i(6, 6, 0))) == PlacementView.View.OFF_THE_ROUTE
			and corridor.view_of(_street(Vector3i(2, 3, 1))) == PlacementView.View.OFF_THE_ROUTE,
			"and a street no route touches is off the route")
	t.check(Corridor.of(null).view_of(_street(Vector3i(2, 2, 0))) == PlacementView.View.OFF_THE_ROUTE,
			"a corridor with no tree has every street off the route")
