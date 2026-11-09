extends RefCounted
## `LocationDraw`, the day's open locations each drawn from its view's bag (inbox #1185 in gentle-owl):
## each open location drawn once and what it drew recorded, an event drawn stood in the day, a
## location taken, unavailable or already drawn left alone, a row the day's ground refuses at a
## location never drawn there, a row not drawn once it has stood as many times as the caps handed in say, and
## each location's weight handed to its bag, a draw taken a step at a time holding nothing until it
## ends, a row's offer taking steps of its own, and a row handed to her walk drawn unplaced. Run with
## stand-ins for what it is handed: the day's locations (`_Locations`, a handful built by hand), the
## ground (`_Ground`, whose refusals, weights and offer steps a check sets); the bags are real
## (`ViewBag`), of a few marbles each. The day draws its locations in its own order (`WalkDraw`);
## here they are drawn in the order a check lists.

func run(t) -> void:
	_test_each_open_location_is_drawn_once(t)
	_test_a_taken_unavailable_or_drawn_location_is_left_alone(t)
	_test_a_row_the_ground_refuses_is_never_drawn_there(t)
	_test_a_row_at_its_cap_is_not_drawn(t)
	_test_a_locations_weight_reaches_its_bag(t)
	_test_a_draw_a_step_at_a_time_holds_nothing_until_it_ends(t)
	_test_a_row_handed_to_her_walk_is_drawn_unplaced(t)

const ON := PlacementView.View.ON_THE_ROUTE

class _Locations extends DayLocations:
	var order: Array[Location] = []
	var recorded := {}

	## Overrides DayLocations.record.
	func record(location: Location, plan: EventScheduler.Planned) -> void:
		recorded[location] = plan
		location.record(plan)

class _Ground extends LocationGround:
	## `[row id, location]` pairs refused.
	var refused: Array = []
	## Location -> its weight for every row.
	var weights := {}
	var stood: Array[EventScheduler.Planned] = []
	## How many steps each offer takes, one when unset.
	var offer_steps := 1

	## Overrides LocationGround.begin_offer.
	func begin_offer(def: EventDef, location: Location) -> LocationGround.Offer:
		return _Offer.new(offer(def, location), offer_steps)

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location) -> EventScheduler.Planned:
		if refused.has([def.id, location]):
			return null
		return EventScheduler.Planned.new(def, location.centre())

	## Overrides LocationGround.scale.
	func scale(_def: EventDef, location: Location) -> float:
		return float(weights.get(location, 1.0))

	## Overrides LocationGround.stand.
	func stand(plan: EventScheduler.Planned) -> void:
		stood.append(plan)

## An offer made on its `steps`th step.
class _Offer extends LocationGround.Offer:
	var _left := 0

	func _init(made: EventScheduler.Planned, steps: int) -> void:
		super(made)
		_left = steps

	## Overrides LocationGround.Offer.step.
	func step() -> bool:
		_left -= 1
		return _left <= 0

static func _location(x: int, available := true) -> Location:
	var tiles := Rect2i(Vector2i(x * 4, 0), Vector2i(3, 2))
	return Location.new(StreetNetwork.Segment.new(Vector2i(x, 0), true), 0, tiles,
			Vector2(tiles.position) * Tuning.TILE_SIZE, ON, available, Location.Kind.SIDEWALK)

static func _row(id: String, most := -1) -> EventDef:
	var def: EventDef = EventCatalogue.by_id(id).duplicate()
	if most >= 0:
		def.max_per_day = most
	return def

## The draw over `locations`, a bag of `fill` for the route view, `rows` the marbles' rows.
static func _drawn(locations: _Locations, fill: Dictionary, rows: Dictionary, ground: _Ground,
		caps := {}, seed_value := 1) -> Array[EventScheduler.Planned]:
	var bags := {ON: ViewBag.new(fill, seed_value)}
	var draw := LocationDraw.new(locations, bags, rows, ground, caps)
	var placed: Array[EventScheduler.Planned] = []
	for location in locations.order:
		var plan := draw.draw(location)
		if plan:
			placed.append(plan)
	return placed

