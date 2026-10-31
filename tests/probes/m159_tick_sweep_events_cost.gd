extends RefCounted
## What the baby's influence sweep (`Baby._physics_process()`) and the events' physics step
## (`EventManager._physics_process()`) cost per 30/s tick, on fixed seeds and days — a headless
## workload on this machine, not a phone frame.
## Run explicitly: `tools/test.sh probes/m159_tick_sweep_events_cost.gd`; one `TICK_SWEEP_JSON`
## line per run is printed, and the evidence's `analyse.py` reads them.
##
## Every run starts the seed's city on the day the way `main._start_day()` does — the day's
## closures and region plan (`City.start_day()`), the day's events planned and streamed around the
## doorstep (`EventManager.start_day()`), the crowd from a fixed RNG seed with the day's gates — and
## walks a player rig with a real `Baby` down from the doorstep and then along one of two walks
## (`WALKS`): back and forth along the street, or from tick `CHASE_FROM` from event to event.
## One simulated thirtieth of a second is one physics tick (the crowd's, the events' with every live
## event's step inside it, the baby's, in that order) followed by one drawn frame (every agent's
## `_process()`).
## The first `WARMUP` ticks are not timed; the next `WINDOW` are.
##
## **Two modes over the same simulation.** `whole` times the real `EventManager._physics_process()`
## and `Baby._physics_process()` as one span each. `split` makes the events' step's own calls in its
## own order (`_tick_the_events()`), timing each apart, and times the sweep's three queries
## (`EventManager.excitement_sources_at()`, `door_holding_her_at()`, `Crowd.excitement_sources_at()`)
## on their own before the baby's whole step — so the split's `baby` column is the step with the
## queries' caches already warm, and is not comparable with `whole`'s. Both modes chain a SHA-256
## over every event's and every agent's state, her alert and the baby's meters after every tick,
## and the probe fails unless the two chains agree: that is what proves `split` is still the step
## the game runs. The same chain, compared between two revisions, is the check that an optimization
## changed nothing: any event, agent, attribution or meter that differs by one bit on any tick
## changes every digest after it.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0
## The phone frame record's own seed (docs/evidence/m159-phone-frame-record-2026-10-04/) and the
## seed every other crowd probe uses.
const SEEDS: Array[int] = [478156010, 4242]
## Day 1 is the phone record's own day and the densest crowd; day 9 the first walled day; day 14
## the last day, with the most of the catalogue in play.
const DAYS: Array[int] = [1, Tuning.REGION_WALL_FIRST_DAY, 14]
## `street` is the crowd probe's fixed walk; `events` walks from tick `CHASE_FROM` at the nearest
## live event she has not yet reached, and on to the next once she has, so fields that reach her,
## warnings, the mark over her head and her attribution are in the hash. She moves on rather than
## standing in one. Some days still end her crying on that walk, and a crying baby returns from
## the sweep at once, so every row ends with whether she was (`crying`).
const WALKS: Array[String] = ["street", "events"]
const CHASE_FROM := 90
const REPETITIONS := 3
const WARMUP := 150
const WINDOW := 600
## The events' step's calls, in `EventManager._tick_the_events()`'s order.
const EVENT_PARTS: Array[String] = ["retire", "camera", "site", "stream", "owed", "sighted",
		"pelicans", "encounters", "warnings", "tell", "step", "officers", "ground", "door_lines",
		"detentions", "hard_fails"]
## The sweep's queries, then the baby's whole step.
const SWEEP_PARTS: Array[String] = ["event_sources", "door", "crowd_sources", "baby"]

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
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		for day in DAYS:
			for walk in WALKS:
				for repetition in REPETITIONS:
					var chains := {}
					for mode in ["whole", "split"]:
						var report := _run_once(city, rig, city_seed, day, mode, walk)
						report["repetition"] = repetition
						chains[mode] = report.chain
						print("TICK_SWEEP_JSON " + JSON.stringify(report))
					t.check(chains.whole == chains.split,
							("seed %d, day %d, %s walk, repetition %d: the split step changes every "
							+ "event, agent and meter exactly as the real one")
							% [city_seed, day, walk, repetition])
		city.events.clear()
		city.crowd._player = null
		city.free()
	rig.free()

