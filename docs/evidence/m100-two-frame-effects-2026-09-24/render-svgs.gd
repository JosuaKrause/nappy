extends SceneTree
## Scratch: render each SVG given after `--` at scales 1 and 4 into /tmp/tfe/out/<name>@<s>.png.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("/tmp/tfe/out")
	for source in args:
		for scale in [1.0, 4.0]:
			var raster := Image.new()
			if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
				push_error("SVG render failed: " + source)
				quit(1)
				return
			var dest := "/tmp/tfe/out/%s@%d.png" % [source.get_file().get_basename(), int(scale)]
			if raster.save_png(dest) != OK:
				push_error("PNG save failed: " + dest)
				quit(1)
				return
			print("wrote ", dest)
	quit(0)
