extends SceneTree


func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() != 4 or arguments[0] != "--output" or arguments[2] != "--source":
		push_error("usage: --output <plaza-svg-8x.png> --source <plaza.svg>")
		quit(2)
		return
	var source: String = FileAccess.get_file_as_string(arguments[3])
	if source.is_empty():
		push_error("cannot read plaza SVG: " + arguments[3])
		quit(1)
		return
	var raster: Image = Image.new()
	var result: Error = raster.load_svg_from_string(source, 8.0)
	if result != OK:
		push_error("SVG render failed: " + arguments[3])
		quit(1)
		return
	if raster.save_png(arguments[1]) != OK:
		push_error("cannot save SVG render: " + arguments[1])
		quit(1)
		return
	quit()
