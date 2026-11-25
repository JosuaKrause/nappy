extends RefCounted
## `UnitRoom`, what is left of a unit for its draw to speak for, in the two of the player's three
## sizes a street draws (inbox #1466 in silky-lemur): a whole street fits a section or a small marble first; after
## a section at least two more draws; after a small marble only small ones until its section is
## full; a street part of which a dawn phase holds starts with what is left; every unit off the
## streets draws one small marble per open location; and a unit with nothing open has no room. Built of plain
## values: a unit and its locations are state, made by hand, so nothing is mocked.

func run(t: TestRunner) -> void:
	_test_a_whole_street_fits_any_marble_first(t)
	_test_after_a_section_at_least_two_more_draws_follow(t)
	_test_after_a_small_marble_only_small_ones_until_its_section_is_full(t)
	_test_a_street_part_of_which_is_held_starts_with_what_is_left(t)
	_test_off_the_streets_each_open_location_takes_one_marble(t)
	_test_a_unit_with_nothing_open_has_no_room(t)

const ON := PlacementView.View.ON_THE_ROUTE
const SECTION := EventDef.StreetShare.A_SECTION
const SMALL := EventDef.StreetShare.A_LOCATION

## A street laid out as `StreetLocations` lays one: three sections along it (3, 2 and 3 tiles) over
## its whole width, then each section's two sidewalk locations, the near side's first.
static func _street() -> PlacementUnit:
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var rect := segment.tile_rect()
	var starts: Array[int] = [0, 3, 5]
	var lengths: Array[int] = [3, 2, 3]
	var locations: Array[Location] = []
	for section in 3:
		var tiles := Rect2i(rect.position + Vector2i(starts[section], 0),
				Vector2i(lengths[section], rect.size.y))
		locations.append(_at(segment, section, tiles, Location.Kind.SECTION))
	for section in 3:
		for band in Corridor.sidewalk_bands(Rect2i(rect.position + Vector2i(starts[section], 0),
				Vector2i(lengths[section], rect.size.y)), true):
			locations.append(_at(segment, section, band, Location.Kind.SIDEWALK))
	return PlacementUnit.new(PlacementGround.Kind.STREET, rect, Rect2(), locations, 7)

static func _at(segment: StreetNetwork.Segment, section: int, tiles: Rect2i,
		kind: Location.Kind) -> Location:
	return Location.new(segment, section, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, kind)

## A unit off the streets of `kind` with `open` open locations and `closed` unavailable ones.
static func _ground(kind: PlacementGround.Kind, location_kind: Location.Kind, open: int,
		closed := 0) -> PlacementUnit:
	var whole := Rect2i(Vector2i(40, 40), Vector2i(4 * (open + closed), 4))
	var locations: Array[Location] = []
	for x in open + closed:
		var tiles := Rect2i(whole.position + Vector2i(4 * x, 0), Vector2i(4, 4))
		locations.append(Location.new(null, x, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
				ON, x < open, location_kind, whole))
	return PlacementUnit.new(kind, whole, Rect2(), locations, 7)

## How many marbles of `share` the room takes before it no longer fits one.
static func _draws(room: UnitRoom, share: EventDef.StreetShare) -> int:
	var count := 0
	while room.fits(share) and count < 20:
		room.take(share)
		count += 1
	return count

func _test_a_whole_street_fits_any_marble_first(t: TestRunner) -> void:
	var room := UnitRoom.of(_street())
	t.check(room.is_open() and room.fits(SECTION) and room.fits(SMALL),
			"a whole street fits a section or a small marble first")
	t.check(_draws(UnitRoom.of(_street()), SMALL) == 6,
			"and draws six small marbles, one a sidewalk location")
	t.check(_draws(UnitRoom.of(_street()), SECTION) == 3, "or three sections")

func _test_after_a_section_at_least_two_more_draws_follow(t: TestRunner) -> void:
	var by_sections := UnitRoom.of(_street())
	by_sections.take(SECTION)
	t.check(by_sections.is_open() and by_sections.fits(SECTION),
			"a street with a section drawn has room left, and another section fits")
	t.check(_draws(by_sections, SECTION) == 2, "two more sections fit, the fewest draws left")
	var by_small := UnitRoom.of(_street())
	by_small.take(SECTION)
	t.check(_draws(by_small, SMALL) == 4, "or four small marbles")

func _test_after_a_small_marble_only_small_ones_until_its_section_is_full(t: TestRunner) -> void:
	var room := UnitRoom.of(_street())
	room.take(SMALL)
	t.check(room.fits(SMALL) and not room.fits(SECTION),
			"after a small marble only a small one fits")
	room.take(SMALL)
	t.check(room.fits(SECTION),
			"and once a second fills its section, a section fits again")
	room.take(SECTION)
	room.take(SMALL)
	t.check(not room.fits(SECTION) and room.fits(SMALL),
			"and the next half-filled section admits small ones")
	room.take(SMALL)
	t.check(not room.is_open(), "until the street is spoken for")

## A sidewalk location a dawn phase holds closes its section (`DayLocations.assign_to()`), which
## leaves that section a half and the other two whole.
func _test_a_street_part_of_which_is_held_starts_with_what_is_left(t: TestRunner) -> void:
	var street := _street()
	var held := street.locations()[3]
	var cafe := EventPlan.new(EventCatalogue.by_id("cafe_tables"), held.centre())
	held.take(cafe)
	street.locations()[0].record(null)
	var room := UnitRoom.of(street)
	t.check(not room.fits(SECTION),
			"a street one sidewalk location of which is held fits no section until its half is "
			+ "filled")
	t.check(_draws(room, SMALL) == 5, "and draws five small marbles")

func _test_off_the_streets_each_open_location_takes_one_marble(t: TestRunner) -> void:
	var box := UnitRoom.of(_ground(PlacementGround.Kind.JUNCTION, Location.Kind.JUNCTION, 1))
	t.check(not box.fits(SECTION) and _draws(box, SMALL) == 1,
			"a junction box draws one small marble and fits no larger one")
	var alley := UnitRoom.of(_ground(PlacementGround.Kind.ALLEY, Location.Kind.ALLEY, 2, 1))
	t.check(_draws(alley, SMALL) == 2, "an alley with two of its three open draws two")
	var lot := UnitRoom.of(_ground(PlacementGround.Kind.OPEN, Location.Kind.OPEN, 5))
	t.check(_draws(lot, SMALL) == 5, "and a lot of five open cells five")

func _test_a_unit_with_nothing_open_has_no_room(t: TestRunner) -> void:
	var closed := UnitRoom.of(_ground(PlacementGround.Kind.ALLEY, Location.Kind.ALLEY, 0, 3))
	t.check(not closed.is_open() and not closed.fits(SMALL),
			"an alley none of whose locations is open has no room")
	var street := _street()
	for location in street.locations():
		location.record(null)
	t.check(not UnitRoom.of(street).is_open(), "nor has a street drawn already")
