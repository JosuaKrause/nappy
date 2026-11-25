class_name RouteSpec
extends RefCounted
## **How a row travels, as one value**: whether it moves along a route of its own, how fast, how the
## route is built and how long it is, whether it paces a beat on it, and whether it stops where it
## arrives. A row holds one (`EventDef.route()`); nothing changes it once it exists (a refinement
## returns a new value), so a row's copies share it by reference, and the code that walks a route
## (`EventRouteWalk`, the car, the departure, the investigation, the notice run) is handed it.
## `none()` is a row that stays where it is placed.
##
## **A route is one thing**: a row that moves has a speed and a kind of route, so a speed on a row
## that does not move, or a stop at the end of a route that does not exist, cannot be written. The
## scheduler builds the path (`PlanBuilder.build()`) from the kind and the tiles.

## **How the scheduler builds a moving row's route.**
enum Kind {
	NONE,
	ALONG_STREET,  ## Down the corridor it starts on.
	## **Across the alley it landed in**, built by the instance itself from the alley it stands in
	## (`EventInstance._alley_crossing_path()`), cut to the ground it fits on: `alley_mouse`, placed
	## on the map with no route of its own (`PlanBuilder.build()`'s default case).
	ACROSS_ITS_ALLEY,
}

## The length of a route along its street when none is written, in tiles.
const DEFAULT_TILES := 24

## Whether it moves along a route of its own.
var _moves := false

## How fast it moves, in px/s. The scheduler builds the path.
var _speed := 0.0

## How its route is built.
var _kind := Kind.NONE

## Route length for `ALONG_STREET`, in tiles, at most: a route a unit draws is also bounded by its
## location's run (`Location.run()`, inbox #1460 in silky-lemur: such as the far side of the
## junction box at its street's end, the box itself for a row drawn in a box, or a square's lot), so
## a long row always stops sooner there. A short beat (the shouting man, the chatting mother, 8
## tiles) keeps its length only where the run's edge is that far off: one drawn in a junction box is
## at most 5 tiles, and one on the last two tiles of a street before the box it heads for is 6 or 7.
var _tiles := DEFAULT_TILES

## **Walks its route and turns round at the ends, for ever.**
##
## The difference between a **journey** and a **beat**. A dog walker is going somewhere: sent
## ahead of her (`EventDef.as_sent_ahead()`), it walks down her sidewalk toward her and past her, it
## is gone at the end of its route, and it costs the stretch of sidewalk it owns while you are
## there. A man shouting is *at* a place, and without this the only way to say so is to make him
## stationary, which reads from the street as "it didn't move". A paced event never reaches the end
## of its path, so it never departs and never expires.
var _paces := false

## **Stops where its route ends and stays there for the rest of the day**, instead of driving on
## out of sight as everything else that runs out of route does. The fire engine and day 10's
## neighbor, who stops at the door, are the rows that carry it.
##
## **It is a decision about cost, not about motion** (PLAYTEST-119 24). A standing 26/s field out to
## 340px beside a fire she was led to is the wall the day puts across the street she is on, and the
## answer it asks for is to turn round or go another way. The pair is why a site is only accepted
## where the home and a calm area she has not used stay reachable outside both fields; see
## `WalkSiting`.
##
## Three things in `EventInstance` read it: `_be_done()` neither finishes nor leaves such a row,
## `EventRouteWalk.advance()` stops adding to the distance it has covered (a gait is driven by
## distance, so a parked engine would bob for ever), and `travel_velocity()` answers zero (the
## exclamation mark over her reads that as a closing speed).
var _parks := false

## A row that stays where it is placed.
static func none() -> RouteSpec:
	return RouteSpec.new()

## A route walked at `speed` px/s, built as `kind` says (no kind: the instance's own path).
static func at(speed: float, kind := Kind.NONE) -> RouteSpec:
	assert(speed > 0.0, "a route is walked at a speed; a row that stays put is none()")
	var spec := RouteSpec.new()
	spec._moves = true
	spec._speed = speed
	spec._kind = kind
	return spec

## The same route at most `tiles` tiles long (`ALONG_STREET`).
func up_to_tiles(count: int) -> RouteSpec:
	var spec := _copy()
	spec._tiles = count
	return spec

## The same route walked as a beat: to and fro, for ever.
func pacing() -> RouteSpec:
	assert(_moves, "a beat is walked on a route")
	var spec := _copy()
	spec._paces = true
	return spec

## The same route, stopping where it ends and standing there.
func parking_where_it_arrives() -> RouteSpec:
	assert(_moves, "a row that never moves has no end of a route to stop at")
	var spec := _copy()
	spec._parks = true
	return spec

## Whether it moves along a route of its own.
func moves() -> bool:
	return _moves

## How fast it moves, in px/s, or 0 for a row that stays where it is placed.
func speed() -> float:
	return _speed

## How its route is built.
func kind() -> Kind:
	return _kind

## The most tiles a route along its street runs.
func tiles() -> int:
	return _tiles

## Whether it walks its route to and fro rather than once.
func paces_a_beat() -> bool:
	return _paces

## Whether it stops where its route ends and stands there for the rest of the day.
func parks_where_it_arrives() -> bool:
	return _parks

func _copy() -> RouteSpec:
	var spec := RouteSpec.new()
	spec._moves = _moves
	spec._speed = _speed
	spec._kind = _kind
	spec._tiles = _tiles
	spec._paces = _paces
	spec._parks = _parks
	return spec
