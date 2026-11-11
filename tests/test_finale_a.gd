extends RefCounted
## The escape, part a: the chains, their exits and the roadblocks on them.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/finale_rig.gd`.

const Rig := preload("res://tests/finale_rig.gd")

func run(t: TestRunner) -> void:
	var cases: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]
	await Rig.new().run_cases(t, cases)
