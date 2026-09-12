extends RefCounted
## Evidence rig for M108's "bind live event people, animals and riders" item: renders every bound
## family at all eight `EightDirection` sectors from the actual runtime selection —
## `EventInstance.setup()`, `_select_view()`, `EIGHT_VIEW_BY_SECTOR` and each family's own
## `_BY_VIEW` table, the same calls `_draw_eight_view()` and the other `_draw_*` functions make —
## rather than a hand-assembled list of source files. Not a suite: it saves PNGs and prints a
## manifest rather than asserting, so it lives under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/m108_event_people_sheet.gd
##
## Output goes to `docs/evidence/m108-event-people-2026-09-11/`. Each sheet is one PNG with a
## native-scale row stacked over a 3x row, both re-rendered from the selected SVG's own source text
## through `Image.load_svg_from_string()` — the same rasteriser
## `docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`'s review sheets used — rather than a
## nearest-neighbour magnification of a small raster.

const OUT_DIR := "res://docs/evidence/m108-event-people-2026-09-11"
const CELL := 68
const GROUND := Color("c9c3b3")

func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_render_sheet("people-native.png", "people-3x.png", [
		_row("dog-walker person", _heading_row("dog_walker", EventInstance.PERSON_BY_VIEW)),
		_row("dog-walker's dog", _heading_row("dog_walker", EventInstance.DOG_BY_VIEW)),
		_row("yeller", _heading_row("homeless_yeller", EventInstance.YELLER_BY_VIEW)),
		_row("busker", _heading_row("busker", EventInstance.BUSKER_BY_VIEW)),
		_row("poster crew", _heading_row("poster_crew", EventInstance.POSTER_CREW_BY_VIEW)),
		_row("cafe sitter", _heading_row("cafe_tables", EventInstance.CAFE_SITTER_BY_VIEW)),
		_row("van victim", _heading_row("abduction", EventInstance.VAN_VICTIM_BY_VIEW)),
		_row("protester (plain)", _heading_row("protest", EventInstance.PROTESTER_BY_VIEW)),
		_row("leaf blower", _heading_row("leaf_blower", EventInstance.LEAF_BLOWER_BY_VIEW)),
	])

	_render_sheet("people-states-native.png", "people-states-3x.png", [
		_row("chatting mother, walking",
				_heading_row("chatting_mother", EventInstance.CHATTING_MOTHER_WALKING_BY_VIEW)),
		_row("chatting mother, talking",
				_heading_row("chatting_mother", EventInstance.CHATTING_MOTHER_TALKING_BY_VIEW)),
		_row("robber, waiting (faces her)", _robber_waiting_row()),
		_row("robber, lunging (faces her lunge)",
				_heading_row("alley_robbery", EventInstance.ROBBER_LUNGING_BY_VIEW)),
	])

	_render_sheet("animals-rider-native.png", "animals-rider-3x.png", [
		_row("cat, crouched", _heading_row("cat_dash", EventInstance.CAT_CROUCHED_BY_VIEW)),
		_row("cat, running", _heading_row("cat_dash", EventInstance.CAT_RUNNING_BY_VIEW)),
		_row("loose dog", _heading_row("loose_dog", EventInstance.DOG_BY_VIEW)),
		_row("charging dog", _heading_row("charging_dog", EventInstance.CHARGING_DOG_BY_VIEW)),
		_row("cyclist", _heading_row("cyclist", EventInstance.CYCLIST_BY_VIEW)),
	])

	_render_sheet("birds-native.png", "birds-3x.png", [
		_row("pigeon, wings up", _bird_row(EventInstance.PIGEON_BY_VIEW)),
		_row("pigeon, wings down", _bird_row(EventInstance.PIGEON_DOWN_BY_VIEW)),
	])

	print("m108_event_people_sheet: 8 PNGs written under %s" % OUT_DIR)
	t.check(true, "m108_event_people_sheet probe ran")

# ------------------------------------------------------------------- selection ---

