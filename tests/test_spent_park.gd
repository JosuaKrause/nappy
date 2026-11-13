extends RefCounted
## A used calm area is shut by the events placed in it, as before, and no route of the day goes
## through it. One used area, at most once a run and no earlier than act III, is fenced instead.
## *(PLAYTEST-140, statement 8: "a used park is shut by the events placed in it, as before... and no
## route of the day goes through it"; statement 9: "doing it for one park, sure, more towards the
## later stages of the game once but not for regular".)*
##
## `ClosurePlanner.calm_to_shut()` decides which used areas come off today's route tree at
## `CityMap.repaint()`; `RouteTree` plans around all of them; `DawnSpoilers`
## spoils every one of them except `CityMap.fenced_park`, the one the run
## ever fences (`ClosurePlanner.plan_day` hands `City` its `ParkClosure`). This suite asks all of
## that over a sweep of seeds and days, with the used areas an act would actually have, and once
## with every calm area used to make the guarantee's refusals happen.

const SEEDS := 6
const BASE_SEED := 14040
const CITY_SCENE := preload("res://scenes/world/city.tscn")

var _maps: Array[CityMap] = []

func run(t: TestRunner) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 37))
	_test_a_used_area_is_taken_off_the_tree_and_stays_open(t)
	_test_the_one_fence_is_remembered_after_its_act(t)
	_test_the_fenced_park_closes_every_entrance(t)
	_test_the_fence_turns_each_corner_on_one_post(t)
	_test_the_guarantees_hold_with_the_fenced_park(t)
	_test_a_never_used_park_is_unaffected(t)
	_test_the_day_spoils_every_shut_area_but_the_fenced_one(t)
	_test_with_every_area_used_one_stays_clean(t)
	_test_a_used_courtyard_keeps_what_was_put_in_it(t)
	_test_shutting_is_refused_rather_than_breaking_a_guarantee(t)
	_test_the_swing_park_is_never_shut_or_fenced_on_its_day(t)
	_test_shutting_is_deterministic_and_forgotten_by_the_next_repaint(t)
	await _test_the_city_stands_a_barrier_body_along_the_fenced_park(t)

# ------------------------------------------------------------------------ setup ---

## Repaints `map` for `day` with `used` handed over the way `DayDirector.start()` hands
## `RunState.calendar.settled_this_act()` over, and `fenced`/`fenced_act` the way it hands over
## `RunState.facts.fenced_park`/`fenced_park_act` — both defaulting to "nothing fenced yet", the shape
## every test but the ones about the fence itself wants. Returns the pair to feed the same map's
## next call, the way `DayDirector.start()` reads them back into the run for tomorrow, so a fence
## chosen on one day of the sweep carries into the next rather than being re-decided.
func _repaint(map: CityMap, day: int, used: Array[Vector2i],
		fenced: Vector2i = Vector2i(-1, -1), fenced_act: int = 0) -> Array:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.set_spent_calm(used)
	map.set_fenced_park_state(fenced, fenced_act, Tuning.act_for_day(day))
	map.repaint(state)
	# Exercise the director's actual read-back policy on a run of its own, thrown away after.
	var run := RunState.new()
	run.start_run(BASE_SEED)
	run.facts.fenced_park = fenced
	run.facts.fenced_park_act = fenced_act
	run.facts.remember_fenced_park(map.fenced_park, map.fenced_park_act)
	var remembered := [run.facts.fenced_park, run.facts.fenced_park_act]
	return remembered

## The calm areas today's repaint leaves calm with nothing handed over.
func _calm_on(map: CityMap, day: int) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	_repaint(map, day, none)
	return map.calm_blocks.duplicate()

## What an act would have used by `day`: one area a day since the act began, most recent first,
## drawn from today's calm in an order rolled from the seed — the shape `RunState.calendar.
## settled_this_act()` has, without playing the days. A block chosen as `CityMap.fenced_park` on an
## earlier day may still be here on a later one, the same way `RunState.settled.settled_in` still carries
## the day she used it before it was fenced — fencing does not erase the past.
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
	for block in map.shut_calm():
		for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
			found[tile] = true
	return found

