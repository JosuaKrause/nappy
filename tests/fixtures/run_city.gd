class_name RunCity
extends RefCounted
## A `City` handed the run it stands in (`City.run`), which `City.build()` refuses to run without.
## A test or rig that builds a city outside a boot says so by taking the live run (`of_the_run`).

## A city over the run `GameState` holds, as `main._new_city()` builds it.
static func of_the_run(scene: PackedScene) -> City:
	var city: City = scene.instantiate()
	city.run = GameState
	return city
