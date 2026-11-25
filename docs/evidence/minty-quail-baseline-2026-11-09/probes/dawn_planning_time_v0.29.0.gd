extends RefCounted
## COPY of placement_rows_v0.29.0.gd (this folder) with SEEDS = 14 and a timer around the one EventScheduler.build_day() call per
## city and day (microseconds summed, printed once as DAWN_PLANNING). Everything else is the original's.
## Dawn planning time as grassy-magpie measured it: 14 cities x 14 days, time inside build_day().
## CUT-DOWN COPY of today's tests/probes/placement_rows.gd (origin/main 38ce03823) for the tree of
## v0.29.0, which has no such probe. Run as tests/probes/placement_rows_v0_29_0.gd in that checkout.
## Same cities (SEEDS, BASE, STEP), same day loop, same output lines (RD / RV / RK), same view
## rule and same kinds of ground. What differs, because v0.29.0 has none of it:
##  - build_day takes the day number, not a DaySpec; there is no CalmAreas argument and no
##    guarded-row argument (ResistanceSteps.guarded_row_on does not exist), so none is passed.
##  - the day's closures, holds, region wall and seals are planned in the order EventManager.start_day
##    and City._close_streets use at v0.29.0; seals and the wall's bodies are handed in as `standing`.
##    The seals do not get stand_as_a_seal() and the wall bodies not stand_in_the_wall() (no such calls).
##  - Corridor.view_of() does not exist; the view is Corridor.view_of()'s rule written out with what
##    v0.29.0 has: a street whose depth is 0 is "on her route" (0); else, one of its two junctions
##    in Corridor.route_junctions() makes it "route-adjacent" (1); else off (2). Ground without a
##    street keeps depth 0 / 1 / 2+, as in today's probe.
##  - StreetNetwork is static there (StreetNetwork.segment_containing, not map.network).

const SEEDS := 14
const BASE := 90210
const STEP := 31

func run(t) -> void:
	var build_usec := 0
	var whole_began := Time.get_ticks_usec()
	for day in range(1, 15):
		var by_view := {}
		var by_kind := {}
		var placed := 0
		var moments := 0
		for i in SEEDS:
			var map := CityGenerator.generate(BASE + i * STEP)
			var sites := MastSites.compute(map)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)
			map.clear_day_holds()
			for closure: RoadClosure in closures:
				map.hold_segment(closure.segment.key())
			for segment: StreetNetwork.Segment in region_plan.walls:
				map.hold_segment(segment.key())
			for segment: StreetNetwork.Segment in region_plan.doors:
				map.hold_segment(segment.key())
			for segment: StreetNetwork.Segment in StreetNetwork.around_blocks(
					Rect2i(map.home_block, Vector2i.ONE)):
				map.hold_segment(segment.key())
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
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary, map.held_segments)
			var doors := PackedVector2Array()
			for body in region_plan.door_bodies:
				doors.append(body.position)
			var standing: Array[EventScheduler.Planned] = []
			standing.append_array(seals)
			standing.append_array(region_plan.wall_bodies)
			var corridor := Corridor.of(tree)
			var beside := {}
			for junction in corridor.route_junctions():
				beside[junction] = true
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
			var consumed: Array[String] = []
			var began := Time.get_ticks_usec()
			var built := EventScheduler.build_day(day, rng, map, consumed, [], [] as Array[Vector2i],
					tree, 0, doors, [] as Array[Vector2i], standing)
			build_usec += Time.get_ticks_usec() - began
			for plan in built:
				var mode := plan.def.spawn_mode_on(day)
				if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER:
					moments += 1
					continue
				if not plan.is_placed():
					continue
				placed += 1
				var tile := map.world_to_tile(plan.position)
				var segment := StreetNetwork.segment_containing(tile)
				var view := 0
				if segment:
					if corridor.depth(tile) == 0:
						view = 0
					elif beside.has(segment.a) or beside.has(segment.b):
						view = 1
					else:
						view = 2
				else:
					var d := corridor.depth(tile)
					view = 0 if d == 0 else (1 if d == 1 else 2)
				var kind := _kind_of(map, tile)
				var id := plan.def.id
				var kv := "%s %d" % [id, view]
				by_view[kv] = int(by_view.get(kv, 0)) + 1
				var kk := "%s %s" % [id, kind]
				by_kind[kk] = int(by_kind.get(kk, 0)) + 1
		print("RD %d %d %d %d" % [day, SEEDS, placed, moments])
		for key: String in by_view:
			print("RV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("RK %d %s %d" % [day, key, by_kind[key]])
	print("DAWN_PLANNING build_day_sec %.3f whole_probe_sec %.3f cities %d days 14" % [build_usec / 1e6, (Time.get_ticks_usec() - whole_began) / 1e6, SEEDS])
	t.check(true, "dawn planning probe ran")

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
