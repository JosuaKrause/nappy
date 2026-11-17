extends RefCounted
## `WholeWalkBag`, the one bag a whole walk draws from: every unit is answered the same bag, so a
## marble one unit's rules refuse is still there for the next, and the same seed draws the same.
##
## Run over hand-made units (`PlacementUnit`, state) and the real bag it answers (`ViewBag`, a
## value of marbles); nothing else is built.

func run(t: TestRunner) -> void:
	_test_every_unit_is_handed_the_same_bag(t)
	_test_a_marble_one_unit_refuses_is_there_for_the_next(t)
	_test_the_same_seed_draws_the_same(t)

const ON := PlacementView.View.ON_THE_ROUTE

## A unit of one junction location at `x` blocks along.
static func _unit(x: int) -> PlacementUnit:
	var tiles := Rect2i(Vector2i(x * CityMap.period(), 0), Vector2i.ONE * Tuning.STREET_WIDTH)
	var location := Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, Location.Kind.JUNCTION, tiles)
	var locations: Array[Location] = [location]
	return PlacementUnit.new(PlacementGround.Kind.JUNCTION, tiles,
			Rect2(Vector2(tiles.position) * Tuning.TILE_SIZE, Vector2(tiles.size) * Tuning.TILE_SIZE),
			locations, 11)

static func _accepts_all(_id: String) -> bool:
	return true

static func _accepts_no_row(id: String) -> bool:
	return id == ViewBag.EMPTY

static func _weighs_one(_id: String) -> float:
	return 1.0

func _test_every_unit_is_handed_the_same_bag(t: TestRunner) -> void:
	var bags := WholeWalkBag.new({"cafe_tables": 3, ViewBag.EMPTY: 2}, 5)
	t.check(bags.bag_for(_unit(0)) == bags.bag_for(_unit(1)),
			"two units of the walk are answered the one bag")

## A bag of one row's marble and one empty marble: the first unit's rules refuse the row, so it
## draws the empty marble, and the row is still in the bag for the second unit, whose rules take it.
func _test_a_marble_one_unit_refuses_is_there_for_the_next(t: TestRunner) -> void:
	var bags := WholeWalkBag.new({"cafe_tables": 1, ViewBag.EMPTY: 1}, 5)
	var first := bags.bag_for(_unit(0)).draw(_accepts_no_row, _weighs_one)
	var second := bags.bag_for(_unit(1)).draw(_accepts_all, _weighs_one)
	t.check(first == ViewBag.EMPTY, "a unit whose rules refuse the row draws the empty marble (%s)"
			% [first])
	t.check(second == "cafe_tables",
			"and the row the first refused is drawn by the next unit that takes it (%s)" % [second])

func _test_the_same_seed_draws_the_same(t: TestRunner) -> void:
	var fill := {"cafe_tables": 4, "dog_walker": 3, ViewBag.EMPTY: 5}
	var alike := WholeWalkBag.new(fill, 9)
	var other := WholeWalkBag.new(fill, 9)
	var elsewhere := WholeWalkBag.new(fill, 10)
	var a: Array[String] = []
	var b: Array[String] = []
	var c: Array[String] = []
	for i in 12:
		a.append(alike.bag_for(_unit(i)).draw(_accepts_all, _weighs_one))
		b.append(other.bag_for(_unit(i)).draw(_accepts_all, _weighs_one))
		c.append(elsewhere.bag_for(_unit(i)).draw(_accepts_all, _weighs_one))
	t.check(a == b, "two walk bags of one fill and seed draw the same marbles (%s)" % [a])
	t.check(a != c, "and another seed draws others, so the seed is what decides (%s)" % [c])
