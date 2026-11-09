class_name DayWorld
extends RefCounted
## A world standing for one spec, as the day director is handed it (`DayWorldSource.stand()`): the
## scene she walks, the events walked among, her and the baby in it, where she is put down and which
## way she faces, and the city whose streets and crowd she walks where the world is one. The fourteen
## days and the escape's city section stand in a city; the escape's building has no streets and no
## crowd, only its events.
##
## Built by whoever stood the world, with everything it answers worked out there; the director only
## asks. `in_the_city()` and `in_the_building()` are the two shapes there are.

var _scene: Node2D
var _events: EventManager
var _player: Stroller
var _baby: Baby
var _start := Vector2.INF
var _facing := Vector2.DOWN
var _city: City
var _plan_rng: RandomNumberGenerator

## A city's world: `city` and its events, her and the baby in it, put down at `start` facing
## `facing`. Its walk is planned on the spec's own stream of the run (`DaySpec.events_stream()`).
static func in_the_city(city: City, events: EventManager, player: Stroller, baby: Baby,
		start: Vector2, facing := Vector2.DOWN) -> DayWorld:
	var world := DayWorld.new()
	world._scene = city
	world._city = city
	world._events = events
	world._player = player
	world._baby = baby
	world._start = start
	world._facing = facing
	return world

## A world with no city: `scene` and the events in it, her and the baby in it, put down at `start`
## facing `facing`, its walk planned on `plan_rng` — the escape's building, whose events are planned
## on a seed of its own that its night shares, the same on every entry so a retry is the same
## building.
static func in_the_building(scene: Node2D, events: EventManager, player: Stroller, baby: Baby,
		start: Vector2, facing: Vector2, plan_rng: RandomNumberGenerator) -> DayWorld:
	var world := DayWorld.new()
	world._scene = scene
	world._events = events
	world._player = player
	world._baby = baby
	world._start = start
	world._facing = facing
	world._plan_rng = plan_rng
	return world

## The scene she walks: the city, or the building.
func scene() -> Node2D:
	return _scene

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

## The city she walks, with its streets and its crowd, or null in a world with neither.
func city() -> City:
	return _city

## The stream the walk is planned on when the world has one of its own, or null for the spec's own
## stream of the run (`DaySpec.events_stream()`).
func plan_rng() -> RandomNumberGenerator:
	return _plan_rng
