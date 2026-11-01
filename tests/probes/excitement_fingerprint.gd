extends RefCounted
## **What every source charges her, tick by tick, printed one line per source**, so a change to how
## excitement is computed can be shown to compute exactly what it computed before. Not a suite: it
## prints rather than asserts. Run by name, before and after a change, and compare the two outputs:
##
##     tools/test.sh probes/excitement_fingerprint.gd > before.txt
##     grep '^XF' before.txt | grep -v '^XF_COST' > before.xf     (the same for after; `diff` them)
##
## `XF_COST` is the one line that is not the fingerprint: the microseconds `ExcitementHalo`'s frame
## took over the walk, the cues' share of a frame, for comparing two revisions' cost.
##
## A walk is a player rig with a real `Baby` and a real `ExcitementHalo`, walked down from where the
## walk starts and then at the nearest live event she has not reached yet, through walls and all.
## One tick is the crowd's physics tick (every agent's step inside it), the events' (every live
## event's step inside it), the baby's, then one drawn frame: every event's own `_process()` and the
## halo's.
## After it, every source with anything to say prints its contribution at her, its projected gross
## and net, whether its course is lethal, what it has landed in the window, its caret's strength and
## whether it holds a rim, each value as the hex of its 64-bit float so a difference in the last bit
## shows. Walks:
##
## - **days** 1, 9 and 14 of two seeds, each with its crowd and its events;
## - **the escape's city** on day 14, with its own plan and nobody on the street;
## - **the building** on two seeds, its events and no crowd.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const BuildingEvents := preload("res://tests/building_events.gd")

const STEP := 1.0 / 30.0
const TICKS := 420
## The building's sources stand further apart than the street's, so its walk is longer.
const BUILDING_TICKS := 1800
const CHASE_FROM := 30
const DAY_SEEDS: Array[int] = [4242, 478156010]
const DAYS: Array[int] = [1, Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS]
const ESCAPE_SEEDS: Array[int] = [4242]
const BUILDING_SEEDS: Array[int] = [4242, 77]

func run(t) -> void:
	var lines := 0
	for seed_value in DAY_SEEDS:
		for day in DAYS:
			lines += _a_day(t, seed_value, day)
	for seed_value in ESCAPE_SEEDS:
		lines += _the_escape_city(t, seed_value)
	for seed_value in BUILDING_SEEDS:
		lines += _the_building(t, seed_value)
	print("XF_TOTAL %d lines" % lines)
	t.check(lines > 0, "there were sources to print (%d)" % lines)

## A day, as `DayDirector.start_day()` starts it: the city's own morning, the events and the crowd.
func _a_day(t, seed_value: int, day: int) -> int:
	GameState.start_run(seed_value)
	GameState.header.day = day
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.crowd_view = ScreenCrowdView.new(t)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"),
			spec)
	var start := city.map.doorstep_world_position()
	var consumed: Array[String] = []
	city.events.start_day(spec, GameState.calendar.day_rng(day), consumed, start)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("excitement-fingerprint-crowd:%d:%d" % [seed_value, day])
	city.crowd.start_day(day, rng, start)
	city.crowd.set_gates(city.region_plan().gates)
	var printed := _walk(t, "day seed %d day %d" % [seed_value, day], city, city.events,
			city.crowd, start)
	city.events.clear()
	city.free()
	return printed

## The escape's city, built and planned as `main._plan_the_finale_city()` does, with nobody on it.
func _the_escape_city(t, seed_value: int) -> int:
	var day := Tuning.RUN_LENGTH_DAYS
	GameState.start_run(seed_value)
	GameState.header.day = day
	var spec := DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.crowd_view = ScreenCrowdView.new(t)
	city.build(CityGenerator.generate(seed_value))
	GameState.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"),
			spec)
	var start := FinalePlanner.service_exit_world_position(city.map)
	var none: Array[String] = []
	city.events.start_day(spec, GameState.calendar.day_rng(day, "finale"), none, start)
	var printed := _walk(t, "escape seed %d" % seed_value, city, city.events, city.crowd, start)
	city.events.clear()
	city.free()
	return printed

## The building, with its events started as every entry into the section starts them.
func _the_building(t, seed_value: int) -> int:
	GameState.start_run(seed_value)
	GameState.header.day = Tuning.RUN_LENGTH_DAYS
	var scene := InteriorScene.new()
	t.add_child(scene)
	var rng := GameState.calendar.day_rng(GameState.header.day, "finale-interior")
	var events := BuildingEvents.events_in(t, scene, rng)
	var printed := _walk(t, "building seed %d" % seed_value, scene, events, null,
			scene.map.start_world_position(), BUILDING_TICKS)
	events.clear()
	events.free()
	scene.free()
	return printed

