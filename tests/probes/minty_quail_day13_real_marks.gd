@warning_ignore_start("untyped_declaration", "unsafe_method_access")
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
## in: 576, 896 or 1,024px), **swapped** (a route-adjacent section's whole content replaced by one,
## `ResistanceDirector._section_to_swap()`), or **missed** (neither, so the task has no roadblock;
## nothing is added in the walk). Each distance is the straight line from where she read the mark to
## the roadblock; `RM_MISS` names a miss's mark. `RM_TIME` is how long the task's placement took on
## the frame she reads the mark, found and swapped apart, and the swap's walk over the whole city,
## the fallback a swap takes where the close-by walk reaches no section, timed on its own. Each mark gets the day started again from the same
## inputs, the
## way `DayDirector.start_day()` starts it, with the world streamed in round her
## (`EventManager.stream_around()`), so what is in the world, and so in her view, is what it would
## be as she stands there.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The six probe seeds, then fourteen more.
const SEEDS: Array[int] = [4242, 90210, 1234567, 7, 31337, 2024,
		1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
const DAY := 13
## At most this many marks per seed, evenly spaced over the legal ones in `_marks()`'s order.
const PER_SEED := 24
const RUN_SEED := 2
## When not empty, only these marks are read, `[seed, mark tile]` each: a rerun of the misses.
const ONLY: Array = []

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
		var roadblocks := _roadblocks(city)
		var chosen := _spaced(marks, PER_SEED)
		if not ONLY.is_empty():
			chosen = []
			for entry: Array in ONLY:
				if entry[0] == seed_value:
					chosen.append(entry[1])
			if chosen.is_empty():
				player.free()
				director.free()
				city.free()
				continue
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
		print("RM_SEED seed %d | %d legal marks, %d read | %d roadblocks the day placed | %s"
				% [seed_value, marks.size(), chosen.size(), roadblocks, per_seed])
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
	print("RM_MISSES %d" % _misses)
	for what: String in _times:
		var list: Array = _times[what]
		list.sort()
		print("RM_TIME %s | n %d | median %.1f max %.1f ms" % [what, list.size(), list[list.size() / 2],
				list.back()])
	t.check(asked > 0, "there were marks to read (%d)" % asked)

var _misses := 0
## What -> the milliseconds each `_place_the_roadblock_near()` call took (`RM_TIME`).
var _times := {}

func _took(what: String, ms: float) -> void:
	if not _times.has(what):
		_times[what] = []
	_times[what].append(ms)

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

## How many roadblocks the day placed (not a region door's or the wall's own bodies).
static func _roadblocks(city: City) -> int:
	var count := 0
	for plan in city.events.plans():
		if plan.row_id() == "roadblock" and plan.is_placed() and not plan.is_door() \
				and not plan.is_in_the_wall():
			count += 1
	return count

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
	var before := {}
	for plan in city.events.plans():
		before[plan] = true
	var started := Time.get_ticks_usec()
	var placed := director._place_the_roadblock_near(at)
	var took := (Time.get_ticks_usec() - started) / 1000.0
	if placed == null:
		print("RM_MISS seed %d at %s" % [seed_value, city.map.world_to_tile(at)])
		_misses += 1
		return ["missed", INF]
	for plan in city.events.plans():
		if not before.has(plan) and plan.instance() == placed:
			_took("swapped", took)
			# The swap's fallback walk alone, her paths over the whole city, timed apart.
			var whole_city := Vector2(Tuning.CITY_BLOCKS * CityMap.period()).length() * Tuning.TILE_SIZE
			var walked := Time.get_ticks_usec()
			director._paths_reach_between(at, 0.0, whole_city)
			_took("the whole-city walk", (Time.get_ticks_usec() - walked) / 1000.0)
			return ["swapped", placed.body_position().distance_to(at)]
	_took("found", took)
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
