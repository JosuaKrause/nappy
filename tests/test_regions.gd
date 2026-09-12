extends RefCounted
## `RegionPlanner`: the lattice's junctions partition into `Tuning.REGION_COUNT` regions at
## generation, and from `Tuning.REGION_WALL_FIRST_DAY` a day's `RouteTree` turns the permanent
## boundary — segments and crossing alleys alike — into a wall with doors in it.
##
## `docs/CITY.md`, "Regions and the wall" is the design; `src/routes/region_planner.gd` is the
## implementation. The flood check (`_test_flood_matches_the_partition`) is the one a segment-level
## check cannot do — see `docs/TODO.md`, M62, "The checks are floods over cells, not counts over
## segments" — because it is the only one that would catch a courtyard archway an atom failed to
## keep whole, or a wall body's circle bleeding sideways into ground it was never meant to cover.
##
## Alleys are not atoms here — see `RegionPlanner._union_atoms`'s own doc for why unioning one's
## two bordering streets chained most of the lattice into a single atom on six measured seeds — so
## this suite tests them as the second kind of crossing they are instead: `_alley_border_segments`,
## `alley_mouth_ground_region` and the day's `alley_doors`/`alley_walls` split.

const SEEDS := 6
const BASE_SEED := 260917

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 137))
	_test_partition_covers_every_real_junction(t)
	_test_assignment_is_deterministic(t)
	_test_calm_atoms_are_never_boundary(t)
	_test_the_home_street_is_never_boundary(t)
	_test_precinct_spans_are_never_boundary(t)
	_test_flood_matches_the_partition(t)
	_test_no_wall_before_the_first_day(t)
	_test_the_day_plan_shape(t)
	_test_crossing_alleys_are_consistent(t)
	_test_wall_bodies_never_cover_an_alley_mouth(t)
	_test_alley_wall_bodies_fit_their_own_mouth(t)
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

## Every key `EventManager.start_day` hands `SealPlanner.plan_day` as `skip` for this plan —
## segment keys (`Vector3i`) for walls and doors, and an alley rect's own `position` (`Vector2i`)
## for a crossing alley, wall or door. The two types never collide in one `Dictionary`.
func _boundary_keys(plan: RegionPlanner.RegionPlan) -> Dictionary:
	var keys := {}
	for segment in plan.walls:
		keys[segment.key()] = true
	for segment in plan.doors:
		keys[segment.key()] = true
	for rect in plan.alley_walls:
		keys[rect.position] = true
	for rect in plan.alley_doors:
		keys[rect.position] = true
	return keys

## The tiles of one mouth of an alley rect — the same one-tile-deep band
## `SealPlanner.alley_mouth_rect` builds, called directly rather than duplicated here.
func _alley_mouth_tiles(map: CityMap, rect: Rect2i, vertical: bool, at_start: bool) -> Array[Vector2i]:
	return map.rect_tiles(SealPlanner.alley_mouth_rect(rect, vertical, at_start))

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

## Which end of `segment`'s wall the map assigns, defaulting the same way `RegionPlanner.
## _assign_wall_ends` does — a helper rather than reaching `map.boundary_wall_at_a` directly at
## every call site below.
func _wall_at_a(map: CityMap, segment: StreetNetwork.Segment) -> bool:
	var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
			< RegionPlanner.region_of_junction(map, segment.b)
	return map.boundary_wall_at_a.get(segment.key(), default_at_a)

