class_name RecipeCityContext
extends RefCounted
## Explicit spatial context for an authored stretch. Generation is a drafting operation only;
## ordinary daily planners read this saved map, with the visible placements overlaid by the loader.

const RECTS := ["home_rect", "power_station", "power_station_door"]
const RECT_LISTS := ["building_rects", "big_buildings", "alley_rects", "square_rects", "courtyard_rects"]
const LAYOUT_RECTS := ["open_rect", "playground", "square", "alley", "passage"]
const SETS := ["absent_segments", "dead_ends"]

static func capture(map: CityMap) -> Dictionary:
	var data := {"size": pair(map.size), "seed": map.seed_used, "main_road": map.main_road,
			"home_block": pair(map.home_block), "power_station_door_key": triple(map.power_station_door_key),
			"power_station_industrial_blocks": map.power_station_industrial_blocks,
			"tiles": [], "blocks": [], "zones": [], "precincts": [], "built_over": [],
			"region_of_junction": Array(map.region_of_junction),
			"region_has_calm": Array(map.region_has_calm), "boundary_wall_at_a": [], "trees": []}
	for y in map.size.y:
		var row: Array = []
		var x := 0
		while x < map.size.x:
			var type := map.tiles[y * map.size.x + x]
			var end := x + 1
			while end < map.size.x and map.tiles[y * map.size.x + end] == type:
				end += 1
			row.append([str(GameEnums.TileType.keys()[type]).to_lower(), end - x])
			x = end
		data.tiles.append(row)
	for field: String in RECTS:
		data[field] = box(map.get(field))
	for field: String in RECT_LISTS:
		data[field] = []
		for rect: Rect2i in map.get(field):
			data[field].append(box(rect))
	for block: Vector2i in map.block_plans:
		var plan: BlockPlan = map.block_plans[block]
		var entry := {"at": pair(block), "steps": [], "forced_open_on": plan.forced_open_on,
				"layout": {}}
		for step in plan.steps:
			entry.steps.append([str(GameEnums.BlockPurpose.keys()[step.purpose]).to_lower(),
					step.from_day, str(GameEnums.BlockCause.keys()[step.cause]).to_lower()])
		var layout: BlockLayout = map.block_layouts.get(block)
		if layout:
			for field: String in LAYOUT_RECTS:
				entry.layout[field] = box(layout.get(field))
		data.blocks.append(entry)
	for block: Vector2i in map.zone_rects:
		data.zones.append(box(map.zone_rects[block]))
	for span in map.precinct_spans:
		data.precincts.append([span.x, span.y, span.z, span.w])
	for field: String in SETS:
		data[field] = []
		for key: Vector3i in map.get(field):
			data[field].append(triple(key))
	for key: Vector3i in map.built_over:
		data.built_over.append({"segment": triple(key), "rect": box(map.built_over[key])})
	for key: Vector3i in map.boundary_wall_at_a:
		data.boundary_wall_at_a.append({"segment": triple(key), "at_a": map.boundary_wall_at_a[key]})
	for tree in StreetTrees.planted(map):
		data.trees.append(pair(tree.tile))
	return data

static func pair(value: Vector2i) -> Array:
	return [value.x, value.y]

static func triple(value: Vector3i) -> Array:
	return [value.x, value.y, value.z]

static func box(value: Rect2i) -> Array:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

