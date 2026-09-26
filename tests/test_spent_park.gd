extends RefCounted
## A spent park is closed: a calm area she has already used this act is shut the next days — she
## cannot get into it, and no route of the day goes through it — wherever that breaks no guarantee.
## *(PLAYTEST-140: "a spent park should not be accesible and no route should go through it".)*
##
## `ClosurePlanner.calm_to_shut()` decides it at `CityMap.repaint()`, `RouteTree` plans around it,
## `ClosurePlanner.plan_day` hands `City` the fence (`ParkClosure`), and the scheduler places
## nothing in it. This suite asks all of that over a sweep of seeds and days, with the used areas
## an act would actually have, and once with every calm area used to make the refusals happen.

const SEEDS := 6
const BASE_SEED := 14040
const CITY_SCENE := preload("res://scenes/world/city.tscn")

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 37))
	_test_a_spent_park_is_shut_and_no_route_goes_through_it(t)
	_test_the_fence_closes_every_entrance(t)
	_test_the_guarantees_hold_with_the_park_shut(t)
	_test_a_never_used_park_is_unaffected(t)
	_test_the_day_places_nothing_in_a_shut_park(t)
	_test_shutting_is_refused_rather_than_breaking_a_guarantee(t)
	_test_the_swing_park_is_never_shut_on_its_day(t)
	_test_shutting_is_deterministic_and_forgotten_by_the_next_repaint(t)
	_test_the_city_stands_a_barrier_body_along_every_entrance(t)

# ------------------------------------------------------------------------ setup ---

## Repaints `map` for `day` with `used` handed over the way `Main._start_day()` hands
## `GameState.settled_this_act()` over.
func _repaint(map: CityMap, day: int, used: Array[Vector2i]) -> CityState:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.set_spent_calm(used)
	map.repaint(state)
	return state

## The calm areas today's repaint leaves calm with nothing handed over.
func _calm_on(map: CityMap, day: int) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	_repaint(map, day, none)
	return map.calm_blocks.duplicate()

## What an act would have used by `day`: one area a day since the act began, most recent first,
## drawn from today's calm in an order rolled from the seed — the shape `GameState.
## settled_this_act()` has, without playing the days.
func _used_by(map: CityMap, day: int) -> Array[Vector2i]:
	var calm := _calm_on(map, day)
	var act_start := 1
	for start: int in Tuning.ACT_START_DAYS:
		if start <= day:
			act_start = start
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spent:%d:%d" % [map.seed_used, act_start])
	var order: Array[Vector2i] = calm.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held := order[i]
		order[i] = order[j]
		order[j] = held
	var used: Array[Vector2i] = []
	for i in mini(day - act_start, order.size()):
		used.push_front(order[i])
	return used

## The days the sweeps below walk: every day of the run.
func _days() -> Array[int]:
	var days: Array[int] = []
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		days.append(day)
	return days

