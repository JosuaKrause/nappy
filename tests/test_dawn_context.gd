extends RefCounted
## `DawnContext`, the dawn in one object: what it answers a phase that places the catalogue's rows.
## A day is handed the catalogue's rows of a kind in the shape the run's heat puts them in; a walk
## with a bag of its own, which stands that bag's rows and no other, is handed none of any kind.
##
## Built as the game builds it, by hand: the walk's spec (data) and the day's seed, with the heat
## handed as the dawn hands it (`use_the_run()`). The map, the walk, the calm areas and the plan
## builder are `null`, since nothing under test reads them.

func run(t: TestRunner) -> void:
	_test_a_day_is_handed_the_catalogues_rows_as_the_heat_puts_them(t)
	_test_a_walk_with_a_bag_of_its_own_is_handed_none(t)

const KINDS: Array[GameEnums.EventKind] = [GameEnums.EventKind.AMBIENT,
		GameEnums.EventKind.SCRIPTED, GameEnums.EventKind.ONE_SHOT, GameEnums.EventKind.RECURRING]

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
			if def.heat_response != EventDef.HeatResponse.NONE:
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