## Repaints as if nothing had ever been fenced this run, so today's own act (every call site below
## is act III or later) is free to choose a fresh one if `calm_to_shut()` accepts a candidate — for
## the tests about the fence itself, which cannot wait for the sweep in
## `_test_a_used_area_is_taken_off_the_tree_and_stays_open` to reach one on its own.
func _force_a_fence(map: CityMap, day: int, used: Array[Vector2i]) -> void:
	_repaint(map, day, used, Vector2i(-1, -1), 0)

# ------------------------------------------------------------------ the rule ---

## The physical fence lasts one act; the fact this run chose one lasts across the boundary.
## Used areas in the later act still come off the route tree without another physical fence.
func _test_the_one_fence_is_remembered_after_its_act(t: TestRunner) -> void:
	var map := _maps[0]
	var fenced := Vector2i(-1, -1)
	var fenced_act := 0
	var first := Vector2i(-1, -1)
	for day in range(8, 15):
		var used := _used_by(map, day)
		var remembered := _repaint(map, day, used, fenced, fenced_act)
		fenced = remembered[0]
		fenced_act = remembered[1]
		if day == 9:
			first = map.fenced_park
			t.check(first.x >= 0 and fenced_act == 3, "the fixture chooses its fence in act III")
		if day >= 9:
			t.check(fenced == first and fenced_act == 3,
					"day %d remembers the original fence after the director's read-back" % day)
		if day >= 12:
			t.check(map.fenced_park == Vector2i(-1, -1) and map.closed_tiles.is_empty(),
					"day %d has no physical fence after the chosen act" % day)
		elif day >= 9:
			t.check(map.fenced_park == first, "the original fence stands for the rest of act III")
		if day == 13:
			t.check(not map.shut_calm().is_empty(), "act IV still excludes used areas from its routes")
	# A run with no earlier choice is still allowed its first fence in act IV.
	var used := _used_by(map, 13)
	_repaint(map, 13, used)
	t.check(map.fenced_park.x >= 0, "act IV can choose the run's first fence")

## The whole point, over the sweep: every area taken off the tree is one she used, its ground stays
## walkable and calm — open unless it is `fenced_park`, closed only if it is — and the day's tree
## neither grows a branch to it nor runs through it. Also counts how often a used area is refused —
## printed, since it is a measurement.
func _test_a_used_area_is_taken_off_the_tree_and_stays_open(t: TestRunner) -> void:
	var offered := 0
	var shut := 0
	var fenced_days := 0
	for map in _maps:
		var fenced := Vector2i(-1, -1)
		var fenced_act := 0
		for day in _days():
			var used := _used_by(map, day)
			var result := _repaint(map, day, used, fenced, fenced_act)
			fenced = result[0]
			fenced_act = result[1]
			offered += used.size()
			shut += map.shut_calm().size()
			if map.fenced_park.x >= 0:
				fenced_days += 1
			for block in map.shut_calm():
				var is_fenced := block == map.fenced_park
				# The fenced park stays off the tree by carrying over from the day it was chosen
				# (`CityMap._shut_the_spent_calm()`), not by being in every later day's own `used` —
				# once fenced she cannot settle there again, but a day she did before it was fenced
				# is still one `RunState.settled.settled_in` remembers. Every other shut area is
				# recomputed fresh from `used` each day, so it has to be in it.
				t.check(is_fenced or block in used,
						"seed %d day %d takes %s off the tree, which she used"
						% [map.seed_used, day, block])
				t.check(is_fenced != (block in map.calm_blocks),
						"seed %d day %d: %s is calm today unless it is the one fenced park"
						% [map.seed_used, day, block])
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
					if not map.is_walkable(tile):
						continue
					if is_fenced:
						t.check(map.is_closed(tile) and not map.is_open(tile),
								"seed %d day %d: %s of fenced %s is closed"
								% [map.seed_used, day, tile, block])
					else:
						t.check(not map.is_closed(tile) and map.is_open(tile),
								"seed %d day %d: %s of shut-but-not-fenced %s stays open"
								% [map.seed_used, day, tile, block])
			var tree := RouteTree.for_day(map, day)
			var shut_tiles := _shut_rect_tiles(map)
			var through := 0
			for cell in tree.cells():
				for dy in 2:
					for dx in 2:
						if shut_tiles.has(cell * 2 + Vector2i(dx, dy)):
							through += 1
			t.check(through == 0, "seed %d day %d: no route of the day runs through a used area "
					% [map.seed_used, day] + "taken off the tree (%d tiles)" % through)
			for branch in tree.branches:
				t.check(not branch.area in map.shut_calm(),
						"seed %d day %d: no branch goes to shut %s" % [map.seed_used, day, branch.area])
	t.check(shut > 0, "the sweep took some used areas off the tree (%d of %d used)"
			% [shut, offered])
	t.check(fenced_days > 0, "the sweep fenced a park on at least one day (%d)" % fenced_days)
	# `shut` can exceed `offered`: the one fenced park stays in `shut_calm` every day of the act it
	# was chosen in (see `_shut_the_spent_calm()`'s own carry-forward), while `used` only ever counts
	# the day she actually settled there — so the two are not a split of one total to subtract.
	print(("  spent parks: %d used-area day-checks taken off the tree (of %d used-area day-checks "
			+ "offered), over %d seeds x %d days; a park stood fenced on %d of those day-checks")
			% [shut, offered, SEEDS, Tuning.RUN_LENGTH_DAYS, fenced_days])

