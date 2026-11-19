extends RefCounted
## `MarbleDraw`, one unit's draw: a marble drawn before it has a place, then laid out in the unit
## with the unit's other rows (inbox #1466 in silky-lemur). A row lands on the location that takes it, not the
## first of the unit; no location has first pick; a larger row drawn later is laid out first and
## the smaller ones move; a row the layout cannot hold beside the drawn ones is refused as it comes
## up, so across from a row the rest refuse a real bag's draw is mostly empty (the player's
## restaurant example), and one whose share does not fit the room left is refused without the
## ground being asked;
## one of a row in a unit; a row's weight the largest the locations it may stand on weigh it,
## on a street built as the game builds one; a row handed to her walk recorded with no position and
## the next row judged without it; a row that travels a sidewalk taking one location of it, as any
## other sidewalk row; every open location ends recorded as drawn, one not open left alone; and the
## plans handed in are left as handed; and where the walk stands one event a unit, the unit draws one
## marble and stops. A row rigged in front of the units' draws is drawn before the unit's own bag,
## as the same row the bag names, where the unit can stand it; it takes its room as any marble does;
## and one the unit cannot stand stays in front, unspent.
##
## Run with stand-ins for what it is handed: the day's locations (`_Locations`, which records each
## draw), the ground (`_Ground`, whose refusals, refusals among a named row and weights a check
## sets, and which records each ask) and the bag (`_Bag`, which answers a scripted run of marbles
## and records what each `accepts` said and what each marble weighed; the restaurant example draws
## from a real `ViewBag`, plain state, since what it holds is how a bag's empty marbles and its
## refusals add up); the units and their
## locations are state, built by hand, and the rows come from the catalogue. `UnitRoom` is real:
## `MarbleDraw` makes its own from the unit as part of the draw (`UnitRoom.of()`), with nothing to
## hand a stand-in to, and it is pure arithmetic on the unit's open locations, checked in its own
## suite (`tests/test_unit_room.gd`).

func run(t: TestRunner) -> void:
	_test_a_row_lands_on_the_location_that_offers_it(t)
	_test_no_location_has_first_pick(t)
	_test_a_larger_row_drawn_later_is_laid_out_first(t)
	_test_a_row_the_layout_cannot_hold_is_refused_as_it_comes_up(t)
	_test_across_from_a_drawn_row_the_draw_is_mostly_empty(t)
	_test_a_share_the_room_does_not_fit_is_refused_unasked(t)
	_test_one_of_a_row_in_a_unit(t)
	_test_a_rows_weight_is_the_largest_of_its_locations(t)
	_test_a_row_handed_to_her_walk_is_recorded_unplaced(t)
	_test_a_row_that_travels_a_sidewalk_takes_one_location(t)
	_test_every_open_location_ends_drawn(t)
	_test_the_plans_handed_in_are_left_as_handed(t)
	_test_one_marble_a_unit_stands_a_row_alone(t)
	_test_one_marble_a_unit_an_empty_marble_leaves_it_empty(t)
	_test_one_marble_a_unit_a_refused_row_gives_way_to_the_next(t)
	_test_a_row_rigged_in_front_is_drawn_before_the_bag_as_the_row_the_bag_names(t)
	_test_a_row_rigged_in_front_takes_its_room(t)
	_test_a_row_rigged_in_front_the_unit_cannot_stand_stays_in_front(t)

const ON := PlacementView.View.ON_THE_ROUTE

class _Locations extends DayLocations:
	## Location -> the plan recorded there, null for the empty event.
	var recorded := {}

	## Overrides DayLocations.record.
	func record(location: Location, plan: EventPlan) -> void:
		recorded[location] = plan
		location.record(plan)

