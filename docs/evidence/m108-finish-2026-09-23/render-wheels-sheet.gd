extends SceneTree
## Renders the before/after sheet of the vehicle wheel split through the engine's SVG parser, and
## prints how far each split picture at rest differs from the single picture it was split from.
##
## One row per view, five cells at 3x over neutral ground: the picture before the split (a crowd
## car's tinted body under its old trim; an event vehicle's one file), the body layer (with its
## trim, for a crowd car), the wheels layer, the split drawn at rest, and the split with the body
## lifted by one world pixel over wheels that stay put — the top of the bob. The wheels go over the
## body except where `EventInstance.WHEELS_BEHIND_THE_BODY` puts them under, which this script
## restates rather than reads, since a `--script` run has no autoloads to load the class with.

const USAGE := "Usage: godot --headless --path . --script render-wheels-sheet.gd -- --before DIR --output FILE.png\n  DIR holds the pre-split art/crowd/car_{view}_{body,trim}.svg and art/events/<vehicle>.svg\n  under crowd/ and events/, e.g. from git show <commit>:art/crowd/car_side_trim.svg."

const SCALE := 3
const PAD := 6
const GROUND := Color8(0xc9, 0xc3, 0xb3)
const PAINT := Color8(0x8f, 0xa8, 0x8a)
const VIEWS: Array[String] = ["side", "front", "back", "front_diagonal", "back_diagonal"]
const FAMILIES: Array[String] = ["police_car", "fire_engine", "unmarked_van", "riot_van",
		"army_truck", "lorry"]
## The views whose tyres the original drew before the body — the flanks of a 34x50 end view.
const BEHIND: Array[String] = ["fire_engine_front", "fire_engine_back", "unmarked_van_front",
		"unmarked_van_back", "riot_van_front", "riot_van_back", "army_truck_front",
		"army_truck_back", "lorry_front", "lorry_back"]

var _rows: Array = []

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 1 and args[0] in ["--help", "-h"]:
		print(USAGE)
		quit()
		return
	var before := ""
	var output := ""
	var index := 0
	while index < args.size():
		if args[index] == "--before" and index + 1 < args.size() and before.is_empty():
			before = args[index + 1]
		elif args[index] == "--output" and index + 1 < args.size() and output.is_empty():
			output = args[index + 1]
		else:
			push_error(USAGE)
			quit(2)
			return
		index += 2
	if before.is_empty() or output.is_empty():
		push_error(USAGE)
		quit(2)
		return
	for view in VIEWS:
		var ok := _crowd_row(before, view)
		if not ok:
			quit(1)
			return
	for family in FAMILIES:
		for view in VIEWS:
			var name := family if view == "side" else "%s_%s" % [family, view]
			if not _event_row(before, name):
				quit(1)
				return
	var sheet := _sheet()
	if sheet.save_png(ProjectSettings.globalize_path(output)) != OK:
		push_error("could not save " + output)
		quit(1)
		return
	print("wrote %s (%dx%d)" % [output, sheet.get_width(), sheet.get_height()])
	quit()

func _render(path: String, scale: float) -> Image:
	var image := Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string(path), scale) != OK:
		push_error("SVG render failed: " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image

func _tinted(image: Image, tint: Color) -> Image:
	var out := image.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			out.set_pixel(x, y, out.get_pixel(x, y) * tint)
	return out

## Layers drawn bottom to top onto one canvas, each at its own vertical offset in pixels, with
## `SCALE` rows of headroom above the source canvas so a lifted body is not clipped at its top.
func _stack(size: Vector2i, layers: Array, offsets: Array) -> Image:
	var out := Image.create(size.x, size.y + SCALE, false, Image.FORMAT_RGBA8)
	for i in layers.size():
		var layer: Image = layers[i]
		out.blend_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()),
				Vector2i(0, SCALE + offsets[i]))
	return out

func _on_ground(image: Image) -> Image:
	var out := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	out.fill(GROUND)
	out.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i.ZERO)
	return out

