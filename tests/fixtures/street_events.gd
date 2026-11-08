class_name StreetEvents
extends RefCounted
## **An `EventManager` over a map of streets and no city**: handed the map, the run its events belong
## to and a bare world node the events stand in, the way a rig that builds no city hands it
## (`EventManager.setup()` with no city, `use_run()`), so a suite whose subject is what the manager
## sends, steps and tells builds none of the city's other parts (the crowd, the scenery, the
## lights). Nothing is sited ahead of her until the suite hands the manager a player
## (`EventManager.use_player()`).

## A manager over `map` in a run of its own seed `run_seed`, added to `t`, with its events' world
## node a child of it. Streaming reaches `stream_radius` (`Tuning.EVENT_STREAM_RADIUS` unless
## asked). It is freed with `free()`, which frees the world node and every instance with it.
static func over(t, map: CityMap, run: RunState, stream_radius := Tuning.EVENT_STREAM_RADIUS) \
		-> EventManager:
	var manager := EventManager.new()
	var holder := WorldContext.new()
	manager.add_child(holder)
	map.world = holder
	manager.setup(null, map)
	manager.use_run(run)
	manager.stream_radius = stream_radius
	t.add_child(manager)
	return manager
