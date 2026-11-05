extends RefCounted
## What the interior suites share: the runs a suite starts for a building's events to belong to.

var _runs: Array[RunState] = []

## A fresh run of the suite's own, started on a seed, for a building's events to belong to.
func fresh_run() -> RunState:
	var run := RunState.new()
	run.start_run(4242)
	_runs.append(run)
	return run

## Frees every run started, after the events that were handed them are freed.
func free_all() -> void:
	for made in _runs:
		made.free()
	_runs.clear()
