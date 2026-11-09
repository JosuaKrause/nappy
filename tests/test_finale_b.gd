extends RefCounted
## The escape, part b: roadblock guards, the plan on the day's ground, the bag and the service exit.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/finale_rig.gd`.

const Rig := preload("res://tests/finale_rig.gd")

func run(t) -> void:
	var cases: Array[int] = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
	await Rig.new().run_cases(t, cases)
