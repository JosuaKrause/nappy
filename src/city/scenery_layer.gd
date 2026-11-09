class_name SceneryLayer
extends Node2D
## A retained batch of registered scenery pictures. Only an alternate-frame change rebuilds
## its drawing; callers keep stationary batches separate and order them around moving pieces.
## Which texture stands where, and which of a picture's two frames shows, is decided here; every
## picture is laid through the drawer its owner hands it (`SceneryDrawer`).

## What every picture of this batch is laid through, handed by the owner that makes the layer
## before it enters the tree: the city's decals (`CityDecals`), a vent's rotor
## (`Building.RoofObject.add_rotor()`) and an event's scenery (`EventScenery`), each handing on the
## drawer it was handed.
var drawer: SceneryDrawer

## Lays every picture of this batch through `through` (see `drawer`), handed before the layer enters
## the tree.
func draw_through(through: SceneryDrawer) -> void:
	drawer = through

var _textures: Array[Texture2D] = []
var _alternates: Array[Texture2D] = []
var _rects: Array[Rect2] = []
## The part of each texture drawn into its rect, in the texture's own pixels; an empty rect for the
## whole texture.
var _sources: Array[Rect2] = []
var frame_b := false:
	set(value):
		if frame_b == value:
			return
		frame_b = value
		queue_redraw()

## Shows each picture's alternate frame when `shown` (see `frame_b`).
func show_frame_b(shown: bool) -> void:
	frame_b = shown

## `source`, when it has an area, is the part of the texture (and of its alternate) drawn into
## `rect`: a picture cut into slices draws each slice's part of it (`EventScenery`).
func append(texture: Texture2D, rect: Rect2, alternate: Texture2D = null,
		source := Rect2()) -> void:
	_textures.append(texture)
	_alternates.append(alternate)
	_rects.append(rect)
	_sources.append(source)
	queue_redraw()

func _draw() -> void:
	for i in _textures.size():
		var texture := _alternates[i] if frame_b and _alternates[i] != null else _textures[i]
		drawer.draw(self, texture, _rects[i], _sources[i])
