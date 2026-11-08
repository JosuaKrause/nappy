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
## in: 576, 896 or 1,024px), **swapped** (one of the day's events replaced by one), or **missed**
## (neither, so the task has no roadblock; nothing is added in the walk). For a miss, `RM_MISS` lists
## every event the day placed within reach and each filter of the swap that refused it, and
## `RM_FILTERS` counts, per filter, the misses where it alone refused some candidate. Each mark gets
## the day started again from the same inputs, the
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
	print("RM_FILTERS %d misses | a filter counts a miss when some candidate in reach is refused by"
			% _misses + " it alone | %s" % _misses_by_filter)
	t.check(asked > 0, "there were marks to read (%d)" % asked)

var _misses := 0
var _misses_by_filter := {}

## **Why no event the day placed could be swapped for the task's roadblock** where she read the mark
## at `at`: for each placed, unspent plan whose touch ground her paths reach within `reach`
## (`ResistanceDirector._touched_within()`), every filter of the swap that refuses it, in the order
## the swap asks them. `plan -> Array[String]`, a plan no filter refuses mapped to `[]`.
func _why_nothing_swaps(city: City, director: ResistanceDirector, at: Vector2, paths: Dictionary,
		reach: float) -> Dictionary:
	var map := city.map
	var siting: EventScheduler.WalkSiting = city.events.ahead._day_siting()
	var def := EventCatalogue.by_id(_roadblock_step().task_event_id).for_day(DAY)
	var role := EventScheduler._role_for(def, DAY)
	var own := {}
	for tile in EventScheduler._ground_for(def, map, siting._ground, siting._corridor, role,
			EventScheduler.NO_SITE, siting.holds_the_home_streets):
		own[tile] = true
	var found := {}
	for plan in director._walk.plans():
		if not plan.is_placed() or plan.is_spent():
			continue
		if director._touched_within(plan, paths, reach) == INF:
			continue
		var why: Array[String] = []
		var tile := map.world_to_tile(plan.placed_at())
		if not plan.stands_still():
			why.append("moving")
		if plan.is_door():
			why.append("door")
		if plan.is_in_the_wall():
			why.append("wall")
		if plan.is_permanent():
			why.append("scar")
		if plan.is_in_the_world() and not plan.may_be_replaced() and plan.stands_still() \
				and not plan.is_door() and not plan.is_in_the_wall() and not plan.is_permanent():
			why.append("noticed her")
		if not siting._corridor.is_beside_the_routes(tile):
			why.append("not beside the routes")
		elif not siting.stands_beside_the_routes(tile):
			why.append("main road")
		if director._drawing_shows(plan.row(), plan.where_it_stands_now()):
			why.append("in view")
		why.append_array(_why_no_spot(city, director, siting, def, role, own, plan))
		found[plan] = why
	return found

