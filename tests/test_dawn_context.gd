extends RefCounted
## `DawnContext`, the dawn in one object: what it answers a phase that places the catalogue's rows.
## A day is handed the catalogue's rows of a kind in the shape the run's heat puts them in; a walk
## with a bag of its own, which stands that bag's rows and no other, is handed none of any kind. A
## walk with no corridor is laid out along the streets it names, and the ground she is put down on is
## the walk's start where the spec does not hold the home's streets.
##
## Built as the game builds it, by hand: the walk's spec (data) and the day's seed, with the heat
## handed as the dawn hands it (`use_the_run()`). The map, the walk, the calm areas and the plan
## builder are `null`, since nothing under test reads them.

func run(t: TestRunner) -> void:
	_test_a_day_is_handed_the_catalogues_rows_as_the_heat_puts_them(t)
	_test_a_walk_with_a_bag_of_its_own_is_handed_none(t)
	_test_a_walk_with_no_corridor_is_laid_out_along_its_streets(t)
	_test_the_ground_she_starts_on_is_kept_where_the_home_streets_are_not_held(t)

const KINDS: Array[GameEnums.EventKind] = [GameEnums.EventKind.AMBIENT,
		GameEnums.EventKind.SCRIPTED, GameEnums.EventKind.ONE_SHOT, GameEnums.EventKind.RECURRING]

## A walk with no corridor (`RouteSource.corridor()` is null): two streets of a bare city's lattice
## and a point she starts at.
class _Walk extends RouteSource:
	var streets: Array[StreetNetwork.Segment] = []
	var begins := Vector2(640, 480)

	## Overrides RouteSource.streets_on_the_walk.
	func streets_on_the_walk() -> Array[StreetNetwork.Segment]:
		return streets

	## Overrides RouteSource.start.
	func start() -> Vector2:
		return begins

static func _context(spec: DaySpec, heat := 0) -> DawnContext:
	var context := DawnContext.new(spec, 7, null, null, null, null, Callable())
	context.use_the_run([], [], heat)
	return context

## **The rows of a day at a heat are the catalogue's own**, the very objects the heat chose
## (`EventCatalogue.of_kind()`): a context that dropped the heat answers the cold rows.
func _test_a_day_is_handed_the_catalogues_rows_as_the_heat_puts_them(t: TestRunner) -> void:
	var day := 8
	var heat := Tuning.RESISTANCE_GOAL
	var context := _context(DaySpec.for_day(day), heat)
	var heated := 0
	for kind in KINDS:
		var asked := context.catalogue_rows(kind)
		var expected := EventCatalogue.of_kind(kind, day, heat)
		t.check(asked == expected, "a day at heat %d is handed the catalogue's rows of kind %d"
				% [heat, kind])
		for def in expected:
			if def.answers_to_heat():
				heated += 1
	t.check(heated > 0, "some row of day %d responds to the heat (%d)" % [day, heated])

## A walk with a bag of its own is the escape city's spec, the one the game gives a bag.
func _test_a_walk_with_a_bag_of_its_own_is_handed_none(t: TestRunner) -> void:
	var spec := DaySpec.for_section(DaySpec.Section.CITY, 60.0)
	t.check(not spec.walk_bag().is_empty(), "the escape city's spec has a bag of its own")
	var rows := 0
	for kind in KINDS:
		rows += EventCatalogue.of_kind(kind, spec.day_number(), 0).size()
	t.check(rows > 0, "the catalogue has rows on the escape city's day (%d), so none is a choice"
			% rows)
	var context := _context(spec)
	for kind in KINDS:
		t.check(context.catalogue_rows(kind).is_empty(),
				"a walk with a bag of its own is handed no row of kind %d" % kind)

## A walk with no corridor is laid out along the two streets it names and no other: asked of a
## context whose walk is a stand-in naming two streets of a bare city's lattice.
func _test_a_walk_with_no_corridor_is_laid_out_along_its_streets(t: TestRunner) -> void:
	var map := CityMap.new()
	var lattice := map.street_segments()
	var walk := _Walk.new()
	walk.streets = [lattice[3], lattice[lattice.size() - 2]] as Array[StreetNetwork.Segment]
	var context := DawnContext.new(DaySpec.for_day(1), 7, map, walk, null, null, Callable())
	var named := {walk.streets[0].key(): true, walk.streets[1].key(): true}
	var found := context.locations().all()
	var only_those := not found.is_empty()
	for location in found:
		only_those = only_those and location.segment() != null \
				and named.has(location.segment().key())
	t.check(only_those, "every location of a walk with no corridor is of a street it names (%d)"
			% found.size())
	var seen := {}
	for location in found:
		seen[location.segment().key()] = true
	t.check(seen.size() == 2, "and both streets it names are laid out (%d seen)" % seen.size())

## **The ground she is put down on** is kept clear by the existing setting: a spec that holds the
## home's streets answers no point, one that does not answers where the walk starts.
func _test_the_ground_she_starts_on_is_kept_where_the_home_streets_are_not_held(
		t: TestRunner) -> void:
	var walk := _Walk.new()
	var held := DaySpec.for_day(1)
	var not_held := DaySpec.for_section(DaySpec.Section.CITY, 180.0)
	var of_a_day := DawnContext.new(held, 7, null, walk, null, null, Callable())
	var of_the_escape := DawnContext.new(not_held, 7, null, walk, null, null, Callable())
	t.check(of_a_day.ground_she_starts_on() == Vector2.INF,
			"a walk that holds the home's streets keeps no ground clear for her start")
	t.check(of_the_escape.ground_she_starts_on() == walk.begins,
			"a walk that does not keeps the ground she starts on clear (%s)"
			% of_the_escape.ground_she_starts_on())
