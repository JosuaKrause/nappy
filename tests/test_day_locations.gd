extends RefCounted
## `DayLocations`, every street's locations for one day laid out at dawn (inbox #1185), with the
## `StreetLocations` and `Location` it is made of, the state it holds: a street split into three
## sections along its length, each with two sidewalk locations; each street's sections filed under
## the view it is told; a street a fixed part holds left with no section open; a section an event
## that spans the street is assigned taken for the day, its two sidewalk locations with it; a tile
## naming the location holding it, of the ground under it; and a fixed part (a mast)
## holding its location, so it leaves the locations still open to a phase or a draw. Laid out
## on a bare city's lattice (`CityMap.new()`, every street present), with a stand-in for the corridor
## whose views the check sets (`_Views`); which view a street really is in is `Corridor.view_of()`'s,
## checked in `tests/test_corridor.gd`.

func run(t) -> void:
	_test_a_street_is_three_sections_along_its_length(t)
	_test_each_street_is_filed_under_the_view_it_is_told(t)
	_test_a_held_or_absent_street_has_no_section_open(t)
	_test_an_assigned_section_is_taken_for_the_day(t)
	_test_a_section_taken_takes_its_two_sidewalk_locations(t)
	_test_the_nearest_section_along_her_paths(t)
	_test_the_ground_beyond_the_streets_has_its_own_locations(t)
	_test_a_carriageway_event_drawn_takes_its_section(t)
	_test_each_kind_of_location_takes_its_own_ground(t)
	_test_a_tile_names_the_location_holding_it(t)
	_test_a_fixed_part_holds_its_location(t)

const ON := Vector3i(2, 2, 0)
const BESIDE := Vector3i(3, 2, 1)
const OFF := Vector3i(6, 6, 0)

## The corridor's view of each street, as the check sets it: off the route unless named.
class _Views extends Corridor:
	var views := {}

	## Overrides Corridor.view_of.
	func view_of(segment: StreetNetwork.Segment) -> int:
		return views.get(segment.key(), PlacementView.View.OFF_THE_ROUTE)

	## Overrides Corridor.view_of_ground.
	func view_of_ground(_tiles: Rect2i) -> int:
		return PlacementView.View.ROUTE_ADJACENT

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
	map.hold_segment(BESIDE, HeldStreets.Why.SEAL)
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

## Her paths as `tile -> distance`, the middle tile of each section given its distance.
static func _paths_to(sections: Array[Location], distances: Array[float]) -> Dictionary:
	var paths := {}
	for index in sections.size():
		var tiles := sections[index].tiles()
		paths[tiles.position + tiles.size / 2] = distances[index]
	return paths

## **The open section of a view nearest along her paths** (`nearest_section_in()`, day 13's swap):
## the route-adjacent street's three sections, with her paths reaching them at 300, 100 and 200px.
## The nearest is taken; one its caller refuses (`may_take`) or one already taken is passed over for
## the next; a tile she may not touch from does not count; and with no path to any, none is.
func _test_the_nearest_section_along_her_paths(t) -> void:
	var always := func(_x: Variant) -> bool: return true
	var locations := DayLocations.lay_out(CityMap.new(), _views())
	var sections := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE)
	var paths := _paths_to(sections, [300.0, 100.0, 200.0] as Array[float])
	t.check(locations.nearest_section_in(PlacementView.View.ROUTE_ADJACENT, paths, always, always)
			== sections[1], "the section her paths reach first is the one taken")
	var not_the_middle := func(section: Location) -> bool: return section != sections[1]
	t.check(locations.nearest_section_in(PlacementView.View.ROUTE_ADJACENT, paths, always,
			not_the_middle) == sections[2], "one its caller refuses is passed over for the next nearest")
	var middle_tile := sections[1].tiles().position + sections[1].tiles().size / 2
	var not_from_there := func(tile: Vector2i) -> bool: return tile != middle_tile
	t.check(locations.nearest_section_in(PlacementView.View.ROUTE_ADJACENT, paths, not_from_there,
			always) == sections[2], "and so is one reached only from ground she may not touch it from")
	t.check(locations.nearest_section_in(PlacementView.View.OFF_THE_ROUTE, paths, always, always)
			== null, "a view her paths reach no section of offers none")
	locations.assign(sections[1], EventScheduler.Planned.new(EventCatalogue.by_id("roadblock"),
			sections[1].centre()))
	t.check(locations.nearest_section_in(PlacementView.View.ROUTE_ADJACENT, paths, always, always)
			== sections[2], "a section already taken is passed over")

