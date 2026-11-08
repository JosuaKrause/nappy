class_name WalkEvents
extends RefCounted
## **What the walk's events are, read through one object while she walks it**: the walk's plans in
## the order they stream, what the walk was planned against that a placement made while she walks
## is stated against too — where today's region doors stand and the day's calm areas — and where she
## can get to from home as the walk was planned (`DayReach`).
## `DayEvents` is the day while dawn plans it; this is the walk once it has started.
##
## *(inbox #1156: "have an object that contains the derived information -- don't rederive over
## and over again -- then pass that object around".)* `EventManager` makes one and fills it at every
## walk's start (`take()`); the streaming, what is put in front of her (`EventsAhead`), every
## `EventScheduler.WalkSiting` and the resistance are handed it, and nothing reads the walk's plans
## any other way.
##
## **Its writes are the walk's own**: `take()` at a walk's start, `add()` for a plan placed while she
## walks (a mast queued near her, a place from her route's bag), and `clear()`. A plan being moved
## or spent is the plan's own business, since nothing here is derived from where a plan stands or
## whether it is spent.
##
## **Never saved**: a load starts the walk again from the run's saved inputs.
##
## **The constructor derives nothing**, so a test hands a consumer a stand-in that overrides the
## questions below and answers what the test set (`tests/fake_walk_events.gd`).

var _plans: Array[EventScheduler.Planned] = []
var _calm: CalmAreas = null
var _doors := PackedVector2Array()
var _reach: DayReach = null
var _locations: DayLocations = null

# ------------------------------------------------------------------- writes ---

## Takes `plans` as the walk's whole plan, the very array handed in, planned against `calm` (the
## day's calm areas, or none for a walk that is not a day in the city), with today's region doors
## standing at `doors`, `reach`, where she can get to from home as it was planned (none for a
## walk that is not in the city), and `locations`, the day's locations as dawn laid them out (none
## on a day that laid none out).
func take(plans: Array[EventScheduler.Planned], calm: CalmAreas = null,
		doors := PackedVector2Array(), reach: DayReach = null,
		locations: DayLocations = null) -> void:
	_plans = plans
	_calm = calm
	_doors = doors
	_reach = reach
	_locations = locations

## Adds one plan placed while she walks, after every plan already in the walk.
func add(plan: EventScheduler.Planned) -> void:
	_plans.append(plan)

## Forgets the walk.
func clear() -> void:
	_plans.clear()
	_calm = null
	_doors = PackedVector2Array()
	_reach = null
	_locations = null

# ---------------------------------------------------------------- questions ---

## The walk's plans, sited and unsited, spent and unspent, in the order they stream: the store
## itself rather than a copy, for the streaming's pass over every plan each tick. Read it; the walk
## is written through `add()` alone.
func plans() -> Array[EventScheduler.Planned]:
	return _plans

## Every plan of the walk but `besides`: what a placement is spaced and checked against. The plan
## being placed is never in it, since a row moved off a position it has not been seen at must not
## be spaced against its own old body. `null` leaves nothing out.
func everything_but(besides: EventScheduler.Planned = null) -> Array[EventScheduler.Planned]:
	var others: Array[EventScheduler.Planned] = []
	for plan in _plans:
		if plan != besides:
			others.append(plan)
	return others

## **Whether `point` stands clear of the walk's events** for a figure `her_reach` across: farther
## from every placed, unspent plan than its clearance (`Planned.clearance()`: its body and her shape,
## its field where it carries one, a hard fail's lethal reach), measured from where it stands now.
## A plan placed inside `besides` is not asked: the park cordon's own park, whose people are being
## walked out (`ParkCordon._clear_of_the_day()`).
func is_clear_at(point: Vector2, her_reach: float, besides := Rect2()) -> bool:
	for plan in plans():
		if plan.is_spent() or not plan.is_placed() or besides.has_point(plan.placed_at()):
			continue
		var reach := plan.clearance(her_reach)
		if reach > 0.0 and point.distance_to(plan.where_it_stands_now()) < reach:
			return false
	return true

## Where today's region doors stand: a day's, and empty for every other walk.
func doors() -> PackedVector2Array:
	return _doors

## The day's calm areas as dawn saw them (`CalmAreas`), or null for a walk that is not a day in the
## city: the escape's walks and the building, where nothing is sited while she walks.
func calm() -> CalmAreas:
	return _calm

## Where she can get to from home as the walk was planned (`DayReach`), or null for a walk that is
## not in the city (the building) and before a walk starts.
func reach() -> DayReach:
	return _reach

## The day's locations as dawn laid them out (`DayLocations`): day 13's, whose route-adjacent
## sections the task's swap takes from (`ResistanceDirector._place_the_roadblock_near()`); null on a
## day that laid none out and before a walk starts.
func locations() -> DayLocations:
	return _locations

## **The walk's placed, unspent plans standing inside `area`** (world space), by where each was
## placed: what a section holds, which day 13's swap spends when it puts its roadblock across the
## section (`EventsAhead.swap_in_a_section()`).
func placed_within(area: Rect2) -> Array[EventScheduler.Planned]:
	var found: Array[EventScheduler.Planned] = []
	for plan in _plans:
		if plan.is_placed() and not plan.is_spent() and area.has_point(plan.placed_at()):
			found.append(plan)
	return found
