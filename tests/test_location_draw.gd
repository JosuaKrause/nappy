extends RefCounted
## `LocationDraw`, the day's open locations each drawn from its view's bag at dawn
## (inbox #1185 in gentle-owl): each open location drawn once and what it drew recorded, an event
## drawn standing among what the next location is judged by, a location taken, unavailable or already
## drawn left alone, a row the day's ground refuses at a location never drawn there, a row not drawn
## once it has stood as many times as the caps handed in say, each location's weight handed to its
## bag, a row handed to her walk drawn unplaced, and each location judged among the plans the draw
## was handed and those it placed since. Run with stand-ins for what it is handed: the day's
## locations (`_Locations`, a handful built by hand), the ground (`_Ground`, whose refusals and
## weights a check sets); the bags are real (`ViewBag`), of a few marbles each.

func run(t: TestRunner) -> void:
	_test_each_open_location_is_drawn_once(t)
	_test_a_taken_unavailable_or_drawn_location_is_left_alone(t)
	_test_a_row_the_ground_refuses_is_never_drawn_there(t)
	_test_a_row_at_its_cap_is_not_drawn(t)
	_test_a_locations_weight_reaches_its_bag(t)
	_test_each_location_is_judged_among_the_plans_handed_in_and_those_placed_since(t)
	_test_a_row_handed_to_her_walk_is_drawn_unplaced(t)

const ON := PlacementView.View.ON_THE_ROUTE

class _Locations extends DayLocations:
	var order: Array[Location] = []
	var recorded := {}

	## Overrides DayLocations.drawing_order.
	func drawing_order(_rng: RandomNumberGenerator) -> Array[Location]:
		return order

	## Overrides DayLocations.record.
	func record(location: Location, plan: EventPlan) -> void:
		recorded[location] = plan
		location.record(plan)

class _Ground extends LocationGround:
	## `[row id, location]` pairs refused.
	var refused: Array = []
	## Location -> its weight for every row.
	var weights := {}
	## The plans each ask was judged among, in the order asked.
	var asked_among: Array = []

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location, among: Array[EventPlan]) -> EventPlan:
		asked_among.append(among.duplicate())
		if refused.has([def.id, location]):
			return null
		return EventPlan.new(def, location.centre())

	## Overrides LocationGround.scale.
	func scale(_def: EventDef, location: Location) -> float:
		return float(weights.get(location, 1.0))

static func _location(x: int, available := true) -> Location:
	var tiles := Rect2i(Vector2i(x * 4, 0), Vector2i(3, 2))
	return Location.new(StreetNetwork.Segment.new(Vector2i(x, 0), true), 0, tiles,
			Vector2(tiles.position) * Tuning.TILE_SIZE, ON, available, Location.Kind.SIDEWALK)

static func _row(id: String, most := -1) -> EventDef:
	var def: EventDef = EventCatalogue.by_id(id).duplicate()
	if most >= 0:
		def.max_per_day = most
	return def

static func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	return rng

## The draw over `locations`, a bag of `fill` for the route view, `rows` the marbles' rows.
static func _drawn(locations: _Locations, fill: Dictionary, rows: Dictionary, ground: _Ground,
		caps := {}, seed_value := 1, among: Array[EventPlan] = []) -> Array[EventPlan]:
	var bags := {ON: ViewBag.new(fill, seed_value)}
	return LocationDraw.new(locations, bags, rows, ground, caps).draw_all(_rng(), among)

func _test_each_open_location_is_drawn_once(t: TestRunner) -> void:
	var locations := _Locations.new()
	locations.order = [_location(0), _location(1), _location(2)] as Array[Location]
	var ground := _Ground.new()
	var placed := _drawn(locations, {"cafe_tables": 2, ViewBag.EMPTY: 1},
			{"cafe_tables": _row("cafe_tables")}, ground)
	t.check(locations.recorded.size() == 3, "each of three open locations is drawn (%d recorded)"
			% locations.recorded.size())
	t.check(placed.size() == 2,
			"a fill of two cafes and one empty puts two cafes down (%d)" % placed.size())
	var empties := 0
	for location: Location in locations.recorded:
		if locations.recorded[location] == null:
			empties += 1
		t.check(location.is_drawn(), "and every location says it is drawn")
	t.check(empties == 1, "and the third draws the empty event (%d)" % empties)

## The judge is handed the plans the draw was given, then each plan the draw placed, the one it
## stands for the next location, and the list the draw was given is left as it was.
func _test_each_location_is_judged_among_the_plans_handed_in_and_those_placed_since(
		t: TestRunner) -> void:
	var locations := _Locations.new()
	locations.order = [_location(0), _location(1), _location(2)] as Array[Location]
	var ground := _Ground.new()
	var given := EventPlan.new(_row("roadblock"), Vector2.ZERO)
	var among: Array[EventPlan] = [given]
	var placed := _drawn(locations, {"cafe_tables": 1}, {"cafe_tables": _row("cafe_tables")}, ground,
			{}, 1, among)
	t.check(placed.size() == 3 and ground.asked_among.size() == 3,
			"a bag of cafes places one at each of three locations (%d placed, %d asks)"
			% [placed.size(), ground.asked_among.size()])
	if placed.size() != 3 or ground.asked_among.size() != 3:
		return
	for i in 3:
		var seen: Array = ground.asked_among[i]
		t.check(seen.size() == 1 + i and seen[0] == given,
				"location %d is judged among the handed-in plan and the %d placed before it (%d)"
				% [i, i, seen.size()])
		if i > 0 and seen.size() > i:
			t.check(seen[i] == placed[i - 1], "and the last of them is the one placed just before")
	t.check(among == ([given] as Array[EventPlan]), "the list handed in is not added to")

