extends RefCounted
## EventManager against a real generated City: the day's units, each drawn as she comes near it.
##
## `tests/test_event_manager.gd` is the manager's wiring over a day and holds that two walks draw
## the same units; this suite is the wiring between the manager, her walk and the unit draw
## (`EventsAhead`, `UnitDraw`): a unit draws before the streaming looks at its ground; a beat her walk
## lays stands in a unit before it draws, and changes no draw but that unit's and the units touching
## it; and what the resistance swaps in or takes away draws the units round it first, so it changes
## no unit's draw. A real city, because each rule is about the order of two parts the manager owns
## (the draw and the streaming, the draw and a siting, the draw and a take-away) over the units a
## generated day lays out and the routes her walk is sited on, which a hand-made unit and a fake
## siting would not show. It is a suite of its
## own because its walks take a real tick each.
##
## **Each case reads the day drawn whole first** (`_the_day_drawn_whole()`): the same city and day
## started and every unit drawn at once, which names a unit far from her door and what it draws, so
## the case can stand her or a placement there on a second start and say what has to be true.

const Rig := preload("res://tests/event_manager_rig.gd")

## A day with poster crews for her walk to site.
const DAY := 4

var _city: City
## Moves her down the route a walking test sets it, on its own physics tick, before the city's.
var _walker: Rig.Walker

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	var tests: Array[Callable] = [
		_test_a_unit_near_her_draws_before_the_streaming_looks,
		_test_streaming_round_a_place_draws_its_units_first,
		_test_a_beat_her_walk_lays_stands_in_a_unit_before_it_draws,
		_test_an_area_cleared_of_its_rows_draws_first,
		_test_a_swap_changes_no_units_draw,
		_test_the_walks_reach_is_told_what_a_unit_draws,
	]
	for test in tests:
		_walker = Rig.Walker.new()
		t.add_child(_walker)
		_city = Rig.build_city(t)
		RunCity.events(_city).stream_within(Tuning.EVENT_STREAM_RADIUS)
		await test.call(t)
		_city.free()
		_walker.free()

## What one unit drew on the day drawn whole: plain values, read across starts by the unit's name.
class _Drew extends RefCounted:
	var name := ""
	var bounds := Rect2()
	## Per row it drew: its id, where it stands (`Vector2.INF` for one handed to her walk) and
	## whether it obstructs.
	var ids: Array[String] = []
	var places: Array[Vector2] = []
	var obstructs: Array[bool] = []

## Starts the day at her door, at a played day's stream radius. Answers the units the start left
## undrawn: all but the ones round her door.
func _start() -> Array[PlacementUnit]:
	Rig.start(_city, DAY, [], _home())
	return _units().undrawn_within(Vector2.ZERO, INF)

func _home() -> Vector2:
	return _city.map.doorstep_world_position()

func _units() -> DayUnits:
	return RunCity.events(_city).walk_events().unit_draw().units()

## **The day drawn whole**: started at her door and every unit drawn at once. Answers what each
## unit the start left undrawn drew, and leaves `_whole` reading the same as one string.
func _the_day_drawn_whole() -> Array[_Drew]:
	var kept := _start()
	RunCity.events(_city).draw_the_ground_round(Vector2.ZERO, INF)
	_whole = Rig.what_the_units_drew(_city.map, kept)
	var drew: Array[_Drew] = []
	for unit in kept:
		var one := _Drew.new()
		one.name = unit.name()
		one.bounds = unit.bounds()
		for plan in unit.drawn():
			one.ids.append(plan.row_id())
			one.places.append(plan.placed_at())
			one.obstructs.append(plan.obstructs())
		drew.append(one)
	return drew

## What the units the start left undrawn drew on the day drawn whole, as
## `Rig.what_the_units_drew()` reads them.
var _whole := ""

## The unit named `name` among `units`, or null.
static func _named(units: Array[PlacementUnit], name: String) -> PlacementUnit:
	for unit in units:
		if unit.name() == name:
			return unit
	return null

