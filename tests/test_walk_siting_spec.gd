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
	_test_the_siting_the_director_hands_out_carries_the_rule(t)
	_test_every_place_that_builds_a_siting_copies_the_rule(t)

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

## The siting `EventsAhead` actually hands out (`_task_siting()`, the one the director's after-dawn
## placements and a task's rows are sited against) carries the rule of the spec handed in last.
func _test_the_siting_the_director_hands_out_carries_the_rule(t) -> void:
	var map := CityGenerator.generate(SEED)
	GameState.attempt_spend.city_state.begin_day(map.block_plans, DAY)
	map.repaint(GameState.attempt_spend.city_state)
	var manager := EventManager.new()
	manager.use_run(GameState)
	manager.world.city_map = map
	manager.world.day = DAY
	manager.ahead._day_tree = RouteTree.for_day(map, DAY)
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead._task_siting().holds_the_home_streets,
			"the escape city's spec reaches the siting the director hands out")
	manager.ahead._task_siting_cache = null
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead._task_siting().holds_the_home_streets,
			"and a day's spec reaches it again")
	manager.free()

## Four places in `EventsAhead` build a `WalkSiting` (the day's, a mast's, the task's, a rigged
## route's), and the first two cannot be observed from outside; each must copy the rule onto what
## it builds, read off the source so a dropped copy fails here rather than siting on a day's rule.
func _test_every_place_that_builds_a_siting_copies_the_rule(t) -> void:
	var lines := FileAccess.get_file_as_string("res://src/events/events_ahead.gd").split("\n")
	var builds := 0
	var copied := 0
	for i in lines.size():
		if "WalkSiting.new(" in lines[i]:
			builds += 1
			for j in range(i + 1, mini(i + 5, lines.size())):
				if "holds_the_home_streets = holds_the_home_streets" in lines[j]:
					copied += 1
					break
	t.check(builds == 4, "EventsAhead builds a WalkSiting in four places (%d)" % builds)
	t.check(copied == builds, "and each copies holds_the_home_streets onto it (%d of %d)" % [copied, builds])
