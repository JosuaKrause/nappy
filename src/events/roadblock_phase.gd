class_name RoadblockPhase
extends RefCounted
## **The roadblock phase at dawn**, day 13's (inbox #1185; `docs/EVENTS.md`, "The three views and
## the placement order"): after the routes are established, it goes through the route-adjacent
## sections and places roadblocks there, spread out. Each roadblock is drawn among the sections
## still open to one with **a bias toward the section farthest from the roadblocks already placed**,
## a bias and not a strict rule (inbox #1185: "it's a _bias_ not a strict placement"), and its
## section is then assigned for the day (`DayLocations.assign()`), so nothing is drawn there later.
##
## **A section is considered only where a roadblock is valid there**: the roadblock the section
## would take is what the day's ground offers (`RoadblockGround.offer()`), today's placement rules
## deciding, and a section it offers none is not in the draw. Nothing is placed and then refused.
##
## **It stops once every route tile has a roadblock close by** (`RoadblockGround.covers()`, the walk
## along her paths day 13's task measures close by with, out to `EventScheduler.TASK_ROW_CLOSE_BY`),
## or once no section left could be close by a route tile that has none. *Read as, the
## orchestrator's and open to correction:* the phase is day 13's, with the stop the dawn pass before
## it kept, which placed 15 to 25 on the probe cities, a number the player called good (inbox #1185);
## fork 6 of the placement proposal. A section is in the draw only while some route tile with none
## lies in the squares (`_CELL`) within `reach` of it, a straight line a walk along her paths can never
## beat; the one drawn is measured along her paths, and one that would be close by none of them after
## all is left out of the next draws.
##
## Handed the day's locations, what it asks of the day's ground (`RoadblockGround`), the reach close
## by is measured within, and how far round a roadblock just placed the offers are asked again.
## Model: no node, nothing that runs.

## The phase's stream salt off the day's seed (`EventScheduler._stream()`): after
## `EventScheduler.WALL_THINNING_SALT` and far below `EventScheduler.FILL_SALT`, so it never shares a
## stream with the fill.
const SALT := 5
## How strongly a section's distance from the nearest roadblock already placed weights its draw:
## the weight is that distance to this power. *Proposed, not asked for:* the player set a bias toward
## the farthest and no strength for it; 2 makes a section twice as far four times as likely.
const SPREAD_EXPONENT := 2.0
## The side of the squares the route tiles with no roadblock close by are counted in, so a section
## asks only the squares within its reach whether any is left.
const _CELL := 256.0

var _locations: DayLocations
var _ground: RoadblockGround
var _reach := 0.0
var _reoffer_within := 0.0
var _uncovered := {}
var _counted := {}
var _placed: Array[EventScheduler.Planned] = []

func _init(locations: DayLocations, ground: RoadblockGround, reach: float,
		reoffer_within: float) -> void:
	_locations = locations
	_ground = ground
	_reach = reach
	_reoffer_within = reoffer_within

## **Places the day's roadblocks** on `rng`, and answers them in the order placed.
func place(rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	for tile in _ground.route_tiles():
		_uncovered[tile] = true
		_count(tile, 1)
	var candidates := _locations.sections_in(PlacementView.View.ROUTE_ADJACENT)
	var offers := {}
	var close_by_none := {}
	while not _uncovered.is_empty():
		var pool: Array[Location] = []
		for section in candidates:
			if section.is_taken() or close_by_none.has(section) \
					or not _near_a_route_tile_with_none(section.centre()):
				continue
			if not offers.has(section):
				offers[section] = _ground.offer(section)
			if offers[section] != null:
				pool.append(section)
		if pool.is_empty():
			break
		var drawn := _draw(pool, rng)
		var plan: EventScheduler.Planned = offers[drawn]
		var newly: Array[Vector2i] = []
		for tile in _ground.covers(plan):
			if _uncovered.has(tile):
				newly.append(tile)
		if newly.is_empty():
			close_by_none[drawn] = true
			continue
		_ground.stand(plan)
		_locations.assign(drawn, plan)
		_placed.append(plan)
		for tile in newly:
			_uncovered.erase(tile)
			_count(tile, -1)
		for section: Location in offers.keys():
			if section.centre().distance_to(plan.placed_at()) <= _reoffer_within:
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

## Whether a route tile with no roadblock close by lies in a square (`_CELL`) within `_reach` of `at`.
func _near_a_route_tile_with_none(at: Vector2) -> bool:
	var from := _cell_of(at - Vector2.ONE * _reach)
	var to := _cell_of(at + Vector2.ONE * _reach)
	# Whichever is fewer to ask: the squares within reach, or the squares holding any at all.
	if (to.x - from.x + 1) * (to.y - from.y + 1) > _counted.size():
		for cell: Vector2i in _counted:
			if int(_counted[cell]) > 0 and cell.x >= from.x and cell.x <= to.x \
					and cell.y >= from.y and cell.y <= to.y:
				return true
		return false
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			if int(_counted.get(Vector2i(x, y), 0)) > 0:
				return true
	return false

func _count(tile: Vector2i, by: int) -> void:
	var cell := _cell_of(Vector2(tile) * Tuning.TILE_SIZE)
	_counted[cell] = int(_counted.get(cell, 0)) + by

static func _cell_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / _CELL), floori(at.y / _CELL))
