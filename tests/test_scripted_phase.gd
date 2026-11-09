extends RefCounted
## `ScriptedPhase`, the dawn phase for a row the day places for a reason of its own (a scripted row
## on its day): it draws one of the day's open locations, weighted by
## what it is handed, offers it the row, assigns the location what it took and stands it, and passes
## over a location that takes nothing. Run with stand-ins for what it is handed: the day's locations
## (`_Locations`, ground locations with no street, the open ones set by hand) and the day's ground
## (`_Ground`, whose offers a check sets). The real ground is the dawn draw's own
## (`EventScheduler.RuledLocationGround`); the phase on a real day is `tests/test_events_scheduler.gd`'s.
##
## - **A location weighed nothing is never drawn**, over many streams, and not once every location
##   weighed something has refused either: the row then does not happen, rather than landing where
##   its ground gives it no copies (for a wall, on a route).
## - **The draw follows the weights**: three to one comes out near three in four.
## - **A location that takes nothing is passed over**, and the row goes to the next it draws; none
##   left that takes it, and the row does not happen.
## - **What it takes is assigned and stood**: the location is taken, and the ground stands the plan.

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
	func assign_to(location: Location, plan: EventScheduler.Planned) -> void:
		location.take(plan)

## The day's ground: which locations take nothing, and what it stood.
class _Ground extends LocationGround:
	var refused := {}
	var stood: Array[EventScheduler.Planned] = []

	## Overrides LocationGround.offer.
	func offer(def: EventDef, location: Location) -> EventScheduler.Planned:
		if refused.has(location):
			return null
		return EventScheduler.Planned.new(def, location.centre())

	## Overrides LocationGround.stand.
	func stand(plan: EventScheduler.Planned) -> void:
		stood.append(plan)

func run(t) -> void:
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

func _test_a_location_weighed_nothing_is_never_drawn(t) -> void:
	var drawn_nothing := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var zero := _location(0)
		var some := _location(1)
		locations.open = [zero, some]
		var weights := {zero: 0.0, some: 1.0}
		var phase := ScriptedPhase.new(locations, _Ground.new(),
				func(_def: EventDef, location: Location) -> float: return weights[location])
		phase.place(_row(), _rng(i))
		if zero.is_taken():
			drawn_nothing += 1
	t.check(drawn_nothing == 0, "a location weighed nothing is never drawn (%d of %d)"
			% [drawn_nothing, SEEDS])

func _test_the_draw_follows_the_weights(t) -> void:
	var heavy_taken := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var heavy := _location(0)
		var light := _location(1)
		locations.open = [heavy, light]
		var weights := {heavy: 3.0, light: 1.0}
		var phase := ScriptedPhase.new(locations, _Ground.new(),
				func(_def: EventDef, location: Location) -> float: return weights[location])
		phase.place(_row(), _rng(i))
		if heavy.is_taken():
			heavy_taken += 1
	var share := float(heavy_taken) / float(SEEDS)
	t.check(share > 0.68 and share < 0.82, "three to one draws the heavy location near three in four (%.2f)"
			% share)

func _test_a_location_that_takes_nothing_is_passed_over(t) -> void:
	var elsewhere := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var refusing := _location(0)
		var taking := _location(1)
		locations.open = [refusing, taking]
		var ground := _Ground.new()
		ground.refused[refusing] = true
		var phase := ScriptedPhase.new(locations, ground,
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
	var phase := ScriptedPhase.new(locations, ground,
			func(_def: EventDef, _location: Location) -> float: return 1.0)
	t.check(phase.place(_row(), _rng(0)) == null and ground.stood.is_empty(),
			"with no location that takes it, the row does not happen")

func _test_what_it_takes_is_assigned_and_stood(t) -> void:
	var locations := _Locations.new()
	var one := _location(0)
	locations.open = [one]
	var ground := _Ground.new()
	var phase := ScriptedPhase.new(locations, ground,
			func(_def: EventDef, _location: Location) -> float: return 1.0)
	var plan := phase.place(_row(), _rng(0))
	t.check(plan != null and one.is_taken(), "the location it drew is taken for the day")
	t.check(ground.stood.size() == 1 and ground.stood[0] == plan, "and the ground stands the plan")

func _test_a_location_weighed_nothing_is_not_drawn_once_the_rest_refuse(t) -> void:
	var landed := 0
	for i in SEEDS:
		var locations := _Locations.new()
		var refusing := _location(0)
		var zero := _location(1)
		locations.open = [refusing, zero]
		var ground := _Ground.new()
		ground.refused[refusing] = true
		var weights := {refusing: 1.0, zero: 0.0}
		var phase := ScriptedPhase.new(locations, ground,
				func(_def: EventDef, location: Location) -> float: return weights[location])
		if phase.place(_row(), _rng(i)) != null or zero.is_taken():
			landed += 1
	t.check(landed == 0, "with every weighed location refusing, the row lands on none weighed nothing"
			+ " (%d of %d)" % [landed, SEEDS])
