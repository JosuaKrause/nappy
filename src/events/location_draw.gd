class_name LocationDraw
extends RefCounted
## **One unit's locations drawn, each from its view's bag** (inbox #1185 in gentle-owl;
## `docs/EVENTS.md`, "The three views and the placement order"): every location still open is filled by one draw from
## the bag of its view (`ViewBag`), the empty event among the marbles, and what is drawn is what
## stands there, with no rejection: **a row the day's ground leaves invalid at the location is not
## considered** (`LocationGround.offer()`, today's placement rules deciding, as the player said:
## "which events make which others invalid on the same street -- this is what your current rules
## accomplish. the same applies still"). Each row's share is the location's own weight times the
## bag's (`LocationGround.scale()`).
##
## **At most one of a row in a unit**, in place of daily caps, since a cap binds whoever draws
## last and so depends on the order the day is drawn in (step 2 of
## `docs/todo/2026-11-11-polite-tapir/placement-by-construction.md`): a unit draws in one call, so
## the rule is a set kept for the length of the call. *The designer's reading, open
## to overturn:* per junction box, per alley and per park or square too, so a square holds one
## street musician.
##
## A unit's locations draw in one call (`UnitDraw`), each judged among what the unit's draw may
## see and what the call has placed since, so a street's later locations draw with its earlier
## draws standing. A row handed to her walk is drawn as any other and kept with no position, for
## her walk to site (`_as_drawn()`).
##
## Handed the day's locations, which record each draw, the rows the bags' marbles name
## (`id -> EventDef`) and the day's ground. Model: no node.

var _locations: DayLocations
var _rows: Dictionary
var _ground: LocationGround

## `locations` records each draw (`DayLocations.record()`); `rows` the rows the bags' marbles name
## (`id -> EventDef`); `ground` the judge.
func _init(locations: DayLocations, rows: Dictionary, ground: LocationGround) -> void:
	_locations = locations
	_rows = rows
	_ground = ground

## **Draws `order`, one unit's locations, each from the bag of its view** (`bags`,
## `view -> ViewBag`), judged among `among`, which grows by each row placed; answers the events
## placed, in the order drawn, a row handed to her walk among them with no position. A location not
## available, taken or already drawn is passed over. **At most one of a row over the call**: a row
## already drawn here is not considered again, a row handed to her walk included. `among` itself is
## left as it was handed.
func draw(order: Array[Location], bags: Dictionary, among: Array[EventPlan]) -> Array[EventPlan]:
	var judged_among := among.duplicate()
	var drawn_here := {}
	var placed: Array[EventPlan] = []
	for location in order:
		if not location.is_available() or location.is_taken() or location.is_drawn():
			continue
		var plan := _as_drawn(_draw(location, bags, judged_among, drawn_here))
		_locations.record(location, plan)
		if plan:
			judged_among.append(plan)
			drawn_here[plan.row_id()] = true
			placed.append(plan)
	return placed

## One location's draw from its view's bag among `bags`, judged among `among`, a row in
## `drawn_here` not considered: the event placed, or null for the empty event.
func _draw(location: Location, bags: Dictionary, among: Array[EventPlan],
		drawn_here: Dictionary) -> EventPlan:
	var bag: ViewBag = bags.get(location.view())
	if bag == null:
		return null
	var offered := {}
	var accepts := func(id: String) -> bool:
		if drawn_here.has(id):
			return false
		var def: EventDef = _rows[id]
		var plan := _ground.offer(def, location, among)
		offered[id] = plan
		return plan != null
	var scale := func(id: String) -> float:
		return _ground.scale(_rows[id], location)
	var drawn := bag.draw(accepts, scale)
	return null if drawn == ViewBag.EMPTY else offered[drawn]

## `plan` as its location holds it: a row handed to her walk (`EventDef.is_handed_to_her_walk()`,
## the poster crew) with no position (`EventScheduler.owed_to_her_walk()`), for her walk to site;
## any other plan, and the empty event, as drawn.
static func _as_drawn(plan: EventPlan) -> EventPlan:
	if plan and plan.row().is_handed_to_her_walk():
		return EventScheduler.owed_to_her_walk(plan)
	return plan
