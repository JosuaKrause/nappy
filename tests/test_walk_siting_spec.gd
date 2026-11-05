extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the director sites against
## (`EventScheduler.WalkSiting`) offers no tile of the street her front door opens onto on a walk
## that holds the home's streets, as the dawn placement offers none, and does offer that street's
## ground on a walk that does not (the escape's city, which sets off from the service exit). And the
## rule is the spec's the manager was handed (`EventManager.start_day()`, `use_the_spec()`), never
## the manager's own.

const Rig := preload("res://tests/event_manager_rig.gd")

const DAY := 1
## A row that stands on a plain sidewalk and does not shut the home street behind it, so only the
## rule under test decides whether a tile of the home street is offered it.
const ROW := "market_stall"

func run(t) -> void:
	_test_a_siting_offers_the_home_street_only_where_the_walk_does_not_hold_it(t)
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_the_siting_the_director_hands_out_carries_the_rule(t)
	_test_every_place_that_builds_a_siting_copies_the_rule(t)

## Every tile of the street her front door opens onto.
func _home_street(city: City) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.assign(city.map.rect_tiles(ClosurePlanner.home_street(city.map).tile_rect()))
	return tiles

## A row of `ROW` sited among the home street's tiles by `city`'s director, or null: the home street
## is the one place the rule changes what is offered, and she stands at her front door.
func _on_the_home_street(city: City) -> EventInstance:
	return city.events.queue_a_task_row(EventCatalogue.by_id(ROW), _home_street(city),
			Rig.rng(DAY), city.map.doorstep_world_position())

func _test_a_siting_offers_the_home_street_only_where_the_walk_does_not_hold_it(t) -> void:
	var city: City = Rig.build_city(t)
	var map := city.map
	var state := city.run.attempt_spend.city_state
	state.begin_day(map.block_plans, DAY)
	map.repaint(state)
	var home_street := _home_street(city)
	t.check(not home_street.is_empty(), "the city has a street her front door opens onto")
	var tree := RouteTree.for_day(map, DAY)
	var sited := {}
	for holds: bool in [true, false]:
		var siting := EventScheduler.WalkSiting.new(DAY, map, tree, [] as Array[Vector2i],
				PackedVector2Array(), EventScheduler.Verdicts.new())
		siting.holds_the_home_streets = holds
		sited[holds] = siting.near_her(EventCatalogue.by_id(ROW), Rig.rng(DAY),
				[] as Array[EventScheduler.Planned], home_street, map.doorstep_world_position())
	t.check(sited[true] == null,
			"a walk that holds the home's streets is offered none of the home street")
	t.check(sited[false] != null and map.world_to_tile(sited[false].position) in home_street,
			"and a walk that does not is offered its ground, and sites on it")
	city.free()

func _test_the_director_reads_the_rule_off_the_walks_spec(t) -> void:
	var manager := EventManager.new()
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead.holds_the_home_streets, "a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead.holds_the_home_streets,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()

## The siting the director hands a task's row (`queue_a_task_row()`, the one it sites against once the
## walk is planned) carries the rule of the walk's spec. The escape city's offers the home street,
## which its planning holds no segment of; a day's keeps the row off it, and the street is asked of
## with the day's holds cleared (`CityMap.clear_day_holds()`, which the escape's planning ends with
## too), so the rule alone decides, not the hold a day puts on the home block's streets as well.
func _test_the_siting_the_director_hands_out_carries_the_rule(t) -> void:
	var city: City = Rig.build_city(t)
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_section(DaySpec.Section.CITY,
			RunConfig.FINALE_LENGTH_SECONDS), Rig.rng(DAY), consumed)
	t.check(_on_the_home_street(city) != null,
			"the escape city's spec reaches the siting the director hands out")
	Rig.start(city, DAY)
	city.map.clear_day_holds()
	t.check(_on_the_home_street(city) == null, "and a day's spec reaches it again")
	city.free()

## Four places in `EventsAhead` build a `WalkSiting` (the day's, a mast's, the task's, a rigged
## route's), and the first two cannot be observed from outside; each must copy the rule onto what
## it builds, read off the source so a dropped copy fails here rather than siting on a day's rule.
## Each also hands what it builds a verdict store of its own (`EventScheduler.Verdicts.new()` in
## the call), which no siting's answers show either: a store shared between sitings changes no
## placement, only what the verdicts kept are worth, so it too is read off the source.
func _test_every_place_that_builds_a_siting_copies_the_rule(t) -> void:
	var lines := FileAccess.get_file_as_string("res://src/events/events_ahead.gd").split("\n")
	var builds := 0
	var copied := 0
	var stores := 0
	for i in lines.size():
		if "WalkSiting.new(" in lines[i]:
			builds += 1
			for j in range(i, mini(i + 5, lines.size())):
				if "holds_the_home_streets = holds_the_home_streets" in lines[j]:
					copied += 1
					break
				if "EventScheduler.Verdicts.new()" in lines[j]:
					stores += 1
	t.check(builds == 4, "EventsAhead builds a WalkSiting in four places (%d)" % builds)
	t.check(copied == builds, "and each copies holds_the_home_streets onto it (%d of %d)" % [copied, builds])
	t.check(stores == builds,
			"and each hands it a verdict store of its own (%d of %d)" % [stores, builds])