static func point(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

static func key_of(value: Array) -> Vector3i:
	return Vector3i(int(value[0]), int(value[1]), int(value[2]))

## Reject malformed saved data before any indexing or typed assignment. There is deliberately no
## generator witness: editing a placement is allowed; referring to impossible data is not.
static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var allowed: Array = ["size", "seed", "main_road", "home_block", "power_station_door_key",
			"power_station_industrial_blocks", "tiles", "blocks", "zones", "precincts", "built_over",
			"region_of_junction", "region_has_calm", "boundary_wall_at_a", "trees"]
	allowed.append_array(RECTS)
	allowed.append_array(RECT_LISTS)
	allowed.append_array(SETS)
	for field: String in data:
		if not allowed.has(field):
			errors.append("context.%s: unknown field" % field)
	for field: String in allowed:
		if not data.has(field):
			errors.append("context.%s: required" % field)
	if not errors.is_empty():
		return errors
	for field: String in ["size", "home_block"]:
		if not SceneRecipe.tuple(data[field], 2, true):
			errors.append("context.%s: expected integer pair" % field)
	if not SceneRecipe.tuple(data.power_station_door_key, 3, true):
		errors.append("context.power_station_door_key: expected segment key")
	for field: String in ["seed", "main_road", "power_station_industrial_blocks"]:
		if not SceneRecipe.integer(data[field]):
			errors.append("context.%s: expected integer" % field)
	for field: String in RECTS:
		if not SceneRecipe.tuple(data[field], 4, true):
			errors.append("context.%s: expected tile rectangle" % field)
	for field: String in allowed:
		if field in RECTS or field in ["size", "home_block", "power_station_door_key", "seed",
				"main_road", "power_station_industrial_blocks"]:
			continue
		if not data[field] is Array:
			errors.append("context.%s: expected array" % field)
	if not errors.is_empty():
		return errors
	if point(data.size) != CityMap.map_tiles():
		errors.append("context.size: must fit the street lattice")
	var bounds := Rect2i(Vector2i.ZERO, CityMap.map_tiles())
	var block_bounds := Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS)
	if not block_bounds.has_point(point(data.home_block)) \
			or int(data.main_road) < 0 or int(data.main_road) > Tuning.CITY_BLOCKS.x:
		errors.append("context: home block or main road outside the lattice")
	for field: String in RECTS:
		var rect := SceneRecipe.rect(data[field])
		if rect.size.x < 0 or rect.size.y < 0 or (rect.has_area() and not bounds.encloses(rect)):
			errors.append("context.%s: rectangle outside map" % field)
	for field: String in RECT_LISTS + ["zones", "precincts"]:
		for value: Variant in data[field]:
			if not SceneRecipe.tuple(value, 4, true):
				errors.append("context.%s: expected integer quadruples" % field)
			elif field != "precincts":
				var rect := SceneRecipe.rect(value)
				var limit := block_bounds if field == "zones" else bounds
				if not rect.has_area() or not limit.encloses(rect):
					errors.append("context.%s: rectangle outside its lattice" % field)
	for field: String in SETS:
		for value: Variant in data[field]:
			if not SceneRecipe.tuple(value, 3, true) or not StreetNetwork.by_key(key_of(value)):
				errors.append("context.%s: invalid segment" % field)
	for tree: Variant in data.trees:
		if not SceneRecipe.tuple(tree, 2, true):
			errors.append("context.trees: expected tile pairs")
		elif not bounds.has_point(point(tree)) or not StreetNetwork.segment_containing(point(tree)):
			errors.append("context.trees: tile outside a street")
	for field: String in ["region_of_junction", "region_has_calm"]:
		for value: Variant in data[field]:
			if not SceneRecipe.integer(value):
				errors.append("context.%s: expected integers" % field)
			elif (field == "region_of_junction" and (int(value) < -1 or int(value) >= Tuning.REGION_COUNT)) \
					or (field == "region_has_calm" and int(value) not in [0, 1]):
				errors.append("context.%s: invalid region value" % field)
	if data.region_of_junction.size() != (Tuning.CITY_BLOCKS.x + 1) * (Tuning.CITY_BLOCKS.y + 1) \
			or data.region_has_calm.size() != Tuning.REGION_COUNT:
		errors.append("context.regions: wrong lattice dimensions")
	for field: String in ["built_over", "boundary_wall_at_a"]:
		for entry: Variant in data[field]:
			if not entry is Dictionary or not SceneRecipe.tuple(entry.get("segment"), 3, true):
				errors.append("context.%s: expected segment objects" % field)
				continue
			if field == "built_over" and not SceneRecipe.tuple(entry.get("rect"), 4, true):
				errors.append("context.built_over: expected tile rectangle")
			if not StreetNetwork.by_key(key_of(entry.segment)):
				errors.append("context.%s: invalid segment" % field)
			if field == "boundary_wall_at_a" and not entry.get("at_a") is bool:
				errors.append("context.boundary_wall_at_a: expected boolean")
	var seen := {}
	for block: Variant in data.blocks:
		if not block is Dictionary or not SceneRecipe.tuple(block.get("at"), 2, true) \
				or not block.get("steps") is Array or not block.get("layout") is Dictionary \
				or not SceneRecipe.integer(block.get("forced_open_on")):
			errors.append("context.blocks: expected at, steps, layout and forced_open_on")
			continue
		var at := point(block.at)
		if seen.has(at) or not Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS).has_point(at):
			errors.append("context.blocks: duplicate or out-of-bounds block")
		seen[at] = true
		if block.steps.is_empty():
			errors.append("context.blocks.steps: empty arc")
		for step: Variant in block.steps:
			if not step is Array or step.size() != 3:
				errors.append("context.blocks.steps: expected [purpose, day, cause]")
				continue
			if not GameEnums.BlockPurpose.has(str(step[0]).to_upper()) \
					or not SceneRecipe.integer(step[1]) \
					or not GameEnums.BlockCause.has(str(step[2]).to_upper()):
				errors.append("context.blocks.steps: unknown purpose, day or cause")
		for field: String in LAYOUT_RECTS:
			if not SceneRecipe.tuple(block.layout.get(field), 4, true):
				errors.append("context.blocks.layout.%s: expected rectangle" % field)
	if data.tiles.size() != CityMap.map_tiles().y:
		errors.append("context.tiles: missing rows")
	for row: Variant in data.tiles:
		var width := 0
		if not row is Array:
			errors.append("context.tiles: expected rows of [type, length] runs")
			continue
		for run: Variant in row:
			if not run is Array or run.size() != 2:
				errors.append("context.tiles: malformed run")
				continue
			if not GameEnums.TileType.has(str(run[0]).to_upper()) \
					or not SceneRecipe.integer(run[1]) or int(run[1]) <= 0:
				errors.append("context.tiles: unknown type or nonpositive length")
			else:
				width += int(run[1])
		if width != CityMap.map_tiles().x:
			errors.append("context.tiles: row does not cover the map")
	return errors