class _Ground extends LocationGround:
	## `[row id, location]` pairs refused.
	var refused: Array = []
	## Row id -> the id of a row which, standing among the plans judged, refuses it everywhere.
	var refused_among := {}
	## Row id -> {location -> its weight}; one where not set.
	var weights := {}
	## `[row id, location, the plans judged among]` per ask, in the order asked.
	var asked: Array = []

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location, among: Array[EventPlan]) -> EventPlan:
		asked.append([def.id, location, among.duplicate()])
		if refused.has([def.id, location]):
			return null
		var by: String = refused_among.get(def.id, "")
		for plan in among:
			if plan.is_placed() and plan.row_id() == by:
				return null
		return EventPlan.new(def, location.centre())

	## Overrides LocationGround.scale.
	func scale(def: EventDef, location: Location) -> float:
		var of_row: Dictionary = weights.get(def.id, {})
		return float(of_row.get(location, 1.0))

	## The asks for `id`.
	func asks_for(id: String) -> Array:
		var found: Array = []
		for ask: Array in asked:
			if ask[0] == id:
				found.append(ask)
		return found

class _Bag extends ViewBag:
	## The marbles still to come up, in order.
	var _marbles: Array[String] = []
	## `[marble, what accepts said]` per marble come up.
	var said: Array = []
	## Marble -> the weight `scale` gave it.
	var weighed := {}

	func _init(marbles: Array[String]) -> void:
		super({ViewBag.EMPTY: 1}, 0)
		_marbles = marbles.duplicate()

	## Overrides ViewBag.draw.
	func draw(accepts: Callable, scale: Callable) -> String:
		while not _marbles.is_empty():
			var marble: String = _marbles.pop_front()
			if marble == ViewBag.EMPTY:
				said.append([marble, true])
				return marble
			weighed[marble] = float(scale.call(marble))
			var yes: bool = accepts.call(marble)
			said.append([marble, yes])
			if yes:
				return marble
		return ViewBag.EMPTY

## A street laid out as `StreetLocations` lays one: three sections along it (3, 2 and 3 tiles),
## then each section's two sidewalk locations, the near side's first (so `locations()[3 + 2 * s]`
## is section `s`'s near sidewalk and the one after it its far one), on the day `day_seed`.
static func _street(day_seed := 7) -> PlacementUnit:
	var segment := StreetNetwork.Segment.new(Vector2i(1, 1), true)
	var rect := segment.tile_rect()
	var starts: Array[int] = [0, 3, 5]
	var lengths: Array[int] = [3, 2, 3]
	var locations: Array[Location] = []
	for section in 3:
		var tiles := Rect2i(rect.position + Vector2i(starts[section], 0),
				Vector2i(lengths[section], rect.size.y))
		locations.append(_at(segment, section, tiles, Location.Kind.SECTION))
	for section in 3:
		for band in Corridor.sidewalk_bands(Rect2i(rect.position + Vector2i(starts[section], 0),
				Vector2i(lengths[section], rect.size.y)), true):
			locations.append(_at(segment, section, band, Location.Kind.SIDEWALK))
	return PlacementUnit.new(PlacementGround.Kind.STREET, rect, Rect2(), locations, day_seed)

static func _at(segment: StreetNetwork.Segment, section: int, tiles: Rect2i,
		kind: Location.Kind) -> Location:
	return Location.new(segment, section, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE, ON,
			true, kind)

## An open lot of `cells` cells.
static func _lot(cells: int) -> PlacementUnit:
	var whole := Rect2i(Vector2i(40, 40), Vector2i(4 * cells, 4))
	var locations: Array[Location] = []
	for x in cells:
		var tiles := Rect2i(whole.position + Vector2i(4 * x, 0), Vector2i(4, 4))
		locations.append(Location.new(null, 0, tiles, Vector2(tiles.get_center()) * Tuning.TILE_SIZE,
				ON, true, Location.Kind.OPEN, whole))
	return PlacementUnit.new(PlacementGround.Kind.OPEN, whole, Rect2(), locations, 7)

## The rows the marbles `ids` name.
static func _rows(ids: Array[String]) -> Dictionary:
	var rows := {}
	for id in ids:
		rows[id] = EventCatalogue.by_id(id)
	return rows

