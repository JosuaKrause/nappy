extends Node
## Writes the runtime's shared damage atlases at native size and 4× for stable visual review.

const SCALE := 4
const TILE_SET: TileSet = preload("res://assets/ground_tileset.tres")
const INPUTS := [
	"res://assets/ground_tileset.tres",
	"res://assets/illustrated/svg-transfer/tiles/layers/manifest.json",
	"res://src/visuals/ground_layers.gd",
	"res://src/visuals/texture_resolver.gd",
	"res://docs/evidence/shared-damage-2026-09-12/damage_atlas_review.gd",
]
const RECORDS := [
	{"name": "road-hairline", "source_id": 40},
	{"name": "road-cracked", "source_id": 42},
	{"name": "road-broken", "source_id": 44},
	{"name": "sidewalk-hairline", "source_id": 46},
	{"name": "sidewalk-cracked", "source_id": 48},
	{"name": "sidewalk-broken", "source_id": 50},
	{"name": "alley-hairline", "source_id": 52},
	{"name": "alley-cracked", "source_id": 54},
	{"name": "alley-broken", "source_id": 56},
]

var _output_dir := ""

func _ready() -> void:
	if not _parse_args():
		return
	TextureResolver.reset_for_tests(false)
	var composed := GroundLayers.build_tile_set(TILE_SET)
	var records: Array = []
	for record_value in RECORDS:
		var record: Dictionary = record_value
		var source_id: int = int(record["source_id"])
		var source := composed.get_source(source_id) as TileSetAtlasSource
		if source == null or source.texture == null:
			_fail("missing composed damage source %d" % source_id)
			return
		var atlas: Image = source.texture.get_image()
		if atlas.get_size() != Vector2i(GroundLayers.TILE_SIZE.x * GroundLayers.DAMAGE_VARIANTS,
				GroundLayers.TILE_SIZE.y):
			_fail("damage source %d does not have the expected shared atlas size" % source_id)
			return
		var stem: String = str(record["name"])
		atlas.save_png(_output_dir.path_join(stem + "-native.png"))
		var enlarged := atlas.duplicate()
		enlarged.resize(atlas.get_width() * SCALE, atlas.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
		enlarged.save_png(_output_dir.path_join(stem + "-4x.png"))
		records.append({"name": stem, "source_id": source_id,
			"atlas_size": [atlas.get_width(), atlas.get_height()],
			"atlas_cells": GroundLayers.DAMAGE_VARIANTS})
	_write_manifest(records)
	TextureResolver.reset_for_tests(DevFlags.svg_requested())
	get_tree().quit()

func _parse_args() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print("usage: damage_atlas_review.tscn -- --output-dir DIRECTORY")
		get_tree().quit()
		return false
	if args.size() != 2 or args[0] != "--output-dir":
		_fail("usage: damage_atlas_review.tscn -- --output-dir DIRECTORY")
		return false
	_output_dir = args[1]
	if DirAccess.dir_exists_absolute(_output_dir) or FileAccess.file_exists(_output_dir):
		_fail("refusing to overwrite existing output: %s" % _output_dir)
		return false
	if DirAccess.make_dir_recursive_absolute(_output_dir) != OK:
		_fail("cannot create output directory: %s" % _output_dir)
		return false
	return true

func _write_manifest(records: Array) -> void:
	var hashes: Dictionary = {}
	for path in INPUTS:
		hashes[path] = FileAccess.get_sha256(path)
	var result := {
		"command": "godot --headless --path . res://docs/evidence/shared-damage-2026-09-12/damage_atlas_review.tscn -- --output-dir DIRECTORY",
		"godot_version": Engine.get_version_info().get("string", "unknown"),
		"presentation_mode": "default PNG composition",
		"tile_size": [GroundLayers.TILE_SIZE.x, GroundLayers.TILE_SIZE.y],
		"damage_variants": GroundLayers.DAMAGE_VARIANTS,
		"records": records,
		"inputs_sha256": hashes,
	}
	var output := FileAccess.open(_output_dir.path_join("manifest.json"), FileAccess.WRITE)
	if output == null:
		_fail("cannot write review manifest: %s" % _output_dir)
		return
	output.store_string(JSON.stringify(result, "\t") + "\n")

func _fail(message: String) -> void:
	printerr(message)
	get_tree().quit(2)
