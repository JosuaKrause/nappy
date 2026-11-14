class_name LocationDraw
extends RefCounted
## **The day's locations drawn at dawn, each from its view's bag** (inbox #1185 in gentle-owl; `docs/EVENTS.md`,
## "The three views and the placement order"): every location still open is filled by one draw from
## the bag of its view (`ViewBag`), the empty event among the marbles, and what is drawn is what
## stands there, with no rejection: **a row the day's ground leaves invalid at the location is not
## considered** (`LocationGround.offer()`, today's placement rules deciding, as the player said:
## "which events make which others invalid on the same street -- this is what your current rules
## accomplish. the same applies still"), and a row that has stood as many times as the day's caps
## let it is not either (the orchestrator's reading of fork 5(b), open to correction). Each row's
## share is the location's own weight times the bag's (`LocationGround.scale()`).
##
## **Every location is drawn once, at dawn**, by the day's plan
## (`DawnDraw`, a phase of `EventScheduler.build_day()`), before
## she can move, so a retry draws the same day. The locations are drawn in the day's order
## (`DayLocations.drawing_order()`), so a street's later locations draw with its earlier draws
## standing: the draw keeps its own list of what it has placed, handed to the judge after the plans
## it was given (`draw_all()`'s `among`). A row handed to her walk is drawn as any other and kept
## with no position, for her walk to site (`_as_drawn()`).
##
## Handed the day's locations, the three bags (`view -> ViewBag`), the rows the bags' marbles name
## (`id -> EventDef`), the day's ground, and the day's caps (`id -> how many may stand`, a row not
## named having none). Model: no node.

var _locations: DayLocations
var _bags: Dictionary
var _rows: Dictionary
var _ground: LocationGround
var _caps := {}
var _stood := {}

func _init(locations: DayLocations, bags: Dictionary, rows: Dictionary, ground: LocationGround,
		caps: Dictionary) -> void:
	_locations = locations
	_bags = bags
	_rows = rows
	_ground = ground
	_caps = caps

## **Draws every open location**, its order shuffled within each street on `rng`, each judged among
## `among`, the day's plans so far, and what the draw has placed since; answers the events placed, in
## the order drawn, a row handed to her walk among them with no position. The day's plan is the
## caller's to add them to.
func draw_all(rng: RandomNumberGenerator, among: Array[EventPlan]) -> Array[EventPlan]:
	var judged_among := among.duplicate()
	var placed: Array[EventPlan] = []
	for location in _locations.drawing_order(rng):
		if not location.is_available() or location.is_taken() or location.is_drawn():
			continue
		var plan := _as_drawn(_draw(location, judged_among))
		_locations.record(location, plan)
		if plan:
			judged_among.append(plan)
			_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
			placed.append(plan)
	return placed

## One location's draw, judged among `among`: the event placed, or null for the empty event.
func _draw(location: Location, among: Array[EventPlan]) -> EventPlan:
	var bag: ViewBag = _bags.get(location.view())
	if bag == null:
		return null
	var offered := {}
	var accepts := func(id: String) -> bool:
		var def: EventDef = _rows[id]
		if _caps.has(id) and int(_stood.get(id, 0)) >= int(_caps[id]):
			return false
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
