class_name RunCity
extends RefCounted
## A `City` handed the run it stands in (`City.run`), which `City.build()` refuses to run without.
## A test or rig that builds a city outside a boot hands it a run of its own (`in_run`, or
## `with_own_run` for a run the city holds). `of_the_run` is the stand-in's accessor, for the suites
## not yet moved onto a run of their own; the last wave drops it with the stand-in.

## A city over the stand-in run `GameState` holds, for a suite not yet moved onto a run of its own.
static func of_the_run(scene: PackedScene) -> City:
	var city: City = scene.instantiate()
	city.run = GameState
	return city

## A city over a run the caller made (`RunState.new()` then `start_run(<seed>)`, freed after), where
## the test hands the code it exercises a run of its own rather than the autoload's.
static func in_run(scene: PackedScene, run: RunState) -> City:
	var city: City = scene.instantiate()
	city.run = run
	return city

## A city over a fresh run of its own (`start_run(run_seed)`), which the city holds as a child so
## freeing the city frees the run.
static func with_own_run(scene: PackedScene, run_seed: int) -> City:
	var run := RunState.new()
	run.start_run(run_seed)
	var city := in_run(scene, run)
	city.add_child(run)
	return city
