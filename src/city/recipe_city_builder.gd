class_name RecipeCityBuilder
extends RefCounted
## Loads authored stretches directly; constructs other scopes with exact choices and a global witness.
## Never searches whole-city seeds and never moves a requested placement after construction.

static func build(data: Dictionary) -> Dictionary:
	var errors := SceneRecipe.validate(data)
	var result := {"map": null, "anchors": {}, "errors": errors, "manifest": {}}
	if not errors.is_empty():
		return result
	if data.extent.scope == "stretch":
		return _build_authored(data, errors)
	var choices: Dictionary = data.city
	var purpose_counts := {}
	var zones := 0
	var complexes := 0
	var courts := 0
	var calm := 0
	for pin: Dictionary in choices.get("lots", []):
		var purpose: int = GameEnums.BlockPurpose[str(pin.purpose).to_upper()]
		purpose_counts[purpose] = int(purpose_counts.get(purpose, 0)) + 1
		var multi := SceneRecipe.rect(pin.blocks).size != Vector2i.ONE
		if CityGenerator._OPEN_CALM.has(purpose):
			calm += 1
			zones += int(multi)
		elif purpose == GameEnums.BlockPurpose.COURTYARD:
			complexes += int(multi)
			courts += int(not multi)
	for purpose: int in CityGenerator._BUILT_TARGETS:
		if int(purpose_counts.get(purpose, 0)) > int(CityGenerator._BUILT_TARGETS[purpose]):
			errors.append("lot.count: exceeds the ordinary purpose quota")
	if zones > Tuning.MAX_CALM_ZONES or complexes > Tuning.MAX_APARTMENT_COMPLEXES \
			or courts > Tuning.MAX_COURTYARD_BLOCKS or calm > Tuning.MAX_CALM_BLOCKS:
		errors.append("lot.count: exceeds an ordinary calm-lot quota")
	if choices.has("precincts"):
		var shore: Array = choices.precincts[0]
		var inland: Array = choices.precincts[1]
		if int(shore[0]) != 0 or int(shore[1]) != Tuning.CITY_BLOCKS.y:
			errors.append("precinct.shore: first span must be on the southern shore")
		if int(inland[1]) < 1 or int(inland[1]) >= Tuning.CITY_BLOCKS.x:
			errors.append("precinct.inland: second span must be inland")
	if choices.get("dead_ends", []).size() > Tuning.MAX_CUL_DE_SACS:
		errors.append("dead_end.count: more pins than the ordinary generator permits")
	for pin: Dictionary in choices.get("layouts", []):
		var block := Vector2i(int(pin.block[0]), int(pin.block[1]))
		if not Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS).has_point(block):
			errors.append("layout.block: pin outside the block lattice")
	for pin: Dictionary in choices.get("dead_ends", []):
		var key := Vector3i(int(pin.segment[0]), int(pin.segment[1]), int(pin.segment[2]))
		if not StreetNetwork.by_key(key):
			errors.append("dead_end.segment: unknown lattice segment")
	if not errors.is_empty():
		return result
	var map := CityGenerator._attempt(int(choices.context_seed), choices)
	_move_street_trees(map, choices.get("tree_moves", []), errors)
	for pin: Dictionary in choices.get("lots", []):
		var footprint := SceneRecipe.rect(pin.blocks)
		var purpose: int = GameEnums.BlockPurpose[str(pin.purpose).to_upper()]
		if map.lot_blocks(footprint.position) != footprint or map.starting_purpose(footprint.position) != purpose:
			errors.append("lot.replaced: requested purpose or footprint did not survive construction")
	if choices.has("precincts"):
		var inland: Vector4i = map.precinct_spans[1]
		if inland.x == 1 and absi(inland.y - map.main_road) <= 1:
			errors.append("precinct.spine: inland precinct cannot occupy the spine or its neighbor")
	for pin: Dictionary in choices.get("layouts", []):
		var block := Vector2i(int(pin.block[0]), int(pin.block[1]))
		if not map.block_layouts.has(block) or map.starting_purpose(block) == GameEnums.BlockPurpose.BIG_BUILDING:
			errors.append("layout.unused: requested layout belongs to an absorbed or replaced lot")
	errors.append_array(map.recipe_diagnostics)
	if not errors.is_empty():
		return result
	var violations: Array[String] = []
	for problem in CityGenerator.validation_problems(map):
		violations.append("city.guarantee:" + problem)
	var expected: Array = data.get("expected_violations", [])
	for violation in violations:
		if not expected.has(violation):
			errors.append(violation)
	for code: String in expected:
		if not violations.has(code):
			errors.append("fixture.missing: " + code)
	if not errors.is_empty():
		return result
	_plan_closures(data, map, errors)
	if not errors.is_empty():
		return result
	var bounds := Rect2i(Vector2i.ZERO, map.size)
	if data.extent.scope == "bounded":
		bounds = SceneRecipe.rect(data.extent.bounds)
		# A bounded view must retain whole footprints. Cutting a building at a camera-sized
		# rectangle would leave its collider, roof and floor disagreeing at the seam.
		for footprint in map.building_rects:
			if footprint.intersects(bounds) and not bounds.encloses(footprint):
				errors.append("extent.cuts_building: %s" % [footprint])
		for closure in map.recipe_closures:
			if not bounds.encloses(closure.segment.tile_rect()):
				errors.append("extent.closure: authored closure must fit inside the bounds")
		for source: Vector2i in map.recipe_tree_moves:
			if not bounds.has_point(source) or not bounds.has_point(map.recipe_tree_moves[source]):
				errors.append("extent.tree_moves: both sides of a selected tree move must fit inside bounds")
		map.recipe_bounds = bounds
		map.recipe_exterior = true
	var anchors := {}
	for name: String in data.get("anchors", {}):
		var spec: Variant = data.anchors[name]
		var at := Vector2.ZERO
		if spec is String:
			if spec == "power_station_door" and not map.has_power_station():
				errors.append("anchor.landmark: power station is absent")
			at = map.doorstep_world_position() if spec == "doorstep" else map.power_station_door_position()
		elif spec.has("world"):
			at = Vector2(float(spec.world[0]), float(spec.world[1]))
		elif spec.has("tile"):
			at = map.tile_to_world(Vector2i(int(spec.tile[0]), int(spec.tile[1])))
		else:
			var tile := Vector2i(int(spec.junction[0]), int(spec.junction[1])) * CityMap.period()
			var side: String = spec.side
			if side.ends_with("east"):
				tile.x += Tuning.STREET_WIDTH - 1
			if side.begins_with("south"):
				tile.y += Tuning.STREET_WIDTH - 1
			at = map.tile_to_world(tile)
		if not bounds.has_point(map.world_to_tile(at)) \
				or (map.has_stretch() and not _on_the_stretch(map, map.world_to_tile(at))):
			errors.append("anchor.extent: %s lies outside the authored %s" % [name,
					"stretch" if map.has_stretch() else "bounds"])
		anchors[name] = at
	if not errors.is_empty():
		return result
	result.map = map
	result.anchors = anchors
	result.manifest = {"classification": data.get("classification", "normal"),
			"scope": data.extent.scope, "bounds": [bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y],
			"context_seed": int(choices.context_seed), "seed": int(data.seed),
			"checks": ["construction_schema", "production_choice_predicates", "whole_visible_footprints"],
			"expected_violations": expected, "violations": violations,
			"choices": choices.duplicate(true), "anchors": anchors.duplicate()}
	if violations.is_empty():
		result.manifest.checks.append("full_context_guarantees")
	return result

