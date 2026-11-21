extends RefCounted
## `PlacementUnit`, one unit of the day's locations: the same name, rank and stream for the same
## day's seed and tiles, so a unit draws alike on every start of the day, and another rank and
## stream for another seed; the draw order between two units total (`draws_before()`); what it
## drew written once; its view the most permissive of its locations'; and the beats her walk
## stood on its locations answered, in the locations' order. Built of plain values: a unit, its
## locations and a plan are state, so nothing is mocked.

func run(t: TestRunner) -> void:
	_test_the_same_seed_and_tiles_give_the_same_unit(t)
	_test_two_units_are_always_ordered(t)
	_test_what_it_drew_is_written_once(t)
	_test_its_view_is_the_most_permissive_of_its_locations(t)
	_test_its_beats_are_what_her_walk_stood_on_its_locations(t)

const STREET := Rect2i(Vector2i(6, 0), Vector2i(8, 6))

static func _unit(day_seed: int, tiles := STREET) -> PlacementUnit:
	var locations: Array[Location] = []
	return PlacementUnit.new(PlacementGround.Kind.STREET, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE),
			locations, day_seed)

static func _streamed(unit: PlacementUnit) -> Array[int]:
	var rng := unit.stream()
	var rolls: Array[int] = []
	for _i in 4:
		rolls.append(rng.randi())
	return rolls

## Two units neither of which draws before the other have the same rank and name.
static func _ranked_alike(a: PlacementUnit, b: PlacementUnit) -> bool:
	return not a.draws_before(b) and not b.draws_before(a)

func _test_the_same_seed_and_tiles_give_the_same_unit(t: TestRunner) -> void:
	var first := _unit(41)
	var again := _unit(41)
	t.check(first.name() == again.name() and first.name() == "street:(6, 0, 8, 6)",
			"a unit is named by its kind and its tiles (%s)" % first.name())
	t.check(_ranked_alike(first, again), "the same seed and tiles give the same rank")
	t.check(_streamed(first) == _streamed(again),
			"and the same stream, a fresh generator on each ask")
	t.check(_streamed(first) == _streamed(first), "asking the stream twice starts it over")
	var another_day := _unit(42)
	t.check(not _ranked_alike(first, another_day), "another day's seed gives another rank")
	t.check(_streamed(first) != _streamed(another_day), "and another stream")
	var another_street := _unit(41, Rect2i(Vector2i(20, 0), Vector2i(8, 6)))
	t.check(_streamed(first) != _streamed(another_street), "as another street's tiles do")

func _test_two_units_are_always_ordered(t: TestRunner) -> void:
	var units: Array[PlacementUnit] = []
	for x in 12:
		units.append(_unit(7, Rect2i(Vector2i(6 + 14 * x, 0), Vector2i(8, 6))))
	var total := true
	var antisymmetric := true
	for a in units:
		for b in units:
			if a == b:
				continue
			total = total and (a.draws_before(b) or b.draws_before(a))
			antisymmetric = antisymmetric and not (a.draws_before(b) and b.draws_before(a))
	t.check(total and antisymmetric,
			"of every two different units exactly one draws before the other")
	var transitive := true
	for a in units:
		for b in units:
			for c in units:
				if a.draws_before(b) and b.draws_before(c):
					transitive = transitive and a.draws_before(c)
	t.check(transitive, "and the order is transitive, so it is one order of them all")

func _test_what_it_drew_is_written_once(t: TestRunner) -> void:
	var unit := _unit(3)
	t.check(not unit.is_drawn() and unit.drawn().is_empty(), "a unit not drawn holds nothing")
	var cafe := EventPlan.new(EventCatalogue.by_id("cafe_tables"), Vector2(200, 100))
	var plans: Array[EventPlan] = [cafe]
	unit.record_draw(plans)
	plans.clear()
	t.check(unit.is_drawn() and unit.drawn() == ([cafe] as Array[EventPlan]),
			"once drawn it holds what its draw placed, a copy of the list it was handed")
	var read := unit.drawn()
	read.clear()
	t.check(unit.drawn().size() == 1, "and what it answers is a copy too")

