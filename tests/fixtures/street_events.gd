class_name StreetEvents
extends RefCounted
## **An `EventManager` over a map of streets and no city**: handed the map, today's streets, the run
## its events belong to and a bare world node the events stand in, the way a rig that builds no city
## hands them (`EventManager.setup()` with no lights, navigator, siting or poster walls), so a suite
## whose subject is what the manager sends, steps and tells builds none of the city's other parts
## (the crowd, the scenery, the lights). Nothing is sited ahead of her until the suite hands the
## manager a player (`EventManager.use_player()`).

## A manager over `map` in the run `run`, planning a day against `streets`, which the suite begins
## before each day it starts (`RigStreets.begin()`), added to `t`, with its events' world node a
## child of it. Streaming reaches `stream_radius` (`Tuning.EVENT_STREAM_RADIUS` unless asked). It is
## freed with `free()`, which frees the world node and every instance with it.
static func over(t: TestRunner, map: CityMap, run: RunState, streets: DayStreets,
		stream_radius := Tuning.EVENT_STREAM_RADIUS) -> EventManager:
	var holder := WorldContext.new()
	var manager := EventManager.new(Shipped.rows(), EventSurroundings.new()
			.in_the_city(map).drawn_in(holder))
	manager.use_bus(EventBus)
	manager.add_child(holder)
	manager.setup(run, streets)
	manager.stream_within(stream_radius)
	t.add_child(manager)
	return manager
