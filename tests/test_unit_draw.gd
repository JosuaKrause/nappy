extends RefCounted
## `UnitDraw`, the day's units drawn each after every touching unit of lower rank: three units that
## all touch drawn in every order they can be asked for, the draws and what each is judged among the
## same every time; a unit asked for draws the touching units of lower rank it waits for first, down
## a chain, and is judged among the dawn's plans and the draws of the units touching it only, a
## plan her walk sites never among them; a unit draws once; a unit whose locations are in
## different views draws from the bag of the most permissive of them; and a unit draws from the
## fill of its view and its kind of ground.
##
## Run with stand-ins for what it is handed: the day's units (`_Units`, a touching table set by
## hand), the day's fills (`_Fills`, a fill set by hand for each view and ground, which records
## each ask) and the unit's draw (`_Drawing`, which records each call and answers one plan for
## it, drawing one marble from the bag it is handed); the units are real (`PlacementUnit`, state),
## each of a location or two made by hand, and so are the bags (`ViewBag`).

func run(t: TestRunner) -> void:
	_test_every_order_of_asking_draws_the_same(t)
	_test_a_unit_waits_for_the_lower_touching_units_down_a_chain(t)
	_test_no_draw_is_judged_among_a_plan_her_walk_sites(t)
	_test_a_unit_draws_once(t)
	_test_a_unit_of_mixed_views_draws_from_the_most_permissive_bag(t)
	_test_a_unit_draws_from_the_fill_of_its_view_and_its_ground(t)

const ON := PlacementView.View.ON_THE_ROUTE
const OFF := PlacementView.View.OFF_THE_ROUTE

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

class _Fills extends UnitFills:
	## `Vector2i(view, ground)` -> the fill handed for it.
	var by_view_and_ground := {}
	## `Vector2i(view, ground)` per ask, in the order asked.
	var asked: Array[Vector2i] = []

	func _init(fills: Dictionary) -> void:
		super({}, 1, 1.0, RowGround.Weights.new(), Callable())
		by_view_and_ground = fills

	## Overrides UnitFills.of.
	func of(view: PlacementView.View, ground: PlacementGround.Kind) -> Dictionary:
		var key := Vector2i(view, ground)
		asked.append(key)
		var fill: Dictionary = by_view_and_ground.get(key, {ViewBag.EMPTY: 1})
		return fill

class _Drawing extends MarbleDraw:
	## A plan's place -> the name of the unit that drew it.
	var unit_of := {}
	## `[unit name, [the names of the units whose plans it was judged among, "dawn" for the
	## dawn's], the marble it drew from the bag it was handed, the rows it was judged among]` per
	## call.
	var calls: Array = []
	var cafe := EventCatalogue.by_id("cafe_tables")
	## Unit name -> true for a unit whose draw also hands a poster crew to her walk, with no place.
	var hands_over := {}

	func _init() -> void:
		super(null, {}, null)

	## Overrides MarbleDraw.draw.
	func draw(unit: PlacementUnit, bag: ViewBag, among: Array[EventPlan]) -> Array[EventPlan]:
		var seen: Array[String] = []
		var rows: Array[String] = []
		for plan in among:
			seen.append(str(unit_of.get(plan.placed_at(), "dawn")))
			rows.append(plan.row_id())
		var name := unit.name()
		var marble := bag.draw(func(_id: String) -> bool: return true,
				func(_id: String) -> float: return 1.0)
		calls.append([name, seen, marble, rows])
		var plan := EventPlan.new(cafe, unit.locations()[0].centre())
		unit_of[plan.placed_at()] = name
		var placed: Array[EventPlan] = [plan]
		if hands_over.has(name):
			placed.append(EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2.INF))
		return placed

## A unit of one junction location at `x` blocks along.
static func _unit(x: int, day_seed := 11) -> PlacementUnit:
	var tiles := Rect2i(Vector2i(x * CityMap.period(), 0), Vector2i.ONE * Tuning.STREET_WIDTH)
	var location := Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, Location.Kind.JUNCTION, tiles)
	var locations: Array[Location] = [location]
	return PlacementUnit.new(PlacementGround.Kind.JUNCTION, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE),
			locations, day_seed)

## `units` lowest rank first.
static func _ranked(units: Array[PlacementUnit]) -> Array[PlacementUnit]:
	var sorted := units.duplicate()
	sorted.sort_custom(func(a: PlacementUnit, b: PlacementUnit) -> bool: return a.draws_before(b))
	return sorted

static func _dawn() -> Array[EventPlan]:
	var dawn: Array[EventPlan] = [EventPlan.new(EventCatalogue.by_id("roadblock"),
			Vector2(-500, -500))]
	return dawn

static func _fills() -> _Fills:
	return _Fills.new({Vector2i(ON, PlacementGround.Kind.JUNCTION):
			{"cafe_tables": 1, ViewBag.EMPTY: 1}})

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
		var made: Array[PlacementUnit] = [_unit(0), _unit(1), _unit(2)]
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
	var ranked := _ranked([_unit(0), _unit(1), _unit(2),
			_unit(3)] as Array[PlacementUnit])
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

