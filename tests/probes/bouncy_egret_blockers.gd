extends RefCounted
## How many hard blockers a day stands off its route tree: seals, road closures and wall-role
## catalogue rows. Printed rather than asserted. Not a suite: it lives under `tests/probes/`, where
## the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/bouncy_egret_blockers.gd
##
## The player, azure-puffin point 4: *"when the guard houses are set up the city gets much harder to
## navigate let's loosen the density of the hard blocking events in that case"*, and on being asked
## which: *"fewer of all three"*. This counts the three over the days around the gatehouse day
## (`Tuning.REGION_WALL_FIRST_DAY`), so a change to how many of each a day places is read as a
## number rather than an impression.
##
## # What is counted, per day
##
## - **sealed streets**: off-tree streets carrying a seal body (`SealPlanner.plan_day`, one entry
##   per street however many bodies it stands), out of the **off-tree streets** that could be;
## - **seal bodies** and **alley mouths**: the bodies the seal pass places, and how many of them stand
##   in a through-alley's mouth;
## - **closures**: `ClosurePlanner.plan_day`'s street closures, the fenced park's own fence left out;
## - **walls** and **friction**: placed catalogue rows by `Planned.role`, from
##   `EventScheduler.build_day` run against the seals and the region wall the way
##   `EventManager.start_day` runs it.
##
## The day is assembled as `tests/probes/m129_walked_sidewalk_walls.gd` assembles it: tree, region
## plan, closures closed on the map, held segments, seals, then the catalogue.

const SEEDS := 6
const BASE_SEED := 4242
const DAYS := [7, 8, 9, 10, 11, 12, 13]

func run(t) -> void:
	var started := Time.get_ticks_msec()
	print("\n== hard blockers per day, %d seeds, days %s ==" % [SEEDS, DAYS])
	print("  day  off-tree  sealed  seal-bodies  alley-mouths  closures  walls  friction")
	var totals := {}
	for day: int in DAYS:
		var sums := {"off": 0, "sealed": 0, "bodies": 0, "mouths": 0, "closures": 0,
				"walls": 0, "friction": 0}
		for i in SEEDS:
			var map := CityGenerator.generate(BASE_SEED + i * 97)
			var counts := _count_day(map, day)
			for key: String in counts:
				sums[key] += counts[key]
		totals[day] = sums
		var n := float(SEEDS)
		print("  %3d  %8.1f  %6.1f  %11.1f  %12.1f  %8.1f  %5.1f  %8.1f" % [day,
				sums["off"] / n, sums["sealed"] / n, sums["bodies"] / n, sums["mouths"] / n,
				sums["closures"] / n, sums["walls"] / n, sums["friction"] / n])
	print("  (%d ms)" % (Time.get_ticks_msec() - started))
	t.check(true, "bouncy_egret_blockers probe ran")

func _rng(map: CityMap, day: int, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("bouncy-egret:%s:%d:%d" % [stream, map.seed_used, day])
	return rng

func _count_day(map: CityMap, day: int) -> Dictionary:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	var tree := RouteTree.for_day(map, day)
	var region_plan := RegionPlanner.plan_day(map, day, tree)
	var closures := ClosurePlanner.plan_day(map, day, _rng(map, day, "closures"), tree,
			region_plan)
	map.close_streets(closures)
	var street_closures := 0
	for closure in closures:
		if closure is RoadClosure:
			street_closures += 1

	map.clear_day_holds()
	for closure in closures:
		if closure is RoadClosure:
			map.hold_segment(closure.segment.key())
	for segment: StreetNetwork.Segment in region_plan.walls:
		map.hold_segment(segment.key())
	for segment: StreetNetwork.Segment in region_plan.doors:
		map.hold_segment(segment.key())
	for segment: StreetNetwork.Segment in StreetNetwork.around_blocks(
			Rect2i(map.home_block, Vector2i.ONE)):
		map.hold_segment(segment.key())

	var boundary := {}
	for segment: StreetNetwork.Segment in region_plan.walls:
		boundary[segment.key()] = true
	for segment: StreetNetwork.Segment in region_plan.doors:
		boundary[segment.key()] = true
	for rect: Rect2i in region_plan.alley_walls:
		boundary[rect.position] = true
	for rect: Rect2i in region_plan.alley_doors:
		boundary[rect.position] = true

	var off_tree := 0
	for segment in StreetNetwork.segments():
		if map.has_street(segment.key()) and not tree.is_on_the_tree(segment.key()):
			off_tree += 1

	var seals := SealPlanner.plan_day(map, day, tree, _rng(map, day, "seals"), boundary,
			map.held_segments)
	var sealed := {}
	var mouths := 0
	for plan in seals:
		var tile := map.world_to_tile(plan.position)
		if map.tile_at(tile) == GameEnums.TileType.ALLEY:
			mouths += 1
			continue
		var segment := StreetNetwork.segment_containing(tile)
		if segment:
			sealed[segment.key()] = true

	var standing: Array[EventScheduler.Planned] = []
	standing.append_array(seals)
	standing.append_array(region_plan.wall_bodies)
	var doors := PackedVector2Array()
	for body in region_plan.door_bodies:
		doors.append(body.position)
	var consumed: Array[String] = []
	var walls := 0
	var friction := 0
	for plan in EventScheduler.build_day(day, _rng(map, day, "events"), map, consumed, [], [],
			tree, 0, doors, [] as Array[Vector2i], standing):
		if not plan.is_placed():
			continue
		if plan.role == GameEnums.BlockerRole.WALL:
			walls += 1
		elif plan.role == GameEnums.BlockerRole.FRICTION:
			friction += 1
	return {"off": off_tree, "sealed": sealed.size(), "bodies": seals.size(), "mouths": mouths,
			"closures": street_closures, "walls": walls, "friction": friction}