static func restore(data: Dictionary) -> CityMap:
	var map := CityMap.new(point(data.size))
	map.seed_used = int(data.seed)
	map.main_road = int(data.main_road)
	map.home_block = point(data.home_block)
	map.power_station_door_key = key_of(data.power_station_door_key)
	map.power_station_industrial_blocks = int(data.power_station_industrial_blocks)
	var index := 0
	for row: Array in data.tiles:
		for run: Array in row:
			for _cell in int(run[1]):
				map.tiles[index] = GameEnums.TileType[str(run[0]).to_upper()]
				index += 1
	for field: String in RECTS:
		map.set(field, SceneRecipe.rect(data[field]))
	# Assign into typed arrays; Object.set with an untyped Array silently drops the assignment.
	for field: String in RECT_LISTS:
		var list: Array = map.get(field)
		for value: Array in data[field]:
			list.append(SceneRecipe.rect(value))
	for block: Dictionary in data.blocks:
		var at := point(block.at)
		var plan := BlockPlan.new()
		plan.forced_open_on = int(block.forced_open_on)
		for step: Array in block.steps:
			plan.steps.append(BlockPlan.Step.new(GameEnums.BlockPurpose[str(step[0]).to_upper()],
					int(step[1]), GameEnums.BlockCause[str(step[2]).to_upper()]))
		map.block_plans[at] = plan
		var layout := BlockLayout.new()
		for field: String in LAYOUT_RECTS:
			layout.set(field, SceneRecipe.rect(block.layout[field]))
		map.block_layouts[at] = layout
	for value: Array in data.zones:
		var zone := SceneRecipe.rect(value)
		map.zone_rects[zone.position] = zone
		for block in map.rect_tiles(zone):
			map.zone_anchor[block] = zone.position
	for value: Array in data.precincts:
		map.precinct_spans.append(Vector4i(int(value[0]), int(value[1]), int(value[2]), int(value[3])))
	for field: String in SETS:
		var set: Dictionary = map.get(field)
		for value: Array in data[field]:
			set[key_of(value)] = true
	for entry: Dictionary in data.built_over:
		map.built_over[key_of(entry.segment)] = SceneRecipe.rect(entry.rect)
	for entry: Dictionary in data.boundary_wall_at_a:
		map.boundary_wall_at_a[key_of(entry.segment)] = entry.at_a
	map.region_of_junction = PackedInt32Array(data.region_of_junction)
	map.region_has_calm = PackedByteArray(data.region_has_calm)
	for tree: Array in data.trees:
		map.recipe_trees.append(point(tree))
	return map