## An authored scene has no generation step. Its saved context supplies off-camera topology;
## visible tile, lot and tree lists are authoritative and feed the same map every rule reads.
static func _build_authored(data: Dictionary, errors: Array[String]) -> Dictionary:
	var map := RecipeCityContext.restore(data.context)
	var result := {"map": null, "anchors": {}, "errors": errors, "manifest": {}}
	var stretch: Dictionary = data.stretch
	map.stretch.resize(map.size.x * map.size.y)
	for type_name: String in stretch.tiles:
		var type: int = GameEnums.TileType[type_name.to_upper()]
		for run: Array in stretch.tiles[type_name]:
			for x in range(int(run[1]), int(run[2]) + 1):
				var tile := Vector2i(x, int(run[0]))
				if not map.in_bounds(tile):
					errors.append("stretch.tiles: %s outside the map" % tile)
					continue
				var index := tile.y * map.size.x + tile.x
				if map.stretch[index] != 0:
					errors.append("stretch.tiles: %s listed twice" % tile)
				map.stretch[index] = 1
				map.tiles[index] = type
	# The saved context's fronting lots are not a second authority for the visible buildings.
	# Remove them, then install precisely the authored list, including a moved or newly added lot.
	var retained: Array[Rect2i] = []
	for lot in map.building_rects:
		if not _fronts_the_stretch(map, lot):
			retained.append(lot)
	map.building_rects = retained
	for listed: Dictionary in stretch.get("buildings", []):
		var lot := SceneRecipe.rect(listed.lot)
		if not Rect2i(Vector2i.ZERO, map.size).encloses(lot) or not lot.has_area():
			errors.append("stretch.buildings: lot outside the map or empty")
			continue
		if not _fronts_the_stretch(map, lot):
			errors.append("stretch.buildings: lot %s does not front the stretch" % lot)
		for tile in map.rect_tiles(lot):
			if map.in_stretch(tile):
				errors.append("stretch.buildings: lot overlaps authored ground at %s" % tile)
		map.fill_rect(lot, GameEnums.TileType.BUILDING)
		map.building_rects.append(lot)
		map.stretch_buildings[lot] = {"district": GameEnums.BlockPurpose[str(listed.district).to_upper()],
				"variant": int(listed.variant), "height": int(listed.height),
				"condition": Building.Condition[str(listed.condition).to_upper()]}
	var trees: Array[Vector2i] = []
	for tile in map.recipe_trees:
		if not map.in_stretch(tile):
			trees.append(tile)
	for listed: Array in stretch.get("trees", []):
		var tile := RecipeCityContext.point(listed)
		if not map.in_stretch(tile) or not map.is_walkable(tile) \
				or not StreetNetwork.segment_containing(tile) or trees.has(tile):
			errors.append("stretch.trees: duplicate tree or no street ground at %s" % tile)
		else:
			trees.append(tile)
	map.recipe_trees = trees
	for listed: Dictionary in stretch.get("props", []):
		var at := Vector2(float(listed.at[0]), float(listed.at[1]))
		if not map.in_stretch(map.world_to_tile(at)):
			errors.append("stretch.props: placement outside the stretch")
		map.stretch_props.append({"kind": Prop.Kind[str(listed.kind).to_upper()], "at": at,
				"variant": int(listed.get("variant", 0)), "scale": float(listed.get("scale", 1.0))})
	for listed: Dictionary in stretch.get("litter", []):
		var at := Vector2(float(listed.at[0]), float(listed.at[1]))
		if not map.in_stretch(map.world_to_tile(at)):
			errors.append("stretch.litter: placement outside the stretch")
		map.stretch_litter.append({"at": at, "texture": SceneRecipe.litter_names().find(str(listed.kind))})
	for crack: Array in stretch.get("cracks", []):
		var tile := Vector2i(int(crack[0]), int(crack[1]))
		if not map.in_stretch(tile):
			errors.append("stretch.cracks: placement outside the stretch")
		map.stretch_cracks[tile] = Vector2i(int(crack[2]), int(crack[3]))
	map.recipe_dawn_tiles = map.tiles.duplicate()
	_plan_closures(data, map, errors)
	map.stretch_active = true
	for label: String in data.get("anchors", {}):
		var spec: Variant = data.anchors[label]
		var at := Vector2.ZERO
		if spec is String:
			at = map.doorstep_world_position() if spec == "doorstep" else map.power_station_door_position()
		elif spec.has("world"):
			at = Vector2(float(spec.world[0]), float(spec.world[1]))
		elif spec.has("tile"):
			at = map.tile_to_world(RecipeCityContext.point(spec.tile))
		else:
			var tile := RecipeCityContext.point(spec.junction) * CityMap.period()
			if str(spec.side).ends_with("east"):
				tile.x += Tuning.STREET_WIDTH - 1
			if str(spec.side).begins_with("south"):
				tile.y += Tuning.STREET_WIDTH - 1
			at = map.tile_to_world(tile)
		if not _on_the_stretch(map, map.world_to_tile(at)):
			errors.append("anchor.extent: %s outside the stretch" % label)
		result.anchors[label] = at
	if not errors.is_empty():
		return result
	result.map = map
	result.manifest = {"classification": data.get("classification", "normal"), "scope": "stretch",
			"bounds": [0, 0, map.size.x, map.size.y], "seed": int(data.seed),
			"checks": ["construction_schema", "explicit_city_context", "authored_placements"],
			"expected_violations": [], "violations": [], "context_sha256":
			JSON.stringify(data.context, "", true).sha256_text()}
	return result

