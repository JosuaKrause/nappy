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
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const MapCache := preload("res://tests/city_map_cache.gd")
const RecordingFrontDrawer := preload("res://tests/recording_front_drawer.gd")
const UI := preload("res://tests/ui_screens.gd")
## The folder the frame recorder of the yard-layer check is handed to write its record in on leaving
## the tree.
const _SCRATCH_RECORDS := "user://test_power_station_scratch_records"

var _maps: Array[CityMap] = []

func run(t: TestRunner) -> void:
	for i in SEEDS:
		_maps.append(MapCache.of(BASE_SEED + i * 211))
	_test_every_city_has_exactly_one(t)
	_test_it_is_not_in_the_home_region(t)
	_test_its_door_is_a_reasonable_walk_from_home(t)
	_test_the_front_door_is_on_its_long_south_side(t)
	_test_industrial_ground_is_preferred(t)
	_test_the_door_is_reached_on_its_day_through_a_region_door(t)
	_test_no_other_day_is_bent_toward_it(t)
	_test_an_older_save_with_the_station_block_advanced_still_loads(t)
	_test_the_yard_layer_is_counted_when_the_station_comes_into_view(t)
	_test_the_stacks_stand_in_the_entities_depth_order(t)
	await _test_the_hall_is_lit_only_on_the_last_night(t)

# ------------------------------------------------------------------ generation ---

## One station on every seed, and it is one of the big buildings rather than a thing of its own:
## the rolled count still bounds the lot, and the station is the pair `power_station` names.
func _test_every_city_has_exactly_one(t: TestRunner) -> void:
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
		t.check(map.big_buildings.size() <= CityGenerator.MAX_BIG_BUILDINGS,
				"seed %d: the station is counted among at most %d big buildings (%d)"
				% [map.seed_used, CityGenerator.MAX_BIG_BUILDINGS, map.big_buildings.size()])

## The door's own street ground belongs to another region than the home street's, which with the
## wall standing means reaching it takes a door crossing — the day-14 half of this suite walks it.
func _test_it_is_not_in_the_home_region(t: TestRunner) -> void:
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

func _test_its_door_is_a_reasonable_walk_from_home(t: TestRunner) -> void:
	var spread := {}
	for map in _maps:
		var key := map.power_station_door_street().key()
		var offset := (Vector2i(key.x, key.y - 1) - map.home_block).abs()
		var away := offset.x + offset.y
		spread[away] = spread.get(away, 0) + 1
		t.check(away >= CityGenerator.POWER_STATION_MIN_BLOCKS_FROM_HOME,
				"seed %d: the door is %d blocks from the home, at least %d"
				% [map.seed_used, away, CityGenerator.POWER_STATION_MIN_BLOCKS_FROM_HOME])
	print("[test_power_station] door distance from the home block, blocks: count — %s" % spread)

## The door is pavement, directly south of the mass, inside its width, on the street
## `power_station_door_street()` names — a real street, which is what makes it a front door rather
## than a painted one.
func _test_the_front_door_is_on_its_long_south_side(t: TestRunner) -> void:
	for map in _maps:
		var pair := map.power_station
		t.check(pair.size == Vector2i(2, 1),
				"seed %d: the station is two blocks wide and one deep (%s)" % [map.seed_used, pair])
		var mass := CityMap.blocks_tile_rect(pair)
		var door := map.power_station_door_tiles()
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
## then the pair nearest industrial ground.
func _test_industrial_ground_is_preferred(t: TestRunner) -> void:
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

# ------------------------------------------------------------------ the day ---

