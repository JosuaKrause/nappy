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

## The heading and speed she was last led by (`lead()`), and how many times she was released.
var _fake_led := Vector2.ZERO
var _fake_led_speed := 0.0
var _fake_releases := 0

## Overrides Stroller.lead.
## Each ask carries her one tick on, as her own physics would.
func lead(heading: Vector2, speed: float) -> void:
	_fake_led = heading.normalized()
	_fake_led_speed = speed
	global_position += _fake_led * speed / float(Engine.physics_ticks_per_second)

## Overrides Stroller.release.
func release() -> void:
	_fake_led = Vector2.ZERO
	_fake_releases += 1

## Whether she is led.
func is_led() -> bool:
	return _fake_led != Vector2.ZERO

## The speed she was last led at.
func led_speed() -> float:
	return _fake_led_speed

## How many times she was handed back.
func releases() -> int:
	return _fake_releases

## Overrides Stroller.reset_at.
func reset_at(where: Vector2, look: Vector2 = Vector2.DOWN) -> void:
	_fake_put_at = where
	_fake_facing_when_put = look
	position = where
	_fake_asked.append("reset_at %s %s" % [where, look])
