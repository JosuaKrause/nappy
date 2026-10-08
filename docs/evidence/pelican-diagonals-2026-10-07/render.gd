extends SceneTree
## Source comparison, using the same SVG parser as the game's atlas bake.
## Columns: NE A, NE B, SE A, SE B. Rows: baseline, current, mirrored current.
## Usage: Godot --headless --path <minimal project> --script <this file> -- <baseline art/events> <current art/events> <output directory>
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("Expected baseline art/events, current art/events, and output directory")
		quit(2)
		return
	var names: Array[String] = ["back_diagonal", "back_diagonal_b", "front_diagonal", "front_diagonal_b"]
	for scale: int in [1, 6]:
		var cell := Vector2i(48, 52) * scale
		var sheet := Image.create(cell.x * 4, cell.y * 3, false, Image.FORMAT_RGBA8)
		sheet.fill(Color("96928a"))
		for row: int in range(3):
			for column: int in range(4):
				var source: String = args[0 if row == 0 else 1] + "/pelican_cyclist_" + names[column] + ".svg"
				var raster := Image.new()
				if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
					push_error("Could not render " + source)
					quit(1)
					return
				if row == 2:
					raster.flip_x()
				sheet.blend_rect(raster, Rect2i(Vector2i.ZERO, raster.get_size()), Vector2i(column * cell.x + 4 * scale, row * cell.y + 4 * scale))
		var destination: String = args[2] + "/comparison-" + str(scale) + "x.png"
		if sheet.save_png(destination) != OK:
			push_error("Could not save " + destination)
			quit(1)
			return
		print(destination)
	quit()
