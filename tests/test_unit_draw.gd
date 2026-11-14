extends RefCounted
## `UnitDraw`, the day's units drawn each after every touching unit of lower rank: three units that
## all touch drawn in every order they can be asked for, the draws and what each is judged among the
## same every time; a unit asked for draws the touching units of lower rank it waits for first, down
## a chain, and is judged among the dawn's plans and the draws of the units touching it only; a
## unit draws once; a street's sections come first in the order it draws its locations; and the
## scope rule is told which unit draws before it does.
##
## Run with stand-ins for what it is handed: the day's units (`_Units`, a touching table set by
## hand), the location draw (`_Drawing`, which records each call and answers one plan for it) and
## the scope rule (`_Scope`, which records whom it was told looks); the units are real
## (`PlacementUnit`, state), each of one location or a street's handful made by hand.

func run(t: TestRunner) -> void:
	_test_every_order_of_asking_draws_the_same(t)
	_test_a_unit_waits_for_the_lower_touching_units_down_a_chain(t)
	_test_a_unit_draws_once(t)
	_test_a_streets_sections_draw_first(t)
	_test_the_scope_rule_is_told_who_draws(t)

const ON := PlacementView.View.ON_THE_ROUTE

class _Units extends DayUnits:
	## Unit name -> the units it touches.
	var table := {}

	## Overrides DayUnits.touching.
	func touching(unit: PlacementUnit) -> Array[PlacementUnit]:
		var found: Array[PlacementUnit] = []
		found.assign(table.get(unit.name(), []))
		found.sort_custom(func(a: PlacementUnit, b: PlacementUnit) -> bool:
			return a.draws_before(b))
		return found

	## Overrides DayUnits.touches.
	func touches(a: PlacementUnit, b: PlacementUnit) -> bool:
		return (table.get(a.name(), []) as Array).has(b)

class _Drawing extends LocationDraw:
	## Location -> the name of its unit.
	var unit_of := {}
	## `[unit name, [the names of the units whose plans it was judged among, "dawn" for the
	## dawn's], the order's locations, the views of its bags]` per call.
	var calls: Array = []
	var cafe := EventCatalogue.by_id("cafe_tables")

	func _init() -> void:
		super(null, {}, null)

	## Overrides LocationDraw.draw.
	func draw(order: Array[Location], bags: Dictionary, among: Array[EventPlan]) -> Array[EventPlan]:
		var seen: Array[String] = []
		for plan in among:
			seen.append(str(unit_of.get(plan.placed_at(), "dawn")))
		var name: String = unit_of[order[0]]
		calls.append([name, seen, order.duplicate(), bags.keys()])
		var plan := EventPlan.new(cafe, order[0].centre())
		unit_of[plan.placed_at()] = name
		var placed: Array[EventPlan] = [plan]
		return placed

class _Scope extends UnitScopeRule:
	var looked: Array[String] = []

	## Overrides UnitScopeRule.look_from.
	func look_from(unit: PlacementUnit) -> void:
		looked.append(unit.name())

## A unit of one junction location at `x` blocks along, and its location in `drawing`.
static func _unit(x: int, drawing: _Drawing, day_seed := 11) -> PlacementUnit:
	var tiles := Rect2i(Vector2i(x * CityMap.period(), 0), Vector2i.ONE * Tuning.STREET_WIDTH)
	var location := Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, Location.Kind.JUNCTION, tiles)
	var locations: Array[Location] = [location]
	var unit := PlacementUnit.new(PlacementUnit.Kind.JUNCTION, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE),
			locations, day_seed)
	drawing.unit_of[location] = unit.name()
	return unit

## `units` lowest rank first.
static func _ranked(units: Array[PlacementUnit]) -> Array[PlacementUnit]:
	var sorted := units.duplicate()
	sorted.sort_custom(func(a: PlacementUnit, b: PlacementUnit) -> bool: return a.draws_before(b))
	return sorted

static func _dawn() -> Array[EventPlan]:
	var dawn: Array[EventPlan] = [EventPlan.new(EventCatalogue.by_id("roadblock"),
			Vector2(-500, -500))]
	return dawn

static func _fills() -> Dictionary:
	return {ON: {"cafe_tables": 1, ViewBag.EMPTY: 1}}

## The calls a draw made, each as its unit and what it was judged among, by rank position.
static func _readable(calls: Array, ranked: Array[PlacementUnit]) -> Array[String]:
	var position := {}
	for i in ranked.size():
		position[ranked[i].name()] = "u%d" % i
	var lines: Array[String] = []
	for call: Array in calls:
		var seen: Array[String] = []
		for name: String in call[1]:
			seen.append(str(position.get(name, name)))
		lines.append("%s among %s" % [position[call[0]], ",".join(seen)])
	return lines

