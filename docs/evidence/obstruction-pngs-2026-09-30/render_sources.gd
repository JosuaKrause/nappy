extends SceneTree
## Rasterizes the authored obstruction SVGs with Godot's own SVG decoder for generation input.

const OUTPUT := "res://docs/evidence/obstruction-pngs-2026-09-30/source-renders"
const CELL_SIZE := 220
const SOURCES: Array[String] = [
	"art/events/fallen_tree.svg",
	"art/events/fallen_tree_vertical.svg",
	"art/closures/fallen_tree.svg",
	"art/closures/fallen_tree_vertical.svg",
	"art/events/burst_water_main.svg",
	"art/events/burst_water_main_b.svg",
	"art/events/burst_water_main_vertical.svg",
	"art/events/burst_water_main_vertical_b.svg",
]


func _initialize() -> void:
	var absolute_output := ProjectSettings.globalize_path(OUTPUT)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
	if directory_error != OK:
		push_error("cannot create source-render directory: error %d" % directory_error)
		quit(1)
		return
	var rendered: Array[Image] = []
	for source: String in SOURCES:
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string("res://" + source))
		if error != OK:
			push_error("cannot rasterize %s: error %d" % [source, error])
			quit(1)
			return
		var output_name := source.trim_prefix("art/").replace("/", "-").trim_suffix(".svg")
		error = image.save_png(absolute_output.path_join(output_name + ".png"))
		if error != OK:
			push_error("cannot save %s: error %d" % [source, error])
			quit(1)
			return
		rendered.append(image)
	var trees: Array[Image] = [rendered[0], rendered[1], rendered[2], rendered[3]]
	var water: Array[Image] = [rendered[4], rendered[5], rendered[6], rendered[7]]
	_write_family_sheet(trees, absolute_output.path_join("trees-source-sheet.png"))
	_write_family_sheet(water, absolute_output.path_join("water-source-sheet.png"))
	quit()


func _write_family_sheet(images: Array[Image], path: String) -> void:
	var sheet := Image.create_empty(CELL_SIZE * 2, CELL_SIZE * 2, false, Image.FORMAT_RGBA8)
	for index: int in images.size():
		var image := images[index].duplicate()
		var scale := mini((CELL_SIZE - 20) / image.get_width(),
				(CELL_SIZE - 20) / image.get_height())
		image.resize(image.get_width() * scale, image.get_height() * scale,
				Image.INTERPOLATE_NEAREST)
		var cell_origin := Vector2i((index % 2) * CELL_SIZE, (index >> 1) * CELL_SIZE)
		var target := cell_origin + Vector2i((CELL_SIZE - image.get_width()) / 2,
				(CELL_SIZE - image.get_height()) / 2)
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), target)
	var error := sheet.save_png(path)
	if error != OK:
		push_error("cannot save family sheet %s: error %d" % [path, error])
		quit(1)
