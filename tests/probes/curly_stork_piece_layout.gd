extends RefCounted
## Sweep probe for the one layout of a planned body's pieces: the three answers that read it, per
## placed plan, digested per city and day, so the same file run on two trees shows by an empty
## `diff` of its output that a change to the layout moved none of them. Not a suite: it prints and
## asserts nothing. Run by name:
##
##     tools/test.sh probes/curly_stork_piece_layout.gd
##
## The cities and days are `tests/probes/placement_rows.gd`'s (its 18 cities from seed 90210 in
## steps of 31, days 1 to 14, each day planned as that probe plans it) and
## `tests/probes/escape_density.gd`'s ten escape cities (run seed 2,
## `DayPlanner.plan_the_escape_city()`). It asks only what every tree has: the walk's ground
## (`WalkGround.solids_of()`), the map's record (`EventSpawner.footprint_of()`) and the
## route rig's tiles near a planned body, which it reads off the rig's private
## `_planned_body_tiles()` because the public `body_clear_tiles()` needs a live events manager.
##
## Prints one `CS <day or E> <seed> <plans> wg <hash> sp <hash> rig <hash>` line per city and day,
## a total line, and `CS agree <n> of <bodies>`: the bodies the record keeps whose walk pieces,
## rasterised the record's way, equal the record's tiles. The day half takes about twelve minutes.

const SEEDS := 18
const BASE := 90210
const STEP := 31
const ESCAPE_SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808]
const ESCAPE_RUN_SEED := 2

func run(t: TestRunner) -> void:
	var totals := {"plans": 0, "bodies": 0, "agree": 0}
	for day in range(1, 15):
		for i in SEEDS:
			var map := CityGenerator.generate(BASE + i * STEP)
			_sweep(map, _plan(map, day, i), str(day), BASE + i * STEP, totals)
	var own_run := RunState.new()
	own_run.start_run(ESCAPE_RUN_SEED)
	for seed_value in ESCAPE_SEEDS:
		var map := CityGenerator.generate(seed_value)
		own_run.attempt_spend().block_arcs().begin_day(map.plans_by_block(), 1)
		map.repaint(own_run.attempt_spend().block_arcs())
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var route := FinalePlanner.route(map)
		var placements := DayPlanner.plan_the_escape_city(Shipped.rows(), map, route,
				rng, DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS),
				GamePlanBuilder.over(map))
		_sweep(map, placements, "E", seed_value, totals)
	print("CS total plans %d bodies %d" % [totals["plans"], totals["bodies"]])
	print("CS agree %d of %d" % [totals["agree"], totals["bodies"]])
	t.check(true, "ran")

## One city's day: the three answers for every placed plan, in plan order.
func _sweep(map: CityMap, plans: Array[EventPlan], label: String, seed_value: int,
		totals: Dictionary) -> void:
	var ground := WalkGround.new(map)
	var rig := RouteRigPlanner.new(map, null, Callable(), null, null, null)
	var walk := PackedStringArray()
	var record := PackedStringArray()
	var rigs := PackedStringArray()
	var placed := 0
	for plan in plans:
		if not plan.is_placed():
			continue
		placed += 1
		var row := plan.row()
		var solids := ground.solids_of(plan)
		for solid in solids:
			walk.append("%s %.3f,%.3f %d %.3f %.3f %.4f,%.4f" % [row.id(), solid.centre.x,
					solid.centre.y,
					1 if solid.shape.is_segment() else 2 if solid.shape.is_rect() else 0,
					solid.shape.reach(),
					solid.shape.spine_half_length(), solid.axis.x, solid.axis.y])
		var tiles := EventSpawner.footprint_of(
				BodyStance.of(map, row, plan.placed_at(), plan.faces()))
		record.append("%s %s" % [row.id(), str(tiles)])
		if not row.stands_as_a_fixed_body():
			continue
		var near := rig._planned_body_tiles(plan).keys()
		near.sort()
		rigs.append("%s %s" % [row.id(), str(near)])
		totals["bodies"] = int(totals["bodies"]) + 1
		var own := row.body().pieces().size()
		var rasterised: Array[Vector2i] = []
		for k in mini(own, solids.size()):
			var solid: WalkGround.Solid = solids[k]
			for tile in solid.shape.tiles_under(solid.centre, solid.axis):
				if not rasterised.has(tile):
					rasterised.append(tile)
		if rasterised == tiles:
			totals["agree"] = int(totals["agree"]) + 1
	totals["plans"] = int(totals["plans"]) + placed
	print("CS %s %d %d wg %d sp %d rig %d" % [label, seed_value, placed,
			"\n".join(walk).hash(), "\n".join(record).hash(), "\n".join(rigs).hash()])

func _plan(map: CityMap, day: int, i: int) -> Array[EventPlan]:
	var sites := MastSites.compute(Shipped.rows(), map)
	var state := CityState.new()
	state.begin_day(map.plans_by_block(), day)
	map.repaint(state)
	var tree := RouteTree.for_day(map, day, null)
	var spec := DaySpec.for_day(day)
	var region_plan := RegionPlanner.plan_day(Shipped.rows(), map, spec, tree)
	var closure_rng := RandomNumberGenerator.new()
	closure_rng.seed = hash("placement_rows closures:%d:%d" % [i, day])
	var closures := ClosurePlanner.plan_day(Shipped.rows(), map, spec, closure_rng,
			tree, region_plan)
	map.close_streets(closures)
	map.clear_day_holds()
	for closure: RoadClosure in closures:
		map.hold_segment(closure.street_key(), HeldStreets.Why.CLOSURE)
	for segment: StreetNetwork.Segment in region_plan.wall_segments():
		map.hold_segment(segment.key(), HeldStreets.Why.WALL)
	for segment: StreetNetwork.Segment in region_plan.door_segments():
		map.hold_segment(segment.key(), HeldStreets.Why.DOOR)
	for segment: StreetNetwork.Segment in map.street_network().around_blocks(
			Rect2i(map.home_block_coordinate(), Vector2i.ONE)):
		map.hold_segment(segment.key(), HeldStreets.Why.HOME)
	var boundary := {}
	for segment in region_plan.wall_segments():
		boundary[segment.key()] = true
	for segment in region_plan.door_segments():
		boundary[segment.key()] = true
	for rect in region_plan.walled_alleys():
		boundary[rect.position] = true
	for rect in region_plan.door_alleys():
		boundary[rect.position] = true
	var seal_rng := RandomNumberGenerator.new()
	seal_rng.seed = hash("placement_rows seals:%d:%d" % [i, day])
	var seals := SealPlanner.plan_day(Shipped.rows(), map, spec, tree, seal_rng,
			boundary, map.held_streets())
	for seal in seals:
		seal.stand_as_a_seal()
	var doors := PackedVector2Array()
	for body in region_plan.door_plans():
		doors.append(body.placed_at())
	var standing: Array[EventPlan] = []
	standing.append_array(seals)
	standing.append_array(region_plan.wall_plans())
	for body in region_plan.wall_plans():
		body.stand_in_the_wall()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
	var guarded := ResistanceSteps.guarded_row_on(day)
	var consumed: Array[String] = []
	var placements := GameDawn.of(spec, rng, map).masts(sites).spent(consumed).on(tree) \
			.doors(doors).standing(standing) \
			.roadblock(Shipped.rows().by_id(guarded) if guarded != "" else null) \
			.plan().placements()
	var all: Array[EventPlan] = []
	all.append_array(placements)
	for plan in standing:
		if not all.has(plan):
			all.append(plan)
	for plan in region_plan.door_plans():
		if not all.has(plan):
			all.append(plan)
	return all