func _test_each_open_location_is_drawn_once(t) -> void:
	var locations := _Locations.new()
	locations.order = [_location(0), _location(1), _location(2)] as Array[Location]
	var ground := _Ground.new()
	var placed := _drawn(locations, {"cafe_tables": 2, ViewBag.EMPTY: 1},
			{"cafe_tables": _row("cafe_tables")}, ground)
	t.check(locations.recorded.size() == 3, "each of three open locations is drawn (%d recorded)"
			% locations.recorded.size())
	t.check(placed.size() == 2 and ground.stood == placed,
			"a fill of two cafes and one empty puts two cafes down, each stood in the day (%d)"
			% placed.size())
	var empties := 0
	for location: Location in locations.recorded:
		if locations.recorded[location] == null:
			empties += 1
		t.check(location.is_drawn(), "and every location says it is drawn")
	t.check(empties == 1, "and the third draws the empty event (%d)" % empties)

func _test_a_taken_unavailable_or_drawn_location_is_left_alone(t) -> void:
	var taken := _location(0)
	taken.take(EventScheduler.Planned.new(_row("roadblock"), taken.centre()))
	var closed := _location(1, false)
	var drawn := _location(2)
	drawn.record(null)
	var open := _location(3)
	var locations := _Locations.new()
	locations.order = [taken, closed, drawn, open] as Array[Location]
	_drawn(locations, {"cafe_tables": 4}, {"cafe_tables": _row("cafe_tables")}, _Ground.new())
	t.check(locations.recorded.keys() == [open],
			"only the open location is drawn: one taken, one unavailable and one drawn already are not")

func _test_a_row_the_ground_refuses_is_never_drawn_there(t) -> void:
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
		var at: EventScheduler.Planned = locations.recorded[refusing]
		never = never and at != null and at.row_id() == "dog_walker"
	t.check(never, "a location whose ground refuses the cafe draws the dog walker instead, every time")

func _test_a_row_at_its_cap_is_not_drawn(t) -> void:
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
func _test_a_locations_weight_reaches_its_bag(t) -> void:
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

## A bag of one cafe and a ground whose offers take three steps: the draw takes three steps, holding
## nothing and standing nothing until `finish()`, which records and stands the cafe.
func _test_a_draw_a_step_at_a_time_holds_nothing_until_it_ends(t) -> void:
	var location := _location(0)
	var locations := _Locations.new()
	locations.order = [location] as Array[Location]
	var ground := _Ground.new()
	ground.offer_steps = 3
	var draw := LocationDraw.new(locations, {ON: ViewBag.new({"cafe_tables": 1}, 1)},
			{"cafe_tables": _row("cafe_tables")}, ground, {})
	var asking := draw.begin(location)
	var over: Array[bool] = []
	for _i in 3:
		over.append(asking.step())
	t.check(over == ([false, false, true] as Array[bool]),
			"an offer of three steps takes the draw three steps (%s)" % [over])
	t.check(not location.is_drawn() and locations.recorded.is_empty() and ground.stood.is_empty(),
			"and until it is finished the location holds nothing and nothing is stood")
	var plan := draw.finish(asking)
	t.check(plan != null and location.is_drawn() and locations.recorded[location] == plan
			and ground.stood == ([plan] as Array[EventScheduler.Planned]),
			"finished, the cafe is recorded at the location and stood")

## A bag of one poster crew, a row her walk sites (`EventDef.is_handed_to_her_walk()`): the location
## draws it, and what is recorded, stood and answered is the crew with no position, for the walk.
func _test_a_row_handed_to_her_walk_is_drawn_unplaced(t) -> void:
	var location := _location(0)
	var locations := _Locations.new()
	locations.order = [location] as Array[Location]
	var ground := _Ground.new()
	var placed := _drawn(locations, {"poster_crew": 1}, {"poster_crew": _row("poster_crew")}, ground)
	var recorded: EventScheduler.Planned = locations.recorded.get(location)
	t.check(placed.size() == 1 and placed[0].row_id() == "poster_crew" and not placed[0].is_placed(),
			"a drawn crew is answered with no position")
	t.check(recorded == placed[0] and ground.stood == placed,
			"and it is what the location records and the day stands")