## Why no tile in `plan`'s place takes the roadblock (`WalkSiting.in_place_of()`'s own order): none
## of its own ground on the street within `SWAP_SPREAD_TILES`, every such tile in her view, or the
## rules `_judge()` asks refusing every one, named for the nearest. Empty when one takes it.
func _why_no_spot(city: City, director: ResistanceDirector, siting: EventScheduler.WalkSiting,
		def: EventDef, role: GameEnums.BlockerRole, own: Dictionary,
		plan: EventScheduler.Planned) -> Array[String]:
	var map := city.map
	var any_own := false
	var first: Array[String] = []
	for tile in siting._tiles_in_place_of(plan):
		if not own.has(tile):
			continue
		any_own = true
		if director._drawing_shows(def, map.tile_to_world(tile)):
			continue
		var why: Array[String] = []
		var candidate := EventScheduler._build_placement(def, map, tile, _rng(0, "probe"))
		if not candidate:
			why.append("no placement built")
		else:
			var already := director._walk.everything_but(plan)
			candidate.role = role
			if EventScheduler._reaches_any(candidate, siting._leave_alone):
				why.append("unused calm")
			if not EventScheduler._clear_of_the_doors(candidate.position, candidate.path,
					director._walk.doors(), candidate.def.field_reach()):
				why.append("door clearance")
			if not EventScheduler._leaves_the_route_junctions_open(candidate, map,
					siting._corridor, siting._ground, already) \
					or not EventScheduler._leaves_the_routes_sidewalk_open(candidate, map,
							siting._corridor, already):
				why.append("route kept open")
			var room := EventScheduler._room_around(candidate, already)
			if room == -INF:
				why.append("spacing (another event within 64px or its field)")
			elif room != INF:
				why.append("spacing (a roadblock within 256px)")
		if why.is_empty():
			return [] as Array[String]
		if first.is_empty():
			first = why
	if not any_own:
		return ["no roadblock ground on its street within %d tiles (%s)"
				% [EventScheduler.SWAP_SPREAD_TILES, _why_not_ground(map, siting, plan)]] as Array[String]
	if first.is_empty():
		return ["its spot in view"] as Array[String]
	return first

## Why the road and crossing tiles in `plan`'s place are not a roadblock's ground
## (`EventScheduler.open_ground_for()`'s refusals, then the role's: a route runs along it): each
## reason found on any of them, joined.
static func _why_not_ground(map: CityMap, siting: EventScheduler.WalkSiting,
		plan: EventScheduler.Planned) -> String:
	var found := {}
	var trees := EventScheduler._street_tree_tiles(map, siting._ground)
	var doorstep := EventScheduler._the_street_she_starts_on(map)
	var road := 0
	for tile in siting._tiles_in_place_of(plan):
		var type := map.tile_at(tile)
		if type != GameEnums.TileType.ROAD and type != GameEnums.TileType.CROSSING:
			continue
		road += 1
		if map.is_closed(tile):
			found["closed"] = true
		if map.is_held_at(tile):
			found["held"] = true
		if doorstep.has_point(tile):
			found["her doorstep street"] = true
		if map.is_on_home_block(tile):
			found["home block"] = true
		if trees.has(tile):
			found["a street tree"] = true
		if EventScheduler._is_a_corner(tile):
			found["a corner"] = true
		if siting._corridor.carries_a_route(tile):
			found["a route runs along it"] = true
	if road == 0:
		return "no road on its street within reach"
	return "/".join(found.keys())

## The filters that alone refuse some candidate: removing that one filter would let a swap through.
static func _only_refusals(refusals: Dictionary) -> Array[String]:
	var only := {}
	for plan: EventScheduler.Planned in refusals:
		var why: Array = refusals[plan]
		if why.size() == 1:
			only[_family(why[0])] = true
	var names: Array[String] = []
	names.assign(only.keys())
	return names

static func _family(reason: String) -> String:
	return reason.get_slice(" (", 0)

static func _summary(refusals: Dictionary) -> String:
	var counts := {}
	for plan: EventScheduler.Planned in refusals:
		var key := "+".join(refusals[plan])
		counts[key] = int(counts.get(key, 0)) + 1
	return "%d in reach: %s" % [refusals.size(), counts]

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
	var spent := {}
	for plan in city.events.plans():
		spent[plan] = plan.is_spent()
	var refusals := _why_nothing_swaps(city, director, at, paths, reaches.back())
	var placed := director._place_the_roadblock_near(at)
	if placed == null:
		print("RM_MISS seed %d at %s | %s" % [seed_value, city.map.world_to_tile(at),
				_summary(refusals)])
		for filter: String in _only_refusals(refusals):
			_misses_by_filter[filter] = int(_misses_by_filter.get(filter, 0)) + 1
		if refusals.is_empty():
			_misses_by_filter["nothing in reach"] = int(_misses_by_filter.get("nothing in reach",
					0)) + 1
		_misses += 1
		return ["missed", INF]
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
