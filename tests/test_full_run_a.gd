extends RefCounted
## Fourteen days end to end, the run of seed 4242. One of the parts the suite is split into by seed so
## none runs two minutes serial; the run is in `tests/full_run_rig.gd`.

const Rig := preload("res://tests/full_run_rig.gd")

func run(t) -> void:
	await Rig.new().run(t, 4242)