## The check a segment-level rule cannot do: block every boundary segment's one-tile mouth strip
## (`Segment.mouth_rect`, at whichever end `map.boundary_wall_at_a` names) and every crossing
## alley's two mouths, then flood from the doorstep. Every real segment's ground —
## `RegionPlanner.ground_region_of`, which is a boundary segment's **far** end now rather than
## either end alike — resolves to reached exactly when it is the home region and not reached
## otherwise, proving the partition and the tile-level ground agree everywhere. A boundary
## segment's own walled mouth tiles are excluded from the per-tile check: they are blocked ground,
## reached from neither side, so asserting them against either region would fail by construction
## rather than say anything about the partition.
func _test_flood_matches_the_partition(t) -> void:
	var checked_cells := 0
	for map in _maps:
		var blocked := {}
		var wall_mouth_tiles := {}
		for segment in RegionPlanner.boundary_segments(map):
			var at_a := _wall_at_a(map, segment)
			for tile in map.rect_tiles(segment.mouth_rect(at_a)):
				blocked[tile] = true
				wall_mouth_tiles[tile] = true
		for rect in map.alley_rects:
			var info := RegionPlanner._alley_border_segments(map, rect)
			if info.is_empty():
				continue
			var ground_a := RegionPlanner.alley_mouth_ground_region(map, info[0])
			var ground_b := RegionPlanner.alley_mouth_ground_region(map, info[1])
			if ground_a < 0 or ground_b < 0 or ground_a == ground_b:
				continue   # not a (detectable) crossing
			var vertical: bool = info[2]
			for at_start in [true, false]:
				for tile in _alley_mouth_tiles(map, rect, vertical, at_start):
					blocked[tile] = true

		var grid := ReachabilityGrid.build(map)
		var doorstep := map.world_to_tile(map.doorstep_world_position())
		var reached := grid.flood([doorstep], blocked)
		var home := RegionPlanner.home_region(map)
		for segment in StreetNetwork.segments():
			if not map.has_street(segment.key()):
				continue
			var region := RegionPlanner.ground_region_of(map, segment)
			if region < 0:
				continue
			var should_reach := region == home
			for tile in map.rect_tiles(segment.tile_rect()):
				if wall_mouth_tiles.has(tile):
					continue
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
## on the tree, unconditionally; every wall is off the tree, unconditionally — the tree wins over
## the partition, full stop, so there is no third rule left to check them against. The home region
## has a door, or every calm area the tree reaches is in the home region — the unconditional form
## the design's own argument always supported, restated as itself now that nothing narrows it.
## Also measures how often a calm-less region gets a door at all (the tree crossing it, which the
## milestone's decree says must win when it happens) and every region the day's tree actually
## reaches a calm area in is reached from the doorstep once only the doors are open.
func _test_the_day_plan_shape(t) -> void:
	var sampled_days := 0
	var total_walls := 0
	var total_doors := 0
	var calmless_region_had_a_door := 0
	for map in _maps:
		for day in range(Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS + 1):
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			var calm := RegionPlanner.regions_with_calm(map)
			var home := RegionPlanner.home_region(map)
			var areas := ClosurePlanner.calm_areas(map)
			sampled_days += 1
			total_walls += plan.walls.size()
			total_doors += plan.doors.size()

			var this_day_had_a_calmless_door := false
			for segment in plan.doors:
				t.check(tree.is_on_the_tree(segment.key()),
						"seed %d day %d: door %s is on the day's tree" % [map.seed_used, day, segment.key()])
				var ra := RegionPlanner.region_of_junction(map, segment.a)
				var rb := RegionPlanner.region_of_junction(map, segment.b)
				if (ra >= 0 and ra < calm.size() and calm[ra] == 0) \
						or (rb >= 0 and rb < calm.size() and calm[rb] == 0):
					this_day_had_a_calmless_door = true
			if this_day_had_a_calmless_door:
				calmless_region_had_a_door += 1

			for segment in plan.walls:
				t.check(not tree.is_on_the_tree(segment.key()),
						"seed %d day %d: wall %s is off the day's tree" % [map.seed_used, day, segment.key()])

			# "The home region has a door, or every calm area the tree reaches is in the home
			# region" — unconditional: the tree-wins rule needs no premise about which regions
			# hold calm to make this true.
			var home_reaches_only_home := true
			for branch in tree.branches:
				var area := _area_for_block(areas, branch.area)
				if not area or area.access.is_empty():
					continue
				if RegionPlanner.region_of_junction(map, area.access[0].a) != home:
					home_reaches_only_home = false
					break
			var boundary_count := plan.walls.size() + plan.doors.size()
			if boundary_count > 0 and not home_reaches_only_home:
				var home_has_door := false
				for segment in plan.doors:
					if RegionPlanner.region_of_junction(map, segment.a) == home \
							or RegionPlanner.region_of_junction(map, segment.b) == home:
						home_has_door = true
						break
				t.check(home_has_door,
						("seed %d day %d: the home region has a door, or every calm area the tree " +
						"reaches is in it (%d boundary segments)") % [map.seed_used, day, boundary_count])

			var blocked := {}
			for plan_body in plan.wall_bodies:
				_add_circle(map, blocked, plan_body.position, plan_body.def.obstructs_radius)
			var grid := ReachabilityGrid.build(map)
			var doorstep := map.world_to_tile(map.doorstep_world_position())
			var reached := grid.flood([doorstep], blocked)
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
	print(("[test_regions] over %d sampled (seed, day) pairs: %d walls, %d doors; a calm-less " +
			"region had a door on %d of them (the tree crossing it, which the decree says wins)")
			% [sampled_days, total_walls, total_doors, calmless_region_had_a_door])

