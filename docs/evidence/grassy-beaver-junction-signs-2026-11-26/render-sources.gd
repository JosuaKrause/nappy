extends SceneTree
## Renders SVGs side by side at scales 1 and 3 on a sidewalk-grey ground, writing
## <out-prefix>_x1.png and <out-prefix>_x3.png.
## Usage: godot --headless --path . --script render-sources.gd -- <out-prefix> <svg>...
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var sources: Array[String] = []
	for i in range(1, args.size()):
		sources.append(args[i])
	for scale: float in [1.0, 3.0]:
		var images: Array[Image] = []
		var width := 8
		var height := 0
		for source in sources:
			var raster := Image.new()
			if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
				push_error("render failed " + source)
				quit(1)
				return
			raster.convert(Image.FORMAT_RGBA8)
			images.append(raster)
			width += raster.get_width() + int(8 * scale)
			height = maxi(height, raster.get_height())
		var sheet := Image.create(width, height + int(16 * scale), false, Image.FORMAT_RGBA8)
		sheet.fill(Color("8f8a80"))
		var x := 8
		for raster in images:
			sheet.blend_rect(raster, Rect2i(Vector2i.ZERO, raster.get_size()), Vector2i(x, int(8 * scale) + height - raster.get_height()))
			x += raster.get_width() + int(8 * scale)
		sheet.save_png(out + "_x%d.png" % int(scale))
	quit(0)
