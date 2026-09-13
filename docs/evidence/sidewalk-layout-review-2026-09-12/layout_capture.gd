extends Node
## Records actual ground source selection for fixed review crops.

const SEED := 4242
const DAYS := [1, 14]
const TILE_SET := preload("res://assets/ground_tileset.tres")


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print("usage: layout_capture.tscn -- --output FILE")
		get_tree().quit()
		return
	if args.size() != 2 or args[0] != "--output":
		printerr("usage: layout_capture.tscn -- --output FILE")
		get_tree().quit(2)
		return
	var destination := args[1]
	if FileAccess.file_exists(destination) or DirAccess.dir_exists_absolute(destination):
		printerr("refusing to overwrite existing output: %s" % destination)
		get_tree().quit(2)
		return

	TextureResolver.reset_for_tests(false)
	var first_map := CityGenerator.generate(SEED)
	var rects := _review_rects(first_map)
	var result := {
		"seed_requested": SEED,
		"seed_used": first_map.seed_used,
		"days": DAYS,
		"tile_size": [Tuning.TILE_SIZE, Tuning.TILE_SIZE],
		"map_size": [first_map.size.x, first_map.size.y],
		"street_width": Tuning.STREET_WIDTH,
		"sidewalk_width": Tuning.SIDEWALK_WIDTH,
		"main_road_corridor": first_map.main_road,
		"sources": _sources(),
		"layouts": [],
	}
	for day in DAYS:
		var map := CityGenerator.generate(SEED)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		for record in rects:
			result.layouts.append(_layout(map, day, record.name, record.kind, record.rect))
	if not _has_review_coverage(result.layouts):
		get_tree().quit(2)
		return
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		printerr("cannot open output: %s" % destination)
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	get_tree().quit()


func _review_rects(map: CityMap) -> Array[Dictionary]:
	var ordinary := _ordinary_junction(map, -1)
	var main := _ordinary_junction(map, map.main_road)
	var period := CityMap.period()
	return [
		{"name": "normal_junction", "kind": "12x12 junction and four block corners",
			"rect": Rect2i(ordinary * period - Vector2i(3, 3), Vector2i(12, 12))},
		{"name": "main_junction", "kind": "12x12 main-road junction and four block corners",
			"rect": Rect2i(main * period - Vector2i(3, 3), Vector2i(12, 12))},
		{"name": "normal_vertical_run", "kind": "full six-tile street across one period",
			"rect": Rect2i(Vector2i(ordinary.x * period, ordinary.y * period), Vector2i(6, period))},
		{"name": "normal_horizontal_run", "kind": "full six-tile street across one period",
			"rect": Rect2i(Vector2i(ordinary.x * period, ordinary.y * period), Vector2i(period, 6))},
		{"name": "main_vertical_run", "kind": "full six-tile main road across one period",
			"rect": Rect2i(Vector2i(main.x * period, main.y * period), Vector2i(6, period))},
	]


func _ordinary_junction(map: CityMap, required_x: int) -> Vector2i:
	var corridors := Tuning.CITY_BLOCKS.x + 1
	for y in range(2, corridors - 2):
		for x in range(2, corridors - 2):
			if required_x >= 0 and x != required_x:
				continue
			if required_x < 0 and x == map.main_road:
				continue
			var at := Vector2i(x * CityMap.period() + 3, y * CityMap.period() + 3)
			var vertical := map.street_kind_at(true, at)
			var horizontal := map.street_kind_at(false, at)
			if horizontal != GameEnums.StreetKind.ORDINARY:
				continue
			if required_x >= 0:
				if vertical == GameEnums.StreetKind.MAIN:
					return Vector2i(x, y)
			elif vertical == GameEnums.StreetKind.ORDINARY:
				return Vector2i(x, y)
	push_error("No suitable review junction for seed %d" % SEED)
	get_tree().quit(2)
	return Vector2i.ZERO


func _sources() -> Dictionary:
	var result := {}
	for index in TILE_SET.get_source_count():
		var source_id := TILE_SET.get_source_id(index)
		var atlas := TILE_SET.get_source(source_id) as TileSetAtlasSource
		if atlas == null:
			continue
		var resolved := TextureResolver.resolve(atlas.texture)
		result[str(source_id)] = {
			"authored_path": atlas.texture.resource_path,
			"resolved_path": resolved.resource_path,
			"dimensions": [int(resolved.get_width()), int(resolved.get_height())],
		}
	return result


func _has_review_coverage(layouts: Array) -> bool:
	var required := {
		"normal_junction": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
		"main_junction": [3, 4, 7, 8, 9, 21, 22, 23, 28, 29, 36, 37, 38, 39],
		"normal_vertical_run": [0, 1, 2, 5, 6, 7, 10, 11],
		"normal_horizontal_run": [0, 3, 4, 5, 6, 7, 8, 9],
		"main_vertical_run": [7, 21, 22, 23, 28, 29, 36, 37, 38, 39],
	}
	for record in layouts:
		if record.day != 1:
			continue
		var found := {}
		for row in record.source_ids:
			for source_id in row:
				found[source_id] = true
		for source_id in required[record.name]:
			if not found.has(source_id):
				push_error("Review crop %s is missing source %d" % [record.name, source_id])
				return false
	return true


func _layout(map: CityMap, day: int, name: String, kind: String, rect: Rect2i) -> Dictionary:
	var source_ids := []
	var texture_paths := []
	var tile_types := []
	var sources := _sources()
	for y in range(rect.position.y, rect.end.y):
		var id_row := []
		var path_row := []
		var type_row := []
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			var source_id := GroundTiles.source_for(map, tile, day)
			id_row.append(source_id)
			path_row.append("ground-absent" if source_id < 0 else sources[str(source_id)].resolved_path)
			type_row.append(GameEnums.TileType.keys()[map.tile_at(tile)])
		source_ids.append(id_row)
		texture_paths.append(path_row)
		tile_types.append(type_row)
	return {
		"day": day,
		"name": name,
		"kind": kind,
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"source_ids": source_ids,
		"texture_paths": texture_paths,
		"tile_types": tile_types,
	}