## Whether a stretch scene can name `tile`: one of its own tiles, or a tile of a building it lists —
## a door on a facade (`power_station_door`) is part of the building, not of the street.
static func _on_the_stretch(map: CityMap, tile: Vector2i) -> bool:
	if map.in_stretch(tile):
		return true
	for lot: Rect2i in map.stretch_buildings:
		if lot.has_point(tile):
			return true
	return false

## Whether a lot touches the stretch, a tile beside one of its own tiles or across a corner from it.
static func _fronts_the_stretch(map: CityMap, lot: Rect2i) -> bool:
	for tile in map.rect_tiles(lot.grow(1)):
		if map.in_stretch(tile):
			return true
	return false

static func _plan_closures(data: Dictionary, map: CityMap, errors: Array[String]) -> void:
	var pins: Array = data.city.get("closures", [])
	if pins.is_empty():
		return
	var setup: Dictionary = data.get("setup", {})
	if not SceneRecipe.integer(setup.get("day")) or int(setup.day) < 1 or int(setup.day) > 14:
		errors.append("closure.day: explicit setup.day is required for closure eligibility")
		return
	var day := int(setup.day)
	if pins.size() > Tuning.closures_for_day(day):
		errors.append("closure.count: exceeds the ordinary day's closure budget")
		return
	var state := CityState.new()
	state.begin_day(map.block_plans, day)
	map.repaint(state)
	var tree := RouteTree.for_day(map, day)
	var regions := RegionPlanner.plan_day(map, day, tree)
	var rng := RandomNumberGenerator.new()
	rng.seed = map.seed_used
	var home := ClosurePlanner.home_street(map)
	var areas := ClosurePlanner.calm_areas(map)
	var candidates := ClosurePlanner._shuffled_candidates(map, home, areas, tree, regions, rng)
	var grid := ReachabilityGrid.build(map)
	var places := ClosurePlanner.places_to_reach_today(map, day, regions)
	var closed := {}
	var emptied: Array[Vector2i] = []
	for pin: Dictionary in pins:
		var key := Vector3i(int(pin.segment[0]), int(pin.segment[1]), int(pin.segment[2]))
		var segment := StreetNetwork.by_key(key)
		var eligible := false
		for candidate in candidates:
			if candidate.key() == key:
				eligible = true
		if not eligible:
			errors.append("closure.ineligible: %s" % [key])
			continue
		var kind: int = RoadClosure.Kind[str(pin.kind).to_upper()]
		if not RoadClosure.kinds_on(day).has(kind):
			errors.append("closure.progression: %s is not available on day %d" % [pin.kind, day])
			continue
		if kind == RoadClosure.Kind.FALLEN_TREE:
			var pit := StreetTrees.pit_nearest(map, key, map.tile_rect_to_world(segment.tile_rect()).get_center())
			if not pit:
				errors.append("closure.tree: no standing tree supplies this fallen tree")
				continue
			emptied.append(pit.tile)
		closed[key] = true
		if not ClosurePlanner._invariant_holds(map, grid, areas, closed, places):
			errors.append("closure.reachability: %s" % [key])
			return
		map.recipe_closures.append(RoadClosure.new(kind as RoadClosure.Kind, segment))
	map.set_closure_tree_pits(emptied)

