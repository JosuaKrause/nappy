class_name RoadblockPhase
extends RefCounted
## **The roadblock phase at dawn**, day 13's (inbox #1185 in gentle-owl; `docs/EVENTS.md`, "The three views and
## the placement order"): after the routes are established, it goes through the route-adjacent
## sections and places roadblocks there, spread out. Each roadblock is drawn among every
## route-adjacent section still open to one, with **a bias toward the section farthest from the
## roadblocks already placed**, a bias and not a strict rule (inbox #1185 in gentle-owl: "it's a _bias_ not a strict
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
## along her paths day 13's task measures close by with, out to
## `RuledRoadblockGround.TASK_ROW_CLOSE_BY`),
## **or once no section still offered would bring one close by a route tile that has none**, **or once
## `MOST` stand**, or once no section is left in the draw. The stop is asked before each draw, never
## of the draw itself: a section close by nothing new is drawn like any other while some other
## section could still cover a route tile. *Read as, the orchestrator's and open to correction:* the phase is day 13's, with
## that stop (fork 6 of the placement proposal); the player, shown the count full coverage gave,
## called it good and said only a playtest can tell (inbox #1185 in gentle-owl), so where full coverage cannot be
## reached the count stops with the last section that could still help rather than running on, and
## never passes the top of the count the player called good (`MOST`).
##
## **What a section would cover is kept, and only ever shrinks**: a roadblock standing only shuts
## ground, so a walk along her paths only grows longer, and what a section covered when it was last
## asked is at least what it covers now. A kept answer that reaches no route tile left without one
## settles that section; one that does is asked again before the phase goes on.
##
## Handed the day's locations and what it asks of the day's ground (`RoadblockGround`). Model: no
## node, nothing that runs.

## The phase's stream salt off the day's seed (`DawnContext.stream()`): apart from the dawn
## draw's (`EventScheduler.LOCATIONS_SALT`) and the moments' (`DawnMoments.SALT`), so it
## never shares a stream with either.
const SALT := 5
## How strongly a section's distance from the nearest roadblock already placed weights its draw:
## the weight is that distance to this power. *Proposed, not asked for, open to overturn:* the player
## set a bias toward the farthest and no strength for it; 2 makes a section twice as far four times as
## likely.
const SPREAD_EXPONENT := 2.0
## The most roadblocks the phase stands: the top of the count the player called good (15 to 25,
## inbox #1185 in gentle-owl). *Read as, the orchestrator's and open to correction*, and asked of the player: a
## cap, so the count never runs away where full coverage cannot be reached.
const MOST := 25

var _locations: DayLocations
var _ground: RoadblockGround
var _uncovered := {}
## Section -> the route tiles its offer was close by when last asked (`_something_left_to_cover()`).
var _covers := {}
var _placed: Array[EventPlan] = []

func _init(locations: DayLocations, ground: RoadblockGround) -> void:
	_locations = locations
	_ground = ground

## **Places the day's roadblocks** on `rng`, and answers them in the order placed.
func place(rng: RandomNumberGenerator) -> Array[EventPlan]:
	for tile in _ground.route_tiles():
		_uncovered[tile] = true
	var candidates := _locations.sections_in(PlacementView.View.ROUTE_ADJACENT)
	var offers := {}
	while not _uncovered.is_empty() and _placed.size() < MOST \
			and _something_left_to_cover(candidates, offers):
		var pool: Array[Location] = []
		for section in candidates:
			if not _open(section):
				continue
			if not offers.has(section):
				offers[section] = _ground.offer(section)
			if offers[section] != null:
				pool.append(section)
		if pool.is_empty():
			break
		var drawn := _draw(pool, rng)
		var plan: EventPlan = offers[drawn]
		for tile in _ground.covers(plan):
			_uncovered.erase(tile)
		_ground.stand(plan)
		_locations.assign(drawn, plan)
		_placed.append(plan)
		var radius := _ground.reoffer_within()
		for section: Location in offers.keys():
			if section.centre().distance_to(plan.placed_at()) <= radius:
				offers.erase(section)
				_covers.erase(section)
	return _placed

## Whether `section` is still open to a roadblock: not taken, and not closed to a draw, as a section
## is once one of its sidewalks holds a fixed part (an ambient row, a mast, a wall's body;
## `StreetLocations.close_the_section_of()`), since a roadblock spans the street and would take that
## sidewalk over the part standing there.
static func _open(section: Location) -> bool:
	return not section.is_taken() and not section.is_drawn()

## Whether some section still offered a roadblock would bring one close by a route tile that has
## none: the phase's stop, asked before each draw.
func _something_left_to_cover(candidates: Array[Location], offers: Dictionary) -> bool:
	for section in candidates:
		if not _open(section):
			continue
		if not offers.has(section):
			offers[section] = _ground.offer(section)
		var plan: EventPlan = offers[section]
		if plan == null:
			continue
		if _covers.has(section) and not _reaches_one_with_none(_covers[section]):
			continue
		_covers[section] = _ground.covers(plan)
		if _reaches_one_with_none(_covers[section]):
			return true
	return false

## Whether any of `tiles` is a route tile with no roadblock close by yet.
func _reaches_one_with_none(tiles: Array[Vector2i]) -> bool:
	for tile in tiles:
		if _uncovered.has(tile):
			return true
	return false

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
