extends RefCounted
## `DayUnits`, the day's locations grouped into units and which touch which: locations grouped by
## their kind and what each is a part of (`Location.part_of()`); a street touching the boxes at its
## ends and the streets meeting it there; a lot (an alley, a park, a square) touching the streets
## and boxes round its block, and they each other through it, and another lot in its block; two
## parallel streets with no lot between them not touching; the undrawn units near a point nearest
## first, and every one for an infinite radius; and a reach handed in making units that far apart
## touch besides; every unit answered in the order its locations first name it; and every location
## naming the unit it was grouped into.
##
## Built of plain values: `Location`s made by hand on the lattice's own numbers (a junction box at
## `junction * CityMap.period()`, a street between two of them,
## `StreetNetwork.Segment.tile_rect()`), since a location is state and nothing here asks a map.

func run(t: TestRunner) -> void:
	_test_locations_are_grouped_by_kind_and_what_they_are_part_of(t)
	_test_a_street_touches_its_boxes_and_the_streets_meeting_there(t)
	_test_a_lot_touches_the_ground_round_its_block(t)
	_test_the_undrawn_units_nearest_first(t)
	_test_a_reach_widens_what_touches(t)
	_test_the_units_are_answered_in_the_order_first_met(t)
	_test_every_location_names_the_unit_it_was_grouped_into(t)

const ON := PlacementView.View.ON_THE_ROUTE

static func _box_rect(junction: Vector2i) -> Rect2i:
	return Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)

static func _located(segment: StreetNetwork.Segment, tiles: Rect2i, kind: int,
		whole := Rect2i()) -> Location:
	return Location.new(segment, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, kind, whole)

## A street's two sidewalk locations of its first section and that section.
static func _street(junction: Vector2i, horizontal: bool) -> Array[Location]:
	var segment := StreetNetwork.Segment.new(junction, horizontal)
	var rect := segment.tile_rect()
	var found: Array[Location] = [_located(segment, rect, Location.Kind.SECTION)]
	for band in Corridor.sidewalk_bands(rect, horizontal):
		found.append(_located(segment, band, Location.Kind.SIDEWALK))
	return found

static func _box(junction: Vector2i) -> Location:
	var rect := _box_rect(junction)
	return _located(null, rect, Location.Kind.JUNCTION, rect)

## A lot's location: `tiles` of `whole`, of `kind`.
static func _lot(tiles: Rect2i, whole: Rect2i, kind: int) -> Location:
	return _located(null, tiles, kind, whole)

static func _unit_named(units: DayUnits, name: String) -> PlacementUnit:
	for unit in units.undrawn_within(Vector2.ZERO, INF):
		if unit.name() == name:
			return unit
	return null

static func _names(units: Array[PlacementUnit]) -> Array[String]:
	var found: Array[String] = []
	for unit in units:
		found.append(unit.name())
	found.sort()
	return found

static func _street_name(junction: Vector2i, horizontal: bool) -> String:
	var rect := StreetNetwork.Segment.new(junction, horizontal).tile_rect()
	return "street:(%d, %d, %d, %d)" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func _box_name(junction: Vector2i) -> String:
	var rect := _box_rect(junction)
	return "junction:(%d, %d, %d, %d)" % [rect.position.x, rect.position.y, rect.size.x,
			rect.size.y]

## The city round block (1, 1): its four streets, its four boxes, and, where asked, an alley in
## it and a square beside the alley; a street two blocks east, and its boxes.
static func _city(with_lots: bool) -> Array[Location]:
	var locations: Array[Location] = []
	locations.append_array(_street(Vector2i(1, 1), true))
	locations.append_array(_street(Vector2i(1, 2), true))
	locations.append_array(_street(Vector2i(1, 1), false))
	locations.append_array(_street(Vector2i(2, 1), false))
	locations.append_array(_street(Vector2i(4, 1), true))
	for junction: Vector2i in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(2, 2),
			Vector2i(4, 1), Vector2i(5, 1)]:
		locations.append(_box(junction))
	if with_lots:
		var block := CityMap.block_rect(Vector2i(1, 1))
		var alley := Rect2i(block.position + Vector2i(3, 0), Vector2i(2, 8))
		for third in 3:
			locations.append(_lot(Rect2i(alley.position + Vector2i(0, third * 3), Vector2i(2, 3)),
					alley, Location.Kind.ALLEY))
		var square := Rect2i(block.position + Vector2i(6, 2), Vector2i(2, 4))
		locations.append(_lot(square, square, Location.Kind.OPEN))
	return locations