## The one fenced park's fence closes it: every edge tile with walkable ground outside it is covered
## by a barrier line lying along that edge, and every line stands on the area's own ground, never on
## the pavement beside it or past its own corner. `City._spawn_barrier()` stands a line
## `ParkClosure.barrier_width()` wide and `CLOSURE_BARRIER_DEPTH` deep at every `mouth_centres()`
## point — this is that geometry, asked of the plan rather than of a scene.
func _test_the_fenced_park_closes_every_entrance(t: TestRunner) -> void:
	var checked := 0
	var half_depth := Tuning.CLOSURE_BARRIER_DEPTH * 0.5
	for map in _maps:
		for day: int in [9, 13]:
			var used := _used_by(map, day)
			if used.is_empty():
				continue
			_force_a_fence(map, day, used)
			if map.fenced_park.x < 0:
				continue
			checked += 1
			var block := map.fenced_park
			var rect := ClosurePlanner.calm_area_rect(map, block)
			var world := map.tile_rect_to_world(rect)
			var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					_closure_rng(map, day))
			var boxes: Array[Rect2] = []
			for closure in closures:
				# Every fence that comes back is the fenced park's: `ClosurePlanner` fences no other.
				var fence := closure as ParkClosure
				if not fence:
					continue
				t.check(fence.kind == RoadClosure.Kind.PARK and
						map.network.by_key(fence.segment.key()) == null,
						"seed %d day %d: a fence is a PARK closure holding no real street"
						% [map.seed_used, day])
				var half_width := fence.barrier_width() * 0.5
				for at in fence.mouth_centres(map):
					var size := Vector2(half_width * 2.0, half_depth * 2.0) \
							if fence.barrier_runs_across() \
							else Vector2(half_depth * 2.0, half_width * 2.0)
					var box := Rect2(at - size * 0.5, size)
					boxes.append(box)
					t.check(world.grow(0.01).encloses(box),
							"seed %d day %d: a barrier of fenced %s stands on its own ground"
							% [map.seed_used, day, block])
			for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				for tile in _edge_tiles(rect, out):
					if not (map.is_walkable(tile) and map.is_walkable(tile + out)):
						continue
					# The middle of the tile's outer edge, a hair inside the area: the point a
					# pram crossing from the pavement onto this tile has to pass.
					var centre := map.tile_to_world(tile)
					var crossing := centre + Vector2(out) * (Tuning.TILE_SIZE * 0.5 - 1.0)
					var covered := false
					for box in boxes:
						if box.has_point(crossing):
							covered = true
							break
					t.check(covered, "seed %d day %d: the way in at %s of fenced %s is fenced"
							% [map.seed_used, day, tile, block])
	t.check(checked > 0, "the sweep had a fenced park to check (%d)" % checked)

