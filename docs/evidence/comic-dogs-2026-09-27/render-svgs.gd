extends SceneTree
## Rasterizes this review batch's SVGs through Godot's SVG parser at scales 1 and 6.
##
## Usage: godot --headless --path <project> --script render-svgs.gd -- LIST ROOT OUT

const USAGE := "usage: godot --headless --path <project> --script render-svgs.gd -- LIST ROOT OUT"

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	if args.size() != 3:
		push_error(USAGE)
		quit(2)
		return
	var lines := FileAccess.get_file_as_string(args[0]).split("\n", false)
	var failures := 0
	for rel in lines:
		var src: String = args[1].path_join(rel)
		var source := FileAccess.get_file_as_string(src)
		for scale in [1.0, 6.0]:
			var image := Image.new()
			if image.load_svg_from_string(source, scale) != OK:
				push_error("SVG render failed: " + src)
				failures += 1
				continue
			var dst: String = args[2].path_join(rel.trim_suffix(".svg") + "@%d.png" % int(scale))
			DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
			if image.save_png(dst) != OK:
				push_error("PNG save failed: " + dst)
				failures += 1
	print("rendered %d sources at two scales, %d failures" % [lines.size(), failures])
	quit(1 if failures > 0 else 0)