## `unit` drawn from `bag` among `among`, its rows the marbles' and the catalogue's.
static func _drawn(unit: PlacementUnit, bag: _Bag, ground: _Ground, locations: _Locations,
		among: Array[EventPlan] = [], one_marble_a_unit := false,
		in_front: MarbleBag = null) -> Array[EventPlan]:
	var ids: Array[String] = ["cafe_tables", "busker", "roadblock", "chatting_mother",
			"poster_crew", "market_stall", "leaf_blower", "homeless_yeller"]
	return MarbleDraw.new(locations, _rows(ids), ground, one_marble_a_unit).draw(unit, bag, among,
			in_front)

## A bag in front of the units' draws holding `id`'s row, as `UnitDraw.rig_the_next_draw()` rigs one.
static func _rigged_front(id: String) -> MarbleBag:
	var front := MarbleBag.new([], [], 0)
	front.rig([EventCatalogue.by_id(id)], 1)
	return front

## Where `id` was recorded, or null.
static func _where(locations: _Locations, id: String) -> Location:
	for location: Location in locations.recorded:
		var plan: EventPlan = locations.recorded[location]
		if plan and plan.row_id() == id:
			return location
	return null

## The ground refusing a cafe at every sidewalk location but section 2's far one: the cafe stands
## there, not on the first location of the unit nor the first of the order it draws in.
func _test_a_row_lands_on_the_location_that_offers_it(t: TestRunner) -> void:
	var every_time := true
	for seed_value in 12:
		var street := _street(seed_value)
		var target := street.locations()[8]
		var ground := _Ground.new()
		for location in street.locations():
			if location != target:
				ground.refused.append(["cafe_tables", location])
		var locations := _Locations.new()
		_drawn(street, _Bag.new(["cafe_tables"] as Array[String]), ground, locations)
		every_time = every_time and _where(locations, "cafe_tables") == target
	t.check(every_time, "a cafe one sidewalk location alone offers stands there, on every seed")

## Over 60 days, a street drawing one cafe that every sidewalk location offers and weighs alike
## puts it on each of its six sidewalk locations, none more than half the time: the order a tie is
## broken in is the unit's own stream's.
func _test_no_location_has_first_pick(t: TestRunner) -> void:
	var counts := {}
	for seed_value in 60:
		var street := _street(1000 + seed_value)
		var locations := _Locations.new()
		_drawn(street, _Bag.new(["cafe_tables"] as Array[String]), _Ground.new(), locations)
		var at := _where(locations, "cafe_tables")
		var index := street.locations().find(at)
		counts[index] = int(counts.get(index, 0)) + 1
	var most := 0
	for index: int in counts:
		most = maxi(most, int(counts[index]))
	t.check(counts.size() == 6 and not counts.has(0) and not counts.has(1) and not counts.has(2)
			and most <= 30, "the first row of 60 days stands on each of the six sidewalk locations, "
			+ "none more than half the time (%s)" % [counts])

## A cafe weighed five times over on section 1's near sidewalk, then a street musician, then a
## roadblock only section 1 takes: the cafe stood on section 1 while the street held two small
## rows, and the roadblock, laid first once drawn, takes section 1 and moves the cafe off it.
func _test_a_larger_row_drawn_later_is_laid_out_first(t: TestRunner) -> void:
	var street := _street()
	var first_near := street.locations()[5]
	var ground := _Ground.new()
	ground.weights = {"cafe_tables": {first_near: 5.0}}
	ground.refused = [["roadblock", street.locations()[0]], ["roadblock", street.locations()[2]]]
	var bag := _Bag.new(["cafe_tables", "busker", "roadblock"] as Array[String])
	var locations := _Locations.new()
	var placed := _drawn(street, bag, ground, locations)
	var ids: Array[String] = []
	for plan in placed:
		ids.append(plan.row_id())
	t.check(ids == (["cafe_tables", "busker", "roadblock"] as Array[String]),
			"the three rows are placed, answered in the order drawn (%s)" % [ids])
	var first_ask: Array = ground.asks_for("cafe_tables")[0]
	t.check(first_ask[1] == first_near, "the cafe was first offered the location weighing it most")
	t.check(_where(locations, "roadblock") == street.locations()[1],
			"the roadblock drawn last takes the section that offers it")
	var cafe_at := _where(locations, "cafe_tables")
	t.check(cafe_at != null and cafe_at.section() != 1,
			"and the cafe moved off that section (section %d)"
			% (cafe_at.section() if cafe_at else -1))

