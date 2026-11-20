extends RefCounted
## COPY of tests/probes/placement_rows.gd (4da1e5285) with SEEDS = 14 and timers around the dawn's planning
## (microseconds summed, printed once as DAWN_PLANNING). Everything else is the original's.
## Dawn planning time as grassy-magpie measured it: 14 cities x 14 days, time inside the one call that plans a day.
## What changed against `probes/dawn_planning_time_today.gd` (the copy of the tree of 38ce03823), and why:
##  - That copy timed `EventScheduler.build_day(spec, rng, map, ...)`, a call that no longer exists: at
##    4da1e5285 `EventScheduler.build_day(context: DawnContext)` plans into a context, and
##    `EventScheduler.Planned` is `EventPlan` (so the copy did not parse). The tree's own probe makes the
##    context with `GameDawn` (`tests/game_dawn.gd`, the one place under tests/ that hands a dawn its inputs).
##  - The timer wraps `EventScheduler.build_day(dawn)`, the call that is the game's dawn (printed as
##    `build_day_sec`, as before). The context is made before the timer starts (`GameDawn.context()`:
##    the walk, the calm areas, the plan builder, the mast sites). The old copy built the mast sites and the
##    route tree outside its timer but ran `CalmAreas.of(map)` inside it, so this timer leaves out the building
##    of the calm areas, which the earlier columns' timer included.
##  - The dawn no longer draws the day's units: each unit draws as she comes near it. The tree's probe counts
##    every unit, so `GameDawn.draw_every_unit(dawn)` runs after `build_day` and is timed apart
##    (printed as `draw_every_unit_sec`): a walk that comes near every unit pays it, the dawn itself does not.
##    The old copy's `build_day` drew everything in one call, so `build_day_sec + draw_every_unit_sec` is the
##    figure of the same coverage; `build_day_sec` alone is the dawn of the game.
##  - The count lines (RD / RV / RK) are the tree's own probe's, with SEEDS = 14.

const SEEDS := 14
const BASE := 90210
const STEP := 31
const KINDS := ["sidewalk", "carriageway", "alley", "open", "junction", "other"]

func run(t: TestRunner) -> void:
	var build_usec := 0
	var draw_usec := 0
	var whole_began := Time.get_ticks_usec()
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
					Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
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
			var dawn := GameDawn.of(spec, rng, map).masts(sites).spent(consumed).on(tree) \
					.doors(doors).standing(standing) \
					.roadblock(EventCatalogue.by_id(guarded) if guarded != "" else null).context()
			var began := Time.get_ticks_usec()
			EventScheduler.build_day(dawn)
			build_usec += Time.get_ticks_usec() - began
			began = Time.get_ticks_usec()
			GameDawn.draw_every_unit(dawn)
			draw_usec += Time.get_ticks_usec() - began
			for plan in dawn.events().placements():
				var mode := plan.def.spawn_mode_on(day)
				# A row the director sends ahead of her is a moment where the dawn left it unplaced.
				if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER \
						or (plan.def.is_sent_ahead() and not plan.is_placed()):
					moments += 1
					continue
				if not plan.is_placed():
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
				var kind := _kind_of(map, tile)
				var id := plan.row_id()
				var kv := "%s %d" % [id, view]
				by_view[kv] = int(by_view.get(kv, 0)) + 1
				var kk := "%s %s" % [id, kind]
				by_kind[kk] = int(by_kind.get(kk, 0)) + 1
		print("RD %d %d %d %d" % [day, SEEDS, placed, moments])
		for key: String in by_view:
			print("RV %d %s %d" % [day, key, by_view[key]])
		for key: String in by_kind:
			print("RK %d %s %d" % [day, key, by_kind[key]])
	print("DAWN_PLANNING build_day_sec %.3f draw_every_unit_sec %.3f whole_probe_sec %.3f cities %d days 14" % [
			build_usec / 1e6, draw_usec / 1e6, (Time.get_ticks_usec() - whole_began) / 1e6, SEEDS])
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