## Move a real pit to the opposite curb of its same street. Planning and scenery read
## StreetTrees.planted, so the tree, pit, collider and event clearance move together.
static func _move_street_trees(map: CityMap, moves: Array, errors: Array[String]) -> void:
	if moves.is_empty():
		return
	var trees := StreetTrees.planted(map)
	var selected := {}
	var destinations := {}
	for move: Dictionary in moves:
		var source := Vector2i(int(move.from[0]), int(move.from[1]))
		var destination := Vector2i(int(move.to[0]), int(move.to[1]))
		var original: StreetTrees.Planted = null
		for tree in trees:
			if tree.tile == source:
				original = tree
		if not original:
			errors.append("tree_moves.from: no existing street tree at %s" % source)
			continue
		var segment := StreetNetwork.by_key(original.segment_key)
		var opposite := source
		var axis := 1 if segment.horizontal else 0
		var offset := CityMap.corridor_offset(source[axis])
		opposite[axis] += (StreetTrees._CURB_OFFSETS[1] - StreetTrees._CURB_OFFSETS[0]) \
				* (1 if offset == StreetTrees._CURB_OFFSETS[0] else -1)
		if destination != opposite or not map.is_open(destination) \
				or StreetTrees._chebyshev(destination, StreetTrees._door_tile(map)) <= 1:
			errors.append("tree_moves.to: must be the clear opposite curb of the same street")
		if selected.has(source) or destinations.has(destination):
			errors.append("tree_moves: duplicate source or destination")
		selected[source] = destination
		destinations[destination] = true
	for tree in trees:
		var tile: Vector2i = selected.get(tree.tile, tree.tile)
		for other in trees:
			if tree == other:
				continue
			var other_tile: Vector2i = selected.get(other.tile, other.tile)
			if map.tile_to_world(tile).distance_to(map.tile_to_world(other_tile)) < StreetTrees.footprint_radius() * 2:
				errors.append("tree_moves.to: overlaps an existing street tree")
	if errors.is_empty():
		map.recipe_tree_moves = selected