## A row a unit far from her door drew with a place, as `[the unit, the row's index in it]`:
## further from `from` than the stream radius and twice `Tuning.EVENT_DRAW_AHEAD`, so nothing a
## start at her door draws reaches it, and passing `wanted` (the unit, the index). Empty where
## none does.
func _a_far_row(drew: Array[_Drew], wanted: Callable, from: Vector2) -> Array:
	var clear := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_DRAW_AHEAD * 2.0
	for one in drew:
		for k in one.ids.size():
			if one.places[k] == Vector2.INF or one.places[k].distance_to(from) < clear \
					or not wanted.call(one, k):
				continue
			return [one, k]
	return []

## Whether every row `units` drew that stands within the stream radius of `at`, and is not spent,
## is in the world; `counted[0]` gains how many such rows there are.
func _their_rows_are_in_the_world(units: Array[PlacementUnit], at: Vector2,
		counted: Array[int]) -> bool:
	var all_in := true
	for unit in units:
		for plan in unit.drawn():
			if not plan.is_placed() or plan.is_spent() \
					or plan.distance_from(at) > Tuning.EVENT_STREAM_RADIUS:
				continue
			counted[0] += 1
			all_in = all_in and plan.is_in_the_world()
	return all_in

## **A unit near her draws before the streaming looks at its ground, on the same tick**
## (`EventManager._tick_the_events()`: `EventsAhead.draw_what_comes_near()`, then the streaming).
## She is put down far from her door, beside units that have not drawn; one tick later every unit
## any part of which lies within the stream radius of her has drawn, and every row those units
## drew within the radius is in the world, none of it left for a later tick.
func _test_a_unit_near_her_draws_before_the_streaming_looks(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var far_row := _a_far_row(_the_day_drawn_whole(), func(_one: _Drew, _k: int) -> bool:
		return true, _home())
	t.check(not far_row.is_empty(), "the day drawn whole holds a row far from her door")
	if far_row.is_empty():
		return
	var far: Vector2 = (far_row[0] as _Drew).places[far_row[1]]
	_start()
	var near := _units().undrawn_within(far, Tuning.EVENT_STREAM_RADIUS)
	var rig := Rig.walker(t, _city, far)
	await PhysicsTicks.pass_ticks(t, 1)
	var counted: Array[int] = [0]
	var in_the_world := _their_rows_are_in_the_world(near, far, counted)
	t.check(not near.is_empty()
			and _units().undrawn_within(far, Tuning.EVENT_STREAM_RADIUS).is_empty(),
			"put down beside %d undrawn units, one tick draws every unit within the stream radius"
			% near.size())
	t.check(in_the_world and counted[0] > 0,
			"and every row they drew within the radius is in the world on that tick (%d rows)"
			% counted[0])
	events.use_player(null)
	rig.free()

## **Streaming round a place draws its units first** (`EventManager.stream_around()`): asked to
## stream round a place far from where the walk started, as the day's start is for a start the
## developer's `--spawn` moved (`DayDirector`), every unit within the stream radius of the place
## draws and its rows are in the world when the call returns.
func _test_streaming_round_a_place_draws_its_units_first(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var far_row := _a_far_row(_the_day_drawn_whole(), func(_one: _Drew, _k: int) -> bool:
		return true, _home())
	t.check(not far_row.is_empty(), "the day drawn whole holds a row far from her door")
	if far_row.is_empty():
		return
	var far: Vector2 = (far_row[0] as _Drew).places[far_row[1]]
	_start()
	var near := _units().undrawn_within(far, Tuning.EVENT_STREAM_RADIUS)
	events.stream_around(far)
	var counted: Array[int] = [0]
	var in_the_world := _their_rows_are_in_the_world(near, far, counted)
	t.check(not near.is_empty()
			and _units().undrawn_within(far, Tuning.EVENT_STREAM_RADIUS).is_empty(),
			"streaming round a place beside %d undrawn units draws every unit within the radius"
			% near.size())
	t.check(in_the_world and counted[0] > 0,
			"and every row they drew within the radius is in the world (%d rows)" % counted[0])

## How many crews her walk has to lay before the walking test stops.
const SITINGS := 4
## The longest the walking test walks, in seconds of walking.
const WALK_SECONDS := 170.0

## **A beat her walk lays stands in a unit before it draws, and changes no draw but its unit's
## and the touching units'** (`WalkSiting.lay_ahead()`, `Location.take_for_her_walk()`,
## `UnitDraw`). She walks the day's longest route out and back at a played day's stream radius,
## through the manager's own tick, until her walk has laid `SITINGS` poster crews, each a row a
## unit drew as she walked and handed to her walk (`EventsAhead._take_what_was_drawn()`,
## `EventDirector.owe_on_her_way()`). Each crew stands on a location of a unit; at least one in
## a unit that had not drawn when it was laid, every other on a location a drawn unit left
## empty. With the rest of the day drawn after the walk, nothing a unit drew stands within
## `EventScheduler.EVENT_SPACING_ANY` of a crew, no unit holding a crew drew a row on the crew's
## location, and every unit that drew otherwise than on the day drawn whole holds a crew,
## touches a unit that does, or is reached from such a unit along touching units that drew
## otherwise (a unit is judged among the draws of the touching units drawn before it, so a
## difference can carry, and two touching units that both differ do not excuse each other): no
## unit differs out of nowhere, and some unit far from every crew is compared.
func _test_a_beat_her_walk_lays_stands_in_a_unit_before_it_draws(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var map := _city.map
	_the_day_drawn_whole()
	var whole_by_unit := {}
	for line in _whole.split("\n"):
		whole_by_unit[line.get_slice(": ", 0)] = line
	var kept := _start()
	var told: Array[String] = []
	events.use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append(str(tiles)))
	var route := Rig.longest_route_out(_city, DAY)
	var back := route.duplicate()
	back.reverse()
	route.append_array(back)
	var rig := Rig.walker(t, _city, route[0])
	_walker.rig = rig
	_walker.route = route
	_walker.next = 0
	var sited_at := {}
	var sitings := 0
	var before_its_unit_drew := 0
	var on_drawn_ground := 0
	var in_no_unit := 0
	var bodies_sited := 0
	var sited_and_not_told := 0
	var walked := 0.0
	while _walker.next < route.size() and walked < WALK_SECONDS and sitings < SITINGS:
		await PhysicsTicks.pass_ticks_faster(t, 1, PhysicsTicks.FASTER, Callable(), Rig.WALK_SCALE)
		walked += Rig.WALK_STEP
		for plan in events.plans():
			if not plan.row().is_handed_to_her_walk() or not plan.is_placed() \
					or sited_at.get(plan, Vector2.INF) == plan.placed_at():
				continue
			sited_at[plan] = plan.placed_at()
			sitings += 1
			var footprint := EventSpawner.footprint_of(BodyStance.of(map, plan.row(),
					plan.placed_at(), plan.faces()))
			if not footprint.is_empty():
				bodies_sited += 1
				if not told.has(str(footprint)):
					sited_and_not_told += 1
			# The manager's tick draws before it sites, so a unit still undrawn now was undrawn
			# when the crew was laid.
			var unit := _holding(plan)
			if unit == null:
				in_no_unit += 1
			elif unit.is_drawn():
				on_drawn_ground += 1
			else:
				before_its_unit_drew += 1
	_walker.rig = null
	t.check(sitings >= SITINGS,
			"her walk lays the crews the units it drew handed to her walk (%d in %.0fs)"
			% [sitings, walked])
	t.check(bodies_sited > 0 and sited_and_not_told == 0,
			"each crew with a body told the listener where it stands (%d told of %d with a body)"
			% [bodies_sited - sited_and_not_told, bodies_sited])
	events.use_body_listener(Callable())
	t.check(in_no_unit == 0 and before_its_unit_drew > 0,
			"every crew stands in a unit, and at least one in a unit that had not drawn when it "
			+ "was laid (%d before its unit drew, %d on drawn ground, %d in no unit)"
			% [before_its_unit_drew, on_drawn_ground, in_no_unit])
	events.draw_the_ground_round(Vector2.ZERO, INF)
	var nearest := INF
	var on_its_location := 0
	var beside: Dictionary = {}
	for crew: EventPlan in sited_at:
		var unit := _holding(crew)
		if unit == null:
			continue
		beside[unit.name()] = true
		for other in _units().touching(unit):
			beside[other.name()] = true
		var tile := map.world_to_tile(crew.placed_at())
		for location in unit.locations():
			if not location.tiles().has_point(tile):
				continue
			for plan in unit.drawn():
				if plan.is_placed() and location.tiles().has_point(map.world_to_tile(plan.placed_at())):
					on_its_location += 1
	for unit in kept:
		for plan in unit.drawn():
			for crew: EventPlan in sited_at:
				if plan != crew and plan.is_placed():
					nearest = minf(nearest, crew.gap_to(plan))
	t.check(nearest >= EventScheduler.EVENT_SPACING_ANY,
			"with the rest drawn after the walk, nothing a unit drew stands within %.0fpx of a crew "
			% EventScheduler.EVENT_SPACING_ANY + "(the nearest %.0fpx)" % nearest)
	t.check(on_its_location == 0,
			"no unit holding a crew drew a row on the crew's location (%d did)" % on_its_location)
	var differ := {}
	for unit in kept:
		var line := Rig.what_the_units_drew(map, [unit] as Array[PlacementUnit])
		if line != str(whole_by_unit.get(unit.name(), "")):
			differ[unit.name()] = unit
	# A difference carries from a unit beside a crew along touching units that differ, so it is
	# followed from there: a differing unit that walk never reaches differs out of nowhere, and two
	# touching units that both differ cannot excuse each other.
	var reached := {}
	var queue: Array[PlacementUnit] = []
	for name: String in differ:
		if beside.has(name):
			reached[name] = true
			queue.append(differ[name] as PlacementUnit)
	var head := 0
	while head < queue.size():
		var at := queue[head]
		head += 1
		for other in _units().touching(at):
			if differ.has(other.name()) and not reached.has(other.name()):
				reached[other.name()] = true
				queue.append(other)
	var out_of_nowhere: Array[String] = []
	for name: String in differ:
		if not reached.has(name):
			out_of_nowhere.append(name)
	t.check(kept.size() > beside.size() + differ.size() and out_of_nowhere.is_empty(),
			"every unit that drew otherwise than on the day drawn whole holds a crew, touches one, "
			+ "or is reached from one along touching units that drew otherwise (%d units, %d beside a "
			% [kept.size(), beside.size()] + "crew, %d differ; out of nowhere: %s)"
			% [differ.size(), out_of_nowhere])
	events.use_player(null)
	rig.free()

## The unit `plan`, a beat her walk laid, stands in, or null.
func _holding(plan: EventPlan) -> PlacementUnit:
	for unit in _units().all():
		if unit.beats().has(plan):
			return unit
	return null

## **An area cleared of its rows draws its units first** (`EventManager.take_away_within()`,
## `take_away_the_unseen_within()`): asked to clear a far unit's ground of the row that unit draws,
## before the unit has drawn, each take-away draws the unit, takes the row it drew, and leaves
## none of that row standing there once the rest of the day is drawn.
func _test_an_area_cleared_of_its_rows_draws_first(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var drew := _the_day_drawn_whole()
	var not_ambient := func(one: _Drew, k: int) -> bool:
		return not EventCatalogue.by_id(one.ids[k]).is_ambient()
	var far_row := _a_far_row(drew, not_ambient, _home())
	t.check(not far_row.is_empty(), "the day drawn whole holds a row far from her door")
	if far_row.is_empty():
		return
	var one: _Drew = far_row[0]
	var id := one.ids[far_row[1]]
	for unseen: bool in [false, true]:
		var kept := _start()
		var unit := _named(kept, one.name)
		var was_undrawn := unit != null and not unit.is_drawn()
		var taken := events.take_away_the_unseen_within(one.bounds) if unseen \
				else events.take_away_within(one.bounds, [id] as Array[String])
		events.draw_the_ground_round(Vector2.ZERO, INF)
		var standing := 0
		for plan in events.plans():
			if plan.row_id() == id and plan.is_placed() and not plan.is_spent() \
					and one.bounds.has_point(plan.placed_at()):
				standing += 1
		var how := "of what is not in the world" if unseen else "of its %s" % id
		t.check(was_undrawn and taken > 0 and unit.is_drawn(),
				"cleared %s before it drew, the unit draws first and the row is taken (%d taken)"
				% [how, taken])
		t.check(standing == 0,
				"and no %s stands there once the rest of the day is drawn (%d)" % [id, standing])

## **A swap changes no unit's draw** (`EventsAhead.swap_in_a_section()`): a roadblock put across a
## section whose unit has not drawn takes the section for the day, which a draw made afterwards
## would read (`Location.is_taken()`); so the section's unit and the units touching it draw first,
## and with the rest of the day drawn every unit drew what it draws on the day drawn whole, the
## rows the section held spent.
func _test_a_swap_changes_no_units_draw(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var map := _city.map
	var drew := _the_day_drawn_whole()
	var def := EventCatalogue.by_id("roadblock").for_day(DAY)
	var far := Tuning.EVENT_STREAM_RADIUS + Tuning.EVENT_DRAW_AHEAD * 2.0
	# The name of a unit a row of which stands in `section`, far from her door: what a swap there
	# replaces. "" where the section holds none.
	var held_in := func(section: Location) -> String:
		var rect := map.tile_rect_to_world(section.tiles())
		for one in drew:
			for k in one.ids.size():
				if one.places[k] != Vector2.INF and rect.has_point(one.places[k]) \
						and one.places[k].distance_to(_home()) > far:
					return one.name
		return ""
	var kept := _start()
	var chosen: Location = null
	var across: EventPlan = null
	var its_unit: PlacementUnit = null
	for section in events.walk_events().locations().sections_in(
			PlacementView.View.ROUTE_ADJACENT):
		var name: String = held_in.call(section)
		if name == "":
			continue
		across = EventScheduler.across_the_section(def, events.plan_builder(), map, section,
				RandomNumberGenerator.new())
		if across != null:
			chosen = section
			its_unit = _named(kept, name)
			break
	t.check(chosen != null and its_unit != null and not its_unit.is_drawn(),
			"a route-adjacent section far from her door holds a row of a unit not yet drawn")
	if chosen == null or its_unit == null:
		return
	var told: Array[String] = []
	events.use_body_listener(func(tiles: Array[Vector2i]) -> void:
		told.append(str(tiles)))
	var swapped := events.swap_in_a_section(chosen, across)
	var across_footprint := EventSpawner.footprint_of(
			BodyStance.of(map, across.row(), across.placed_at(),
			across.faces()))
	t.check(not across_footprint.is_empty() and str(across_footprint) in told,
			"the swap tells the crowd's listener the roadblock's footprint, as a drawn body is told")
	t.check(swapped != null and its_unit.is_drawn(),
			"the swap draws the section's unit before its roadblock stands")
	events.draw_the_ground_round(Vector2.ZERO, INF)
	t.check(Rig.what_the_units_drew(map, kept) == _whole and _whole != "",
			"and with the rest of the day drawn, every unit drew what it draws on the day drawn "
			+ "whole")
	var left := 0
	for plan in events.walk_events().placed_within(map.tile_rect_to_world(chosen.tiles())):
		if plan != across:
			left += 1
	t.check(left == 0, "with what the section held spent (%d left standing)" % left)

## **The walk's reach is told what a unit draws** (`EventsAhead._take_what_was_drawn()`,
## `DayReach.shut_more()`): the ground a far unit's body stands on is open in the walk's reach
## until the unit draws, and shut once it has, so whoever asks whether she can be sent somewhere
## is answered over the bodies drawn so far.
func _test_the_walks_reach_is_told_what_a_unit_draws(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var map := _city.map
	var a_body := func(one: _Drew, k: int) -> bool:
		return one.obstructs[k]
	var far_row := _a_far_row(_the_day_drawn_whole(), a_body, _home())
	t.check(not far_row.is_empty(), "the day drawn whole holds a body far from her door")
	if far_row.is_empty():
		return
	var one: _Drew = far_row[0]
	var under := map.world_to_tile(one.places[far_row[1]])
	var kept := _start()
	var unit := _named(kept, one.name)
	var reach := events.walk_events().reach()
	var open_before := unit != null and not unit.is_drawn() and not reach.is_shut(under)
	events.draw_the_ground_round(one.bounds.get_center(), 1.0)
	t.check(open_before and unit.is_drawn() and reach.is_shut(under),
			"the ground under a far unit's %s is open in the walk's reach until the unit draws, "
			% one.ids[far_row[1]] + "and shut once it has")
