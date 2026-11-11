extends RefCounted
## Fourteen days end to end, the run of seed 4242. One of the parts the suite is split into by seed so
## none runs two minutes serial; the run is in `tests/full_run_rig.gd`.
##
## It builds every real piece on purpose: the game's composition is what it tests. Played days with
## time advancing are the only place the mobile one-shots finish and the whole successor-and-scar
## chain runs, which no suite of one module can see.

const Rig := preload("res://tests/full_run_rig.gd")

func run(t: TestRunner) -> void:
	await Rig.new().run(t, 4242)
