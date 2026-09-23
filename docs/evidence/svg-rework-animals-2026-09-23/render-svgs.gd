extends SceneTree
## Rasterizes the animal SVGs through the engine's own SVG parser (the one the atlas bake uses) at
## scales 1 and 6, one transparent PNG per file and scale, named <path without .svg>@<scale>.png
## under the output directory. The list file names one repository-relative SVG path per line.
##
## Usage: godot --headless --path <any project> --script render-svgs.gd -- LIST ROOT OUT
##   LIST  a text file of paths such as art/events/dog.svg, one per line
##   ROOT  the tree the paths are read from (a checkout, or a folder `git show` wrote into)
##   OUT   where the PNGs go

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
		var text := FileAccess.get_file_as_string(src)
		for scale in [1.0, 6.0]:
			var img := Image.new()
			if img.load_svg_from_string(text, scale) != OK:
				push_error("SVG render failed: " + src)
				failures += 1
				continue
			var dst: String = args[2].path_join(rel.trim_suffix(".svg") + "@%d.png" % int(scale))
			DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
			if img.save_png(dst) != OK:
				push_error("PNG save failed: " + dst)
				failures += 1
	print("rendered %d sources, %d failures" % [lines.size(), failures])
	quit(1 if failures > 0 else 0)
