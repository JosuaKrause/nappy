extends RefCounted
## `RegionPlanner`: the lattice's junctions partition into `Tuning.REGION_COUNT` regions at
## generation, and from `Tuning.REGION_WALL_FIRST_DAY` a day's `RouteTree` turns the permanent
## boundary into a wall with doors in it.
##
## `docs/CITY.md`, "Regions and the wall" is the design; `src/routes/region_planner.gd` is the
## implementation. The flood check (`_test_flood_matches_the_partition`) is the one a segment-level
## check cannot do — see `docs/TODO.md`, M62, "The checks are floods over cells, not counts over
## segments" — because it is the only one that would catch an alley or a courtyard archway an atom
## failed to keep whole.

const SEEDS := 6
const BASE_SEED := 260917

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 137))
	_test_partition_covers_every_real_junction(t)
	_test_assignment_is_deterministic(t)
	_test_calm_atoms_are_never_boundary(t)
	_test_alley_atoms_are_never_boundary(t)
	_test_the_home_street_is_never_boundary(t)
	_test_precinct_spans_are_never_boundary(t)
	_test_flood_matches_the_partition(t)
	_test_no_wall_before_the_first_day(t)
	_test_the_day_plan_shape(t)
	_test_winnability_holds_with_the_wall_standing(t)
	_test_closures_and_seals_never_land_on_a_boundary(t)

# ------------------------------------------------------------------------ setup ---

func _repaint_for(map: CityMap, day: int) -> void:
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)

