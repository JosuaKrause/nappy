extends RefCounted
## `UnitDraw`, the day's units drawn each after every touching unit of lower rank: three units that
## all touch drawn in every order they can be asked for, the draws and what each is judged among the
## same every time; a unit asked for draws the touching units of lower rank it waits for first, down
## a chain, and is judged among the dawn's plans, the draws of the units touching it and the beats
## her walk laid in it or a touching unit, and no other plan her walk sites; a unit draws once; a
## unit whose locations are in
## different views draws from the bag of the most permissive of them; and a unit draws from the
## fill of its view and its kind of ground. A walk drawn whole (`draw_in_their_order()`) draws every
## unit in the order its units are in, never asks which touch, judges each among the dawn's plans and
## everything drawn before it, passes over a unit drawn already, and has every unit draw from the one
## bag its walk answers.
##
## Run with stand-ins for what it is handed: the day's units (`_Units`, a touching table and an
## order set by hand), the day's fills (`_Fills`, a fill set by hand for each view and ground, which
## records each ask), one bag for the walk (`_Bags`, which records each ask) and the unit's draw
## (`_Drawing`, which records each call and answers one plan for it, drawing one marble from the bag
## it is handed); the units are real (`PlacementUnit`, state), each of a location or two made by
## hand, and so are the bags (`ViewBag`).

func run(t: TestRunner) -> void:
	_test_every_order_of_asking_draws_the_same(t)
	_test_a_unit_waits_for_the_lower_touching_units_down_a_chain(t)
	_test_a_draw_is_judged_among_a_beat_stood_in_its_unit_or_a_touching_one(t)
	_test_a_unit_draws_once(t)
	_test_a_unit_of_mixed_views_draws_from_the_most_permissive_bag(t)
	_test_a_unit_draws_from_the_fill_of_its_view_and_its_ground(t)
	_test_a_whole_walk_is_drawn_in_its_units_order(t)
	_test_a_whole_walk_judges_each_unit_among_everything_before_it(t)
	_test_a_whole_walk_passes_over_a_unit_already_drawn(t)
	_test_every_unit_draws_from_the_bag_its_walk_answers(t)

const ON := PlacementView.View.ON_THE_ROUTE
const OFF := PlacementView.View.OFF_THE_ROUTE

class _Units extends DayUnits:
	## Unit name -> the units it touches.
	var table := {}
	## The units in the order the day names them, `all()`'s answer.
	var order: Array[PlacementUnit] = []
	## How many times the draw asked which units touch one.
	var touched := 0

	## Overrides DayUnits.all.
	func all() -> Array[PlacementUnit]:
		return order.duplicate()

	## Overrides DayUnits.touching.
	func touching(unit: PlacementUnit) -> Array[PlacementUnit]:
		touched += 1
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

class _Bags extends UnitBags:
	## The one bag every unit is answered.
	var bag: ViewBag
	## The name of each unit asked, in the order asked.
	var asked: Array[String] = []

	func _init(the_bag: ViewBag) -> void:
		bag = the_bag

	## Overrides UnitBags.bag_for.
	func bag_for(unit: PlacementUnit) -> ViewBag:
		asked.append(unit.name())
		return bag

