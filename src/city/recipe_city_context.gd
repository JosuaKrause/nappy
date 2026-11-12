class_name RecipeCityContext
extends RefCounted
## Explicit spatial context for an authored stretch. Generation is a drafting operation only;
## ordinary daily planners read this saved map, with the visible placements overlaid by the loader.
##
## **What the context holds is the map's own**: `CityMap.capture()` says what generation fixed in
## a city, and `CityMap.restored()` builds the same map from it. This class is the recipe file's
## half: it writes those facts into the JSON-safe rows, arrays and objects a recipe's `context`
## holds, checks a saved one before anything indexes it (`validate()`), and reads it back.

const RECTS := ["home_rect", "power_station", "power_station_door"]
const RECT_LISTS := ["building_rects", "big_buildings", "alley_rects", "square_rects", "courtyard_rects"]
const LAYOUT_RECTS := ["open_rect", "playground", "square", "alley", "passage"]
const SETS := ["absent_segments", "dead_ends"]

## The saved form of `map`'s spatial context, as a recipe's `context` holds it.
static func capture(map: CityMap) -> Dictionary:
	var facts := map.capture()
	var size: Vector2i = facts["size"]
	var region_of_junction: PackedInt32Array = facts["region_of_junction"]
	var region_has_calm: PackedByteArray = facts["region_has_calm"]
	var data := {"size": pair(size), "seed": facts["seed"], "main_road": facts["main_road"],
			"home_block": pair(facts["home_block"]),
			"power_station_door_key": triple(facts["power_station_door_key"]),
			"power_station_industrial_blocks": facts["power_station_industrial_blocks"],
			"tiles": _runs(facts["tiles"], size), "blocks": _blocks(facts["block_plans"],
					facts["block_layouts"]),
			"zones": [], "precincts": [], "built_over": [],
			"region_of_junction": Array(region_of_junction),
			"region_has_calm": Array(region_has_calm), "boundary_wall_at_a": [], "trees": []}
	for field: String in RECTS:
		data[field] = box(facts[field])
	for field: String in RECT_LISTS:
		var boxed: Array = []
		var rects: Array[Rect2i] = facts[field]
		for rect in rects:
			boxed.append(box(rect))
		data[field] = boxed
	var zones: Array[Rect2i] = facts["zones"]
	var saved_zones: Array = data["zones"]
	for zone in zones:
		saved_zones.append(box(zone))
	var precincts: Array[Vector4i] = facts["precincts"]
	var saved_precincts: Array = data["precincts"]
	for span in precincts:
		saved_precincts.append([span.x, span.y, span.z, span.w])
	for field: String in SETS:
		var keys: Array = []
		var segments: Array[Vector3i] = facts[field]
		for key in segments:
			keys.append(triple(key))
		data[field] = keys
	var built_over: Dictionary = facts["built_over"]
	var saved_built_over: Array = data["built_over"]
	for key: Vector3i in built_over:
		saved_built_over.append({"segment": triple(key), "rect": box(built_over[key])})
	var wall_ends: Dictionary = facts["boundary_wall_at_a"]
	var saved_wall_ends: Array = data["boundary_wall_at_a"]
	for key: Vector3i in wall_ends:
		saved_wall_ends.append({"segment": triple(key), "at_a": wall_ends[key]})
	var trees: Array[Vector2i] = facts["trees"]
	var saved_trees: Array = data["trees"]
	for tree in trees:
		saved_trees.append(pair(tree))
	return data

## The ground as a recipe saves it: one row per tile row, each a list of `[type, length]` runs.
static func _runs(tiles: PackedByteArray, size: Vector2i) -> Array:
	var rows: Array = []
	for y in size.y:
		var row: Array = []
		var x := 0
		while x < size.x:
			var type := tiles[y * size.x + x]
			var end := x + 1
			while end < size.x and tiles[y * size.x + end] == type:
				end += 1
			row.append([str(GameEnums.TileType.keys()[type]).to_lower(), end - x])
			x = end
		rows.append(row)
	return rows

