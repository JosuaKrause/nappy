extends RefCounted
## `DayLocations`, every street's locations for one day laid out at dawn (inbox #1185), with the
## `StreetLocations` and `Location` it is made of, the state it holds: a street split into three
## sections along its length, each with two sidewalk locations; each street's sections filed under
## the view it is told; a street a fixed part holds left with no section open; and a section an event
## that spans the street is assigned taken for the day, its two sidewalk locations with it. Laid out
## on a bare city's lattice (`CityMap.new()`, every street present), with a stand-in for the corridor
## whose views the check sets (`_Views`); which view a street really is in is `Corridor.view_of()`'s,
## checked in `tests/test_corridor.gd`.

func run(t) -> void:
	_test_a_street_is_three_sections_along_its_length(t)
	_test_each_street_is_filed_under_the_view_it_is_told(t)
	_test_a_held_or_absent_street_has_no_section_open(t)
	_test_an_assigned_section_is_taken_for_the_day(t)
	_test_a_section_taken_takes_its_two_sidewalk_locations(t)

const ON := Vector3i(2, 2, 0)
const BESIDE := Vector3i(3, 2, 1)
const OFF := Vector3i(6, 6, 0)

## The corridor's view of each street, as the check sets it: off the route unless named.
class _Views extends Corridor:
	var views := {}

	## Overrides Corridor.view_of.
	func view_of(segment: StreetNetwork.Segment) -> int:
		return views.get(segment.key(), PlacementView.View.OFF_THE_ROUTE)

static func _views() -> _Views:
	var views := _Views.new()
	views.views = {ON: PlacementView.View.ON_THE_ROUTE, BESIDE: PlacementView.View.ROUTE_ADJACENT}
	return views

static func _segment(key: Vector3i) -> StreetNetwork.Segment:
	return StreetNetwork.Segment.new(Vector2i(key.x, key.y), key.z == 0)

## The open, untaken sections of the street `key` in `view`, in order along it.
func _sections_of(locations: DayLocations, view: int, key: Vector3i) -> Array[Location]:
	var found: Array[Location] = []
	for section in locations.sections_in(view):
		if section.segment().key() == key:
			found.append(section)
	return found

func _test_a_street_is_three_sections_along_its_length(t) -> void:
	var sections := _sections_of(DayLocations.lay_out(CityMap.new(), _views()),
			PlacementView.View.OFF_THE_ROUTE, OFF)
	t.check(sections.size() == 3, "a street is split into three sections (%d)" % sections.size())
	if sections.size() != 3:
		return
	var rect := _segment(OFF).tile_rect()
	var lengths: Array[int] = []
	var x := rect.position.x
	for index in sections.size():
		var tiles := sections[index].tiles()
		t.check(tiles.position.x == x and tiles.position.y == rect.position.y
				and tiles.size.y == rect.size.y and sections[index].section() == index,
				"section %d follows the one before along the street, the street's whole width (%s)"
				% [index, tiles])
		lengths.append(tiles.size.x)
		x = tiles.end.x
	t.check(x == rect.end.x, "and the three reach the street's far end")
	t.check(lengths == ([3, 2, 3] as Array[int]),
			"a block of 8 tiles is split 3, 2 and 3, so the street has a middle (%s)" % [lengths])

func _test_each_street_is_filed_under_the_view_it_is_told(t) -> void:
	var locations := DayLocations.lay_out(CityMap.new(), _views())
	t.check(_sections_of(locations, PlacementView.View.ON_THE_ROUTE, ON).size() == 3,
			"a street told it is on the route has all three sections there")
	t.check(_sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE).size() == 3,
			"one told it is route-adjacent has them route-adjacent")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, OFF).size() == 3,
			"one told it is off the route has them off the route")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, ON).is_empty()
			and _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, ON).is_empty(),
			"and a street's sections are in the one view it was told")

func _test_a_held_or_absent_street_has_no_section_open(t) -> void:
	var map := CityMap.new()
	map.hold_segment(BESIDE)
	map.absent_segments[OFF] = true
	var locations := DayLocations.lay_out(map, _views())
	t.check(_sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE).is_empty(),
			"a street held today has no section open to an event")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE, OFF).is_empty(),
			"and a street a calm zone absorbed has no locations at all")
	t.check(_sections_of(locations, PlacementView.View.OFF_THE_ROUTE,
			Vector3i(3, 1, 1)).size() == 3, "while a street beside it keeps all three")

func _test_an_assigned_section_is_taken_for_the_day(t) -> void:
	var locations := DayLocations.lay_out(CityMap.new(), _views())
	var sections := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE)
	var middle := sections[1]
	var roadblock := EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"), middle.centre())
	locations.assign(middle, roadblock)
	var left := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE)
	t.check(middle.is_taken() and not left.has(middle),
			"a section a roadblock is assigned to is taken, so nothing is drawn there today")
	t.check(left == ([sections[0], sections[2]] as Array[Location]),
			"and the street's other two sections stay open")

func _test_a_section_taken_takes_its_two_sidewalk_locations(t) -> void:
	var segment := _segment(BESIDE)
	var street := StreetLocations.of(CityMap.new(), segment, PlacementView.View.ROUTE_ADJACENT)
	var sidewalks := street.sidewalks()
	t.check(sidewalks.size() == 6, "a street has six sidewalk locations (%d)" % sidewalks.size())
	var bands := Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)
	var middle := street.sections()[1]
	for sidewalk in sidewalks:
		var on_a_band := false
		for band in bands:
			on_a_band = on_a_band or band.encloses(sidewalk.tiles())
		t.check(on_a_band and middle.tiles().intersects(sidewalk.tiles()) == (sidewalk.section() == 1),
				"each sidewalk location lies on one sidewalk inside its own section (%s)"
				% sidewalk.tiles())
	street.take_section(middle, EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"),
			middle.centre()))
	var taken: Array[int] = []
	for sidewalk in sidewalks:
		if sidewalk.is_taken():
			taken.append(sidewalk.section())
	t.check(taken == ([1, 1] as Array[int]),
			"a section taken takes its two sidewalk locations and no other (%s)" % [taken])
