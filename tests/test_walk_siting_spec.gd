extends RefCounted
## **What is sited after dawn keeps the walk's own home-street rule** (`DaySpec.holds_the_home_streets`),
## not always a day's: the placement context the events build after dawn
## (`EventScheduler.WalkSiting`) refuses the street her front door opens onto on a walk that holds
## the home's streets, as the dawn placement does, and offers it on a walk that does not (the escape's
## city, which sets off from the service exit); the rule is the spec's the manager was handed
## (`EventManager.start_day()`, `use_the_spec()`), never the manager's own, and every siting the
## events build is handed it.
##
## What the dawn ground for a row asks of the rule (`EventScheduler.open_ground_for()`'s
## `from_the_door`) is that function's own suites'; these two hold that every siting after dawn is
## handed the walk's own rule.

const DAY := 1

func run(t: TestRunner) -> void:
	_test_the_director_reads_the_rule_off_the_walks_spec(t)
	_test_every_place_that_builds_a_siting_copies_the_rule(t)

func _test_the_director_reads_the_rule_off_the_walks_spec(t: TestRunner) -> void:
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
func _test_every_place_that_builds_a_siting_copies_the_rule(t: TestRunner) -> void:
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