func _add_circle(map: CityMap, blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true

func _main_road_tiles(map: CityMap) -> Dictionary:
	var blocked := {}
	if map.main_road < 0:
		return blocked
	var rect := Rect2i(Vector2i(map.main_road * CityMap.period(), 0),
			Vector2i(Tuning.STREET_WIDTH, map.size.y))
	for tile in map.rect_tiles(rect):
		blocked[tile] = true
	return blocked

## Every junction touched by at least one real street — the ones a region question means anything
## about. A junction with no real segment at all is left `-1` by `RegionPlanner.assign()` on
## purpose (see its own doc) and is not one of these.
func _real_junctions(map: CityMap) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var count := StreetNetwork.junction_count()
	for y in count.y:
		for x in count.x:
			var junction := Vector2i(x, y)
			for segment in StreetNetwork.at_junction(junction):
				if map.has_street(segment.key()):
					found.append(junction)
					break
	return found

func _area_for_block(areas: Array[ClosurePlanner.CalmArea], block: Vector2i) -> ClosurePlanner.CalmArea:
	for area in areas:
		if area.block == block:
			return area
	return null

func _boundary_keys(plan: RegionPlanner.RegionPlan) -> Dictionary:
	var keys := {}
	for segment in plan.walls:
		keys[segment.key()] = true
	for segment in plan.doors:
		keys[segment.key()] = true
	return keys

# ------------------------------------------------------------------ the partition ---

## Every real junction has exactly one region, and (on these seeds) every one of the
## `Tuning.REGION_COUNT` regions is actually used. A count narrower than `REGION_COUNT` is not a
## contradiction on its own — a tiny or unusually shaped lattice could legitimately grow fewer —
## but this project's fixed 11×11 lattice and four regions leaves ample room, so the sweep asserts
## the number rather than merely a floor.
func _test_partition_covers_every_real_junction(t) -> void:
	var sizes_report: Array[String] = []
	for map in _maps:
		var seen := {}
		var total_real := 0
		for junction in _real_junctions(map):
			total_real += 1
			var region := RegionPlanner.region_of_junction(map, junction)
			t.check(region >= 0 and region < Tuning.REGION_COUNT,
					"seed %d: junction %s, touched by a real street, has a region in [0, %d) (got %d)"
					% [map.seed_used, junction, Tuning.REGION_COUNT, region])
			seen[region] = (seen.get(region, 0) as int) + 1
		t.check(total_real > 0, "there were real junctions to check (%d)" % total_real)
		t.check(seen.size() == Tuning.REGION_COUNT,
				"seed %d: all %d regions are used, not just some of them (got %d)"
				% [map.seed_used, Tuning.REGION_COUNT, seen.size()])
		var counts: Array[int] = []
		for r in Tuning.REGION_COUNT:
			counts.append(seen.get(r, 0) as int)
		sizes_report.append("seed %d: %s" % [map.seed_used, counts])
	# A plain measurement, not a pass/fail bound — the milestone report's "region size spread".
	print("[test_regions] junctions per region, one line per seed: ", sizes_report)

## The same seed assigns the same regions twice — a run is learnable or it is nothing, the same
## reason every other planner in `src/routes/` is deterministic from its seed.
func _test_assignment_is_deterministic(t) -> void:
	for map in _maps:
		var rng_a := RandomNumberGenerator.new()
		rng_a.seed = hash("regions:%d" % map.seed_used)
		RegionPlanner.assign(map, rng_a)
		var first := map.region_of_junction.duplicate()
		var rng_b := RandomNumberGenerator.new()
		rng_b.seed = hash("regions:%d" % map.seed_used)
		RegionPlanner.assign(map, rng_b)
		t.check(first == map.region_of_junction,
				"seed %d: the same seed assigns the same regions twice" % map.seed_used)

# ----------------------------------------------------------------------- the atoms ---

## A calm area's own access segments are never boundary segments — a boundary through a park's
## frontage would wall off half a destination, which is a region edge affecting a path.
func _test_calm_atoms_are_never_boundary(t) -> void:
	var checked := 0
	for map in _maps:
		for area in ClosurePlanner.calm_areas(map):
			for segment in area.access:
				checked += 1
				t.check(RegionPlanner.region_of_segment(map, segment) >= 0,
						"seed %d: calm area %s's access street %s is not a region boundary"
						% [map.seed_used, area.block, segment.key()])
	t.check(checked > 0, "at least one calm area's access street was checked (%d)" % checked)

## The two streets a through-alley joins are never boundary segments, or a boundary could seal a
## courtyard by its own archway the way M69 found a barrier doing.
func _test_alley_atoms_are_never_boundary(t) -> void:
	var checked := 0
	for map in _maps:
		for rect in map.alley_rects:
			if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
				continue
			var vertical := rect.size.x < rect.size.y
			var block := map.block_at(map.tile_rect_to_world(rect).get_center())
			var side_a: int = StreetNetwork.Side.NORTH if vertical else StreetNetwork.Side.WEST
			var side_b: int = StreetNetwork.Side.SOUTH if vertical else StreetNetwork.Side.EAST
			var segment_a := StreetNetwork.beside_block(block, side_a)
			var segment_b := StreetNetwork.beside_block(block, side_b)
			for segment in [segment_a, segment_b]:
				# A hard blocker can take either bordering street independently of the alley
				# itself — see `RegionPlanner._area_touch_points`'s own doc, "A calm area can be
				# tile-adjacent to a dead end's still-open stub". An absent one is neither
				# boundary nor interior; it simply is not in the lattice, and `region_of_segment`
				# says so with the same `-1` a real boundary segment would, so it has to be told
				# apart here rather than asserted about directly.
				if not segment or not map.has_street(segment.key()):
					continue
				checked += 1
				t.check(RegionPlanner.region_of_segment(map, segment) >= 0,
						"seed %d: alley at %s's own street %s is not a region boundary"
						% [map.seed_used, rect.position, segment.key()])
	t.check(checked > 0, "at least one alley's street was checked (%d)" % checked)

func _test_the_home_street_is_never_boundary(t) -> void:
	for map in _maps:
		var home := ClosurePlanner.home_street(map)
		t.check(home != null, "seed %d: the front door opens onto a street" % map.seed_used)
		if home:
			t.check(RegionPlanner.region_of_segment(map, home) >= 0,
					"seed %d: the home street %s is not a region boundary"
					% [map.seed_used, home.key()])

## Every street along a precinct span's own corridor is interior to one region — cutting one would
## wall off half a place the player is told how to find.
func _test_precinct_spans_are_never_boundary(t) -> void:
	var checked := 0
	for map in _maps:
		for span: Vector4i in map.precinct_spans:
			var corridor := span.y
			var range_end := span.w + 1
			for along in range(span.z, range_end):
				var key := Vector3i(corridor, along, 1) if span.x == 1 else Vector3i(along, corridor, 0)
				var segment := StreetNetwork.by_key(key)
				if not segment or not map.has_street(segment.key()):
					continue
				checked += 1
				t.check(RegionPlanner.region_of_segment(map, segment) >= 0,
						"seed %d: precinct span street %s is not a region boundary"
						% [map.seed_used, segment.key()])
	t.check(checked > 0, "at least one precinct span street was checked (%d)" % checked)

# ------------------------------------------------------------------------- the flood ---

## The check a segment-level rule cannot do: block every boundary segment's midpoint band (the
## same cross-section `SealPlanner._hard_positions` spans, sidewalk to sidewalk) and flood from the
## doorstep. Every tile of every interior (non-boundary) street resolves to reached exactly when
## its street's region is the home region, and to not reached otherwise — proving the partition and
## the tile-level ground agree everywhere, not merely at the segments a rule happened to think
## about.
func _test_flood_matches_the_partition(t) -> void:
	var checked_cells := 0
	for map in _maps:
		var boundary := RegionPlanner.boundary_segments(map)
		var blocked := {}
		for segment in boundary:
			for tile in SealPlanner._cross_section_tiles(segment):
				blocked[tile] = true
		var grid := ReachabilityGrid.build(map)
		var doorstep := map.world_to_tile(map.doorstep_world_position())
		var reached := grid.flood([doorstep], blocked)
		var home := RegionPlanner.home_region(map)
		for segment in StreetNetwork.segments():
			if not map.has_street(segment.key()):
				continue
			var region := RegionPlanner.region_of_segment(map, segment)
			if region < 0:
				continue   # a boundary segment itself; not one of "the interior segments" below
			var should_reach := region == home
			for tile in map.rect_tiles(segment.tile_rect()):
				checked_cells += 1
				var does_reach := grid.reaches(tile, blocked, reached)
				t.check(does_reach == should_reach,
						"seed %d: tile %s of region %d's street %s reached=%s, want %s (home is %d)"
						% [map.seed_used, tile, region, segment.key(), does_reach, should_reach, home])
	t.check(checked_cells > 0, "there were cells to ask (%d)" % checked_cells)

# ---------------------------------------------------------------------------- the day ---

func _test_no_wall_before_the_first_day(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.REGION_WALL_FIRST_DAY):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			t.check(plan.walls.is_empty() and plan.doors.is_empty(),
					"seed %d day %d: nothing is drawn before day %d (%d walls, %d doors)"
					% [map.seed_used, day, Tuning.REGION_WALL_FIRST_DAY, plan.walls.size(),
					plan.doors.size()])

## The day's whole shape, from `Tuning.REGION_WALL_FIRST_DAY` to the end of the run: every door is
## on the tree; every wall is off the tree unless a no-calm, non-home region forces it regardless
## (`RegionPlanner._forces_wall`, asked directly rather than re-derived, so this checks the
## contract and not merely restates the arithmetic) — a segment touching home is never forced,
## whatever the tree does or does not cross, which is the exemption's literal reading (see
## `plan_day`'s own class doc); a door never touches a no-calm region unless the other side is
## home; the home region has at least one door whenever there is a boundary at all; and every
## region the day's tree actually reaches a calm area in is reached from the doorstep once only the
## doors are open.
func _test_the_day_plan_shape(t) -> void:
	var forced_at_all := 0
	var forced_overrode_the_tree := 0
	var sampled_days := 0
	var total_walls := 0
	var total_doors := 0
	var home_door_skipped := 0
	for map in _maps:
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			var calm := RegionPlanner.regions_with_calm(map)
			var home := RegionPlanner.home_region(map)
			sampled_days += 1

			for segment in plan.doors:
				t.check(tree.is_on_the_tree(segment.key()),
						"seed %d day %d: door %s is on the day's tree" % [map.seed_used, day, segment.key()])
				var ra := RegionPlanner.region_of_junction(map, segment.a)
				var rb := RegionPlanner.region_of_junction(map, segment.b)
				var touches_home := ra == home or rb == home
				t.check(touches_home or (not RegionPlanner._forces_wall(ra, calm)
						and not RegionPlanner._forces_wall(rb, calm)),
						"seed %d day %d: door %s touches home, or touches no region with no calm"
						% [map.seed_used, day, segment.key()])

			for segment in plan.walls:
				var ra := RegionPlanner.region_of_junction(map, segment.a)
				var rb := RegionPlanner.region_of_junction(map, segment.b)
				var touches_home := ra == home or rb == home
				var forced := not touches_home \
						and (RegionPlanner._forces_wall(ra, calm) or RegionPlanner._forces_wall(rb, calm))
				if forced:
					forced_at_all += 1
					if tree.is_on_the_tree(segment.key()):
						forced_overrode_the_tree += 1
				t.check(forced or not tree.is_on_the_tree(segment.key()),
						"seed %d day %d: wall %s is off the tree, or forced by a no-calm region"
						% [map.seed_used, day, segment.key()])

			# The provable form of "the home region always has a door": `plan_day`'s own doc
			# argument is that the branch reaching a calm area *outside* home must cross one of
			# home's own boundary segments, which is then a door. Where no other region holds any
			# calm at all — every calm area this city ever had landed in the home region's own
			# atom, which the sweep below found does happen on an unlucky seed — there is nothing
			# for the tree to cross out for, and the milestone's own reasoning does not apply. See
			# the milestone report for how often that condition holds across the sweep.
			var other_region_has_calm := false
			for r in Tuning.REGION_COUNT:
				if r != home and r < calm.size() and calm[r] == 1:
					other_region_has_calm = true
			var boundary_count := plan.walls.size() + plan.doors.size()
			total_walls += plan.walls.size()
			total_doors += plan.doors.size()
			if boundary_count > 0 and not other_region_has_calm:
				home_door_skipped += 1
			if boundary_count > 0 and other_region_has_calm:
				var home_has_door := false
				for segment in plan.doors:
					if RegionPlanner.region_of_junction(map, segment.a) == home \
							or RegionPlanner.region_of_junction(map, segment.b) == home:
						home_has_door = true
						break
				t.check(home_has_door,
						"seed %d day %d: the home region has at least one door (%d boundary segments)"
						% [map.seed_used, day, boundary_count])

			var boundary := {}
			for segment in plan.walls:
				boundary[segment.key()] = true
			var blocked := {}
			for plan_body in plan.wall_bodies:
				_add_circle(map, blocked, plan_body.position, plan_body.def.obstructs_radius)
			var grid := ReachabilityGrid.build(map)
			var doorstep := map.world_to_tile(map.doorstep_world_position())
			var reached := grid.flood([doorstep], blocked)
			var areas := ClosurePlanner.calm_areas(map)
			for branch in tree.branches:
				var area := _area_for_block(areas, branch.area)
				if not area or area.access.is_empty():
					continue
				var region := RegionPlanner.region_of_junction(map, area.access[0].a)
				var area_reached := false
				for tile in map.rect_tiles(area.rect):
					if Tile.is_calm(map.tile_at(tile)) and grid.reaches(tile, blocked, reached):
						area_reached = true
						break
				t.check(area_reached,
						("seed %d day %d: region %d's calm area %s, which today's tree reaches, is " +
						"reached from the doorstep with only the day's doors open")
						% [map.seed_used, day, region, branch.area])
	t.check(sampled_days > 0, "at least one day from %d to %d was sampled (%d)"
			% [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS, sampled_days])
	# Not a pass/fail bound — a plain measurement for whoever reads the suite's own output.
	print(("[test_regions] over %d sampled (seed, day) pairs: %d walls, %d doors; a no-calm " +
			"region forced a wall %d times, overriding an on-tree segment %d of those; the " +
			"home-has-a-door check was skipped (no other region held calm) %d times")
			% [sampled_days, total_walls, total_doors, forced_at_all, forced_overrode_the_tree,
			home_door_skipped])

## Reuses `tests/test_seals.gd`'s reachability-without-the-main-road shape, with the region wall's
## own bodies added to the blocked set: the milestone's wall must not be the thing that breaks the
## existing winnability guarantee it stands alongside.
func _test_winnability_holds_with_the_wall_standing(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			map.close_streets(closures)
			var boundary := _boundary_keys(region_plan)
			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary)

			var blocked := map.closed_tiles.duplicate()
			for plan_item in seals:
				_add_circle(map, blocked, plan_item.position, plan_item.def.obstructs_radius)
			for plan_item in region_plan.wall_bodies:
				_add_circle(map, blocked, plan_item.position, plan_item.def.obstructs_radius)
			for tile in _main_road_tiles(map):
				blocked[tile] = true

			var grid := ReachabilityGrid.build(map)
			var reached := grid.flood([map.home_rect.position], blocked)
			var some_calm := false
			for tile in map.calm_tiles():
				if grid.reaches(tile, blocked, reached):
					some_calm = true
					break
			t.check(some_calm,
					("seed %d day %d: some calm area is reachable with the region wall standing " +
					"and the main road removed") % [map.seed_used, day])

## Closures and seals are checked before acceptance against the same tree; this checks the region
## boundary is one more thing neither may land on, over the same sweep of days.
func _test_closures_and_seals_never_land_on_a_boundary(t) -> void:
	for map in _maps:
		for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var region_plan := RegionPlanner.plan_day(map, day, tree)
			var boundary := _boundary_keys(region_plan)

			var closure_rng := RandomNumberGenerator.new()
			closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
			var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
			for closure in closures:
				t.check(not boundary.has(closure.segment.key()),
						"seed %d day %d: closure at %s does not land on a region boundary"
						% [map.seed_used, day, closure.segment.key()])

			var seal_rng := RandomNumberGenerator.new()
			seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
			var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary)
			for plan_item in seals:
				var segment := StreetNetwork.segment_containing(map.world_to_tile(plan_item.position))
				if segment:
					t.check(not boundary.has(segment.key()),
							"seed %d day %d: seal at %s does not land on a region boundary"
							% [map.seed_used, day, segment.key()])
