extends SceneTree
## Scratch: render each SVG named after `--` through Godot's own SVG rasterizer at scales 1, 2
## and 4, into the directory given by `--out` (created if missing), as `<name>@<scale>.png`.
##
## godot --headless --path . --script docs/evidence/m100-vent-pipe-2026-09-24/render-svgs.gd \
##     -- --out /tmp/m100vp/out art/events/steam_pipe.svg art/events/steam.svg ...

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path . --script render-svgs.gd -- --out DIR SVG..."
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	if args.size() < 3 or args[0] != "--out":
		push_error(usage)
		quit(2)
		return
	var out: String = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	for source: String in args.slice(2):
		for scale in [1, 2, 4]:
			var raster := Image.new()
			if raster.load_svg_from_string(FileAccess.get_file_as_string(source), float(scale)) != OK:
				push_error("SVG render failed: " + source)
				quit(1)
				return
			var dest := "%s/%s@%d.png" % [out, source.get_file().get_basename(), scale]
			if raster.save_png(dest) != OK:
				push_error("PNG save failed: " + dest)
				quit(1)
				return
			print("wrote ", dest)
	quit(0)
