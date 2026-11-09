extends RefCounted
## Measurement probe for the walk's mix (`docs/EVENTS.md`, "The density, and why it is caps and
## bags"): **what each day puts in the world as she walks, row by row, by view and by kind of
## ground.** Not a suite: it
## prints rather than asserting, so it lives here under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/walk_rows.gd
##
## Each day is planned as `placement_rows.gd` plans it, and then walked: the day's longest route out
## from the doorstep and home again, at walking speed, a tick a thirtieth of a second, with the
## director siting what it sites on her way (`EventDirector.due()`, `site_what_is_on_her_way()`) and,
## where the tree draws its locations during the walk (`WalkDraw`), the walk's draw ahead of her. A
## placed row counts once it comes within the stream radius of her (`Tuning.EVENT_STREAM_RADIUS`),
## the moment it would stream in, under its row, its view and its kind of ground; the director's own
## sitings are not counted. It asks only what every tree has, and the walk's draw by name where the
## tree has one, so the same file measures main and a branch alike. Prints `WD day seeds streamed`,
## `WV day row view count` and `WK day row kind count`, summed over the seeds, and per seed and day
## `WT` lines of the tick costs, in microseconds: the walk's draw (`draw`) and the director's siting
## (`siting`), each `ticks median p99 worst total`. Each day is planned as the game plans it: its closures, holds, region wall and
## seals first, the seals and the wall's bodies handed in as standing.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]
## A tick of her walk, in seconds.
const TICK := 1.0 / 30.0

