extends RefCounted
## Measurement probe for "the main road is never closed" (inbox #1186): what the region plan and the
## rest of an ordinary day stand on the main road's carriageway, and whether its traffic drives the
## crossings of a region boundary. Not a suite — it prints numbers rather than asserting
## relationships — so it lives under `tests/probes/`, where the runner never discovers it, and runs
## only by name:
##
##     tools/test.sh probes/main_road_open.gd
##
## On the seeds the region-plan suites use (`tests/test_regions.gd` and `tests/test_checkpoints.gd`)
## and every day from `Tuning.REGION_WALL_FIRST_DAY` on, three readings:
##
## - **`PLAN`**, the region plan alone (`RegionPlanner.plan_day()` with the day's own spec): how many
##   boundary segments are main road, how many of those are wall and how many door, how many of the
##   door gates hold a car, and how many main-road carriageway tiles a wall body covers.
## - **`DAY`**, the whole morning as `DayDirector.start_day()` plans it (the city's streets, then the
##   events): every main-road segment held to the traffic that is not a door, every one closed, and
##   every planned body whose footprint (`EventSpawner.obstructed_footprint()`) covers main-road
##   carriageway, by row, with when it comes. That is the survey of what else can close the road.
## - **`CROWD`**, one day a seed with a main-road boundary crossing: the day's traffic run for
##   `SECONDS` round the crossing, counting the cars that drive through it and the car-frames a gate
##   on the main road holds a car for.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RUN_SEED := 2
const STEP := 1.0 / 60.0
const SECONDS := 30.0

## `tests/test_regions.gd`'s six maps and `tests/test_checkpoints.gd`'s four.
static func _seeds() -> Array[int]:
	var found: Array[int] = []
	for i in 6:
		found.append(260917 + i * 137)
	for i in 4:
		found.append(771103 + i * 251)
	return found

func run(t) -> void:
	var totals := {"boundary": 0, "walls": 0, "doors": 0, "holding": 0, "wall_tiles": 0,
			"held": 0, "closed": 0, "bodies": 0}
	var rows := {}
	for seed_value in _seeds():
		var crowd_day := -1
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			var crossings := _plan(seed_value, day, totals)
			_day(t, seed_value, day, totals, rows)
			if crowd_day < 0 and crossings > 0:
				crowd_day = day
		if crowd_day >= 0:
			_crowd(t, seed_value, crowd_day)
	print("TOTAL main-road boundary segments %d | wall %d | door %d | gates holding cars %d"
			% [totals.boundary, totals.walls, totals.doors, totals.holding]
			+ " | wall-body carriageway tiles %d" % totals.wall_tiles)
	print("TOTAL day: main-road segments held (not a door) %d | closed %d | bodies on the carriageway %d"
			% [totals.held, totals.closed, totals.bodies])
	for id: String in rows:
		print("TOTAL row on the main-road carriageway: %s x%d" % [id, rows[id]])
	t.check(true, "probe finished")

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

