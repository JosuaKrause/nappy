extends RefCounted
## EventManager against a real generated City: the day's units, each drawn as she comes near it.
##
## `tests/test_event_manager.gd` is the manager's wiring over a day and holds that two walks draw
## the same units; this suite is the wiring between the manager, her walk and the unit draw
## (`EventsAhead`, `UnitDraw`): a unit draws before the streaming looks at its ground, and every
## placement made from her walk draws the units round its place before the place stands, so
## nothing her walk sites or takes away changes what a unit draws. A real city, because each rule
## is about the order of two parts the manager owns (the draw and the streaming, the draw and a
## siting, the draw and a take-away) over the units a generated day lays out and the routes her
## walk is sited on, which a hand-made unit and a fake siting would not show. It is a suite of its
## own because its walks take a real tick each.
##
## **Each case reads the day drawn whole first** (`_the_day_drawn_whole()`): the same city and day
## started and every unit drawn at once, which names a unit far from her door and what it draws, so
## the case can stand her or a placement there on a second start and say what has to be true.

const Rig := preload("res://tests/event_manager_rig.gd")

## A day with poster crews for her walk to site.
const DAY := 4

var _city: City
## What made the day's siting, which keeps it for the case that reads what the walk gave up
## (handed to the events in `_start()`, before the day starts).
var _siting_maker: KeepingSitingMaker
## Moves her down the route a walking test sets it, on its own physics tick, before the city's.
var _walker: Rig.Walker

func run(t: TestRunner) -> void:
	await PhysicsTicks.settle(t)
	var tests: Array[Callable] = [
		_test_a_unit_near_her_draws_before_the_streaming_looks,
		_test_streaming_round_a_place_draws_its_units_first,
		_test_what_her_walk_sites_stands_on_drawn_ground,
		_test_an_area_cleared_of_its_rows_draws_first,
		_test_a_swap_changes_no_units_draw,
		_test_the_walks_reach_is_told_what_a_unit_draws,
	]
	for test in tests:
		_walker = Rig.Walker.new()
		t.add_child(_walker)
		_city = Rig.build_city(t)
		RunCity.events(_city).stream_radius = Tuning.EVENT_STREAM_RADIUS
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
	_siting_maker = KeepingSitingMaker.on(RunCity.events(_city))
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

## How many crews her walk has to site before the walking test stops.
const SITINGS := 4
## The longest the walking test walks, in seconds of walking.
const WALK_SECONDS := 170.0

## **What her walk sites stands on drawn ground, and changes no unit's draw**
## (`WalkSiting.lay_ahead()`, `EventsAhead.draw_the_ground_round()`). She walks the
## day's longest route out and back, through the manager's own tick, until her walk has sited
## `SITINGS` poster crews, each a row a unit drew as she walked and handed to her walk
## (`EventsAhead._take_what_was_drawn()`, `EventDirector.owe_on_her_way()`). At each siting no
## undrawn unit lies within `Tuning.EVENT_DRAW_AHEAD` of the site; the walk gave up at least one
## pick the ground round which had not drawn, so the rule had work to do; and with the rest of the
## day drawn after the walk, every unit drew what it draws on the day drawn whole, and nothing a
## unit drew stands within `EventScheduler.EVENT_SPACING_ANY` of a sited crew.
func _test_what_her_walk_sites_stands_on_drawn_ground(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	_the_day_drawn_whole()
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
	var on_undrawn_ground := 0
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
			var footprint := EventSpawner.obstructed_footprint(_city.map, plan.def,
					plan.position, plan.facing)
			if not footprint.is_empty():
				bodies_sited += 1
				if not told.has(str(footprint)):
					sited_and_not_told += 1
			if not _units().undrawn_within(plan.placed_at(), Tuning.EVENT_DRAW_AHEAD).is_empty():
				on_undrawn_ground += 1
	_walker.rig = null
	t.check(sitings >= SITINGS,
			"her walk sites the crews the units it drew handed to her walk (%d sitings in %.0fs)"
			% [sitings, walked])
	t.check(bodies_sited > 0 and sited_and_not_told == 0,
			"each siting with a body told the listener where it stands (%d told of %d with a body)"
			% [bodies_sited - sited_and_not_told, bodies_sited])
	events.use_body_listener(Callable())
	t.check(on_undrawn_ground == 0,
			"and at no siting does an undrawn unit lie within %.0fpx of the site (%d of %d did)"
			% [Tuning.EVENT_DRAW_AHEAD, on_undrawn_ground, sitings])
	var siting := _siting_maker.latest()
	var gave_up := int(siting.waits().get("the ground round its site had not drawn", 0)) \
			if siting else 0
	t.check(gave_up > 0,
			"the walk gave up a pick the ground round which had not drawn (%d times)" % gave_up)
	events.draw_the_ground_round(Vector2.ZERO, INF)
	t.check(Rig.what_the_units_drew(_city.map, kept) == _whole and _whole != "",
			"with the rest drawn after the walk, every unit drew what it draws on the day drawn "
			+ "whole")
	var nearest := INF
	for crew: EventPlan in sited_at:
		for unit in kept:
			for plan in unit.drawn():
				if plan != crew and plan.is_placed():
					nearest = minf(nearest, crew.gap_to(plan))
	t.check(nearest >= EventScheduler.EVENT_SPACING_ANY,
			"and nothing a unit drew stands within %.0fpx of a sited crew (the nearest %.0fpx)"
			% [EventScheduler.EVENT_SPACING_ANY, nearest])
	events.use_player(null)
	rig.free()

## **An area cleared of its rows draws its units first** (`EventManager.take_away_within()`,
## `take_away_the_unseen_within()`): asked to clear a far unit's ground of the row that unit draws,
## before the unit has drawn, each take-away draws the unit, takes the row it drew, and leaves
## none of that row standing there once the rest of the day is drawn.
func _test_an_area_cleared_of_its_rows_draws_first(t: TestRunner) -> void:
	var events := RunCity.events(_city)
	var drew := _the_day_drawn_whole()
	var not_ambient := func(one: _Drew, k: int) -> bool:
		return EventCatalogue.by_id(one.ids[k]).kind != GameEnums.EventKind.AMBIENT
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
	var across_footprint := EventSpawner.obstructed_footprint(map, across.def, across.position,
			across.facing)
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
