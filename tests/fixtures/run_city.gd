class_name RunCity
extends RefCounted
## A `City` handed the run it stands in (`City.use_run()`), which `City.build()` refuses to run
## without.
## A test or rig that builds a city outside a boot makes a run of its own (`started_run()`), keeps
## it and hands it to `build()`, which hands it to the city and to the simulation alike, so the two
## cannot stand in different runs. It keeps the library it hands `build()` and the trace it reads:
## the city is asked for none of them. A suite asks this class, never the city, for the parts
## standing in a city it built: `build()` builds it and stands its simulation in it as `main` does
## (`SimulationBuilder.in_the_city()`), and `simulation()`, `events()`, `crowd()`, `spawn_siting()`
## and `poster_walls()` find its `WorldSimulation`, `EventManager`, `Crowd`, `SpawnSiting` and
## `PosterWalls` in the tree, under the name the builder gives the simulation
## (`WorldSimulation.NODE_NAME`), the way `tests/booted_main.gd` finds what a booted `main` built.
##
## **The city and every builder `build()` uses are equipped with one trace, one library and one
## frame timing** (`City.equip()`, `SimulationBuilder.equip()`), so the city and its parts draw from
## one library as a booted city does, without reading any field of the city. A suite that wants a
## part configured otherwise makes a builder (`new_builder()`), hands it what `main` would
## (`leave_out()`, `use_the_crowds_screen()` and the like) and hands it to `build()`; it hands the
## city its own library through `build()`, never the builder.
##
## **Nobody is handed her but by the suite.** A city's crowd, poster walls and blackout meet her
## only when she is handed in, as the game hands her at the start of a walk
## (`WorldSimulation.meet_her()`): a suite that walks her past the walls or away from the station
## says when they see her (`show_her_to_the_walls_and_the_blackout()`), and one that wants the crowd
## to meet her too calls `meet_her()`.

## The name the builder gives a city's blackout under its simulation (`SimulationBuilder`), which
## nothing reads back but a suite handing it her.
const BLACKOUT_NODE := "Blackout"

## A city of `scene`, not yet handed its run, its library or its map: `build()` hands them.
static func new_city(scene: PackedScene) -> City:
	return scene.instantiate() as City

## A fresh run started on `run_seed`, for a suite to keep and hand `build()`.
static func started_run(run_seed: int) -> RunState:
	var run := RunState.new()
	run.start_run(run_seed)
	return run

## A builder as a suite configures one before `build()`: handed the game's bus, as `main` hands
## it (`main._simulation_builder()`), and nothing else yet.
static func new_builder() -> SimulationBuilder:
	var made := SimulationBuilder.new(EventCatalogue.shipped())
	made.use_bus(EventBus)
	return made

## Builds `city` on `map` (`City.build()`), then stands its simulation in it with `builder`
## (`SimulationBuilder.in_the_city()`), or with a builder of the game's defaults where the suite
## hands none: what a suite calls in place of `city.build(rows, map)`, the rows the shipped
## catalogue's (`EventCatalogue.shipped()`). `run` is the one the suite
## made by `started_run()`, which `build()` hands the city and the simulation alike.
## `dark_from_the_start` is the escape's city, dark from its first frame. `library` is the one the
## city and its parts draw from, a new one where the suite hands none.
static func build(city: City, run: RunState, map: CityMap, builder: SimulationBuilder = null,
		dark_from_the_start := false, library: AtlasLibrary = null) -> void:
	city.use_run(run)
	var trace := RunTrace.new()
	var timing := FrameTiming.new()
	var pictures := library if library else AtlasLibrary.new()
	city.equip(trace, pictures, timing)
	city.build(EventCatalogue.shipped(), map)
	var stands := builder if builder else new_builder()
	stands.equip(trace, pictures, timing)
	stands.in_the_city(city, city.map(), city.navigator(), city.streets(), city.traffic_signals(),
			city.buildings(), run, dark_from_the_start)

## What stands in `city` (`WorldSimulation`): its events, its crowd, its poster walls and its
## blackout.
static func simulation(city: City) -> WorldSimulation:
	return city.get_node(NodePath(WorldSimulation.NODE_NAME)) as WorldSimulation

## A world standing for a walk in `city`, built of the city's own parts as `main` builds one
## (`main._the_world_of()`): its map, streets, dressing (the city itself), crowd, poster walls and
## events, her and the baby in it, put down at the doorstep, the walk won nowhere. For a suite that
## hands an authored scene or a draft a world while it still builds a real city. `baby` is the one
## under `player` where none is handed; `player` may be null where nobody is asked.
static func world_of(city: City, player: Stroller, baby: Baby = null) -> DayWorld:
	var carried := baby if baby else (player.get_node_or_null("Baby") as Baby if player else null)
	return DayWorld.in_the_city(city, city.map(), city.streets(), crowd(city), poster_walls(city),
			events(city), player, carried, city.map().doorstep_world_position(), null, {})

## The day's events on `city`'s streets (`EventManager`).
static func events(city: City) -> EventManager:
	return simulation(city).events()

## The crowd on `city`'s streets (`Crowd`).
static func crowd(city: City) -> Crowd:
	return simulation(city).crowd()

## Where something sent at her may start in `city` (`SpawnSiting`).
static func spawn_siting(city: City) -> SpawnSiting:
	return events(city).spawn_siting()

## The posters on `city`'s fronts (`PosterWalls`).
static func poster_walls(city: City) -> PosterWalls:
	return simulation(city).poster_walls()

## **Hands her to `city`'s poster walls and its blackout, and not to its crowd**: from here on a
## crew pastes while she watches, her push tears a sheet and the blackout measures her distance
## from the station (`PosterWalls.use_player()`, `Blackout.use_player()`), while the crowd keeps
## the rig's own arrangement with her. `player` is her, or a rig body the blackout measures and the
## walls, which only a `Stroller` can push, do not see.
static func show_her_to_the_walls_and_the_blackout(city: City, player: Node2D) -> void:
	poster_walls(city).use_player(player as Stroller)
	var blackout := simulation(city).get_node(BLACKOUT_NODE) as Blackout
	blackout.use_player(player)
