class_name SceneryLayer
extends Node2D
## A retained batch of registered scenery pictures. Only an alternate-frame change rebuilds
## its drawing; callers keep stationary batches separate and order them around moving pieces.

var _textures: Array[Texture2D] = []
var _alternates: Array[Texture2D] = []
var _rects: Array[Rect2] = []
var frame_b := false:
	set(value):
		if frame_b == value:
			return
		frame_b = value
		queue_redraw()

func append(texture: Texture2D, rect: Rect2, alternate: Texture2D = null) -> void:
	_textures.append(texture)
	_alternates.append(alternate)
	_rects.append(rect)
	queue_redraw()

func _draw() -> void:
	if FrameRecord.on:
		FrameRecord.drew(FrameLedger.DRAWS_SCENERY)
	for i in _textures.size():
		var texture := _alternates[i] if frame_b and _alternates[i] != null else _textures[i]
		draw_texture_rect(texture, _rects[i], false)