## Two runs that meet at a corner of the area turn on it as one fence: each line ends exactly at
## the corner of the two fence lines (neither stops short of it nor runs past it), one post stands
## there and only one, and an end that turns no corner ends on a post of its own on its own ground.
## Asked of every calm area of every map, whether or not the sweep ever fences it, since which one
## is fenced is a matter of the day and the corners are a matter of the ground.
func _test_the_fence_turns_each_corner_on_one_post(t: TestRunner) -> void:
	var corners := 0
	var open_ends := 0
	for map in _maps:
		var none: Array[Vector2i] = []
		_repaint(map, 9, none)
		for block in map.calm_blocks:
			var fences := ParkClosure.fence(map, block)
			var posts := {}
			for fence in fences:
				for at in fence.posts(map):
					t.check(not posts.has(at), "seed %d %s: one post at %s, not two"
							% [map.seed_used, block, at])
					posts[at] = true
			for fence in fences:
				t.check(fence.barrier_width() > 0.0, "seed %d %s: a run of %s has length"
						% [map.seed_used, block, fence.segment.tile_rect()])
				# Where the line ends, worked out from its middle and its length alone (not from
				# `rail_ends()`, which the posts are built from): a joined end stands on the corner it
				# turns, an open end's post `ParkClosure.POST_HALF` in from it.
				var line := _line_ends(fence, map)
				var inward := _along(fence)
				for end: Array in [[fence.joined_start, line[0], inward],
						[fence.joined_end, line[1], -inward]]:
					var joined: bool = end[0]
					var point: Vector2 = end[1]
					if not joined:
						open_ends += 1
						var post: Vector2 = point + (end[2] as Vector2) * ParkClosure.POST_HALF
						t.check(posts.has(post),
								"seed %d %s: the open end at %s ends on its own post"
								% [map.seed_used, block, point])
						continue
					corners += 1
					var meets := 0
					for other in fences:
						var other_line := _line_ends(other, map)
						if other != fence and (other_line[0] == point or other_line[1] == point):
							meets += 1
					t.check(meets == 1, "seed %d %s: the run ending at %s meets exactly one "
							% [map.seed_used, block, point] + "other run there (%d)" % meets)
					t.check(posts.has(point), "seed %d %s: a post stands at the corner %s"
							% [map.seed_used, block, point])
	t.check(corners > 0, "the sweep had corners to turn (%d)" % corners)
	print("  fence corners: %d run ends turn a corner, %d end on a post of their own"
			% [corners, open_ends])

## The direction a fence's line runs in: across the screen along a north or south edge, down it along
## a west or east one.
func _along(fence: ParkClosure) -> Vector2:
	return Vector2.RIGHT if fence.outward.y != 0 else Vector2.DOWN

## A fence's two line ends, start first: half its length either side of its middle (`mouth_centres()`).
func _line_ends(fence: ParkClosure, map: CityMap) -> Array[Vector2]:
	var middle := fence.mouth_centres(map)[0]
	var half := _along(fence) * fence.barrier_width() * 0.5
	var found: Array[Vector2] = [middle - half, middle + half]
	return found

func _edge_tiles(rect: Rect2i, out: Vector2i) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var on_the_edge := (out == Vector2i.UP and y == rect.position.y) \
					or (out == Vector2i.DOWN and y == rect.end.y - 1) \
					or (out == Vector2i.LEFT and x == rect.position.x) \
					or (out == Vector2i.RIGHT and x == rect.end.x - 1)
			if on_the_edge:
				found.append(Vector2i(x, y))
	return found

## The guarantees hold with the one fenced park closed and the day's street closures down: at least
## `MIN_CALM_AREAS_REACHABLE` open calm areas reachable from the doorstep, and nothing that was
## reachable before the fencing cut off by it but its own ground.
func _test_the_guarantees_hold_with_the_fenced_park(t: TestRunner) -> void:
	var checked := 0
	for map in _maps:
		for day: int in [9, 12, 13, 14]:
			var used := _used_by(map, day)
			if used.is_empty():
				continue
			var home := map.world_to_tile(map.doorstep_world_position())
			var none: Array[Vector2i] = []
			_repaint(map, day, none)
			var before := map.walk_field(home)
			_force_a_fence(map, day, used)
			if map.fenced_park.x < 0:
				continue
			checked += 1
			var fenced_tiles := {}
			for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, map.fenced_park)):
				fenced_tiles[tile] = true
			var after := map.walk_field(home, map.closed_tiles)
			var cut := 0
			for index in before.size():
				var tile := Vector2i(index % map.size.x, index / map.size.x)
				if before[index] >= 0 and after[index] < 0 and not fenced_tiles.has(tile):
					cut += 1
			t.check(cut == 0, "seed %d day %d: fencing cuts nothing off but its own ground (%d tiles)"
					% [map.seed_used, day, cut])
			var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					_closure_rng(map, day))
			map.close_streets(closures)
			var barriers := map.closed_tiles.duplicate()
			for closure in closures:
				if closure is ParkClosure:
					continue
				for at_a: bool in [true, false]:
					for tile in map.rect_tiles(closure.segment.mouth_rect(at_a)):
						barriers[tile] = true
			var field := map.walk_field(home, barriers)
			var reachable := 0
			for block in map.calm_blocks:
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, block)):
					if Tile.is_calm(map.tile_at(tile)) and map.reaches(field, tile):
						reachable += 1
						break
			t.check(reachable >= ClosurePlanner.MIN_CALM_AREAS_REACHABLE,
					"seed %d day %d: %d open calm areas reachable with the park fenced and the "
					% [map.seed_used, day, reachable] + "streets closed, need %d"
					% ClosurePlanner.MIN_CALM_AREAS_REACHABLE)
	t.check(checked > 0, "the sweep had a fenced park to check guarantees against (%d)" % checked)

