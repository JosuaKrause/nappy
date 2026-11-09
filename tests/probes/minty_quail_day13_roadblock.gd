@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## **Day 13's task roadblock, found or swapped in**, on the six probe seeds: how many roadblocks the
## day's plan stands at dawn, how many of them stand beside her routes (on a street no route runs
## along, one of whose junction boxes a route crosses, not the main road), and, read from ten places
## along her routes, what the task's placement does there (`ResistanceDirector.
## _place_the_roadblock_near()`): a roadblock the day placed taken as it stands (**found**), one of
## the day's events replaced by one (**swapped**), a new roadblock added to the plan (**placed**), or
## nothing. Not a suite: it prints rather than asserts. Run by name on each tree and compare:
##
##     tools/test.sh probes/minty_quail_day13_roadblock.gd > out.txt
##     grep '^RB' out.txt
##
## Each place gets the day started again from the same inputs, the way `DayDirector.start_day()`
## starts it, so no place's placement is read on a plan another place changed. She stands on the
## place with the camera's view round her, and the mark is read there.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024]
const DAY := 13
const SPOTS := 10
## The seed of each city's own run: the one the test runner starts the live run on.
const RUN_SEED := 2

func run(t) -> void:
	var outcomes := {}
	var distances: Array[float] = []
	var asked := 0
	for seed_value in SEEDS:
		var city := RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		var director := ResistanceDirector.new()
		var player := _start_the_day(t, city, director, seed_value)
		_count_the_dawn(city, seed_value)
		var route := _route_tiles(city)
		for spot in SPOTS:
			if spot > 0:
				_restart_the_day(city, director, seed_value)
			var at := city.map.tile_to_world(route[(route.size() * spot) / SPOTS])
			var outcome := _read_the_mark_at(city, director, player, at)
			outcomes[outcome[0]] = int(outcomes.get(outcome[0], 0)) + 1
			if outcome[1] != INF:
				distances.append(outcome[1])
			print("RB_SPOT seed %d spot %d | %s | %s" % [seed_value, spot, outcome[0],
					"%.0fpx from where she read it" % outcome[1] if outcome[1] != INF else "-"])
			asked += 1
		player.free()
		director.free()
		city.free()
	distances.sort()
	print("RB_TOTAL %d places | %s | distance min %.0f median %.0f max %.0f px" % [asked, outcomes,
			distances[0] if not distances.is_empty() else 0.0,
			distances[distances.size() / 2] if not distances.is_empty() else 0.0,
			distances.back() if not distances.is_empty() else 0.0])
	t.check(asked > 0, "there were places to read the mark at (%d)" % asked)

## The roadblocks standing at dawn: every placed `roadblock` of the walk's plans that is not the
## region wall's own body or a door's.
func _count_the_dawn(city: City, seed_value: int) -> void:
	var wall := {}
	var region := city.streets().region_plan()
	if region:
		for body in region.wall_bodies:
			wall[body] = true
	var corridor := Corridor.of(city.streets().route_tree())
	var standing := 0
	var beside := 0
	for plan in city.events.plans():
		if plan.def.id != "roadblock" or not plan.is_placed() or plan.is_door() or wall.has(plan):
			continue
		standing += 1
		if _beside(city.map, corridor, city.map.world_to_tile(plan.position)):
			beside += 1
	print("RB_DAWN seed %d | %d roadblocks the day placed | %d beside her routes"
			% [seed_value, standing, beside])

## On a street no route runs along, one of whose junction boxes a route crosses, and not the main
## road: the probe's own reading, so it reads the same before and after.
static func _beside(map: CityMap, corridor: Corridor, tile: Vector2i) -> bool:
	var segment := map.network.segment_containing(tile)
	if not segment or map.is_main_road(not segment.horizontal, segment.a.x):
		return false
	for tile_on in map.rect_tiles(segment.tile_rect()):
		if corridor.carries_a_route(tile_on):
			return false
	for junction: Vector2i in [segment.a, segment.b]:
		var box := Rect2i(junction * CityMap.period(), Vector2i.ONE * Tuning.STREET_WIDTH)
		for tile_in in map.rect_tiles(box):
			if corridor.carries_a_route(tile_in):
				return true
	return false

## What the task's placement does with her reading the mark at `at`: `[outcome, distance]`, the
## distance from `at` to the task's roadblock, `INF` with none.
func _read_the_mark_at(city: City, director: ResistanceDirector, player: Stroller,
		at: Vector2) -> Array:
	player.global_position = at
	city.events.visible_view().look(Rect2(at - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), null)
	director.set_sight(city.events.sees)
	var spent := {}
	for plan in city.events.plans():
		spent[plan] = plan.is_spent()
	var before := city.events.plans().size()
	director._step = _roadblock_step()
	var placed := director._place_the_roadblock_near(at)
	if placed == null:
		return ["none", INF]
	var newly_spent := 0
	for plan in city.events.plans():
		if spent.has(plan) and plan.is_spent() and not spent[plan]:
			newly_spent += 1
	var added := city.events.plans().size() - before
	var outcome := "found"
	if added > 0:
		outcome = "swapped" if newly_spent > 0 else "placed"
	return [outcome, placed.body_position().distance_to(at)]

static func _roadblock_step() -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.day == DAY and step.is_a_guarded_band:
			return step
	return null

func _route_tiles(city: City) -> Array[Vector2i]:
	var corridor := Corridor.of(city.streets().route_tree())
	var found: Array[Vector2i] = []
	for y in city.map.size.y:
		for x in city.map.size.x:
			var tile := Vector2i(x, y)
			if corridor.carries_a_route(tile) and city.map.passable(tile, Mover.lattice()):
				found.append(tile)
	return found

func _start_the_day(t, city: City, director: ResistanceDirector, seed_value: int) -> Stroller:
	_restart_the_day(city, director, seed_value, t)
	var player := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	player.add_child(camera)
	t.add_child(player)
	city.events.use_player(player)
	director.use_player(player)
	player.set_physics_process(false)
	return player

func _restart_the_day(city: City, director: ResistanceDirector, seed_value: int, t = null) -> void:
	var done: Array[int] = []
	for step in ResistanceSteps.all():
		if step.day < DAY:
			done.append(step.index)
	var run: RunState = city.run
	run.header.day = DAY
	run.resistance.completed_steps.assign(done)
	var state := CityState.new()
	run.attempt_spend.city_state = state
	state.begin_day(city.map.block_plans, DAY)
	city.start_day(state, DAY, _rng(seed_value, "closures"))
	city.events.start_day(DaySpec.for_day(DAY), _rng(seed_value, "events"), [],
			city.map.doorstep_world_position())
	if t != null:
		t.add_child(director)
		director.set_process(false)
		director.setup(city.map, city.run, city.events, city.streets(), city.fronts(), city, null,
				city.spawn_siting)
	director.start_day(DAY, _rng(seed_value, "resistance"), 300.0)

func _rng(seed_value: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%s" % [seed_value, DAY, stream])
	return rng