## Each anchor block as a recipe saves it: where it is, its arc's steps, the day it is forced
## open, and its carves (an empty object for a block with none).
static func _blocks(plans: Dictionary, layouts: Dictionary) -> Array:
	var saved: Array = []
	for block: Vector2i in plans:
		var plan: BlockPlan = plans[block]
		var steps: Array = []
		for step in plan.steps_in_order():
			steps.append([str(GameEnums.BlockPurpose.keys()[step.purpose]).to_lower(),
					step.from_day, str(GameEnums.BlockCause.keys()[step.cause]).to_lower()])
		var layout := {}
		if layouts.has(block):
			var carves: Dictionary = layouts[block]
			for field: String in LAYOUT_RECTS:
				layout[field] = box(carves[field])
		saved.append({"at": pair(block), "steps": steps, "forced_open_on": plan.forced_open_day(),
				"layout": layout})
	return saved

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
	if not SceneRecipe.tuple(data["power_station_door_key"], 3, true):
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
	if point(data["size"]) != CityMap.map_tiles():
		errors.append("context.size: must fit the street lattice")
	var bounds := Rect2i(Vector2i.ZERO, CityMap.map_tiles())
	var block_bounds := Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS)
	var main_road := int(data["main_road"])
	if not block_bounds.has_point(point(data["home_block"])) \
			or main_road < 0 or main_road > Tuning.CITY_BLOCKS.x:
		errors.append("context: home block or main road outside the lattice")
	for field: String in RECTS:
		var rect := SceneRecipe.rect(data[field])
		if rect.size.x < 0 or rect.size.y < 0 or (rect.has_area() and not bounds.encloses(rect)):
			errors.append("context.%s: rectangle outside map" % field)
	for field: String in RECT_LISTS + ["zones", "precincts"]:
		var values: Array = data[field]
		for value: Variant in values:
			if not SceneRecipe.tuple(value, 4, true):
				errors.append("context.%s: expected integer quadruples" % field)
			elif field != "precincts":
				var rect := SceneRecipe.rect(value)
				var limit := block_bounds if field == "zones" else bounds
				if not rect.has_area() or not limit.encloses(rect):
					errors.append("context.%s: rectangle outside its lattice" % field)
	# No map is built yet, so the keys are checked against a lattice of their own: the same streets
	# every city's map holds (`CityMap.street_network()`).
	var lattice := StreetNetwork.new()
	for field: String in SETS:
		var values: Array = data[field]
		for value: Variant in values:
			if not SceneRecipe.tuple(value, 3, true) or not lattice.by_key(key_of(value)):
				errors.append("context.%s: invalid segment" % field)
	var trees: Array = data["trees"]
	for tree: Variant in trees:
		if not SceneRecipe.tuple(tree, 2, true):
			errors.append("context.trees: expected tile pairs")
		elif not bounds.has_point(point(tree)) or not lattice.segment_containing(point(tree)):
			errors.append("context.trees: tile outside a street")
	for field: String in ["region_of_junction", "region_has_calm"]:
		var values: Array = data[field]
		for value: Variant in values:
			if not SceneRecipe.integer(value):
				errors.append("context.%s: expected integers" % field)
			elif (field == "region_of_junction" and (int(value) < -1 or int(value) >= Tuning.REGION_COUNT)) \
					or (field == "region_has_calm" and int(value) not in [0, 1]):
				errors.append("context.%s: invalid region value" % field)
	var region_of_junction: Array = data["region_of_junction"]
	var region_has_calm: Array = data["region_has_calm"]
	if region_of_junction.size() != (Tuning.CITY_BLOCKS.x + 1) * (Tuning.CITY_BLOCKS.y + 1) \
			or region_has_calm.size() != Tuning.REGION_COUNT:
		errors.append("context.regions: wrong lattice dimensions")
	for field: String in ["built_over", "boundary_wall_at_a"]:
		var entries: Array = data[field]
		for value: Variant in entries:
			if not value is Dictionary or not SceneRecipe.tuple((value as Dictionary).get("segment"), 3, true):
				errors.append("context.%s: expected segment objects" % field)
				continue
			var entry: Dictionary = value
			if field == "built_over" and not SceneRecipe.tuple(entry.get("rect"), 4, true):
				errors.append("context.built_over: expected tile rectangle")
			if not lattice.by_key(key_of(entry["segment"])):
				errors.append("context.%s: invalid segment" % field)
			if field == "boundary_wall_at_a" and not entry.get("at_a") is bool:
				errors.append("context.boundary_wall_at_a: expected boolean")
	var seen := {}
	var blocks: Array = data["blocks"]
	for value: Variant in blocks:
		if not value is Dictionary or not _has_block_fields(value as Dictionary):
			errors.append("context.blocks: expected at, steps, layout and forced_open_on")
			continue
		var block: Dictionary = value
		var at := point(block["at"])
		if seen.has(at) or not Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS).has_point(at):
			errors.append("context.blocks: duplicate or out-of-bounds block")
		seen[at] = true
		var steps: Array = block["steps"]
		if steps.is_empty():
			errors.append("context.blocks.steps: empty arc")
		for step: Variant in steps:
			if not step is Array or (step as Array).size() != 3:
				errors.append("context.blocks.steps: expected [purpose, day, cause]")
				continue
			var parts: Array = step
			if not GameEnums.BlockPurpose.has(str(parts[0]).to_upper()) \
					or not SceneRecipe.integer(parts[1]) \
					or not GameEnums.BlockCause.has(str(parts[2]).to_upper()):
				errors.append("context.blocks.steps: unknown purpose, day or cause")
		var layout: Dictionary = block["layout"]
		for field: String in LAYOUT_RECTS:
			if not SceneRecipe.tuple(layout.get(field), 4, true):
				errors.append("context.blocks.layout.%s: expected rectangle" % field)
	var rows: Array = data["tiles"]
	if rows.size() != CityMap.map_tiles().y:
		errors.append("context.tiles: missing rows")
	for row: Variant in rows:
		var width := 0
		if not row is Array:
			errors.append("context.tiles: expected rows of [type, length] runs")
			continue
		for run: Variant in (row as Array):
			if not run is Array or (run as Array).size() != 2:
				errors.append("context.tiles: malformed run")
				continue
			var parts: Array = run
			if not GameEnums.TileType.has(str(parts[0]).to_upper()) \
					or not SceneRecipe.integer(parts[1]) or int(parts[1]) <= 0:
				errors.append("context.tiles: unknown type or nonpositive length")
			else:
				width += int(parts[1])
		if width != CityMap.map_tiles().x:
			errors.append("context.tiles: row does not cover the map")
	return errors