## A calm area she has not used is untouched: still calm, none of its ground touched by the
## shutting or the fencing, and the tree still grows it a branch wherever the tree with nothing
## shut did.
func _test_a_never_used_park_is_unaffected(t: TestRunner) -> void:
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
			if map.shut_calm().is_empty():
				continue
			var shut_tree := {}
			for branch in RouteTree.for_day(map, day).branches:
				shut_tree[branch.area] = true
			var all_calm: Array[Vector2i] = map.calm_blocks.duplicate()
			if map.fenced_park.x >= 0:
				all_calm.append(map.fenced_park)
			all_calm.append_array(map.shut_calm())
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

## The scheduler's calm-ground pass spoils every used area the tree has taken off the route —
## the day still has a clean open calm area, which dawn keeps clean before any spoiler is placed
## (`DawnCalmKeptClean`) — and places nothing inside `CityMap.fenced_park`, whose fence is the whole of
## what it shows.
func _test_the_day_spoils_every_shut_area_but_the_fenced_one(t: TestRunner) -> void:
	var offered := 0
	var spoiled := 0
	for map in _maps:
		var fenced := Vector2i(-1, -1)
		var fenced_act := 0
		for day: int in [3, 6, 10, 13]:
			var used := _used_by(map, day)
			var result := _repaint(map, day, used, fenced, fenced_act)
			fenced = result[0]
			fenced_act = result[1]
			var tree := RouteTree.for_day(map, day)
			var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					_closure_rng(map, day), tree)
			map.close_streets(closures)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("events:%d:%d" % [map.seed_used, day])
			var no_one_shots: Array[String] = []
			var no_scars: Array[Dictionary] = []
			var calm := CalmAreas.of(map, used)
			var events := GameDawn.of(DaySpec.for_day(day), rng, map).calm(calm).spent(no_one_shots) \
					.scars(no_scars).on(tree).plan()
			var planned := events.placements()
			if map.fenced_park.x >= 0:
				var fenced_tiles := {}
				for tile in map.rect_tiles(ClosurePlanner.calm_area_rect(map, map.fenced_park)):
					fenced_tiles[tile] = true
				for plan in planned:
					if not plan.is_placed():
						continue
					t.check(not fenced_tiles.has(map.world_to_tile(plan.position)),
							"seed %d day %d: '%s' is not placed inside the fenced park"
							% [map.seed_used, day, plan.def.id])
			for block in used:
				if block == map.fenced_park or not block in calm.blocks():
					continue
				offered += 1
				if events.is_spoiled(block):
					spoiled += 1
				t.check(events.is_spoiled(block), "seed %d day %d: the used area %s is spoiled"
						% [map.seed_used, day, block])
				t.check(_a_body_stands_inside(map, events, calm, block),
						"seed %d day %d: something stands inside the used area %s at the end of the plan"
						% [map.seed_used, day, block])
			var clean := 0
			for block in calm.blocks():
				if not events.is_spoiled(block):
					clean += 1
			t.check(clean >= 1, "seed %d day %d leaves an open calm area clean"
					% [map.seed_used, day])
	t.check(offered > 0, "the sweep had used, open areas to spoil (%d)" % offered)
	print("  spent parks: %d of %d used-and-open areas were spoiled with events" % [spoiled, offered])

