extends RefCounted
## **How old a row sent down her line at once is as it is created** (`EventsAhead._send_down_her_line()`):
## the dog walker the director sends ahead of her (`EventDef.is_sent_ahead()`) is created past its
## telegraph at a point of its bark drawn on the director's stream
## (`EventDirector.age_it_is_sent_at()`), so a pass costs the row's price in `docs/COSTS.md`, which
## averages the bark's points, whichever way the street runs; the loose dog is created at the age a
## warned row would have (`EventSpawner.age_when_warned()`), the loud of its beat on her, the point
## its own line in that table prices. Each row is forced every `FORCED_INTERVAL` seconds while she
## walks down the arterial's sidewalk, and the age of every one created is read as it appears.
##
## **The subject is what the event manager creates**, so it is built over a copy of the generated
## city's map and no city (`tests/fixtures/street_events.gd`), as `tests/test_loose_dog_arrives.gd`
## is: the sidewalk each row is sent down, and what the day stands on it, are the streets' and the
## siting's own, and nothing else of a city is read.

const MapCache := preload("res://tests/city_map_cache.gd")
## The run's seed. Where she walks is chosen clear of the day's bodies (`_on_a_clear_line()`).
const RUN_SEED := 2
## The engine's clock for the walk, sped up and put back after it.
const FAST_SCALE := 3.0
## Seconds between two forced rows: short, so several are sent within the walk.
const FORCED_INTERVAL := 1.0
## How many of each row are read, and the game seconds the walk may take to send them.
const SENT := 6
const WALK_FOR := 20.0

var _events: EventManager
var _map: CityMap
var _run: RunState
var _streets := DayStreets.new()
var _rig: Stroller

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	_run = RunState.new()
	_run.start_run(RUN_SEED)
	_map = MapCache.of(4242)
	_events = StreetEvents.over(t, _map, _run, _streets)
	_rig = Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.enabled = false
	_rig.add_child(camera)
	t.add_child(_rig)
	_rig.set_physics_process(false)
	_events.use_player(_rig)
	await _test_the_dog_walker_is_created_at_a_drawn_point_of_its_bark(t)
	await _test_the_loose_dog_is_created_at_the_loud_of_its_beat_on_her(t)
	_rig.free()
	_events.free()

## Every dog walker sent is past its telegraph, and the points of its bark they are created at are
## spread over its beat, not one point: a quarter of its period at least between the earliest and
## the latest of `SENT`.
func _test_the_dog_walker_is_created_at_a_drawn_point_of_its_bark(t: TestRunner) -> void:
	var made := await _sent("dog_walker", t)
	var def := EventCatalogue.by_id("dog_walker")
	t.check(made.size() >= SENT, "%d dog walkers are sent down her line (%d)" % [SENT, made.size()])
	var past := true
	var earliest := INF
	var latest := -INF
	for age in made:
		past = past and age >= def.telegraph_time
		var point := fposmod(age - def.telegraph_time, def.pulse_period)
		earliest = minf(earliest, point)
		latest = maxf(latest, point)
	t.check(past, "each dog walker is created past its %.1fs telegraph (%s)" % [def.telegraph_time, made])
	t.check(latest - earliest >= def.pulse_period * 0.25,
			"at points of its %.1fs bark spread over it, %.2fs to %.2fs (%s)"
			% [def.pulse_period, earliest, latest, made])

## Every loose dog sent is created at the age a warned row has (`EventSpawner.age_when_warned()`),
## read within the two ticks the manager may have stepped it by when it is first seen.
func _test_the_loose_dog_is_created_at_the_loud_of_its_beat_on_her(t: TestRunner) -> void:
	var made := await _sent("loose_dog", t)
	var def := EventCatalogue.by_id("loose_dog")
	var aged := EventSpawner.age_when_warned(def)
	var tick := FAST_SCALE / Engine.physics_ticks_per_second
	var off: Array[float] = []
	for age in made:
		if absf(age - aged) > 2.0 * tick:
			off.append(age)
	t.check(made.size() >= SENT and off.is_empty(),
			"each of %d loose dogs is created at the loud of its beat on her, %.2fs old (off: %s)"
			% [made.size(), aged, off])

## The ages, as each first appears, of the first `SENT` of `row` the director sends down her line
## while she walks down the arterial's sidewalk on a day forced to owe that row.
func _sent(row: String, t: TestRunner) -> Array[float]:
	_events.force(row, FORCED_INTERVAL)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var consumed: Array[String] = []
	var spec := DaySpec.for_day(Tuning.RUN_TAUGHT_DAY + 2)
	RigStreets.begin(_streets, _map, spec)
	_events.start_day(spec, rng, consumed)
	_events.draw_the_ground_round(Vector2.ZERO, INF)
	_rig.global_position = _on_a_clear_line(CrowdLanes.arterial_pavement(_map))
	_rig.velocity = Vector2.ZERO
	var step := FAST_SCALE / Engine.physics_ticks_per_second
	var before := _events.instances().duplicate()
	var ages: Array[float] = []
	var each := func(_n: int) -> bool:
		_rig.velocity = Vector2.DOWN * Tuning.WALK_SPEED
		_rig.global_position += _rig.velocity * step
		for instance in _events.instances():
			if instance.def.id == row and not before.has(instance):
				before.append(instance)
				ages.append(instance.age())
		return ages.size() >= SENT
	await PhysicsTicks.pass_ticks(t, PhysicsTicks.ticks_for(WALK_FOR, FAST_SCALE), each, FAST_SCALE)
	_events.force("", 0.0)
	return ages

## The nearest point up the street from `start` with walkable ground for 1200px down it and no body
## the day placed within two tiles of that line, so each row sent has its sidewalk; `start` itself
## where none is found within a few blocks.
func _on_a_clear_line(start: Vector2) -> Vector2:
	var bodies: Array[Vector2] = []
	for plan in _events.plans():
		if plan.is_placed() and plan.obstructs():
			bodies.append(plan.position)
	for step in 64:
		var her := start + Vector2.UP * Tuning.TILE_SIZE * step
		var clear := true
		var along := 0.0
		while clear and along <= 1200.0:
			var at := her + Vector2.DOWN * along
			clear = _map.is_walkable(_map.world_to_tile(at))
			for body in bodies:
				clear = clear and body.distance_to(at) > Tuning.TILE_SIZE * 2.0
			along += Tuning.TILE_SIZE * 0.5
		if clear:
			return her
	return start
