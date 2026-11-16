class_name SentAhead
extends Resource
## **How the director sends a row ahead of her on an ordinary day** (`EventDef.send_ahead()`): the
## dog walker, the police patrol and the military convoy, drawn when she is close by and put just
## ahead of her on the street she is walking. *(inbox #1460: "neither of these should be drawn at
## the beginning. they all should be drawn when the player is close by to guarantee an encounter",
## "just spawn in the car just ahead of the player? then you guarantee an encounter", "the same for
## the dog walker and the convoy".)*
##
## A row carrying one is a marble of her route's bag (`EventDirector`) and is drawn by no unit
## (`EventDef.is_drawn_by_units()`). The catalogue row stays `MAP`: whatever else places it (the
## escape's bag, a scene recipe, a happening) reads none of this.
##
## Data, a value type as `DaySwitch` is.

## Whether it is warned of first: its screen-edge badge alone for its own second, then created
## just out of sight in its lane (the convoy, as day 13's column is). False for a row created at once
## (the dog walker, slower than a walk; the patrol, warned the way a car warns).
@export var warned := false
## Whether it may come from either end of her street, a coin flip on the director's stream, so that
## half of them overtake her from behind. False for every row the director sends: each comes toward
## her, "just ahead of the player" (inbox #1460). A convoy from behind her, faster than her walk and
## loud for as long as she can see it, costs well over the meter's length to a her who walks on.
@export var from_either_end := false

## **Created at once just ahead of her, coming toward her** (the dog walker down her sidewalk, the
## patrol down the carriageway lane that drives toward her): no warning first, and never from
## behind her.
static func at_once() -> SentAhead:
	return SentAhead.new()

## **Warned of first in the lane beside her** (the convoy): its badge alone for its own second, then
## created just out of sight up the lane ahead of her, as day 13's column is, driving toward her.
static func warned_first() -> SentAhead:
	var sent := SentAhead.new()
	sent.warned = true
	return sent

## Whether it is warned of first (`warned`).
func is_warned_first() -> bool:
	return warned

## Whether it may come from either end of her street (`from_either_end`).
func comes_from_either_end() -> bool:
	return from_either_end
