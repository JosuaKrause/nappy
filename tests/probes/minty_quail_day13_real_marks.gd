extends RefCounted
## **Day 13's task roadblock, read from real chalk marks**: what the task's placement
## (`ResistanceDirector._place_the_roadblock_near()`) does when she reads the mark where a mark
## actually stands, one tile into an alley from its mouth (`ResistanceDirector._marks()`), rather
## than on a route tile. Every mark tile the day's draw could pick is read (`_pick_reachable()`'s
## two tests: legal ground, and open to it and reachable from home under the day's plan), or an
## evenly spaced `PER_SEED` of them where a city has more. Not a suite: it prints rather than
## asserts.
##
##     tools/test.sh probes/minty_quail_day13_real_marks.gd > out.txt
##     grep '^RM' out.txt
##
## Each outcome is **found** (a roadblock the day placed, with the ring of the walk it was found
## in: 576, 896 or 1,024px), **swapped** (one of the day's events replaced by one), or **fallback**
## (neither, so the task would go to the edge of the 576px circle, `_pick_near()`; the distance
## printed is that edge spawn's). Each mark gets the day started again from the same inputs, the
## way `DayDirector.start_day()` starts it, with the world streamed in round her
## (`EventManager.stream_around()`), so what is in the world, and so out of the swap, is what it
## would be as she stands there.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The six probe seeds, then fourteen more.
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024,
		1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
const DAY := 13
## At most this many marks per seed, evenly spaced over the legal ones in `_marks()`'s order.
const PER_SEED := 24
const RUN_SEED := 2

func run(t) -> void:
	var totals := {}
	var distances := {}
	var asked := 0
	for seed_value in SEEDS:
		var city := RunCity.with_own_run(CITY_SCENE, RUN_SEED)
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		var director := ResistanceDirector.new()
		var player := _start_the_day(t, city, director, seed_value)
		var marks := _legal_marks(city, director)
		var chosen := _spaced(marks, PER_SEED)
		var per_seed := {}
		for index in chosen.size():
			if index > 0:
				_restart_the_day(city, director, seed_value)
			var at := city.map.tile_to_world(chosen[index])
			var outcome := _read_the_mark_at(city, director, player, at, seed_value)
			var kind: String = outcome[0]
			var key := kind.get_slice("@", 0)
			per_seed[key] = int(per_seed.get(key, 0)) + 1
			totals[kind] = int(totals.get(kind, 0)) + 1
			if not distances.has(key):
				distances[key] = []
			if outcome[1] != INF:
				distances[key].append(outcome[1])
			print("RM_MARK seed %d mark %s | %s | %s" % [seed_value, chosen[index], kind,
					"%.0fpx" % outcome[1] if outcome[1] != INF else "-"])
			asked += 1
		print("RM_SEED seed %d | %d legal marks, %d read | %s" % [seed_value, marks.size(),
				chosen.size(), per_seed])
		player.free()
		director.free()
		city.free()
	print("RM_TOTAL %d marks over %d seeds | %s" % [asked, SEEDS.size(), totals])
	for key: String in distances:
		var list: Array = distances[key]
		list.sort()
		if list.is_empty():
			continue
		print("RM_DIST %s | n %d | min %.0f median %.0f max %.0f px" % [key, list.size(), list[0],
				list[list.size() / 2], list.back()])
	t.check(asked > 0, "there were marks to read (%d)" % asked)

## The mark tiles the day's draw could pick, in `_marks()`'s order: those `_pick_reachable()` takes,
## legal ground and open to it and reachable from home.
func _legal_marks(city: City, director: ResistanceDirector) -> Array[Vector2i]:
	var siting: SpawnSiting = city.spawn_siting
	var ground := siting.ask_of_ground()
	var legal: Array[Vector2i] = []
	for tile in director._marks():
		var world := city.map.tile_to_world(tile)
		if siting.allows(SpawnSiting.Rule.LEGAL_GROUND, ground, world) \
				and siting.allows(SpawnSiting.Rule.OPEN_TO_IT, ground, world) \
				and director._reachable_from_home(tile):
			legal.append(tile)
	return legal

static func _spaced(tiles: Array[Vector2i], most: int) -> Array[Vector2i]:
	if tiles.size() <= most:
		return tiles
	var picked: Array[Vector2i] = []
	for index in most:
		picked.append(tiles[(tiles.size() * index) / most])
	return picked

## What the task's placement does with her reading the mark at `at`: `[outcome, distance]`, the
## straight-line distance from `at` to the task's roadblock (or the edge spawn's spot), `INF` with
## none.
func _read_the_mark_at(city: City, director: ResistanceDirector, player: Stroller,
		at: Vector2, seed_value: int) -> Array:
	player.global_position = at
	city.events.stream_around(at)
	city.events.visible_view().look(Rect2(at - Tuning.VIEW_HALF_EXTENT,
			Tuning.VIEW_HALF_EXTENT * 2.0), null)
	director.set_sight(city.events.sees)
	var step := _roadblock_step()
	director._step = step
	var def := EventCatalogue.by_id(step.task_event_id)
	var reaches: Array[float] = [ResistanceDirector.NEAR_THE_MARK]
	reaches.append_array(ResistanceDirector.ROADBLOCK_WIDER_REACH)
	var paths := director._paths_reach_between(at, 0.0, reaches.back())
	var ring := -1.0
	for reach in reaches:
		if director._a_roadblock_the_day_placed(def.id, paths, reach):
			ring = reach
			break
	var spent := {}
	for plan in city.events.plans():
		spent[plan] = plan.is_spent()
	var placed := director._place_the_roadblock_near(at)
	if placed == null:
		var edge := director._place_contact(step, _rng(seed_value, "fallback"), at)
		return ["fallback", at.distance_to(edge) if edge != Vector2.INF else INF]
	for plan in city.events.plans():
		if spent.has(plan) and plan.is_spent() and not spent[plan]:
			return ["swapped", placed.body_position().distance_to(at)]
	return ["found@%.0f" % ring, placed.body_position().distance_to(at)]

static func _roadblock_step() -> ResistanceSteps.Step:
	for step in ResistanceSteps.all():
		if step.day == DAY and step.is_a_guarded_band:
			return step
	return null

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