## Whether a plan that spoils `block`'s lot (`EventPlan.spoils()`: not a playground, not a scar) stands
## inside it as the day's plan ends: what shuts a used area is the events placed in it (PLAYTEST-140
## 8), not a field reaching in from outside.
func _a_body_stands_inside(map: CityMap, events: DayEvents, calm: CalmAreas, block: Vector2i) -> bool:
	var lot := map.tile_rect_to_world(calm.rect_of(block))
	for plan in events.placements():
		if plan.spoils(lot) and lot.has_point(plan.placed_at()):
			return true
	return false

## **A used area keeps what the spoil pass put in it.** A row handed to her walk
## (`EventDef.is_handed_to_her_walk()`) stands where her walk sites it, so a spoiler of that kind
## would leave the area it spoiled empty; the spoil pass offers none
## (`DawnSpoilers._things_to_put_in_a_park()`). The city is the one where that happened: seed
## 61823 on day 14, with the four-tile courtyard at block (3, 2) used yesterday, whose one spoiler
## was the sidewalk `poster_crew`.
func _test_a_used_courtyard_keeps_what_was_put_in_it(t: TestRunner) -> void:
	var map := CityGenerator.generate(61823)
	var day := 14
	var block := Vector2i(3, 2)
	var used: Array[Vector2i] = [block]
	# Repainted with the area handed over and nothing fenced before, the run as it stood that day.
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.set_spent_calm(used)
	map.repaint(state)
	var tree := RouteTree.for_day(map, day)
	map.close_streets(ClosurePlanner.plan_day(map, DaySpec.for_day(day), _closure_rng(map, day), tree))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("events:%d:%d" % [map.seed_used, day])
	var calm := CalmAreas.of(map, used)
	t.check(block in calm.blocks() and block != map.fenced_park,
			"the courtyard is a counted, unfenced calm area that day")
	var no_one_shots: Array[String] = []
	var no_scars: Array[Dictionary] = []
	var events := GameDawn.of(DaySpec.for_day(day), rng, map).calm(calm).spent(no_one_shots) \
			.scars(no_scars).on(tree).plan()
	t.check(_a_body_stands_inside(map, events, calm, block),
			"something stands inside the used courtyard at the end of the plan")
	map.close_streets([])

## **With every calm area she could settle in used this act, one is still clean**: the day she has
## settled in all of them is the one the calm rule protects nothing on, so dawn keeps one clean by
## construction before the spoilers are placed (`DawnCalmKeptClean`), and the plan
## has some counted calm area nothing reaches. Days 5, 9 and 14, the used order the one an act
## would have.
func _test_with_every_area_used_one_stays_clean(t: TestRunner) -> void:
	var asked := 0
	for map in _maps:
		for day: int in [5, 9, 14]:
			var used := _calm_on(map, day)
			_repaint(map, day, used)
			var tree := RouteTree.for_day(map, day)
			map.close_streets(ClosurePlanner.plan_day(map, DaySpec.for_day(day),
					_closure_rng(map, day), tree))
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("events:%d:%d" % [map.seed_used, day])
			var no_one_shots: Array[String] = []
			var no_scars: Array[Dictionary] = []
			var calm := CalmAreas.of(map, used)
			if not calm.unused().is_empty():
				continue
			asked += 1
			var events := GameDawn.of(DaySpec.for_day(day), rng, map).calm(calm).spent(no_one_shots) \
					.scars(no_scars).on(tree).plan()
			var clean := 0
			for block in calm.blocks():
				if block != calm.besides() and not events.is_spoiled(block):
					clean += 1
			t.check(clean >= 1, "seed %d day %d, every area used: one calm area is clean (%d)"
					% [map.seed_used, day, clean])
	t.check(asked > 0, "the sweep had days with every calm area used (%d)" % asked)

## With every calm area handed over as used, the tree takes as many off as it may and no more: at
## least `MIN_CALM_AREAS_REACHABLE` of them are never excluded, and only the one fenced park, if any,
## actually leaves `calm_blocks`.
func _test_shutting_is_refused_rather_than_breaking_a_guarantee(t: TestRunner) -> void:
	for map in _maps:
		for day: int in [1, 5, 9, 12, 14]:
			var calm := _calm_on(map, day)
			_repaint(map, day, calm, Vector2i(-1, -1), 0)
			t.check(calm.size() - map.shut_calm().size() >= ClosurePlanner.MIN_CALM_AREAS_REACHABLE,
					"seed %d day %d: %d of %d calm areas kept fully on the tree, need %d"
					% [map.seed_used, day, calm.size() - map.shut_calm().size(), calm.size(),
					ClosurePlanner.MIN_CALM_AREAS_REACHABLE])
			var fenced_count := 1 if map.fenced_park.x >= 0 else 0
			t.check(map.calm_blocks.size() == calm.size() - fenced_count,
					"seed %d day %d: only the fenced park, if any, leaves calm_blocks (%d calm, "
					% [map.seed_used, day, calm.size()] + "%d left, fenced %s)"
					% [map.calm_blocks.size(), map.fenced_park])

