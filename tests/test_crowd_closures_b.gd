@warning_ignore_start("untyped_declaration")
extends RefCounted
## The crowd against the map edges: the tunnel, the mountain, a plain edge and the entry roll.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/crowd_closures_rig.gd`.

const Rig := preload("res://tests/crowd_closures_rig.gd")

func run(t: TestRunner) -> void:
	var rig = Rig.new()
	var scenarios: Array[int] = [12, 13, 15, 16]
	rig.run_scenarios(t, scenarios)
