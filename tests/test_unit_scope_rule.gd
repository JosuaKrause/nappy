extends RefCounted
## `UnitScopeRule`, a field kept clear held to the ground the drawing unit can see: a lethal row
## that keeps its field clear is refused where its field reaches a unit that does not touch the
## one drawing, and allowed where it reaches only that unit and units touching it; a row that keeps
## no field clear (a cafe, or the lethal row as a wall) is never refused.
##
## Run with a stand-in for the day's units (`_Units`: the units a field reaches and which touch,
## set by hand); the units are real (`PlacementUnit`, state) and the rows the catalogue's, as
## plans with a role given.

func run(t: TestRunner) -> void:
	var drawing := _unit(0)
	var beside := _unit(1)
	var far := _unit(3)
	var units := _Units.new()
	units.touching_pairs = [[drawing, beside]]
	var rule := UnitScopeRule.new(units)
	rule.look_from(drawing)
	var lorry := EventCatalogue.by_id("reversing_lorry")
	t.check(lorry.hard_fail and lorry.pursuit == null,
			"the reversing lorry is lethal and pursues nothing, the row this needs")
	var lethal := EventPlan.new(lorry, Vector2(100, 100))
	lethal.give_role(GameEnums.BlockerRole.FRICTION)
	units.reached = [drawing, beside] as Array[PlacementUnit]
	t.check(rule.allows(lethal, Vector2i.ZERO, NONE, NONE),
			"a lethal field reaching only the drawing unit and one touching it is allowed")
	units.reached = [drawing, beside, far] as Array[PlacementUnit]
	t.check(not rule.allows(lethal, Vector2i.ZERO, NONE, NONE),
			"one reaching a unit that does not touch the drawing unit is refused")
	t.check(units.asked_reach == lorry.field_reach(),
			"asked with the row's whole field (%.0fpx)" % units.asked_reach)
	var as_a_wall := EventPlan.new(lorry, Vector2(100, 100))
	as_a_wall.give_role(GameEnums.BlockerRole.WALL)
	t.check(rule.allows(as_a_wall, Vector2i.ZERO, NONE, NONE),
			"the same row as a wall keeps nothing clear, and is allowed")
	var cafe := EventPlan.new(EventCatalogue.by_id("cafe_tables"), Vector2(100, 100))
	cafe.give_role(GameEnums.BlockerRole.FRICTION)
	t.check(rule.allows(cafe, Vector2i.ZERO, NONE, NONE), "as a row with no lethal field is")
	rule.look_from(far)
	units.reached = [far] as Array[PlacementUnit]
	t.check(rule.allows(lethal, Vector2i.ZERO, NONE, NONE),
			"and the unit it is asked from is the last one it was told of")

const NONE: Array[EventPlan] = []

class _Units extends DayUnits:
	## What every field reaches, as the check sets it.
	var reached: Array[PlacementUnit] = []
	## `[a, b]` pairs that touch, both ways.
	var touching_pairs: Array = []
	## The reach the rule last asked with.
	var asked_reach := 0.0

	## Overrides DayUnits.reached_by.
	func reached_by(_plan: EventPlan, reach: float) -> Array[PlacementUnit]:
		asked_reach = reach
		return reached

	## Overrides DayUnits.touches.
	func touches(a: PlacementUnit, b: PlacementUnit) -> bool:
		for pair: Array in touching_pairs:
			if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
				return true
		return false

static func _unit(x: int) -> PlacementUnit:
	var tiles := Rect2i(Vector2i(x * CityMap.period(), 0), Vector2i.ONE * Tuning.STREET_WIDTH)
	var none: Array[Location] = []
	return PlacementUnit.new(PlacementUnit.Kind.JUNCTION, tiles, Rect2(), none, 1)