## **No draw is judged among a plan her walk sites.** A crew the lower of two touching units handed
## to her walk, and a set piece the dawn left with no place, are each sited since, the place
## written into the very plan as the director writes it (`EventDirector.site_what_is_on_her_way()`);
## the higher unit, drawn after, is judged among the dawn's placed row and the lower unit's placed
## row and neither of the two, so where her walk put them changes nothing it draws.
func _test_no_draw_is_judged_among_a_plan_her_walk_sites(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var ranked := _ranked([_unit(0), _unit(1)] as Array[PlacementUnit])
	var low := ranked[0]
	var high := ranked[1]
	drawing.hands_over[low.name()] = true
	var units := _Units.new()
	units.table = {low.name(): [high], high.name(): [low]}
	var dawn := _dawn()
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2.INF)
	dawn.append(fire)
	var draw := UnitDraw.new(units, drawing, _fills(), dawn)
	var crew: EventPlan = null
	for plan in draw.draw(low):
		if not plan.is_placed():
			crew = plan
	t.check(crew != null and crew.row().is_handed_to_her_walk() and low.drawn().has(crew),
			"the lower unit hands a crew to her walk, with no place, and holds it as drawn")
	if crew == null:
		return
	crew.position = high.bounds().get_center()
	fire.position = high.bounds().get_center() + Vector2(64.0, 0.0)
	draw.draw(high)
	var rows: Array = drawing.calls[1][3]
	t.check(crew.is_placed() and fire.is_placed() and rows == ["roadblock", "cafe_tables"],
			"sited since, neither the crew nor the dawn's set piece is among what the next unit "
			+ "is judged among: the dawn's placed row and the lower unit's placed row alone (%s)"
			% [rows])

func _test_a_unit_draws_once(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var unit := _unit(0)
	var draw := UnitDraw.new(_Units.new(), drawing, _fills(), _dawn())
	var first := draw.draw(unit)
	var second := draw.draw(unit)
	t.check(first.size() == 1 and second.is_empty() and drawing.calls.size() == 1,
			"a unit asked for twice draws once (%d calls)" % drawing.calls.size())
	t.check(unit.drawn() == first, "and holds what it drew")

## **A unit of mixed views draws from the bag of the most permissive one** (inbox #1466 in silky-lemur): an open
## lot of two cells, the first off the route and the second on it, is handed a bag of the
## on-the-route fill, each fill one marble of its own, so the marble its draw takes names the bag.
func _test_a_unit_of_mixed_views_draws_from_the_most_permissive_bag(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var lot := Rect2i(Vector2i(20, 20), Vector2i(8, 4))
	var locations: Array[Location] = []
	for x in 2:
		var tiles := Rect2i(lot.position + Vector2i(x * 4, 0), Vector2i(4, 4))
		locations.append(Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
				OFF if x == 0 else ON, true, Location.Kind.OPEN, lot))
	var unit := PlacementUnit.new(PlacementGround.Kind.OPEN, lot,
			Rect2(Vector2(lot.position) * Tuning.TILE_SIZE, Vector2(lot.size) * Tuning.TILE_SIZE),
			locations, 5)
	var fills := _Fills.new({Vector2i(ON, PlacementGround.Kind.OPEN): {"cafe_tables": 1},
			Vector2i(OFF, PlacementGround.Kind.OPEN): {"dog_walker": 1}})
	UnitDraw.new(_Units.new(), drawing, fills, _dawn()).draw(unit)
	t.check(drawing.calls.size() == 1 and drawing.calls[0][2] == "cafe_tables",
			"a lot with a cell off the route and one on it draws from the route's bag (%s)"
			% [drawing.calls[0][2] if not drawing.calls.is_empty() else "no draw"])

## **A unit draws from the fill of its view and its kind of ground** (`UnitFills.of()`): a
## street and a junction box, both on the route, are handed fills of one marble each, a different one
## for each ground, so the marble each draw takes names the fill its bag was made of.
func _test_a_unit_draws_from_the_fill_of_its_view_and_its_ground(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var tiles := Rect2i(Vector2i(Tuning.STREET_WIDTH, 0), Vector2i(8, Tuning.STREET_WIDTH))
	var sidewalk := Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
			ON, true, Location.Kind.SIDEWALK, tiles)
	var bounds := Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE,
			Vector2(tiles.size) * Tuning.TILE_SIZE)
	var street := PlacementUnit.new(PlacementGround.Kind.STREET, tiles, bounds,
			[sidewalk] as Array[Location], 5)
	var box := _unit(0)
	var fills := _Fills.new({Vector2i(ON, PlacementGround.Kind.STREET): {"dog_walker": 1},
			Vector2i(ON, PlacementGround.Kind.JUNCTION): {"cafe_tables": 1}})
	var draw := UnitDraw.new(_Units.new(), drawing, fills, _dawn())
	draw.draw(street)
	draw.draw(box)
	var marbles: Array[String] = []
	for call: Array in drawing.calls:
		marbles.append(str(call[2]))
	t.check(marbles == ["dog_walker", "cafe_tables"],
			"a street and a junction box of one view draw from their own ground's fill (%s)"
			% [marbles])
	t.check(fills.asked == [Vector2i(ON, PlacementGround.Kind.STREET),
			Vector2i(ON, PlacementGround.Kind.JUNCTION)],
			"each asks the fills for its view and its ground (%s)" % [fills.asked])