func _closure_rng(map: CityMap, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
	return rng

func _shut_rect_tiles(map: CityMap) -> Dictionary:
	var found := {}
	for block in map.shut_calm:
		for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
			found[tile] = true
	return found

# ------------------------------------------------------------------ the rule ---

## The whole point, over the sweep: every area shut is one she used, its ground is closed tile for
## tile, it has left the calm, and the day's tree neither grows a branch to it nor runs through it.
## Also counts how often a used area is refused — printed, since it is a measurement.
func _test_a_spent_park_is_shut_and_no_route_goes_through_it(t) -> void:
	var offered := 0
	var shut := 0
	for map in _maps:
		for day in _days():
			var used := _used_by(map, day)
			_repaint(map, day, used)
			offered += used.size()
			shut += map.shut_calm.size()
			for block in map.shut_calm:
				t.check(block in used, "seed %d day %d shuts %s, which she used"
						% [map.seed_used, day, block])
				t.check(not block in map.calm_blocks, "seed %d day %d: shut %s is not calm today"
						% [map.seed_used, day, block])
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
					if map.is_walkable(tile):
						t.check(map.is_closed(tile) and not map.is_open(tile),
								"seed %d day %d: %s of shut %s is closed"
								% [map.seed_used, day, tile, block])
			var tree := RouteTree.for_day(map, day)
			var shut_tiles := _shut_rect_tiles(map)
			var through := 0
			for cell in tree.cells():
				for dy in 2:
					for dx in 2:
						if shut_tiles.has(cell * 2 + Vector2i(dx, dy)):
							through += 1
			t.check(through == 0, "seed %d day %d: no route of the day runs through a shut park "
					% [map.seed_used, day] + "(%d tiles)" % through)
			for branch in tree.branches:
				t.check(not branch.area in map.shut_calm,
						"seed %d day %d: no branch goes to shut %s" % [map.seed_used, day, branch.area])
	t.check(shut > 0, "the sweep shut some parks (%d of %d used)" % [shut, offered])
	print("  spent parks: %d of %d used calm areas shut, %d refused, over %d seeds x %d days"
			% [shut, offered, offered - shut, SEEDS, Tuning.RUN_LENGTH_DAYS])

## A shut area's fence closes it: every edge tile with walkable ground outside it is covered by a
## barrier line lying along that edge, and every line stands on the area's own ground, never on the
## pavement beside it. `City._spawn_barrier()` stands a line `STREET_WIDTH` tiles long and
## `CLOSURE_BARRIER_DEPTH` deep at every `mouth_centres()` point — this is that geometry, asked of
## the plan rather than of a scene.
func _test_the_fence_closes_every_entrance(t) -> void:
	var fenced := 0
	var half_line := Tuning.STREET_WIDTH * Tuning.TILE_SIZE * 0.5
	var half_depth := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	for map in _maps:
		for day in [2, 6, 10, 13]:
			_repaint(map, day, _used_by(map, day))
			var closures := ClosurePlanner.plan_day(map, day, _closure_rng(map, day))
			for block in map.shut_calm:
				var rect := ClosurePlanner.calm_area_rect(map, block)
				var world := map.tile_rect_to_world(rect)
				var boxes: Array[Rect2] = []
				for closure in closures:
					var fence := closure as ParkClosure
					if not fence or fence.area != rect:
						continue
					t.check(fence.kind == RoadClosure.Kind.PARK and
							StreetNetwork.by_key(fence.segment.key()) == null,
							"seed %d day %d: a fence is a PARK closure holding no real street"
							% [map.seed_used, day])
					# A run shorter than one line — a courtyard's archway — is crossed by a line
					# that overhangs the walls either side of it; every other line stands wholly
					# on the area's own ground.
					var run := fence.segment.tile_rect()
					var short := maxi(run.size.x, run.size.y) < Tuning.STREET_WIDTH
					for at in fence.mouth_centres(map):
						var size := Vector2(half_line * 2.0, half_depth * 2.0) \
								if fence.barrier_runs_across() \
								else Vector2(half_depth * 2.0, half_line * 2.0)
						var box := Rect2(at - size * 0.5, size)
						boxes.append(box)
						t.check(short or world.grow(0.01).encloses(box),
								"seed %d day %d: a barrier of %s stands on its own ground"
								% [map.seed_used, day, block])
				for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					for tile in _edge_tiles(rect, out):
						if not (map.is_walkable(tile) and map.is_walkable(tile + out)):
							continue
						fenced += 1
						# The middle of the tile's outer edge, a hair inside the area: the point a
						# pram crossing from the pavement onto this tile has to pass.
						var centre := map.tile_to_world(tile)
						var crossing := centre + Vector2(out) * (Tuning.TILE_SIZE * 0.5 - 1.0)
						var covered := false
						for box in boxes:
							if box.has_point(crossing):
								covered = true
								break
						t.check(covered, "seed %d day %d: the way in at %s of shut %s is fenced"
								% [map.seed_used, day, tile, block])
	t.check(fenced > 0, "the sweep had entrances to fence (%d)" % fenced)

func _edge_tiles(rect: Rect2i, out: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var horizontal := out.y != 0
	var length: int = rect.size.x if horizontal else rect.size.y
	for i in length:
		found.append(ParkClosure._edge_tile(rect, out, i))
	return found

## The guarantees hold with the park shut and the day's street closures down: at least
## `MIN_CALM_AREAS_REACHABLE` open calm areas reachable from the doorstep, and nothing that was
## reachable before the shutting cut off by it.
func _test_the_guarantees_hold_with_the_park_shut(t) -> void:
	for map in _maps:
		for day in _days():
			var none: Array[Vector2i] = []
			_repaint(map, day, none)
			var home := map.world_to_tile(map.doorstep_world_position())
			var before := map.walk_field(home)
			_repaint(map, day, _used_by(map, day))
			if map.shut_calm.is_empty():
				continue
			var shut_tiles := _shut_rect_tiles(map)
			var after := map.walk_field(home, map.closed_tiles)
			var cut := 0
			for index in before.size():
				var tile := Vector2i(index % map.size.x, index / map.size.x)
				if before[index] >= 0 and after[index] < 0 and not shut_tiles.has(tile):
					cut += 1
			t.check(cut == 0, "seed %d day %d: shutting cuts nothing off (%d tiles)"
					% [map.seed_used, day, cut])
			var closures := ClosurePlanner.plan_day(map, day, _closure_rng(map, day))
			map.close_streets(closures)
			var barriers := map.closed_tiles.duplicate()
			for closure in closures:
				if closure is ParkClosure:
					continue
				for at_a in [true, false]:
					for tile in map.rect_tiles(closure.segment.mouth_rect(at_a)):
						barriers[tile] = true
			var field := map.walk_field(home, barriers)
			var reachable := 0
			for block in map.calm_blocks:
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
					if Tile.is_calm(map.tile_at(tile)) and map.reaches(field, tile):
						reachable += 1
						break
			t.check(reachable >= Tuning.MIN_CALM_AREAS_REACHABLE,
					"seed %d day %d: %d open calm areas reachable with the park shut and the "
					% [map.seed_used, day, reachable] + "streets closed, need %d"
					% Tuning.MIN_CALM_AREAS_REACHABLE)

## A calm area she has not used is untouched: still calm, none of its ground closed by the
## shutting, and the tree still grows it a branch wherever the tree with nothing shut did.
func _test_a_never_used_park_is_unaffected(t) -> void:
	var compared := 0
	for map in _maps:
		for day in _days():
			var none: Array[Vector2i] = []
			_repaint(map, day, none)
			var plain := {}
			for branch in RouteTree.for_day(map, day).branches:
				plain[branch.area] = true
			var used := _used_by(map, day)
			_repaint(map, day, used)
			if map.shut_calm.is_empty():
				continue
			var shut_tree := {}
			for branch in RouteTree.for_day(map, day).branches:
				shut_tree[branch.area] = true
			var all_calm: Array[Vector2i] = map.calm_blocks.duplicate()
			all_calm.append_array(map.shut_calm)
			for block in all_calm:
				if block in used:
					continue
				compared += 1
				t.check(block in map.calm_blocks, "seed %d day %d: unused %s is still calm"
						% [map.seed_used, day, block])
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
					t.check(not map.is_shut(tile) and not map.is_closed(tile),
							"seed %d day %d: %s of unused %s is open" % [map.seed_used, day, tile,
							block])
				if plain.has(block):
					t.check(shut_tree.has(block),
							"seed %d day %d: unused %s still has its branch" % [map.seed_used, day,
							block])
	t.check(compared > 0, "the sweep compared unused parks on days with a park shut (%d)"
			% compared)

## The scheduler's calm-ground pass places nothing in a shut park — its fence is the whole of what
## it shows — and the day still has a clean open calm area, which `_ensure_one_usable_park`
## guarantees. A used area whose shutting was refused is still spoiled, as before.
func _test_the_day_places_nothing_in_a_shut_park(t) -> void:
	var spoiled_refusals := 0
	for map in _maps:
		for day in [3, 6, 10, 13]:
			var used := _used_by(map, day)
			_repaint(map, day, used)
			var tree := RouteTree.for_day(map, day)
			var closures := ClosurePlanner.plan_day(map, day, _closure_rng(map, day), tree)
			map.close_streets(closures)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("events:%d:%d" % [map.seed_used, day])
			var no_one_shots: Array[String] = []
			var no_scars: Array[Dictionary] = []
			var planned := EventScheduler.build_day(day, rng, map, no_one_shots, no_scars, used,
					tree)
			var shut_tiles := _shut_rect_tiles(map)
			for plan in planned:
				if not plan.is_placed():
					continue
				t.check(not shut_tiles.has(map.world_to_tile(plan.position)),
						"seed %d day %d: '%s' is not placed inside a shut park"
						% [map.seed_used, day, plan.def.id])
			var clean := 0
			for block in map.calm_blocks:
				if not EventScheduler._is_spoiled(map, planned,
						ClosurePlanner.calm_area_rect(map, block)):
					clean += 1
			t.check(clean >= 1, "seed %d day %d leaves an open calm area clean"
					% [map.seed_used, day])
			for block in used:
				if block in map.calm_blocks and EventScheduler._is_spoiled(map, planned,
						ClosurePlanner.calm_area_rect(map, block)):
					spoiled_refusals += 1
	print("  spent parks: %d used areas left open were spoiled instead" % spoiled_refusals)

## With every calm area handed over as used, the city shuts as many as it may and no more: the calm
## count keeps `MIN_CALM_AREAS_REACHABLE` open, and each refusal leaves the area calm.
func _test_shutting_is_refused_rather_than_breaking_a_guarantee(t) -> void:
	for map in _maps:
		for day in [1, 5, 9, 12, 14]:
			var calm := _calm_on(map, day)
			_repaint(map, day, calm)
			t.check(map.calm_blocks.size() >= mini(calm.size(), Tuning.MIN_CALM_AREAS_REACHABLE),
					"seed %d day %d: %d of %d calm areas left open, need %d"
					% [map.seed_used, day, map.calm_blocks.size(), calm.size(),
					Tuning.MIN_CALM_AREAS_REACHABLE])
			t.check(map.shut_calm.size() + map.calm_blocks.size() == calm.size(),
					"seed %d day %d: every calm area is either shut or still calm"
					% [map.seed_used, day])

## Day 12's park is where the day's task is, so it is never shut on its day, even when she used it.
func _test_the_swing_park_is_never_shut_on_its_day(t) -> void:
	var day := ResistanceSteps.swing_day()
	t.check(day > 0, "the calendar has a swing day")
	if day <= 0:
		return
	for map in _maps:
		var park := CityGenerator.swing_park(map)
		var used: Array[Vector2i] = [park]
		_repaint(map, day, used)
		t.check(not park in map.shut_calm and park in map.calm_blocks,
				"seed %d: the swing park %s stays open on day %d" % [map.seed_used, park, day])

## The same handover shuts the same areas, and a repaint with no handover shuts nothing — the
## escape's own repaint, and every rig that never hands one over.
func _test_shutting_is_deterministic_and_forgotten_by_the_next_repaint(t) -> void:
	for map in _maps.slice(0, 3):
		var cmap: CityMap = map
		for day in [3, 7, 11]:
			var used := _used_by(cmap, day)
			_repaint(cmap, day, used)
			var first: Array[Vector2i] = cmap.shut_calm.duplicate()
			_repaint(cmap, day, used)
			t.check(first == cmap.shut_calm, "seed %d day %d shuts the same parks twice"
					% [cmap.seed_used, day])
			var state := CityState.new()
			state.begin_day(cmap.block_plans, day)
			cmap.repaint(state)
			t.check(cmap.shut_calm.is_empty() and cmap.closed_tiles.is_empty(),
					"seed %d day %d: a repaint with nothing handed over shuts nothing"
					% [cmap.seed_used, day])

## The real `City` stands one static body behind every fence line, where `ParkClosure` says: a shut
## park has a body across every way in, the same body a closed street's mouth has.
func _test_the_city_stands_a_barrier_body_along_every_entrance(t) -> void:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(BASE_SEED))
	var day := 3
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	var calm: Array[Vector2i] = []
	city.map.repaint(state)
	calm = city.map.calm_blocks.duplicate()
	var used: Array[Vector2i] = [calm[0], calm[1]]
	city.map.set_spent_calm(used)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spent-park:closures:%d" % day)
	city.start_day(state, day, rng)
	t.check(not city.map.shut_calm.is_empty(), "the city shut a park it was handed (%s)"
			% [city.map.shut_calm])
	var bodies: Array[Rect2] = []
	for node in city._closure_nodes:
		var body := node as StaticBody2D
		if not body:
			continue
		var shape := (body.get_child(0) as CollisionShape2D).shape as RectangleShape2D
		bodies.append(Rect2(body.position - shape.size * 0.5, shape.size))
	for block in city.map.shut_calm:
		var rect := ClosurePlanner.calm_area_rect(city.map, block)
		var entrances := 0
		for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			for tile in _edge_tiles(rect, out):
				if not (city.map.is_walkable(tile) and city.map.is_walkable(tile + out)):
					continue
				entrances += 1
				var crossing := city.map.tile_to_world(tile) \
						+ Vector2(out) * (Tuning.TILE_SIZE * 0.5 - 1.0)
				var covered := false
				for box in bodies:
					if box.has_point(crossing):
						covered = true
						break
				t.check(covered, "a body stands across the way in at %s of shut %s" % [tile, block])
		t.check(entrances > 0, "shut %s has ways in to stand bodies across" % block)
	city.free()
