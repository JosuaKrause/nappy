extends RefCounted
## Evidence rig for M108's "every living thing that moves has a stride" item, event-family half:
## renders every family's five authored views with frame a beside frame b, straight from the SVG
## source files under `assets/events/` rather than through `EventInstance`'s own texture
## dictionaries -- run once *before* those dictionaries exist, the way the walker's own precedent
## (`tests/probes/m108_walker_stride_sheet.gd`) was reviewed before its runtime binding landed.
## Not a suite: it saves PNGs and prints a manifest rather than asserting, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m108_event_strides_sheet.gd
##
## Output goes to `docs/evidence/m108-event-strides-2026-09-12/`. Look for: no drift above the
## waist in the humanoid families' cardinal/side columns, legs or pedals visibly crossed/shifted
## in every b column, and the busker's hand and the sitters' lean reading as a clear difference at
## native scale.

const OUT_DIR := "res://docs/evidence/m108-event-strides-2026-09-12"
const CELL := 68
const GROUND := Color("c9c3b3")

const VIEWS: Array[String] = ["front", "back", "side", "front_diagonal", "back_diagonal"]

## Families whose "side" view is its own named file (`<family>_side.svg`), matching the humanoid
## and café/busker convention already live in `EventInstance`.
const NAMED_SIDE_FAMILIES: Array[String] = [
	"person", "yeller", "robber_lunging", "protester", "leaf_blower", "van_victim",
	"chatting_mother_walking", "cafe_sitter", "busker",
]
## Families whose side view is the older unsuffixed source (`<family>.svg`), matching every
## animal/rider family `docs/GRAPHICS.md` already documents that way.
const UNSUFFIXED_SIDE_FAMILIES: Array[String] = [
	"dog", "cat_running", "charging_dog", "cyclist", "mouse",
]

func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var rows := []
	for family in NAMED_SIDE_FAMILIES + UNSUFFIXED_SIDE_FAMILIES:
		for view in VIEWS:
			var a_path := _source_path(family, view, false)
			var b_path := _source_path(family, view, true)
			if not FileAccess.file_exists(ProjectSettings.globalize_path(a_path)) \
					or not FileAccess.file_exists(ProjectSettings.globalize_path(b_path)):
				continue
			rows.append(_row("%s %s" % [family, view], a_path, b_path))
	_render_sheet("event-strides-native.png", "event-strides-3x.png", rows)
	for row in rows:
		print("m108_event_strides_sheet: row %s = [frame a, frame b]" % row["label"])
	print("m108_event_strides_sheet: 2 PNGs written under %s, %d rows" % [OUT_DIR, rows.size()])
	t.check(true, "m108_event_strides_sheet probe ran")

# ------------------------------------------------------------------- selection ---

func _source_path(family: String, view: String, is_b: bool) -> String:
	var suffix := "_b" if is_b else ""
	if view == "side" and family in UNSUFFIXED_SIDE_FAMILIES:
		return "res://assets/events/%s%s.svg" % [family, suffix]
	return "res://assets/events/%s_%s%s.svg" % [family, view, suffix]

func _row(label: String, a_path: String, b_path: String) -> Dictionary:
	return {"label": label, "a": a_path, "b": b_path}

# ------------------------------------------------------------------- rendering ---

func _cell_image(path: String, scale: float) -> Image:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
	return image

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
		var row: Dictionary = rows[r]
		var paths := [row["a"], row["b"]]
		for c in range(2):
			var cell_image: Image = _cell_image(paths[c], scale)
			var at := Vector2i(
					c * cell + int((cell - cell_image.get_width()) / 2.0),
					r * cell + int((cell - cell_image.get_height()) / 2.0))
			sheet.blend_rect(cell_image, Rect2i(Vector2i.ZERO, cell_image.get_size()), at)
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	sheet.save_png(path)
