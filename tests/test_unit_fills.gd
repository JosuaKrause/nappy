extends RefCounted
## `UnitFills`, the day's bag fills by view and kind of ground: a fill holds its cell's events in a
## hundred of its marbles and empty for the rest; a wall share gives the walls' place to empty and
## leaves every other row its count; a view weighs a row by its role on the day; a row has marbles
## only on ground it stands on, scaled by its weight there; a marble that takes a section weighs as
## the two locations it speaks for; and a cell no row stands in is the empty marble alone.
##
## Built for real over rows made by hand (`EventDef.new()` with the fields a fill reads) or taken
## from the catalogue, the role-by-view weights `RowGround.Weights.of(1, 3, 5, 1, 7)` (three
## different numbers, so each role's weight is told apart without naming a setting) and a lambda
## for which wall is one by its cost. Mocks nothing: every collaborator is data
## (`EventDef`, `RowGround.Weights`, `PlacementDensity`).

func run(t: TestRunner) -> void:
	_test_a_fill_holds_its_cells_events_in_a_hundred(t)
	_test_a_wall_share_gives_the_walls_place_to_empty(t)
	_test_a_view_weighs_a_row_by_its_role(t)
	_test_a_row_has_marbles_only_where_it_stands(t)
	_test_a_rows_weight_on_a_ground_scales_its_marbles(t)
	_test_a_larger_marble_weighs_as_the_locations_it_speaks_for(t)
	_test_a_cell_no_row_stands_in_is_all_empty(t)
	_test_a_unit_is_made_a_fresh_bag_of_its_fill(t)

const ON := PlacementView.View.ON_THE_ROUTE
const BESIDE := PlacementView.View.ROUTE_ADJACENT
const OFF := PlacementView.View.OFF_THE_ROUTE
const VIEWS: Array[PlacementView.View] = [ON, BESIDE, OFF]
const STREET := PlacementGround.Kind.STREET
const JUNCTION := PlacementGround.Kind.JUNCTION
const ALLEY := PlacementGround.Kind.ALLEY
const OPEN := PlacementGround.Kind.OPEN
const GROUNDS: Array[PlacementGround.Kind] = [STREET, JUNCTION, ALLEY, OPEN]
## The role-by-view weights: friction and a wall by its fit three times over on the route, a costly
## wall five times over beside it and on it, a lethal wall seven times over off it.
const ROUTES := 3
const RIM := 5
const DEEP := 7

static func _weights() -> RowGround.Weights:
	return RowGround.Weights.of(1, ROUTES, RIM, 1, DEEP)

## Whether a row is a wall by what it costs: one of the hand rows `ids` names.
static func _by_cost(ids: Array[String]) -> Callable:
	return func(def: EventDef) -> bool: return ids.has(def.id)

## A recurring row placed on the map, standing on `placement`, of weight one, scenery unless
## `role` says otherwise: `"friction"` a quiet row, `"wall"` one whose field is too costly to walk
## through, `"lethal"` one that ends the day.
static func _row(id: String, placement: Array[int], role := "scenery") -> EventDef:
	var def := EventDef.new()
	def.id = id
	def.kind = GameEnums.EventKind.RECURRING
	def.placement = placement
	def.weight = 1.0
	match role:
		"scenery":
			def.role = EventDef.Role.SCENERY
		"friction":
			def.intensity = 1.0
			def.inner_radius = 10.0
			def.outer_radius = 40.0
		"wall":
			def.intensity = 60.0
			def.inner_radius = 80.0
			def.outer_radius = 200.0
		"lethal":
			def.hard_fail = true
	return def

## The rows a unit draws on `day`, as the dawn draw gathers them (`DawnDraw`), cold.
static func _catalogue(day: int) -> Dictionary:
	var rows := {}
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day, 0):
		if def.is_drawn_by_units(day, ""):
			rows[def.id] = def.for_day(day)
	return rows

static func _fills(rows: Dictionary, day: int, share := 1.0,
		by_cost: Callable = func(def: EventDef) -> bool: return def.hard_fail) -> UnitFills:
	return UnitFills.new(rows, day, share, _weights(), by_cost)

## A street unit of one sidewalk location on the route, `x` blocks along, on the day seed `day_seed`.
static func _street_unit(x: int, day_seed: int) -> PlacementUnit:
	return _unit_of(STREET, ON, x, day_seed)

