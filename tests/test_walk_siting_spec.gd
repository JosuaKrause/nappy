extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the events build after dawn
## (`EventScheduler.WalkSiting`) refuses the street her front door opens onto on a walk that holds
## the home's streets, as the dawn placement does, and offers it on a walk that does not (the escape's
## city, which sets off from the service exit). The rule is the ground's a siting is handed
## (`RowGround`): the day's own, made at dawn under the day's spec and handed on with the walk, or,
## for a walk no dawn planned, one the events make under the spec the manager was handed
## (`EventManager.start_day()`, `use_the_spec()`), never the manager's own.
##
## What a ground refuses under the rule (`RowGround.tiles_for()`) is the suites' that ask it of a
## city; `tests/test_event_manager.gd` holds that a day's walk carries the dawn's ground and that the
## siting made at the day's start asks it, and this suite holds the rule is read off the walk's spec,
## that every place that builds a siting hands it `EventsAhead._ground_of_the_walk()` (a mast's and
## a rigged route's sitings are held by nothing else) and a verdict store of its own.

const DAY := 1

func run(t: TestRunner) -> void:
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_every_place_that_builds_a_siting_hands_it_the_walks_ground_and_a_store_of_its_own(t)

func _test_the_director_reads_the_rule_off_the_walks_spec(t: TestRunner) -> void:
	var manager := EventManager.new()
	manager.use_the_spec(DaySpec.for_day(DAY))
	t.check(manager.ahead.holds_the_home_streets, "a day's spec holds the home's streets after dawn")
	manager.use_the_spec(DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS))
	t.check(not manager.ahead.holds_the_home_streets,
			"and the escape city's spec does not, as its dawn placement does not")
	manager.free()

## Every place in `EventsAhead` that builds a `WalkSiting` (the day's, a mast's, a rigged
## route's) hands what it builds the walk's ground (`_ground_of_the_walk()` in the call; which
## ground that answers is held by `tests/test_event_manager.gd`) and a verdict store of its own
## (`EventScheduler.Verdicts.new()` in the call), neither of which any siting's answers show: a
## store shared between sitings would let one asked during the other's look read verdicts judged
## for the other's plans and place wrongly, so both are read off the source.
func _test_every_place_that_builds_a_siting_hands_it_the_walks_ground_and_a_store_of_its_own(t: TestRunner) -> void:
	var lines := FileAccess.get_file_as_string("res://src/events/events_ahead.gd").split("\n")
	var builds := 0
	var handed := 0
	var stores := 0
	for i in lines.size():
		if "WalkSiting.new(" in lines[i]:
			builds += 1
			var has_ground := false
			var has_store := false
			for j in range(i, mini(i + 5, lines.size())):
				has_ground = has_ground or "_ground_of_the_walk()" in lines[j]
				has_store = has_store or "EventScheduler.Verdicts.new()" in lines[j]
			handed += int(has_ground)
			stores += int(has_store)
	t.check(builds > 0, "EventsAhead builds a WalkSiting somewhere (%d places)" % builds)
	t.check(handed == builds, "and each hands it the walk's ground (%d of %d)" % [handed, builds])
	t.check(stores == builds,
			"and each hands it a verdict store of its own (%d of %d)" % [stores, builds])
