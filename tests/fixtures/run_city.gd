class_name RunCity
extends RefCounted
## A `City` handed the run it stands in (`City.run`), which `City.build()` refuses to run without.
## A test or rig that builds a city outside a boot hands it a run of its own (`in_run`, or
## `with_own_run` for a run the city holds).

## A city over a run the caller made (`RunState.new()` then `start_run(<seed>)`), where
## the test hands the code it exercises a run of its own.
static func in_run(scene: PackedScene, run: RunState) -> City:
	var city: City = scene.instantiate()
	city.run = run
	return city

## A city over a fresh run of its own (`start_run(run_seed)`), which the city holds (`City.run`).
static func with_own_run(scene: PackedScene, run_seed: int) -> City:
	var run := RunState.new()
	run.start_run(run_seed)
	var city := in_run(scene, run)
	return city

## Builds `city` on `map` (`City.build()`), with its events and its crowd standing in it: what a
## suite calls in place of `city.build(map)`.
static func build(city: City, map: CityMap) -> void:
	city.build(map)

## The day's events on `city`'s streets (`EventManager`).
static func events(city: City) -> EventManager:
	return city.events

## The crowd on `city`'s streets (`Crowd`).
static func crowd(city: City) -> Crowd:
	return city.crowd

## Where something sent at her may start in `city` (`SpawnSiting`).
static func spawn_siting(city: City) -> SpawnSiting:
	return city.spawn_siting

## The posters on `city`'s fronts (`PosterWalls`).
static func poster_walls(city: City) -> PosterWalls:
	return city.poster_walls()