## A unit of `ground` with one location in `view`, `x` blocks along, on the day seed `day_seed`.
static func _unit_of(ground: PlacementGround.Kind, view: PlacementView.View, x: int,
		day_seed: int) -> PlacementUnit:
	var tiles := Rect2i(Vector2i(x * CityMap.period(), 0), Vector2i(8, Tuning.STREET_WIDTH))
	var kind := Location.Kind.SIDEWALK if ground == STREET else Location.Kind.OPEN
	var location := Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
			view, true, kind, tiles)
	var locations: Array[Location] = [location]
	return PlacementUnit.new(ground, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE),
			locations, day_seed)

## The first `count` marbles a bag draws with every row accepted and every marble weighed alike.
static func _first_marbles(bag: ViewBag, count: int) -> Array[String]:
	var drawn: Array[String] = []
	for _i in count:
		drawn.append(bag.draw(func(_marble: String) -> bool: return true,
				func(_marble: String) -> float: return 1.0))
	return drawn

## A fill's marbles, all told.
static func _total(fill: Dictionary) -> int:
	var total := 0
	for marble: String in fill:
		total += int(fill[marble])
	return total

## **A unit is made a fresh bag of its fill** (`bag_for()`): asked twice it answers two bags, not
## one, that draw the same first ten marbles, each a marble of the fill of the unit's view and
## ground; a unit of other tiles draws on a stream of its own, so its first ten differ from the first
## unit's on at least one of three day seeds. **Which fill** is pinned by drawing a whole fill's worth of
## marbles, a bag being drawn without putting back: the counts are the fill's own, for two units
## whose fills differ, so the view and the kind of ground the bag is made of are the unit's.
func _test_a_unit_is_made_a_fresh_bag_of_its_fill(t: TestRunner) -> void:
	var day := 8
	var fills := _fills(_catalogue(day), day)
	var fill := fills.of(ON, STREET)
	t.check(fill.size() > 1, "the street's fill on day %d holds several marbles (%d)"
			% [day, fill.size()])
	var differed := 0
	for day_seed: int in [3, 5, 9]:
		var unit := _street_unit(0, day_seed)
		var first := fills.bag_for(unit)
		var second := fills.bag_for(unit)
		t.check(first != second, "bag_for() makes a bag a time (day seed %d)" % day_seed)
		var marbles := _first_marbles(first, 10)
		t.check(marbles == _first_marbles(second, 10),
				"two bags of one unit draw the same first ten marbles (day seed %d)" % day_seed)
		if _first_marbles(fills.bag_for(_street_unit(1, day_seed)), 10) != marbles:
			differed += 1
	t.check(differed > 0, "a unit of other tiles draws on another stream (%d of 3 seeds differ)"
			% differed)
	var street := _street_unit(0, 3)
	var lot := _unit_of(OPEN, OFF, 0, 3)
	t.check(fills.of(ON, STREET) != fills.of(OFF, OPEN),
			"the two units' fills differ, so the counts below tell them apart")
	for unit: PlacementUnit in [street, lot]:
		var whole := fills.of(unit.view() as PlacementView.View, unit.kind())
		for _fresh in 2:
			var counts := {}
			var bag := fills.bag_for(unit)
			for _i in _total(whole):
				var marble := bag.draw(func(_m: String) -> bool: return true,
						func(_m: String) -> float: return 1.0)
				counts[marble] = int(counts.get(marble, 0)) + 1
			t.check(counts == whole, "a bag of %s holds exactly its view's and ground's fill"
					% unit.name())

## **A fill holds its cell's events in a hundred of its marbles**, the rest empty: for every view
## and ground on a day of each act, over the catalogue's drawn rows at a wall share of one, the row
## marbles of a fill that has rows are `PlacementDensity.events_per_hundred()` in a hundred of its
## marbles, to within a marble a row.
func _test_a_fill_holds_its_cells_events_in_a_hundred(t: TestRunner) -> void:
	var cells := 0
	var wrong: Array[String] = []
	for day: int in [1, 4, 8, 12]:
		var fills := _fills(_catalogue(day), day)
		for view in VIEWS:
			for ground in GROUNDS:
				var fill := fills.of(view, ground)
				if fill.size() < 2:
					continue
				cells += 1
				var rows := 0
				for marble: String in fill:
					if marble != ViewBag.EMPTY:
						rows += int(fill[marble])
				var total := _total(fill)
				var asked := PlacementDensity.events_per_hundred(view, ground, day) / 100.0 \
						* float(total)
				if not fill.has(ViewBag.EMPTY) or absf(float(rows) - asked) > float(fill.size()):
					wrong.append("day %d view %d ground %d: %d of %d" % [day, view, ground, rows,
							total])
	t.check(cells >= 30, "there were fills with rows to ask (%d)" % cells)
	t.check(wrong.is_empty(), "every fill holds its cell's events in a hundred, empty the rest (%s)"
			% [wrong])