func _test_a_taken_unavailable_or_drawn_location_is_left_alone(t: TestRunner) -> void:
	var taken := _location(0)
	taken.take(EventPlan.new(_row("roadblock"), taken.centre()))
	var closed := _location(1, false)
	var drawn := _location(2)
	drawn.record(null)
	var open := _location(3)
	var locations := _Locations.new()
	locations.order = [taken, closed, drawn, open] as Array[Location]
	_drawn(locations, {"cafe_tables": 4}, {"cafe_tables": _row("cafe_tables")}, _Ground.new())
	t.check(locations.recorded.keys() == [open],
			"only the open location is drawn: one taken, one unavailable and one drawn already are not")

func _test_a_row_the_ground_refuses_is_never_drawn_there(t: TestRunner) -> void:
	var never := true
	for seed_value in 50:
		var refusing := _location(0)
		var other := _location(1)
		var locations := _Locations.new()
		locations.order = [refusing, other] as Array[Location]
		var ground := _Ground.new()
		ground.refused = [["cafe_tables", refusing]]
		_drawn(locations, {"cafe_tables": 1, "dog_walker": 1},
				{"cafe_tables": _row("cafe_tables"), "dog_walker": _row("dog_walker")}, ground, {},
				seed_value)
		var at: EventPlan = locations.recorded[refusing]
		never = never and at != null and at.row_id() == "dog_walker"
	t.check(never, "a location whose ground refuses the cafe draws the dog walker instead, every time")

func _test_a_row_at_its_cap_is_not_drawn(t: TestRunner) -> void:
	var capped := _Locations.new()
	capped.order = [_location(0), _location(1), _location(2)] as Array[Location]
	var placed := _drawn(capped, {"cafe_tables": 3}, {"cafe_tables": _row("cafe_tables")},
			_Ground.new(), {"cafe_tables": 1})
	t.check(placed.size() == 1, "a row whose cap is one is drawn once (%d)" % placed.size())
	var two := _Locations.new()
	two.order = [_location(0), _location(1), _location(2)] as Array[Location]
	placed = _drawn(two, {"cafe_tables": 3}, {"cafe_tables": _row("cafe_tables")}, _Ground.new(),
			{"cafe_tables": 2})
	t.check(placed.size() == 2, "a cap of two, twice: the cap is the one handed in (%d)" % placed.size())
	var uncapped := _Locations.new()
	uncapped.order = [_location(0), _location(1), _location(2)] as Array[Location]
	placed = _drawn(uncapped, {"cafe_tables": 3}, {"cafe_tables": _row("cafe_tables", 1)},
			_Ground.new(), {})
	t.check(placed.size() == 3, "and at every location on a walk that hands no caps (%d)" % placed.size())

## A cafe and an empty marble: a location weighing the cafe a thousand times over draws it on nearly
## every seed, one weighing it as the bag does about half the time.
func _test_a_locations_weight_reaches_its_bag(t: TestRunner) -> void:
	var heavy := 0
	var plain := 0
	for seed_value in 200:
		var weighed := _location(0)
		var locations := _Locations.new()
		locations.order = [weighed] as Array[Location]
		var ground := _Ground.new()
		ground.weights = {weighed: 1000.0}
		if not _drawn(locations, {"cafe_tables": 1, ViewBag.EMPTY: 1},
				{"cafe_tables": _row("cafe_tables")}, ground, {}, seed_value).is_empty():
			heavy += 1
		var even := _Locations.new()
		even.order = [_location(1)] as Array[Location]
		if not _drawn(even, {"cafe_tables": 1, ViewBag.EMPTY: 1},
				{"cafe_tables": _row("cafe_tables")}, _Ground.new(), {}, seed_value).is_empty():
			plain += 1
	t.check(heavy > 190, "a location weighing the cafe a thousand times over draws it (%d of 200)" % heavy)
	t.check(plain > 60 and plain < 140, "one weighing it as the bag does, about half the time (%d of 200)"
			% plain)

## A bag of poster crews, a row her walk sites (`EventDef.is_handed_to_her_walk()`): the location
## draws one, and what is recorded and answered is the crew with no position, for the walk; the
## location after it is judged among that crew, so no row drawn after it is spaced from a place it
## never stands on.
func _test_a_row_handed_to_her_walk_is_drawn_unplaced(t: TestRunner) -> void:
	var location := _location(0)
	var locations := _Locations.new()
	locations.order = [location, _location(1)] as Array[Location]
	var ground := _Ground.new()
	var placed := _drawn(locations, {"poster_crew": 2}, {"poster_crew": _row("poster_crew")},
			ground)
	var recorded: EventPlan = locations.recorded.get(location)
	t.check(placed.size() == 2 and placed[0].row_id() == "poster_crew" \
			and not placed[0].is_placed(), "a drawn crew is answered with no position")
	t.check(recorded == placed[0], "and it is what the location records")
	if placed.size() != 2 or ground.asked_among.size() != 2:
		return
	var next_among: Array = ground.asked_among[1]
	t.check(next_among == [placed[0]],
			"and the next location is judged among that crew with no position (%d)"
			% next_among.size())
