extends RefCounted
## Measurement probe for the bags per view (`docs/EVENTS.md`, "The three views and the placement
## order"): **what the day's placement puts in each view, per day.** Not a suite: it prints rather
## than asserting, so it lives here under `tests/probes/`, where the runner never discovers it, and
## runs only by name:
##
##     tools/test.sh probes/placement_view_mix.gd
##
## Each day is planned as the game plans it (`DayPlanner._plan_a_day()`): its closures, holds, region
## wall and seals first, the seals and the wall's bodies handed in as standing, then
## `EventScheduler.build_day()` on the repainted city and its route tree. Every placed plan is
## counted under the view of the ground it stands on (`Corridor.view_of()` for a street,
## `Corridor.view_of_ground()` for an alley, a lot or a junction box), by row, against the number of
## locations each view has (`DayLocations.all()`).
## The rows the director sites in front of her, which the day owes her but places nowhere, are
## counted apart (`MOMENTS`). `PV_VIEW` lines give each view's events per location and `PV_DAY`
## the day's whole count; the declared table's own cells, by view, kind of ground and act, are
## `tests/probes/placement_cells.gd`'s.

const SEEDS := 18
const SAMPLE_DAYS := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
const NAMES := ["on the route", "route-adjacent", "off the route"]

func run(t: TestRunner) -> void:
	for day: int in SAMPLE_DAYS:
		_mix_on(day)
	t.check(true, "placement_view_mix probe ran")

func _mix_on(day: int) -> void:
	var locations_in := [0, 0, 0]
	var counts := [{}, {}, {}]
	var totals := [0, 0, 0]
	var moments := 0
	var placed := 0
	for i in SEEDS:
		var map := CityGenerator.generate(90210 + i * 31)
		# The run's mast sites, worked out once on the city as built, as the game does.
		var sites := MastSites.compute(map)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), day)
		map.repaint(state)
		var tree := RouteTree.for_day(map, day)
		var spec := DaySpec.for_day(day)
		# The day's own closures, holds, region wall and seals, planned as the game plans them
		# (`City.start_day()`, `DayPlanner._plan_a_day()`), so the seals and the wall's bodies
		# stand as the day's standing and hold their locations.
		var region_plan := RegionPlanner.plan_day(map, spec, tree)
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("placement_view_mix closures:%d:%d" % [i, day])
		var closures := ClosurePlanner.plan_day(map, spec, closure_rng, tree, region_plan)
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
		seal_rng.seed = hash("placement_view_mix seals:%d:%d" % [i, day])
		var seals := SealPlanner.plan_day(map, spec, tree, seal_rng, boundary, map.held_streets())
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
		var corridor := Corridor.of(tree)
		for location in DayLocations.lay_out(map, corridor).all():
			if location.is_available():
				locations_in[location.view()] += 1
		var rng := _rng(i, day)
		var guarded := ResistanceSteps.guarded_row_on(day)
		var consumed: Array[String] = []
		for plan in GameDawn.of(spec, rng, map).masts(sites).spent(consumed) \
				.on(tree).doors(doors).standing(standing).roadblock(EventCatalogue.by_id(guarded) if guarded != "" else null).plan().placements():
			var mode := plan.spawn_mode_on(day)
			# A row the director sends ahead of her is a moment where the dawn left it unplaced.
			if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER or mode == EventDef.SpawnMode.TOWARD_PLAYER \
					or (plan.is_sent_ahead() and not plan.is_placed()):
				moments += 1
				continue
			if not plan.is_placed():
				continue
			placed += 1
			var tile := map.world_to_tile(plan.placed_at())
			var segment := map.street_network().segment_containing(tile)
			var view := corridor.view_of(segment) if segment else \
					corridor.view_of_ground(Rect2i(tile, Vector2i.ONE))
			var row: Dictionary = counts[view]
			row[plan.row_id()] = int(row.get(plan.row_id(), 0)) + 1
			totals[view] += 1
	var seeds := float(SEEDS)
	print("PV_DAY %d | %.1f placed, %.1f moments owed, per day over %d seeds"
			% [day, placed / seeds, moments / seeds, SEEDS])
	for view in NAMES.size():
		var locations: float = locations_in[view] / seeds
		var events: float = totals[view] / seeds
		print("PV_VIEW %d %s | %.0f locations, %.1f events, %.2f%% of locations"
				% [day, NAMES[view], locations, events, 100.0 * events / maxf(1.0, locations)])
		var rows: Dictionary = counts[view]
		var ids := rows.keys()
		ids.sort_custom(func(a: String, b: String) -> bool: return int(rows[a]) > int(rows[b]))
		var parts: Array[String] = []
		for id: String in ids:
			parts.append("%s %.1f" % [id, int(rows[id]) / seeds])
		print("PV_ROWS %d %s | %s" % [day, NAMES[view], ", ".join(parts)])

static func _rng(i: int, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("placement_view_mix:%d:%d" % [i, day])
	return rng
