class_name LocationGround
extends RefCounted
## **What the dawn draw asks of the day it places into** (`LocationDraw`): the event a row would be at
## a location, if the row fits there and the day's rules leave it valid, and how much the location
## weighs the row. The draw decides what each location holds; this answers for the day's ground, so
## the draw is handed it (dependency injection) and a test hands a stand-in holding the answers it
## sets. The day's own is `RuledLocationGround`. Every method is to be overridden.
##
## **The judge is a function of what it is handed**: it keeps no plan and stands none. The caller
## hands the plans a candidate is judged among and keeps the list it hands in, adding what it
## accepts.

## The event `def` would be at `location`, stood on a tile of the location it fits on, or null where
## it fits nowhere there or the day's rules leave it invalid among `among`, the plans standing in
## the day so far (the judge also reads the bodies the day stands as sealed ground, which it was
## made with).
func offer(_def: EventDef, _location: Location, _among: Array[EventPlan]) -> EventPlan:
	assert(false, "LocationGround.offer() is overridden by every implementation")
	return null

## How many times over `location` weighs `def` against its view bag's weight for it: 1 for an
## ordinary location (the player's "yes" to a weight per location, inbox #1185 in gentle-owl).
func scale(_def: EventDef, _location: Location) -> float:
	assert(false, "LocationGround.scale() is overridden by every implementation")
	return 1.0
