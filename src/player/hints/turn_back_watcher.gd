class_name TurnBackWatcher
extends HintWatcher
## **Turn back**: she nears a seal or a closure that leaves no sidewalk on along her heading (day
## 2's dead end; curly-moose #819, "a hint to turn around"). Looked for along the line she faces,
## a few tiles ahead: the first tile she cannot walk on is a closure's (`CityMap.is_closed()`), a
## soft seal's sidewalk (`soft_sealed_tiles()`), or a body on a street held for a body across it
## (`is_obstructed()`, `is_barred_at()`: a hard seal or a region wall; a district door is held for
## the catalogue only, and is walked through). Armed again once nothing bars her way ahead.

## How far ahead, in tiles, along her heading the seal or closure is looked for.
const LOOK_AHEAD_TILES := 4

var _map: CityMap
var _armed := true

func _init(map: CityMap) -> void:
	_map = map

## Overrides HintWatcher.kind.
func kind() -> HintKind.Kind:
	return HintKind.Kind.TURN_BACK

## Overrides HintWatcher.begin_walk.
func begin_walk(_route: TutorialRoute) -> void:
	_armed = true

## Overrides HintWatcher.asks.
func asks(frame: HintFrame) -> bool:
	var barred := _barred_ahead(frame)
	if not barred:
		_armed = true
	return barred and _armed

## Overrides HintWatcher.shown.
func shown() -> void:
	_armed = false

func _barred_ahead(frame: HintFrame) -> bool:
	var step := _step_along(frame.heading())
	if step == Vector2i.ZERO:
		return false
	var tile := _map.world_to_tile(frame.position())
	var soft := _map.soft_sealed_tiles()
	for i in range(1, LOOK_AHEAD_TILES + 1):
		var ahead := tile + step * i
		var sealed_soft := soft.has(ahead)
		var body := _map.is_obstructed(ahead)
		if _map.is_walkable(ahead) and not _map.is_closed(ahead) and not sealed_soft and not body:
			continue
		return _map.is_closed(ahead) or sealed_soft or (body and _map.is_barred_at(ahead))
	return false

## The tile step along `heading`'s larger axis, or zero for no heading.
static func _step_along(heading: Vector2) -> Vector2i:
	if heading.length() < 0.5:
		return Vector2i.ZERO
	if absf(heading.x) >= absf(heading.y):
		return Vector2i(int(signf(heading.x)), 0)
	return Vector2i(0, int(signf(heading.y)))