## The locations of `kind` the day laid out beyond the streets, in the draw's order.
static func _grounds_of(locations: DayLocations, kind: int) -> Array[Location]:
	var found: Array[Location] = []
	var rng := RandomNumberGenerator.new()
	for location in locations.drawing_order(rng):
		if location.kind() == kind:
			found.append(location)
	return found

## **The ground beyond the streets** (the player's "yes" to a group of locations per kind of ground,
## issue #1185): on a bare lattice painted with an alley six tiles long, a square eight tiles across
## and one crossing in a junction box, the alley is three locations along its length, the square a
## grid of four cells, and the junction box one location, each told the view the corridor gives it.
func _test_the_ground_beyond_the_streets_has_its_own_locations(t) -> void:
	var map := CityMap.new()
	var alley := Rect2i(Vector2i(20, 6), Vector2i(2, 6))
	map.fill_rect(alley, GameEnums.TileType.ALLEY)
	var square := Rect2i(Vector2i(48, 48), Vector2i(8, 8))
	map.fill_rect(square, GameEnums.TileType.SQUARE)
	var box := Vector2i(3, 3) * CityMap.period()
	map.set_tile(box + Vector2i(2, 2), GameEnums.TileType.CROSSING)
	var locations := DayLocations.lay_out(map, _views())
	var alleys := _grounds_of(locations, Location.Kind.ALLEY)
	var lengths: Array[int] = []
	for location in alleys:
		lengths.append(location.tiles().size.y)
	t.check(alleys.size() == 3 and lengths == ([2, 2, 2] as Array[int])
			and alleys[0].tiles().position == alley.position,
			"an alley is three locations along its length (%s)" % [lengths])
	var cells := _grounds_of(locations, Location.Kind.OPEN)
	var covered := {}
	for cell in cells:
		for y in range(cell.tiles().position.y, cell.tiles().end.y):
			for x in range(cell.tiles().position.x, cell.tiles().end.x):
				covered[Vector2i(x, y)] = true
	t.check(cells.size() == 4 and covered.size() == 64,
			"a square of 8 by 8 tiles is a grid of four cells covering it (%d cells)" % cells.size())
	var junctions := _grounds_of(locations, Location.Kind.JUNCTION)
	var lattice := StreetNetwork.junction_count()
	var the_box: Location = null
	for junction in junctions:
		if junction.tiles() == Rect2i(box, Vector2i.ONE * Tuning.STREET_WIDTH):
			the_box = junction
	t.check(junctions.size() == lattice.x * lattice.y and the_box != null,
			"and every junction box a street meets is one location, the whole box (%d of %d)"
			% [junctions.size(), lattice.x * lattice.y])
	for key: Vector3i in [Vector3i(3, 3, 0), Vector3i(2, 3, 0), Vector3i(3, 3, 1), Vector3i(3, 2, 1)]:
		map.absent_segments[key] = true
	var absorbed := false
	for junction in _grounds_of(DayLocations.lay_out(map, _views()), Location.Kind.JUNCTION):
		absorbed = absorbed or junction.tiles().position == box
	t.check(not absorbed, "while a box no street meets, its streets absorbed, is none")
	var views_right := true
	for location in alleys + cells + junctions:
		views_right = views_right and location.view() == PlacementView.View.ROUTE_ADJACENT
	t.check(views_right, "each told the view the corridor gives its ground")

## An event drawn into a section, one that drives the carriageway, takes the section's two sidewalk
## locations with it (`DayLocations.record()`); an event drawn on a sidewalk takes only its own.
func _test_a_carriageway_event_drawn_takes_its_section(t) -> void:
	var locations := DayLocations.lay_out(CityMap.new(), _views())
	var sections := _sections_of(locations, PlacementView.View.ROUTE_ADJACENT, BESIDE)
	var middle := sections[1]
	locations.record(middle, EventScheduler.Planned.new(EventCatalogue.by_id("police_patrol"),
			middle.centre()))
	var sidewalks: Array[Location] = []
	for location in locations.drawing_order(RandomNumberGenerator.new()):
		if location.kind() == Location.Kind.SIDEWALK and location.segment().key() == BESIDE:
			sidewalks.append(location)
	var taken := 0
	for sidewalk in sidewalks:
		if sidewalk.is_taken():
			taken += 1
			t.check(sidewalk.section() == 1, "only the section's own sidewalks are taken")
	t.check(middle.is_drawn() and middle.is_taken() and taken == 2,
			"a patrol drawn into a section takes it and its two sidewalk locations (%d)" % taken)
	var first := sidewalks[0]
	if first.section() == 1:
		first = sidewalks[sidewalks.size() - 1]
	locations.record(first, EventScheduler.Planned.new(EventCatalogue.by_id("cafe_tables"),
			first.centre()))
	var others_taken := 0
	for sidewalk in sidewalks:
		if sidewalk != first and sidewalk.section() != 1 and sidewalk.is_taken():
			others_taken += 1
	t.check(first.is_taken() and others_taken == 0,
			"while a cafe drawn on a sidewalk takes that location alone")

