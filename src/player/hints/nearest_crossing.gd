class_name NearestCrossing
extends RefCounted
## **The way from a tile to the nearest zebra crossing**, searched in rings out from it: the one
## answer the two hints that point at a crossing share (`UseZebraWatcher`, `CrossStreetWatcher`).
## The last answer is kept for its tile, so a bubble up while she stands still searches once.

## How far, in tiles, the nearest crossing is looked for; none within it answers zero.
const SEARCH_TILES := 10

## A tile no search is ever asked from, so the first ask always searches.
const NOWHERE := Vector2i(-1000000, -1000000)
var _map: WorldMap
var _asked_from := NOWHERE
var _answer := Vector2.ZERO

func _init(map: WorldMap) -> void:
	_map = map

## The unit vector from `tile` toward the nearest crossing tile, or zero when none lies within
## `SEARCH_TILES`.
func toward(tile: Vector2i) -> Vector2:
	if tile == _asked_from:
		return _answer
	_asked_from = tile
	_answer = _search(tile)
	return _answer

func _search(tile: Vector2i) -> Vector2:
	for ring in range(1, SEARCH_TILES + 1):
		var best_distance := INF
		var best := Vector2.ZERO
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) != ring:
					continue
				if _map.is_crossing(tile + Vector2i(x, y)) and Vector2(x, y).length() < best_distance:
					best_distance = Vector2(x, y).length()
					best = Vector2(x, y).normalized()
		if best_distance < INF:
			return best
	return Vector2.ZERO
