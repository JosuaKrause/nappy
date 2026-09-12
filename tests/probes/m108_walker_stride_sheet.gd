extends RefCounted
## Evidence rig for M108's "walkers first" stride item: renders each of the walker's five
## authored views with gait frame a beside gait frame b, body tinted and trim above — the same
## composition `CrowdAgent._draw_body()`'s walker branch draws, reproduced here from the SVG
## source text rather than a live scene so the sheet can be judged without booting a day. Not a
## suite: it saves PNGs and prints a manifest rather than asserting, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m108_walker_stride_sheet.gd
##
## Output goes to `docs/evidence/m108-walker-stride-2026-09-11/`. Look for: no drift in the coat,
## head or hands between the two columns of a row, and the legs visibly crossed in the b column.

const OUT_DIR := "res://docs/evidence/m108-walker-stride-2026-09-11"
const CELL := 48
const GROUND := Color("c9c3b3")
## `Palette.COATS[5]`, the same sage sample `docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`
## used for its own composed sheets.
const TINT := Color("4f5b52")

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]

func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var rows := []
	for view in VIEWS:
		rows.append(_row(view, [
			_entry(CrowdAgent.WALKER_BODY_BY_VIEW[view], CrowdAgent.WALKER_TRIM_BY_VIEW[view]),
			_entry(CrowdAgent.WALKER_BODY_BY_VIEW_B[view], CrowdAgent.WALKER_TRIM_BY_VIEW_B[view]),
		]))
	_render_sheet("walker-stride-native.png", "walker-stride-3x.png", rows)
	for row in rows:
		print("m108_walker_stride_sheet: row %s = [frame a, frame b]" % row["label"])
	print("m108_walker_stride_sheet: 2 PNGs written under %s" % OUT_DIR)
	t.check(true, "m108_walker_stride_sheet probe ran")

# ------------------------------------------------------------------- selection ---

func _entry(body: Texture2D, trim: Texture2D) -> Dictionary:
	return {"body": body, "trim": trim}

func _row(label: String, entries: Array) -> Dictionary:
	return {"label": label, "entries": entries}

# ------------------------------------------------------------------- rendering ---

## Rasterises `entry`'s own body and trim from their SVG source text at `scale`, tinting the body
## the way `CrowdAgent._colour()`'s own comment describes it ("authored near-white and
## multiplied") and compositing the untinted trim above it — `Sprites.draw_standing()`'s own layer
## order, reproduced on stills instead of a canvas transform.
func _cell_image(entry: Dictionary, scale: float) -> Image:
	var body := Image.new()
	body.load_svg_from_string(FileAccess.get_file_as_string(entry["body"].resource_path), scale)
	for y in body.get_height():
		for x in body.get_width():
			var c := body.get_pixel(x, y)
			body.set_pixel(x, y, Color(c.r * TINT.r, c.g * TINT.g, c.b * TINT.b, c.a))
	var trim := Image.new()
	trim.load_svg_from_string(FileAccess.get_file_as_string(entry["trim"].resource_path), scale)
	body.blend_rect(trim, Rect2i(Vector2i.ZERO, trim.get_size()), Vector2i.ZERO)
	return body

func _render_sheet(native_name: String, wide_name: String, rows: Array) -> void:
	_render_scale(native_name, rows, 1.0)
	_render_scale(wide_name, rows, 3.0)

func _render_scale(filename: String, rows: Array, scale: float) -> void:
	var cell := int(round(CELL * scale))
	var width := cell * 2
	var height := cell * rows.size()
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(GROUND)
	for r in rows.size():
		var entries: Array = rows[r]["entries"]
		for c in range(2):
			var cell_image: Image = _cell_image(entries[c], scale)
			var at := Vector2i(
					c * cell + int((cell - cell_image.get_width()) / 2.0),
					r * cell + int((cell - cell_image.get_height()) / 2.0))
			sheet.blend_rect(cell_image, Rect2i(Vector2i.ZERO, cell_image.get_size()), at)
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	sheet.save_png(path)