## **A wall share gives the walls' place to empty**: the same rows off the route on a street at a
## share of a half and of one, each wall row holding half its marbles to within one, every other
## row the same count, and the two fills the same size.
func _test_a_wall_share_gives_the_walls_place_to_empty(t: TestRunner) -> void:
	var day := 4
	var rows := _catalogue(day)
	var full := _fills(rows, day, 1.0).of(OFF, STREET)
	var half := _fills(rows, day, 0.5).of(OFF, STREET)
	var walls := 0
	var others := 0
	var wrong: Array[String] = []
	for id: String in full:
		if id == ViewBag.EMPTY:
			continue
		var was := int(full[id])
		var now := int(half.get(id, 0))
		var def: EventDef = rows[id]
		if EventScheduler.role_for(def, day) == GameEnums.BlockerRole.WALL:
			walls += 1
			if absf(float(now) - float(was) * 0.5) > 1.0:
				wrong.append("%s %d -> %d" % [id, was, now])
		else:
			others += 1
			if now != was:
				wrong.append("%s %d -> %d" % [id, was, now])
	t.check(walls > 0 and others > 0, "there were walls (%d) and other rows (%d) to weigh"
			% [walls, others])
	t.check(wrong.is_empty(), "a wall holds half its marbles at a half share and every other row "
			+ "its count (%s)" % [wrong])
	t.check(_total(full) == _total(half), "and the two fills are the same size (%d, %d)"
			% [_total(full), _total(half)])

## **A view weighs a row by its role**: hand rows of one weight on a street, each against a scenery
## row's marbles in the same fill: friction three times over on the route and once elsewhere, a
## wall by its fit the same, a costly wall five times over on the route and beside it and once off
## it, a lethal wall seven times over off the route and once nearer; a row of alleys only has none
## in an alley's fill on the route and has one beside it.
func _test_a_view_weighs_a_row_by_its_role(t: TestRunner) -> void:
	var sidewalk: Array[int] = [GameEnums.TileType.SIDEWALK]
	var rows := {}
	for def: EventDef in [_row("scenery", sidewalk), _row("friction", sidewalk, "friction"),
			_row("fit_wall", sidewalk, "wall"), _row("costly_wall", sidewalk, "wall"),
			_row("lethal_wall", sidewalk, "lethal")]:
		rows[def.id] = def
	var by_cost := _by_cost(["costly_wall", "lethal_wall"] as Array[String])
	var fills := _fills(rows, 1, 1.0, by_cost)
	var expected := {
		"friction": [ROUTES, 1, 1],
		"fit_wall": [ROUTES, 1, 1],
		"costly_wall": [RIM, RIM, 1],
		"lethal_wall": [1, 1, DEEP],
	}
	var wrong: Array[String] = []
	for view in VIEWS:
		var fill := fills.of(view, STREET)
		var scenery := float(fill.get("scenery", 0))
		for id: String in expected:
			var times := float((expected[id] as Array)[view])
			var count := float(fill.get(id, 0))
			if scenery <= 0.0 or absf(count - times * scenery) > times + 1.0:
				wrong.append("%s in view %d: %d against scenery's %d" % [id, view, count, scenery])
	t.check(wrong.is_empty(), "each role weighs as its view says against scenery (%s)" % [wrong])
	var alleys := {"alleys": _row("alleys", [GameEnums.TileType.ALLEY] as Array[int])}
	var alley_fills := _fills(alleys, 1)
	t.check(not alley_fills.of(ON, ALLEY).has("alleys") and alley_fills.of(BESIDE, ALLEY).has(
			"alleys"), "a row of alleys only has no marble on the route and one beside it")