## A street musician the ground refuses wherever a cafe stands among the plans judged: drawn after
## the cafe, it is refused as it comes up, and the cafe keeps its place.
func _test_a_row_the_layout_cannot_hold_is_refused_as_it_comes_up(t: TestRunner) -> void:
	var street := _street()
	var ground := _Ground.new()
	ground.refused_among = {"busker": "cafe_tables"}
	var bag := _Bag.new(["cafe_tables", "busker"] as Array[String])
	var locations := _Locations.new()
	var placed := _drawn(street, bag, ground, locations)
	t.check(bag.said == [["cafe_tables", true], ["busker", false]],
			"the musician is refused as it comes up (%s)" % [bag.said])
	t.check(placed.size() == 1 and placed[0].row_id() == "cafe_tables"
			and _where(locations, "cafe_tables") != null, "and the cafe keeps a place")

## **Across from a drawn row the draw is mostly empty** *(inbox #1185 in gentle-owl: "if a
## restaurant is drawn the other side is drawn with only a subset of valid restaurant adjacent
## events (most likely just 'empty' but could have 'yeller' with a low chance for later days)", and
## "the bag itself doesn't change just that the invalid events don't get considered when
## drawing")*: a real bag of a cafe, a market stall and a leaf blower ten marbles each, a man shouting
## two and thirty empty, drawn on 60 streets with a chatting mother standing across (among the plans
## judged), the ground refusing every row but the man shouting beside her, and on the same 60
## streets with nothing across. Across from her the sidewalks end empty more often than with
## nothing there, and hold nothing but the man shouting, who still stands on some of them.
func _test_across_from_a_drawn_row_the_draw_is_mostly_empty(t: TestRunner) -> void:
	var fill := {"cafe_tables": 10, "market_stall": 10, "leaf_blower": 10, "homeless_yeller": 2,
			ViewBag.EMPTY: 30}
	var mother := EventPlan.new(EventCatalogue.by_id("chatting_mother"), Vector2(-640, -640))
	var empty := {true: 0, false: 0}
	var sidewalks := 0
	var only_the_yeller := true
	var yellers := 0
	for seed_value in 60:
		for across: bool in [true, false]:
			var street := _street(3000 + seed_value)
			var ground := _Ground.new()
			ground.refused_among = {"cafe_tables": "chatting_mother",
					"market_stall": "chatting_mother", "leaf_blower": "chatting_mother"}
			var locations := _Locations.new()
			var among: Array[EventPlan] = []
			if across:
				among.append(mother)
			MarbleDraw.new(locations, _rows(["cafe_tables", "market_stall", "leaf_blower",
					"homeless_yeller"] as Array[String]), ground).draw(street,
					ViewBag.new(fill, seed_value), among)
			for location in street.locations():
				if location.kind() != Location.Kind.SIDEWALK:
					continue
				var plan: EventPlan = locations.recorded.get(location)
				if across:
					sidewalks += 1
				if plan == null:
					empty[across] = int(empty[across]) + 1
				elif across:
					only_the_yeller = only_the_yeller and plan.row_id() == "homeless_yeller"
					yellers += 1
	t.check(sidewalks > 0 and int(empty[true]) > int(empty[false]),
			"across from her the sidewalks end empty more often (%d of %d) than with nothing there "
			% [empty[true], sidewalks] + "(%d)" % [empty[false]])
	t.check(only_the_yeller and yellers > 0,
			"and hold nothing but the man shouting, who stands on %d of them" % yellers)

