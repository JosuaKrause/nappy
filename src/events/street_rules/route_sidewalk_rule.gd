class_name RouteSidewalkRule
extends StreetRule
## **The sidewalk a route walks keeps a line she can take at no cost, with room for her body,
## junction to junction** (`EventScheduler._leaves_the_routes_sidewalk_open()`): the far side of a
## street answers a van, and nothing answers a van on the side the route is drawn down. What
## stands round the street, seals included, is asked with it.

var _map: CityMap
var _corridor: Corridor

func _init(map: CityMap, corridor: Corridor) -> void:
	_map = map
	_corridor = corridor

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	return EventScheduler._leaves_the_routes_sidewalk_open(candidate, _map, _corridor, around)
