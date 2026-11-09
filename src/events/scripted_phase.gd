class_name ScriptedPhase
extends RefCounted
## **The dawn phase for a row the day places for a reason of its own**: a scripted row on its day
## (day 10's night raid, day 13's firefight). It draws one of the
## day's open locations its ground takes, each weighted by `weigh` (the row's role weights over the
## location's tiles: a wall kept off the route, friction drawn onto it, as the roll weighed a tile),
## offers it the row through `ground` (the dawn draw's own path: the first tile with room all round,
## else the roomiest a rule leaves), and assigns the location what it took, so no draw happens there.
## A location that takes nothing is passed over and the draw goes on among the rest; none left, and
## the row does not happen, which is the right failure direction. Placement by location, no tile
## rolled (the orchestrator's reading of the fixed parts' phases, open to correction;
## `docs/EVENTS.md`, "The three views and the placement order"). Model: no node.

var _locations: DayLocations
var _ground: LocationGround
var _weigh: Callable

## The phase over the day's `locations`, offering through `ground`, each location weighed by `weigh`
## (`(def, location) -> float`, 0 for one the row's ground does not take).
func _init(locations: DayLocations, ground: LocationGround, weigh: Callable) -> void:
	_locations = locations
	_ground = ground
	_weigh = weigh

## **`def`'s placement for the day, drawn on `rng`**, standing in and assigned to its location, or
## null where no open location takes it.
func place(def: EventDef, rng: RandomNumberGenerator) -> EventScheduler.Planned:
	var pool: Array[Location] = []
	var weights: Array[float] = []
	for location in _locations.open_locations():
		var weight := float(_weigh.call(def, location))
		if weight > 0.0:
			pool.append(location)
			weights.append(weight)
	while not pool.is_empty():
		var total := 0.0
		for weight in weights:
			total += weight
		var pick := rng.randf() * total
		var chosen := pool.size() - 1
		for i in pool.size():
			pick -= weights[i]
			if pick < 0.0:
				chosen = i
				break
		var location := pool[chosen]
		var plan := _ground.offer(def, location)
		if plan:
			_locations.assign_to(location, plan)
			_ground.stand(plan)
			return plan
		pool.remove_at(chosen)
		weights.remove_at(chosen)
	return null
