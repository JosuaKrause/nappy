extends RefCounted
## The rig the event manager suites share (`tests/test_event_manager.gd`,
## `tests/test_event_manager_fire.gd` and `tests/test_event_manager_units.gd`): a real generated
## city in a run of its own, the day's random stream, a day started on the city's streets, the
## walking tick, a player the manager can find, and what walks her down a route.
##
## **Its cities come from the cache of generated cities** (`tests/city_map_cache.gd`): each
## seed's city is generated once in the test process and every case is handed a copy of its own,
## the same city `CityGenerator.generate()` builds for the seed.

const MapCache := preload("res://tests/city_map_cache.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

## A walking tick: a tenth of a second, which is what a tick is at `WALK_SCALE` times real time.
const WALK_STEP := 1.0 / 10.0
## The walks go at this many times real time (`PhysicsTicks`), so each tick is `WALK_STEP` long and
## a walk of a minute takes ten seconds of the run.
const WALK_SCALE := 6.0

## A city of the suite's seed in a run of its own, added to `t`, so no test leans on what an
## earlier one left behind. Streaming is let reach the whole map: with no player in the rig nothing
## would ever come within streaming reach, and the questions about the manager's wiring over a day's
## events are the same whether or not the day is streamed. A test that streams sets the radius it
## needs (`Tuning.EVENT_STREAM_RADIUS`); streaming itself is checked in
## `test_event_manager.gd`'s `_test_an_event_waits_until_she_is_near_it`.
static func build_city(t: TestRunner) -> City:
	var city := RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(MapCache.of(SEED))
	city.events.stream_radius = INF
	return city

## The stream a day's events are planned from.
static func rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

## Starts day `day` on `city` through the manager, which plans it against the city's streets: the
## rig runs no dawn of the city's own (`City.start_day()`), so it begins them for the day first, as
## dawn grows them with no street closed (`RigStreets.begin()`). `consumed` is the one-shots the run
## has already spent, appended to as the day spends them; `focus` is where she stands as the walk
## starts, round which its units draw (`EventManager.start_day()`).
static func start(city: City, day: int, consumed: Array[String] = [],
		focus := Vector2.ZERO) -> void:
	var spec := DaySpec.for_day(day)
	RigStreets.begin(city.streets(), city.map, spec)
	city.events.start_day(spec, rng(day), consumed, focus)

## A player the manager can find, out of the physics loop (its own physics is off) and moved by
## hand or by a walking node. A camera is under it, as the manager looks through her camera.
static func walker(t: TestRunner, city: City, at: Vector2) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	# Set here rather than left to the engine: a camera built in code under physics interpolation is
	# overridden to the physics callback with a warning, and a warning in a test run is a failure.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	# Never the current camera: this camera is not the viewport's, so it works out nothing about where
	# it is drawing from, and what she can see (`VisibleView.look_through()`) is about her,
	# `Stroller.camera_screen_center()`'s own answer for a camera that is not current.
	camera.enabled = false
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.global_position = at
	city.events.use_player(rig)
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
## its centre (`EventScheduler.WalkSiting.cell_centre()`). The tree is the city's own where a dawn
## of the city grew one, and one grown for the day otherwise, as the manager chooses it.
static func longest_route_out(city: City, day: int) -> PackedVector2Array:
	var grown := city.streets().route_tree()
	var tree := grown if grown else RouteTree.for_day(city.map, day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var siting := EventScheduler.WalkSiting.new(day, city.map, tree, city.events.walk_events(),
			EventScheduler.Verdicts.new(), GamePlanBuilder.over(city.map), null)
	var points := PackedVector2Array()
	for i in best.size():
		points.append(siting.cell_centre(best[best.size() - 1 - i]))
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
