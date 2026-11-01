extends RefCounted
## What the crowd's own numbers come to when its motion is stepped at a frame rate other than the
## 30Hz physics tick: the car headways, the junction boxes' throughput, the horns, the box
## collisions, the bumps and the strikes, over a minute of the live day's order on fixed seeds.
##
## Run explicitly in each revision's checkout: `tools/test.sh probes/minty_quail_crowd_cadence.gd`,
## one `CROWD_CADENCE_JSON` line per run. `CADENCE_FRAMES` (default `1,2,4`) lists how many drawn
## frames each tick is emulated with: before minty-quail shared-components C1 every agent moved in
## its own `_process()`, once a drawn frame, after the crowd's physics tick, so a tick at 120fps was
## the tick and then four agent frames of a quarter tick each; from C1 the crowd steps its agents
## inside its own tick (`Crowd._step_the_agents()`) and the frame count reaches nothing, so a
## revision with C1 runs each tick once whatever the count says. Called by name so the one file
## runs on either revision.
##
## `CADENCE_SEEDS` (comma-separated, default `SEEDS`) names more cities to run, to tell a difference
## from noise.
##
## `CADENCE_EVENTS` set runs the day's own events beside the crowd: each run also starts the day's
## events (`EventManager.start_day()`, no director) handed the rig, and runs the event manager's whole
## tick (`EventManager._tick_the_events()`) before the crowd's, the order `City` adds the two in, so
## the day's figures stream in round her and walk through the crowd; the line then also carries the
## figures' counts (`minty_quail_crowd_yields.gd`'s `Meeting`: overlaps of a walker or a crowd car
## with an event figure, the seconds cars stand for one, the longest stand in a junction box).
##
## **The `walkers` walk heads for the nearest walker, so where she goes depends on where the crowd
## is**, and with the day's events live, what streams in round her (`EventStreaming.stream_around()`,
## handed her position each tick) follows her. A revision that moves the crowd therefore moves her
## and, through her, the events, which is no event reading the crowd. `CADENCE_RIG_RECORD` (a
## directory) writes each run's walk, her position and velocity every tick, to
## `<seed>-<day>-<walk>-<frames>.var`; `CADENCE_RIG_REPLAY` (a directory) walks her along a recorded file
## instead, so two revisions' events can be compared with her on the same walk.
##
## Each run starts the seed's city on the day as `m159_crowd_tick_cost.gd` does, and walks a player
## rig one of two ways (`WALKS`): `road`, back and forth across the carriageway nearest the doorstep,
## two kerbs apart, which is what the horns, the give-way and the strike answer; and `walkers`, at
## the nearest walker, which is what the bumps answer. The first `WARMUP` ticks are not counted.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const YIELDS := preload("res://tests/probes/minty_quail_crowd_yields.gd")
const STEP := 1.0 / 30.0
const SEEDS: Array[int] = [478156010, 4242]
const DAYS: Array[int] = [1, Tuning.REGION_WALL_FIRST_DAY]
const WALKS: Array[String] = ["road", "walkers"]
const WARMUP := 150
const WINDOW := 1800

var _horns := 0
var _bumps := 0
var _strikes := 0

func run(t) -> void:
	var frames: Array[int] = []
	for word in (OS.get_environment("CADENCE_FRAMES") if OS.has_environment("CADENCE_FRAMES")
			else "1,2,4").split(","):
		frames.append(int(word))
	var seeds := SEEDS
	if OS.has_environment("CADENCE_SEEDS"):
		seeds = []
		for word in OS.get_environment("CADENCE_SEEDS").split(","):
			seeds.append(int(word))
	EventBus.car_near_miss.connect(func(_at: Vector2) -> void: _horns += 1)
	EventBus.crowd_bumped.connect(func(_at: Vector2) -> void: _bumps += 1)
	EventBus.hard_fail_triggered.connect(func(cause: String) -> void:
		if cause == "car_strike":
			_strikes += 1)
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.set_process(false)
	for city_seed in seeds:
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.crowd_view = ScreenCrowdView.new(t)
		city.build(CityGenerator.generate(city_seed))
		for day in DAYS:
			for walk in WALKS:
				for per_tick in frames:
					print("CROWD_CADENCE_JSON " + JSON.stringify(
							_run_once(city, rig, city_seed, day, walk, per_tick)))
		city.crowd._player = null
		city.free()
	rig.free()
	t.check(true, "ran")

