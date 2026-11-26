class_name UseZebraWatcher
extends HintWatcher
## **Use the zebra crossing**: when she steps onto the carriageway away from a crossing, the bubble
## points at the nearest one (minty-dolphin #834, #867). Armed again once she is off the road.

## How far, in tiles, the nearest crossing is looked for; none within it, no bubble.
const SEARCH_TILES := 10

var _map: CityMap
var _armed := true
var _way := Vector2.ZERO

func _init(map: CityMap) -> void:
	_map = map

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.USE_ZEBRA

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var tile := _map.world_to_tile(frame.position())
	if _map.tile_at(tile) != GameEnums.TileType.ROAD:
		_armed = true
		return false
	if not _armed:
		return false
	_way = _toward_a_crossing(tile)
	return _way != Vector2.ZERO

## Overrides HintWatcher.direction.
func direction(_frame: HintFrame) -> Vector2:
	return _way

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

func _toward_a_crossing(tile: Vector2i) -> Vector2:
	for ring in range(1, SEARCH_TILES + 1):
		var best_distance := INF
		var best := Vector2.ZERO
		for x in range(-ring, ring + 1):
			for y in range(-ring, ring + 1):
				if maxi(absi(x), absi(y)) != ring:
					continue
				var candidate := tile + Vector2i(x, y)
				if _map.tile_at(candidate) == GameEnums.TileType.CROSSING \
						and Vector2(x, y).length() < best_distance:
					best_distance = Vector2(x, y).length()
					best = Vector2(x, y).normalized()
		if best_distance < INF:
			return best
	return Vector2.ZERO
