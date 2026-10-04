extends SceneTree
## Rasterizes SVGs with the engine's own SVG loader, the call the atlas bake makes.
## usage: godot --headless --path <scratch project> --script render.gd -- <scale> <outdir> <svg>...
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var scale := float(args[0])
	var outdir := args[1]
	for i in range(2, args.size()):
		var source := args[i]
		var raster := Image.new()
		var result := raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale)
		if result != OK:
			push_error("SVG render failed: " + source)
			quit(1)
			return
		var dest := outdir + "/" + source.get_file().get_basename() + "@" + str(scale) + ".png"
		if raster.save_png(dest) != OK:
			push_error("PNG save failed: " + dest)
			quit(1)
			return
	quit(0)
