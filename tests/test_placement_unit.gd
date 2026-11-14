extends RefCounted
## `PlacementUnit`, one unit of the day's locations: the same name, rank and stream for the same
## day's seed and tiles, so a unit draws alike on every start of the day, and another rank and
## stream for another seed; the draw order between two units total (`draws_before()`); and what it
## drew written once. Built of plain values: a unit and its locations are state, so nothing is
## mocked.

func run(t: TestRunner) -> void:
	_test_the_same_seed_and_tiles_give_the_same_unit(t)
	_test_two_units_are_always_ordered(t)
	_test_what_it_drew_is_written_once(t)

const STREET := Rect2i(Vector2i(6, 0), Vector2i(8, 6))

static func _unit(day_seed: int, tiles := STREET) -> PlacementUnit:
	var locations: Array[Location] = []
	return PlacementUnit.new(PlacementUnit.Kind.STREET, tiles,
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
