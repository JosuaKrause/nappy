class_name HintFrame
extends RefCounted
## **What a watcher is asked against, one tick**: where she is, which way she faces, how long the
## tick was. Made once a tick by `HintWatch`, so every watcher reads the same moment.

var _position := Vector2.ZERO
var _heading := Vector2.DOWN
var _delta := 0.0

func _init(her_position: Vector2, her_heading: Vector2, seconds: float) -> void:
	_position = her_position
	_heading = her_heading
	_delta = seconds

func position() -> Vector2:
	return _position

func heading() -> Vector2:
	return _heading

func delta() -> float:
	return _delta
