class_name OneNoticeRule
extends StreetRule
## **No two waiting guards notice her from the same ground**, so she deals with one at a time
## (`EventScheduler._keeps_its_notice_to_itself()`): the escape's rule (`DaySpec.one_notice_at_a_time`),
## asked of what the walk has placed.

var _map: CityMap

func _init(map: CityMap) -> void:
	_map = map

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		placed: Array[EventScheduler.Planned], _around: Array[EventScheduler.Planned]) -> bool:
	return EventScheduler._keeps_its_notice_to_itself(_map, candidate, placed)
