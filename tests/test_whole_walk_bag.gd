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

static func _weighs_the_row_most(_id: String) -> float:
	return 1.0e9

static func _weighs_one(_id: String) -> float:
	return 1.0

func _test_every_unit_is_handed_the_same_bag(t: TestRunner) -> void:
	var bags := WholeWalkBag.new({"cafe_tables": 3, ViewBag.EMPTY: 2}, 5)
	t.check(bags.bag_for(_unit(0)) == bags.bag_for(_unit(1)),
			"two units of the walk are answered the one bag")

## A bag of one row's marble and one empty marble, the row weighed a billion to one so it comes up
## first on every seed: the first unit's rules are asked about it and refuse it, so that unit draws
## the empty marble, and the row is still in the bag for the second unit, whose rules take it. A
## refused marble spent instead of left would leave the second unit the empty marble.
func _test_a_marble_one_unit_refuses_is_there_for_the_next(t: TestRunner) -> void:
	for seed_value in 8:
		var bags := WholeWalkBag.new({"cafe_tables": 1, ViewBag.EMPTY: 1}, seed_value)
		var asked: Array[String] = []
		var refuses_the_row := func(id: String) -> bool:
			asked.append(id)
			return id == ViewBag.EMPTY
		var first := bags.bag_for(_unit(0)).draw(refuses_the_row, _weighs_the_row_most)
		var second := bags.bag_for(_unit(1)).draw(_accepts_all, _weighs_the_row_most)
		t.check(asked == ["cafe_tables"],
				"seed %d: the first unit's rules were asked about the row, and refused it (%s)" % [seed_value, asked])
		t.check(first == ViewBag.EMPTY, "seed %d: so it draws the empty marble (%s)" % [seed_value, first])
		t.check(second == "cafe_tables",
				"seed %d: and the row the first refused is drawn by the next unit that takes it (%s)"
						% [seed_value, second])

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
