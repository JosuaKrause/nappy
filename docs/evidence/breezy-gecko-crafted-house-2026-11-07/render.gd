extends SceneTree
## Renders SVGs through the engine's own parser (`Image.load_svg_from_string()`), the one the game's
## atlas bake uses, so a draft is judged as the game would draw it. Each source is written as
## `<output-dir>/<name>-<scale>x.png`, at every scale given.
##
##   godot --headless --path <checkout> --script docs/evidence/breezy-gecko-crafted-house-2026-11-07/render.gd \
##       -- --output-dir FRESH_DIR --scale 1 --scale 3 SOURCE.svg...

const USAGE := "Usage: godot --headless --path . --script render.gd -- --output-dir FRESH_DIRECTORY --scale N [--scale N]... SOURCE.svg..."

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	var output := ""
	var scales: Array[float] = []
	var sources: Array[String] = []
	var index := 0
	while index < args.size():
		var word := args[index]
		if word == "--output-dir" and index + 1 < args.size() and output.is_empty():
			output = args[index + 1]
			index += 2
		elif word == "--scale" and index + 1 < args.size() and args[index + 1].is_valid_float():
			scales.append(float(args[index + 1]))
			index += 2
		elif word.ends_with(".svg") and not word.begins_with("--"):
			sources.append(word)
			index += 1
		else:
			push_error(USAGE)
			quit(2)
			return
	if output.is_empty() or scales.is_empty() or sources.is_empty():
		push_error(USAGE)
		quit(2)
		return
	var out_dir := ProjectSettings.globalize_path(output)
	if DirAccess.dir_exists_absolute(out_dir) or FileAccess.file_exists(out_dir):
		push_error("Output must be fresh: " + out_dir)
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	for source in sources:
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
			var destination := "%s/%s-%dx.png" % [out_dir, source.get_file().get_basename(), int(scale)]
			if raster.save_png(destination) != OK:
				push_error("PNG save failed: " + destination)
				quit(1)
				return
			print("wrote ", destination)
	quit()