func _test_every_order_of_asking_draws_the_same(t: TestRunner) -> void:
	var orders := [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]
	var readings: Array = []
	for order: Array in orders:
		var drawing := _Drawing.new()
		var made: Array[PlacementUnit] = [_unit(0, drawing), _unit(1, drawing), _unit(2, drawing)]
		var units := _Units.new()
		for unit in made:
			var others: Array[PlacementUnit] = []
			for other in made:
				if other != unit:
					others.append(other)
			units.table[unit.name()] = others
		var draw := UnitDraw.new(units, drawing, _fills(), _dawn())
		for index: int in order:
			draw.draw(made[index])
		readings.append(_readable(drawing.calls, _ranked(made)))
	var alike := true
	for reading: Array in readings:
		alike = alike and reading == readings[0]
	t.check(alike and (readings[0] as Array).size() == 3,
			"three units that all touch, asked for in each of six orders, draw alike (%s)"
			% [readings[0]])
	t.check(readings[0] == ["u0 among dawn", "u1 among dawn,u0", "u2 among dawn,u0,u1"],
			"lowest rank first, each judged among the dawn and the lower ones' draws (%s)"
			% [readings[0]])

func _test_a_unit_waits_for_the_lower_touching_units_down_a_chain(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var ranked := _ranked([_unit(0, drawing), _unit(1, drawing), _unit(2, drawing),
			_unit(3, drawing)] as Array[PlacementUnit])
	var low := ranked[0]
	var mid := ranked[1]
	var high := ranked[2]
	var alone := ranked[3]
	var units := _Units.new()
	units.table = {high.name(): [mid], mid.name(): [high, low], low.name(): [mid]}
	var draw := UnitDraw.new(units, drawing, _fills(), _dawn())
	var placed := draw.draw(high)
	t.check(_readable(drawing.calls, ranked) == ["u0 among dawn", "u1 among dawn,u0",
			"u2 among dawn,u1"], "asked for the highest of a chain, the draw goes down it and "
			+ "comes back up, each judged among the dawn and its touching units only (%s)"
			% [_readable(drawing.calls, ranked)])
	t.check(placed.size() == 3 and low.is_drawn() and mid.is_drawn() and high.is_drawn(),
			"and answers everything it placed (%d)" % placed.size())
	t.check(not alone.is_drawn(), "a unit touching none of them is not drawn")
	draw.draw(alone)
	t.check(_readable(drawing.calls, ranked).back() == "u3 among dawn",
			"and draws alone, among the dawn's plans, when asked for")

func _test_a_unit_draws_once(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var unit := _unit(0, drawing)
	var draw := UnitDraw.new(_Units.new(), drawing, _fills(), _dawn())
	var first := draw.draw(unit)
	var second := draw.draw(unit)
	t.check(first.size() == 1 and second.is_empty() and drawing.calls.size() == 1,
			"a unit asked for twice draws once (%d calls)" % drawing.calls.size())
	t.check(unit.drawn() == first, "and holds what it drew")

func _test_a_streets_sections_draw_first(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var rect := segment.tile_rect()
	var locations: Array[Location] = []
	for section in 3:
		var tiles := Rect2i(rect.position + Vector2i(section * 3, 0), Vector2i(2, rect.size.y))
		locations.append(Location.new(segment, section, tiles, Vector2(tiles.position) * 32.0, ON,
				true, Location.Kind.SECTION))
	for section in 3:
		for side in 2:
			var tiles := Rect2i(rect.position + Vector2i(section * 3, side * 4), Vector2i(2, 2))
			locations.append(Location.new(segment, section, tiles, Vector2(tiles.position) * 32.0,
					ON, true, Location.Kind.SIDEWALK))
	var street := PlacementUnit.new(PlacementUnit.Kind.STREET, rect, Rect2(), locations, 5)
	for location in locations:
		drawing.unit_of[location] = street.name()
	UnitDraw.new(_Units.new(), drawing, _fills(), _dawn()).draw(street)
	var order: Array = drawing.calls[0][2]
	var kinds: Array[int] = []
	var sections: Array[int] = []
	for location: Location in order:
		kinds.append(location.kind())
		if location.kind() == Location.Kind.SECTION:
			sections.append(location.section())
	var sidewalk := Location.Kind.SIDEWALK
	var section_kind := Location.Kind.SECTION
	t.check(kinds == ([section_kind, section_kind, section_kind, sidewalk, sidewalk, sidewalk,
			sidewalk, sidewalk, sidewalk] as Array[int]) and sections == ([0, 1, 2] as Array[int]),
			"a street draws its three sections first, in order along it, then its sidewalks")
	t.check(drawing.calls[0][3] == [ON], "from one bag, of the one view its locations are in")

func _test_the_scope_rule_is_told_who_draws(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var ranked := _ranked([_unit(0, drawing), _unit(1, drawing)] as Array[PlacementUnit])
	var units := _Units.new()
	units.table = {ranked[0].name(): [ranked[1]], ranked[1].name(): [ranked[0]]}
	var scope := _Scope.new(units)
	UnitDraw.new(units, drawing, _fills(), _dawn(), scope).draw(ranked[1])
	t.check(scope.looked == ([ranked[0].name(), ranked[1].name()] as Array[String]),
			"the scope rule is told each unit before it draws, in the order they draw")
