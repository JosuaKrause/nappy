extends Node
## Boots the actual main scene and records the ground resource after City.build().

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GRASS_SOURCE_ID := 12
const TILE_SIZE := Vector2i(32, 32)
const INPUT_PATHS := [
	"res://docs/evidence/grass-runtime-2026-09-12/runtime_probe.gd",
	"res://docs/evidence/grass-runtime-2026-09-12/grass_runtime_probe.tscn",
	"res://scenes/main.tscn",
	"res://scenes/world/city.tscn",
	"res://src/city/city.gd",
	"res://src/visuals/ground_layers.gd",
	"res://src/visuals/texture_resolver.gd",
	"res://assets/ground_tileset.tres",
	"res://assets/illustrated/svg-transfer/tiles/layers/manifest.json",
	"res://assets/illustrated/svg-transfer/tiles/layers/grass_base.png",
	"res://assets/illustrated/svg-transfer/tiles/layers/grass_feature_a.png",
	"res://assets/illustrated/svg-transfer/tiles/layers/grass_feature_b.png",
	"res://assets/illustrated/svg-transfer/tiles/layers/grass_feature_c.png",
	"res://assets/illustrated/svg-transfer/tiles/grass.png",
	"res://assets/illustrated/svg-transfer/tiles/forest.png",
]

var _valid := true
var _output_dir := ""

func _enter_tree() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print("usage: grass_runtime_probe.tscn -- --output-dir DIRECTORY [--seed SEED]")
		_valid = false
		get_tree().quit()
		return
	var output_index := args.find("--output-dir")
	if output_index == -1 or output_index + 1 >= args.size():
		printerr("usage: grass_runtime_probe.tscn -- --output-dir DIRECTORY [--seed SEED]")
		_valid = false
		get_tree().quit(2)
		return
	if args.find("--output-dir", output_index + 1) != -1:
		printerr("duplicate argument: --output-dir")
		_valid = false
		get_tree().quit(2)
		return
	_output_dir = args[output_index + 1]
	var seed_count := 0
	var index := 0
	while index < args.size():
		if index == output_index:
			index += 2
			continue
		if args[index] == "--seed" and index + 1 < args.size():
			seed_count += 1
			if not args[index + 1].is_valid_int():
				printerr("seed must be an integer: %s" % args[index + 1])
				_valid = false
				get_tree().quit(2)
				return
			index += 2
			continue
		printerr("unknown argument: %s" % args[index])
		_valid = false
		get_tree().quit(2)
		return
	if seed_count > 1:
		printerr("duplicate argument: --seed")
		_valid = false
		get_tree().quit(2)
		return
	if DirAccess.dir_exists_absolute(_output_dir) or FileAccess.file_exists(_output_dir):
		printerr("refusing to overwrite existing output: %s" % _output_dir)
		_valid = false
		get_tree().quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(_output_dir) != OK:
		printerr("cannot create output directory: %s" % _output_dir)
		_valid = false
		get_tree().quit(2)

