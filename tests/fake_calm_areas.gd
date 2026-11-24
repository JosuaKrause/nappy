class_name FakeCalmAreas
extends CalmAreas
## A stand-in for the day's calm areas whose answers a check sets: handed to what is handed
## `CalmAreas` (`DayEvents.over()`) in place of the real one, so the check builds no city. It
## answers what that asks: the areas, each one's calm ground, the ground of those she has not
## used, and the one set aside (none). Its values are copied from what `CalmAreas.of()` answers for
## a real city; the real object's own logic is checked once, in `tests/test_calm_areas.gd`. A
## helper, not a suite: the runner loads only `test_*.gd`.

var _fake_blocks: Array[Vector2i] = []
var _fake_grounds := {}
var _fake_used: Array[Vector2i] = []

## Adds the calm area `block`: its calm ground in world space, and whether she settled in it this
## act.
func set_area(block: Vector2i, ground: Rect2, used_this_act := false) -> FakeCalmAreas:
	_fake_blocks.append(block)
	_fake_grounds[block] = ground
	if used_this_act:
		_fake_used.append(block)
	return self

## Overrides CalmAreas.blocks.
func blocks() -> Array[Vector2i]:
	return _fake_blocks.duplicate()

## Overrides CalmAreas.ground_of.
func ground_of(block: Vector2i) -> Rect2:
	return _fake_grounds.get(block, Rect2())

## Overrides CalmAreas.unused_ground.
func unused_ground() -> Array[Rect2]:
	var ground: Array[Rect2] = []
	for block in _fake_blocks:
		if not _fake_used.has(block):
			ground.append(_fake_grounds.get(block, Rect2()))
	return ground

## Overrides CalmAreas.besides.
func besides() -> Vector2i:
	return CalmAreas.NONE
