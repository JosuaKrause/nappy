extends SceneTree
## Rasterizes SVG files through the engine's own SVG parser (the one the atlas bake uses) at the
## given scales, one transparent PNG per file and scale, named <label>@<scale>x.png.

func _init() -> void:
	var usage := "Usage: godot --headless --path . --script render-svgs.gd -- --output-dir FRESH_DIR --scales 1,4 LABEL=PATH.svg [LABEL=PATH.svg ...]"
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	var output := ""
	var scales: Array[float] = []
	var sources: Dictionary = {}
	var index := 0
	while index < args.size():
		var word := args[index]
		if word == "--output-dir" and index + 1 < args.size() and output.is_empty():
			output = args[index + 1]
			index += 2
		elif word == "--scales" and index + 1 < args.size() and scales.is_empty():
			for part in args[index + 1].split(","):
				if not part.is_valid_float():
					push_error(usage)
					quit(2)
					return
				scales.append(float(part))
			index += 2
		elif "=" in word and not word.begins_with("-"):
			var pair := word.split("=", true, 1)
			sources[pair[0]] = pair[1]
			index += 1
		else:
			push_error(usage)
			quit(2)
			return
	if output.is_empty() or scales.is_empty() or sources.is_empty():
		push_error(usage)
		quit(2)
		return
	output = ProjectSettings.globalize_path(output)
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output):
		push_error("Output must be fresh: " + output)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	for label: String in sources:
		var source: String = sources[label]
		var text := FileAccess.get_file_as_string(source)
		if text.is_empty():
			push_error("Cannot read: " + source)
			quit(1)
			return
		for scale in scales:
			var raster := Image.new()
			if raster.load_svg_from_string(text, scale) != OK:
				push_error("SVG render failed: " + source)
				quit(1)
				return
			var destination := output.path_join("%s@%dx.png" % [label, int(scale)])
			if raster.save_png(destination) != OK:
				push_error("PNG save failed: " + destination)
				quit(1)
				return
			print(destination)
	quit()
