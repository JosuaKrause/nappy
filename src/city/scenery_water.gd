class_name SceneryWater
extends Node2D
## The unreachable south water, kept off the static ground TileMap. The shader samples only
## its own baked region; a pausable local clock moves the existing ripples without redraws.

const RIPPLE_SHADER := """
shader_type canvas_item;
uniform vec4 region_uv;
uniform vec2 page_pixel;
uniform float elapsed = 0.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec2 local = (UV - region_uv.xy) / region_uv.zw;
	vec2 drift = vec2(sin(elapsed * 0.7) * sin(local.y * 6.283185) * 0.65,
		sin(elapsed * 0.5) * sin(local.x * 6.283185) * 0.35);
	vec2 sample_uv = region_uv.xy + fract(local + drift / 32.0) * region_uv.zw;
	sample_uv = clamp(sample_uv, region_uv.xy + page_pixel * 0.5,
		region_uv.xy + region_uv.zw - page_pixel * 0.5);
	COLOR = texture(TEXTURE, sample_uv) * tint;
}
"""

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
	var shader := Shader.new()
	shader.code = RIPPLE_SHADER
	_ripples = ShaderMaterial.new()
	_ripples.shader = shader
	var page_size := _texture.atlas.get_size()
	var region := _texture.region
	_ripples.set_shader_parameter("region_uv", Vector4(region.position.x / page_size.x,
			region.position.y / page_size.y, region.size.x / page_size.x, region.size.y / page_size.y))
	_ripples.set_shader_parameter("page_pixel", Vector2.ONE / page_size)
	_ripples.set_shader_parameter("elapsed", elapsed)
	material = _ripples
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if _ripples != null:
		_ripples.set_shader_parameter("elapsed", elapsed)

func _draw() -> void:
	var extent := Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	for tile in cells:
		draw_texture_rect(_texture, Rect2(Vector2(tile) * extent, extent), false)