## Whether a saved block has each of its fields, each of the kind it needs.
static func _has_block_fields(block: Dictionary) -> bool:
	return SceneRecipe.tuple(block.get("at"), 2, true) and block.get("steps") is Array \
			and block.get("layout") is Dictionary and SceneRecipe.integer(block.get("forced_open_on"))

## The map a saved `context` describes, `data` having passed `validate()`.
static func restore(data: Dictionary) -> CityMap:
	var size := point(data["size"])
	var tiles := PackedByteArray()
	tiles.resize(size.x * size.y)
	var index := 0
	var rows: Array = data["tiles"]
	for row: Array in rows:
		for run: Array in row:
			var type: int = GameEnums.TileType[str(run[0]).to_upper()]
			for _cell in int(run[1]):
				tiles[index] = type
				index += 1
	var region_of_junction: Array = data["region_of_junction"]
	var region_has_calm: Array = data["region_has_calm"]
	var facts := {"size": size, "seed": int(data["seed"]), "main_road": int(data["main_road"]),
			"home_block": point(data["home_block"]),
			"power_station_door_key": key_of(data["power_station_door_key"]),
			"power_station_industrial_blocks": int(data["power_station_industrial_blocks"]),
			"tiles": tiles, "region_of_junction": PackedInt32Array(region_of_junction),
			"region_has_calm": PackedByteArray(region_has_calm)}
	for field: String in RECTS:
		facts[field] = SceneRecipe.rect(data[field])
	for field: String in RECT_LISTS + ["zones"]:
		var rects: Array[Rect2i] = []
		var values: Array = data[field]
		for value: Array in values:
			rects.append(SceneRecipe.rect(value))
		facts[field] = rects
	var plans := {}
	var layouts := {}
	var blocks: Array = data["blocks"]
	for block: Dictionary in blocks:
		var at := point(block["at"])
		var plan := BlockPlan.new()
		plan.force_open_on(int(block["forced_open_on"]))
		var steps: Array = block["steps"]
		for step: Array in steps:
			plan.append_step(BlockPlan.Step.new(GameEnums.BlockPurpose[str(step[0]).to_upper()],
					int(step[1]), GameEnums.BlockCause[str(step[2]).to_upper()]))
		plans[at] = plan
		var layout: Dictionary = block["layout"]
		var carves := {}
		for field: String in LAYOUT_RECTS:
			carves[field] = SceneRecipe.rect(layout[field])
		layouts[at] = carves
	facts["block_plans"] = plans
	facts["block_layouts"] = layouts
	var precincts: Array[Vector4i] = []
	var spans: Array = data["precincts"]
	for value: Array in spans:
		precincts.append(Vector4i(int(value[0]), int(value[1]), int(value[2]), int(value[3])))
	facts["precincts"] = precincts
	for field: String in SETS:
		var keys: Array[Vector3i] = []
		var values: Array = data[field]
		for value: Array in values:
			keys.append(key_of(value))
		facts[field] = keys
	var built_over := {}
	var built_entries: Array = data["built_over"]
	for entry: Dictionary in built_entries:
		built_over[key_of(entry["segment"])] = SceneRecipe.rect(entry["rect"])
	facts["built_over"] = built_over
	var wall_ends := {}
	var wall_entries: Array = data["boundary_wall_at_a"]
	for entry: Dictionary in wall_entries:
		wall_ends[key_of(entry["segment"])] = entry["at_a"]
	facts["boundary_wall_at_a"] = wall_ends
	var trees: Array[Vector2i] = []
	var saved_trees: Array = data["trees"]
	for tree: Array in saved_trees:
		trees.append(point(tree))
	facts["trees"] = trees
	return CityMap.restored(facts)
