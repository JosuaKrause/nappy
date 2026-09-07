extends Node2D
## Bounded art review: a cardinal street composition with authored PNG layers.
## This node has no City, collision, route, or gameplay dependencies by design.

const GROUND := preload("res://assets/illustrated/street/street-ground-v2.png")
const FACADE := preload("res://assets/illustrated/street/apartment-facade-v2.png")
const ROOF := preload("res://assets/illustrated/street/roof-depth-overlay-v2.png")
const PROPS := preload("res://assets/illustrated/street/street-props-v2.png")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_composition()
	var arguments := OS.get_cmdline_user_args()
	var capture_index := arguments.find("--street-capture")
	if capture_index >= 0 and capture_index + 1 < arguments.size():
		var capture_path: String = arguments[capture_index + 1]
		get_tree().create_timer(0.8).timeout.connect(_capture.bind(capture_path))

func _build_composition() -> void:
	var ground := _sprite("Ground", GROUND, Vector2(640, 432), 0, Vector2(1.05, 0.72))
	ground.region_enabled = true
	ground.region_rect = Rect2(0, 0, 1254, 1254)
	# The facade is intentionally lifted and shortened toward north: a camera-specific depth cheat
	# keeps the cross street legible while preserving the continuous apartment-block silhouette.
	_sprite("ApartmentFacade", FACADE, Vector2(640, 175), 10, Vector2(0.72, 0.72))
	var roof := _sprite("RoofDepth", ROOF, Vector2(640, 265), 20, Vector2(0.57, 0.42))
	var roof_material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded; uniform float reveal = 0.78; void fragment(){ vec4 c=texture(TEXTURE,UV); float grid=mod(floor(UV.x*96.0)+floor(UV.y*64.0),2.0); if(UV.y>reveal && grid<1.0){ c.a*=0.18; } COLOR=c; }"
	roof_material.shader = shader
	roof.material = roof_material
	var props := _sprite("StreetProps", PROPS, Vector2(640, 535), 30, Vector2(0.33, 0.27))
	props.modulate = Color(1.0, 0.92, 0.78, 1.0)

func _sprite(label: String, texture: Texture2D, position: Vector2, layer: int, scale: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = label
	sprite.texture = texture
	sprite.position = position
	sprite.z_index = layer
	sprite.scale = scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("street review capture failed: %s" % error)
	get_tree().quit()
