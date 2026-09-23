extends RefCounted
## The power station: one big building on every city, not in the home's region, a reasonable walk
## from the home, on industrial ground where the city has it, with a front door on a real street.
##
## `docs/CITY.md`, "The power station", is the design; `CityGenerator._place_power_station` is the
## placement and `CityGenerator.validate()` the second opinion. This suite asks the cities that come
## out, across a spread of seeds, rather than trusting either.

## Seeds for the generation sweep. Generation is a quarter of a second a city and the guarantee is a
## per-seed refusal whose failures would be one-seed-in-many arrangements, so the sweep is wide.
const SEEDS := 24
const BASE_SEED := 7_140
## How many of those cities the day-14 sweep plans a whole day for — a tree, the region plan, the
## closures and the seals each — which is seconds a city rather than a quarter of one.
const DAY_SEEDS := 10

var _maps: Array[CityMap] = []

func run(t) -> void:
	for i in SEEDS:
		_maps.append(CityGenerator.generate(BASE_SEED + i * 211))
	_test_every_city_has_exactly_one(t)
	_test_it_is_not_in_the_home_region(t)
	_test_its_door_is_a_reasonable_walk_from_home(t)
	_test_the_front_door_is_on_its_long_south_side(t)
	_test_industrial_ground_is_preferred(t)
	_test_the_door_is_reached_on_its_day_through_a_region_door(t)
	_test_no_other_day_is_bent_toward_it(t)

# ------------------------------------------------------------------ generation ---

## One station on every seed, and it is one of the big buildings rather than a thing of its own:
## the rolled count still bounds the lot, and the station is the pair `power_station` names.
func _test_every_city_has_exactly_one(t) -> void:
	for map in _maps:
		t.check(CityGenerator.validate(map) == "",
				"seed %d: the city passes validation (%s)" % [map.seed_used, CityGenerator.validate(map)])
		t.check(map.has_power_station(), "seed %d has a power station" % map.seed_used)
		var matching := 0
		for pair in map.big_buildings:
			if pair == map.power_station:
				matching += 1
		t.check(matching == 1,
				"seed %d: exactly one big building is the power station (%d)" % [map.seed_used, matching])
		t.check(map.big_buildings.size() <= Tuning.MAX_BIG_BUILDINGS,
				"seed %d: the station is counted among at most %d big buildings (%d)"
				% [map.seed_used, Tuning.MAX_BIG_BUILDINGS, map.big_buildings.size()])

## The door's own street ground belongs to another region than the home street's, which with the
## wall standing means reaching it takes a door crossing — the day-14 half of this suite walks it.
func _test_it_is_not_in_the_home_region(t) -> void:
	for map in _maps:
		var street := map.power_station_door_street()
		t.check(street != null, "seed %d: the door opens onto a street" % map.seed_used)
		if not street:
			continue
		var door_region := RegionPlanner.ground_region_of(map, street)
		var home_region := RegionPlanner.home_region(map)
		t.check(door_region >= 0 and home_region >= 0 and door_region != home_region,
				"seed %d: the door is in region %d, the home in %d"
				% [map.seed_used, door_region, home_region])

func _test_its_door_is_a_reasonable_walk_from_home(t) -> void:
	var spread := {}
	for map in _maps:
		var key := map.power_station_door_key
		var away := CityGenerator.blocks_from_home(Vector2i(key.x, key.y - 1))
		spread[away] = spread.get(away, 0) + 1
		t.check(away >= Tuning.POWER_STATION_MIN_BLOCKS_FROM_HOME,
				"seed %d: the door is %d blocks from the home, at least %d"
				% [map.seed_used, away, Tuning.POWER_STATION_MIN_BLOCKS_FROM_HOME])
	print("[test_power_station] door distance from the home block, blocks: count — %s" % spread)

