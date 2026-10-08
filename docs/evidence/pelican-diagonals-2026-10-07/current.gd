extends SceneTree
## Current candidate only: NE A/B, SE A/B, E A/B; western mirrors beneath.
## Usage: Godot --headless --path <minimal project> --script <this file> -- <art/events> <output>
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("Expected art/events and output directory")
		quit(2)
		return
	var names: Array[String] = ["_back_diagonal", "_back_diagonal_b", "_front_diagonal", "_front_diagonal_b", "", "_b"]
	for scale: int in [1, 6]:
		var cell := Vector2i(48 * scale, 52 * scale + 20)
		var sheet := Image.create(cell.x * 6, cell.y * 2, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("96928a"))
		for row: int in range(2):
			for column: int in range(6):
				var source: String = args[0] + "/pelican_cyclist" + names[column] + ".svg"
				var raster := Image.new()
				if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
					push_error("Could not render " + source)
					quit(1)
					return
				if row == 1:
					raster.flip_x()
				var at := Vector2i(column * cell.x + 4 * scale, (row + 1) * cell.y - 4 * scale - raster.get_height())
				sheet.blend_rect(raster, Rect2i(Vector2i.ZERO, raster.get_size()), at)
		var destination: String = args[1] + "/current-" + str(scale) + "x.png"
		if sheet.save_png(destination) != OK:
			push_error("Could not save " + destination)
			quit(1)
			return
	quit()
