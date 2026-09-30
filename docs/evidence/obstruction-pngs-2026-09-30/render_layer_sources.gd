extends SceneTree
## Builds the two fixed-order source sheets used to redraw the water-main painter spans.

const OUTPUT := "res://docs/evidence/obstruction-pngs-2026-09-30/source-renders"
const CELL := Vector2i(250, 220)
const HORIZONTAL: Array[String] = [
	"burst_water_main_static_0", "burst_water_main_motion_1",
	"burst_water_main_motion_1_b", "burst_water_main_static_2",
	"burst_water_main_motion_3", "burst_water_main_motion_3_b",
	"burst_water_main_static_4", "burst_water_main_motion_5",
	"burst_water_main_motion_5_b", "burst_water_main_static_6",
]
const VERTICAL: Array[String] = [
	"burst_water_main_vertical_static_0", "burst_water_main_vertical_motion_1",
	"burst_water_main_vertical_motion_1_b", "burst_water_main_vertical_static_2",
	"burst_water_main_vertical_motion_3", "burst_water_main_vertical_motion_3_b",
	"burst_water_main_vertical_static_4", "burst_water_main_vertical_motion_5",
	"burst_water_main_vertical_motion_5_b", "burst_water_main_vertical_static_6",
]


func _initialize() -> void:
	var output := ProjectSettings.globalize_path(OUTPUT)
	var error := DirAccess.make_dir_recursive_absolute(output)
	if error != OK:
		push_error("cannot create layer-source directory: error %d" % error)
		quit(1)
		return
	var layer_output := output.path_join("water-layers-native")
	error = DirAccess.make_dir_recursive_absolute(layer_output)
	if error != OK:
		push_error("cannot create native layer directory: error %d" % error)
		quit(1)
		return
	_write_sheet(HORIZONTAL, output.path_join("water-horizontal-layers-source.png"), layer_output)
	_write_sheet(VERTICAL, output.path_join("water-vertical-layers-source.png"), layer_output)
	quit()


func _write_sheet(names: Array[String], path: String, native_output: String) -> void:
	var sheet := Image.create_empty(CELL.x * 5, CELL.y * 2, false, Image.FORMAT_RGBA8)
	for index: int in names.size():
		var image := Image.new()
		var source := "res://art/events/%s.svg" % names[index]
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(source))
		if error != OK:
			push_error("cannot rasterize %s: error %d" % [source, error])
			quit(1)
			return
		error = image.save_png(native_output.path_join(names[index] + ".png"))
		if error != OK:
			push_error("cannot save native %s: error %d" % [names[index], error])
			quit(1)
			return
		var scale := mini((CELL.x - 20) / image.get_width(), (CELL.y - 20) / image.get_height())
		image.resize(image.get_width() * scale, image.get_height() * scale,
				Image.INTERPOLATE_NEAREST)
		var origin := Vector2i((index % 5) * CELL.x, (index / 5) * CELL.y)
		var target := origin + Vector2i((CELL.x - image.get_width()) / 2,
				(CELL.y - image.get_height()) / 2)
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), target)
	var save_error := sheet.save_png(path)
	if save_error != OK:
		push_error("cannot save %s: error %d" % [path, save_error])
		quit(1)