## One walk of `ticks` ticks in `world`, printing every source's line after every tick.
func _walk(t, walk: String, world: WorldContext, events: EventManager, crowd: Crowd,
		start: Vector2, ticks := TICKS) -> int:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.set_process(false)
	rig.global_position = start
	var baby := Baby.new()
	baby.name = "Baby"
	rig.add_child(baby)
	baby.set_physics_process(false)
	baby.set_world(world)
	var halo := ExcitementHalo.new()
	t.add_child(halo)
	halo.set_process(false)
	halo.setup(world.excitement_sources, rig, baby)
	events.use_player(rig)
	events.stream_around(start)
	if crowd:
		crowd._player = rig
	var here := start
	var reached := {}
	var printed := 0
	var cues_usec := 0
	print("XF_WALK %s" % walk)
	for tick in ticks:
		var going := Vector2.DOWN if tick < CHASE_FROM \
				else _heading_at_the_next_event(events, here, reached)
		here += going * Tuning.WALK_SPEED * STEP
		rig.global_position = here
		rig.velocity = going * Tuning.WALK_SPEED
		if crowd:
			crowd._physics_process(STEP)
		events._physics_process(STEP)
		baby._physics_process(STEP)
		for instance in events.instances():
			instance._process(STEP)
		var began := Time.get_ticks_usec()
		halo._process(STEP)
		cues_usec += Time.get_ticks_usec() - began
		here = rig.global_position
		printed += _print_the_sources(walk, tick, events, crowd, here)
		print("XF_BABY %s | %d | %s" % [walk, tick, _hex([baby.excitement, baby.last_incoming,
				baby.decay_in_window()])])
		if tick % 60 == 0:
			print("XF_WHERE %s | %d | at %s | %d live" % [walk, tick, here, events.active_count()])
	print("XF_COST %s | cues %d usec over %d ticks" % [walk, cues_usec, ticks])
	events.use_player(null)
	if crowd:
		crowd._player = null
	halo.free()
	rig.free()
	return printed

## Every source with anything to say at `her`: the events first, in the manager's order, then the
## crowd in its own.
func _print_the_sources(walk: String, tick: int, events: EventManager, crowd: Crowd,
		her: Vector2) -> int:
	var printed := 0
	var instances := events.instances()
	for i in instances.size():
		var instance := instances[i]
		var source := instance.excitement
		var caret := source.caret_strength() if instance.look else -1
		printed += _print_one(walk, tick, "E%d:%s" % [i, instance.logged_name()], [
				source.contribution_at(her), source.expected_gross_at(her),
				source.expected_impact_at(her), source.landed()],
				source.will_be_lethal(her), caret, (source.rim as SourceRim).is_held())
	if crowd:
		var agents := crowd.agents()
		for i in agents.size():
			var agent := agents[i]
			var source := agent.excitement
			printed += _print_one(walk, tick, "A%d:%d" % [i, agent.kind], [
					source.contribution_at(her), source.expected_gross_at(her),
					source.expected_impact_at(her), source.landed()],
					source.will_be_lethal(her), source.caret_strength(),
					(source.rim as SourceRim).is_held())
	return printed

func _print_one(walk: String, tick: int, label: String, values: Array, lethal: bool, caret: int,
		rim: bool) -> int:
	var silent := not lethal and caret <= 0 and not rim
	for value: float in values:
		silent = silent and value == 0.0
	if silent:
		return 0
	print("XF %s | %d | %s | %s | lethal %s | caret %d | rim %s"
			% [walk, tick, label, _hex(values), lethal, caret, rim])
	return 1

## Each value as the hex of its 64-bit float, so two runs agree only when every bit does.
static func _hex(values: Array) -> String:
	var parts: Array[String] = []
	for value: float in values:
		parts.append(PackedFloat64Array([value]).to_byte_array().hex_encode())
	return " ".join(parts)

## Toward the live, unfinished event nearest `here` that she has not reached yet, the first in the
## manager's order on a tie; within half a tile of it, it counts as reached and she turns for the
## next. Straight on south when there is none.
func _heading_at_the_next_event(events: EventManager, here: Vector2, reached: Dictionary) -> Vector2:
	var best := INF
	var target: EventInstance = null
	for instance in events.instances():
		if instance.is_finished or reached.has(instance):
			continue
		var distance := instance.global_position.distance_squared_to(here)
		if distance < best:
			best = distance
			target = instance
	if target == null:
		return Vector2.DOWN
	if best < pow(Tuning.TILE_SIZE * 0.5, 2.0):
		reached[target] = true
		return _heading_at_the_next_event(events, here, reached)
	return (target.global_position - here).normalized()
