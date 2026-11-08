class_name PacingOpeningRule
extends StreetRule
## **The opening a pacing man's beat leaves is ground in its own right**: the rows reaching one route
## street are asked together whether a walk along it survives, so nothing stands in the one end the
## man shouting is away from (`EventScheduler._leaves_a_pacing_beats_opening()`).

var _map: CityMap
var _corridor: Corridor

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	return EventScheduler._leaves_a_pacing_beats_opening(candidate, _map, _corridor, around)
