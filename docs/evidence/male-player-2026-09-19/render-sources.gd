extends SceneTree
## Renders editable male player sources through the engine's SVG parser.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path . --script render-sources.gd -- [--source-map PATH] --output-dir FRESH_DIRECTORY"
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	var output_argument := ""
	var source_map_argument := ""
	var index := 0
	while index < args.size():
		if args[index] == "--output-dir" and index + 1 < args.size() and output_argument.is_empty():
			output_argument = args[index + 1]
		elif args[index] == "--source-map" and index + 1 < args.size() and source_map_argument.is_empty():
			source_map_argument = args[index + 1]
		else:
			push_error(usage)
			quit(2)
			return
		index += 2
	if output_argument.is_empty():
		push_error(usage)
		quit(2)
		return
	var source_map: Dictionary = {}
	var source_map_path := ""
	if not source_map_argument.is_empty():
		source_map_path = ProjectSettings.globalize_path(source_map_argument)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_map_path))
		if not parsed is Dictionary:
			push_error("Source map must be a JSON object: " + source_map_path)
			quit(2)
			return
		source_map = parsed
	var output := ProjectSettings.globalize_path(output_argument)
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Output must be fresh: " + output)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for state in ["", "carrying_"]:
		for view in ["front", "back", "side", "front_diagonal", "back_diagonal"]:
			for pose in ["a", "c", "b"]:
				var name := "father_%s%s_%s" % [state, view, pose]
				var logical_source := "assets/rig/%s.svg" % name
				var source := "res://" + logical_source
				if source_map.has(logical_source):
					var entry: Variant = source_map[logical_source]
					if not entry is Dictionary or not entry.has("file") or not entry.has("sha256"):
						push_error("Invalid source-map entry: " + logical_source)
						quit(2)
						return
					source = source_map_path.get_base_dir().path_join(entry["file"])
					var context := HashingContext.new()
					context.start(HashingContext.HASH_SHA256)
					context.update(FileAccess.get_file_as_bytes(source))
					if context.finish().hex_encode() != entry["sha256"]:
						push_error("Historical source hash differs: " + logical_source)
						quit(1)
						return
				for scale in [1.0, 3.0, 8.0]:
					var raster := Image.new()
					var error := raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
					if error != OK or raster.save_png("%s/%s-%dx.png" % [output, name, scale]) != OK:
						push_error("SVG render failed: " + source)
						quit(1)
						return
	quit()
