class_name SceneRecipe
extends RefCounted
## Construction schema only. Runtime validates setup and playback before exposing a scene.

static func load_file(path: String, drafting := false) -> Dictionary:
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		errors.append("recipe.file: cannot read %s" % path)
		return {"data": {}, "errors": errors}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		errors.append("recipe.json: line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return {"data": {}, "errors": errors}
	if not parser.data is Dictionary:
		errors.append("recipe.schema: root must be an object")
		return {"data": {}, "errors": errors}
	var data: Dictionary = parser.data
	return {"data": data, "errors": validate(SceneRecipeDraft.base_of(data) if drafting else data)}

static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_keys(data, ["version", "name", "seed", "kind", "classification", "expected_violations",
			"extent", "city", "anchors", "setup", "playback", "stretch", "draft", "context"], "recipe", errors)
	if not integer(data.get("version")) or int(data.get("version", 0)) != 1:
		errors.append("recipe.version: expected 1")
	if not data.get("name") is String or str(data.get("name", "")).strip_edges().is_empty():
		errors.append("recipe.name: expected a nonempty string")
	if not integer(data.get("seed")):
		errors.append("recipe.seed: expected an integer")
	if data.get("kind", "city") not in ["city", "escape"]:
		errors.append("recipe.kind: expected city or escape")
	if data.get("classification", "normal") not in ["normal", "fixture"]:
		errors.append("recipe.classification: expected normal or fixture")
	var expected: Variant = data.get("expected_violations", [])
	if not expected is Array:
		errors.append("recipe.expected_violations: expected an array")
	else:
		var seen := {}
		for code: Variant in expected:
			if not code is String or str(code).is_empty() or seen.has(code):
				errors.append("recipe.expected_violations: empty, duplicate or non-string diagnostic")
			seen[code] = true
		if data.get("classification", "normal") == "normal" and not expected.is_empty():
			errors.append("recipe.expected_violations: normal scenes cannot waive checks")
	for field in ["extent", "city", "anchors", "setup", "playback", "stretch", "draft", "context"]:
		if not data.get(field, {}) is Dictionary:
			errors.append("recipe.%s: expected an object" % field)
	if not errors.is_empty():
		return errors
	var extent: Dictionary = data.get("extent", {})
	_keys(extent, ["scope", "bounds"], "extent", errors)
	if extent.get("scope") not in ["full", "bounded", "stretch"]:
		errors.append("extent.scope: expected full, bounded or stretch")
	if (extent.get("scope") == "stretch") != data.has("stretch"):
		errors.append("stretch: a stretch scope and a stretch object come together")
	elif data.has("stretch"):
		_validate_stretch(data.stretch, errors)
		if not data.has("context"):
			errors.append("context: a stretch requires explicit saved city context; draft it first")
		else:
			errors.append_array(RecipeCityContext.validate(data.context))
	elif data.has("context"):
		errors.append("context: saved city context belongs to a stretch")
	if data.get("draft", {}) is Dictionary:
		_keys(data.get("draft", {}), ["include"], "draft", errors)
		var include: Variant = data.get("draft", {}).get("include", [])
		if not include is Array or not (include as Array).all(
				func(tile: Variant) -> bool: return tuple(tile, 2, true)):
			errors.append("draft.include: a list of tiles [x, y] whose ground the draft adds")
	if extent.get("scope") == "bounded":
		if not tuple(extent.get("bounds"), 4, true):
			errors.append("extent.bounds: expected [x,y,width,height] in integer tiles")
		else:
			var bounds := rect(extent.bounds)
			if not bounds.has_area() or not Rect2i(Vector2i.ZERO, CityMap.map_tiles()).encloses(bounds):
				errors.append("extent.bounds: expected positive bounds inside the city lattice")
	elif extent.has("bounds"):
		errors.append("extent.bounds: only a bounded scope has bounds")
	var city: Dictionary = data.get("city", {})
	_keys(city, ["context_seed", "main_road", "precincts", "lots", "layouts", "dead_ends", "power_station", "closures", "tree_moves"], "city", errors)
	if not city.get("tree_moves", []) is Array:
		errors.append("city.tree_moves: expected an array")
	else:
		for move: Variant in city.get("tree_moves", []):
			if not move is Dictionary:
				errors.append("city.tree_moves: expected from/to tile objects")
				continue
			_keys(move, ["from", "to"], "city.tree_moves", errors)
			if not tuple(move.get("from"), 2, true) or not tuple(move.get("to"), 2, true):
				errors.append("city.tree_moves: from/to must be integer tile pairs")
	if not integer(city.get("context_seed")):
		errors.append("city.context_seed: explicit construction context is required")
	if city.has("main_road") and (not integer(city.main_road) or int(city.main_road) < 3
			or int(city.main_road) > Tuning.CITY_BLOCKS.x - 3):
		errors.append("city.main_road: spine requires three corridors of clearance")
	if not city.get("lots", []) is Array:
		errors.append("city.lots: expected an array")
	else:
		var footprints: Array[Rect2i] = []
		for pin: Variant in city.get("lots", []):
			if not pin is Dictionary:
				errors.append("city.lots: expected objects")
				continue
			_keys(pin, ["blocks", "purpose"], "city.lots", errors)
			if not tuple(pin.get("blocks"), 4, true) or pin.get("purpose") not in ["residential", "civic", "commercial", "industrial", "park", "forest", "quiet_square", "courtyard"]:
				errors.append("city.lots: requires blocks [x,y,w,h] and a starting purpose")
				continue
			var footprint := rect(pin.blocks)
			if not footprint.has_area() or not Rect2i(Vector2i.ZERO, Tuning.CITY_BLOCKS).encloses(footprint):
				errors.append("city.lots: footprint outside the block lattice")
			if footprint.size != Vector2i.ONE:
				if pin.purpose not in ["park", "forest", "quiet_square", "courtyard"]:
					errors.append("city.lots: built purposes require single blocks")
				elif pin.purpose == "courtyard" and footprint.size != Vector2i(2, 2):
					errors.append("city.lots: apartment complexes require a 2 by 2 footprint")
				elif not Tuning.CALM_ZONE_SHAPES.has(footprint.size):
					errors.append("city.lots: unsupported calm-zone footprint")
			for other in footprints:
				if footprint.intersects(other):
					errors.append("city.lots: overlapping pins")
			footprints.append(footprint)
	if city.has("precincts"):
		if not city.precincts is Array or city.precincts.size() != 2:
			errors.append("city.precincts: exactly shore and inland spans are required")
		else:
			for span: Variant in city.precincts:
				if not tuple(span, 4, true):
					errors.append("city.precincts: spans are [axis,corridor,start,end]")
				elif int(span[0]) not in [0, 1] or int(span[1]) < 0 \
						or int(span[1]) >= CrowdLanes.corridor_count(Tuning.CITY_BLOCKS[1 - int(span[0])]) \
						or int(span[2]) < 0 or int(span[3]) >= Tuning.CITY_BLOCKS[int(span[0])] \
						or int(span[3]) - int(span[2]) + 1 != Tuning.PRECINCT_BLOCKS:
					errors.append("city.precincts: invalid precinct span")
	for field in ["layouts", "dead_ends", "closures"]:
		if not city.get(field, []) is Array:
			errors.append("city.%s: expected an array" % field)
			continue
		var seen := {}
		for pin: Variant in city.get(field, []):
			if not pin is Dictionary:
				errors.append("city.%s: expected objects" % field)
				continue
			if field == "layouts":
				_keys(pin, ["block", "seed"], "city.layouts", errors)
				if not tuple(pin.get("block"), 2, true) or not integer(pin.get("seed")):
					errors.append("city.layouts: requires integer block and seed")
			elif field == "dead_ends":
				_keys(pin, ["segment", "end"], "city.dead_ends", errors)
				if not tuple(pin.get("segment"), 3, true) or pin.get("end") not in ["a", "b"]:
					errors.append("city.dead_ends: requires segment [x,y,axis] and end a or b")
			else:
				_keys(pin, ["segment", "kind"], "city.closures", errors)
				if not tuple(pin.get("segment"), 3, true) or pin.get("kind") not in ["roadworks", "fallen_tree", "crash", "cordon", "rubble"]:
					errors.append("city.closures: requires segment [x,y,axis] and an ordinary street closure kind")
			var key: String = str(pin.get("block", pin.get("segment")))
			if seen.has(key):
				errors.append("city.%s: duplicate pin %s" % [field, key])
			seen[key] = true
	if city.has("power_station"):
		var station: Variant = city.power_station
		if not station is Dictionary:
			errors.append("city.power_station: expected an object")
		else:
			_keys(station, ["blocks", "door_block"], "city.power_station", errors)
			if not tuple(station.get("blocks"), 4, true) or not tuple(station.get("door_block"), 2, true):
				errors.append("city.power_station: requires blocks [x,y,2,1] and door_block [x,y]")
			elif rect(station.blocks).size != Vector2i(2, 1) or int(station.blocks[0]) < 1 \
					or int(station.blocks[1]) < 1 or not Rect2i(Vector2i.ONE, Tuning.CITY_BLOCKS - Vector2i(2, 2)).encloses(rect(station.blocks)):
				errors.append("city.power_station: requires two horizontal interior blocks")
	for key: Variant in data.get("anchors", {}):
		var anchor: Variant = data.anchors[key]
		if not key is String or str(key).is_empty():
			errors.append("anchors: names must be nonempty strings")
		if anchor is String:
			if anchor not in ["doorstep", "power_station_door"]:
				errors.append("anchors.%s: unknown landmark" % key)
		elif not anchor is Dictionary:
			errors.append("anchors.%s: expected landmark string or position object" % key)
		else:
			_keys(anchor, ["tile", "world", "junction", "side"], "anchors.%s" % key, errors)
			var forms := int(anchor.has("tile")) + int(anchor.has("world")) + int(anchor.has("junction"))
			if forms != 1:
				errors.append("anchors.%s: choose exactly one position form" % key)
			for form in ["tile", "world", "junction"]:
				if anchor.has(form) and not tuple(anchor[form], 2, form != "world"):
					errors.append("anchors.%s.%s: expected two coordinates" % [key, form])
			if anchor.has("junction") and anchor.get("side") not in ["northwest", "northeast", "southwest", "southeast"]:
				errors.append("anchors.%s.side: expected a junction sidewalk corner" % key)
			if anchor.has("side") and not anchor.has("junction"):
				errors.append("anchors.%s.side: requires a junction" % key)
	return errors

## The tile type names a stretch lists its tiles under, lowercased from `GameEnums.TileType`.
static func tile_type_names() -> Array[String]:
	var names: Array[String] = []
	for key: String in GameEnums.TileType:
		names.append(key.to_lower())
	return names

## The prop kinds a stretch places, lowercased from `Prop.Kind` but for the street tree, which a
## stretch lists under `trees` so drawing, collision and event clearance share its placement.
static func prop_kind_names() -> Array[String]:
	var names: Array[String] = []
	for key: String in Prop.Kind:
		if key != "STREET_TREE":
			names.append(key.to_lower())
	return names

## The litter a stretch places, by the picture's own name (`Litter.TEXTURES`, `props/litter_cup`
## as `cup`).
static func litter_names() -> Array[String]:
	var names: Array[String] = []
	for texture in Litter.TEXTURES:
		names.append(str(texture).trim_prefix("props/litter_"))
	return names

## The shape of `stretch` (`docs/SCENE_RECIPES.md`, "The task scenes"); whether each piece fits the
## saved context and authored extent is `RecipeCityBuilder`'s to say.
static func _validate_stretch(stretch: Dictionary, errors: Array[String]) -> void:
	_keys(stretch, ["tiles", "buildings", "trees", "props", "litter", "cracks"], "stretch", errors)
	var tiles: Variant = stretch.get("tiles")
	if not tiles is Dictionary or (tiles as Dictionary).is_empty():
		errors.append("stretch.tiles: expected an object of tile type -> [y, x_from, x_to] runs")
	else:
		for type: Variant in tiles:
			if not type in tile_type_names() or type == "building":
				errors.append("stretch.tiles.%s: not a walkable tile type" % type)
			elif not tiles[type] is Array:
				errors.append("stretch.tiles.%s: expected an array of runs" % type)
			else:
				for run: Variant in tiles[type]:
					if not tuple(run, 3, true) or int(run[1]) > int(run[2]):
						errors.append("stretch.tiles.%s: a run is [y, x_from, x_to] with x_from <= x_to" % type)
	for field in ["buildings", "trees", "props", "litter", "cracks"]:
		if not stretch.get(field, []) is Array:
			errors.append("stretch.%s: expected an array" % field)
	if not errors.is_empty():
		return
	var districts: Array[String] = []
	for key: String in GameEnums.BlockPurpose:
		districts.append(key.to_lower())
	var conditions: Array[String] = []
	for key: String in Building.Condition:
		conditions.append(key.to_lower())
	for building: Variant in stretch.get("buildings", []):
		if not building is Dictionary:
			errors.append("stretch.buildings: expected objects")
			continue
		_keys(building, ["lot", "district", "variant", "height", "condition"], "stretch.buildings", errors)
		if not tuple(building.get("lot"), 4, true) or not building.get("district") in districts \
				or not integer(building.get("variant")) or not integer(building.get("height")) \
				or int(building.get("height", 0)) < 1 or not building.get("condition") in conditions:
			errors.append("stretch.buildings: requires lot [x,y,w,h], a district, an integer variant, a height in tiles and a condition")
	for tree: Variant in stretch.get("trees", []):
		if not tuple(tree, 2, true):
			errors.append("stretch.trees: a street tree is its pit tile [x,y]")
	for prop: Variant in stretch.get("props", []):
		if not prop is Dictionary:
			errors.append("stretch.props: expected objects")
			continue
		_keys(prop, ["kind", "at", "variant", "scale"], "stretch.props", errors)
		if not prop.get("kind") in prop_kind_names() or not tuple(prop.get("at"), 2, false) \
				or not integer(prop.get("variant", 0)) or not (prop.get("scale", 1.0) is float
				or prop.get("scale", 1.0) is int) or float(prop.get("scale", 1.0)) <= 0.0:
			errors.append("stretch.props: requires a kind, at [x,y], an integer variant and a positive scale")
	for litter: Variant in stretch.get("litter", []):
		if not litter is Dictionary:
			errors.append("stretch.litter: expected objects")
			continue
		_keys(litter, ["kind", "at"], "stretch.litter", errors)
		if not litter.get("kind") in litter_names() or not tuple(litter.get("at"), 2, false):
			errors.append("stretch.litter: requires a kind (%s) and at [x,y]" % ", ".join(litter_names()))
	for crack: Variant in stretch.get("cracks", []):
		if not tuple(crack, 4, true) or int(crack[2]) < 0 or int(crack[2]) > 2 \
				or int(crack[3]) < 0 or int(crack[3]) > 1:
			errors.append("stretch.cracks: a crack is [x, y, level 0-2, pattern 0-1]")

static func integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

static func tuple(value: Variant, count: int, integral: bool) -> bool:
	if not value is Array or value.size() != count:
		return false
	for component: Variant in value:
		if integral and not integer(component):
			return false
		if not (component is int or component is float) or not is_finite(float(component)):
			return false
	return true

static func rect(value: Array) -> Rect2i:
	return Rect2i(int(value[0]), int(value[1]), int(value[2]), int(value[3]))

static func _keys(data: Dictionary, allowed: Array, at: String, errors: Array[String]) -> void:
	for key: Variant in data:
		if not allowed.has(key):
			errors.append("%s.%s: unsupported field" % [at, key])
