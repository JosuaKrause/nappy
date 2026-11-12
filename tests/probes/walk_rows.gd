@warning_ignore_start("untyped_declaration")
extends RefCounted
## Measurement probe for the walk's mix (`docs/EVENTS.md`, "The density, and why it is caps and
## bags"): **what each day puts in the world as she walks, row by row, by view and by kind of
## ground.** Not a suite: it prints rather than asserting, so it lives here under `tests/probes/`,
## where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/walk_rows.gd
##
## Each day is planned as `placement_rows.gd` plans it, and then walked: the day's longest route
## out from the doorstep and home again, at walking speed, a tick a thirtieth of a second, with the
## director siting what it sites on her way (`EventDirector.due()`,
## `site_what_is_on_her_way()`). A placed row counts once it comes within the stream radius of her
## (`Tuning.EVENT_STREAM_RADIUS`), the moment it would stream in, under its row, its view and its
## kind of ground: a row the director sites on her way among them, once sited (a poster crew), but
## not a place her route's bag hands it. It asks only what every tree has, so the same file
## measures main and a branch alike. Prints `WD day seeds streamed`, `WV day row view count`,
## `WK day row kind count` and `WM day met at-the-door late-out`, where the capped rows are met
## (`CAPPED`: within the stream radius of her door, and in the second half of the walk out), summed
## over the seeds, and per seed and day `WT day seed siting ticks median p99 worst total`, the
## director's siting's tick costs in microseconds, and `WP day seed microseconds`, the dawn's
## planning of each (`EventScheduler.build_day()`). Each day is planned as the game plans it: its
## closures, holds, region wall and seals first, the seals and the wall's bodies handed in as
## standing.
##
## **And whether the day's routes stay open, which no rule floods the city to keep** (`RouteGroundRule`
## and the line rules of `StreetInvalidation` keep them by construction): per day, summed over the
## seeds, `WC day dawn walk`, the route tiles (`Corridor.carries_a_route()`) home reached among the
## day's closures that it no longer reaches among the day's obstructing bodies (`EventPlan.obstructs()`)
## and that no body's disc covers, counted once after the dawn's plan (its rows, the seals and the
## region wall's bodies) and once at the end of her walk (everything the walk then holds, what it
## sited included), so a tile cut off names which half placed the body; `WC all dawn walk` sums the
## days. Each such tile prints `WX day seed half tile kind rows`, the rows being the bodies whose
## taking away alone gives it back (`jointly` where none does). The expected count is none.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]
## A tick of her walk, in seconds.
const TICK := 1.0 / 30.0
## The rows whose caps bound what she meets, the dawn drawing the whole city, for the `WM` lines.
const CAPPED := ["abduction", "alley_mouse", "charging_dog", "chatting_mother", "pigeon_flock",
		"roadblock"]

