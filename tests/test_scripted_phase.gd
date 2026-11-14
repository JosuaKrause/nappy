extends RefCounted
## `ScriptedPhase`, the dawn phase for a row the day places for a reason of its own (a scripted row
## on its day): it draws one of the day's open locations, weighted by
## what it is handed, offers it the row, assigns the location what it took and adds it to the day's
## plan, and passes over a location that takes nothing. Run with stand-ins for what it is handed: the
## day's locations (`_Locations`, ground locations with no street, the open ones set by hand), the
## day's plan (`_Events`, a list) and the day's ground (`_Ground`, whose offers a check sets). The
## real ground is the dawn draw's own (`RuledLocationGround`); the phase on a real day is
## `tests/test_events_scheduler.gd`'s.
##
## - **A location weighed nothing is never drawn**, over many streams, and not once every location
##   weighed something has refused either: the row then does not happen, rather than landing where
##   its ground gives it no copies (for a wall, on a route).
## - **The draw follows the weights**: three to one comes out near three in four.
## - **A location that takes nothing is passed over**, and the row goes to the next it draws; none
##   left that takes it, and the row does not happen.
## - **What it takes is assigned and stood**: the location is taken, and the plan is added to the
##   day's; the next ask is judged among it.

const SEEDS := 400

## The day's locations, the open ones set by hand.
class _Locations extends DayLocations:
	var open: Array[Location] = []

	## Overrides DayLocations.open_locations.
	func open_locations() -> Array[Location]:
		var found: Array[Location] = []
		for location in open:
			if not location.is_taken():
				found.append(location)
		return found

	## Overrides DayLocations.assign_to.
	func assign_to(location: Location, plan: EventPlan) -> void:
		location.take(plan)

## The day's plan, kept as a list: what the phase stands in it and what it is read for.
class _Events extends DayEvents:
	var rows: Array[EventPlan] = []

	## Overrides DayEvents.add.
	func add(row: EventPlan) -> void:
		rows.append(row)

	## Overrides DayEvents.placements.
	func placements() -> Array[EventPlan]:
		return rows.duplicate()

## The day's ground: which locations take nothing, and what each ask was judged among.
class _Ground extends LocationGround:
	var refused := {}
	var asked_among: Array = []

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location, among: Array[EventPlan]) -> EventPlan:
		asked_among.append(among.duplicate())
		if refused.has(location):
			return null
		return EventPlan.new(def, location.centre())

func run(t: TestRunner) -> void:
	_test_a_location_weighed_nothing_is_never_drawn(t)
	_test_a_location_weighed_nothing_is_not_drawn_once_the_rest_refuse(t)
	_test_the_draw_follows_the_weights(t)
	_test_a_location_that_takes_nothing_is_passed_over(t)
	_test_what_it_takes_is_assigned_and_stood(t)

func _row() -> EventDef:
	return EventCatalogue.by_id("night_raid")

func _location(i: int) -> Location:
	var tiles := Rect2i(Vector2i(i * 10, 0), Vector2i(4, 4))
	return Location.new(null, 0, tiles, Vector2(i * 320.0 + 64.0, 64.0),
			PlacementView.View.OFF_THE_ROUTE, true, Location.Kind.OPEN)

func _rng(i: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("scripted phase:%d" % i)
	return rng

func _test_a_location_weighed_nothing_is_never_drawn(t: TestRunner) -> void:
	var drawn_nothing := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var zero := _location(0)
		var some := _location(1)
		locations.open = [zero, some]
		var weights := {zero: 0.0, some: 1.0}
		var phase := ScriptedPhase.new(locations, _Events.new(), _Ground.new(),
				func(_def: EventDef, location: Location) -> float: return weights[location])
		phase.place(_row(), _rng(i))
		if zero.is_taken():
			drawn_nothing += 1
	t.check(drawn_nothing == 0, "a location weighed nothing is never drawn (%d of %d)"
			% [drawn_nothing, SEEDS])

func _test_the_draw_follows_the_weights(t: TestRunner) -> void:
	var heavy_taken := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var heavy := _location(0)
		var light := _location(1)
		locations.open = [heavy, light]
		var weights := {heavy: 3.0, light: 1.0}
		var phase := ScriptedPhase.new(locations, _Events.new(), _Ground.new(),
				func(_def: EventDef, location: Location) -> float: return weights[location])
		phase.place(_row(), _rng(i))
		if heavy.is_taken():
			heavy_taken += 1
	var share := float(heavy_taken) / float(SEEDS)
	t.check(share > 0.68 and share < 0.82, "three to one draws the heavy location near three in four (%.2f)"
			% share)

func _test_a_location_that_takes_nothing_is_passed_over(t: TestRunner) -> void:
	var elsewhere := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var refusing := _location(0)
		var taking := _location(1)
		locations.open = [refusing, taking]
		var ground := _Ground.new()
		ground.refused[refusing] = true
		var phase := ScriptedPhase.new(locations, _Events.new(), ground,
				func(_def: EventDef, _location: Location) -> float: return 1.0)
		var plan := phase.place(_row(), _rng(i))
		if plan != null and taking.is_taken() and not refusing.is_taken():
			elsewhere += 1
	t.check(elsewhere == SEEDS, "a location that takes nothing is passed over for the next (%d of %d)"
			% [elsewhere, SEEDS])
	var locations := _Locations.new()
	var only := _location(0)
	locations.open = [only]
	var ground := _Ground.new()
	ground.refused[only] = true
	var events := _Events.new()
	var phase := ScriptedPhase.new(locations, events, ground,
			func(_def: EventDef, _location: Location) -> float: return 1.0)
	t.check(phase.place(_row(), _rng(0)) == null and events.rows.is_empty(),
			"with no location that takes it, the row does not happen")

func _test_what_it_takes_is_assigned_and_stood(t: TestRunner) -> void:
	var locations := _Locations.new()
	var one := _location(0)
	var two := _location(1)
	locations.open = [one, two]
	var ground := _Ground.new()
	var events := _Events.new()
	var given := EventPlan.new(EventCatalogue.by_id("roadblock"), Vector2.ZERO)
	events.add(given)
	var phase := ScriptedPhase.new(locations, events, ground,
			func(_def: EventDef, _location: Location) -> float: return 1.0)
	var plan := phase.place(_row(), _rng(0))
	t.check(plan != null and one.is_taken(), "the location it drew is taken for the day")
	t.check(events.rows == ([given, plan] as Array[EventPlan]), "and the plan is added to the day's")
	t.check(ground.asked_among.size() == 1 and ground.asked_among[0] == [given],
			"the ask was judged among the plans the day held when it was made")
	var second := phase.place(_row(), _rng(1))
	t.check(second != null and two.is_taken(), "the next row the one phase places takes the other")
	t.check(ground.asked_among.size() == 2 and ground.asked_among[1] == [given, plan],
			"and is judged among the day's plans as they are by then, the first row's included")

func _test_a_location_weighed_nothing_is_not_drawn_once_the_rest_refuse(t: TestRunner) -> void:
	var landed := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var refusing := _location(0)
		var zero := _location(1)
		locations.open = [refusing, zero]
		var ground := _Ground.new()
		ground.refused[refusing] = true
		var weights := {refusing: 1.0, zero: 0.0}
		var phase := ScriptedPhase.new(locations, _Events.new(), ground,
				func(_def: EventDef, location: Location) -> float: return weights[location])
		if phase.place(_row(), _rng(i)) != null or zero.is_taken():
			landed += 1
	t.check(landed == 0, "with every weighed location refusing, the row lands on none weighed nothing"
			+ " (%d of %d)" % [landed, SEEDS])
