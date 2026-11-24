extends RefCounted
## The rig the event manager suites share (`tests/test_event_manager.gd`,
## `tests/test_event_manager_fire.gd` and `tests/test_event_manager_units.gd`): a manager over a
## generated map and no city (`Stage`), the day's random stream, a day started on the streets the
## stage holds, the walking tick, a player the manager can find, and what walks her down a route.
## A case that needs what only a city holds builds the stage in one (`build_city_stage()`).
##
## **Its maps come from the cache of generated cities** (`tests/city_map_cache.gd`): each seed's
## city is generated once in the test process and every case is handed a copy of its own, the
## same map `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The bus script, so a recording bus of a suite's own is the class a manager takes.
const _BUS := preload("res://src/autoload/event_bus.gd")
const SEED := 4242

## A walking tick: a tenth of a second, which is what a tick is at `WALK_SCALE` times real time.
const WALK_STEP := 1.0 / 10.0
## The walks go at this many times real time (`PhysicsTicks`), so each tick is `WALK_STEP` long and
## a walk of a minute takes ten seconds of the run.
const WALK_SCALE := 6.0

## What a case stands the manager on: a copy of the suite's seed's generated map, a run of its own,
## the streets a day it starts is planned against and the manager over them, with its world node a
## child of the manager and the manager a child of the test. Nothing of the city is built round it
## (no crowd, no scenery, no poster walls, no lights): the manager asks the map, the run and the
## streets, and the one wiring it has with the crowd (the listener a drawn body is told to) is the
## builder's (`tests/test_simulation_builder.gd`). `free_events()` frees the manager and, with
## it, the world node and every live event.
class Stage extends RefCounted:
	var _events: EventManager
	var _map: CityMap
	var _run: RunState
	var _streets: DayStreets
	var _city: City

	func _init(events: EventManager, map: CityMap, run: RunState, streets: DayStreets,
			city: City = null) -> void:
		_events = events
		_map = map
		_run = run
		_streets = streets
		_city = city

	## The manager.
	func events() -> EventManager:
		return _events

	## The map the manager stands on.
	func map() -> CityMap:
		return _map

	## The run the manager's events belong to.
	func run() -> RunState:
		return _run

	## The streets a day the manager starts is planned against.
	func streets() -> DayStreets:
		return _streets

	## The city the manager stands in, where the stage was built in one (`build_city_stage()`);
	## null for a stage with none.
	func city() -> City:
		return _city

	## Hands her to the city's poster walls and its blackout, where the stage has a city.
	func show_her_to_the_city(her: Stroller) -> void:
		if _city:
			RunCity.show_her_to_the_walls_and_the_blackout(_city, her)

	## Frees the manager, and with it its world node and every live event: the city, where the
	## stage has one.
	func free_events() -> void:
		if _city:
			_city.free()
		else:
			_events.free()

## A stage of the suite's seed, its manager in the tree of `t` so no test leans on what an earlier
## one left behind. Streaming is let reach the whole map: with no player in the rig nothing would
## ever come within streaming reach, and the questions about the manager's wiring over a day's
## events are the same whether or not the day is streamed. A test that streams sets the radius it
## needs (`Tuning.EVENT_STREAM_RADIUS`); streaming itself is checked in
## `test_event_manager.gd`'s `_test_an_event_waits_until_she_is_near_it`. `bus` is the bus the
## manager reports on where a test hands one of its own, the game's otherwise. `on` is the map it
## stands on where a case asks only a few drawn streets (`StreetMap.full()`), the seed's generated
## city's otherwise.
static func build_stage(t: TestRunner, bus: _BUS = null, on: CityMap = null) -> Stage:
	var run := RunState.new()
	run.start_run(SEED)
	var map := on if on else MapCache.of(SEED)
	var streets := DayStreets.new()
	var manager := StreetEvents.over(t, map, run, streets, INF)
	if bus:
		manager.use_bus(bus)
	return Stage.new(manager, map, run, streets)

## A stage in a city of the suite's seed, for a case that asks of the city what no map holds: the
## city's own dawn (`City.start_day()`), or the blank walls its buildings give a poster crew. The
## manager is the simulation's, standing as `main` stands it, streaming reaching the whole map as
## `build_stage()`'s does; the stage frees the city.
static func build_city_stage(t: TestRunner) -> Stage:
	var run := RunCity.started_run(SEED)
	var city := RunCity.new_city(CITY_SCENE)
	t.add_child(city)
	RunCity.build(city, run, MapCache.of(SEED))
	RunCity.events(city).stream_within(INF)
	return Stage.new(RunCity.events(city), city.map(), run, city.streets(), city)