## **A row has marbles only where it stands**, from the catalogue off the route: the street musician
## none in a street's fill and some on open ground, the alley mouse only in an alley's, and a row
## weighed at nothing in a junction box (the cafe) none there and some on a street.
func _test_a_row_has_marbles_only_where_it_stands(t: TestRunner) -> void:
	var day := 4
	var fills := _fills(_catalogue(day), day)
	t.check(not fills.of(OFF, STREET).has("busker") and fills.of(OFF, OPEN).has("busker"),
			"the street musician has marbles on open ground and none on a street")
	var mouse_on: Array[int] = []
	for ground in GROUNDS:
		if fills.of(OFF, ground).has("alley_mouse"):
			mouse_on.append(ground)
	t.check(mouse_on == ([ALLEY] as Array[int]), "the alley mouse has marbles in an alley's fill only "
			+ "(%s)" % [mouse_on])
	var cafe := EventCatalogue.by_id("cafe_tables")
	t.check(cafe.weight_on(JUNCTION) == 0.0 and not fills.of(OFF, JUNCTION).has("cafe_tables")
			and fills.of(OFF, STREET).has("cafe_tables"),
			"a row weighed at nothing in a junction box has no marble there and some on a street")

## **A row's weight on a ground scales its marbles there**: two hand rows alike but for one weighed
## at a half on a street hold half the other's marbles in a street's fill and as many in a
## junction box's.
func _test_a_rows_weight_on_a_ground_scales_its_marbles(t: TestRunner) -> void:
	var sidewalk: Array[int] = [GameEnums.TileType.SIDEWALK]
	var light := _row("light", sidewalk)
	light.weigh_on(STREET, 0.5)
	var fills := _fills({"plain": _row("plain", sidewalk), "light": light}, 1)
	var street := fills.of(OFF, STREET)
	var box := fills.of(OFF, JUNCTION)
	t.check(absf(float(street["light"]) - float(street["plain"]) * 0.5) <= 1.0,
			"weighed at a half on a street, it holds half the marbles there (%d against %d)"
			% [street["light"], street["plain"]])
	t.check(box["light"] == box["plain"], "and as many in a junction box (%d against %d)"
			% [box["light"], box["plain"]])

## **A larger marble weighs as the locations it speaks for**: a row that takes a section (it stands
## on the carriageway) holds twice the marbles of a one-location row in a street's fill, since a
## section is its two sidewalk locations; in a junction box's, where every marble speaks for one,
## they hold the same.
func _test_a_larger_marble_weighs_as_the_locations_it_speaks_for(t: TestRunner) -> void:
	var section := _row("section", [GameEnums.TileType.ROAD] as Array[int])
	var location := _row("location", [GameEnums.TileType.SIDEWALK] as Array[int])
	var fills := _fills({"section": section, "location": location}, 1)
	var street := fills.of(OFF, STREET)
	var box := fills.of(OFF, JUNCTION)
	t.check(absf(float(street["section"]) - 2.0 * float(street["location"])) <= 2.0,
			"in a street a section's marble weighs twice a location's (%d against %d)"
			% [street["section"], street["location"]])
	t.check(box["section"] == box["location"], "in a junction box they weigh the same (%d, %d)"
			% [box["section"], box["location"]])

## **A cell no row stands in is the empty marble alone**: sidewalk rows in an alley's fill, and, for
## every cell the table holds no event in, a row that stands there.
func _test_a_cell_no_row_stands_in_is_all_empty(t: TestRunner) -> void:
	var sidewalk: Array[int] = [GameEnums.TileType.SIDEWALK]
	var fills := _fills({"a": _row("a", sidewalk), "b": _row("b", sidewalk, "friction")}, 1)
	t.check(fills.of(OFF, ALLEY) == {ViewBag.EMPTY: 1},
			"an alley's fill over sidewalk rows is the empty marble alone (%s)"
			% [fills.of(OFF, ALLEY)])
	var everywhere: Array[int] = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.CROSSING,
			GameEnums.TileType.ALLEY, GameEnums.TileType.PARK]
	var wrong: Array[String] = []
	var stands := true
	for day: int in [1, 4, 8, 12]:
		var on_day := _fills({"wide": _row("wide", everywhere)}, day)
		stands = stands and on_day.of(OFF, ALLEY).has("wide")
		for view in VIEWS:
			for ground in GROUNDS:
				if PlacementDensity.events_per_hundred(view, ground, day) <= 0.0 \
						and on_day.of(view, ground) != {ViewBag.EMPTY: 1}:
					wrong.append("day %d view %d ground %d" % [day, view, ground])
	t.check(stands and wrong.is_empty(),
			"a cell holding no event is all empty though a row stands there (%s)" % [wrong])