## Day 12's park is where the day's task is, so it is never taken off the tree or fenced on its day,
## even when she used it.
func _test_the_swing_park_is_never_shut_or_fenced_on_its_day(t: TestRunner) -> void:
	var day := ResistanceSteps.swing_day()
	t.check(day > 0, "the calendar has a swing day")
	if day <= 0:
		return
	for map in _maps:
		var park := CityGenerator.swing_park(map)
		var used: Array[Vector2i] = [park]
		_force_a_fence(map, day, used)
		t.check(not park in map.shut_calm() and park != map.fenced_park and park in map.calm_blocks,
				"seed %d: the swing park %s stays open and unfenced on day %d"
				% [map.seed_used, park, day])

## The same handover shuts and fences the same areas, and a repaint with no handover shuts and
## fences nothing — the escape's own repaint, and every rig that never hands one over.
func _test_shutting_is_deterministic_and_forgotten_by_the_next_repaint(t: TestRunner) -> void:
	for map: CityMap in _maps.slice(0, 3):
		var cmap: CityMap = map
		for day: int in [3, 7, 11]:
			var used := _used_by(cmap, day)
			_repaint(cmap, day, used)
			var first: Array[Vector2i] = cmap.shut_calm().duplicate()
			var first_fenced := cmap.fenced_park
			_repaint(cmap, day, used)
			t.check(first == cmap.shut_calm(), "seed %d day %d shuts the same parks twice"
					% [cmap.seed_used, day])
			t.check(first_fenced == cmap.fenced_park, "seed %d day %d fences the same park twice"
					% [cmap.seed_used, day])
			var state := CityState.new()
			state.begin_day(cmap.block_plans, day)
			cmap.repaint(state)
			t.check(cmap.shut_calm().is_empty() and cmap.closed_tiles.is_empty() \
					and cmap.fenced_park == Vector2i(-1, -1),
					"seed %d day %d: a repaint with nothing handed over shuts and fences nothing"
					% [cmap.seed_used, day])

## Every closure picture the city stands, found the way any node is: down the city's own subtree,
## where `City` hands each piece to the entities layer (`add_entity()`) and to the scenery.
func _closure_markers(node: Node, into: Array[ClosureMarker]) -> Array[ClosureMarker]:
	for child in node.get_children():
		if child is ClosureMarker:
			into.append(child as ClosureMarker)
		_closure_markers(child, into)
	return into

## Whether the physics world holds anything solid at `point`, asked the way a mover is stopped by
## it. The world takes a body in on the physics tick after it enters the tree.
func _solid_at(node: Node2D, point: Vector2) -> bool:
	var probe := CircleShape2D.new()
	probe.radius = 0.5
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = probe
	query.transform = Transform2D(0.0, point)
	return not node.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