## A crossing alley — `ground_region_of` differs at its two real bordering streets — is a door
## exactly when the tree uses one of its own tiles, and a wall otherwise; every alley the day
## classifies either way is confirmed to actually be a crossing (`ground_region_of` really does
## differ), and every non-crossing alley is confirmed to stay off both lists, left to the ordinary
## M64 sealing pass as it always was. Also counts how many alleys are crossings, the measurement
## the coordinator asked the generation-time pass to report.
func _test_crossing_alleys_are_consistent(t) -> void:
	var crossing_alleys := 0
	var total_alleys := 0
	for map in _maps:
		for rect in map.alley_rects:
			var info := RegionPlanner._alley_border_segments(map, rect)
			if info.is_empty():
				continue
			var ground_a := RegionPlanner.alley_mouth_ground_region(map, info[0])
			var ground_b := RegionPlanner.alley_mouth_ground_region(map, info[1])
			if ground_a < 0 or ground_b < 0:
				continue   # neither a real nor a readable dead-end ground on one side; not counted
			total_alleys += 1
			if ground_a != ground_b:
				crossing_alleys += 1
		for day in [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS]:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			for rect in plan.alley_doors + plan.alley_walls:
				var info := RegionPlanner._alley_border_segments(map, rect)
				var ok := false
				if not info.is_empty():
					var ga := RegionPlanner.alley_mouth_ground_region(map, info[0])
					var gb := RegionPlanner.alley_mouth_ground_region(map, info[1])
					ok = ga >= 0 and gb >= 0 and ga != gb
				t.check(ok, "seed %d day %d: alley %s classified as a door or a wall is a real crossing"
						% [map.seed_used, day, rect.position])
			for rect in plan.alley_doors:
				var on_tree := false
				for tile in map.rect_tiles(rect):
					if not tree.branches_on(tile).is_empty():
						on_tree = true
						break
				t.check(on_tree, "seed %d day %d: alley door %s is on the day's tree"
						% [map.seed_used, day, rect.position])
			for rect in plan.alley_walls:
				var on_tree := false
				for tile in map.rect_tiles(rect):
					if not tree.branches_on(tile).is_empty():
						on_tree = true
						break
				t.check(not on_tree, "seed %d day %d: alley wall %s is off the day's tree"
						% [map.seed_used, day, rect.position])
	t.check(total_alleys > 0, "at least one alley with two real bordering streets was checked (%d)"
			% total_alleys)
	# Not a pass/fail bound — the measurement the coordinator asked for.
	print("[test_regions] %d of %d alleys with two real bordering streets are crossings"
			% [crossing_alleys, total_alleys])

## The wall's own mouth bodies never reach an alley's mouth tiles — the defect a midpoint band had
## (a roadblock's 60px reaches roughly two tiles along the street, wide enough to cover an alley
## mouth at offset 4 outright). Checked against **every** alley, not only crossings, since the
## concern is a segment wall body bleeding sideways into unrelated ground.
func _test_wall_bodies_never_cover_an_alley_mouth(t) -> void:
	var checked := 0
	for map in _maps:
		var alley_mouth_tiles := {}
		for rect in map.alley_rects:
			if map.tile_at(rect.position) != GameEnums.TileType.ALLEY:
				continue
			var vertical := rect.size.x < rect.size.y
			for at_start in [true, false]:
				for tile in _alley_mouth_tiles(map, rect, vertical, at_start):
					alley_mouth_tiles[tile] = true
		if alley_mouth_tiles.is_empty():
			continue
		for day in [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS]:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			for segment in plan.walls:
				var at_a := _wall_at_a(map, segment)
				for body in SealPlanner.place_hard_on(map, segment, RegionPlanner._WALL_DEF_ID, at_a):
					checked += 1
					for tile: Vector2i in alley_mouth_tiles:
						var distance := map.tile_to_world(tile).distance_to(body.position)
						t.check(distance > body.def.obstructs_radius,
								("seed %d day %d: a wall body at %s (radius %.0f) does not reach " +
								"alley mouth tile %s (%.0fpx away)")
								% [map.seed_used, day, body.position, body.def.obstructs_radius,
								tile, distance])
	t.check(checked > 0, "at least one wall body was checked against every alley mouth (%d)" % checked)

