class_name SouthWaterTile
extends SubViewport
## The south water's one live tile (amber-puffin): a seamless square of the drifting Voronoi
## lines (`assets/shaders/south_water.gdshader`), which every south-water surface
## (`SceneryWater`) repeats over its cells. Only the tile runs the shader, so the water costs a
## frame one textured draw per surface plus the shader over the tile's 384×384 texels, whatever
## the screen's size; the shader run over every water pixel instead costs about twenty-five times
## a flat fill on the desktop, which a phone's renderer, already bound by the pixels it fills,
## cannot be trusted to pay (the record amber-puffin).
##
## The tile is drawn a texel a world pixel, so its pattern repeats every `CELL_SIZE * CELLS`
## world pixels and its outlines are magnified on screen as the ground is. It is drawn again on every frame while
## `keep_drawing()` is on, and not at all while it is off; its clock is the ground's
## (`set_clock()`), so it holds still while gameplay is paused.

const LINES_SHADER: Shader = preload("res://assets/shaders/south_water.gdshader")
## World pixels between neighbouring centroids, on average: a cell and a half of the ground.
const CELL_SIZE := 48.0
## Cells a side. The shader's centroids repeat every this many, so the square wraps without a seam.
const CELLS := 8

var _lines: ShaderMaterial

func _init() -> void:
	name = "SouthWaterTile"
	gui_disable_input = true
	render_target_update_mode = SubViewport.UPDATE_DISABLED
	size = Vector2i(_side(), _side())
	_lines = lines_material()
	var canvas := ColorRect.new()
	canvas.name = "Lines"
	canvas.size = Vector2(_side(), _side())
	canvas.material = _lines
	add_child(canvas)

## The material the tile's square is drawn with. The boot's warmup draws through one too, so the
## renderer compiles the shader before the shore is first seen.
static func lines_material() -> ShaderMaterial:
	var lines := ShaderMaterial.new()
	lines.shader = LINES_SHADER
	lines.set_shader_parameter("cell_size", CELL_SIZE)
	lines.set_shader_parameter("wrap_cells", CELLS)
	return lines

## The tile's side, in texels and in the world pixels it covers.
static func _side() -> int:
	return roundi(CELL_SIZE * CELLS)

## Where in the tile a ground cell's picture is: the square the cell covers in the world, taken
## modulo the tile, so neighbouring cells, and the cells of neighbouring chunks, draw neighbouring
## texels. A cell never straddles the tile's edge, since the side is a whole number of ground cells.
func region_for(cell: Vector2i) -> Rect2:
	var corner := cell * Tuning.TILE_SIZE
	return Rect2(Vector2(posmod(corner.x, _side()), posmod(corner.y, _side())),
			Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE))

## Sets the water's clock, in seconds, which moves its outlines.
func set_clock(seconds: float) -> void:
	_lines.set_shader_parameter("elapsed", seconds)

## Draws the tile again on every frame while `on`, and not at all while not: the ground keeps it on
## while a water surface stands.
func keep_drawing(on: bool) -> void:
	render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
