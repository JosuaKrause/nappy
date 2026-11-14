class_name UnitScopeRule
extends StreetRule
## **A field kept clear stays on ground the drawing unit can see**: a row that keeps its field clear
## (`EventPlan.keeps_its_field_clear()`, a lethal row with a place) is refused ground from which its
## field (`EventDef.field_reach()`) would reach a unit that is neither the unit drawing nor one
## touching it (`DayUnits.touches()`).
##
## The events skill's contract, "nothing else happens inside a lethal event's field", is asked of
## a unit's draw against only what it can see: the dawn's plans, its own draws and the touching
## units' (`UnitDraw`). So it must be impossible for a field to reach ground the draw cannot see,
## and this rule is what makes it so: then every event that could stand in a lethal field is in a
## unit touching the lethal row's, and the two draws are ordered and see each other.
##
## Asked after the day's rules (`RuledLocationGround`'s `also`), which have given the candidate its
## role already, so a wall, off the routes by construction, keeps nothing clear and is never
## refused here. `UnitDraw` says which unit draws before each (`look_from()`). Model: no node.

var _units: DayUnits
var _looking_from: PlacementUnit = null

func _init(units: DayUnits) -> void:
	_units = units

## The unit whose draw asks next.
func look_from(unit: PlacementUnit) -> void:
	_looking_from = unit

## Overrides StreetRule.allows. False where `candidate` keeps its field clear and a unit within
## its field (`DayUnits.reached_by()`) is neither the unit looked from nor one touching it; true
## while no unit has been looked from.
func allows(candidate: EventPlan, _tile: Vector2i,
		_placed: Array[EventPlan], _around: Array[EventPlan]) -> bool:
	if _looking_from == null or not candidate.keeps_its_field_clear():
		return true
	for unit in _units.reached_by(candidate, candidate.row().field_reach()):
		if unit != _looking_from and not _units.touches(_looking_from, unit):
			return false
	return true
