class_name RunCity
extends RefCounted
## A `City` handed the run parts it reads (`City.run_posters`, `run_spend`, `run_resistance`),
## which `City.build()` refuses to run without. A test or rig that builds a city outside a boot
## says which run it means: the live run's own parts (`of_the_run`), or parts of its own (`fresh`).

## A city over the run `GameState` holds, as `main._new_city()` builds it.
static func of_the_run(scene: PackedScene) -> City:
	var city: City = scene.instantiate()
	city.run_posters = GameState.posters
	city.run_spend = GameState.attempt_spend
	city.run_resistance = GameState.resistance
	return city

## A city over parts of its own: bare walls, nothing spent, nothing done.
static func fresh(scene: PackedScene) -> City:
	var city: City = scene.instantiate()
	city.run_posters = PosterState.new()
	city.run_spend = AttemptSpendState.new()
	city.run_resistance = ResistanceRunState.new()
	return city
