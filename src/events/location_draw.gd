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
	var asking := begin(location)
	if asking == null:
		return null
	while not asking.step():
		pass
	return finish(asking)

## **The same draw, a step at a time** (`Asking.step()`), or null for a location that is not open or
## whose view has no bag: what a walk spreads over ticks. A step is a marble taken from the bag or one
## candidate of the offer it asks for (`LocationGround.begin_offer()`), since one offer may ask a row
## at every tile of the location. Nothing is recorded or stood until
## `finish()`, so a location part-way drawn holds nothing that could stream in.
func begin(location: Location) -> Asking:
	if not location.is_available() or location.is_taken() or location.is_drawn():
		return null
	var bag: ViewBag = _bags.get(location.view())
	if bag == null:
		return null
	var asking := Asking.new(location)
	# The offers go into a dictionary the draw shares, not into `asking`: a closure holding
	# `asking` that `asking` holds back would be a cycle nothing frees.
	var offered := asking.offered
	var offers := {}
	var accepts := func(id: String) -> Variant:
		if _caps.has(id) and int(_stood.get(id, 0)) >= int(_caps[id]):
			offers.erase(id)
			return false
		var made: LocationGround.Offer = offers.get(id)
		if made == null:
			made = _ground.begin_offer(_rows[id], location)
			offers[id] = made
		if not made.step():
			return null
		offers.erase(id)
		offered[id] = made.plan
		return made.plan != null
	var scale := func(id: String) -> float:
		return _ground.scale(_rows[id], location)
	asking.drawing = bag.begin(accepts, scale)
	return asking

## **Ends `asking`'s draw**, asking what is left of it at once, records what it drew at its location,
## stands it, and answers it: null for the empty event. A row handed to her walk
## (`EventDef.is_handed_to_her_walk()`, the poster crew) is recorded and stood unplaced
## (`EventScheduler.owed_to_her_walk()`), for her walk to site, as the dawn hands one over.
func finish(asking: Asking) -> EventScheduler.Planned:
	while not asking.step():
		pass
	var drawn := asking.drawing.drawn
	var plan: EventScheduler.Planned = null if drawn == ViewBag.EMPTY else asking.offered[drawn]
	if plan and plan.def.is_handed_to_her_walk():
		plan = EventScheduler.owed_to_her_walk(plan)
	_locations.record(asking.location, plan)
	if plan:
		_ground.stand(plan)
		_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
	return plan

## One location's draw under way: its location, its bag's draw and what each marble asked was
## offered once its offer was made.
class Asking extends RefCounted:
	var location: Location
	var drawing: ViewBag.Drawing
	var offered := {}

	func _init(at: Location) -> void:
		location = at

	## Takes the next step of the draw, and answers whether it is over.
	func step() -> bool:
		return drawing.step()

## Hands the day's ground the walk it now judges against (`LocationGround.judge_against()`).
func judge_against(walk: WalkEvents) -> void:
	_ground.judge_against(walk)