func run(t: TestRunner) -> void:
	var all_cut_at_dawn := 0
	var all_cut_after_walk := 0
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		# Where on her walk the capped rows are met: within the stream radius of her door at the
		# start, and in the second half of the walk out.
		var capped_met := 0
		var capped_at_the_door := 0
		var capped_late_out := 0
		# Route tiles cut off from home, after the dawn's plan and at the end of her walk.
		var cut_at_dawn := 0
		var cut_after_walk := 0
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
			var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary,
					map.held_streets())
			for seal in seals:
				seal.stand_as_a_seal()
			var doors := PackedVector2Array()
			for body in region_plan.door_bodies:
				doors.append(body.position)
			var standing: Array[EventPlan] = []
			standing.append_array(seals)
			standing.append_array(region_plan.wall_bodies)
			for body in region_plan.wall_bodies:
				body.stand_in_the_wall()
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
			var guarded := ResistanceSteps.guarded_row_on(day)
			var consumed: Array[String] = []
			var planned_from := Time.get_ticks_usec()
			var events = EventScheduler.build_day(spec, rng, map, CalmAreas.of(map), sites,
					consumed, [], tree, 0, doors, standing, null,
					EventCatalogue.by_id(guarded) if guarded != "" else null)
			print("WP %d %d %d" % [day, i, Time.get_ticks_usec() - planned_from])
			var plans: Array[EventPlan] = events.placements()
			plans.append_array(seals)
			plans.append_array(region_plan.wall_bodies)
			var grid := ReachabilityGrid.build(map)
			var routes: Array[Vector2i] = []
			for y in map.size.y:
				for x in map.size.x:
					if corridor.carries_a_route(Vector2i(x, y)):
						routes.append(Vector2i(x, y))
			var reached_bare := grid.flood([map.home_tile()], map.closed_tiles)
			cut_at_dawn += _report_cut_off(map, grid, routes, reached_bare, plans, day, i, "dawn")
			var walk := WalkEvents.new()
			walk.take(plans, CalmAreas.of(map), doors)
			# The walk's sitings are judged against the walk itself, as the game's are.
			var siting := EventScheduler.WalkSiting.new(day, map, tree, walk,
					EventScheduler.Verdicts.new())
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
			var door: Vector2 = path[0]
			var out_length := 0.0
			for k in range(1, route.size()):
				out_length += (route[k] as Vector2).distance_to(route[k - 1])
			var walked := 0.0
			var counted := {}
			var siting_ticks: Array[int] = []
			var tick := 0
			for k in range(1, path.size()):
				var toward: Vector2 = path[k] - at
				while toward.length() > Tuning.WALK_SPEED * TICK:
					var heading := toward.normalized()
					var velocity := heading * Tuning.WALK_SPEED
					at += velocity * TICK
					walked += Tuning.WALK_SPEED * TICK
					tick += 1
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
								if CAPPED.has(plan.row_id()):
									capped_met += 1
									if plan.placed_at().distance_to(door) \
											<= Tuning.EVENT_STREAM_RADIUS:
										capped_at_the_door += 1
									if walked > out_length * 0.5 and walked <= out_length:
										capped_late_out += 1
					toward = path[k] - at
			for plan: EventPlan in counted:
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
			cut_after_walk += _report_cut_off(map, grid, routes, reached_bare, walk.plans(), day, i,
					"walk")
			print("WT %d %d siting %s" % [day, i, _costs(siting_ticks)])
		print("WD %d %d %d" % [day, SEEDS, placed])
		print("WC %d %d %d" % [day, cut_at_dawn, cut_after_walk])
		all_cut_at_dawn += cut_at_dawn
		all_cut_after_walk += cut_after_walk
		print("WM %d %d %d %d" % [day, capped_met, capped_at_the_door, capped_late_out])
		for key: String in by_view:
			print("WV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("WK %d %s %d" % [day, key, by_kind[key]])
	print("WC all %d %d" % [all_cut_at_dawn, all_cut_after_walk])
	t.check(true, "walk probe ran")

## How many of `routes` home reached among the day's closures (`reached_bare`) that it no longer
## reaches among the bodies of `plans` and that no body's disc covers, each printed as a `WX` line
## with the kind of ground it is and the rows whose taking away alone gives it back.
static func _report_cut_off(map: CityMap, grid: ReachabilityGrid, routes: Array[Vector2i],
		reached_bare: Dictionary, plans: Array[EventPlan], day: int, seed_index: int,
		half: String) -> int:
	var bodies: Array[EventPlan] = []
	for plan in plans:
		if plan.obstructs():
			bodies.append(plan)
	var cut := _cut_off(map, grid, routes, reached_bare, bodies)
	if cut.is_empty():
		return 0
	var restores := {}
	for body in bodies:
		var others: Array[EventPlan] = bodies.duplicate()
		others.erase(body)
		var still := _cut_off(map, grid, cut, reached_bare, others)
		for tile in cut:
			if not still.has(tile):
				var names: Array = restores.get(tile, [])
				names.append("%s@%s" % [body.row_id(), map.world_to_tile(body.placed_at())])
				restores[tile] = names
	for tile in cut:
		var names: Array = restores.get(tile, ["jointly"])
		print("WX %d %d %s %s %s %s" % [day, seed_index, half, tile, _kind_of(map, tile),
				" ".join(names)])
	return cut.size()

## The tiles of `routes` home reached among the day's closures (`reached_bare`) that it does not
## reach among `bodies` and that no body's disc covers.
static func _cut_off(map: CityMap, grid: ReachabilityGrid, routes: Array[Vector2i],
		reached_bare: Dictionary, bodies: Array[EventPlan]) -> Array[Vector2i]:
	var blocked := EventScheduler.blocked_by(map, bodies)
	var reached := grid.flood([map.home_tile()], blocked)
	var cut: Array[Vector2i] = []
	for tile in routes:
		if not blocked.has(tile) and grid.reaches(tile, map.closed_tiles, reached_bare) \
				and not grid.reaches(tile, blocked, reached):
			cut.append(tile)
	return cut

## The day's longest route as the line she walks, out from the doorstep: a route is grown from the
## area to the doorstep, so the walk out is the route reversed.
static func _longest_route(tree: RouteTree,
		siting: EventScheduler.WalkSiting) -> PackedVector2Array:
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var points := PackedVector2Array()
	for k in best.size():
		points.append(siting.cell_centre(best[best.size() - 1 - k]))
	return points

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
