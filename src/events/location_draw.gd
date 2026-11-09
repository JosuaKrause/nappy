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
## **Which rows a draw stands is its configuration** (`kept`, a row -> whether this draw stands
## it): the dawn sweeps every location in the day's order and stands only the rows that block the
## way (`draw_all()`), so every body stands before the walk and is judged by every dawn rule; the
## walk then draws each location left open as she comes near it (`WalkDraw`, `draw()`, `begin()`),
## accepting only the rows that block nothing (gray-dolphin #1173 30: "a blocking event is never
## placed"), so a street's later locations draw with its earlier draws standing, and what the walk
## stands besides (`judge_against()`).
##
## **A walk's caps are a rate** (`spread`): a row's cap is spread over the locations the walk may
## draw by how likely each is to draw the row (its share of the location's bag times the location's
## weight for it, `LocationGround.scale()`), so once the walk has drawn locations holding a share of
## that chance a row may have stood that share of its cap, rounded up or down at random once per row
## on `rng`. The dawn spent a cap over the whole city as each location's chance came up, and so does
## this (the orchestrator's reading, open to the player's overturn).
##
## Handed the day's locations, the three bags (`view -> ViewBag`), the rows the bags' marbles name
## (`id -> EventDef`), the day's ground, the day's caps (`id -> how many may stand`, a row not named
## having none), which rows it stands (every row where `kept` is not given), and for a walk whether
## its caps are spread over the locations open when it is made, and the stream their rounding is
## drawn on. Model: no node.

var _locations: DayLocations
var _bags: Dictionary
var _rows: Dictionary
var _ground: LocationGround
var _caps := {}
var _stood := {}
var _kept := Callable()
var _spread := false
## Per capped row, the fraction its running cap is rounded on (`_at_its_cap()`).
var _offsets := {}
## Per capped row, its chance over every location open when the draw was made, and over those drawn.
var _chance := {}
var _chance_drawn := {}

func _init(locations: DayLocations, bags: Dictionary, rows: Dictionary, ground: LocationGround,
		caps: Dictionary, kept := Callable(), spread := false,
		rng: RandomNumberGenerator = null) -> void:
	_locations = locations
	_bags = bags
	_rows = rows
	_ground = ground
	_caps = caps
	_kept = kept
	_spread = spread
	if _spread:
		var ids := _caps.keys()
		ids.sort()
		for id: String in ids:
			_offsets[id] = rng.randf() if rng else 0.5
			_chance[id] = 0.0
			_chance_drawn[id] = 0.0
		for location in _locations.open_locations():
			var chances := _chances_at(location)
			for id: String in chances:
				_chance[id] = float(_chance[id]) + float(chances[id])

## **Sweeps every open location in the day's order** (`DayLocations.drawing_order()`, on `rng`),
## each drawn whole from its bag as any draw is, and stands what it drew only where this draw keeps
## the row; a location that drew another row, or nothing, is left open for the walk. What the dawn
## does with the rows that block the way.
func draw_all(rng: RandomNumberGenerator) -> void:
	for location in _locations.drawing_order(rng):
		var asking := _begin(location, false)
		if asking == null:
			continue
		while not asking.step():
			pass
		var drawn := asking.drawing.drawn
		var plan: EventScheduler.Planned = null if drawn == ViewBag.EMPTY else asking.offered[drawn]
		if plan == null:
			continue
		_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
		if _keeps(plan.def):
			plan = _as_drawn(plan)
			_locations.record(location, plan)
			_ground.stand(plan)

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
	return _begin(location, true)

## `begin()`, refusing a row this draw does not keep where `only_kept`.
func _begin(location: Location, only_kept: bool) -> Asking:
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
		if (only_kept and not _keeps(_rows[id])) or _at_its_cap(id):
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
## stands it, and answers it: null for the empty event, a row handed to her walk unplaced
## (`_as_drawn()`).
func finish(asking: Asking) -> EventScheduler.Planned:
	while not asking.step():
		pass
	var drawn := asking.drawing.drawn
	var plan: EventScheduler.Planned = null if drawn == ViewBag.EMPTY else asking.offered[drawn]
	if plan:
		plan = _as_drawn(plan)
	_locations.record(asking.location, plan)
	if _spread:
		var chances := _chances_at(asking.location)
		for id: String in chances:
			_chance_drawn[id] = float(_chance_drawn[id]) + float(chances[id])
	if plan:
		_ground.stand(plan)
		_stood[plan.row_id()] = int(_stood.get(plan.row_id(), 0)) + 1
	return plan

## `plan` as a location holds it: a row handed to her walk (`EventDef.is_handed_to_her_walk()`, the
## poster crew) with no position (`EventScheduler.owed_to_her_walk()`), for her walk to site.
func _as_drawn(plan: EventScheduler.Planned) -> EventScheduler.Planned:
	if plan.def.is_handed_to_her_walk():
		return EventScheduler.owed_to_her_walk(plan)
	return plan

## Whether this draw stands `def`'s row.
func _keeps(def: EventDef) -> bool:
	return not _kept.is_valid() or bool(_kept.call(def))

## Whether row `id` has stood as many times as its cap lets it yet: the day's cap, or for a walk the
## cap's share of the row's chance the locations drawn so far held (`spread`).
func _at_its_cap(id: String) -> bool:
	if not _caps.has(id):
		return false
	var most := int(_caps[id])
	if _spread and float(_chance[id]) > 0.0:
		most = mini(most, floori(float(_caps[id]) * float(_chance_drawn[id]) / float(_chance[id])
				+ float(_offsets[id])))
	return int(_stood.get(id, 0)) >= most

## Each capped row this draw keeps -> its chance at `location`: its share of the location's bag
## times the location's weight for it.
func _chances_at(location: Location) -> Dictionary:
	var chances := {}
	var bag: ViewBag = _bags.get(location.view())
	if bag == null:
		return chances
	for id: String in _chance:
		if not _keeps(_rows[id]):
			continue
		var share := bag.share_of(id)
		if share > 0.0:
			chances[id] = share * _ground.scale(_rows[id], location)
	return chances

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
