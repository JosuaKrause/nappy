extends RefCounted
## Evidence rig for M108's "bind vehicle views" item: renders every bound event-vehicle and the
## police car at all eight `EightDirection` sectors from the actual runtime selection —
## `EventInstance.setup()`, `_select_view()`, `EIGHT_VIEW_BY_SECTOR` and each family's own
## `_BY_VIEW` table, the same calls `_draw_eight_view()` makes, `side_faces_west` included — rather
## than a hand-assembled list of source files. Copied from `tests/probes/m108_event_people_sheet.gd`
## rather than shared with it: that rig's `_heading_row()` has no `side_faces_west` parameter, and
## every family here needs one answer or the other. Not a suite: it saves PNGs and prints a
## manifest rather than asserting, so it lives under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/m108_event_vehicles_sheet.gd
##
## Output goes to `docs/evidence/m108-event-vehicles-2026-09-11/`. Each sheet is one PNG with a
## native-scale row stacked over a 3x row, both re-rendered from the selected SVG's own source text
## through `Image.load_svg_from_string()` rather than a nearest-neighbour magnification of a small
## raster.

const OUT_DIR := "res://docs/evidence/m108-event-vehicles-2026-09-11"
const CELL := 68
const GROUND := Color("c9c3b3")

func run(t) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_render_sheet("vehicles-native.png", "vehicles-3x.png", [
		_row("delivery van (west-authored side)",
				_heading_row("delivery_van", EventInstance.DELIVERY_VAN_BY_VIEW, true)),
		_row("fire engine (west-authored side)",
				_heading_row("fire_truck", EventInstance.FIRE_ENGINE_BY_VIEW, true)),
		_row("ice-cream van (east-authored side)",
				_heading_row("ice_cream_van", EventInstance.ICE_CREAM_VAN_BY_VIEW, false)),
		_row("reversing lorry (east-authored side)",
				_heading_row("reversing_lorry", EventInstance.LORRY_BY_VIEW, false)),
	])

	_render_sheet("vehicles-security-native.png", "vehicles-security-3x.png", [
		_row("unmarked van (west-authored side)",
				_heading_row("abduction", EventInstance.UNMARKED_VAN_BY_VIEW, true)),
		_row("army truck (west-authored side)",
				_heading_row("military_convoy", EventInstance.ARMY_TRUCK_BY_VIEW, true)),
		_row("riot van (west-authored side)",
				_heading_row("night_raid", EventInstance.RIOT_VAN_BY_VIEW, true)),
	])

	_render_sheet("police-car-native.png", "police-car-3x.png", [
		_row("police car (east-authored side)",
				_heading_row("police_patrol", EventInstance.POLICE_CAR_BY_VIEW, false)),
	])

	print("m108_event_vehicles_sheet: 6 PNGs written under %s" % OUT_DIR)
	t.check(true, "m108_event_vehicles_sheet probe ran")

# ------------------------------------------------------------------- selection ---

func _sector_heading(sector: int) -> Vector2:
	return Vector2.from_angle(deg_to_rad(sector * 45.0))

func _entry(texture: Texture2D, mirror: bool) -> Dictionary:
	return {"texture": texture, "mirror": mirror}

func _row(label: String, entries: Array) -> Dictionary:
	return {"label": label, "entries": entries}

## The exact runtime selection `EventInstance._draw_eight_view()` makes, `side_faces_west` included
## — see that function's own doc comment. `setup()`'s own `face` argument is the identical
## assignment `_draw_body()` reads (`_heading = face` for a fresh instance), so sitting a fresh
## instance at each of the eight headings and reading `_view_sector` back is the same selection the
## real draw path runs, whatever heading the row would actually reach in play — the probe's job is
## to show the picture at every sector, not to reproduce which ones are reachable.
func _heading_row(def_id: String, by_view: Dictionary, side_faces_west: bool) -> Array:
	var row := []
	for sector in range(8):
		var instance := EventInstance.new()
		instance.setup(EventCatalogue.by_id(def_id), Vector2.ZERO, PackedVector2Array(),
				_sector_heading(sector))
		var view: String = EventInstance.EIGHT_VIEW_BY_SECTOR[instance._view_sector]
		var mirror := EightDirection.is_mirrored(instance._view_sector)
		if view == "side" and side_faces_west:
			mirror = not mirror
		row.append(_entry(by_view[view], mirror))
		instance.free()
	return row

# ------------------------------------------------------------------- rendering ---

## Rasterises `entry`'s own texture from its SVG source text at `scale`, mirrored if the sector
## says so — `Image.flip_x()`, the same horizontal mirror `Sprites.draw_standing()` gives every
## mirrored sector, applied to a still image instead of a canvas transform.
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