func _ready() -> void:
	if not _valid:
		return
	var args := OS.get_cmdline_user_args()
	var main: Node = MAIN_SCENE.instantiate()
	main.name = "Main"
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_node_or_null("Main")
	var city: Node = main.get_node_or_null("City") if main else null
	var ground: TileMapLayer = city.get_node_or_null("Ground") as TileMapLayer if city else null
	var tile_set: TileSet = ground.tile_set if ground else null
	var source: TileSetAtlasSource = tile_set.get_source(GRASS_SOURCE_ID) as TileSetAtlasSource if tile_set else null
	var texture: Texture2D = source.texture if source else null
	var cells: Array = []
	if source:
		for cell_x in range(8):
			cells.append(source.has_tile(Vector2i(cell_x, 0)))
	var forest_source: TileSetAtlasSource = tile_set.get_source(17) as TileSetAtlasSource if tile_set else null
	var forest_texture: Texture2D = forest_source.texture if forest_source else null
	var forest_tile := Vector2i(42, 26)
	var forest_cell_source := ground.get_cell_source_id(forest_tile) if ground else -1
	var forest_cell_coords := ground.get_cell_atlas_coords(forest_tile) if ground else Vector2i(-1, -1)
	var forest_cells_nearby: Array = []
	if ground:
		for y in range(forest_tile.y - 4, forest_tile.y + 5):
			for x in range(forest_tile.x - 4, forest_tile.x + 5):
				var at := Vector2i(x, y)
				if ground.get_cell_source_id(at) == 17:
					var coords := ground.get_cell_atlas_coords(at)
					forest_cells_nearby.append([x, y, coords.x, coords.y])
	var result := {
		"command_line_args": Array(args),
		"dev_flags_svg_requested": DevFlags.svg_requested(),
		"main_scene": "res://scenes/main.tscn",
		"city_scene": "res://scenes/world/city.tscn",
		"city_found": city != null,
		"ground_found": ground != null,
		"grass_source_id": GRASS_SOURCE_ID,
		"grass_source_found": source != null,
		"grass_texture_resource_path": texture.resource_path if texture else "",
		"grass_texture_size": [texture.get_width(), texture.get_height()] if texture else [],
		"grass_texture_is_atlas": texture != null and texture.get_width() >= TILE_SIZE.x * 2,
		"grass_atlas_cells_0_to_7": cells,
		"expected_composed_atlas_size": [TILE_SIZE.x * 8, TILE_SIZE.y],
		"forest_source_id": 17,
		"forest_texture_resource_path": forest_texture.resource_path if forest_texture else "",
		"forest_texture_size": [forest_texture.get_width(), forest_texture.get_height()] if forest_texture else [],
		"forest_cell": [forest_tile.x, forest_tile.y],
		"forest_cell_source_id": forest_cell_source,
		"forest_cell_atlas_coords": [forest_cell_coords.x, forest_cell_coords.y],
		"forest_cells_nearby_x42_y26": forest_cells_nearby,
		"engine_version": Engine.get_version_info().get("string", "unknown"),
		"input_sha256": _input_hashes(),
	}
	var file := FileAccess.open(_output_dir.path_join("runtime-result.json"), FileAccess.WRITE)
	if file == null:
		printerr("cannot write probe output: %s" % _output_dir)
		get_tree().quit(2)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	if texture:
		texture.get_image().save_png(_output_dir.path_join("park-grass-atlas.png"))
	if forest_texture:
		forest_texture.get_image().save_png(_output_dir.path_join("forest-atlas.png"))
	_save_ground_crop(ground, tile_set, forest_tile)
	print(JSON.stringify(result))
	get_tree().quit()

func _input_hashes() -> Dictionary:
	var hashes := {}
	for path in INPUT_PATHS:
		hashes[path] = FileAccess.get_sha256(path)
	return hashes

func _save_ground_crop(ground: TileMapLayer, tile_set: TileSet, centre: Vector2i) -> void:
	var rect := Rect2i(centre - Vector2i(4, 4), Vector2i(9, 9))
	var image := Image.create(rect.size.x * TILE_SIZE.x, rect.size.y * TILE_SIZE.y,
		false, Image.FORMAT_RGBA8)
	image.fill(Color("202126"))
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var at := Vector2i(x, y)
			var source_id := ground.get_cell_source_id(at)
			if source_id < 0:
				continue
			var source := tile_set.get_source(source_id) as TileSetAtlasSource
			if source == null or source.texture == null:
				continue
			var coords := ground.get_cell_atlas_coords(at)
			var source_image := source.texture.get_image()
			var source_rect := Rect2i(coords * TILE_SIZE, TILE_SIZE)
			var destination := Vector2i((x - rect.position.x) * TILE_SIZE.x,
				(y - rect.position.y) * TILE_SIZE.y)
			image.blit_rect(source_image, source_rect, destination)
	image.save_png(_output_dir.path_join("forest-area-native.png"))
	image.resize(image.get_width() * 4, image.get_height() * 4, Image.INTERPOLATE_NEAREST)
	image.save_png(_output_dir.path_join("forest-area-4x.png"))
