class_name SceneryWater
extends Node2D
## The unreachable south water, kept off the static ground TileMap. The shader samples only
## its own baked region; a pausable local clock moves the existing ripples without redraws.

## One shader resource for the boot probe and every water surface. Materials stay per surface so
## each city or fixture owns its clock without recompiling the same program on tree reentry.
const RIPPLE_SHADER: Shader = preload("res://assets/shaders/scenery_water.gdshader")

var cells: Array[Vector2i] = []
var elapsed := 0.0
var _texture: AtlasTexture
var _ripples: ShaderMaterial

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"ground")
	if not cells.is_empty():
		configure(cells)

func _exit_tree() -> void:
	RenderingServer.canvas_item_clear(get_canvas_item())
	_texture = null
	material = null
	_ripples = null
	AtlasLibrary.release(&"ground")

func configure(water_cells: Array[Vector2i]) -> void:
	if cells != water_cells:
		cells.assign(water_cells)
	_texture = AtlasLibrary.region(&"tiles/water") as AtlasTexture
	_ripples = material_for(_texture, elapsed)
	material = _ripples
	queue_redraw()

## Builds one surface's uniforms around the shared runtime shader. The boot warmup calls this same
## path so the material it draws has the atlas page and region values real shoreline draws use.
static func material_for(texture: AtlasTexture, at_elapsed: float = 0.0) -> ShaderMaterial:
	var ripples := ShaderMaterial.new()
	ripples.shader = RIPPLE_SHADER
	var page_size := texture.atlas.get_size()
	var region := texture.region
	ripples.set_shader_parameter("region_uv", Vector4(region.position.x / page_size.x,
			region.position.y / page_size.y, region.size.x / page_size.x, region.size.y / page_size.y))
	ripples.set_shader_parameter("page_pixel", Vector2.ONE / page_size)
	ripples.set_shader_parameter("elapsed", at_elapsed)
	return ripples

func _process(delta: float) -> void:
	elapsed += delta
	if _ripples != null:
		_ripples.set_shader_parameter("elapsed", elapsed)

func _draw() -> void:
	var extent := Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	for tile in cells:
		draw_texture_rect(_texture, Rect2(Vector2(tile) * extent, extent), false)
