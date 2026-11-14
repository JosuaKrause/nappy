extends RefCounted
## `DayUnits`, the day's locations grouped into units and which touch which: locations grouped by
## their kind and what each is a part of (`Location.part_of()`); a street touching the boxes at its
## ends and the streets meeting it there; a lot (an alley, a park, a square) touching the streets
## and boxes round its block, and they each other through it, and another lot in its block; two
## parallel streets with no lot between them not touching; the undrawn units near a point nearest
## first, and every one for an infinite radius; the units a field of a reach lands on; and a reach
## handed in making units that far apart touch besides.
##
## Built of plain values: `Location`s made by hand on the lattice's own numbers (a junction box at
## `junction * CityMap.period()`, a street between two of them,
## `StreetNetwork.Segment.tile_rect()`), since a location is state and nothing here asks a map.

func run(t: TestRunner) -> void:
	_test_locations_are_grouped_by_kind_and_what_they_are_part_of(t)
	_test_a_street_touches_its_boxes_and_the_streets_meeting_there(t)
	_test_a_lot_touches_the_ground_round_its_block(t)
	_test_the_undrawn_units_nearest_first(t)
	_test_the_units_a_field_reaches(t)
	_test_a_reach_widens_what_touches(t)

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
	t.check(street != null and street.kind() == PlacementUnit.Kind.STREET
			and street.locations().size() == 3,
			"a street's section and its two sidewalks are one street unit")
	var alley_rect := Rect2i(CityMap.block_rect(Vector2i(1, 1)).position + Vector2i(3, 0),
			Vector2i(2, 8))
	var alley := _unit_named(units, "alley:(%d, %d, 2, 8)" % [alley_rect.position.x,
			alley_rect.position.y])
	t.check(alley != null and alley.locations().size() == 3 and alley.tiles() == alley_rect,
			"an alley's three locations are one unit, the alley's tiles")
	var box := _unit_named(units, _box_name(Vector2i(2, 1)))
	t.check(box != null and box.kind() == PlacementUnit.Kind.JUNCTION
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
	t.check(units.touches(north, east) and units.touches(east, north),
			"two streets meeting at a box touch, both ways")
	t.check(not units.touches(north, south),
			"two parallel streets with no lot between them do not touch")
	t.check(not units.touches(north, far) and not units.touches(north, north),
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
		round_the_block = round_the_block and units.touches(alley, unit)
	t.check(round_the_block, "an alley touches every street and box round its block")
	t.check(units.touches(north, south),
			"and the streets on opposite sides of its block touch through it")
	t.check(units.touches(_unit_named(units, _box_name(Vector2i(1, 1))), south),
			"as a box and a street on opposite sides of the block do")
	t.check(units.touches(alley, square), "two lots in one block touch")
	t.check(not units.touches(alley, far), "while a street two blocks away does not")

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

static func _distance(at: Vector2, unit: PlacementUnit) -> float:
	var bounds := unit.bounds()
	return at.distance_to(Vector2(clampf(at.x, bounds.position.x, bounds.end.x),
			clampf(at.y, bounds.position.y, bounds.end.y)))

func _test_the_units_a_field_reaches(t: TestRunner) -> void:
	var units := DayUnits.of(_city(false), 1)
	var box := _box_rect(Vector2i(4, 1))
	var at := Vector2(box.get_center()) * Tuning.TILE_SIZE
	var plan := EventPlan.new(EventCatalogue.by_id("cafe_tables"), at)
	var expected: Array[String] = [_box_name(Vector2i(4, 1)), _street_name(Vector2i(4, 1), true)]
	t.check(_names(units.reached_by(plan, 4.0 * Tuning.TILE_SIZE)) == expected,
			"a field of four tiles from a box's middle lands on the box and its street (%s)"
			% [_names(units.reached_by(plan, 4.0 * Tuning.TILE_SIZE))])
	t.check(units.reached_by(plan, 20.0 * Tuning.TILE_SIZE).size() == 3,
			"and one of twenty tiles on the box at the street's far end as well")

## **A reach handed in widens the relation, and only by it**: the two parallel streets either side of
## a block, 256px apart with no lot between them, do not touch by the item's relation, and do with a
## reach of 270px, while the street two blocks away still does not.
func _test_a_reach_widens_what_touches(t: TestRunner) -> void:
	var north_name := _street_name(Vector2i(1, 1), true)
	var south_name := _street_name(Vector2i(1, 2), true)
	var far_name := _street_name(Vector2i(4, 1), true)
	var plain := DayUnits.of(_city(false), 1)
	t.check(not plain.touches(_unit_named(plain, north_name), _unit_named(plain, south_name)),
			"by the item's relation two parallel streets a block apart do not touch")
	var wide := DayUnits.of(_city(false), 1, 270.0)
	var north := _unit_named(wide, north_name)
	t.check(wide.touches(north, _unit_named(wide, south_name))
			and wide.touches(_unit_named(wide, south_name), north),
			"with a reach of 270px they touch, both ways")
	t.check(not wide.touches(north, _unit_named(wide, far_name)),
			"and a street two blocks off still does not")
