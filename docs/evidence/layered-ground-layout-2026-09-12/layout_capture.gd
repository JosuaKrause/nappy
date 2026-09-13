extends Node
## Writes selected actual ground-atlas cells for a fixed city, without running a windowed scene.

const SEED := 4242
const DAYS := [1, 14]
const SCALE := 4
const TILE_SET: TileSet = preload("res://assets/ground_tileset.tres")
const INPUTS := [
	"res://assets/ground_tileset.tres",
	"res://assets/illustrated/svg-transfer/tiles/layers/manifest.json",
	"res://src/city/ground_tiles.gd",
	"res://src/city/city_generator.gd",
	"res://src/city/city_map.gd",
	"res://src/city/city_state.gd",
	"res://src/autoload/tuning.gd",
	"res://src/visuals/ground_layers.gd",
	"res://src/visuals/texture_resolver.gd",
	"res://docs/evidence/layered-ground-layout-2026-09-12/layout_capture.gd",
]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print("usage: layout_capture.tscn -- --output-dir DIRECTORY")
		get_tree().quit()
		return
	if args.size() != 2 or args[0] != "--output-dir":
		printerr("usage: layout_capture.tscn -- --output-dir DIRECTORY")
		get_tree().quit(2)
		return
	var output_dir: String = args[1]
	if FileAccess.file_exists(output_dir) or DirAccess.dir_exists_absolute(output_dir):
		printerr("refusing to overwrite existing output: %s" % output_dir)
		get_tree().quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		printerr("cannot create output directory: %s" % output_dir)
		get_tree().quit(2)
		return
	TextureResolver.reset_for_tests(false)
	var composed := GroundLayers.build_tile_set(TILE_SET)
	var city_map := CityGenerator.generate(SEED)
	var rects := _review_rects(city_map)
	for day in DAYS:
		var map := CityGenerator.generate(SEED)
		var state := CityState.new()
		state.begin_day(map.block_plans, day)
		map.repaint(state)
		for record in rects:
			_write_crop(output_dir, composed, map, day, record)
	_write_manifest(output_dir, composed, city_map, rects)
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
	get_tree().quit()

func _review_rects(map: CityMap) -> Array[Dictionary]:
	var ordinary := _ordinary_junction(map, -1)
	var main := _ordinary_junction(map, map.main_road)
	var period := CityMap.period()
	var park := _park_patch(map)
	return [
		{"name": "normal_junction", "rect": Rect2i(ordinary * period - Vector2i(3, 3), Vector2i(12, 12))},
		{"name": "main_junction", "rect": Rect2i(main * period - Vector2i(3, 3), Vector2i(12, 12))},
		{"name": "normal_vertical_run", "rect": Rect2i(ordinary * period, Vector2i(6, period))},
		{"name": "normal_horizontal_run", "rect": Rect2i(ordinary * period, Vector2i(period, 6))},
		{"name": "main_vertical_run", "rect": Rect2i(main * period, Vector2i(6, period))},
		{"name": "park_grass", "rect": park},
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
			if required_x >= 0 and vertical == GameEnums.StreetKind.MAIN:
				return Vector2i(x, y)
			if required_x < 0 and vertical == GameEnums.StreetKind.ORDINARY:
				return Vector2i(x, y)
	push_error("no suitable junction for seed %d" % SEED)
	return Vector2i.ZERO

func _park_patch(map: CityMap) -> Rect2i:
	for y in range(map.size.y):
		for x in range(map.size.x):
			var tile := Vector2i(x, y)
			if map.tile_at(tile) == GameEnums.TileType.PARK:
				return Rect2i(tile - Vector2i(2, 2), Vector2i(8, 8))
	push_error("seed %d has no park ground" % SEED)
	return Rect2i()

func _write_crop(output_dir: String, tile_set: TileSet, map: CityMap, day: int,
		record: Dictionary) -> void:
	var rect: Rect2i = record.rect
	var image := Image.create(rect.size.x * Tuning.TILE_SIZE, rect.size.y * Tuning.TILE_SIZE,
			false, Image.FORMAT_RGBA8)
	image.fill(Color("202126"))
	var ids: Array = []
	var coords: Array = []
	for y in range(rect.position.y, rect.end.y):
		var id_row: Array = []
		var coord_row: Array = []
		for x in range(rect.position.x, rect.end.x):
			var tile := Vector2i(x, y)
			var source_id := GroundTiles.source_for(map, tile, day)
			var atlas_coord := GroundLayers.atlas_coords_for(source_id, map.seed_used, tile, tile_set)
			id_row.append(source_id)
			coord_row.append([atlas_coord.x, atlas_coord.y])
			if source_id >= 0:
				var source := tile_set.get_source(source_id) as TileSetAtlasSource
				var source_image := source.texture.get_image()
				var source_rect := Rect2i(atlas_coord * Tuning.TILE_SIZE,
						Vector2i(Tuning.TILE_SIZE, Tuning.TILE_SIZE))
				var destination := Vector2i((x - rect.position.x) * Tuning.TILE_SIZE,
						(y - rect.position.y) * Tuning.TILE_SIZE)
				image.blit_rect(source_image, source_rect, destination)
		ids.append(id_row)
		coords.append(coord_row)
	var stem := "day-%02d-%s" % [day, record.name]
	image.save_png(output_dir.path_join(stem + "-native.png"))
	image.resize(image.get_width() * SCALE, image.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	image.save_png(output_dir.path_join(stem + "-4x.png"))
	var grid := {"day": day, "name": record.name, "rect": [rect.position.x, rect.position.y,
				rect.size.x, rect.size.y], "source_ids": ids, "atlas_coords": coords}
	var grid_file := FileAccess.open(output_dir.path_join(stem + ".json"), FileAccess.WRITE)
	grid_file.store_string(JSON.stringify(grid, "\t") + "\n")

func _write_manifest(output_dir: String, tile_set: TileSet, city_map: CityMap,
		rects: Array[Dictionary]) -> void:
	var hashes: Dictionary = {}
	for path in _input_paths():
		hashes[path] = FileAccess.get_sha256(path)
	var grass := tile_set.get_source(GroundLayers.GRASS_SOURCE_ID) as TileSetAtlasSource
	var manifest := {
		"seed_requested": SEED,
		"seed_used": city_map.seed_used,
		"days": DAYS,
		"command": "godot --headless --path . res://docs/evidence/layered-ground-layout-2026-09-12/layout_capture.tscn -- --output-dir DIRECTORY",
		"tile_size": Tuning.TILE_SIZE,
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"grass_atlas_size": [grass.texture.get_width(), grass.texture.get_height()],
		"grass_variants": GroundLayers.GRASS_VARIANTS,
		"inputs_sha256": hashes,
		"crops": rects,
	}
	var file := FileAccess.open(output_dir.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")

func _input_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in INPUTS:
		paths.append(path)
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(
			"res://assets/illustrated/svg-transfer/tiles/layers/manifest.json")) != OK:
		return paths
	if parser.data is not Dictionary:
		return paths
	var manifest: Dictionary = parser.data
	var root := "res://assets/illustrated/svg-transfer/tiles/layers"
	for collection_name in ["bases", "components"]:
		var collection: Dictionary = manifest.get(collection_name, {})
		for filename_value in collection.values():
			var path: String = root.path_join(str(filename_value))
			if not path in paths:
				paths.append(path)
	return paths