## The stream a day's events are planned from.
static func rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

## Starts day `day` on `stage` through the manager, which plans it against the stage's streets: the
## rig runs no dawn of a city's own (`City.start_day()`), so it begins them for the day first, as
## dawn grows them with no street closed (`RigStreets.begin()`). `consumed` is the one-shots the run
## has already spent, appended to as the day spends them; `focus` is where she stands as the walk
## starts, round which its units draw (`EventManager.start_day()`).
static func start(stage: Stage, day: int, consumed: Array[String] = [],
		focus := Vector2.ZERO) -> void:
	var spec := DaySpec.for_day(day)
	RigStreets.begin(stage.streets(), stage.map(), spec)
	stage.events().start_day(spec, rng(day), consumed, focus)

## A player the manager is handed, out of the physics loop (its own physics is off) and moved by
## hand or by a walking node. A camera is under it, as the manager
## looks through her camera.
static func walker(t: TestRunner, stage: Stage, at: Vector2) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	# Set here rather than left to the engine: a camera built in code under physics interpolation is
	# overridden to the physics callback with a warning, and a warning in a test run is a failure.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# Never the current camera: this camera is not the viewport's, so it works out nothing about where
	# it is drawing from, and what she can see (`VisibleView.look_from()`) is about her,
	# `Stroller.view_centre_of()`'s own answer for a camera that is not current.
	camera.enabled = false
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.global_position = at
	stage.events().use_player(rig)
	# The walls paste and the blackout measures only for her, handed in as a walk hands her.
	stage.show_her_to_the_city(rig)
	return rig

## Takes her down a route on its own physics tick, at `Tuning.WALK_SPEED`: a point is walked to
## rather than through, and `velocity` is set to match, since the director's clock only runs while
## she is actually going somewhere and its heading is read off `velocity`. A point within a step of
## her is passed over. Added to the tree before the city, so the manager's tick sees her where this
## tick put her.
class Walker extends Node:
	var rig: Stroller
	var route := PackedVector2Array()
	var next := 0
	var heading := Vector2.RIGHT

	func _physics_process(delta: float) -> void:
		if rig == null:
			return
		var step := Tuning.WALK_SPEED * delta
		while next < route.size() and route[next].distance_to(rig.global_position) <= step:
			next += 1
		if next >= route.size():
			return
		heading = (route[next] - rig.global_position).normalized()
		rig.velocity = heading * Tuning.WALK_SPEED
		rig.global_position += heading * step

## The index of the route point she is standing nearest to. A route is a chain of cell centres and
## she walks between them, so this is where a resumed walk picks up.
static func nearest_on(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in route.size():
		var distance := route[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

## The longest route of day `day`'s tree as the line she walks out from the doorstep: a route is
## grown from the calm area to the doorstep, so the walk out is the route reversed, each cell at
## its centre (`RouteTree.cell_centre()`). The tree is the stage's own where a day was started on
## it, and one grown for the day otherwise, as the manager chooses it.
static func longest_route_out(stage: Stage, day: int) -> PackedVector2Array:
	var grown := stage.streets().route_tree()
	var tree := grown if grown else RouteTree.for_day(stage.map(), day)
	var best: Array = []
	for branch in tree.branches():
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for i in best.size():
		points.append(tree.cell_centre(best[best.size() - 1 - i]))
	return points

## Each of `units`' draws as `name: row@tile, ...`, one line a unit, a row handed to her walk as
## `row@walk`, wherever her walk has since sited it: what a unit drew, read the same on any start
## of the same city and day.
static func what_the_units_drew(map: CityMap, units: Array[PlacementUnit]) -> String:
	var lines: Array[String] = []
	for unit in units:
		var parts: Array[String] = []
		for plan in unit.drawn():
			parts.append("%s@%s" % [plan.row_id(), "walk" if plan.row().is_handed_to_her_walk()
					else str(map.world_to_tile(plan.placed_at()))])
		lines.append("%s: %s" % [unit.name(), ", ".join(parts)])
	lines.sort()
	return "\n".join(lines)
