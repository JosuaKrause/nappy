extends RefCounted
## `DayLocations`, every street's locations for one day laid out at dawn (inbox #1185), with the
## `StreetLocations` and `Location` it is made of, the state it holds: a street split into three
## sections along its length, each street told its view once (`Corridor.view_of()`), a street a fixed
## part holds left with no section open, and a section an event that spans the street is assigned
## taken for the day. Laid out on a bare city's lattice (`CityMap.new()`, every street present) with a
## corridor made of a tree whose routes are set by hand (`tests/fake_route_tree.gd`): a route east
## along the street from junction (2, 2) to (4, 2), crossing the junctions (2, 2), (3, 2) and (4, 2).

func run(t) -> void:
	_test_a_street_is_three_sections_along_its_length(t)
	_test_each_street_is_told_its_view(t)
	_test_a_held_or_absent_street_has_no_section_open(t)
	_test_an_assigned_section_is_taken_for_the_day(t)

const ROUTE := Vector3i(2, 2, 0)
const SIDE_STREET := Vector3i(3, 2, 1)
const FAR_STREET := Vector3i(6, 6, 0)

func _corridor(map: CityMap) -> Corridor:
	return Corridor.of(FakeRouteTree.new(map).set_routes(
			[ROUTE, Vector3i(3, 2, 0)] as Array[Vector3i],
			[Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)] as Array[Vector2i]))

## The open, untaken sections of the street `key` in `view`, in order along it.
func _sections_of(locations: DayLocations, view: int, key: Vector3i) -> Array[Location]:
	var found: Array[Location] = []
	for section in locations.sections_in(view):
		if section.segment().key() == key:
			found.append(section)
	return found

func _test_a_street_is_three_sections_along_its_length(t) -> void:
	var map := CityMap.new()
	var sections := _sections_of(DayLocations.lay_out(map, _corridor(map)),
			PlacementView.View.OFF_THE_ROUTE, FAR_STREET)
	t.check(sections.size() == 3, "a street is split into three sections (%d)" % sections.size())
	if sections.size() != 3:
		return
	var rect := StreetNetwork.Segment.new(Vector2i(FAR_STREET.x, FAR_STREET.y), true).tile_rect()
	var lengths: Array[int] = []
	var x := rect.position.x
	for section in sections:
		var tiles := section.tiles()
		t.check(tiles.position.x == x and tiles.position.y == rect.position.y
				and tiles.size.y == rect.size.y,
				"each section follows the one before along the street, the street's whole width (%s)"
				% tiles)
		lengths.append(tiles.size.x)
		x = tiles.end.x
	t.check(x == rect.end.x, "and the three reach the street's far end")
	t.check(lengths == ([3, 2, 3] as Array[int]),
			"a block of 8 tiles is split 3, 2 and 3, so the street has a middle (%s)" % [lengths])

func _test_each_street_is_told_its_view(t) -> void:
	var map := CityMap.new()
	var locations := DayLocations.lay_out(map, _corridor(map))
	t.check(_sections_of(locations, PlacementView.View.ON_THE_ROUTE, ROUTE).size() == 3,
			"a street a route runs along is on the route, all three of its sections")
	t.check(_sections_of(locations, PlacementView.View.ROUTE_ADJACENT, SIDE_STREET).size() == 3,
			"a street off the routes whose junction a route crosses is route-adjacent")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, FAR_STREET).size() == 3,
			"a street no route touches is off the route")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, ROUTE).is_empty()
			and _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, ROUTE).is_empty(),
			"and a street is in one view only")

func _test_a_held_or_absent_street_has_no_section_open(t) -> void:
	var map := CityMap.new()
	map.hold_segment(SIDE_STREET)
	map.absent_segments[FAR_STREET] = true
	var locations := DayLocations.lay_out(map, _corridor(map))
	t.check(_sections_of(locations, PlacementView.View.ROUTE_ADJACENT, SIDE_STREET).is_empty(),
			"a street held today has no section open to an event")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, FAR_STREET).is_empty(),
			"and a street a calm zone absorbed has no locations at all")
	t.check(_sections_of(locations, PlacementView.View.ROUTE_ADJACENT,
			Vector3i(3, 1, 1)).size() == 3, "while a street beside it keeps all three")

func _test_an_assigned_section_is_taken_for_the_day(t) -> void:
	var map := CityMap.new()
	var locations := DayLocations.lay_out(map, _corridor(map))
	var sections := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, SIDE_STREET)
	var middle := sections[1]
	var roadblock := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), middle.centre())
	locations.assign(middle, roadblock)
	var left := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, SIDE_STREET)
	t.check(middle.is_taken() and not left.has(middle),
			"a section a roadblock is assigned to is taken, so nothing is drawn there today")
	t.check(left == ([sections[0], sections[2]] as Array[Location]),
			"and the street's other two sections stay open")
