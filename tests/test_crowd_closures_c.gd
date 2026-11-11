@warning_ignore_start("untyped_declaration")
extends RefCounted
## The crowd on the spine and at the day start: cars put out of sight, an entry that keeps room for its picture.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/crowd_closures_rig.gd`.

const Rig := preload("res://tests/crowd_closures_rig.gd")

func run(t: TestRunner) -> void:
	var rig = Rig.new()
	var scenarios: Array[int] = [14, 17]
	rig.run_scenarios(t, scenarios)
	rig.run_day_start(t)
