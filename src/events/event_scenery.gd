class_name EventScenery
extends Node2D
## A wide scene's static vector spans and cropped moving details, in their source painter order.
## The event keeps its simulation clock and cues; only these small moving layers change phase.

var moving_layers: Array[SceneryLayer] = []
var static_layers: Array[SceneryLayer] = []
var _picture: String
var _extent: Vector2
var _anchor: Vector2
var _shadow: String
var _frame_b := false

func _enter_tree() -> void:
	AtlasLibrary.acquire(&"events")

func _ready() -> void:
	_build()

func _exit_tree() -> void:
	for layer in moving_layers:
		layer.free()
	for layer in static_layers:
		layer.free()
	moving_layers.clear()
	static_layers.clear()
	AtlasLibrary.release(&"events")
	request_ready()

func configure(picture: String, extent: Vector2, anchor: Vector2, shadow: String) -> void:
	_picture = picture
	_extent = extent
	_anchor = anchor
	_shadow = shadow

func _build() -> void:
	show_behind_parent = true
	var original := AtlasLibrary.region(_picture)
	var scale_factor := _extent / original.get_size()
	var top_left := _anchor - Vector2(_extent.x * 0.5, _extent.y)
	if not _shadow.is_empty():
		var contact := SceneryLayer.new()
		contact.modulate = Palette.SHADOW
		contact.append(AtlasLibrary.region(_shadow), Rect2(top_left, _extent))
		static_layers.append(contact)
		add_child(contact)
	var stem := _picture.get_file()
	for part: Array in EventSceneryParts.LAYERS[stem]:
		var layer := SceneryLayer.new()
		var region := "events/" + str(part[0])
		var moving: bool = part[5]
		var rect := Rect2(top_left + Vector2(part[1], part[2]) * scale_factor,
				Vector2(part[3], part[4]) * scale_factor)
		layer.append(AtlasLibrary.region(region), rect,
				AtlasLibrary.region(region + "_b") if moving else null)
		if moving:
			moving_layers.append(layer)
		else:
			static_layers.append(layer)
		add_child(layer)
	set_frame(_frame_b)

func set_frame(frame_b: bool) -> void:
	_frame_b = frame_b
	for layer in moving_layers:
		layer.frame_b = frame_b
