class_name UnitBags
extends RefCounted
## **The bag a unit draws from** (`UnitDraw`): the unit draw is handed this, so which bag a unit
## draws from is a setting of the walk and not the draw's own business. The day's fills answer it,
## a fresh bag for each unit of the fill of its view and ground (`UnitFills`); a test hands a
## stand-in. Model: no node. Every method is to be overridden.

## The bag `unit` draws from.
func bag_for(_unit: PlacementUnit) -> ViewBag:
	assert(false, "UnitBags.bag_for() is overridden by every implementation")
	return null
