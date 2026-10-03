class_name SceneRecipe
extends RefCounted
## Construction schema only. Runtime validates setup and playback before exposing a scene.

static func load_file(path: String) -> Dictionary:
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
	return {"data": data, "errors": validate(data)}

static func validate(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	_keys(data, ["version", "name", "seed", "kind", "classification", "expected_violations",
			"extent", "city", "anchors", "setup", "playback"], "recipe", errors)
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
	for field in ["extent", "city", "anchors", "setup", "playback"]:
		if not data.get(field, {}) is Dictionary:
			errors.append("recipe.%s: expected an object" % field)
	if not errors.is_empty():
		return errors
	var extent: Dictionary = data.get("extent", {})
	_keys(extent, ["scope", "bounds"], "extent", errors)
	if extent.get("scope") not in ["full", "bounded"]:
		errors.append("extent.scope: expected full or bounded")
	if extent.get("scope") == "bounded":
		if not tuple(extent.get("bounds"), 4, true):
			errors.append("extent.bounds: expected [x,y,width,height] in integer tiles")
		else:
			var bounds := rect(extent.bounds)
			if not bounds.has_area() or not Rect2i(Vector2i.ZERO, CityMap.map_tiles()).encloses(bounds):
				errors.append("extent.bounds: expected positive bounds inside the city lattice")
	elif extent.has("bounds"):
		errors.append("extent.bounds: full scope has implicit complete city bounds")
	var city: Dictionary = data.get("city", {})
	_keys(city, ["context_seed", "main_road", "precincts", "lots", "layouts", "dead_ends", "power_station", "closures"], "city", errors)
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
				elif int(span[0]) not in [0, 1] or int(span[1]) < 0 or int(span[1]) > 11 \
						or int(span[2]) < 0 or int(span[3]) >= 11 \
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
					or int(station.blocks[1]) < 1 or not Rect2i(1, 1, 9, 9).encloses(rect(station.blocks)):
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
