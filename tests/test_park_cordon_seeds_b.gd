extends RefCounted
## Day 12's police cordon across part 2 of 3 of the seed sweep: seeds 2, 5, 8 and so on every third seed to 40.
## What it checks is `tests/park_cordon_sweep.gd`'s header; the sweep is split three ways so that
## no suite runs two minutes serial.

const SWEEP := preload("res://tests/park_cordon_sweep.gd")

func run(t: TestRunner) -> void:
	SWEEP.new().sweep(t, SWEEP.part(1, 3))
