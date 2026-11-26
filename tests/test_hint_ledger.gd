extends RefCounted
## `HintLedger`: the shows each thought-bubble hint has had this run, given back with a lost
## attempt and saved under a key of its own. Built the way the run builds it, as a part of a
## `RunState`, so the registry's own walks (a dawn photograph, a give-back) are what is exercised.

func run(t: TestRunner) -> void:
	_test_a_hint_has_a_few_shows_and_then_none(t)
	_test_a_lost_attempt_gives_its_shows_back(t)
	_test_the_ledger_survives_the_save(t)

func _test_a_hint_has_a_few_shows_and_then_none(t: TestRunner) -> void:
	var ledger := RunState.new().hints()
	var limit := 2
	t.check(ledger.has_shows_left(&"use_zebra", limit), "a hint never shown has shows left")
	ledger.record_show(&"use_zebra")
	t.check(ledger.has_shows_left(&"use_zebra", limit), "one show of two leaves one")
	t.check(ledger.record_show(&"use_zebra") == 2, "a show answers how many the hint has had")
	t.check(not ledger.has_shows_left(&"use_zebra", limit), "the limit is the last show")
	t.check(ledger.has_shows_left(&"walk_wide", limit), "another hint's shows are its own")

func _test_a_lost_attempt_gives_its_shows_back(t: TestRunner) -> void:
	var run := RunState.new()
	run.hints().record_show(&"way_to_park")
	run.run_parts().photograph()
	run.hints().record_show(&"way_to_park")
	run.hints().record_show(&"walk_wide")
	run.run_parts().give_back()
	t.check(run.hints().has_shows_left(&"way_to_park", 2),
			"the shows since the dawn are given back, the ones before it kept")
	t.check(not run.hints().has_shows_left(&"way_to_park", 1), "the one before the dawn stays counted")
	t.check(run.hints().has_shows_left(&"walk_wide", 1), "a hint first shown in the attempt is unshown")

func _test_the_ledger_survives_the_save(t: TestRunner) -> void:
	var ledger := HintLedger.new()
	ledger.record_show(&"back_to_route")
	ledger.record_show(&"back_to_route")
	ledger.photograph()
	var json := JSON.new()
	t.check(json.parse(JSON.stringify(ledger.to_data())) == OK, "its data is JSON-safe")
	var restored := HintLedger.new()
	restored.restore(json.data as Dictionary)
	t.check(not restored.has_shows_left(&"back_to_route", 2), "its shows come back as whole numbers")
	restored.give_back()
	t.check(not restored.has_shows_left(&"back_to_route", 2), "and so does its photograph")
	var fresh := HintLedger.new()
	fresh.restore({})
	t.check(fresh.has_shows_left(&"back_to_route", 1), "a save from before the bubbles loads with none shown")