## The door is pavement, directly south of the mass, inside its width, on the street
## `power_station_door_key` names — a real street, which is what makes it a front door rather than
## a painted one.
func _test_the_front_door_is_on_its_long_south_side(t) -> void:
	for map in _maps:
		var pair := map.power_station
		t.check(pair.size == Vector2i(2, 1),
				"seed %d: the station is two blocks wide and one deep (%s)" % [map.seed_used, pair])
		var mass := CityMap.blocks_tile_rect(pair)
		var door := map.power_station_door
		t.check(door.size == Vector2i(CityMap.POWER_STATION_DOOR_TILES, 1),
				"seed %d: the door is %d tiles wide (%s)"
				% [map.seed_used, CityMap.POWER_STATION_DOOR_TILES, door])
		t.check(door.position.y == mass.end.y and door.position.x >= mass.position.x
				and door.end.x <= mass.end.x,
				"seed %d: the door %s is on the south face of %s" % [map.seed_used, door, mass])
		var street := map.power_station_door_street()
		t.check(street != null and street.horizontal and map.has_street(street.key()),
				"seed %d: the door's street is a real east-west street" % map.seed_used)
		for tile in map.rect_tiles(door):
			t.check(map.tile_at(tile) == GameEnums.TileType.SIDEWALK,
					"seed %d: the door's pavement at %s is sidewalk" % [map.seed_used, tile])
			if street:
				t.check(street.tile_rect().has_point(tile),
						"seed %d: the door's pavement %s is on its own street" % [map.seed_used, tile])
			t.check(not map.is_walkable(tile + Vector2i.UP),
					"seed %d: the tile north of the door's pavement %s is the building"
					% [map.seed_used, tile])

## **The preference is an order, and the order is what is held**: both blocks industrial, then one,
## then the pair nearest industrial ground. The sweep prints how often each is what a city got —
## the fallback is taken whenever no free, far-enough industrial pair outside the home region exists,
## which is the common case with the industrial district scattered a block at a time.
func _test_industrial_ground_is_preferred(t) -> void:
	var industrial := {Vector2i(4, 4): true, Vector2i(5, 4): true, Vector2i(8, 8): true}
	var both := CityGenerator.power_station_rank(Rect2i(Vector2i(4, 4), Vector2i(2, 1)), industrial)
	var one := CityGenerator.power_station_rank(Rect2i(Vector2i(7, 8), Vector2i(2, 1)), industrial)
	var beside := CityGenerator.power_station_rank(Rect2i(Vector2i(6, 7), Vector2i(2, 1)), industrial)
	var far := CityGenerator.power_station_rank(Rect2i(Vector2i(1, 1), Vector2i(2, 1)), industrial)
	t.check(both < one and one < beside and beside < far,
			"industrial ground ranks first, then half, then nearest (%d < %d < %d < %d)"
			% [both, one, beside, far])
	var none := {}
	t.check(CityGenerator.power_station_rank(Rect2i(Vector2i(1, 1), Vector2i(2, 1)), none)
			== CityGenerator.power_station_rank(Rect2i(Vector2i(6, 6), Vector2i(2, 1)), none),
			"with no industrial ground every pair ranks the same")

	var got := {0: 0, 1: 0, 2: 0}
	for map in _maps:
		got[map.power_station_industrial_blocks] += 1
	print("[test_power_station] industrial blocks under the station: count — %s" % got)

# ------------------------------------------------------------------ the day ---

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

func _reaches_any(grid: ReachabilityGrid, reached: Dictionary, blocked: Dictionary,
		tiles: Array[Vector2i]) -> bool:
	for tile in tiles:
		if grid.reaches(tile, blocked, reached):
			return true
	return false

