class_name RouteGroundRule
extends StreetRule
## **No body and no cost stands on the ground a route runs along off the streets**: a candidate
## that blocks the way (`EventPlan.obstructs()`: a body she cannot pass, or a catch that shuts
## ground where its row holds its place, `EventDef.catch_shuts_within()`) is refused when its disc
## (`EventPlan.blocking_radius()` round where its body stands, `EventPlan.body_at()`, painted as
## `EventScheduler.block_a_disc()` paints it) covers a tile a route runs along
## (`Corridor.carries_a_route()`) that is off the streets (`is_ground_off_the_street()`: an alley,
## a park cut, a square); and a row that counts against her line is refused when its line reach
## covers one (`_denies_a_route_off_the_streets()`).
##
## **With it a route cannot be closed, so nothing floods the city to see whether one is.** On a
## street the other route rules keep the way: her line is followed from a route's junction box onto
## the sidewalks she walks (`RouteLineRule`), the sidewalk she walks keeps a line with room for her
## (`RouteSidewalkRule`), and nothing stands in the open end of a pacing beat
## (`PacingOpeningRule`). Off the streets no line is flooded, and this one leaves the route's own
## tiles free, which is stricter than asking whether a way round exists: a body or a cost never
## stands on a route tile there even where a detour would have taken her past it. *(inbox #1173 in gray-dolphin:
## "there is no reason to check whether a route is open during game play because it cannot be
## closed to begin with".)*
##
## **One setting, whether a street's route tiles count** (`counts_the_streets`). Off for a judge
## the line rules also ask (`StreetInvalidation`), which asks the cost half too, since it is a line
## rule; on for what the line rules are not asked of, the
## run's scars and the park spoilers, which are not spaced and not given a role and stand where they
## stand: for them a route's sidewalk is ground no body may cover either, so a barricade the run
## left across a route's street is not stood, and one on the far sidewalk is. So is the street she
## starts on (`home_street`, handed in with the setting), every route's first stretch, which the
## tree does not carry because a door is not a route (`RouteTree`): the home is a notch with one
## exit, and a body across that street seals her in whatever the tree's own tiles keep.
##
## It reads the candidate's disc or its line reach and the route's tiles and nothing else: nothing of what is placed
## or stands round it, and nothing kept between asks. With no corridor it asks nothing. Model: no
## node.

var _map: CityMap
var _corridor: Corridor
var _counts_the_streets: bool
## The tiles of the street she starts on, counted where the streets count.
var _home_street: Rect2i

## The rule on `map` for the routes `corridor` runs (null for a walk with no route tree, which this
## refuses nothing on), counting a street's route tiles too where `counts_the_streets`, and with
## them `home_street`, the tiles of the street she starts on (`DawnContext.keeps_the_routes()`'s reading of it,
## the one place it is worked out; empty for a map with no home street).
func _init(map: CityMap, corridor: Corridor, counts_the_streets := false,
		home_street := Rect2i()) -> void:
	_map = map
	_corridor = corridor
	_counts_the_streets = counts_the_streets
	_home_street = home_street

## Overrides StreetRule.allows.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	if _corridor == null:
		return true
	if candidate.obstructs():
		var disc := {}
		EventScheduler.block_a_disc(_map, disc, candidate.body_at(), candidate.blocking_radius())
		for tile: Vector2i in disc:
			if _is_route_ground(tile):
				return false
	return _counts_the_streets or not candidate.counts_against_the_line() \
			or not _denies_a_route_off_the_streets(candidate)

## **Whether a row that counts against her line denies a tile a route runs along off the
## streets**, at its line reach (`EventDef.line_reach()`, a pacing row at the ground its beat never
## leaves free, `EventPlan.denies()`): the cost half of this rule, beside the body half. Off the
## streets no line is flooded, as on a street (`RouteLineRule`, `RouteSidewalkRule`); the route's
## own tiles there stay free of cost, which is stricter than asking whether a free way round exists.
func _denies_a_route_off_the_streets(candidate: EventPlan) -> bool:
	var reach := candidate.line_reach()
	if reach <= 0.0:
		return false
	var centre := candidate.walks()[0] if candidate.walks_a_beat() else candidate.placed_at()
	var from := _map.world_to_tile(centre - Vector2.ONE * reach)
	var to := _map.world_to_tile(centre + Vector2.ONE * reach)
	for y in range(from.y, to.y + 1):
		for x in range(from.x, to.x + 1):
			var tile := Vector2i(x, y)
			if _corridor.carries_a_route(tile) and is_ground_off_the_street(_map, tile) \
					and candidate.denies(_map.tile_to_world(tile), reach):
				return true
	return false

## Whether a body may not cover `tile`: a route runs along it, or the streets count and it is the
## street she starts on; and it is open today and, unless the streets count, no street's.
func _is_route_ground(tile: Vector2i) -> bool:
	if _counts_the_streets:
		return (_corridor.carries_a_route(tile) or _home_street.has_point(tile)) \
				and _map.is_open(tile)
	return _corridor.carries_a_route(tile) and is_ground_off_the_street(_map, tile)

## **Walkable today and not part of a street**: a park, a square, an alley, a courtyard, a
## precinct's own ground. A carriageway is walkable and is not a way off a street, which is why
## this asks `CityMap.is_street()` rather than only `CityMap.is_open()`. Public because a pacing
## beat's way out is the same ground (`StreetInvalidation._a_side_route_opens_off()`), and one
## reading asked twice is stated once.
static func is_ground_off_the_street(map: CityMap, tile: Vector2i) -> bool:
	return map.is_open(tile) and not map.is_street(tile)