func _run_once(city: City, rig: Stroller, city_seed: int, day: int, walk: String,
		per_tick: int) -> Dictionary:
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
	var with_events := OS.get_environment("CADENCE_EVENTS") != ""
	var meeting = null
	if with_events:
		var events_rng := RandomNumberGenerator.new()
		events_rng.seed = hash("crowd-cadence-events:%d:%d" % [city_seed, day])
		city.events.start_day(DaySpec.for_day(day), events_rng, [], start)
		city.events.use_player(rig)
		meeting = YIELDS.Meeting.new(null, city, {"seed": city_seed, "day": day, "walk": walk})
	var steps_its_agents := crowd.has_method("_step_the_agents")
	var across := _crossing(city.map, start)
	var here: Vector2 = across[0] if walk == "road" else start
	var walk_file := "%d-%d-%s-%d.var" % [city_seed, day, walk, per_tick]
	var recorded := PackedVector2Array()
	var replayed := PackedVector2Array()
	if OS.has_environment("CADENCE_RIG_REPLAY"):
		var file := FileAccess.open(OS.get_environment("CADENCE_RIG_REPLAY").path_join(walk_file),
				FileAccess.READ)
		replayed = file.get_var()
	var startled := {}
	var boxed := {}
	var gaps: Array[float] = []
	var speeds := 0.0
	var speed_samples := 0
	var car_startles := 0
	var box_entries := 0
	_horns = 0
	_bumps = 0
	_strikes = 0
	var horns_at_warmup := 0
	var bumps_at_warmup := 0
	var strikes_at_warmup := 0
	for tick in WARMUP + WINDOW:
		var going := _road_heading(tick, across) if walk == "road" \
				else _heading_at_the_nearest_walker(crowd, here)
		rig.global_position = here
		rig.velocity = going * Tuning.WALK_SPEED
		here += going * Tuning.WALK_SPEED * STEP
		if not replayed.is_empty():
			rig.global_position = replayed[tick * 2]
			rig.velocity = replayed[tick * 2 + 1]
		recorded.append(rig.global_position)
		recorded.append(rig.velocity)
		if with_events:
			city.events._tick_the_events(STEP)
		crowd._physics_process(STEP)
		if with_events and tick >= WARMUP:
			meeting.observe([], [])
		if not steps_its_agents:
			for _frame in per_tick:
				for agent in crowd.agents():
					agent.call("_process", STEP / float(per_tick))
		if tick == WARMUP - 1:
			horns_at_warmup = _horns
			bumps_at_warmup = _bumps
			strikes_at_warmup = _strikes
		for agent in crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var now_startled := agent.excitement.is_startled()
			var box := agent.junction_occupied()
			var in_box := box != Vector2i(-1, -1)
			if tick >= WARMUP:
				if now_startled and not startled.get(agent, false):
					car_startles += 1
				if in_box and boxed.get(agent, Vector2i(-1, -1)) != box:
					box_entries += 1
				if agent.speed() > 1.0 and is_finite(agent.gap_ahead):
					gaps.append(agent.gap_ahead)
				speeds += agent.speed()
				speed_samples += 1
			startled[agent] = now_startled
			boxed[agent] = box if in_box else Vector2i(-1, -1)
	gaps.sort()
	var horns := _horns - horns_at_warmup
	var minutes := WINDOW * STEP / 60.0
	if OS.has_environment("CADENCE_RIG_RECORD"):
		var file := FileAccess.open(OS.get_environment("CADENCE_RIG_RECORD").path_join(walk_file),
				FileAccess.WRITE)
		file.store_var(recorded)
	var figures := {}
	if with_events:
		figures = meeting.report()
		city.events.use_player(null)
		# The next run on this city starts with none of this run's events on the map's list.
		city.events.clear()
	return figures.merged({"seed": city_seed, "day": day, "walk": walk, "frames_per_tick": per_tick,
		"steps_on_the_tick": steps_its_agents, "agents": crowd.agent_count(),
		"window_seconds": WINDOW * STEP,
		"headway_p10": _quantile(gaps, 0.1), "headway_median": _quantile(gaps, 0.5),
		"headway_min": gaps[0] if not gaps.is_empty() else INF,
		"box_entries_per_minute": box_entries / minutes,
		"mean_car_speed": speeds / maxf(1.0, float(speed_samples)),
		"horns": horns, "box_collisions": car_startles - horns,
		"bumps": _bumps - bumps_at_warmup, "strikes": _strikes - strikes_at_warmup}, true)

func _quantile(sorted: Array[float], q: float) -> float:
	if sorted.is_empty():
		return INF
	return sorted[clampi(int(q * sorted.size()), 0, sorted.size() - 1)]

## The two kerbs of the carriageway nearest `from`, out of any junction: the middle of the first and
## of the last carriageway tile across the street, as `[one, other]`.
func _crossing(map: CityMap, from: Vector2) -> Array[Vector2]:
	var origin := map.world_to_tile(from)
	for radius in 12:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var tile := origin + Vector2i(dx, dy)
				if not map.in_bounds(tile) or not map.is_carriageway(tile):
					continue
				var offsets := map.corridor_offsets(tile)
				if offsets.x >= 0 and offsets.y >= 0:
					continue
				var step := Vector2i(1, 0) if offsets.x >= 0 else Vector2i(0, 1)
				var low := tile
				while map.is_carriageway(low - step):
					low -= step
				var high := tile
				while map.is_carriageway(high + step):
					high += step
				return [map.tile_to_world(low), map.tile_to_world(high)]
	return [from, from]

## Two seconds across from the first kerb, then two back, and so on; still on the kerb in between,
## for as long as the leg is short.
func _road_heading(tick: int, across: Array[Vector2]) -> Vector2:
	var leg := (tick / 60) % 2
	var line := across[1] - across[0]
	if line.length() < 1.0:
		return Vector2.ZERO
	var direction := line.normalized() * (1.0 if leg == 0 else -1.0)
	var into := float(tick % 60) * Tuning.WALK_SPEED * STEP
	return direction if into <= line.length() else Vector2.ZERO

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