## One day's warmup and window in one mode; returns the run's report.
##
## **A new `Baby` every run**: its own clock (`Baby._clock`) runs on across `reset()`, and the
## sliding windows it prunes against that clock round differently at a different starting time, so
## a baby carried from one run to the next would make a run's chain depend on the runs before it.
func _run_once(city: City, rig: Stroller, city_seed: int, day: int, mode: String,
		walk: String) -> Dictionary:
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	city.start_day(state, day, _rng("closures", city_seed, day))
	var start := city.map.doorstep_world_position()
	var consumed: Array[String] = []
	var events := city.events
	events.start_day(DaySpec.for_day(day), _rng("events", city_seed, day), consumed, start)
	events.stream_around(start)
	var crowd := city.crowd
	crowd.start_day(day, _rng("crowd", city_seed, day), start)
	crowd.set_gates(city.region_plan().gates)
	crowd._player = rig
	events.use_player(rig)
	rig.global_position = start
	rig.velocity = Vector2.ZERO
	rig._alert = Stroller.Alert.NONE
	rig._alert_left = 0.0
	var baby := Baby.new()
	baby.name = "Baby"
	rig.add_child(baby)
	baby.set_physics_process(false)
	# Thirty-two zero bytes rather than an empty array, which `HashingContext.update()` refuses.
	var chain := PackedByteArray()
	chain.resize(32)
	var marks: Array[String] = []
	var rows: Array = []
	var here := start
	var reached_ticks := 0
	var alert_ticks := 0
	var most_live := 0
	var crying_ticks := 0
	var reached := {}
	for tick in WARMUP + WINDOW:
		var going := _street_heading(tick) if walk == "street" or tick < CHASE_FROM \
				else _heading_at_the_next_event(events, here, reached)
		here += going * Tuning.WALK_SPEED * STEP
		rig.global_position = here
		rig.velocity = going * Tuning.WALK_SPEED
		crowd._physics_process(STEP)
		var was_crying := baby.state == GameEnums.BabyState.CRYING
		var row: Array[int] = []
		if mode == "whole":
			var began := Time.get_ticks_usec()
			events._physics_process(STEP)
			var stepped := Time.get_ticks_usec()
			baby._physics_process(STEP)
			var swept := Time.get_ticks_usec()
			row = [stepped - began, swept - stepped]
		else:
			row = _split_events(events, STEP)
			row.append_array(_split_sweep(city, baby, rig.global_position))
		for agent in crowd.agents():
			agent._process(STEP)
		# Wherever the step left her: a door's release sets her down somewhere else.
		here = rig.global_position
		chain = _chain(chain, city, rig, baby)
		if baby.last_incoming > 0.0:
			reached_ticks += 1
		if baby.state == GameEnums.BabyState.CRYING:
			crying_ticks += 1
		if rig._alert != Stroller.Alert.NONE:
			alert_ticks += 1
		most_live = maxi(most_live, events.active_count())
		if tick >= WARMUP:
			# Whether the sweep ran for a crying baby, which it returns from at once: the analysis
			# leaves those ticks out of the sweep's times.
			row.append(int(was_crying))
			rows.append(row)
		if (tick + 1) % 150 == 0:
			marks.append(chain.hex_encode())
	baby.free()
	return {"schema_version": 1, "seed": city_seed, "day": day, "mode": mode, "walk": walk,
		"reached_ticks": reached_ticks, "alert_ticks": alert_ticks, "crying_ticks": crying_ticks,
		"most_live_events": most_live,
		"planned_events": events.planned_count(), "agents": crowd.agent_count(),
		"step_seconds": STEP, "warmup_ticks": WARMUP, "window_ticks": WINDOW,
		"columns": (["events", "influence"] if mode == "whole" else EVENT_PARTS + SWEEP_PARTS) \
				+ ["crying"],
		"rows": rows, "chain": chain.hex_encode(), "chain_every_150_ticks": marks,
		"engine": Engine.get_version_info().string, "os": OS.get_name(),
		"processor": OS.get_processor_name()}

