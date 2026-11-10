@warning_ignore_start("untyped_declaration")
extends RefCounted
## The crowd against seals, pockets, turn-arounds, the region wall, a door and an ordinary edge.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/crowd_closures_rig.gd`.

const Rig := preload("res://tests/crowd_closures_rig.gd")

func run(t) -> void:
	var rig = Rig.new()
	var scenarios: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	rig.run_scenarios(t, scenarios)
	rig.run_region_wall(t)
	rig.run_door_day(t)