## The real `City` stands one static body behind every fence line, where `ParkClosure` says: the
## one fenced park has a body across every way in, the same body a closed street's mouth has. The
## bodies are asked of the physics world, which is what stops her.
func _test_the_city_stands_a_barrier_body_along_the_fenced_park(t: TestRunner) -> void:
	var run := RunState.new()
	run.start_run(BASE_SEED)
	var city: City = RunCity.in_run(CITY_SCENE, run)
	t.add_child(city)
	city.build(CityGenerator.generate(BASE_SEED))
	var day := 9
	var state := CityState.new()
	state.begin_day(city.map.block_plans, day)
	city.map.repaint(state)
	var calm: Array[Vector2i] = city.map.calm_blocks.duplicate()
	t.check(calm.size() >= 1, "seed %d day %d has a calm area to use (%d)"
			% [city.map.seed_used, day, calm.size()])
	if calm.is_empty():
		city.free()
		return
	var used: Array[Vector2i] = [calm[0]]
	city.map.set_spent_calm(used)
	city.map.set_fenced_park_state(Vector2i(-1, -1), 0, 3)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("spent-park:closures:%d" % day)
	city.start_day(state, day, rng)
	t.check(city.map.fenced_park.x >= 0, "the city fenced the park it was handed (%s)"
			% [city.map.fenced_park])
	if city.map.fenced_park.x < 0:
		city.free()
		return
	var park_pictures := 0
	for marker in _closure_markers(city, []):
		if marker.kind == RoadClosure.Kind.PARK:
			park_pictures += 1
			t.check(marker is ParkFenceMarker,
					"the real city draws park pieces with the connected fence renderer")
		else:
			t.check(not marker is ParkFenceMarker,
					"street closures retain their own barrier renderer")
	t.check(park_pictures > 0, "the fenced park has runtime pictures to check")
	await PhysicsTicks.pass_ticks(t, 1)
	var block := city.map.fenced_park
	var rect := ClosurePlanner.calm_area_rect(city.map, block)
	var entrances := 0
	for out: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		for tile in _edge_tiles(rect, out):
			if not (city.map.is_walkable(tile) and city.map.is_walkable(tile + out)):
				continue
			entrances += 1
			var crossing := city.map.tile_to_world(tile) \
					+ Vector2(out) * (Tuning.TILE_SIZE * 0.5 - 1.0)
			t.check(_solid_at(city, crossing),
					"a body stands across the way in at %s of fenced %s" % [tile, block])
	t.check(entrances > 0, "fenced %s has ways in to stand bodies across" % block)
	var fenced: Array[RoadClosure] = city.streets().closures().duplicate()
	city.free()
	_test_the_fence_pieces_stand_in_draw_order(t, fenced)

## The fence's pictures, drawn for the closures a recipe hands the city (`recipe_closures`, which
## `start_recipe_day()` stands): the park's own runs and a short archway besides. End-on terminal
## panels share the post's exact anchor: subpixel drift can reverse their draw order. The mounted
## sign has its own midpoint support on either axis.
func _test_the_fence_pieces_stand_in_draw_order(t: TestRunner, fenced: Array[RoadClosure]) -> void:
	var run := RunState.new()
	run.start_run(BASE_SEED)
	var city: City = RunCity.in_run(CITY_SCENE, run)
	t.add_child(city)
	var map := CityGenerator.generate(BASE_SEED)
	var short_run := ParkClosure.new(Vector2i.ZERO, Rect2i(117, 121, 4, 4),
			Rect2i(120, 122, 1, 1), Vector2i.RIGHT)
	map.recipe_closures.append_array(fenced)
	map.recipe_closures.append(short_run)
	city.build(map)
	var day := 9
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	city.start_recipe_day(state, day, run.calendar.day_rng(day, "closures"))
	var shared_panel_posts := 0
	var short_end := short_run.posts(city.map).back() as Vector2
	var short_end_checked := false
	var sign_centers := {}
	for closure in city.streets().closures():
		if closure is ParkClosure:
			for center in closure.mouth_centres(city.map):
				sign_centers[center] = true
	var markers := _closure_markers(city, [])
	for marker in markers:
		if not marker is ParkFenceMarker:
			continue
		var fence_marker := marker as ParkFenceMarker
		if fence_marker.piece == ClosureMarker.Piece.SIGN:
			var sign_ground := fence_marker.position + fence_marker.sign_offset
			t.check(sign_centers.has(sign_ground),
					"each park sign stands at one run's exact midpoint")
			sign_centers.erase(sign_ground)
		if fence_marker.across or fence_marker.piece == ClosureMarker.Piece.POST:
			continue
		for other in markers:
			var post := other as ParkFenceMarker
			if not post or post.piece != ClosureMarker.Piece.POST:
				continue
			if fence_marker.position.distance_to(post.position) < 0.01:
				shared_panel_posts += 1
				t.check(fence_marker.position == post.position,
						"an endpoint rail and its post share exactly one ground anchor")
				if post.position == short_end:
					short_end_checked = true
					t.check(post.get_index() < fence_marker.get_index(),
							"the unjoined archway support draws behind its rail and mounted sign")
	t.check(shared_panel_posts > 0, "the scene includes an end-on terminal panel and post")
	t.check(short_end_checked, "the short archway's support order is exercised")
	t.check(sign_centers.is_empty(), "every park fence run has exactly one centered mounted sign")
	city.free()
