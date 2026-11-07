class_name FakeCalmAreas
extends CalmAreas
## A stand-in for the day's calm areas whose answers a check sets: handed to what is handed
## `CalmAreas` (`DayEvents.over()`, `DayRepairs`' repairs) in place of the real one, so the
## check builds no city. It answers what those ask: the areas, each one's calm ground and calm
## tiles, which are unused, and the one set aside. Its values are copied from what
## `CalmAreas.of()` answers for a real city; the real object's own logic is checked once, in
## `tests/test_calm_areas.gd`. A helper, not a suite: the runner loads only `test_*.gd`.

var _fake_blocks: Array[Vector2i] = []
var _fake_grounds := {}
var _fake_tiles := {}
var _fake_used: Array[Vector2i] = []
var _fake_besides := CalmAreas.NONE

## Adds the calm area `block`: its calm ground in world space, its calm tiles, and whether she
## settled in it this act.
func set_area(block: Vector2i, ground: Rect2, calm_tiles: Array[Vector2i] = [],
		used_this_act := false) -> FakeCalmAreas:
	_fake_blocks.append(block)
	_fake_grounds[block] = ground
	_fake_tiles[block] = calm_tiles.duplicate()
	if used_this_act:
		_fake_used.append(block)
	return self

## Sets the area that does not count today.
func set_besides(block: Vector2i) -> FakeCalmAreas:
	_fake_besides = block
	return self

## Overrides CalmAreas.blocks.
func blocks() -> Array[Vector2i]:
	return _fake_blocks.duplicate()

## Overrides CalmAreas.ground_of.
func ground_of(block: Vector2i) -> Rect2:
	return _fake_grounds.get(block, Rect2())

## Overrides CalmAreas.calm_tiles_of.
func calm_tiles_of(block: Vector2i) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	tiles.assign(_fake_tiles.get(block, []))
	return tiles

## Overrides CalmAreas.unused.
func unused() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for block in _fake_blocks:
		if not _fake_used.has(block):
			found.append(block)
	return found

## Overrides CalmAreas.besides.
func besides() -> Vector2i:
	return _fake_besides
