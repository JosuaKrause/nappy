class_name FakeStroller
extends Stroller
## A stand-in for her, handed to what is handed a `Stroller` (the day director, an authored scene)
## in place of the real one: it notes where she is put down and which way she faces, and stands
## there. A helper, not a suite: the runner loads only `test_*.gd`. A node: the suite frees it.

var _fake_asked: Array[String]
var _fake_put_at := Vector2.INF
var _fake_facing_when_put := Vector2.ZERO

## Notes her being put down as lines of `asked`, the list a suite shares among its stand-ins.
func _init(asked: Array[String] = []) -> void:
	_fake_asked = asked

## Where she was last put down, `Vector2.INF` before.
func put_at() -> Vector2:
	return _fake_put_at

## Which way she was asked to face when she was put down, `Vector2.ZERO` before.
func facing_when_put() -> Vector2:
	return _fake_facing_when_put

## Overrides Stroller.reset_at.
func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
	_fake_put_at = where
	_fake_facing_when_put = look
	position = where
	_fake_asked.append("reset_at %s %s" % [where, look])
