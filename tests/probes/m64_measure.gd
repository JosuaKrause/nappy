extends RefCounted
## Measurement probe for "measure the empty feeling before and after". Not a suite: it prints
## numbers rather than asserting relationships, so it lives here under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m64_measure.gd
##
## and read the numbers off stdout. Two questions, matching the two candidate causes playtest 21
## could not tell apart:
##
## 1. Does `EventScheduler._role_for` call the pavement-changing rows (`cafe_tables`,
##    `market_stall`, `construction`, `delivery_van`) a WALL, which `_copies_of` then refuses on
##    every corridor tile?
## 2. How much of `ClosurePlanner`'s calm-area access-street refusal falls on the rim — the ground
##    closest to where she actually walks — versus scattered elsewhere?

const SEEDS := 8
const BASE_SEED := 90210
const SAMPLE_DAYS := [1, 5, 8, 11, 14]

func run(t) -> void:
	_role_for_the_named_rows()
	_role_and_depth_sweep()
	_closure_access_vs_rim_sweep()
	# Satisfy the runner, which wants at least one check to not report a suite that found nothing.
	t.check(true, "zz_m64 probe ran")

# ---------------------------------------------------------- hypothesis: role by row ---

func _role_for_the_named_rows() -> void:
	print("\n== _role_for and walk_through_cost() for the named rows (static, no city needed) ==")
	print("WALL_WORTH_OF_COST = %.2f" % Tuning.WALL_WORTH_OF_COST)
	var ids := ["cafe_tables", "market_stall", "construction", "delivery_van",
			"dog_walker", "homeless_yeller", "loose_dog"]
	for id in ids:
		var def := EventCatalogue.by_id(id)
		if not def:
			print("  %-16s not in the catalogue" % id)
			continue
		var role := EventScheduler._role_for(def)
		var role_name: String = ["NONE", "WALL", "FRICTION", "SET_PIECE"][role]
		print("  %-16s cost=%6.2f hard_fail=%s role=%s"
				% [id, def.walk_through_cost(), def.hard_fail, role_name])

# ---------------------------------------------------------- role x depth sweep ---

func _role_and_depth_sweep() -> void:
	print("\n== role x Corridor.depth() over %d seeds x days %s (EVENT_CORRIDOR_WEIGHT=%d) =="
			% [SEEDS, SAMPLE_DAYS, Tuning.EVENT_CORRIDOR_WEIGHT])
	# depth bucket 0 = on the corridor, 1 = rim, 2 = "deep" (2 or more, saturating at Corridor.DEEP)
	var by_role_depth := {}   # "%s:%d" % [role_name, depth] -> count
	var by_id_depth := {}     # "%s:%d" % [id, depth] -> count
	var by_id_role := {}      # "%s:%s" % [id, role_name] -> count
	var role_names := ["NONE", "WALL", "FRICTION", "SET_PIECE"]
	var named := ["cafe_tables", "market_stall", "construction", "delivery_van"]
	var placed_total := 0

	# The crossing-rate metric for item 2: a "crossing" is a corridor street that carries at
	# least one stationary, solid friction placement — the pavement obstacles M48 gave a real
	# body to (obstructs_radius > 0, not mobile, so a dog walker's route does not count: he does
	# not occupy a lane). Counted as *distinct corridor streets carrying one*, not as raw
	# placements, because the question is how often she is made to cross, not how many things
	# are near her.
	var sum_corridor_streets := 0
	var sum_streets_with_a_crossing := 0
	var sum_solid_friction_on_corridor := 0
	var day_count := 0
	# The winnability guarantee, re-checked independently of `build_day`'s own
	# `_ensure_the_city_is_still_walkable` (which already ran before `planned` came back) — a
	# fresh flood from the home tile against every obstruction the day actually placed.
	var days_unwinnable := 0

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		var grid := ReachabilityGrid.build(map)
		for day in SAMPLE_DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("zz_m64:%d:%d" % [map.seed_used, day])
			var consumed: Array[String] = []
			var planned := EventScheduler.build_day(day, rng, map, consumed, [], [], tree)
			day_count += 1
			sum_corridor_streets += tree.streets().size()
			var crossing_streets := {}
			for plan in planned:
				if not plan.is_placed():
					continue
				placed_total += 1
				var tile := map.world_to_tile(plan.position)
				var depth := mini(corridor.depth(tile), 2)
				var role_name: String = role_names[plan.role]
				var rd := "%s:%d" % [role_name, depth]
				by_role_depth[rd] = int(by_role_depth.get(rd, 0)) + 1
				if plan.def.id in named:
					var idd := "%s:%d" % [plan.def.id, depth]
					by_id_depth[idd] = int(by_id_depth.get(idd, 0)) + 1
					var idr := "%s:%s" % [plan.def.id, role_name]
					by_id_role[idr] = int(by_id_role.get(idr, 0)) + 1
				if depth == 0 and plan.role == GameEnums.BlockerRole.FRICTION \
						and not plan.def.mobile and plan.def.obstructs_radius > 0.0:
					sum_solid_friction_on_corridor += 1
					var segment := StreetNetwork.segment_containing(tile)
					if segment:
						crossing_streets[segment.key()] = true
			sum_streets_with_a_crossing += crossing_streets.size()
			if not _some_calm_is_reachable(map, grid, planned):
				days_unwinnable += 1

	print("total placed (is_placed()) over the sweep: %d" % placed_total)
	print("day-site count: %d (%d seeds x %d sample days)" % [day_count, SEEDS, SAMPLE_DAYS.size()])
	print("days where no calm area was reachable after placement: %d of %d"
			% [days_unwinnable, day_count])
	var days_f := maxf(1.0, float(day_count))
	print("mean corridor streets/day: %.1f" % (sum_corridor_streets / days_f))
	print("mean corridor streets/day carrying >=1 solid friction obstacle (a 'crossing'): %.1f (%.1f%% of corridor streets)"
			% [sum_streets_with_a_crossing / days_f,
			100.0 * float(sum_streets_with_a_crossing) / maxf(1.0, float(sum_corridor_streets))])
	print("mean solid friction placements on the corridor/day: %.1f"
			% (sum_solid_friction_on_corridor / days_f))
	print("-- by role x depth (0 = on corridor, 1 = rim, 2 = deep/2+) --")
	for role_name in role_names:
		var counts: Array[int] = []
		for depth in range(3):
			counts.append(int(by_role_depth.get("%s:%d" % [role_name, depth], 0)))
		print("  %-10s depth0=%5d depth1=%5d depth2+=%5d" % [role_name, counts[0], counts[1], counts[2]])

	print("-- per named row: placements by depth, and by role --")
	for id in named:
		var counts: Array[int] = []
		for depth in range(3):
			counts.append(int(by_id_depth.get("%s:%d" % [id, depth], 0)))
		var total := counts[0] + counts[1] + counts[2]
		var role_bits: Array[String] = []
		for role_name in role_names:
			var c := int(by_id_role.get("%s:%s" % [id, role_name], 0))
			if c > 0:
				role_bits.append("%s=%d" % [role_name, c])
		print("  %-16s total=%4d depth0=%4d depth1=%4d depth2+=%4d  roles: %s"
				% [id, total, counts[0], counts[1], counts[2], ", ".join(role_bits)])

