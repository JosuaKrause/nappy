extends SceneTree
## Renders SVG files at a given scale with Godot's own SVG parser.
## usage: godot --headless --path <proj> --script render.gd -- <scale> <out_dir> <svg>...
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3 or args[0] in ["-h", "--help"]:
		print("usage: render.gd -- <scale> <out_dir> <svg>...")
		quit(0 if args.size() > 0 and args[0] in ["-h", "--help"] else 2)
		return
	var scale := float(args[0])
	var out_dir: String = args[1]
	for i in range(2, args.size()):
		var source: String = args[i]
		var raster := Image.new()
		var result := raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
		if result != OK:
			push_error("SVG render failed: " + source)
			quit(1)
			return
		var dest := out_dir.path_join(source.get_file().get_basename() + "@%sx.png" % args[0])
		if raster.save_png(dest) != OK:
			push_error("PNG save failed: " + dest)
			quit(1)
			return
	quit(0)
