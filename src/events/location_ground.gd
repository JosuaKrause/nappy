class_name LocationGround
extends RefCounted
## **What the dawn draw asks of the day it places into** (`LocationDraw`): the event a row would be at
## a location, if the row fits there and the day's rules leave it valid, and how much the location
## weighs the row. The draw decides what each location holds; this answers for the day's ground, so
## the draw is handed it (dependency injection) and a test hands a stand-in holding the answers it
## sets. The day's own is `EventScheduler.JudgedLocationGround`. Every method is to be overridden.

## The event `def` would be at `location`, stood on a tile of the location it fits on, or null where
## it fits nowhere there or the day's rules leave it invalid given what already stands.
func offer(_def: EventDef, _location: Location) -> EventScheduler.Planned:
	assert(false, "LocationGround.offer() is overridden by every implementation")
	return null

## How many times over `location` weighs `def` against its view bag's weight for it: 1 for an
## ordinary location (the player's "yes" to a weight per location, issue #1185).
func scale(_def: EventDef, _location: Location) -> float:
	assert(false, "LocationGround.scale() is overridden by every implementation")
	return 1.0

## Stands `plan` in the day, so what is offered after it is asked with it standing.
func stand(_plan: EventScheduler.Planned) -> void:
	assert(false, "LocationGround.stand() is overridden by every implementation")
