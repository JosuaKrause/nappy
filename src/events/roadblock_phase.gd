class_name RoadblockPhase
extends RefCounted
## **The roadblock phase at dawn**, day 13's (inbox #1185; `docs/EVENTS.md`, "The three views and
## the placement order"): after the routes are established, it goes through the route-adjacent
## sections and places roadblocks there, spread out. Each roadblock is drawn among every
## route-adjacent section still open to one, with **a bias toward the section farthest from the
## roadblocks already placed**, a bias and not a strict rule (inbox #1185: "it's a _bias_ not a strict
## placement"), and its section is then assigned for the day (`DayLocations.assign()`), so nothing is
## drawn there later.
##
## **A section is considered only where a roadblock is valid there**: the roadblock the section
## would take is what the day's ground offers (`RoadblockGround.offer()`), today's placement rules
## deciding, and a section it offers none is not in the draw. Nothing is placed and then refused.
## An offer is asked again once a roadblock stands within the ground's own radius of the section
## (`RoadblockGround.reoffer_within()`), since that roadblock may have made it invalid.
##
## **It stops once every route tile has a roadblock close by** (`RoadblockGround.covers()`, the walk
## along her paths day 13's task measures close by with, out to `EventScheduler.TASK_ROW_CLOSE_BY`),
## or once no section is left in the draw. *Read as, the orchestrator's and open to correction:* the
## phase is day 13's, with that stop (fork 6 of the placement proposal); the player, shown the count
## full coverage gives, called it good and said only a playtest can tell (inbox #1185).
##
## Handed the day's locations and what it asks of the day's ground (`RoadblockGround`). Model: no
## node, nothing that runs.

## The phase's stream salt off the day's seed (`EventScheduler._stream()`): after
## `EventScheduler.WALL_THINNING_SALT` and far below `EventScheduler.FILL_SALT`, so it never shares a
## stream with the fill.
const SALT := 5
## How strongly a section's distance from the nearest roadblock already placed weights its draw:
## the weight is that distance to this power. *Proposed, not asked for, open to overturn:* the player
## set a bias toward the farthest and no strength for it; 2 makes a section twice as far four times as
## likely.
const SPREAD_EXPONENT := 2.0

var _locations: DayLocations
var _ground: RoadblockGround
var _uncovered := {}
var _placed: Array[EventScheduler.Planned] = []

func _init(locations: DayLocations, ground: RoadblockGround) -> void:
	_locations = locations
	_ground = ground

## **Places the day's roadblocks** on `rng`, and answers them in the order placed.
func place(rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	for tile in _ground.route_tiles():
		_uncovered[tile] = true
	var candidates := _locations.sections_in(PlacementView.View.ROUTE_ADJACENT)
	var offers := {}
	while not _uncovered.is_empty():
		var pool: Array[Location] = []
		for section in candidates:
			if section.is_taken():
				continue
			if not offers.has(section):
				offers[section] = _ground.offer(section)
			if offers[section] != null:
				pool.append(section)
		if pool.is_empty():
			break
		var drawn := _draw(pool, rng)
		var plan: EventScheduler.Planned = offers[drawn]
		for tile in _ground.covers(plan):
			_uncovered.erase(tile)
		_ground.stand(plan)
		_locations.assign(drawn, plan)
		_placed.append(plan)
		var radius := _ground.reoffer_within()
		for section: Location in offers.keys():
			if section.centre().distance_to(plan.placed_at()) <= radius:
				offers.erase(section)
	return _placed

## How many of the ground's route tiles are left with no roadblock close by once `place()` is done.
func left_uncovered() -> int:
	return _uncovered.size()

## One section of `pool`, drawn with a bias toward the farthest from the roadblocks placed so far;
## the first of the day uniformly.
func _draw(pool: Array[Location], rng: RandomNumberGenerator) -> Location:
	var weights: Array[float] = []
	var total := 0.0
	for section in pool:
		var weight := 1.0
		if not _placed.is_empty():
			var nearest := INF
			for plan in _placed:
				nearest = minf(nearest, section.centre().distance_to(plan.placed_at()))
			weight = pow(nearest, SPREAD_EXPONENT)
		weights.append(weight)
		total += weight
	var roll := rng.randf() * total
	for index in pool.size():
		roll -= weights[index]
		if roll <= 0.0:
			return pool[index]
	return pool[pool.size() - 1]
