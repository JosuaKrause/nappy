class_name FakeBaby
extends Baby
## A stand-in for the baby, handed to what is handed a `Baby` (the day director, an authored
## scene) in place of the real one: it notes being reset, having her meters seeded and being put to
## sleep, and changes nothing. A helper, not a suite: the runner loads only `test_*.gd`. A node: the
## suite frees it.

var _fake_asked: Array[String]
var _fake_seeded: Array[Vector2] = []

## Notes what she is asked as lines of `asked`, the list a suite shares among its stand-ins.
func _init(asked: Array[String] = []) -> void:
	_fake_asked = asked

## Every `seed_meters()` ask as (sleepiness, excitement), in order.
func seeded_meters() -> Array[Vector2]:
	return _fake_seeded

## Overrides Baby.reset.
func reset() -> void:
	_fake_asked.append("baby reset")

## Overrides Baby.seed_meters.
func seed_meters(sleepiness: float, excitement: float) -> void:
	_fake_seeded.append(Vector2(sleepiness, excitement))
	_fake_asked.append("baby seed_meters %.1f %.1f" % [sleepiness, excitement])

## Overrides Baby.force_sleep.
func force_sleep() -> void:
	_fake_asked.append("baby force_sleep")