## After a small marble a section does not fit (`UnitRoom`): the roadblock that comes up next is
## refused and the ground is never asked about it.
func _test_a_share_the_room_does_not_fit_is_refused_unasked(t: TestRunner) -> void:
	var ground := _Ground.new()
	var bag := _Bag.new(["cafe_tables", "roadblock"] as Array[String])
	_drawn(_street(), bag, ground, _Locations.new())
	t.check(bag.said == [["cafe_tables", true], ["roadblock", false]],
			"a roadblock after a cafe is refused (%s)" % [bag.said])
	t.check(ground.asks_for("roadblock").is_empty(), "without the ground being asked")

func _test_one_of_a_row_in_a_unit(t: TestRunner) -> void:
	var bag := _Bag.new(["cafe_tables", "cafe_tables"] as Array[String])
	var placed := _drawn(_street(), bag, _Ground.new(), _Locations.new())
	t.check(bag.said == [["cafe_tables", true], ["cafe_tables", false]] and placed.size() == 1,
			"a second cafe in a street is refused (%s)" % [bag.said])

## A street built as the game builds one with a sidewalk held: section 2's near sidewalk holds a
## busker, which closes section 2 (`DayLocations.assign_to()`). The cafe weighed 3 and 7 on two
## open sidewalk locations, 1000 on the held one and 100 on a section; the roadblock 4 on section 1
## and 9 on the closed section 2. The cafe weighs 7 and the roadblock 4.
func _test_a_rows_weight_is_the_largest_of_its_locations(t: TestRunner) -> void:
	var street := _street()
	var at := street.locations()
	at[7].take(EventPlan.new(EventCatalogue.by_id("busker"), at[7].centre()))
	at[2].record(null)
	var ground := _Ground.new()
	ground.weights = {
		"cafe_tables": {at[3]: 3.0, at[4]: 7.0, at[7]: 1000.0, at[0]: 100.0},
		"roadblock": {at[1]: 4.0, at[2]: 9.0, at[5]: 50.0},
	}
	var bag := _Bag.new(["cafe_tables", "roadblock"] as Array[String])
	_drawn(street, bag, ground, _Locations.new())
	t.check(is_equal_approx(float(bag.weighed.get("cafe_tables", 0.0)), 7.0),
			"a sidewalk row weighs the most an open sidewalk location weighs it (%s)"
			% bag.weighed.get("cafe_tables"))
	t.check(is_equal_approx(float(bag.weighed.get("roadblock", 0.0)), 4.0),
			"a row across the street the most an open section weighs it (%s)"
			% bag.weighed.get("roadblock"))

## A poster crew, a row her walk sites, then a cafe: the crew is answered and recorded with no
## position, and the cafe is judged among no placed crew.
func _test_a_row_handed_to_her_walk_is_recorded_unplaced(t: TestRunner) -> void:
	var street := _street()
	var ground := _Ground.new()
	var locations := _Locations.new()
	var placed := _drawn(street, _Bag.new(["poster_crew", "cafe_tables"] as Array[String]), ground,
			locations)
	t.check(placed.size() == 2 and placed[0].row_id() == "poster_crew"
			and not placed[0].is_placed(), "a drawn crew is answered with no position")
	t.check(placed.size() == 2 and locations.recorded.values().has(placed[0]),
			"and it is what its location records")
	var asks := ground.asks_for("cafe_tables")
	var without := not asks.is_empty()
	for ask: Array in asks:
		for plan: EventPlan in ask[2]:
			without = without and not (plan.row_id() == "poster_crew" and plan.is_placed())
	t.check(without, "the cafe is judged among no placed crew (%d asks)" % asks.size())

## A chatting mother, a row that paces its sidewalk, takes one sidewalk location and no more: drawn
## first, it leaves the street five more, so five more rows are placed beside it, each on a
## location of its own.
func _test_a_row_that_travels_a_sidewalk_takes_one_location(t: TestRunner) -> void:
	var locations := _Locations.new()
	var ids: Array[String] = ["chatting_mother", "cafe_tables", "busker", "market_stall",
			"leaf_blower", "homeless_yeller"]
	var placed := _drawn(_street(), _Bag.new(ids), _Ground.new(), locations)
	var stood := {}
	for plan in placed:
		for location: Location in locations.recorded:
			if locations.recorded[location] == plan:
				stood[location] = true
	t.check(placed.size() == 6 and stood.size() == 6,
			"a chatting mother and five rows beside it stand on six locations of their own (%d placed)"
			% placed.size())

