extends RefCounted
## `DawnContext`, the dawn in one object: what it answers a phase that places the catalogue's rows.
## A day is handed the catalogue's rows of a kind; a walk with a bag of its own, which stands that
## bag's rows and no other, is handed none of any kind.
##
## Built as the game builds it, by hand: the walk's spec (data) and the day's seed, with the map,
## the walk, the calm areas and the plan builder the answers under test never read.

func run(t: TestRunner) -> void:
	_test_a_day_is_handed_the_catalogues_rows(t)
	_test_a_walk_with_a_bag_of_its_own_is_handed_none(t)

const KINDS: Array[GameEnums.EventKind] = [GameEnums.EventKind.AMBIENT,
		GameEnums.EventKind.SCRIPTED, GameEnums.EventKind.ONE_SHOT, GameEnums.EventKind.RECURRING]

static func _context(spec: DaySpec) -> DawnContext:
	return DawnContext.new(spec, 7, CityMap.new(), RouteSource.new(), CalmAreas.new(), null,
			Callable())

static func _ids(rows: Array[EventDef]) -> Array[String]:
	var ids: Array[String] = []
	for def in rows:
		ids.append(def.id)
	return ids

func _test_a_day_is_handed_the_catalogues_rows(t: TestRunner) -> void:
	var day := 8
	var context := _context(DaySpec.for_day(day))
	var recurring := context.catalogue_rows(GameEnums.EventKind.RECURRING)
	t.check(not recurring.is_empty(), "a day is handed some recurring rows (%d)" % recurring.size())
	for kind in KINDS:
		t.check(_ids(context.catalogue_rows(kind)) == _ids(EventCatalogue.of_kind(kind, day, 0)),
				"a day is handed the catalogue's rows of kind %d" % kind)

func _test_a_walk_with_a_bag_of_its_own_is_handed_none(t: TestRunner) -> void:
	var spec := DaySpec.for_day(8)
	spec.bag = {"roadblock": 1, DaySpec.EMPTY_MARBLE: 1}
	var context := _context(spec)
	for kind in KINDS:
		t.check(context.catalogue_rows(kind).is_empty(),
				"a walk with a bag of its own is handed no row of kind %d" % kind)
