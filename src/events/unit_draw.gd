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
## **A draw reads a beat her walk laid in its unit or a touching one, and no other plan her walk
## sites.** A beat (day 3's fire, a poster crew, day 11's mast on her route; `WalkSiting`) takes a
## location of the nearest unit on her way that has not drawn, and the unit is told
## (`PlacementUnit.rig()`): its room starts without the location, and it and the units touching it
## are judged among the beat, drawn or not (`PlacementUnit.rigged()`). *(The player: "repeating
## the day has the exact same preconditions. if the player does something differently different
## things might happen. if the player were to do exactly the same everything would behave exactly
## the same. beats are marbles, yes"; inbox #1521 in breezy-magpie.)* So a unit a beat stands in or
## beside draws by her path, on purpose, and every other unit by the dawn and the seed alone. A row
## of one unit reaches another's ground only where the two touch, so no other draw needs the beat.
## A plan the dawn or a unit left with no place is otherwise kept out of what a draw is judged
## among: the dawn's plans are copied without the ones that had no place, and a touching unit's row
## handed to her walk (`EventDef.is_handed_to_her_walk()`) is passed over, since where her walk puts
## it is a beat of the unit it lands in.
##
## **A rigged bag goes in front of the units' draws** (`rig_the_next_draw()`): the rows a mark puts
## on her way, day 6's man shouting and day 7's van, are drawn first by the next unit to draw that
## can stand them, wherever and whenever that draw happens (`MarbleDraw.draw()`). *(The player:
## "the draw doesn't have to happen at the point where she touches the mark. the bag gets the biased
## bag in front (via the chained bags mechanism) and the next draw (whenever that happens) will
## guarantee the shouting man"; inbox #1520 in breezy-magpie.)* It is a `MarbleBag`'s queue, which
## holds nothing until a mark rigs it, so a day no mark rigs draws from the units' own bags alone.
##
## Drawing one unit: one bag, the one the walk's bags answer for the unit (`UnitBags`): on a day a
## fresh bag of the fill of the unit's view (the most permissive of its locations',
## `PlacementUnit.view()`) and kind of ground (`UnitFills`), on the unit's stream (`ViewBag`), so
## what a far unit drew changes nothing here; the marbles drawn from it and laid out in the unit
## (`MarbleDraw.draw()`), a marble drawn before it has a place.
##
## **A walk that is drawn whole before she sets off** (`DaySpec.draws_before_she_sets_off()`) draws
## every unit at once instead (`draw_in_their_order()`), in the order the day's units are in, each
## judged among the dawn's plans and everything drawn before it: the order is total and the same on
## every plan of the same seed, so no rank is asked and no touching unit is pulled first. Model: no
## node.

var _units: DayUnits
var _drawing: MarbleDraw
var _bags: UnitBags
var _dawn: Array[EventPlan] = []
## The bag in front of every unit's own (`rig_the_next_draw()`): rows, empty until a mark rigs it,
## with no ordinary set behind it, so once its rows are drawn it holds nothing again.
var _in_front := MarbleBag.new([], [], 0)
## The plans a unit drew out of the bag in front (`drew_from_the_front()`), as `plan -> true`.
var _from_the_front := {}

## `units` the day's units; `drawing` draws one unit (`MarbleDraw`); `bags` what answers a
## unit's bag (`UnitBags`: on a day, `UnitFills`); `dawn` the plans the dawn placed, copied, a
## plan it left with no place left out (the class comment says why).
func _init(units: DayUnits, drawing: MarbleDraw, bags: UnitBags,
		dawn: Array[EventPlan]) -> void:
	_units = units
	_drawing = drawing
	_bags = bags
	for plan in dawn:
		if plan.is_placed():
			_dawn.append(plan)

## **Rigs the next draws to stand `rows`**: a bag of them goes in front of the units' own
## (`MarbleBag.rig()`), and the next unit to draw draws them first, each where the unit can lay it
## out (`MarbleDraw.draw()`); one the unit cannot stand stays in front for the unit after it. The
## rigged bag holds the rows alone: each unit draws from a bag of its own (`UnitBags`), so there is
## no one bag the rest of a rigged bag could be taken out of, and the player's "the next draw
## (whenever that happens) will guarantee" is the next unit's.
func rig_the_next_draw(rows: Array[EventDef]) -> void:
	var marbles: Array = []
	marbles.append_array(rows)
	_in_front.rig(marbles, marbles.size())

## **Whether `plan` is a row a unit drew out of the bag in front** (`rig_the_next_draw()`) rather than
## out of its own: where a mark's row landed, which the run log records (`EventsAhead`).
func drew_from_the_front(plan: EventPlan) -> bool:
	return _from_the_front.has(plan)

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

## **Draws every undrawn unit now, in the order the day's units are in** (`DayUnits.all()`), each
## judged among the dawn's plans and everything every unit before it in that order drew, a row
## handed to her walk passed over: the draw of a walk that is drawn whole before she sets off
## (`DaySpec.draws_before_she_sets_off()`). The order is total and the same on every plan of the
## same seed, so no rank is asked and no touching unit is pulled first, and a draw may be judged
## among every draw before it however far off, which a route that leaves its street needs
## (`DawnDraw`). Answers everything placed, in the order drawn.
func draw_in_their_order() -> Array[EventPlan]:
	var placed: Array[EventPlan] = []
	var before: Array[EventPlan] = _dawn.duplicate()
	for unit in _units.all():
		if not unit.is_drawn():
			placed.append_array(_draw_among(unit, before))
		for plan in unit.drawn():
			if not plan.row().is_handed_to_her_walk():
				before.append(plan)
	return placed

## Draws `unit`, every touching unit of lower rank drawn already: judged among the dawn's plans, the
## beats her walk laid in it and in every unit touching it, drawn or not, and what the touching
## units drew, a row one of them handed to her walk passed over, which stands where her walk laid it
## as a beat of the unit it landed in.
func _draw_alone(unit: PlacementUnit) -> Array[EventPlan]:
	var among: Array[EventPlan] = _dawn.duplicate()
	among.append_array(unit.rigged())
	for other in _units.touching(unit):
		among.append_array(other.rigged())
		if not other.is_drawn():
			continue
		for plan in other.drawn():
			if not plan.row().is_handed_to_her_walk():
				among.append(plan)
	return _draw_among(unit, among)

## Draws `unit` among `among`, the rigged bag in front first and then the bag the walk's bags answer
## for it, and records what it placed.
func _draw_among(unit: PlacementUnit, among: Array[EventPlan]) -> Array[EventPlan]:
	var rigged_before := _in_front.draws_made()
	var placed := _drawing.draw(unit, _bags.bag_for(unit), among, _in_front)
	# The rows drawn out of the bag in front come first in what a draw answers, in the order drawn.
	for i in mini(_in_front.draws_made() - rigged_before, placed.size()):
		_from_the_front[placed[i]] = true
	unit.record_draw(placed)
	return placed