## The day she is sent there, planned the way `City.start_day` and `EventManager.start_day` plan it
## — the tree, the region plan from it, the closures off both, the seals — and then flooded from the
## doorstep with every closure's cut ground, every seal body and every wall body standing. The door
## is reached. Flooded again with the region doors shut as well, it is not: every way there crosses
## a region door, which is what the story asks of it.
func _test_the_door_is_reached_on_its_day_through_a_region_door(t) -> void:
	var day := Tuning.POWER_STATION_DAY
	for map: CityMap in _maps.slice(0, DAY_SEEDS):
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var door_street := map.power_station_door_street()
		t.check(door_street != null and tree.is_on_the_tree(door_street.key()),
				"seed %d day %d: the corridor reaches the door's street" % [map.seed_used, day])
		var region_plan := RegionPlanner.plan_day(map, day, tree)
		t.check(not (region_plan.doors.is_empty() and region_plan.alley_doors.is_empty()),
				"seed %d day %d: the wall has a door in it" % [map.seed_used, day])
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
		var closures := ClosurePlanner.plan_day(map, day, closure_rng, tree, region_plan)
		map.close_streets(closures)
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
		seal_rng.seed = hash("seals:%d:%d" % [map.seed_used, day])
		var seals := SealPlanner.plan_day(map, day, tree, seal_rng, boundary)

		var blocked := map.closed_tiles.duplicate()
		for item in seals:
			_add_circle(map, blocked, item.position, item.def.obstructs_radius)
		for item in region_plan.wall_bodies:
			_add_circle(map, blocked, item.position, item.def.obstructs_radius)
		var grid := ReachabilityGrid.build(map)
		var door := map.rect_tiles(map.power_station_door)
		var reached := grid.flood([map.home_rect.position], blocked)
		t.check(_reaches_any(grid, reached, blocked, door),
				"seed %d day %d: the front door is reachable with the day's walls, seals and "
				% [map.seed_used, day] + "%d closures in place" % closures.size())

		var shut := blocked.duplicate()
		for segment in region_plan.doors:
			var default_at_a := RegionPlanner.region_of_junction(map, segment.a) \
					< RegionPlanner.region_of_junction(map, segment.b)
			var at_a: bool = map.boundary_wall_at_a.get(segment.key(), default_at_a)
			for tile in map.rect_tiles(segment.mouth_rect(at_a)):
				shut[tile] = true
		for rect in region_plan.alley_doors:
			var vertical := rect.size.x < rect.size.y
			for at_start in [true, false]:
				for tile in map.rect_tiles(SealPlanner.alley_mouth_rect(rect, vertical, at_start)):
					shut[tile] = true
		var reached_shut := grid.flood([map.home_rect.position], shut)
		t.check(not _reaches_any(grid, reached_shut, shut, door),
				"seed %d day %d: with the region doors shut the front door is out of reach"
				% [map.seed_used, day])

## The day before, the corridor is what it would be with no station at all — the spur is the one
## thing the station's day adds, and nothing else in the tree moves for it on that day either.
func _test_no_other_day_is_bent_toward_it(t) -> void:
	for map: CityMap in _maps.slice(0, DAY_SEEDS):
		var day := Tuning.POWER_STATION_DAY
		_repaint_for(map, day)
		var with_spur := RouteTree.for_day(map, day)
		var without := RouteTree.grow(map, ClosurePlanner.home_street(map),
				ClosurePlanner.calm_areas(map), map.blocked_segments(), ReachabilityGrid.build(map),
				_routes_rng(map, day))
		# Asked of the trees' own node ids, which agree because both grids are built from the same
		# map the same way — a cell can hold two nodes, so a cell-to-tile round trip cannot ask it.
		var kept := 0
		for node: int in without._colours:
			if with_spur._colours.has(node):
				kept += 1
		t.check(kept == without._colours.size(),
				"seed %d: the station's day keeps every cell of the corridor it would have had (%d of %d)"
				% [map.seed_used, kept, without._colours.size()])
		t.check(with_spur.cells().size() >= without.cells().size(),
				"seed %d: and only adds to it" % map.seed_used)

		var before := Tuning.POWER_STATION_DAY - 1
		_repaint_for(map, before)
		var plain := RouteTree.grow(map, ClosurePlanner.home_street(map),
				ClosurePlanner.calm_areas(map), map.blocked_segments(), ReachabilityGrid.build(map),
				_routes_rng(map, before))
		t.check(RouteTree.for_day(map, before).cells().size() == plain.cells().size(),
				"seed %d day %d: an ordinary day's corridor has no spur" % [map.seed_used, before])

func _routes_rng(map: CityMap, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("routes:%d:%d" % [map.seed_used, day])
	return rng