## The same reachability guarantee `EventScheduler._ensure_the_city_is_still_walkable` states,
## re-checked from the outside against the day `build_day` actually returned — calling the real
## `_park_is_reachable` so this is not a second implementation to drift from the one under test.
func _some_calm_is_reachable(map: CityMap, grid: ReachabilityGrid, planned: Array) -> bool:
	var blockers: Array[EventScheduler.Planned] = []
	for plan: EventScheduler.Planned in planned:
		if not plan.is_placed():
			continue
		if plan.def.obstructs_radius > 0.0 or plan.def.hard_fail:
			blockers.append(plan)
	return EventScheduler._park_is_reachable(map, grid, blockers)

# ---------------------------------------------------------- closures vs the access refusal ---

func _closure_access_vs_rim_sweep() -> void:
	print("\n== closures, the access-street refusal, and the rim, over %d seeds x 14 days ==" % SEEDS)
	var total_streets := StreetNetwork.segments().size()
	var sum_access := 0
	var sum_rim := 0
	var sum_access_and_rim := 0
	var day_count := 0

	var sum_closures_with_filter := 0
	var sum_closures_with_filter_on_rim := 0

	var sum_closures_without_filter := 0
	var sum_closures_without_filter_on_rim := 0
	var sum_closures_without_filter_on_access := 0

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + 1000 + i * 31)
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var home := ClosurePlanner.home_street(map)
			var areas := ClosurePlanner.calm_areas(map)
			if not home or areas.size() < Tuning.MIN_CALM_AREAS_REACHABLE:
				continue
			var tree := RouteTree.for_day(map, day)
			day_count += 1

			var rim := {}
			for key in tree.rim():
				rim[key] = true
			var access := {}
			for area in areas:
				for segment in area.access:
					access[segment.key()] = true
			sum_access += access.size()
			sum_rim += rim.size()
			var overlap := 0
			for key in access:
				if rim.has(key):
					overlap += 1
			sum_access_and_rim += overlap

			# The real, filtered plan — ClosurePlanner.plan_day, exactly as the game runs it.
			var rng_a := RandomNumberGenerator.new()
			rng_a.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var real := ClosurePlanner.plan_day(map, day, rng_a, tree)
			sum_closures_with_filter += real.size()
			for closure in real:
				if rim.has(closure.segment.key()):
					sum_closures_with_filter_on_rim += 1

			# The ablation: the same candidate weighting and the same accept-if-invariant-holds
			# loop, with the access-street exclusion removed. Reimplemented here rather than in
			# `ClosurePlanner` itself, which item 1 may not change — this is measurement code, not
			# a behaviour change.
			var rng_b := RandomNumberGenerator.new()
			rng_b.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var without := _plan_without_access_filter(map, day, rng_b, tree, home, areas)
			sum_closures_without_filter += without.size()
			for segment in without:
				if rim.has(segment.key()):
					sum_closures_without_filter_on_rim += 1
				if access.has(segment.key()):
					sum_closures_without_filter_on_access += 1

	var days := maxf(1.0, float(day_count))
	print("candidate lattice streets: %d" % total_streets)
	print("mean access streets refused per day: %.1f of %d" % [sum_access / days, total_streets])
	print("mean rim streets per day: %.1f" % (sum_rim / days))
	print("mean (access ∩ rim) per day: %.1f" % (sum_access_and_rim / days))
	if sum_access > 0:
		print("share of refused access streets that are also rim: %.1f%%"
				% (100.0 * float(sum_access_and_rim) / float(sum_access)))
	if sum_rim > 0:
		print("share of rim streets that the access filter removes from the closure pool: %.1f%%"
				% (100.0 * float(sum_access_and_rim) / float(sum_rim)))
	print("-- as built (access streets excluded) --")
	print("  closures placed: %d over %d days (%.2f/day)"
			% [sum_closures_with_filter, day_count, sum_closures_with_filter / days])
	if sum_closures_with_filter > 0:
		print("  of which on the rim: %d (%.1f%%)" % [sum_closures_with_filter_on_rim,
				100.0 * float(sum_closures_with_filter_on_rim) / float(sum_closures_with_filter)])
	print("-- ablation (access streets allowed as candidates) --")
	print("  closures placed: %d over %d days (%.2f/day)"
			% [sum_closures_without_filter, day_count, sum_closures_without_filter / days])
	if sum_closures_without_filter > 0:
		print("  of which on the rim: %d (%.1f%%)" % [sum_closures_without_filter_on_rim,
				100.0 * float(sum_closures_without_filter_on_rim) / float(sum_closures_without_filter)])
		print("  of which on a calm area's own access street: %d (%.1f%%)"
				% [sum_closures_without_filter_on_access,
				100.0 * float(sum_closures_without_filter_on_access) / float(sum_closures_without_filter)])

