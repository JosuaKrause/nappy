extends RefCounted
## What the interior suites share: the runs a suite starts for a building's events to belong to.

## A fresh run of the suite's own, started on a seed, for a building's events to belong to.
func fresh_run() -> RunState:
	var run := RunState.new()
	run.start_run(4242)
	return run
