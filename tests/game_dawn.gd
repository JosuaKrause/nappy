class_name GameDawn
extends RefCounted
## **A dawn planned the way the game plans one, for a suite or a probe that plans a day by hand**:
## made over what every dawn has (its spec, the stream its seed is read off and the map), told
## only what the test's day differs in, and planned with `plan()`. What is not said is what a
## plain day has: every calm area unused (`CalmAreas.of()`), the mast sites worked out on the map
## as it stands (`MastSites.compute()`), the route tree the city grows for the spec's day
## (`RouteTree.for_day()`), nothing spent, no scars, no heat, no doors, nothing standing, no trace
## and no roadblock row. A helper, not a suite: the runner loads only `test_*.gd`.
##
## **The one place under `tests/` that knows how a dawn is handed its inputs**, so a change to
## that reaches the suites and the probes through this file.

var _spec: DaySpec
var _rng: RandomNumberGenerator
var _map: CityMap
var _calm: CalmAreas = null
var _masts: Array[MastSites.Site] = []
## Whether `masts()` was called: an empty list said is no mast, and none said is the map's own.
var _masts_are_said := false
var _spent: Array[String] = []
var _scars: Array[Dictionary] = []
var _walk: RouteSource = null
var _heat := 0
var _doors := PackedVector2Array()
var _standing: Array[EventPlan] = []
var _trace: RunTrace = null
var _roadblock: EventDef = null

## The dawn of the walk `spec` describes on `map`, its seed the one `rng` was made with.
static func of(spec: DaySpec, rng: RandomNumberGenerator, map: CityMap) -> GameDawn:
	var dawn := GameDawn.new()
	dawn._spec = spec
	dawn._rng = rng
	dawn._map = map
	return dawn

## The day's calm areas, where the test's are not `CalmAreas.of(map)`.
func calm(areas: CalmAreas) -> GameDawn:
	_calm = areas
	return self

## The run's mast sites, where the test worked them out once or wants none.
func masts(sites: Array[MastSites.Site]) -> GameDawn:
	_masts = sites
	_masts_are_said = true
	return self

## The one-shots the run has spent.
func spent(one_shots: Array[String]) -> GameDawn:
	_spent = one_shots
	return self

## The scars the run left.
func scars(left: Array[Dictionary]) -> GameDawn:
	_scars = left
	return self

## The walk the day is placed against, where it is not the tree the city grows for the day.
func on(walk: RouteSource) -> GameDawn:
	_walk = walk
	return self

## The run's heat.
func heat(progress: int) -> GameDawn:
	_heat = progress
	return self

## Where today's region-door bodies stand.
func doors(at: PackedVector2Array) -> GameDawn:
	_doors = at
	return self

## What stands whatever the dawn plans: the seals and the region wall's bodies.
func standing(bodies: Array[EventPlan]) -> GameDawn:
	_standing = bodies
	return self

## Where the planning writes its account.
func traced(to: RunTrace) -> GameDawn:
	_trace = to
	return self

## The row the roadblock phase stands beside the day's routes.
func roadblock(row: EventDef) -> GameDawn:
	_roadblock = row
	return self

## Plans the dawn and answers its plan.
func plan() -> DayEvents:
	return EventScheduler.build_day(_spec, _rng, _map, _calm if _calm else CalmAreas.of(_map),
			_masts if _masts_are_said else MastSites.compute(_map), _spent, _scars,
			_walk if _walk else RouteTree.for_day(_map, _spec.day_number()), _heat, _doors,
			_standing, _trace, _roadblock)