func _test_locations_are_grouped_by_kind_and_what_they_are_part_of(t: TestRunner) -> void:
	var units := DayUnits.of(_city(true), 1)
	var all := units.undrawn_within(Vector2.ZERO, INF)
	t.check(all.size() == 5 + 6 + 2, "five streets, six boxes, an alley and a square (%d units)"
			% all.size())
	var street := _unit_named(units, _street_name(Vector2i(1, 1), true))
	t.check(street != null and street.kind() == PlacementGround.Kind.STREET
			and street.locations().size() == 3,
			"a street's section and its two sidewalks are one street unit")
	var alley_rect := Rect2i(CityMap.block_rect(Vector2i(1, 1)).position + Vector2i(3, 0),
			Vector2i(2, 8))
	var alley := _unit_named(units, "alley:(%d, %d, 2, 8)" % [alley_rect.position.x,
			alley_rect.position.y])
	t.check(alley != null and alley.locations().size() == 3 and alley.tiles() == alley_rect,
			"an alley's three locations are one unit, the alley's tiles")
	var box := _unit_named(units, _box_name(Vector2i(2, 1)))
	t.check(box != null and box.kind() == PlacementGround.Kind.JUNCTION
			and box.locations().size() == 1, "and a junction box is a unit of its own")

func _test_a_street_touches_its_boxes_and_the_streets_meeting_there(t: TestRunner) -> void:
	var units := DayUnits.of(_city(false), 1)
	var north := _unit_named(units, _street_name(Vector2i(1, 1), true))
	var south := _unit_named(units, _street_name(Vector2i(1, 2), true))
	var east := _unit_named(units, _street_name(Vector2i(2, 1), false))
	var far := _unit_named(units, _street_name(Vector2i(4, 1), true))
	var expected: Array[String] = [_box_name(Vector2i(1, 1)), _box_name(Vector2i(2, 1)),
			_street_name(Vector2i(1, 1), false), _street_name(Vector2i(2, 1), false)]
	expected.sort()
	t.check(_names(units.touching(north)) == expected,
			"a street touches the two boxes at its ends and the streets meeting it there (%s)"
			% [_names(units.touching(north))])
	t.check(_touch(units, north, east) and _touch(units, east, north),
			"two streets meeting at a box touch, both ways")
	t.check(not _touch(units, north, south),
			"two parallel streets with no lot between them do not touch")
	t.check(not _touch(units, north, far) and not _touch(units, north, north),
			"nor does a street two blocks away, and nothing touches itself")
	var touching := units.touching(north)
	var in_order := true
	for i in range(1, touching.size()):
		in_order = in_order and touching[i - 1].draws_before(touching[i])
	t.check(in_order, "and what it touches is answered in rank order, lowest first")

func _test_a_lot_touches_the_ground_round_its_block(t: TestRunner) -> void:
	var units := DayUnits.of(_city(true), 1)
	var block := CityMap.block_rect(Vector2i(1, 1))
	var alley := _unit_named(units, "alley:(%d, %d, 2, 8)" % [block.position.x + 3,
			block.position.y])
	var square := _unit_named(units, "open:(%d, %d, 2, 4)" % [block.position.x + 6,
			block.position.y + 2])
	var north := _unit_named(units, _street_name(Vector2i(1, 1), true))
	var south := _unit_named(units, _street_name(Vector2i(1, 2), true))
	var west := _unit_named(units, _street_name(Vector2i(1, 1), false))
	var corner := _unit_named(units, _box_name(Vector2i(2, 2)))
	var far := _unit_named(units, _street_name(Vector2i(4, 1), true))
	var round_the_block := true
	for unit: PlacementUnit in [north, south, west, corner]:
		round_the_block = round_the_block and _touch(units, alley, unit)
	t.check(round_the_block, "an alley touches every street and box round its block")
	t.check(_touch(units, north, south),
			"and the streets on opposite sides of its block touch through it")
	t.check(_touch(units, _unit_named(units, _box_name(Vector2i(1, 1))), south),
			"as a box and a street on opposite sides of the block do")
	t.check(_touch(units, alley, square), "two lots in one block touch")
	t.check(not _touch(units, alley, far), "while a street two blocks away does not")