class _Drawing extends MarbleDraw:
	## A plan's place -> the name of the unit that drew it.
	var unit_of := {}
	## `[unit name, [the names of the units whose plans it was judged among, "dawn" for the
	## dawn's], the marble it drew from the bag it was handed, the rows it was judged among]` per
	## call.
	var calls: Array = []
	var cafe := EventCatalogue.shipped().by_id("cafe_tables")
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
			placed.append(EventPlan.new(EventCatalogue.shipped().by_id("poster_crew"), Vector2.INF))
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
	var dawn: Array[EventPlan] = [EventPlan.new(EventCatalogue.shipped().by_id("roadblock"),
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

## **A draw is judged among a beat her walk laid in its unit or a touching one, and no other
## plan her walk sites.** A fire her walk laid in the lowest of three units stands on its
## location (`Location.take_for_her_walk()`, as `WalkSiting` does through `DayLocations`); the
## unit drawing is judged among it, and so is a unit touching it, drawn after; a unit that
## touches neither is not. A crew a unit handed to her walk and a set piece the dawn left with
## no place, each since given a place but laid in no unit, are in no draw's judgment.
func _test_a_draw_is_judged_among_a_beat_stood_in_its_unit_or_a_touching_one(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var ranked := _ranked([_unit(0), _unit(1), _unit(2)] as Array[PlacementUnit])
	var low := ranked[0]
	var mid := ranked[1]
	var far := ranked[2]
	drawing.hands_over[low.name()] = true
	var units := _Units.new()
	units.table = {low.name(): [mid], mid.name(): [low, far], far.name(): [mid]}
	var dawn := _dawn()
	var unsited := EventPlan.new(EventCatalogue.shipped().by_id("burning_building"), Vector2.INF)
	dawn.append(unsited)
	var draw := UnitDraw.new(units, drawing, _fills(), dawn)
	var beat := EventPlan.new(EventCatalogue.shipped().by_id("poster_crew"), low.bounds().get_center())
	low.locations()[0].take_for_her_walk(beat)
	var crew: EventPlan = null
	for plan in draw.draw(low):
		if not plan.is_placed():
			crew = plan
	t.check(crew != null and crew.row().is_handed_to_her_walk(),
			"the lowest unit hands a crew to her walk, with no place (the guard that there is one)")
	if crew == null:
		return
	crew.stand_where(EventPlan.new(crew.row(), far.bounds().get_center()))
	unsited.stand_where(EventPlan.new(unsited.row(), far.bounds().get_center() + Vector2(64.0, 0.0)))
	draw.draw(mid)
	draw.draw(far)
	var low_rows: Array = drawing.calls[0][3]
	var mid_rows: Array = drawing.calls[1][3]
	var far_rows: Array = drawing.calls[2][3]
	t.check(low_rows == ["roadblock", "poster_crew"],
			"the unit the beat stands in is judged among it besides the dawn's placed row (%s)"
			% [low_rows])
	t.check(mid_rows == ["roadblock", "poster_crew", "cafe_tables"],
			"a unit touching it is judged among the beat as well as the lower unit's draw (%s)"
			% [mid_rows])
	t.check(far_rows == ["roadblock", "cafe_tables"],
			"a unit touching neither is judged among no beat, and the crew and the dawn's set piece, "
			+ "given a place but laid in no unit, are in no draw's judgment (%s)" % [far_rows])

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

## Three units, none touching another, named by the day in `order`: the last of the ranked units
## first, so a later unit draws before an earlier one by rank.
static func _a_walk_not_in_rank_order() -> _Units:
	var made := _ranked([_unit(0), _unit(1), _unit(2)] as Array[PlacementUnit])
	var units := _Units.new()
	units.order = [made[2], made[0], made[1]] as Array[PlacementUnit]
	return units

## **A walk drawn whole draws every unit in the order the day's units are in** (`DayUnits.all()`),
## whatever their rank, and never asks which touch.
func _test_a_whole_walk_is_drawn_in_its_units_order(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var units := _a_walk_not_in_rank_order()
	t.check(units.order[1].draws_before(units.order[0]),
			"a later unit of the walk draws before an earlier one by rank, so the order is not the rank")
	var draw := UnitDraw.new(units, drawing, _fills(), _dawn())
	var placed := draw.draw_in_their_order()
	var named: Array[String] = []
	for call: Array in drawing.calls:
		named.append(str(call[0]))
	var wanted: Array[String] = []
	for unit in units.order:
		wanted.append(unit.name())
	t.check(named == wanted, "every unit is drawn once, in the walk's own order (%s)" % [named])
	t.check(units.touched == 0, "and none is asked which units touch it (%d asks)" % units.touched)
	t.check(placed.size() == 3 and placed[0] == units.order[0].drawn()[0]
			and placed[2] == units.order[2].drawn()[0],
			"and answers every plan placed, in the order drawn (%d)" % placed.size())

## **Each unit of a walk drawn whole is judged among everything drawn before it**, though none
## touches another, and a row a unit handed to her walk is in no later unit's judgment.
func _test_a_whole_walk_judges_each_unit_among_everything_before_it(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var units := _a_walk_not_in_rank_order()
	drawing.hands_over[units.order[0].name()] = true
	var draw := UnitDraw.new(units, drawing, _fills(), _dawn())
	draw.draw_in_their_order()
	var judged: Array = []
	for call: Array in drawing.calls:
		judged.append(call[3])
	t.check(judged == [["roadblock"], ["roadblock", "cafe_tables"],
			["roadblock", "cafe_tables", "cafe_tables"]],
			"the first unit is judged among the dawn's plan, the second among that and the first's "
			+ "row, the third among all three; the crew the first handed to her walk is in none (%s)"
			% [judged])

## **A unit drawn before the call is not drawn again**, and what it drew is among the later units'.
func _test_a_whole_walk_passes_over_a_unit_already_drawn(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var units := _a_walk_not_in_rank_order()
	var draw := UnitDraw.new(units, drawing, _fills(), _dawn())
	draw.draw(units.order[1])
	draw.draw_in_their_order()
	var named: Array[String] = []
	for call: Array in drawing.calls:
		named.append(str(call[0]))
	t.check(named == [units.order[1].name(), units.order[0].name(), units.order[2].name()],
			"the unit drawn already is passed over and the other two are drawn after it (%s)" % [named])
	var judged: Array = drawing.calls[2][3]
	t.check(judged == ["roadblock", "cafe_tables", "cafe_tables"],
			"and the last is judged among the dawn's plan and both draws before it (%s)" % [judged])

## **Every unit draws from the bag its walk answers**, asked once a unit in the order drawn: one bag
## drawn without putting back gives three different marbles to three units.
func _test_every_unit_draws_from_the_bag_its_walk_answers(t: TestRunner) -> void:
	var drawing := _Drawing.new()
	var units := _a_walk_not_in_rank_order()
	var bags := _Bags.new(ViewBag.new({"cafe_tables": 1, "dog_walker": 1, "roadblock": 1}, 3))
	UnitDraw.new(units, drawing, bags, _dawn()).draw_in_their_order()
	var wanted: Array[String] = []
	for unit in units.order:
		wanted.append(unit.name())
	t.check(bags.asked == wanted, "the walk's bags are asked once a unit, in the order drawn (%s)"
			% [bags.asked])
	var marbles: Array[String] = []
	for call: Array in drawing.calls:
		marbles.append(str(call[2]))
	marbles.sort()
	t.check(marbles == ["cafe_tables", "dog_walker", "roadblock"],
			"and every unit drew from the one bag, each marble once (%s)" % [marbles])
