@warning_ignore_start("untyped_declaration")
extends RefCounted
## Day 12's police cordon across part 3 of 3 of the seed sweep: seeds 3, 6, 9 and so on every third seed to 40, and the largest calm zone's seed.
## What it checks is `tests/park_cordon_sweep.gd`'s header; the sweep is split three ways so that
## no suite runs two minutes serial.

const SWEEP := preload("res://tests/park_cordon_sweep.gd")

func run(t) -> void:
	SWEEP.new().sweep(t, SWEEP.part(2, 3))
