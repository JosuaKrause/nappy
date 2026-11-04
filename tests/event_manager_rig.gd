extends RefCounted
## The rig the two event manager suites share (`tests/test_event_manager.gd` and
## `tests/test_event_manager_fire.gd`): a real generated city in a run of its own, the day's
## random stream, a day started, the walking tick, and a player the manager can find.

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
static func build_city(t) -> City:
	var city := RunCity.with_own_run(CITY_SCENE, SEED)
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	city.events.stream_radius = INF
	return city

## The stream a day's events are planned from.
static func rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [SEED, day])
	return rng

## Starts day `day` on `city` through the manager.
static func start(city: City, day: int) -> void:
	var consumed: Array[String] = []
	city.events.start_day(DaySpec.for_day(day), rng(day), consumed)

## A player the manager can find, out of the physics loop (its own physics is off) and moved by
## hand or by a walking node. A camera is under it, as the manager looks through her camera.
static func walker(t, city: City, at: Vector2) -> Stroller:
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
