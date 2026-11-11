class_name RouteGroundRule
extends StreetRule
## **No body stands on the ground a route runs along off the streets**: a candidate that blocks the
## way (`EventPlan.obstructs()`: a body she cannot pass, or a row that ends the day) is refused when
## its disc (`EventPlan.blocking_radius()` round `EventPlan.placed_at()`, painted as
## `EventScheduler.block_a_disc()` paints it) covers a tile a route runs along
## (`Corridor.carries_a_route()`) that is off the streets (`is_ground_off_the_street()`: an alley, a
## park cut, a square).
##
## **With it a route cannot be closed, so nothing floods the city to see whether one is.** On a
## street the other route rules keep the way: a route's junction box keeps a free crossing
## (`RouteJunctionsRule`), the sidewalk it walks keeps a line with room for her
## (`RouteSidewalkRule`), and nothing stands in the open end of a pacing beat
## (`PacingOpeningRule`). Off the streets no line rule reaches, and this one leaves the route's own
## tiles free, which is stricter than asking whether a way round exists: a body never stands on a
## route tile there even where a detour would have taken her past it. *(inbox #1173 in gray-dolphin:
## "there is no reason to check whether a route is open during game play because it cannot be
## closed to begin with".)*
##
## **One setting, whether a street's route tiles count** (`counts_the_streets`). Off for a judge
## the line rules also ask (`StreetInvalidation`); on for what the line rules are not asked of, the
## run's scars and the park spoilers, which are not spaced and not given a role and stand where they
## stand: for them a route's sidewalk is ground no body may cover either, so a barricade the run
## left across a route's street is not stood, and one on the far sidewalk is.
##
## It reads the candidate's disc and the route's tiles and nothing else: nothing of what is placed
## or stands round it, and nothing kept between asks. With no corridor it asks nothing. Model: no
## node.

var _map: CityMap
var _corridor: Corridor
var _counts_the_streets: bool

## The rule on `map` for the routes `corridor` runs (null for a walk with no route tree, which this
## refuses nothing on), counting a street's route tiles too where `counts_the_streets`.
func _init(map: CityMap, corridor: Corridor, counts_the_streets := false) -> void:
	_map = map
	_corridor = corridor
	_counts_the_streets = counts_the_streets

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	if _corridor == null or not candidate.obstructs():
		return true
	var disc := {}
	EventScheduler.block_a_disc(_map, disc, candidate.placed_at(), candidate.blocking_radius())
	for tile: Vector2i in disc:
		if _is_route_ground(tile):
			return false
	return true

## Whether a body may not cover `tile`: a route runs along it, and it is open today and, unless the
## streets count, no street's.
func _is_route_ground(tile: Vector2i) -> bool:
	if not _corridor.carries_a_route(tile):
		return false
	if _counts_the_streets:
		return _map.is_open(tile)
	return is_ground_off_the_street(_map, tile)

## **Walkable today and not part of a street**: a park, a square, an alley, a courtyard, a
## precinct's own ground. A carriageway is walkable and is not a way off a street, which is why
## this asks `CityMap.is_street()` rather than only `CityMap.is_open()`. Public because a pacing
## beat's way out is the same ground (`StreetInvalidation._a_side_route_opens_off()`), and one
## reading asked twice is stated once.
static func is_ground_off_the_street(map: CityMap, tile: Vector2i) -> bool:
	return map.is_open(tile) and not map.is_street(tile)