## Whether `segment` runs along the main road.
static func _on_the_main_road(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	return map.is_main_road(not segment.horizontal, segment.a.x)

## Whether `tile` is main-road carriageway: in the spine's own column and road or crossing paint.
static func _main_road_carriageway(map: CityMap, tile: Vector2i) -> bool:
	if map.main_road < 0:
		return false
	var left := map.main_road * CityMap.period()
	if tile.x < left or tile.x >= left + Tuning.STREET_WIDTH:
		return false
	return map.is_carriageway(tile) or map.is_crossing(tile)

func _footprint_on_the_road(map: CityMap, body: EventScheduler.Planned) -> int:
	var count := 0
	for tile in EventSpawner.obstructed_footprint(map, body.def, body.position, body.facing):
		if _main_road_carriageway(map, tile):
			count += 1
	return count

## The region plan alone. Returns how many main-road boundary segments it has.
func _plan(seed_value: int, day: int, totals: Dictionary) -> int:
	var map := CityGenerator.generate(seed_value)
	_repaint_for(map, day)
	var tree := RouteTree.for_day(map, day)
	var plan := RegionPlanner.plan_day(map, day, tree)
	var boundary := 0
	for segment in RegionPlanner.boundary_segments(map):
		if _on_the_main_road(map, segment):
			boundary += 1
	var walls := 0
	for segment in plan.walls:
		if _on_the_main_road(map, segment):
			walls += 1
	var doors := 0
	var holding := 0
	for i in plan.doors.size():
		if _on_the_main_road(map, plan.doors[i]):
			doors += 1
			if _holds_cars(plan.gates[i]):
				holding += 1
	var wall_tiles := 0
	for body in plan.wall_bodies:
		wall_tiles += _footprint_on_the_road(map, body)
	totals.boundary += boundary
	totals.walls += walls
	totals.doors += doors
	totals.holding += holding
	totals.wall_tiles += wall_tiles
	print("PLAN seed %d day %d | main-road boundary %d | wall %d | door %d | holding %d | wall tiles %d"
			% [seed_value, day, boundary, walls, doors, holding, wall_tiles])
	return boundary

## Whether a gate stops the cars. Every gate does where the gate cannot say otherwise.
static func _holds_cars(gate: RegionPlanner.GateState) -> bool:
	return not gate.has_method("holds_cars") or gate.call("holds_cars")

## A real day's morning, as `DayDirector.start_day()` plans it.
func _day(t, seed_value: int, day: int, totals: Dictionary, rows: Dictionary) -> void:
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	city.run.header.day = day
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var map := city.map
	city.run.attempt_spend.city_state.begin_day(map.block_plans, day)
	city.start_day(city.run.attempt_spend.city_state, day,
			city.run.calendar.day_rng(day, "closures"), spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, city.run.calendar.day_rng(day), consumed,
			map.doorstep_world_position())
	var doors := {}
	for segment in city.streets().region_plan().doors:
		doors[segment.key()] = true
	var held := 0
	var closed := 0
	var blocked := map.blocked_segments()
	for segment in map.network.segments():
		if not _on_the_main_road(map, segment):
			continue
		if map.is_held(segment) and not doors.has(segment.key()):
			held += 1
		if blocked.has(segment.key()):
			closed += 1
	var bodies := 0
	for body in city.events.plans():
		if not body.is_placed():
			continue
		var on_road := _footprint_on_the_road(map, body)
		if on_road <= 0:
			continue
		bodies += 1
		rows[body.def.id] = int(rows.get(body.def.id, 0)) + 1
		print("DAY seed %d day %d | body %s | role %d | tiles %d | comes_in %.1f | at %s"
				% [seed_value, day, body.def.id, body.role, on_road, body.comes_in, body.position])
	totals.held += held
	totals.closed += closed
	totals.bodies += bodies
	print("DAY seed %d day %d | main-road segments held %d | closed %d | bodies %d"
			% [seed_value, day, held, closed, bodies])
	city.free()

## The day's traffic round a main-road boundary crossing.
func _crowd(t, seed_value: int, day: int) -> void:
	var spec := DaySpec.for_day(day)
	var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
	city.run.header.day = day
	t.add_child(city)
	city.build(CityGenerator.generate(seed_value))
	var map := city.map
	city.run.attempt_spend.city_state.begin_day(map.block_plans, day)
	city.start_day(city.run.attempt_spend.city_state, day,
			city.run.calendar.day_rng(day, "closures"), spec)
	var consumed: Array[String] = []
	city.events.start_day(spec, city.run.calendar.day_rng(day), consumed,
			map.doorstep_world_position())
	var crossing: StreetNetwork.Segment = null
	for segment in RegionPlanner.boundary_segments(map):
		if _on_the_main_road(map, segment):
			crossing = segment
			break
	var default_at_a := RegionPlanner.region_of_junction(map, crossing.a) \
			< RegionPlanner.region_of_junction(map, crossing.b)
	var at_a: bool = map.boundary_wall_at_a.get(crossing.key(), default_at_a)
	var at := map.tile_rect_to_world(crossing.mouth_rect(at_a)).get_center()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("main-road-open:%d:%d" % [seed_value, day])
	city.crowd.start_day(day, rng, at)
	city.crowd.set_gates(city.streets().region_plan().gates)
	var left := map.main_road * CityMap.period()
	var side := {}
	var through := 0
	var held_frames := 0
	for frame in int(round(SECONDS / STEP)):
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		for agent: CrowdAgent in city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var tile := map.world_to_tile(agent.global_position)
			if tile.x < left or tile.x >= left + Tuning.STREET_WIDTH:
				side.erase(agent.get_instance_id())
				continue
			if agent.gate_hold < INF:
				held_frames += 1
			var now := signf(agent.global_position.y - at.y)
			var id := agent.get_instance_id()
			var before: float = side.get(id, now)
			if before != now and absf(agent.global_position.y - at.y) < 64.0:
				through += 1
			side[id] = now
	print("CROWD seed %d day %d | crossing %s | cars through %d in %.0fs | car-frames held at a gate %d"
			% [seed_value, day, crossing.key(), through, SECONDS, held_frames])
	city.free()