## A lot of cells in the views `views`, in that order.
static func _lot(views: Array[int]) -> PlacementUnit:
	var lot := Rect2i(Vector2i(20, 20), Vector2i(4 * maxi(views.size(), 1), 4))
	var locations: Array[Location] = []
	for x in views.size():
		var tiles := Rect2i(lot.position + Vector2i(x * 4, 0), Vector2i(4, 4))
		locations.append(Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
				views[x], true, Location.Kind.OPEN, lot))
	return PlacementUnit.new(PlacementGround.Kind.OPEN, lot,
			Rect2(Vector2(lot.position) * Tuning.TILE_SIZE, Vector2(lot.size) * Tuning.TILE_SIZE),
			locations, 3)

## **A unit's view is the most permissive of its locations'** (inbox #1466 in silky-lemur): on the route before
## route-adjacent before off the route, wherever in the unit the location lies, and off the route
## for a unit with none.
func _test_its_view_is_the_most_permissive_of_its_locations(t: TestRunner) -> void:
	var on := PlacementView.View.ON_THE_ROUTE
	var beside := PlacementView.View.ROUTE_ADJACENT
	var off := PlacementView.View.OFF_THE_ROUTE
	t.check(_lot([off, off, on] as Array[int]).view() == on,
			"a lot whose last cell is on the route is on the route")
	t.check(_lot([off, beside, off] as Array[int]).view() == beside,
			"one whose cells are off the route and route-adjacent is route-adjacent")
	t.check(_lot([off, off] as Array[int]).view() == off, "one all off the route is off it")
	t.check(_unit(3).view() == off, "and a unit with no location is off the route")

## **What her walk stood on its locations is answered**, in the locations' order, each once, and not
## what a draw or a dawn phase put there, nor a beat given back.
func _test_its_beats_are_what_her_walk_stood_on_its_locations(t: TestRunner) -> void:
	var tiles := Rect2i(Vector2i(6, 0), Vector2i(8, 2))
	var near := _location(Rect2i(tiles.position, Vector2i(4, 2)))
	var far := _location(Rect2i(tiles.position + Vector2i(4, 0), Vector2i(4, 2)))
	var middle := _location(Rect2i(tiles.position + Vector2i(2, 0), Vector2i(4, 2)))
	var locations: Array[Location] = [near, far, middle]
	var unit := PlacementUnit.new(PlacementGround.Kind.STREET, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE,
					Vector2(tiles.size) * Tuning.TILE_SIZE), locations, 5)
	t.check(unit.beats().is_empty(), "a unit holds no beat until her walk stands one on a location")
	var fire := EventPlan.new(EventCatalogue.by_id("burning_building"), Vector2(200, 100))
	var crew := EventPlan.new(EventCatalogue.by_id("poster_crew"), Vector2(260, 100))
	var drawn := EventPlan.new(EventCatalogue.by_id("cafe_tables"), Vector2(300, 100))
	middle.take_for_her_walk(crew)
	near.take_for_her_walk(fire)
	far.record(drawn)
	t.check(unit.beats() == ([fire, crew] as Array[EventPlan]),
			"the beats are answered in the locations' order, and a row a draw put there is none")
	unit.record_draw([] as Array[EventPlan])
	t.check(unit.beats() == ([fire, crew] as Array[EventPlan]), "and drawing changes none of it")
	near.take(drawn)
	t.check(unit.beats() == ([crew] as Array[EventPlan]),
			"a plan put over a beat (day 13's task roadblock) ends it")
	near.give_back(fire)
	t.check(unit.beats() == ([crew] as Array[EventPlan]) and near.is_taken(),
			"and giving the ended beat back changes nothing")
	middle.give_back(crew)
	t.check(unit.beats().is_empty(), "a beat given back is answered no more")
	var answered := unit.beats()
	answered.append(fire)
	t.check(unit.beats().is_empty(), "and what it answers is a copy")

static func _location(tiles: Rect2i) -> Location:
	return Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
			PlacementView.View.ON_THE_ROUTE, true, Location.Kind.SIDEWALK, tiles)
