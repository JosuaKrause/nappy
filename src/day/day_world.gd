class_name DayWorld
extends RefCounted
## A world standing for one spec, as the day director and the run log are handed it
## (`DayWorldSource.stand()`, `RunFlow.world_stood`): the map of the ground she walks, the events
## walked among, her and the baby in it, where she is put down and which way she faces, the city's
## parts where the world is one (its map, today's streets, its crowd, its poster walls and what
## dresses it for the day), and what the walk is won at in it — the map her front door is on, or the ways out of it.
## The fourteen days and the escape's city section stand in a city; the escape's building has no
## streets and no crowd, only its events.
##
## **The city's parts, never the city.** *(inbox #1156 in gray-dolphin: "the city should never be
## built for tests that don't test the actual city".)* The director and the run log are handed only
## what they read of the city, each a part of its own: the map (`CityMap`), today's streets
## (`DayStreets`), the crowd, the poster walls and the city scene's own dressing (`CityDressing`), so
## a test stands a world of fakes with no city. An authored scene is handed the same world and
## installs itself into it (`AuthoredScene.install()`).
##
## Built by whoever stood the world, with everything it answers worked out there; the director and
## the run log only ask, and the director hands on what the walk's goal is read from (the ways out to the spec, the home's map to
## the day's clock), so a source only stands a world. `in_the_city()` and `in_the_building()` are the
## two shapes there are.

var _map: WorldMap
var _events: EventManager
var _player: Stroller
var _baby: Baby
var _start := Vector2.INF
var _facing := Vector2.DOWN
var _in_a_city := false
var _city_map: CityMap
var _streets: DayStreets
var _crowd: Crowd
var _dressing: CityDressing
var _posters: PosterWalls
var _plan_rng: RandomNumberGenerator
var _home_map: CityMap
var _exits := {}

## A city's world: its map `map`, today's streets `streets`, its crowd `crowd`, the walls its posters
## are pasted on `posters`, what dresses the city for the day `dressing` and its events, her and the baby in it, put down at `start` facing
## `facing`. Its walk is won at her front door on `home_map` — the city's own map on a walk home,
## null on one that is not — or at `exits`, the ways out of the city by `CityExit.Kind`, empty on a
## walk with none. Its walk is planned on the spec's own stream of the run
## (`DaySpec.events_stream()`).
##
## **A city has all five of its parts**, so a world is a city or it is not (`is_in_a_city()`), and
## nothing that walks it asks which parts it has. Refused, null, when the dressing, the map, the
## streets, the crowd or the poster walls is missing: a half-city is a world nothing could walk.
static func in_the_city(dressing: CityDressing, map: CityMap, streets: DayStreets, crowd: Crowd,
		posters: PosterWalls, events: EventManager, player: Stroller, baby: Baby, start: Vector2,
		home_map: CityMap, exits: Dictionary, facing := Vector2.DOWN) -> DayWorld:
	if dressing == null or map == null or streets == null or crowd == null or posters == null:
		return null
	var world := DayWorld.new()
	world._in_a_city = true
	world._map = map
	world._city_map = map
	world._streets = streets
	world._crowd = crowd
	world._dressing = dressing
	world._posters = posters
	world._events = events
	world._player = player
	world._baby = baby
	world._start = start
	world._home_map = home_map
	world._exits = exits
	world._facing = facing
	return world

## A world with no city: the map `map` of the ground she walks and the events in it, her and the
## baby in it, put down at `start` facing `facing`, its walk planned on `plan_rng` — the escape's
## building, whose events are planned on a seed of its own that its night shares, the same on every
## entry so a retry is the same building. No front door and no ways out: the building's service exit says itself when she is
## through it (`InteriorScene.exit_requested`).
static func in_the_building(map: WorldMap, events: EventManager, player: Stroller, baby: Baby,
		start: Vector2, facing: Vector2, plan_rng: RandomNumberGenerator) -> DayWorld:
	var world := DayWorld.new()
	world._map = map
	world._events = events
	world._player = player
	world._baby = baby
	world._start = start
	world._facing = facing
	world._plan_rng = plan_rng
	return world

## The map of the ground she walks (`WorldMap`): the city's, or the building's own grid — what a
## line the run log writes names a tile on.
func map() -> WorldMap:
	return _map

## The events walked among.
func events() -> EventManager:
	return _events

## Her, standing in this world.
func player() -> Stroller:
	return _player

## The baby she carries.
func baby() -> Baby:
	return _baby

## Where she is put down as the walk starts: the spec's start point in this world
## (`DaySpec.start_point()`), worked out by whoever stood it.
func start_position() -> Vector2:
	return _start

## Which way she faces as she is put down.
func start_facing() -> Vector2:
	return _facing

## Whether this world is a city, with all five of the city's parts (`in_the_city()`): the one answer
## the director and the run log key every city branch on, rather than asking which parts it has.
func is_in_a_city() -> bool:
	return _in_a_city

## The city's map, with its streets, blocks and calm ground, or null in a world with no city.
func city_map() -> CityMap:
	return _city_map

## Today's streets as dawn left them (`DayStreets`), or null in a world with no city.
func streets() -> DayStreets:
	return _streets

## The crowd on the city's streets, or null in a world with no city.
func crowd() -> Crowd:
	return _crowd

## What dresses the city for the day (`CityDressing`), or null in a world with no city to dress.
func dressing() -> CityDressing:
	return _dressing

## The walls the city's posters are pasted on, or null in a world with no city. An authored scene
## is the one that reads them.
func poster_walls() -> PosterWalls:
	return _posters

## The stream the walk is planned on when the world has one of its own, or null for the spec's own
## stream of the run (`DaySpec.events_stream()`).
func plan_rng() -> RandomNumberGenerator:
	return _plan_rng

## The map her front door is on, which the day's clock checks home and the calm she settles on
## against (`DayController.use_the_walk()`): the city's map on a walk home, null on any other.
func home_map() -> CityMap:
	return _home_map

## The ways out of the world by `CityExit.Kind`, each the world point a walk out of it ends at, which
## the spec is handed (`DaySpec.use_exits()`): the escape city's two, empty in any other world.
func exits() -> Dictionary:
	return _exits
