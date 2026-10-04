extends RefCounted
## What the crowd's physics tick (`Crowd._physics_process()`) costs, split by the call that pays it,
## on fixed seeds — a headless workload on this machine, not a phone frame.
## Run explicitly: `tools/test.sh probes/m159_crowd_tick_cost.gd`; one `CROWD_TICK_JSON` line per
## run is printed, and the evidence's `analyse.py` reads them.
##
## Every run starts the seed's city on the day (`City.start_day()`: the day's closures and region
## plan), starts the day's crowd from a fixed RNG seed with the day's gates, and walks a player
## rig down from the doorstep and back and forth along the street (`_player_heading()`), one agent frame
## (`CrowdAgent._process()`) and one crowd tick per simulated thirtieth of a second. The first
## `WARMUP` ticks are not timed; the next `WINDOW` are.
##
## **Two modes over the same simulation.** `whole` calls the real `Crowd._physics_process()` and
## times it as one span. `split` makes the same calls the tick makes, in the same order, timing each
## one apart. Both modes chain a SHA-256 over every agent's position and speed after every tick,
## and the probe fails unless the two chains agree: that is what proves `split` is still the tick
## the game runs rather than a copy that has drifted from it. The same chain, compared between two
## revisions, is the check that an optimization moved nobody: any agent whose position differs by
## one bit on any tick changes every digest after it.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0
## The phone frame record's own seed (docs/evidence/m159-phone-frame-record-2026-10-04/) and the
## seed every other crowd probe uses.
const SEEDS: Array[int] = [478156010, 4242]
## Day 1 is the densest crowd and the phone record's own day; day 9 is the first with the region
## wall, so its walkers have checkpoint huts to queue at and its cars a gate to stop for.
const DAYS: Array[int] = [1, Tuning.REGION_WALL_FIRST_DAY]
const REPETITIONS := 3
const WARMUP := 150
const WINDOW := 600
## The split's columns, in the order the tick runs them: the agents' own frame first (the per-frame
## work, timed for scale and not part of the tick), then `_advance_the_world()`'s calls and
## `space_out_the_traffic()`'s inside it, then the player half.
const PARTS: Array[String] = ["agents", "signals", "pockets", "resolve", "keep_room", "index",
		"claims", "give_way", "gates", "doors", "player"]

func run(t) -> void:
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
			for repetition in REPETITIONS:
				var chains := {}
				for mode in ["whole", "split"]:
					var report := _run_once(city, rig, city_seed, day, mode)
					report["repetition"] = repetition
					chains[mode] = report.chain
					print("CROWD_TICK_JSON " + JSON.stringify(report))
				t.check(chains.whole == chains.split,
						("seed %d, day %d, repetition %d: the split tick moves every agent exactly as "
						+ "the real one") % [city_seed, day, repetition])
		city.crowd._player = null
		city.free()
	rig.free()

## One day's warmup and window in one mode; returns the run's report.
func _run_once(city: City, rig: Stroller, city_seed: int, day: int, mode: String) -> Dictionary:
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
	# Thirty-two zero bytes rather than an empty array, which `HashingContext.update()` refuses.
	var chain := PackedByteArray()
	chain.resize(32)
	var marks: Array[String] = []
	var rows: Array = []
	var here := start
	for tick in WARMUP + WINDOW:
		var going := _player_heading(tick)
		rig.global_position = here
		rig.velocity = going * Tuning.WALK_SPEED
		here += going * Tuning.WALK_SPEED * STEP
		var row: Array[int] = []
		if mode == "whole":
			var began := Time.get_ticks_usec()
			for agent in crowd.agents():
				agent._process(STEP)
			var moved := Time.get_ticks_usec()
			crowd._physics_process(STEP)
			var ended := Time.get_ticks_usec()
			row = [moved - began, ended - moved]
		else:
			row = _split_tick(crowd)
		chain = _chain(chain, crowd)
		if tick >= WARMUP:
			rows.append(row)
		if (tick + 1) % 150 == 0:
			marks.append(chain.hex_encode())
	return {"schema_version": 1, "seed": city_seed, "day": day, "mode": mode,
		"agents": crowd.agent_count(), "huts": crowd._door_holds.size(), "gates": crowd._gates.size(), "step_seconds": STEP, "warmup_ticks": WARMUP,
		"window_ticks": WINDOW, "columns": ["agents", "tick"] if mode == "whole" else PARTS,
		"rows": rows, "chain": chain.hex_encode(), "chain_every_150_ticks": marks,
		"engine": Engine.get_version_info().string, "os": OS.get_name(),
		"processor": OS.get_processor_name()}

## The tick, call by call, in `Crowd._tick_the_crowd()`'s own order: `_advance_the_world()` (with
## `space_out_the_traffic()` opened up inside it) and then `_meet_the_player()`. Returns each call's
## microseconds in `PARTS` order.
func _split_tick(crowd: Crowd) -> Array[int]:
	var stamps: Array[int] = [Time.get_ticks_usec()]
	for agent in crowd.agents():
		agent._process(STEP)
	stamps.append(Time.get_ticks_usec())
	if crowd._signals:
		crowd._signals.advance(STEP)
	stamps.append(Time.get_ticks_usec())
	crowd._pockets.refresh(crowd._map, crowd._crossable_segments)
	stamps.append(Time.get_ticks_usec())
	var lanes := crowd._resolve_the_queues()
	stamps.append(Time.get_ticks_usec())
	crowd._keep_room_for_the_turning(lanes)
	stamps.append(Time.get_ticks_usec())
	crowd._index_the_queues(lanes)
	stamps.append(Time.get_ticks_usec())
	for agent in crowd.agents():
		if agent.is_turning():
			crowd._traffic.claim(agent.turn_lane_key(), agent.turn_landing())
	stamps.append(Time.get_ticks_usec())
	crowd.give_way_at_junctions()
	stamps.append(Time.get_ticks_usec())
	crowd._stop_for_gates(STEP)
	stamps.append(Time.get_ticks_usec())
	crowd._hold_walkers_at_doors(STEP)
	stamps.append(Time.get_ticks_usec())
	crowd._meet_the_player()
	stamps.append(Time.get_ticks_usec())
	var parts: Array[int] = []
	for i in range(1, stamps.size()):
		parts.append(stamps[i] - stamps[i - 1])
	return parts

## Down from the doorstep for three seconds, then two-second legs east and west along the street.
func _player_heading(tick: int) -> Vector2:
	if tick < 90:
		return Vector2.DOWN
	return Vector2.RIGHT if (tick - 90) / 60 % 2 == 0 else Vector2.LEFT

## The running digest: the previous one followed by every agent's position and speed, in the
## crowd's own order. Read after the tick and outside every timer.
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
