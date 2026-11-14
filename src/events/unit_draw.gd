class_name UnitDraw
extends RefCounted
## **The day's units drawn one at a time, each after every touching unit of lower rank**
## (`PlacementUnit`, `DayUnits`): what makes a unit's draw the same whatever order the units are
## asked for in, and so whatever her path. *(The player, to the proposal of drawing a whole street
## at once, seeded by the day and the street, so a street holds the same events whatever her path:
## "agree on all design review points. let's do it", inbox #1268 in olive-ferret.)*
##
## A unit's draw reads four things, and nothing else: the map and the day as the dawn left them
## (through the judge it draws with), the dawn's plans (`dawn`, a list copied when the dawn made
## the draw), its own stream and rank, and the plans drawn by the units touching it. Before a unit
## draws, every undrawn touching unit of lower rank draws first, each after its own, so when it
## draws, the touching units drawn are exactly those of lower rank, whichever she came near first;
## by induction over the ranks, every unit's draw is a function of the dawn and the seed alone,
## which is what drawing every unit at dawn in rank order gives.
##
## Drawing one unit: its locations in an order of its own stream, a street's three sections first
## (`StreetLocations` keeps a row that takes its section drawn before the sidewalks it takes), the
## rest shuffled, so no location of a unit always has first pick; a fresh bag per view the unit
## has a location in, of the view's fill, on the unit's stream (`ViewBag`), so what a far unit
## drew changes nothing here; at most one of a row in the unit (`LocationDraw.draw()`). Model: no
## node.

var _units: DayUnits
var _drawing: LocationDraw
var _fills := {}
var _dawn: Array[EventPlan] = []

## `units` the day's units; `drawing` draws one unit's locations (`LocationDraw`); `fills` the
## three views' bag fills (`view -> {marble -> count}`, `EventScheduler.view_fills()`); `dawn` the
## plans the dawn placed, copied.
func _init(units: DayUnits, drawing: LocationDraw, fills: Dictionary,
		dawn: Array[EventPlan]) -> void:
	_units = units
	_drawing = drawing
	_fills = fills
	_dawn = dawn.duplicate()

## The day's units the draw draws.
func units() -> DayUnits:
	return _units

## **The unit that may draw now on the way to drawing `unit`**: `unit` itself where no undrawn
## unit touching it has a lower rank, else the same question asked of the lowest-ranked such unit.
## Null where `unit` is drawn. Each step lowers the rank, so it ends, on a unit every touching unit
## of lower rank of which is drawn: the one condition a draw has.
func _next_towards(unit: PlacementUnit) -> PlacementUnit:
	if unit.is_drawn():
		return null
	var at := unit
	var lower := _lowest_waited_for(at)
	while lower != null:
		at = lower
		lower = _lowest_waited_for(at)
	return at

## **Draws one unit, the one `_next_towards(unit)` names**, and answers what it placed, in the
## order drawn, a row handed to her walk among them unplaced. Empty where `unit` is drawn.
func draw_one_towards(unit: PlacementUnit) -> Array[EventPlan]:
	var next := _next_towards(unit)
	if next == null:
		var none: Array[EventPlan] = []
		return none
	return _draw_alone(next)

## **Draws `unit` now**, after every unit it waits for: `draw_one_towards()` until `unit` is drawn.
## Answers everything placed, in the order drawn.
func draw(unit: PlacementUnit) -> Array[EventPlan]:
	var placed: Array[EventPlan] = []
	while not unit.is_drawn():
		placed.append_array(draw_one_towards(unit))
	return placed

## The lowest-ranked undrawn unit touching `unit` that draws before it, or null where none does.
func _lowest_waited_for(unit: PlacementUnit) -> PlacementUnit:
	for other in _units.touching(unit):
		if not other.is_drawn() and other.draws_before(unit):
			return other
	return null

## Draws `unit`, every touching unit of lower rank drawn already.
func _draw_alone(unit: PlacementUnit) -> Array[EventPlan]:
	var among: Array[EventPlan] = _dawn.duplicate()
	for other in _units.touching(unit):
		if other.is_drawn():
			among.append_array(other.drawn())
	var rng := unit.stream()
	var order := _order_of(unit.locations(), rng)
	var bags := {}
	for location in order:
		var view := location.view()
		if bags.has(view) or not _fills.has(view):
			continue
		bags[view] = ViewBag.new(_fills[view], hash("%d:%s:bag:%d" % [rng.seed, unit.name(), view]))
	var placed := _drawing.draw(order, bags, among)
	unit.record_draw(placed)
	return placed

## **A unit's locations in the order it draws them**: a street's sections first, in their order
## along it, so a row that takes its section is drawn before the sidewalks it takes; then every
## other location, shuffled on `rng` (Fisher-Yates), so with one of a row per unit the first
## location in map order does not always have first pick of every row.
static func _order_of(locations: Array[Location], rng: RandomNumberGenerator) -> Array[Location]:
	var order: Array[Location] = []
	var rest: Array[Location] = []
	for location in locations:
		if location.kind() == Location.Kind.SECTION:
			order.append(location)
		else:
			rest.append(location)
	for i in range(rest.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var kept := rest[i]
		rest[i] = rest[j]
		rest[j] = kept
	order.append_array(rest)
	return order
