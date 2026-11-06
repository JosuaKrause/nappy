extends RefCounted
## The escape, part c: where she comes out, the sections, the clock, pause and the route rig.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/finale_rig.gd`.

const Rig := preload("res://tests/finale_rig.gd")

func run(t) -> void:
	var cases: Array[int] = [26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47]
	await Rig.new().run_cases(t, cases)
