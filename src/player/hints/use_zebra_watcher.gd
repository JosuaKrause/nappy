class_name UseZebraWatcher
extends HintWatcher
## **Use the zebra crossing**: when she steps onto the carriageway away from a crossing, the bubble
## points at the nearest one (minty-dolphin #834, #867). Armed again once she is off the road.

var _map: CityMap
var _crossings: NearestCrossing
var _armed := true
var _way := Vector2.ZERO

func _init(map: CityMap, crossings: NearestCrossing) -> void:
	_map = map
	_crossings = crossings

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.USE_ZEBRA

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_armed = true

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var tile := _map.world_to_tile(frame.position())
	if _map.tile_at(tile) != GameEnums.TileType.ROAD:
		_armed = true
		return false
	if not _armed:
		return false
	_way = _crossings.toward(tile)
	return _way != Vector2.ZERO

## Overrides HintWatcher.direction.
func direction(_frame: HintFrame) -> Vector2:
	return _way

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false
