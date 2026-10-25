extends RefCounted
## Uncommitted parity probe for the lane-mover refactor: the m159 crowd probe's own walk, seeds,
## days and chain (every agent's position and speed after every tick), plus a second chain over
## what the drawing reads (the redraw key, the drawn-heading key, visibility, lane key, velocity,
## heading), and the per-tick time of the agents' own frames and of the crowd tick.
## Reads only names that exist before and after the refactor.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0
const SEEDS: Array[int] = [478156010, 4242]
const DAYS: Array[int] = [1, Tuning.REGION_WALL_FIRST_DAY, 14]
const WALKS: Array[String] = ["street", "walkers"]
const CHASE_FROM := 90
const WARMUP := 150
const WINDOW := 600

func run(t) -> void:
	var reps := int(OS.get_environment("LANE_PARITY_REPS")) if OS.has_environment("LANE_PARITY_REPS") else 1
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.set_process(false)
	for city_seed in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		for day in DAYS:
			for walk in WALKS:
				for repetition in reps:
					var report := _run_once(city, rig, city_seed, day, walk)
					report["repetition"] = repetition
					print("LANE_PARITY_JSON " + JSON.stringify(report))
		city.crowd._player = null
		city.free()
	rig.free()
	t.check(true, "ran")

func _run_once(city: City, rig: Stroller, city_seed: int, day: int, walk: String) -> Dictionary:
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var closures := RandomNumberGenerator.new()
	closures.seed = hash("crowd-tick-cost-closures:%d:%d" % [city_seed, day])
	city.start_day(state, day, closures)
	var crowd := city.crowd
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-tick-cost:%d:%d" % [city_seed, day])
	var start := city.map.doorstep_world_position()
	crowd.start_day(day, rng, start)
	crowd.set_gates(city.region_plan().gates)
	crowd._player = rig
	var chain := PackedByteArray()
	chain.resize(32)
	var drawn := PackedByteArray()
	drawn.resize(32)
	var agents_us: Array[int] = []
	var tick_us: Array[int] = []
	var here := start
	for tick in WARMUP + WINDOW:
		var going := _player_heading(tick) if walk == "street" or tick < CHASE_FROM \
				else _heading_at_the_nearest_walker(crowd, here)
		rig.global_position = here
		rig.velocity = going * Tuning.WALK_SPEED
		here += going * Tuning.WALK_SPEED * STEP
		var began := Time.get_ticks_usec()
		for agent in crowd.agents():
			agent._process(STEP)
		var moved := Time.get_ticks_usec()
		crowd._physics_process(STEP)
		var ended := Time.get_ticks_usec()
		if tick >= WARMUP:
			agents_us.append(moved - began)
			tick_us.append(ended - moved)
		chain = _chain(chain, crowd)
		drawn = _drawn(drawn, crowd)
	agents_us.sort()
	tick_us.sort()
	return {"seed": city_seed, "day": day, "walk": walk, "agents": crowd.agent_count(),
		"chain": chain.hex_encode(), "drawn": drawn.hex_encode(),
		"agents_median_us": agents_us[agents_us.size() / 2],
		"tick_median_us": tick_us[tick_us.size() / 2]}

func _player_heading(tick: int) -> Vector2:
	if tick < 90:
		return Vector2.DOWN
	return Vector2.RIGHT if (tick - 90) / 60 % 2 == 0 else Vector2.LEFT

func _heading_at_the_nearest_walker(crowd: Crowd, here: Vector2) -> Vector2:
	var best := INF
	var target := here
	for agent in crowd.agents():
		if agent.kind != CrowdAgent.Kind.WALKER:
			continue
		var distance := agent.global_position.distance_squared_to(here)
		if distance < best:
			best = distance
			target = agent.global_position
	if best < 4.0:
		return Vector2.ZERO
	return (target - here).normalized()

func _chain(previous: PackedByteArray, crowd: Crowd) -> PackedByteArray:
	var state := PackedFloat32Array()
	for agent in crowd.agents():
		state.append(agent.global_position.x)
		state.append(agent.global_position.y)
		state.append(agent.speed())
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(previous)
	context.update(state.to_byte_array())
	return context.finish()

func _drawn(previous: PackedByteArray, crowd: Crowd) -> PackedByteArray:
	var state := PackedFloat32Array()
	for agent in crowd.agents():
		var picture: Vector3i = agent.get("_picture")
		var heading_key: Vector2i = agent.get("_drawn_heading")
		var velocity := agent.velocity()
		var heading := agent.heading()
		state.append_array([picture.x, picture.y, picture.z, heading_key.x, heading_key.y,
				1.0 if agent.visible else 0.0, float(agent.lane_key()), velocity.x, velocity.y,
				heading.x, heading.y, agent.colour.r, agent.colour.g, agent.colour.b])
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(previous)
	context.update(state.to_byte_array())
	return context.finish()
