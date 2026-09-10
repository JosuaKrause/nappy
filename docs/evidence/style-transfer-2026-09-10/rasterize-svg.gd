extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		quit(2)
		return
	var source := FileAccess.get_file_as_string(args[0])
	var raster := Image.new()
	var error := raster.load_svg_from_string(source, float(args[2]))
	if error != OK:
		quit(error)
		return
	error = raster.save_png(args[1])
	print("%s: %s" % [args[1], raster.get_size()])
	quit(error)
