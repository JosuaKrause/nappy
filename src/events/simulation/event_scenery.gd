class_name EventScenery
extends Node2D
## A partly animated picture's static vector spans and cropped moving details, in their source
## painter order (`EventSceneryParts`). The event keeps its simulation clock and cues; only these
## small moving layers change phase, so a swap redraws them and nothing else.
## One of these stands behind each slice of a wide scene (`SpreadLook.Slice`), holding the part of
## every span inside its slice's band (`clip`); the first slice's also holds the contact shadow,
## whole, so it goes down before every other part of the scene. A figure whose idle frame moves part
## of it (the busker's strumming arm, a café sitter's lean, a poster crew's brush) stands one on its
## feet, over the shadow its owner draws, mirrored about its feet for a view that faces west.
## Whether it stands behind its parent is its owner's to say.
## `EventManager` owns the events atlas page for its whole tree lifetime, including every scenery
## child and every streamed instance; a standalone fixture acquires that page around this node.

## The baked atlas pages the event's own look draws from (`AtlasLibrary`), handed in
## `draw_through()`.
var _atlas: AtlasLibrary
## What every layer of this scenery lays its pictures through (`SceneryDrawer`), handed in
## `draw_through()` and handed on to each layer it makes (`SceneryLayer.draw_through()`).
var _drawer: SceneryDrawer
var _moving_layers: Array[SceneryLayer] = []
var _static_layers: Array[SceneryLayer] = []
var _picture: String
var _extent: Vector2
var _anchor: Vector2
var _shadow: String
## The band of the scene this one draws, in the same space as `_anchor`; no area for all of it.
var _clip := Rect2()
## Whether the picture is drawn mirrored left to right about `_anchor`, as `Sprites.draw_standing()`
## mirrors a figure about its feet.
var _mirrored := false
var _frame_b := false

func _ready() -> void:
	_build()

func _exit_tree() -> void:
	for layer in _moving_layers:
		layer.free()
	for layer in _static_layers:
		layer.free()
	_moving_layers.clear()
	_static_layers.clear()
	request_ready()

## Handed, by the drawer that builds this scenery for the look (`EventDrawer.scenery()`) and before
## it is configured, the atlas pages its pictures are cut from and what its layers lay them through.
func draw_through(atlas: AtlasLibrary, drawer: SceneryDrawer) -> void:
	_atlas = atlas
	_drawer = drawer

func configure(picture: String, extent: Vector2, anchor: Vector2, shadow: String,
		clip := Rect2(), mirrored := false) -> void:
	_picture = picture
	_extent = extent
	_anchor = anchor
	_shadow = shadow
	_clip = clip
	_mirrored = mirrored

func _build() -> void:
	var original := _atlas.region(_picture)
	var scale_factor := _extent / original.get_size()
	var top_left := _anchor - Vector2(_extent.x * 0.5, _extent.y)
	if not _shadow.is_empty():
		var contact := SceneryLayer.new()
		contact.draw_through(_drawer)
		contact.modulate = Palette.SHADOW
		contact.append(_atlas.region(_shadow), _laid(contact, Rect2(top_left, _extent)))
		_static_layers.append(contact)
		add_child(contact)
	var stem := _picture.get_file()
	for part: Array in EventSceneryParts.LAYERS[stem]:
		var region := "events/" + str(part[0])
		var moving: bool = part[5]
		var rect := Rect2(top_left + Vector2(part[1], part[2]) * scale_factor,
				Vector2(part[3], part[4]) * scale_factor)
		var texture := _atlas.region(region)
		var source := Rect2()
		if _clip.has_area():
			var inside := rect.intersection(_clip)
			if not inside.has_area():
				continue
			var texels := texture.get_size() / rect.size
			source = Rect2((inside.position - rect.position) * texels, inside.size * texels)
			rect = inside
		var layer := SceneryLayer.new()
		layer.draw_through(_drawer)
		layer.append(texture, _laid(layer, rect), _atlas.region(region + "_b") if moving else null,
				source)
		if moving:
			_moving_layers.append(layer)
		else:
			_static_layers.append(layer)
		add_child(layer)
	set_frame(_frame_b)

## Where `rect` is laid in `layer`'s own space: where it stands, or, for a mirrored picture, the
## same place with `layer` turned left to right about the anchor, since a texture cannot be flipped
## by its rectangle (the **godot** skill, "Physics and drawing").
func _laid(layer: SceneryLayer, rect: Rect2) -> Rect2:
	if not _mirrored:
		return rect
	layer.position = _anchor
	layer.scale = Vector2(-1.0, 1.0)
	return Rect2(rect.position - _anchor, rect.size)

func set_frame(frame_b: bool) -> void:
	_frame_b = frame_b
	for layer in _moving_layers:
		layer.show_frame_b(frame_b)