## `ClosurePlanner._shuffled_candidates`, minus the `access.has(key)` exclusion — the ablation.
func _candidates_without_access_filter(map: CityMap, home: StreetNetwork.Segment, tree: RouteTree,
		rng: RandomNumberGenerator) -> Array[StreetNetwork.Segment]:
	var rim := {}
	for key in tree.rim():
		rim[key] = true
	var gaps := {}
	for key in tree.gaps():
		gaps[key] = true
	var pool: Array[StreetNetwork.Segment] = []
	var weights: Array[float] = []
	for segment in StreetNetwork.segments():
		var key := segment.key()
		if key == home.key() or not map.has_street(key) or tree.is_on_the_tree(key):
			continue
		pool.append(segment)
		var weight := Tuning.CLOSURE_WALL_BIAS if rim.has(key) else 1.0
		weights.append(weight * Tuning.CLOSURE_GAP_BIAS if gaps.has(key) else weight)

	var order: Array[StreetNetwork.Segment] = []
	while not pool.is_empty():
		var index := _pick_weighted(weights, rng)
		order.append(pool[index])
		pool.remove_at(index)
		weights.remove_at(index)
	return order

func _pick_weighted(weights: Array[float], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := rng.randf() * total
	for index in weights.size():
		roll -= weights[index]
		if roll <= 0.0:
			return index
	return weights.size() - 1

## `ClosurePlanner.plan_day`'s own accept loop, run against the ablated candidate list.
func _plan_without_access_filter(map: CityMap, day: int, rng: RandomNumberGenerator, tree: RouteTree,
		home: StreetNetwork.Segment, areas: Array[ClosurePlanner.CalmArea]) -> Array[StreetNetwork.Segment]:
	var chosen: Array[StreetNetwork.Segment] = []
	var wanted := Tuning.closures_for_day(day)
	if wanted <= 0:
		return chosen
	var grid := ReachabilityGrid.build(map)
	var today_closed := {}
	for segment in _candidates_without_access_filter(map, home, tree, rng):
		if chosen.size() >= wanted:
			break
		today_closed[segment.key()] = true
		if ClosurePlanner._invariant_holds(map, grid, areas, today_closed):
			chosen.append(segment)
		else:
			today_closed.erase(segment.key())
	return chosen
