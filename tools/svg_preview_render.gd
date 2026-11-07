extends SceneTree
## Renders SVG files with the runtime SVG parser at each requested scale, one PNG per scale.
## Invoked only by tools/svg-preview.sh, which validates its arguments first and runs this in a
## scratch project with no game autoloads.

const USAGE := """usage: Godot --headless --path <scratch-project> --script tools/svg_preview_render.gd -- OUTDIR SCALES FILE...

Writes OUTDIR/<name>@<scale>x.png for each FILE (an SVG) and each scale in SCALES (comma
separated). Normally invoked by tools/svg-preview.sh.
"""

func _init() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() == 1 and arguments[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	if arguments.size() < 3:
		printerr("svg_preview_render.gd: expected OUTDIR SCALES FILE...")
		printerr(USAGE)
		quit(2)
		return
	var out_dir: String = arguments[0]
	var scales: PackedStringArray = arguments[1].split(",")
	for index in range(2, arguments.size()):
		var source: String = arguments[index]
		for label in scales:
			var scale := float(label)
			var raster := Image.new()
			if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
				push_error("SVG render failed: " + source)
				quit(1)
				return
			var destination := out_dir.path_join("%s@%sx.png" % [source.get_file().get_basename(), label])
			if raster.save_png(destination) != OK:
				push_error("PNG save failed: " + destination)
				quit(1)
				return
			print("rendered ", destination, " ", raster.get_width(), "x", raster.get_height())
	quit()