func _test_the_undrawn_units_nearest_first(t: TestRunner) -> void:
	var units := DayUnits.of(_city(false), 1)
	var at := Vector2(_box_rect(Vector2i(4, 1)).get_center()) * Tuning.TILE_SIZE
	var near := units.undrawn_within(at, 4.0 * Tuning.TILE_SIZE)
	t.check(near.size() == 2 and near[0].name() == _box_name(Vector2i(4, 1))
			and near[1].name() == _street_name(Vector2i(4, 1), true),
			"within four tiles of a box's middle are the box, then its street three tiles off (%s)"
			% [_names(near)])
	if near.is_empty():
		return
	var all := units.undrawn_within(at, INF)
	var nearest_first := true
	for i in range(1, all.size()):
		nearest_first = nearest_first and _distance(at, all[i - 1]) <= _distance(at, all[i])
	t.check(all.size() == 11 and nearest_first,
			"an infinite reach answers every unit, nearest first (%d)" % all.size())
	var none: Array[EventPlan] = []
	near[0].record_draw(none)
	t.check(units.undrawn_within(at, INF).size() == 10
			and not units.undrawn_within(at, INF).has(near[0]), "and a drawn one is left out")
	# How far the ground has drawn round a point is the distance to the nearest unit left: the
	# box she stands in has drawn, so it is the street three tiles off, and with every unit drawn
	# there is no end to it.
	t.check(is_equal_approx(units.drawn_round(at), _distance(at, near[1]))
			and units.drawn_round(at) > 0.0
			and units.undrawn_within(at, units.drawn_round(at) - 1.0).is_empty(),
			"the ground round the box's middle has drawn as far as the nearest undrawn unit (%.0fpx)"
			% units.drawn_round(at))
	for unit in units.undrawn_within(at, INF):
		unit.record_draw(none)
	t.check(is_inf(units.drawn_round(at)), "and without end once every unit has drawn")

static func _distance(at: Vector2, unit: PlacementUnit) -> float:
	var bounds := unit.bounds()
	return at.distance_to(Vector2(clampf(at.x, bounds.position.x, bounds.end.x),
			clampf(at.y, bounds.position.y, bounds.end.y)))

## **A reach handed in widens the relation, and only by it**: the two parallel streets either side of
## a block, 256px apart with no lot between them, do not touch by the item's relation, and do with a
## reach of 270px, while the street two blocks away still does not.
func _test_a_reach_widens_what_touches(t: TestRunner) -> void:
	var north_name := _street_name(Vector2i(1, 1), true)
	var south_name := _street_name(Vector2i(1, 2), true)
	var far_name := _street_name(Vector2i(4, 1), true)
	var plain := DayUnits.of(_city(false), 1)
	t.check(not _touch(plain, _unit_named(plain, north_name), _unit_named(plain, south_name)),
			"by the item's relation two parallel streets a block apart do not touch")
	var wide := DayUnits.of(_city(false), 1, 270.0)
	var north := _unit_named(wide, north_name)
	t.check(_touch(wide, north, _unit_named(wide, south_name))
			and _touch(wide, _unit_named(wide, south_name), north),
			"with a reach of 270px they touch, both ways")
	t.check(not _touch(wide, north, _unit_named(wide, far_name)),
			"and a street two blocks off still does not")

## Whether `b` is one of the units `a` touches (`DayUnits.touching()`).
static func _touch(units: DayUnits, a: PlacementUnit, b: PlacementUnit) -> bool:
	return b in units.touching(a)

## **`all()` answers every unit in the order the locations name them**, which for a walk laid out
## along its own streets is the walk's own order, and a change to the array answered changes nothing
## in the units.
func _test_the_units_are_answered_in_the_order_first_met(t: TestRunner) -> void:
	var units := DayUnits.of(_city(false), 1)
	var wanted: Array[String] = [
		_street_name(Vector2i(1, 1), true), _street_name(Vector2i(1, 2), true),
		_street_name(Vector2i(1, 1), false), _street_name(Vector2i(2, 1), false),
		_street_name(Vector2i(4, 1), true), _box_name(Vector2i(1, 1)), _box_name(Vector2i(2, 1)),
		_box_name(Vector2i(1, 2)), _box_name(Vector2i(2, 2)), _box_name(Vector2i(4, 1)),
		_box_name(Vector2i(5, 1))]
	var named: Array[String] = []
	for unit in units.all():
		named.append(unit.name())
	t.check(named == wanted, "every unit is answered, in the order its locations first name it (%s)"
			% [named])
	units.all().clear()
	t.check(units.all().size() == wanted.size(),
			"and emptying the answered array leaves the units as they were (%d)" % units.all().size())

## **Every location names the unit it was grouped into** (`unit_of()`), and a location that is not
## one of the day's names none.
func _test_every_location_names_the_unit_it_was_grouped_into(t: TestRunner) -> void:
	var locations := _city(true)
	var units := DayUnits.of(locations, 3)
	var every := not units.all().is_empty()
	for unit in units.all():
		for location in unit.locations():
			every = every and units.unit_of(location) == unit
	var grouped := 0
	for unit in units.all():
		grouped += unit.locations().size()
	t.check(every and grouped == locations.size(),
			"each of the %d locations names the unit holding it" % locations.size())
	t.check(units.unit_of(_box(Vector2i(8, 8))) == null, "and a location of no unit names none")
