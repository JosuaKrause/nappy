extends RefCounted
## Measurement probe for downy-llama (the roadblock covers its own sidewalk and the road, and leaves
## the far sidewalk whole): **how many roadblocks each day places on the streets of her routes,
## beside them and off them, at heat 0 and at heat 4**, where the checkpoint guard hunts and the
## one-sidewalk rule still reads the roadblock at its band. Not a suite: it prints rather than
## asserting, and runs only by name:
##
##     tools/test.sh probes/downy_llama_route_roadblocks.gd
##
## Each day is planned as `placement_rows.gd` plans it (the same cities, streams and standing), with
## the dawn's heat set and, on day 13, the roadblock phase handed the heated row. It asks only what
## every tree has (`Corridor.view_of()`, the tile under each plan), so the same file measures main
## and a branch alike. Prints `RB heat day on adjacent off junction`, each summed over the seeds.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const HEATS: Array[int] = [0, 4]

func run(t: TestRunner) -> void:
	for heat: int in HEATS:
		for day in range(7, 15):
			_one_day(heat, day)
	t.check(true, "route roadblocks probe ran")

func _one_day(heat: int, day: int) -> void:
	var counts: Array[int] = [0, 0, 0, 0]
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
		var guarded_row: EventDef = null
		if guarded != "":
			guarded_row = EventCatalogue.heated(EventCatalogue.by_id(guarded), heat)
		for plan in GameDawn.of(spec, rng, map).masts(sites).spent(consumed).on(tree) \
				.heat(heat).doors(doors).standing(standing) \
				.roadblock(guarded_row).plan().placements():
			if plan.row_id() != "roadblock" or not plan.is_placed():
				continue
			var tile := map.world_to_tile(plan.placed_at())
			if CityMap.junction_at(tile) != Vector2i(-1, -1):
				counts[3] += 1
				continue
			var segment := map.network.segment_containing(tile)
			if segment:
				counts[corridor.view_of(segment)] += 1
	print("RB %d %d %d %d %d %d" % [heat, day, counts[0], counts[1], counts[2], counts[3]])