## Cities of their own for a test that plans days on them: repainting and closing streets change a
## map, so a test that does it is handed maps no other test reads, from the same seeds as `_maps`.
func _maps_to_plan_days_on() -> Array[CityMap]:
	var fresh: Array[CityMap] = []
	for i in DAY_SEEDS:
		fresh.append(MapCache.of(BASE_SEED + i * 211))
	return fresh

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
func _test_the_door_is_reached_on_its_day_through_a_region_door(t: TestRunner) -> void:
	var day := Tuning.POWER_STATION_DAY
	for map: CityMap in _maps_to_plan_days_on():
		_repaint_for(map, day)
		var tree := RouteTree.for_day(map, day)
		var door_street := map.power_station_door_street()
		t.check(door_street != null and tree.is_on_the_tree(door_street.key()),
				"seed %d day %d: the corridor reaches the door's street" % [map.seed_used, day])
		var region_plan := RegionPlanner.plan_day(map, DaySpec.for_day(day), tree)
		t.check(not (region_plan.doors.is_empty() and region_plan.alley_doors.is_empty()),
				"seed %d day %d: the wall has a door in it" % [map.seed_used, day])
		var closure_rng := RandomNumberGenerator.new()
		closure_rng.seed = hash("closures:%d:%d" % [map.seed_used, day])
		var closures := ClosurePlanner.plan_day(map, DaySpec.for_day(day),
				closure_rng, tree, region_plan)
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
		var seals := SealPlanner.plan_day(map, DaySpec.for_day(day), tree, seal_rng, boundary)

		var blocked := map.closed_tiles.duplicate()
		for item in seals:
			_add_circle(map, blocked, item.position, item.def.obstructs_radius)
		for item in region_plan.wall_bodies:
			_add_circle(map, blocked, item.position, item.def.obstructs_radius)
		var grid := ReachabilityGrid.build(map)
		var door := map.rect_tiles(map.power_station_door_tiles())
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
			for at_start: bool in [true, false]:
				for tile in map.rect_tiles(SealPlanner.alley_mouth_rect(rect, vertical, at_start)):
					shut[tile] = true
		var reached_shut := grid.flood([map.home_rect.position], shut)
		t.check(not _reaches_any(grid, reached_shut, shut, door),
				"seed %d day %d: with the region doors shut the front door is out of reach"
				% [map.seed_used, day])

## The day before, the corridor is what it would be with no station at all — the spur is the one
## thing the station's day adds, and nothing else in the tree moves for it on that day either.
func _test_no_other_day_is_bent_toward_it(t: TestRunner) -> void:
	for map: CityMap in _maps_to_plan_days_on():
		var day := Tuning.POWER_STATION_DAY
		_repaint_for(map, day)
		var with_spur := RouteTree.for_day(map, day)
		var without := RouteTree.grow(map, ClosurePlanner.home_street(map),
				ClosurePlanner.calm_areas(map), map.blocked_segments(),
				ReachabilityGrid.build(map, Mover.ground()), _routes_rng(map, day))
		# Asked of the cells the trees cover (`RouteTree.cells()`, what the dusk map draws), one entry
		# per node, so a cell two nodes share is counted twice and the question stays the nodes'.
		var kept := 0
		var held := _nodes_by_cell(with_spur)
		var wanted := _nodes_by_cell(without)
		for cell: Vector2i in wanted:
			kept += mini(wanted[cell], held.get(cell, 0))
		t.check(kept == without.cells().size(),
				"seed %d: the station's day keeps every cell of the corridor it would have had (%d of %d)"
				% [map.seed_used, kept, without.cells().size()])
		t.check(with_spur.cells().size() >= without.cells().size(),
				"seed %d: and only adds to it" % map.seed_used)

		var before := Tuning.POWER_STATION_DAY - 1
		_repaint_for(map, before)
		var plain := RouteTree.grow(map, ClosurePlanner.home_street(map),
				ClosurePlanner.calm_areas(map), map.blocked_segments(),
				ReachabilityGrid.build(map, Mover.ground()), _routes_rng(map, before))
		t.check(RouteTree.for_day(map, before).cells().size() == plain.cells().size(),
				"seed %d day %d: an ordinary day's corridor has no spur" % [map.seed_used, before])

## How many of the tree's nodes stand in each cell it covers.
func _nodes_by_cell(tree: RouteTree) -> Dictionary:
	var counts := {}
	for cell in tree.cells():
		counts[cell] = counts.get(cell, 0) + 1
	return counts

