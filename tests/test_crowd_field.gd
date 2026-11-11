extends RefCounted
## The crowd against a real city: the field around the player, lanes and headways, the morning's unpacking and how the crowd is drawn.
## One of the parts the suite is split into so none runs two minutes serial; the cases are in `tests/crowd_rig.gd`.

const Rig := preload("res://tests/crowd_rig.gd")

func run(t: TestRunner) -> void:
	var rig := Rig.new()
	await rig.run_part(t, "field")
