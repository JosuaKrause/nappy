extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the director sites against
## (`EventScheduler.WalkSiting`) offers no tile of the street her front door opens onto on a walk
## that holds the home's streets, as the dawn placement offers none, and does offer that street's
## ground on a walk that does not (the escape's city, which sets off from the service exit). And the
## rule is the spec's the manager was handed (`EventManager.start_day()`, `use_the_spec()`), never
## the manager's own.

const SEED := 4242
const DAY := 1

func run(t) -> void:
	_test_a_siting_offers_the_home_street_only_where_the_walk_does_not_hold_it(t)
	_test_the_director_reads_the_rule_off_the_walks_spec(t)

func _test_a_siting_offers_the_home_street_only_where_the_walk_does_not_hold_it(t) -> void:
	var map := CityGenerator.generate(SEED)
	GameState.attempt_spend.city_state.begin_day(map.block_plans, DAY)
	map.repaint(GameState.attempt_spend.city_state)
	var tree := RouteTree.for_day(map, DAY)
	var def := EventCatalogue.by_id("delivery_van")
	var home_street := EventScheduler._the_street_she_starts_on(map)
	t.check(home_street.has_area(), "the city has a street her front door opens onto")
	var on_the_home_street := {}
	for holds: bool in [true, false]:
		var siting := EventScheduler.WalkSiting.new(DAY, map, tree, [] as Array[Vector2i],
				PackedVector2Array())
		siting.holds_the_home_streets = holds
		var offered := 0
		for tile: Vector2i in siting._ground_as_a_set(def):
			if home_street.has_point(tile):
				offered += 1
		on_the_home_street[holds] = offered
	t.check(int(on_the_home_street[true]) == 0,
			"a walk that holds the home's streets is offered none of the home street (%d tiles)"
			% on_the_home_street[true])
	t.check(int(on_the_home_street[false]) > 0,
			"and a walk that does not is offered its ground (%d tiles)" % on_the_home_street[false])

func _test_the_director_reads_the_rule_off_the_walks_spec(t) -> void:
	var manager := EventManager.new()
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead.holds_the_home_streets, "a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead.holds_the_home_streets,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()
