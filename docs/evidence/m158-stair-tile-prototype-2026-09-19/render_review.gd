extends SceneTree
## Renders the unbound SVG sources and their two-module directional review on the live shaft art.

const SOURCE_NAMES: PackedStringArray = [
	"upper_e", "lower_e", "continue_e", "upper_w", "lower_w", "continue_w",
]
const SOURCE_PATHS: PackedStringArray = [
	"res://assets/interior/m158_stair_side_upper_e.svg",
	"res://assets/interior/m158_stair_side_lower_e.svg",
	"res://assets/interior/m158_stair_side_continue_e.svg",
	"res://assets/interior/m158_stair_side_upper_w.svg",
	"res://assets/interior/m158_stair_side_lower_w.svg",
	"res://assets/interior/m158_stair_side_continue_w.svg",
]
const BACKDROP := "res://assets/interior/stairwell_segment_backdrop.svg"
const FLOOR := "res://assets/interior/stairwell_floor.svg"
const LABELS := "res://docs/evidence/m158-stair-tile-prototype-2026-09-19/review_labels.svg"

func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size() == 1 and arguments[0] in ["--help", "-h"]:
		print("usage: render_review.gd -- --output-dir DIRECTORY")
		quit()
		return
	if arguments.size() != 2 or arguments[0] != "--output-dir":
		printerr("usage: render_review.gd -- --output-dir DIRECTORY")
		quit(2)
		return
	var output_dir: String = arguments[1]
	if DirAccess.dir_exists_absolute(output_dir) or FileAccess.file_exists(output_dir):
		printerr("refusing existing output: %s" % output_dir)
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		printerr("could not create output: %s" % output_dir)
		quit(2)
		return
	var sources: Array[Image] = []
	for i: int in SOURCE_PATHS.size():
		var source := _load_svg(SOURCE_PATHS[i], 1.0)
		if source == null:
			quit(2)
			return
		sources.append(source)
		if source.save_png(output_dir.path_join("%s-native.png" % SOURCE_NAMES[i])) != OK:
			quit(2)
			return
		var enlarged := _load_svg(SOURCE_PATHS[i], 3.0)
		if enlarged == null or enlarged.save_png(output_dir.path_join("%s-3x.png" % SOURCE_NAMES[i])) != OK:
			quit(2)
			return
	var review := _review_image(sources)
	if review.save_png(output_dir.path_join("stair-side-review.png")) != OK:
		quit(2)
		return
	quit()

func _load_svg(path: String, scale: float) -> Image:
	var picture := Image.new()
	var result := picture.load_svg_from_string(FileAccess.get_file_as_string(path), scale)
	if result != OK:
		printerr("SVG render failed: %s" % path)
		return null
	return picture

func _review_image(sources: Array[Image]) -> Image:
	var review := Image.create(680, 356, false, Image.FORMAT_RGBA8)
	review.fill(Color("20242a"))
	var backdrop := _load_svg(BACKDROP, 1.0)
	var floor := _load_svg(FLOOR, 1.0)
	if backdrop == null or floor == null:
		return review
	var east_origin := Vector2i(28, 64)
	var west_origin := Vector2i(364, 64)
	var labels := _load_svg(LABELS, 1.0)
	if labels == null:
		return review
	review.blend_rect(labels, Rect2i(Vector2i.ZERO, labels.get_size()), Vector2i.ZERO)
	review.blit_rect(backdrop, Rect2i(Vector2i.ZERO, backdrop.get_size()), east_origin)
	review.blit_rect(backdrop, Rect2i(Vector2i.ZERO, backdrop.get_size()), west_origin)
	for panel_x: int in [east_origin.x, west_origin.x]:
		for x: int in range(0, 288, 32):
			review.blit_rect(floor, Rect2i(Vector2i.ZERO, floor.get_size()), Vector2i(panel_x + x, 288))
	_blit_module(review, sources, east_origin + Vector2i(64, 24), 0)
	_blit_module(review, sources, east_origin + Vector2i(96, 56), 0)
	_blit_module(review, sources, west_origin + Vector2i(160, 24), 3)
	_blit_module(review, sources, west_origin + Vector2i(128, 56), 3)
	return review

func _blit_module(canvas: Image, sources: Array[Image], origin: Vector2i, index: int) -> void:
	for role: int in 3:
		var tile: Image = sources[index + role]
		canvas.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()), origin + Vector2i(0, role * 32))
