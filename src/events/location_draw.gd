class_name LocationDraw
extends RefCounted
## **The day's locations drawn, each from its view's bag** (inbox #1185; `docs/EVENTS.md`,
## "The three views and the placement order"): a location still open is filled by one draw from
## the bag of its view (`ViewBag`), the empty event among the marbles, and what is drawn is what
## stands there, with no rejection: **a row the day's ground leaves invalid at the location is not
## considered** (`LocationGround.offer()`, today's placement rules deciding, as the player said:
## "which events make which others invalid on the same street -- this is what your current rules
## accomplish. the same applies still"), and a row that has stood as many times as the day's caps
## let it is not either (the orchestrator's reading of fork 5(b), open to correction). Each row's
## share is the location's own weight times the bag's (`LocationGround.scale()`).
##
## A location is drawn as she walks near it (`WalkDraw`), so a street's later locations draw with
## its earlier draws standing, and what the walk stands besides (`judge_against()`).
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

## **Draws `location`**, if it is still open, and answers the event placed there, or null for the
## empty event or a location already drawn or taken.
func draw(location: Location) -> EventScheduler.Planned:
	if not location.is_available() or location.is_taken() or location.is_drawn():
		return null
	var plan := _draw(location)
	_locations.record(location, plan)
	if plan:
		_ground.stand(plan)
		_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
	return plan

## Hands the day's ground the walk it now judges against (`LocationGround.judge_against()`).
func judge_against(walk: WalkEvents) -> void:
	_ground.judge_against(walk)

func _draw(location: Location) -> EventScheduler.Planned:
	var bag: ViewBag = _bags.get(location.view())
	if bag == null:
		return null
	var offered := {}
	var accepts := func(id: String) -> bool:
		var def: EventDef = _rows[id]
		if _caps.has(id) and int(_stood.get(id, 0)) >= int(_caps[id]):
			return false
		var plan := _ground.offer(def, location)
		offered[id] = plan
		return plan != null
	var scale := func(id: String) -> float:
		return _ground.scale(_rows[id], location)
	var drawn := bag.draw(accepts, scale)
	return null if drawn == ViewBag.EMPTY else offered[drawn]
