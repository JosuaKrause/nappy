extends SceneTree
## Renders the charger pose review sheet through the engine's own SVG parser
## (`Image.load_svg_from_string`) and composes it on the sidewalk ground colour.
##
## The spec is a JSON object: `rows`, a list of rows, each a list of SVG paths relative to the
## repository root; `scales`, the scales to draw (the first is game scale). Each scale is one block
## of the sheet, its rows stacked; every picture stands on one ground line per row, centred in a
## column as wide as the row's widest picture, which is how `Sprites` grounds a standing sprite
## (bottom centre).

const SIDEWALK := Color("8b8478")
const PAD := 6


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var usage := "Usage: godot --headless --path <any project> --script render-sheet.gd -- --repo REPO_ROOT --spec SPEC.json --output FRESH.png"
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(usage)
		quit()
		return
	var options := {}
	var index := 0
	while index < args.size():
		if args[index] in ["--repo", "--spec", "--output"] and index + 1 < args.size() and not options.has(args[index]):
			options[args[index]] = args[index + 1]
		else:
			push_error(usage)
			quit(2)
			return
		index += 2
	if options.size() != 3:
		push_error(usage)
		quit(2)
		return
	var output: String = options["--output"]
	if FileAccess.file_exists(output):
		push_error("Output must be fresh, a delivered sheet is never overwritten: " + output)
		quit(2)
		return
	var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string(options["--spec"]))
	if not spec is Dictionary or not spec.has("rows") or not spec.has("scales"):
		push_error("The spec must be a JSON object with rows and scales: " + options["--spec"])
		quit(2)
		return
	var blocks: Array[Image] = []
	for scale: float in spec["scales"]:
		var block := _render_block(options["--repo"], spec["rows"], scale)
		if block == null:
			quit(1)
			return
		blocks.append(block)
	var width := 0
	var height := PAD
	for block in blocks:
		width = maxi(width, block.get_width())
		height += block.get_height() + PAD
	var sheet := Image.create_empty(width + 2 * PAD, height, false, Image.FORMAT_RGBA8)
	sheet.fill(SIDEWALK)
	var y := PAD
	for block in blocks:
		sheet.blend_rect(block, Rect2i(Vector2i.ZERO, block.get_size()), Vector2i(PAD, y))
		y += block.get_height() + PAD
	if sheet.save_png(output) != OK:
		push_error("PNG save failed: " + output)
		quit(1)
		return
	print("wrote ", output, " ", sheet.get_size())
	quit()


func _render_block(repo: String, rows: Array, scale: float) -> Image:
	var rendered: Array = []
	var column_widths: Array[int] = []
	var row_heights: Array[int] = []
	for row: Array in rows:
		var images: Array[Image] = []
		var row_height := 0
		for column in row.size():
			var source: String = repo.path_join(row[column])
			var raster := Image.new()
			if raster.load_svg_from_string(FileAccess.get_file_as_string(source), scale) != OK:
				push_error("SVG render failed: " + source)
				return null
			raster.convert(Image.FORMAT_RGBA8)
			images.append(raster)
			row_height = maxi(row_height, raster.get_height())
			while column_widths.size() <= column:
				column_widths.append(0)
			column_widths[column] = maxi(column_widths[column], raster.get_width())
		rendered.append(images)
		row_heights.append(row_height)
	var gap := int(PAD * maxf(scale, 1.0))
	var width := 0
	for column_width in column_widths:
		width += column_width + gap
	var height := 0
	for row_height in row_heights:
		height += row_height + gap
	var block := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	block.fill(SIDEWALK)
	var y := 0
	for row_index in rendered.size():
		var x := 0
		var images: Array[Image] = rendered[row_index]
		for column in images.size():
			var image := images[column]
			var left := x + (column_widths[column] - image.get_width()) / 2
			var top := y + row_heights[row_index] - image.get_height()
			block.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(left, top))
			x += column_widths[column] + gap
		y += row_heights[row_index] + gap
	return block