## A crossing alley's own wall bodies draw and collide no wider than the alley's own paving — the
## defect `docs/playtests/PLAYTEST-57.md`, "Roofs" reported: a barrier band drawn over the roof
## edges of the lots either side of an alley mouth, because the wall's body kept the catalogue
## `roadblock` row's own 120px reach (`GroundShape.band(60.0)`) rather than the alley's own 64px
## width (`Tuning.ALLEY_WIDTH_TILES * Tuning.TILE_SIZE`).
## `RegionPlanner._alley_mouth_wall_body()` trims it to a point that draws and collides at exactly
## the alley's own width, so this checks the drawn extent (`2 * obstructs_radius`, what
## `EventInstance._draw_spread` actually paints) stays within the alley's own tile rect on the
## across-alley axis — no tolerance needed, since the fit is exact rather than merely close.
func _test_alley_wall_bodies_fit_their_own_mouth(t) -> void:
	var checked := 0
	for map in _maps:
		for day in [Tuning.REGION_WALL_FIRST_DAY, Tuning.RUN_LENGTH_DAYS]:
			_repaint_for(map, day)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			for rect in plan.alley_walls:
				var info := RegionPlanner._alley_border_segments(map, rect)
				if info.is_empty():
					continue
				var vertical: bool = info[2]
				var world := map.tile_rect_to_world(rect)
				var low: float = world.position.x if vertical else world.position.y
				var high: float = world.end.x if vertical else world.end.y
				for at_start in [true, false]:
					checked += 1
					var body := RegionPlanner._alley_mouth_wall_body(map, rect, vertical, at_start)
					var centre: float = body.position.x if vertical else body.position.y
					var half := body.def.obstructs_radius
					t.check(centre - half >= low - 0.01 and centre + half <= high + 0.01,
							("seed %d day %d: alley wall body at %s (half-width %.0f) draws within " +
							"the alley's own mouth %.0f..%.0f, not over the lots either side")
							% [map.seed_used, day, body.position, half, low, high])
	t.check(checked > 0, "at least one alley wall body was checked against its own mouth (%d)" % checked)

## The core guarantee, unconditionally: with the region wall standing alongside the day's closures
## and seals, some calm area is still reachable from the doorstep. The wall never stands on tree
## ground (a wall is only ever an *off*-tree boundary crossing), so this can never fail without the
## tree/closure/seal guarantees it sits beside already having failed.
##
## Also reuses `tests/test_seals.gd`'s stronger reachability-**without**-the-main-road shape, with
## the region wall's own bodies added to the blocked set — but measured rather than hard-asserted.
## **Found on one sampled (seed, day): the region wall can close off the specific alternate route
## that avoids the main road, while the tree's own guaranteed route (which may cross the main road)
## and the core guarantee above both stay intact.** The two checks above it in `test_seals.gd` never
## had to draw this distinction because nothing there could wall an *off*-tree alternate: the base
## system's own "avoid the main road" route is not necessarily the tree's own route, and once every
## other off-tree crossing is also walled, an alternate that happened to dodge the main road can run
## out of ground of its own. This is not the two-calm-areas-reachable invariant weakening — that one
## is the hard check above and it holds everywhere sampled — it is a narrower, stronger property the
## region wall's own contracts never promised, so it is reported as a rate rather than asserted.
func _test_winnability_holds_with_the_wall_standing(t) -> void:
	var without_main_road_days := 0
	var without_main_road_held := 0
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

			var grid := ReachabilityGrid.build(map)
			var reached := grid.flood([map.home_rect.position], blocked)
			var some_calm := false
			for tile in map.calm_tiles():
				if grid.reaches(tile, blocked, reached):
					some_calm = true
					break
			t.check(some_calm,
					("seed %d day %d: some calm area is reachable with the region wall standing")
					% [map.seed_used, day])

			var blocked_no_road := blocked.duplicate()
			for tile in _main_road_tiles(map):
				blocked_no_road[tile] = true
			var reached_no_road := grid.flood([map.home_rect.position], blocked_no_road)
			without_main_road_days += 1
			for tile in map.calm_tiles():
				if grid.reaches(tile, blocked_no_road, reached_no_road):
					without_main_road_held += 1
					break
	# Not a pass/fail bound — see this function's own doc for why the stronger property is
	# measured rather than asserted.
	print("[test_regions] reachable without the main road too, with the wall standing: %d of %d"
			% [without_main_road_held, without_main_road_days])

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