func run(t) -> void:
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		var moments := 0
		for i in SEEDS:
			var map := CityGenerator.generate(BASE + i * STEP)
			# The run's mast sites, worked out once on the city as built, as the game does.
			var sites := MastSites.compute(map)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var spec := DaySpec.for_day(day)
			# The day's own closures, holds, region wall and seals, planned as the game plans them
			# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
			# stand as the day's standing and hold their locations.
			var region_plan := RegionPlanner.plan_day(map, spec, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
			var closures := ClosurePlanner.plan_day(map, spec, closure_rng, tree, region_plan)
			map.close_streets(closures)
			map.clear_day_holds()
			for closure: RoadClosure in closures:
				map.hold_segment(closure.segment.key(), HeldStreets.Why.CLOSURE)
			for segment: StreetNetwork.Segment in region_plan.walls:
				map.hold_segment(segment.key(), HeldStreets.Why.WALL)
			for segment: StreetNetwork.Segment in region_plan.doors:
				map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
			for segment: StreetNetwork.Segment in map.network.around_blocks(
					Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key(), HeldStreets.Why.HOME)
			var boundary := {}
			for segment in region_plan.walls:
				boundary[segment.key()] = true
			for segment in region_plan.doors:
				boundary[segment.key()] = true
			for rect in region_plan.alley_walls:
				boundary[rect.position] = true
			for rect in region_plan.alley_doors:
				boundary[rect.position] = true
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
			var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary, map.held_streets())
			for seal in seals:
				seal.stand_as_a_seal()
			var doors := PackedVector2Array()
			for body in region_plan.door_bodies:
				doors.append(body.position)
			var standing: Array[EventScheduler.Planned] = []
			standing.append_array(seals)
			standing.append_array(region_plan.wall_bodies)
			for body in region_plan.wall_bodies:
				body.stand_in_the_wall()
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
			var guarded := ResistanceSteps.guarded_row_on(day)
			var consumed: Array[String] = []
			var events = EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), sites,
					consumed, [], tree, 0, doors, standing, null,
					EventCatalogue.by_id(guarded) if guarded != "" else null)
			var plans: Array[EventScheduler.Planned] = events.placements()
			plans.append_array(seals)
			plans.append_array(region_plan.wall_bodies)
			var walk_draw = events.call("walk_draw") if events.has_method("walk_draw") else null
			var walk := WalkEvents.new()
			walk.take(plans, CalmAreas.of(map), doors)
			var fake := FakeWalkEvents.new()
			fake.set_plans(plans)
			fake.set_calm(CalmAreas.of(map))
			var siting := EventScheduler.WalkSiting.new(day, map, tree, fake, EventScheduler.Verdicts.new())
			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("walk_rows director:%d:%d" % [i, day])
			director.start_day(day, plans, director_rng, siting)
			var route := _longest_route(tree, siting)
			if route.size() < 2:
				continue
			var path := route.duplicate()
			var back := route.duplicate()
			back.reverse()
			path.append_array(back)
			var at: Vector2 = path[0]
			var counted := {}
			var draw_ticks: Array[int] = []
			var siting_ticks: Array[int] = []
			var open_before := 0
			if walk_draw:
				open_before = events.call("locations").open_locations().size()
				walk_draw.judge_against(walk)
				for drawn in walk_draw.draw_within(at, walk_draw.MUST_DRAW):
					walk.add(drawn)
			var tick := 0
			for k in range(1, path.size()):
				var toward: Vector2 = path[k] - at
				while toward.length() > Tuning.WALK_SPEED * TICK:
					var heading := toward.normalized()
					var velocity := heading * Tuning.WALK_SPEED
					at += velocity * TICK
					tick += 1
					var her := at
					var sees := func(rect: Rect2) -> bool: return _view_of(her).intersects(rect)
					if walk_draw:
						var t0 := Time.get_ticks_usec()
						var drawn_now: Array = walk_draw.draw_ahead(at, heading, sees)
						draw_ticks.append(Time.get_ticks_usec() - t0)
						for drawn in drawn_now:
							walk.add(drawn)
					var t1 := Time.get_ticks_usec()
					director.due(TICK, at, velocity)
					director.site_what_is_on_her_way(TICK, at, velocity)
					siting_ticks.append(Time.get_ticks_usec() - t1)
					if tick % 10 == 0:
						for plan in walk.plans():
							if counted.has(plan) or not plan.is_placed() or plan.is_a_fixed_part():
								continue
							if plan.placed_at().distance_to(at) <= Tuning.EVENT_STREAM_RADIUS:
								counted[plan] = true
					toward = path[k] - at
			for plan: EventScheduler.Planned in counted:
				var mode := plan.def.spawn_mode_on(day)
				if mode != EventDef.SpawnMode.MAP:
					moments += 1
					continue
				placed += 1
				var tile := map.world_to_tile(plan.placed_at())
				var segment := map.network.segment_containing(tile)
				var view := 0
				if segment:
					view = corridor.view_of(segment)
				else:
					var d := corridor.depth(tile)
					view = 0 if d == 0 else (1 if d == 1 else 2)
				var kv := "%s %d" % [plan.row_id(), view]
				by_view[kv] = int(by_view.get(kv, 0)) + 1
				var kk := "%s %s" % [plan.row_id(), _kind_of(map, tile)]
				by_kind[kk] = int(by_kind.get(kk, 0)) + 1
			print("WT %d %d draw %s" % [day, i, _costs(draw_ticks)])
			print("WT %d %d siting %s" % [day, i, _costs(siting_ticks)])
			if walk_draw:
				var drawn_on_the_walk: int = open_before - events.call("locations").open_locations().size()
				print("WF %d %d forced %d drawn %d ticks %d" % [day, i, walk_draw.forced(),
						drawn_on_the_walk, tick])
		print("WD %d %d %d %d" % [day, SEEDS, placed, moments])
		for key: String in by_view:
			print("WV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("WK %d %s %d" % [day, key, by_kind[key]])
	t.check(true, "walk probe ran")

## The day's longest route as the line she walks, out from the doorstep: a route is grown from the
## area to the doorstep, so the walk out is the route reversed.
static func _longest_route(tree: RouteTree, siting: EventScheduler.WalkSiting) -> PackedVector2Array:
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for k in best.size():
		points.append(siting.cell_centre(best[best.size() - 1 - k]))
	return points

## What she sees from `her`: the view and the camera's lead, as a siting's own check reads it
## (`EventScheduler.WalkSiting.could_be_in_her_view()`).
static func _view_of(her: Vector2) -> Rect2:
	var lead := Vector2(Stroller.CAMERA_LOOK_AHEAD,
			Stroller.CAMERA_LOOK_AHEAD * Stroller.OBLIQUE_Y) + Vector2.ONE * Tuning.TILE_SIZE
	return Rect2(her - Tuning.VIEW_HALF_EXTENT - lead, (Tuning.VIEW_HALF_EXTENT + lead) * 2.0)

## `ticks median p99 worst total` of `ticks`, in microseconds; zeros for none.
static func _costs(ticks: Array[int]) -> String:
	if ticks.is_empty():
		return "0 0 0 0 0"
	var sorted := ticks.duplicate()
	sorted.sort()
	var total := 0
	for value in sorted:
		total += value
	return "%d %d %d %d %d" % [sorted.size(), sorted[sorted.size() / 2],
			sorted[mini(sorted.size() - 1, int(sorted.size() * 0.99))], sorted[-1], total]

static func _kind_of(map: CityMap, tile: Vector2i) -> String:
	if CityMap.junction_at(tile) != Vector2i(-1, -1):
		return "junction"
	match map.tile_at(tile):
		GameEnums.TileType.ALLEY:
			return "alley"
		GameEnums.TileType.PARK, GameEnums.TileType.SQUARE:
			return "open"
		GameEnums.TileType.ROAD:
			return "carriageway"
		GameEnums.TileType.SIDEWALK:
			return "sidewalk"
	return "other"