## A lot of three cells, one a dawn phase holds: drawing one cafe records both open cells, one with
## the cafe and the other empty, and leaves the held one alone. A street drawing nothing but empty
## marbles ends with every location drawn.
func _test_every_open_location_ends_drawn(t: TestRunner) -> void:
	var lot := _lot(3)
	var held := lot.locations()[0]
	held.take(EventPlan.new(EventCatalogue.by_id("busker"), held.centre()))
	var locations := _Locations.new()
	_drawn(lot, _Bag.new(["cafe_tables"] as Array[String]), _Ground.new(), locations)
	var empties := 0
	for location: Location in locations.recorded:
		if locations.recorded[location] == null:
			empties += 1
	t.check(locations.recorded.size() == 2 and not locations.recorded.has(held) and empties == 1,
			"the two open cells are recorded, one empty, the held one left alone (%d recorded)"
			% locations.recorded.size())
	var street := _street()
	_drawn(street, _Bag.new([] as Array[String]), _Ground.new(), _Locations.new())
	var all_drawn := true
	for location in street.locations():
		all_drawn = all_drawn and location.is_drawn()
	t.check(all_drawn, "a street that draws only empty marbles ends with every location drawn")

## The plans handed in are what every ask is judged among first, and the list is not added to.
func _test_the_plans_handed_in_are_left_as_handed(t: TestRunner) -> void:
	var given := EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2(-500, -500))
	var among: Array[EventPlan] = [given]
	var ground := _Ground.new()
	_drawn(_street(), _Bag.new(["cafe_tables", "busker"] as Array[String]), ground,
			_Locations.new(), among)
	var first := true
	for ask: Array in ground.asked:
		var seen: Array = ask[2]
		first = first and not seen.is_empty() and seen[0] == given
	t.check(first and ground.asked.size() >= 2, "every ask is judged among the plan handed in")
	t.check(among == ([given] as Array[EventPlan]), "and the list handed in is not added to")

## Whether no location of `unit` is open to a draw any more.
static func _none_open(unit: PlacementUnit) -> bool:
	for location in unit.locations():
		if location.is_open():
			return false
	return true

## A bag scripted with two rows the street could both hold: with the setting on one plan is answered,
## the first row's, the bag was drawn once (the second marble is still in the script, never asked
## of the ground) and every location of the unit is closed to a draw.
func _test_one_marble_a_unit_stands_a_row_alone(t: TestRunner) -> void:
	var street := _street()
	var bag := _Bag.new(["cafe_tables", "busker"] as Array[String])
	var ground := _Ground.new()
	var placed := _drawn(street, bag, ground, _Locations.new(), [], true)
	t.check(placed.size() == 1 and placed[0].row_id() == "cafe_tables",
			"one plan is answered, the first row's (%d placed)" % placed.size())
	t.check(bag.said == [["cafe_tables", true]] and ground.asks_for("busker").is_empty(),
			"the bag was drawn once, and the second row never asked (%s)" % [bag.said])
	t.check(_none_open(street), "and every location of the unit is no longer open")

## The bag scripted empty, then a row: the unit stands nothing, the row is still in the script and
## every location is closed to a draw.
func _test_one_marble_a_unit_an_empty_marble_leaves_it_empty(t: TestRunner) -> void:
	var street := _street()
	var bag := _Bag.new([ViewBag.EMPTY, "cafe_tables"] as Array[String])
	var placed := _drawn(street, bag, _Ground.new(), _Locations.new(), [], true)
	t.check(placed.is_empty() and bag.said == [[ViewBag.EMPTY, true]],
			"an empty marble stands nothing and the row after it is still in the script (%s)"
			% [bag.said])
	t.check(_none_open(street), "and every location of the unit is no longer open")

