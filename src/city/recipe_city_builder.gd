class_name RecipeCityBuilder
extends RefCounted
## A single constructive attempt with exact choices and an explicit global witness.
## Never searches whole-city seeds and never moves a requested placement after construction.

static func build(data: Dictionary) -> Dictionary:
	var errors := SceneRecipe.validate(data)
	var result := {"map": null, "anchors": {}, "errors": errors, "manifest": {}}
	if not errors.is_empty():
		return result
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
		if not bounds.has_point(map.world_to_tile(at)):
			errors.append("anchor.extent: %s lies outside the authored bounds" % name)
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
