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
# The reference is a crop with a 5px margin, not a change to the tile canvases or module stride.
const ASSEMBLY_SIZE := Vector2i(74, 121)
const START_OFFSET := Vector2i(5, 5)

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
	var enlarged_sources: Array[Image] = []
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
		enlarged_sources.append(enlarged)
	for direction: int in 2:
		var name: String = ["east", "west"][direction]
		var native := _assembly_image(sources, direction * 3, 1)
		var enlarged := _assembly_image(enlarged_sources, direction * 3, 3)
		if native.save_png(output_dir.path_join("assembly-%s-native.png" % name)) != OK:
			quit(2)
			return
		if enlarged.save_png(output_dir.path_join("assembly-%s-3x.png" % name)) != OK:
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
	var east := _assembly_image(sources, 0, 1)
	var west := _assembly_image(sources, 3, 1)
	review.blend_rect(east, Rect2i(Vector2i.ZERO, ASSEMBLY_SIZE), east_origin + Vector2i(59, 19))
	review.blend_rect(west, Rect2i(Vector2i.ZERO, ASSEMBLY_SIZE), west_origin + Vector2i(123, 19))
	return review

## Keeps the reference's crop margin while assembling exactly two three-tile modules.
func _assembly_image(sources: Array[Image], index: int, scale: int) -> Image:
	var assembly := Image.create(ASSEMBLY_SIZE.x * scale, ASSEMBLY_SIZE.y * scale,
		false, Image.FORMAT_RGBA8)
	assembly.fill(Color.TRANSPARENT)
	for module: int in 2:
		var column: int = module if index == 0 else 1 - module
		var origin := (START_OFFSET + Vector2i(column * 32, module * 32)) * scale
		_blit_module(assembly, sources, origin, index, scale)
	return assembly

func _blit_module(canvas: Image, sources: Array[Image], origin: Vector2i,
		index: int, scale: int) -> void:
	for role: int in 3:
		var tile: Image = sources[index + role]
		canvas.blend_rect(tile, Rect2i(Vector2i.ZERO, tile.get_size()),
			origin + Vector2i(0, role * 32 * scale))