## The ground refuses a cafe at every location: the bag offers the next marble inside the same draw,
## so the street stands the street musician alone, and the cafe was asked of the ground.
func _test_one_marble_a_unit_a_refused_row_gives_way_to_the_next(t: TestRunner) -> void:
	var street := _street()
	var ground := _Ground.new()
	for location in street.locations():
		ground.refused.append(["cafe_tables", location])
	var bag := _Bag.new(["cafe_tables", "busker", "chatting_mother"] as Array[String])
	var placed := _drawn(street, bag, ground, _Locations.new(), [], true)
	t.check(placed.size() == 1 and placed[0].row_id() == "busker",
			"the refused cafe gives way, and the street stands the musician alone (%d placed)"
			% placed.size())
	t.check(not ground.asks_for("cafe_tables").is_empty() and bag.said.size() == 2,
			"the cafe was asked of the ground, and the draw stopped at the musician (%s)" % [bag.said])

## **A row rigged in front is drawn before the unit's own bag**: the man shouting rigged in front of
## a street whose bag holds a cafe and then a man shouting of its own is laid in the street and
## answered first, the bag's cafe after, and the bag's own man refused as a second of the row in the
## unit; the bag in front holds nothing after.
func _test_a_row_rigged_in_front_is_drawn_before_the_bag_as_the_row_the_bag_names(t: TestRunner) -> void:
	var front := _rigged_front("homeless_yeller")
	var bag := _Bag.new(["cafe_tables", "homeless_yeller"] as Array[String])
	var locations := _Locations.new()
	var placed := _drawn(_street(), bag, _Ground.new(), locations, [] as Array[EventPlan], false, front)
	var ids: Array[String] = []
	for plan in placed:
		ids.append(plan.row_id())
	t.check(ids == ["homeless_yeller", "cafe_tables"] and _where(locations, "homeless_yeller") != null,
			"the rigged man is drawn and laid out first, then the bag's cafe (%s)" % [ids])
	t.check(bag.said.has(["homeless_yeller", false]),
			"and the bag's own man shouting is refused as a second of the row in the unit (%s)"
			% [bag.said])
	t.check(front.peek() == null, "and nothing is left in front")

## **A row rigged in front takes its room as any marble does**: a lot of one cell drawing the rigged
## man is spoken for, and its own bag draws nothing.
func _test_a_row_rigged_in_front_takes_its_room(t: TestRunner) -> void:
	var bag := _Bag.new(["cafe_tables"] as Array[String])
	var placed := _drawn(_lot(1), bag, _Ground.new(), _Locations.new(), [] as Array[EventPlan],
			false, _rigged_front("homeless_yeller"))
	t.check(placed.size() == 1 and placed[0].row_id() == "homeless_yeller" and bag.said.is_empty(),
			"a one-cell lot that draws the rigged man draws no marble of its own (%d placed, %s)"
			% [placed.size(), bag.said])

## **A row rigged in front the unit cannot stand stays in front**, unspent, for the next unit to draw,
## and the unit draws from its own bag as it would with nothing in front.
func _test_a_row_rigged_in_front_the_unit_cannot_stand_stays_in_front(t: TestRunner) -> void:
	var street := _street()
	var ground := _Ground.new()
	for location in street.locations():
		ground.refused.append(["homeless_yeller", location])
	var front := _rigged_front("homeless_yeller")
	var bag := _Bag.new(["cafe_tables"] as Array[String])
	var placed := _drawn(street, bag, ground, _Locations.new(), [] as Array[EventPlan], false, front)
	t.check(placed.size() == 1 and placed[0].row_id() == "cafe_tables",
			"a street that cannot stand the man draws its own cafe (%d placed)" % placed.size())
	var still: Variant = front.peek()
	t.check(still is EventDef and (still as EventDef).id == "homeless_yeller",
			"and the man stays in front for the next unit")
	t.check(ground.asks_for("homeless_yeller").size() <= street.locations().size(),
			"asked of the unit's ground once a draw, not again for every marble (%d asks)"
			% ground.asks_for("homeless_yeller").size())
