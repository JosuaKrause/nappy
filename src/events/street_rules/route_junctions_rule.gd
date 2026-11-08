class_name RouteJunctionsRule
extends StreetRule
## **A route's junction box keeps a walk between the route streets meeting there**, against the line
## reach of every row that counts against it (`EventScheduler._leaves_the_route_junctions_open()`).
## It reads what stands round the box, seals and the region wall included, so what another street
## holds within its reach invalidates here too (fork 3 of the placement proposal, the orchestrator's
## reading: today's rules reach across a junction).

var _map: CityMap
var _corridor: Corridor
var _ground: Dictionary

func _init(map: CityMap, corridor: Corridor, ground: Dictionary) -> void:
	_map = map
	_corridor = corridor
	_ground = ground

## Overrides StreetRule.allows.
func allows(candidate: EventScheduler.Planned, _tile: Vector2i,
		_placed: Array[EventScheduler.Planned], around: Array[EventScheduler.Planned]) -> bool:
	return EventScheduler._leaves_the_route_junctions_open(candidate, _map, _corridor, _ground,
			around)