func _sector_heading(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

func _entry(texture: Texture2D, mirror: bool) -> Dictionary:
	return {"texture": texture, "mirror": mirror}

func _row(label: String, entries: Array) -> Dictionary:
	return {"label": label, "entries": entries}

## The exact runtime selection for a family whose heading source is `_heading`: every stationary
## family reads its own fixed site facing this way, and every mobile one has `_heading` set the
## same way by `_advance_along_path()`/`_chase()` during play — `setup()`'s own `face` argument is
## the identical assignment (`_heading = face`), so sitting a fresh instance at each of the eight
## headings and reading `_view_sector` back is the same selection the real draw path runs.
func _heading_row(def_id: String, by_view: Dictionary) -> Array:
	var row := []
	for sector in range(8):
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(def_id), Vector2.ZERO, PackedVector2Array(),
				_sector_heading(sector))
		var view: String = EventInstance.EIGHT_VIEW_BY_SECTOR[instance._view_sector]
		row.append(_entry(by_view[view], EightDirection.is_mirrored(instance._view_sector)))
		instance.free()
	return row

## The waiting robber's own target-facing: `player_at` set at each of the eight bearings, read back
## through `_robber_waiting_heading()` exactly as `_draw_robber()` does while `is_waiting()`.
func _robber_waiting_row() -> Array:
	var row := []
	var def := EventCatalogue.by_id("alley_robbery")
	for sector in range(8):
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		instance.player_at = _sector_heading(sector) * (def.pursues_within + 40.0)
		var view := instance._select_view(instance._robber_waiting_heading())
		row.append(_entry(EventInstance.ROBBER_WAITING_BY_VIEW[view],
				EightDirection.is_mirrored(instance._view_sector)))
		instance.free()
	return row

## A flock's per-bird selection lives in `EventInstance._draw_birds()` itself
## (`bird.view_sector = EightDirection.update(bird.view_sector, bird.heading)`), which needs a
## canvas to reach — so this calls the same two functions directly on a synthetic heading, which is
## exactly what that line reduces to for a heading already sitting on a sector's own centre.
func _bird_row(by_view: Dictionary) -> Array:
	var row := []
	for sector in range(8):
		var s := EightDirection.nearest(_sector_heading(sector))
		var view: String = EventInstance.EIGHT_VIEW_BY_SECTOR[s]
		row.append(_entry(by_view[view], EightDirection.is_mirrored(s)))
	return row

# ------------------------------------------------------------------- rendering ---

## Rasterises `entry`'s own texture from its SVG source text at `scale`, mirrored if the sector
## says so — `Image.flip_x()`, the same horizontal mirror `Sprites.draw_standing()` gives every
## west-facing sector, applied to a still image instead of a canvas transform.
func _cell_image(entry: Dictionary, scale: float) -> Image:
	var texture: Texture2D = entry["texture"]
	var text := FileAccess.get_file_as_string(texture.resource_path)
	var image := Image.new()
	image.load_svg_from_string(text, scale)
	if entry["mirror"]:
		image.flip_x()
	return image

func _render_sheet(native_name: String, wide_name: String, rows: Array) -> void:
	_render_scale(native_name, rows, 1.0)
	_render_scale(wide_name, rows, 3.0)

func _render_scale(filename: String, rows: Array, scale: float) -> void:
	var cell := int(round(CELL * scale))
	var width := cell * 8
	var height := cell * rows.size()
	var sheet := Image.create(width, height, false, Image.FORMAT_RGBA8)
	sheet.fill(GROUND)
	for r in rows.size():
		var entries: Array = rows[r]["entries"]
		for c in range(8):
			var cell_image: Image = _cell_image(entries[c], scale)
			var at := Vector2i(
					c * cell + int((cell - cell_image.get_width()) / 2.0),
					r * cell + int((cell - cell_image.get_height()) / 2.0))
			sheet.blend_rect(cell_image, Rect2i(Vector2i.ZERO, cell_image.get_size()), at)
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(filename))
	sheet.save_png(path)
