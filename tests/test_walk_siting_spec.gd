extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the events build after dawn
## (`EventScheduler.WalkSiting`) refuses the street her front door opens onto on a walk that holds
## the home's streets, as the dawn placement does, and offers it on a walk that does not (the escape's
## city, which sets off from the service exit); the rule is the spec's the manager was handed
## (`EventManager.start_day()`, `use_the_spec()`), never the manager's own, and every siting the
## events build is handed it.
##
## **Why the first check generates a city**: the home street is a generated city's, the street the
## home's front door opens onto (`ClosurePlanner.home_street()`). Its routes are a stand-in
## (`tests/fake_route_tree.gd`, none set) and so are the walk's events (`tests/fake_walk_events.gd`,
## none), so only the rule under test decides.

const DAY := 1
## A row that stands on a plain sidewalk, so only the rule under test decides whether a tile of the
## home street takes it.
const ROW := "market_stall"

func run(t) -> void:
	_test_a_siting_takes_the_home_street_only_where_the_walk_does_not_hold_it(t)
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_every_place_that_builds_a_siting_copies_the_rule(t)

## A `ROW` asked to stand where one of the day's events stands on the home street
## (`WalkSiting.in_place_of()`, which asks the row's ground under the rule as every siting after dawn
## does): refused on a walk that holds the home's streets, placed there on one that does not.
func _test_a_siting_takes_the_home_street_only_where_the_walk_does_not_hold_it(t) -> void:
	var map := CityGenerator.generate(4242)
	var def := EventCatalogue.by_id(ROW)
	var home := ClosurePlanner.home_street(map).tile_rect()
	var siting := EventScheduler.WalkSiting.new(DAY, map, FakeRouteTree.new(map), FakeWalkEvents.new(),
			EventScheduler.Verdicts.new())
	var tried := 0
	var offered: Array[bool] = []
	for tile in EventScheduler.open_ground_for(def, map, {}, -1, false):
		if not home.has_point(tile):
			continue
		var old := EventScheduler.Planned.new(def, map.tile_to_world(tile))
		siting.holds_the_home_streets = false
		var placed := siting.in_place_of(def, old, _rng())
		if not placed:
			continue
		tried += 1
		siting.holds_the_home_streets = true
		offered.append(siting.in_place_of(def, old, _rng()) != null)
		t.check(map.world_to_tile(placed.placed_at()) == tile,
				"a walk that does not hold the home's streets places it on the home street at %s" % tile)
		if tried >= 4:
			break
	t.check(tried > 0, "the home street has ground the row takes (%d tiles asked)" % tried)
	t.check(not offered.has(true), "and a walk that holds the home's streets is refused every one")

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("walk-siting-spec:%d" % DAY)
	return rng

func _test_the_director_reads_the_rule_off_the_walks_spec(t) -> void:
	var manager := EventManager.new()
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead.holds_the_home_streets, "a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead.holds_the_home_streets,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()

## Every place in `EventsAhead` that builds a `WalkSiting` (the day's, a mast's, a rigged
## route's), which cannot be observed from outside; each must copy the rule onto what it builds,
## read off the source so a dropped copy fails here rather than siting on a day's rule. Each also hands what it builds a verdict store of its own (`EventScheduler.Verdicts.new()` in
## the call), which no siting's answers show either: a store shared between sitings would let one
## asked during the other's look read verdicts judged for the other's plans and place wrongly, so
## it too is read off the source.
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
	t.check(builds > 0, "EventsAhead builds a WalkSiting somewhere (%d places)" % builds)
	t.check(copied == builds, "and each copies holds_the_home_streets onto it (%d of %d)" % [copied, builds])
	t.check(stores == builds,
			"and each hands it a verdict store of its own (%d of %d)" % [stores, builds])