## Which ground each kind of location offers a row (`Location.takes()`).
func _test_each_kind_of_location_takes_its_own_ground(t) -> void:
	var at := func(kind: int) -> Location:
		return Location.new(null, 0, Rect2i(), Vector2.ZERO, PlacementView.View.OFF_THE_ROUTE, true,
				kind)
	var sidewalk: Location = at.call(Location.Kind.SIDEWALK)
	var section: Location = at.call(Location.Kind.SECTION)
	t.check(sidewalk.takes(GameEnums.TileType.SIDEWALK) and not sidewalk.takes(GameEnums.TileType.ROAD),
			"a sidewalk location takes the sidewalk and not the carriageway")
	t.check(section.takes(GameEnums.TileType.ROAD) and not section.takes(GameEnums.TileType.SIDEWALK),
			"a section takes its carriageway and not the sidewalks its sidewalk locations hold")
	t.check((at.call(Location.Kind.ALLEY) as Location).takes(GameEnums.TileType.ALLEY)
			and (at.call(Location.Kind.OPEN) as Location).takes(GameEnums.TileType.PARK)
			and (at.call(Location.Kind.OPEN) as Location).takes(GameEnums.TileType.SQUARE)
			and (at.call(Location.Kind.JUNCTION) as Location).takes(GameEnums.TileType.CROSSING)
			and (at.call(Location.Kind.JUNCTION) as Location).takes(GameEnums.TileType.SIDEWALK)
			and (at.call(Location.Kind.JUNCTION) as Location).takes(GameEnums.TileType.ROAD)
			and not (at.call(Location.Kind.JUNCTION) as Location).takes(GameEnums.TileType.PARK),
			"an alley its alley, an open lot its park or square, a junction box its corners, carriageway and crossings")

## A sidewalk tile names its sidewalk location, a carriageway tile its section, a square tile the
## open cell holding it; a tile no location holds names none.
func _test_a_tile_names_the_location_holding_it(t) -> void:
	var map := CityMap.new()
	var square := Rect2i(Vector2i(48, 48), Vector2i(8, 8))
	map.fill_rect(square, GameEnums.TileType.SQUARE)
	var locations := DayLocations.lay_out(map, _views())
	var segment := _segment(BESIDE)
	var bands := Corridor.sidewalk_bands(segment.tile_rect(), segment.horizontal)
	var sidewalk_tile: Vector2i = (bands[0] as Rect2i).get_center()
	var road_tile := segment.tile_rect().get_center()
	var on_sidewalk := locations.holding(sidewalk_tile, GameEnums.TileType.SIDEWALK)
	var on_road := locations.holding(road_tile, GameEnums.TileType.ROAD)
	t.check(on_sidewalk != null and on_sidewalk.kind() == Location.Kind.SIDEWALK
			and on_sidewalk.tiles().has_point(sidewalk_tile),
			"a sidewalk tile names the sidewalk location holding it")
	t.check(on_road != null and on_road.kind() == Location.Kind.SECTION
			and on_road.tiles().has_point(road_tile), "a carriageway tile names its section")
	var cell := locations.holding(square.position + Vector2i.ONE, GameEnums.TileType.SQUARE)
	t.check(cell != null and cell.kind() == Location.Kind.OPEN, "a square tile names its open cell")
	t.check(locations.holding(Vector2i(8, 8), map.tile_at(Vector2i(8, 8))) == null,
			"a tile inside a block names no location")

## A fixed part recorded on its tile takes the location holding it, and that location is no longer
## open to a phase; every other location stays open.
func _test_a_fixed_part_holds_its_location(t) -> void:
	var map := CityMap.new()
	var square := Rect2i(Vector2i(48, 48), Vector2i(8, 8))
	map.fill_rect(square, GameEnums.TileType.SQUARE)
	var locations := DayLocations.lay_out(map, _views())
	var open_before := locations.open_locations().size()
	var tile := square.position + Vector2i.ONE
	var cell := locations.holding(tile, GameEnums.TileType.SQUARE)
	var mast := EventScheduler.Planned.new(EventCatalogue.mast(), map.tile_to_world(tile))
	locations.hold_fixed_part(mast, tile, GameEnums.TileType.SQUARE)
	t.check(cell.is_taken(), "the location holding a fixed part is taken for the day")
	t.check(not cell in locations.open_locations()
			and locations.open_locations().size() == open_before - 1,
			"and only it leaves the locations open to a phase (%d of %d open)"
			% [locations.open_locations().size(), open_before])
