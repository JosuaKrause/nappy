class_name FakeClosure
extends RoadClosure
## A stand-in for a day's road closure whose ground a check sets: handed to `CityMap.close_streets()`
## on a hand-drawn map in place of a planned one, so the check names the tiles that are shut and
## plans no street. Its tiles and its two mouths both answer the tiles the check names, one tile
## each, so the flood from the doorstep that `close_streets()` makes stops at each and closes it.
## The real closure is checked in `tests/test_routes_closures_a.gd`. A helper, not a suite: the
## runner loads only `test_*.gd`.

var _fake_tiles: Array[Vector2i] = []

func _init(closed: Array[Vector2i]) -> void:
	super(Kind.ROADWORKS, null)
	_fake_tiles = closed.duplicate()

## A closure over the tiles of a set (`tile -> true`), as a map's closed tiles were kept.
static func over_set(tiles: Dictionary) -> FakeClosure:
	var closed: Array[Vector2i] = []
	for tile: Vector2i in tiles:
		closed.append(tile)
	return FakeClosure.new(closed)

## Overrides RoadClosure.tiles.
func tiles(_map: CityMap) -> Array[Vector2i]:
	return _fake_tiles.duplicate()

## Overrides RoadClosure.mouth_rects.
func mouth_rects() -> Array[Rect2i]:
	var found: Array[Rect2i] = []
	for tile in _fake_tiles:
		found.append(Rect2i(tile, Vector2i.ONE))
	return found