## The largest channel difference between two pictures over the same ground, 0..255, and how
## many pixels differ by more than an antialiasing step.
func _difference(a: Image, b: Image) -> Vector2i:
	var ga := _on_ground(a)
	var gb := _on_ground(b)
	var worst := 0
	var count := 0
	for y in ga.get_height():
		for x in ga.get_width():
			var p := ga.get_pixel(x, y)
			var q := gb.get_pixel(x, y)
			var d := roundi(255.0 * maxf(maxf(absf(p.r - q.r), absf(p.g - q.g)), absf(p.b - q.b)))
			worst = maxi(worst, d)
			if d > 8:
				count += 1
	return Vector2i(worst, count)

func _crowd_row(before: String, view: String) -> bool:
	var images := {}
	for scale in [1.0, float(SCALE)]:
		var body := _render("res://art/crowd/car_%s_body.svg" % view, scale)
		var trim := _render("res://art/crowd/car_%s_trim.svg" % view, scale)
		var wheels := _render("res://art/crowd/car_%s_wheels.svg" % view, scale)
		var old_trim := _render(before.path_join("crowd/car_%s_trim.svg" % view), scale)
		if body == null or trim == null or wheels == null or old_trim == null:
			return false
		var paint := _tinted(body, PAINT)
		var size := body.get_size()
		var lift := -roundi(scale)
		images[scale] = [
			_stack(size, [paint, old_trim], [0, 0]),
			_stack(size, [paint, trim], [0, 0]),
			_stack(size, [wheels], [0]),
			_stack(size, [paint, trim, wheels], [0, 0, 0]),
			_stack(size, [paint, trim, wheels], [lift, lift, 0]),
		]
	var d := _difference(images[1.0][0], images[1.0][3])
	print("car_%s: at rest differs from before by at most %d/255 on %d px" % [view, d.x, d.y])
	_rows.append(images[float(SCALE)])
	return true

func _event_row(before: String, name: String) -> bool:
	var images := {}
	for scale in [1.0, float(SCALE)]:
		var body := _render("res://art/events/%s.svg" % name, scale)
		var wheels := _render("res://art/events/%s_wheels.svg" % name, scale)
		var old := _render(before.path_join("events/%s.svg" % name), scale)
		if body == null or wheels == null or old == null:
			return false
		var size := body.get_size()
		var lift := -roundi(scale)
		var behind := name in BEHIND
		var rest: Image
		var lifted: Image
		if behind:
			rest = _stack(size, [wheels, body], [0, 0])
			lifted = _stack(size, [wheels, body], [0, lift])
		else:
			rest = _stack(size, [body, wheels], [0, 0])
			lifted = _stack(size, [body, wheels], [lift, 0])
		images[scale] = [_stack(size, [old], [0]), _stack(size, [body], [0]),
				_stack(size, [wheels], [0]), rest, lifted]
	var d := _difference(images[1.0][0], images[1.0][3])
	print("%s: at rest differs from before by at most %d/255 on %d px" % [name, d.x, d.y])
	_rows.append(images[float(SCALE)])
	return true

func _sheet() -> Image:
	var cell := Vector2i.ZERO
	for row: Array in _rows:
		for image: Image in row:
			cell = Vector2i(maxi(cell.x, image.get_width()), maxi(cell.y, image.get_height()))
	cell += Vector2i.ONE * PAD * 2
	var sheet := Image.create(cell.x * 5, cell.y * _rows.size(), false, Image.FORMAT_RGBA8)
	sheet.fill(GROUND.darkened(0.08))
	for r in _rows.size():
		var row: Array = _rows[r]
		for c in row.size():
			var image: Image = row[c]
			var origin := Vector2i(c * cell.x, r * cell.y)
			var panel := Image.create(cell.x - 2, cell.y - 2, false, Image.FORMAT_RGBA8)
			panel.fill(GROUND)
			sheet.blit_rect(panel, Rect2i(Vector2i.ZERO, panel.get_size()), origin + Vector2i.ONE)
			# Bottom-centred in its cell, the way `Sprites.draw_standing()` registers it.
			var at := origin + Vector2i((cell.x - image.get_width()) / 2,
					cell.y - PAD - image.get_height())
			sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), at)
	return sheet