func _rng(stream: String, city_seed: int, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("tick-sweep-events-cost:%s:%d:%d" % [stream, city_seed, day])
	return rng

## `EventManager._tick_the_events()`, call by call in its own order. Returns each call's
## microseconds in `EVENT_PARTS` order; a call the step skips this tick reads 0.
func _split_events(events: EventManager, delta: float) -> Array[int]:
	var stamps: Array[int] = [Time.get_ticks_usec()]
	events.streaming.broadcast_clock += delta
	events.streaming.retire_finished()
	stamps.append(Time.get_ticks_usec())
	var found := events.world.has_player()
	if found:
		events._look_through_the_camera()
	stamps.append(Time.get_ticks_usec())
	if found and not events._recipe_plan:
		events.ahead.site_what_is_on_her_way(delta)
	stamps.append(Time.get_ticks_usec())
	if found:
		events.stream_around(events.world.player.global_position)
	stamps.append(Time.get_ticks_usec())
	if found and not events._recipe_plan:
		events.ahead.place_what_is_owed_ahead(delta)
	stamps.append(Time.get_ticks_usec())
	if found:
		events.spawner.summon_what_has_been_sighted(events.plans())
	stamps.append(Time.get_ticks_usec())
	if found:
		events.spawner.report_the_pelicans_in_view()
	stamps.append(Time.get_ticks_usec())
	if found:
		events._watch_the_encounters(delta)
	stamps.append(Time.get_ticks_usec())
	if found:
		events.warnings.run(delta, events.world.player.global_position)
	stamps.append(Time.get_ticks_usec())
	if found:
		events._tell_them_where_she_is()
	stamps.append(Time.get_ticks_usec())
	events._step_them(delta)
	stamps.append(Time.get_ticks_usec())
	if found:
		events.ahead.let_the_officers_out()
	stamps.append(Time.get_ticks_usec())
	if found:
		events.warnings.warn_about_the_ground_she_is_on()
	stamps.append(Time.get_ticks_usec())
	if found:
		events.checkpoints.watch_the_door_lines()
	stamps.append(Time.get_ticks_usec())
	if found:
		events.checkpoints.check_detentions()
	stamps.append(Time.get_ticks_usec())
	events._check_hard_fails()
	stamps.append(Time.get_ticks_usec())
	var parts: Array[int] = []
	for i in range(1, stamps.size()):
		parts.append(stamps[i] - stamps[i - 1])
	return parts

## The sweep's three queries timed on their own at `her`, then the baby's whole step. Returns
## microseconds in `SWEEP_PARTS` order.
func _split_sweep(city: City, baby: Baby, her: Vector2) -> Array[int]:
	var stamps: Array[int] = [Time.get_ticks_usec()]
	city.events.excitement_sources_at(her)
	stamps.append(Time.get_ticks_usec())
	city.events.door_holding_her_at(her)
	stamps.append(Time.get_ticks_usec())
	city.crowd.excitement_sources_at(her)
	stamps.append(Time.get_ticks_usec())
	baby._physics_process(STEP)
	stamps.append(Time.get_ticks_usec())
	var parts: Array[int] = []
	for i in range(1, stamps.size()):
		parts.append(stamps[i] - stamps[i - 1])
	return parts

## Down from the doorstep for three seconds, then two-second legs east and west along the street.
func _street_heading(tick: int) -> Vector2:
	if tick < 90:
		return Vector2.DOWN
	return Vector2.RIGHT if (tick - 90) / 60 % 2 == 0 else Vector2.LEFT

## Toward the live, unfinished event nearest `here` that she has not reached yet, the first in the
## manager's order on a tie; within half a tile of it, it counts as reached (in `reached`) and she
## turns for the next. Straight on south when there is none.
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

## The running digest: the previous one followed by every live event's id, place, age, phase and
## what it has landed on her; every agent's place, speed and what it has landed; her place and the
## mark over her head; and the baby's meters. Read after the tick and outside every timer.
func _chain(previous: PackedByteArray, city: City, rig: Stroller, baby: Baby) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(previous)
	var state := PackedFloat64Array()
	for instance in city.events.instances():
		context.update(instance.def.id.to_utf8_buffer())
		state.append(instance.global_position.x)
		state.append(instance.global_position.y)
		state.append(instance.age)
		state.append(float(instance.is_finished))
		state.append(float(instance.is_leaving))
		state.append(float(instance.is_telegraphing()))
		state.append(instance.landed())
	state.append(float(city.events.pending_warnings().size()))
	state.append(float(city.events.active_count()))
	for agent in city.crowd.agents():
		state.append(agent.global_position.x)
		state.append(agent.global_position.y)
		state.append(agent.speed())
		state.append(agent.landed())
	state.append(rig.global_position.x)
	state.append(rig.global_position.y)
	state.append(float(rig._alert))
	state.append(rig._alert_left)
	state.append(baby.excitement)
	state.append(baby.sleepiness)
	state.append(float(baby.state))
	state.append(baby.last_incoming)
	state.append(baby.last_decay)
	state.append(baby.self_landed())
	state.append(baby.decay_in_window())
	context.update(state.to_byte_array())
	return context.finish()