func _routes_rng(map: CityMap, day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("routes:%d:%d" % [map.seed_used, day])
	return rng

# ------------------------------------------------------------------ saves ---

## A save holds the run seed, not the city, so a save written before the station existed is
## restored onto this build's city — where one of the blocks it had boarded up or burnt may now be
## the station, whose arc has one step. Built here the way such a save arrives: a `CityState`
## snapshot through JSON, with a station block recorded past step 0. It loads: the block reads as
## the station for the whole run, the day's arcs advance around it, and the mass stays solid.
func _test_an_older_save_with_the_station_block_advanced_still_loads(t: TestRunner) -> void:
	var map := MapCache.of(BASE_SEED)
	var block := map.power_station.position
	var plan: BlockPlan = map.block_plans[block]
	t.check(plan.steps.size() == 1, "the station's block has a one-step arc (%d)" % plan.steps.size())
	var saved := {"stage": [{"x": block.x, "y": block.y, "v": 2}],
			"changed_on": [{"x": block.x, "y": block.y, "v": 5}]}
	var data: Dictionary = JSON.parse_string(JSON.stringify(saved))
	var state := CityState.new()
	state.restore(data)
	t.check(state.purpose_of(map.block_plans, block) == GameEnums.BlockPurpose.BIG_BUILDING,
			"a stage past the station's arc reads as the station")
	state.begin_day(map.block_plans, Tuning.POWER_STATION_DAY)
	map.repaint(state)
	t.check(state.purpose_of(map.block_plans, block) == GameEnums.BlockPurpose.BIG_BUILDING,
			"and stays the station once the day's arcs have advanced")
	var solid := true
	for tile in map.rect_tiles(CityMap.blocks_tile_rect(map.power_station)):
		if map.is_walkable(tile):
			solid = false
			break
	t.check(solid, "the station's mass is still solid after the repaint")
	t.check(not state.calm_blocks(map.block_plans).is_empty(), "the city still has calm ground")

# --------------------------------------------------------------------- drawing ---

## PLAYTEST-143: "the chimneys of the power plant render behind the player. they should be in
## front." A stack rises past the station's lot into the street north of it, so it stands in the
## city's y-sorted `Entities` layer at its own foot, where the engine draws it over anything whose
## origin is north of that foot and under anything south of it — never in the `Buildings` layer,
## which is drawn beneath every entity. Asked of a real city, since the wiring is `City`'s: the one case here that builds one.
func _test_the_stacks_stand_in_the_entities_depth_order(t: TestRunner) -> void:
	var city: City = RunCity.with_own_run(CITY_SCENE, BASE_SEED)
	t.add_child(city)
	city.build(MapCache.of(BASE_SEED))
	var entities: Node2D = city.get_node("Entities")
	var buildings: Node2D = city.get_node("Buildings")
	t.check(entities.y_sort_enabled and entities.z_index > buildings.z_index,
			"Entities is the y-sorted layer above the buildings")
	var station: Building = null
	for child in buildings.get_children():
		if child is Building and (child as Building).power_station:
			station = child
	t.check(station != null, "the city has a power station building")
	if station == null:
		city.free()
		return
	var stacks: Array[Node2D] = []
	for child in entities.get_children():
		if child is Building.StationStack:
			stacks.append(child)
	var feet := station.stack_feet()
	t.check(feet.size() == 2 and stacks.size() == feet.size(),
			"one stack in Entities per foot on the hall's roof (%d stacks, %d feet)"
			% [stacks.size(), feet.size()])
	var in_buildings := 0
	for node in buildings.find_children("*", "Node2D", true, false):
		if node is Building.StationStack:
			in_buildings += 1
	t.check(in_buildings == 0, "no stack is left in the building layer (%d)" % in_buildings)
	var lot := city.map.tile_rect_to_world(CityMap.blocks_tile_rect(city.map.power_station))
	var height := float(AtlasTable.baked().native_size(Building.POWER_STATION_STACK).y)
	for i in mini(stacks.size(), feet.size()):
		var stack := stacks[i]
		var foot := station.position + feet[i]
		t.check(stack.position.is_equal_approx(foot),
				"stack %d stands at its foot %s (%s)" % [i, foot, stack.position])
		t.check(lot.has_point(foot) and foot.y - height < lot.position.y,
				"stack %d's foot is on the lot and its picture rises past the lot's north edge" % i)
		# The case the player saw: walkable ground under the picture, past the lot's north edge and
		# so north of the foot, where she stands behind the stack and the y-sort draws it over her.
		var behind := 0
		var y := lot.position.y - Tuning.TILE_SIZE * 0.5
		while y > foot.y - height:
			if city.map.is_walkable(city.map.world_to_tile(Vector2(foot.x, y))):
				behind += 1
			y -= Tuning.TILE_SIZE
		t.check(behind > 0, "stack %d's picture reaches walkable ground behind it (%d tiles)"
				% [i, behind])
	city.free()

## The hall is dimly lit on the one night it is seen to go out, and drawn as approved on every other.
## A station hall of the shape a city dresses its own in (the values a generated seed's station
## building has: a 704 x 256 px lot, a door at column 3, a yard of 8 columns from column 14), handed a
## drawer that records its front, as the city hands it the real one; what is checked is the clerestory
## band the front was drawn with. What puts the light out on the last night is `tests/test_blackout.gd`'s.
func _test_the_hall_is_lit_only_on_the_last_night(t: TestRunner) -> void:
	var hall := Building.new()
	var front := RecordingFrontDrawer.new()
	hall.front_drawer = front
	hall.power_station = true
	hall.station_door_col = 3
	hall.station_yard_cols = Vector2i(14, 8)
	hall.stand_on(Rect2i(), Vector2(704.0, 256.0), 0, GameEnums.BlockPurpose.INDUSTRIAL, 128.0)
	hall.day = Tuning.POWER_STATION_DAY
	hall.powered = true
	t.add_child(hall)
	await UI.frames(t, 2)
	var band := _clerestory_band(front)
	var columns := hall.hall_cols().y - hall.hall_cols().x
	t.check(columns > 0 and band.size() == columns
			and band.count(Building.POWER_STATION_CLERESTORY_LIT) == columns,
			"on the last night, with the power on, the hall is lit (%s)" % [band])
	var yards := front.pictures().count(Building.POWER_STATION_YARD)
	t.check(yards == 1, "and its yard is stood beside it, once (%d)" % yards)
	front.draws.clear()
	hall.powered = false
	await UI.frames(t, 2)
	band = _clerestory_band(front)
	t.check(band.size() == columns and band.count(Building.POWER_STATION_CLERESTORY) == columns,
			"and with it off, the hall is dark (%s)" % [band])
	front.draws.clear()
	hall.powered = true
	hall.day = Tuning.POWER_STATION_DAY - 1
	await UI.frames(t, 2)
	band = _clerestory_band(front)
	t.check(band.size() == columns and band.count(Building.POWER_STATION_CLERESTORY) == columns,
			"on any other day the hall is unlit, as it always was (%s)" % [band])
	hall.free()

## The pictures the hall's clerestory band shows now, read off what its front was last drawn with.
## Empty when the front has not been drawn since `front` was cleared.
func _clerestory_band(front: RecordingFrontDrawer) -> Array[StringName]:
	var band: Array[StringName] = []
	for entry in front.shown():
		if entry.picture in [Building.POWER_STATION_CLERESTORY, Building.POWER_STATION_CLERESTORY_LIT]:
			band.append(entry.picture)
	return band

## The yard layer is built when residency brings the station into view, in a tree whose frame record
## is listening: the recorder classifies a node as it is added, so the layer carries its kind
## before it enters the tree, and its draws land in the scenery count.
func _test_the_yard_layer_is_counted_when_the_station_comes_into_view(t: TestRunner) -> void:
	var record := FrameRecord.new()
	var ledger := FrameLedger.new(2)
	record.start(ledger)
	var sitting := Sitting.new()
	sitting.frame_timing = record
	# Its saved record goes to a scratch folder, and the run it names the file by is the test's own.
	var run := RunState.new()
	var recorder := FrameRecorder.new()
	t.add_child(recorder)
	recorder.setup(func() -> bool: return false, null, null, SceneryGround.Mode.ONE, null, null,
			run, sitting, _SCRATCH_RECORDS)
	var station := Building.new()
	station.stand_on(Rect2i(), Vector2(96.0, 256.0), 0, GameEnums.BlockPurpose.INDUSTRIAL, 64.0)
	station.power_station = true
	station.equip(null, null, null)
	t.add_child(station)
	station.residence().set_resident(true)
	ledger.process_start(Time.get_ticks_usec())
	var layers := 0
	for child in station.get_children():
		if child is Node2D and child.has_meta(FrameTiming.DRAW_KIND_META):
			layers += 1
			for connection: Dictionary in (child as Node2D).draw.get_connections():
				var drawn_with: Callable = connection["callable"]
				if drawn_with.get_object() == recorder:
					drawn_with.call()
	t.check(layers == 1, "the station's yard layer declares its kind (%d layers)" % layers)
	# The frame the draws landed in is kept, and the next one begins: the ledger hands it out as a row.
	ledger.keep = true
	ledger.process_end(Time.get_ticks_usec())
	ledger.process_start(Time.get_ticks_usec())
	var rows := ledger.rows()
	t.check(rows.size() == 1 and rows[0][FrameLedger.FIRST_COUNTER + FrameLedger.DRAWS_CROWD + FrameTiming.Draw.SCENERY] == 1,
			"a yard layer built into a listening tree is counted as scenery")
	station.free()
	recorder.free()
	var written := sitting.frame_record_file()
	sitting.free()
	if written != "":
		DirAccess.remove_absolute(ProjectSettings.globalize_path(written))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_SCRATCH_RECORDS))
