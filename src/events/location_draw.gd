class_name LocationDraw
extends RefCounted
## **The day's locations drawn at dawn, each from its view's bag** (inbox #1185; `docs/EVENTS.md`,
## "The three views and the placement order"): every location still open is filled by one draw from
## the bag of its view (`ViewBag`), the empty event among the marbles, and what is drawn is what
## stands there, with no rejection: **a row the day's ground leaves invalid at the location is not
## considered** (`LocationGround.offer()`, today's placement rules deciding, as the player said:
## "which events make which others invalid on the same street -- this is what your current rules
## accomplish. the same applies still"), and a row at its `EventDef.max_per_day` is not either, where
## the spec keeps the caps (the orchestrator's reading of fork 5(b), open to correction). Each row's
## share is the location's own weight times the bag's (`LocationGround.scale()`).
##
## The locations are drawn in the day's order (`DayLocations.drawing_order()`), so a street's later
## locations draw with its earlier draws standing. *In this step of the placement they are drawn at
## dawn, not during the walk:* the walk's draws are the next step's.
##
## Handed the day's locations, the three bags (`view -> ViewBag`), the rows the bags' marbles name
## (`id -> EventDef`), the day's ground, and whether the day keeps the caps. Model: no node.

var _locations: DayLocations
var _bags: Dictionary
var _rows: Dictionary
var _ground: LocationGround
var _caps := true
var _stood := {}

func _init(locations: DayLocations, bags: Dictionary, rows: Dictionary, ground: LocationGround,
		caps: bool) -> void:
	_locations = locations
	_bags = bags
	_rows = rows
	_ground = ground
	_caps = caps

## **Draws every open location**, its order shuffled within each street on `rng`, and answers the
## events placed, in the order drawn.
func draw_all(rng: RandomNumberGenerator) -> Array[EventScheduler.Planned]:
	var placed: Array[EventScheduler.Planned] = []
	for location in _locations.drawing_order(rng):
		if not location.is_available() or location.is_taken() or location.is_drawn():
			continue
		var plan := _draw(location)
		_locations.record(location, plan)
		if plan:
			_ground.stand(plan)
			_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
			placed.append(plan)
	return placed

## One location's draw: the event placed, or null for the empty event.
func _draw(location: Location) -> EventScheduler.Planned:
	var bag: ViewBag = _bags.get(location.view())
	if bag == null:
		return null
	var offered := {}
	var accepts := func(id: String) -> bool:
		var def: EventDef = _rows[id]
		if _caps and int(_stood.get(id, 0)) >= def.most_in_a_day():
			return false
		var plan := _ground.offer(def, location)
		offered[id] = plan
		return plan != null
	var scale := func(id: String) -> float:
		return _ground.scale(_rows[id], location)
	var drawn := bag.draw(accepts, scale)
	return null if drawn == ViewBag.EMPTY else offered[drawn]
