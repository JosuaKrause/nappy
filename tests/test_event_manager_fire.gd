extends RefCounted
## EventManager against a real generated City: the fire, and a walk down the day's own routes.
##
## `tests/test_event_manager.gd` is the manager's wiring over a day; this suite is what a walking
## player adds, the fire sited on her way, the engine sent to it and the day's fire lit at dusk. They
## are two suites because the walks take a real tick each and together they outran the two minutes
## a suite is allowed.

const Rig := preload("res://tests/event_manager_rig.gd")

var _city: City

## Moves her down the route a walking test sets it, on its own physics tick, before the city's
## (it is added to the tree first), so the manager's tick sees her where this tick put her.
var _walker_node: Walker

func run(t) -> void:
	await PhysicsTicks.settle(t)
	# Every test builds a city and a run of its own, so none leans on what an earlier one left
	# behind: the scars a fire writes, the streaming radius, the day a test started.
	var tests: Array[Callable] = [
		_test_the_fire_under_a_covered_corner_is_not_sighted,
		_test_the_fire_is_sited_on_the_way_she_is_walking,
		_test_the_fire_burns_where_her_walk_put_it,
		_test_the_fire_she_did_not_choose_leaves_her_a_way_out,
		_test_the_engine_waits_on_its_road_to_the_fire,
		_test_a_fire_that_was_never_lit_was_not_spent,
		_test_a_won_day_with_the_fire_unmet_still_burns,
	]
	for test in tests:
		_build_city(t)
		await test.call(t)
		_teardown()

func _build_city(t) -> void:
	_walker_node = Walker.new()
	t.add_child(_walker_node)
	_city = Rig.build_city(t)

## **A day 3 she wins with the fire never in the world still burns.** *"I agree with the fire fix"*
## (PLAYTEST-121). The row's only day is day 3 and it is spent where it enters the world, so a day
## she wins while every siting waited would leave the run with no fire, no scar and no shell — and
## the shell is what the city remembering day 3 is made of. It is lit at the end of the day instead,
## off her path, by the same acceptance rules.
##
## Nothing walks here, which is the case: a day nobody walked far enough into for a siting to be due
## is the cheapest way to produce exactly the state this is for.
func _test_a_won_day_with_the_fire_unmet_still_burns(t) -> void:
	var day := Tuning.RUN_TAUGHT_DAY
	_start(day)
	var plan := _fire_plan()
	t.check(plan != null and not plan.is_placed() and not plan.was_live,
			"the day ends with the fire owed, planned and never in the world")
	if not plan:
		return
	var doorstep := _city.map.doorstep_world_position()
	t.check(_city.events.light_what_she_never_met(doorstep),
			"the end of a won day lights it")
	t.check(plan.is_placed() and plan.was_live,
			"and it has been in the world, which is what records what a fire does to a run")
	t.check(plan.position.distance_to(doorstep)
			>= EventScheduler.WalkSiting.DUSK_CLEAR_OF_HER,
			("it is lit %.0fpx from where she finished, past the %.0fpx streaming band, so it is "
			% [plan.position.distance_to(doorstep),
			EventScheduler.WalkSiting.DUSK_CLEAR_OF_HER]) + "nowhere she could have seen it happen")
	var scar_here := false
	for scar in _city.run.attempt_spend.scars:
		scar_here = scar_here or (String(scar["id"]) == "burnt_shell"
				and Vector2(scar["position"]).distance_to(plan.position) < 1.0)
	t.check(scar_here, "and the shell the run keeps is standing where it burned")
	var still_alight := false
	for instance in _city.events.instances():
		still_alight = still_alight or instance.def.id == "burning_building"
	t.check(not still_alight,
			"and nothing is left burning in a day that is over")

	# A second call on the same day has nothing left to light: the one-shot is spent.
	t.check(not _city.events.light_what_she_never_met(doorstep),
			"a run gets exactly one fire, however many times the day ends")

func _teardown() -> void:
	_city.free()
	_walker_node.free()

func _start(day: int) -> void:
	Rig.start(_city, day)

# ------------------------------------------- the fire is on her way (M179) ---
# *"the fire should come first and be on your way guaranteed (a dynamic event dependent on the
# route you chose that day)"* (PLAYTEST-117). Day 3's fire carries `EventDef.on_her_way`, so
# the day budgets it with no position and `EventDirector.site_what_is_on_her_way()` puts it on a
# building face ahead of her once her heading for the day is clear.
#
# **These have to be here rather than in `tests/test_events.gd`.** Everything about the siting is a
# function of where she actually walked, so it needs a real city, a real manager and something in
# the `player` group that moves — the same reason this suite exists at all.

## Long enough for a whole route out to a calm area and back again at walking pace, which is what
## the outbound and return legs of a 210s day are.
const WALK_SECONDS := 240.0

## Takes her down a route on its own physics tick, at `Tuning.WALK_SPEED`: a point is walked to
## rather than through, and `velocity` is set to match, since the director's clock only runs while
## she is actually going somewhere and its heading is read off `velocity`. A point within a step of
## her is passed over.
class Walker extends Node:
	var rig: Stroller
	var route := PackedVector2Array()
	var next := 0
	var heading := Vector2.RIGHT

	func _physics_process(delta: float) -> void:
		if rig == null:
			return
		var step := Tuning.WALK_SPEED * delta
		while next < route.size() and route[next].distance_to(rig.global_position) <= step:
			next += 1
		if next >= route.size():
			return
		heading = (route[next] - rig.global_position).normalized()
		rig.velocity = heading * Tuning.WALK_SPEED
		rig.global_position += heading * step

## Seconds of walking since the last `_start`, advanced by `_walk` so a test can say *when*
## something happened without threading a clock through the walking itself.
var _walk_clock := 0.0

## Lets the manager's ticks pass while she walks `route` — a chain of world points — until it runs
## out, `WALK_SECONDS` of walking have gone by, or `until` answers true after a tick. Returns the
## direction she was travelling on the last tick, which is what a caller asking "and then she turned
## round" needs.
##
## From where she already is, so a second call carries on down the same route rather than walking
## her back to its first point — which is what a test that stops at the siting and then keeps going
## needs.
func _walk(t, rig: Stroller, route: PackedVector2Array, until := Callable()) -> Vector2:
	_walker_node.rig = rig
	_walker_node.route = route
	_walker_node.next = _nearest_on(route, rig.global_position)
	while _walker_node.next < route.size() and _walk_clock < WALK_SECONDS:
		await PhysicsTicks.pass_ticks_faster(t, 1, PhysicsTicks.FASTER, Callable(), Rig.WALK_SCALE)
		_walk_clock += Rig.WALK_STEP
		if until.is_valid() and until.call():
			break
	_walker_node.rig = null
	return _walker_node.heading

## **The engine's badge holds still for its second, and the engine is then created on its road, on
## its way to the fire, just out of sight.** *(PLAYTEST-145: "the spawn point follows her but must
## keep making sense. the firetruck needs to stay on the road traveling to the fire"; calm-kestrel,
## inbox #559: "show the warning for x seconds (never longer than 2s) without placing anything then
## place the object immediately off screen ... they jump around wildly"; busy-quail, inbox #569:
## "1s warning should be enough".)* She walks out and sees the fire, which puts the engine's warning up
## with no engine in the world; then she keeps walking on along the day's route while it runs. Every
## frame its badge keeps the same offset from her, moving only with her; once its second is up the
## engine is created on the carriageway, on the line of the fire's own street through the kerb it
## stops at, up the road from that kerb rather than past it, level with her or further up rather than
## between her and the fire, and wholly out of sight — and is given the route down to the kerb.
func _test_the_engine_waits_on_its_road_to_the_fire(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(Tuning.RUN_TAUGHT_DAY)
	var plan := _fire_plan()
	var route := _a_route_out(Tuning.RUN_TAUGHT_DAY)
	var rig := Rig.walker(t, _city, route[0])
	_walk_clock = 0.0
	if plan:
		await _walk(t, rig, route,
				func() -> bool: return plan.is_placed() and _city.events.sees(plan.position))
	var warning: PendingWarning = null
	for pending in _city.events.pending_warnings():
		if pending.def.id == "fire_truck":
			warning = pending
	t.check(plan != null and warning != null, "she walks out, finds the fire, and the engine is warned")
	if not warning:
		rig.free()
		_city.events.stream_radius = INF
		return
	t.check(warning.left <= Tuning.WARNING_ALONE_MAX, "its badge is up alone for at most a second")
	var stop := EventSpawner.where_the_summoned_row_stops(_city.map, plan.position)
	var offset := warning.offset
	var looked := [0]
	var jumped := [0]
	var her_at := [rig.global_position]
	var watch := func() -> bool:
		her_at[0] = rig.global_position
		if not _city.events.pending_warnings().has(warning):
			return true
		looked[0] += 1
		if not (warning.place - rig.global_position).is_equal_approx(offset):
			jumped[0] += 1
		return false
	_walk_clock = 0.0
	await _walk(t, rig, route, watch)
	t.check(looked[0] > 0 and jumped[0] == 0,
			"its badge keeps its offset from her for all %d frames it is up (%d not)"
			% [looked[0], jumped[0]])
	t.check(not warning.withdrawn, "and it is not withdrawn")
	var engine: EventInstance = null
	for instance in _city.events.instances():
		if instance.def.id == "fire_truck":
			engine = instance
	t.check(engine != null, "and the engine is created once its second is over")
	if engine:
		var at := engine.path[0]
		var up_the_road := (at - stop).normalized()
		var across := Vector2(-up_the_road.y, up_the_road.x)
		var from_the_kerb := at - stop
		var wrong: Array[String] = []
		if absf(from_the_kerb.dot(across)) > 0.5:
			wrong.append("off the line of its street")
		if from_the_kerb.dot(up_the_road) <= 0.0:
			wrong.append("past the fire's kerb")
		if from_the_kerb.dot(up_the_road) < (her_at[0] - stop).dot(up_the_road) - 0.5:
			wrong.append("between her and the fire")
		if not Tile.is_road(_city.map.tile_type_at_world(at)):
			wrong.append("off the carriageway")
		if not SpawnSiting.is_out_of_sight(VisibleView.around(her_at[0], null),
				EventFootprints.footprint_of(engine.def), her_at[0], at):
			wrong.append("in sight")
		t.check(wrong.is_empty(), "created at %v with her at %v: on its road, on its way to the fire, "
				% [at, her_at[0]] + "just out of sight%s" % ("" if wrong.is_empty() else " — " + ", ".join(wrong)))
		t.close_to(engine.path[engine.path.size() - 1].distance_to(stop), 0.0,
				"and it drives to the kerb across from the fire", 1.0)
	rig.free()
	_city.events.stream_radius = INF

	# The same place on a straight road, walked a long way up it toward where the engine comes from:
	# the stretch between her and the fire goes out of view behind her long before she stops, and
	# the place stays ahead of her rather than dropping in behind her there.
	var truck := EventCatalogue.by_id("fire_truck")
	var kerb := Vector2.ZERO
	var her := Vector2(Tuning.TILE_SIZE * 1.5, 0.0)
	var behind_her := 0
	for i in int(round(8.0 / Rig.WALK_STEP)):
		her += Vector2.UP * Tuning.WALK_SPEED * Rig.WALK_STEP
		var place := PendingWarning.on_its_route(truck, her, kerb, Vector2.DOWN, 4000.0)
		if place == Vector2.INF or place.y > her.y:
			behind_her += 1
	t.check(behind_her == 0,
			"walking a long way up its road, the place stays up the road from her (%d frames not)"
			% behind_her)

## Paints one disc of ground into a `blocked` set, the way the day's own reachability questions do.
func _block(blocked: Dictionary, at: Vector2, radius: float) -> void:
	if radius <= 0.0:
		return
	var reach := ceili(radius / float(Tuning.TILE_SIZE))
	var centre := _city.map.world_to_tile(at)
	for dy in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var tile := centre + Vector2i(dx, dy)
			if _city.map.tile_to_world(tile).distance_to(at) <= radius:
				blocked[tile] = true

## The nearest walkable tile to `from` that is not inside anything `blocked` — where she steps back
## to when she comes round the corner into a field. `Vector2i(-1, -1)` if there is none within the
## fire's own field, which would be a fire she cannot get out of at all.
func _retreat_from(from: Vector2i, blocked: Dictionary) -> Vector2i:
	var reach := ceili(EventCatalogue.by_id("burning_building").outer_radius / Tuning.TILE_SIZE)
	for ring in range(0, reach + 1):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var tile := from + Vector2i(dx, dy)
				if not blocked.has(tile) and _city.map.is_walkable(tile):
					return tile
	return Vector2i(-1, -1)

## The calm tiles of every area she has not settled in this act — what the siting's own acceptance
## check requires to stay reachable, worked out here from the map rather than asked of the check.
func _calm_she_has_not_used() -> Array[Vector2i]:
	var used := _city.run.calendar.settled_this_act()
	var tiles: Array[Vector2i] = []
	for block in _city.map.calm_blocks:
		if used.has(block):
			continue
		for tile in _city.map.rect_tiles(ClosurePlanner.calm_area_rect(_city.map, block)):
			if Tile.is_calm(_city.map.tile_at(tile)):
				tiles.append(tile)
	return tiles if not tiles.is_empty() else _city.map.calm_tiles()

## The index of the route point she is standing nearest to. A route is a chain of cell centres and
## she walks between them, so this is where a resumed walk picks up.
func _nearest_on(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_distance := INF
	for i in route.size():
		var distance := route[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best

## The tree the manager planned this day against, chosen the way `EventManager.start_day` chooses
## it: the city's own if a `City.start_day` has ever grown one, and a fresh `RouteTree.for_day`
## otherwise. **Asking for a fresh one unconditionally is the trap**, because this suite drives the
## manager without the city on most of its days and with it on one — so after that one the city
## holds a tree grown for a different day, and a rig walking a route out of a tree the fire was
## never sited against measures nothing.
func _days_tree(day: int) -> RouteTree:
	var tree := _city.route_tree()
	return tree if tree else RouteTree.for_day(_city.map, day)

## The longest route of the day's own tree as the line she walks: out from the doorstep to the calm
## area it reaches when `outward`, back down the same ground when not.
##
## A route runs from the area to the doorstep, which is why the walk out is the array reversed.
func _a_route_out(day: int, outward := true) -> PackedVector2Array:
	var tree := _days_tree(day)
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	var siting := _a_siting(day)
	var points := PackedVector2Array()
	for i in best.size():
		var cell: Vector2i = best[best.size() - 1 - i] if outward else best[i]
		points.append(siting.cell_centre(cell))
	return points

## A siting of the test's own over the day's tree, to ask what the director's own is asked: where a
## cell of a route stands, and whether a point is still ahead of her along the branch she walks.
func _a_siting(day: int) -> EventScheduler.WalkSiting:
	return EventScheduler.WalkSiting.new(day, _city.map, _days_tree(day),
			_city.events.walk_events(), EventScheduler.Verdicts.new())

## Which cells of the day's routes carry `position`, as the branch colours `RouteTree` records —
## empty for a point off the tree. What "on the path" means, asked of a placement.
func _branches_on(day: int, position: Vector2) -> Array[int]:
	return _days_tree(day).branches_on(_city.map.world_to_tile(position))

## **The fire under a corner the joystick's controls cover is not sighted** (dappled-swan's
## the-sightings): with the burning building standing only under the left corner, the day's own
## visible area in the joystick scheme sends no `seen-fire` and summons no engine; in the tap scheme,
## the same view and the same fire, it does both.
func _test_the_fire_under_a_covered_corner_is_not_sighted(t) -> void:
	_start(Tuning.RUN_TAUGHT_DAY)
	var events := _city.events
	var def := EventCatalogue.by_id("burning_building")
	var at := CrowdLanes.arterial_pavement(_city.map)
	var sighted: Array[String] = []
	var on_sighted := func(id: String) -> void: sighted.append(id)
	EventBus.event_sighted.connect(on_sighted)
	var day_plans := events.plans().duplicate()
	# The view whose left corner holds the fire's point: the corner's middle is (-224, 108) world px
	# off the view's centre at zoom 2.
	var corner := TouchCover.joystick().left.get_center() - ScreenOrientation.DESIGN_SIZE * 0.5
	var view := Rect2(at - corner * 0.5 - Tuning.VIEW_HALF_EXTENT, Tuning.VIEW_HALF_EXTENT * 2.0)
	for joystick: bool in [true, false]:
		var plan := EventScheduler.Planned.new(def, at)
		var instance := EventInstance.new()
		instance.setup(def, at)
		_city.add_child(instance)
		plan.live = instance
		events.streaming.add(plan)
		sighted.clear()
		var warnings_before := events.pending_warnings().size()
		events.world.visible.look(view, TouchCover.joystick() if joystick else null)
		events.spawner.summon_what_has_been_sighted(events.plans())
		var summoned := events.pending_warnings().size() > warnings_before
		t.check(sighted.has("burning_building") != joystick and summoned != joystick,
				"%s scheme: the fire under the left corner is %s" % ["joystick" if joystick else "tap",
				"neither sighted nor sends for the engine" if joystick else "sighted, and sends for the engine"])
		var walk := events.walk_events()
		walk.take(day_plans.duplicate(), walk.calm(), walk.doors())
		events.warnings.clear()
		instance.free()
	EventBus.event_sighted.disconnect(on_sighted)

func _fire_plan() -> EventScheduler.Planned:
	for plan in _city.events.plans():
		if plan.def.id == "burning_building":
			return plan
	return null

## **The fire is on the path she is walking, and nowhere else.** *(PLAYTEST-119: "the fire needs to
## spawn on the current path the player is on — moving it around works but valid spawn locations are
## only on the path".)* The day plans it with no position at all; walking the day's own route out of
## the doorstep has it sited on that route ahead of her, off screen, and brought into view by
## continuing to walk. Walking the same route home again is the same rule, which is the whole of
## PLAYTEST-120: a fire she has dodged is still ahead of her on the way back.
##
## The three properties checked on the siting itself are the ones the design is stated in. It is
## **on the tree** — the day's own `RouteTree` carries the tile it stands on. It is **ahead on the
## branch she is walking**, which is `WalkSiting.still_ahead_of()`'s own question asked from where
## she was standing. And it is **off screen**: outside the streaming band, so nothing about it is
## visible and nothing about it is real yet.
func _test_the_fire_is_sited_on_the_way_she_is_walking(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var day := Tuning.RUN_TAUGHT_DAY
	for leg: String in ["out", "home again"]:
		_start(day)
		var plan := _fire_plan()
		t.check(plan != null and not plan.is_placed(),
				"walking %s: day 3 budgets a fire and leaves it for her walk to site" % leg)
		if not plan:
			continue
		var route := _a_route_out(day)
		var rig := Rig.walker(t, _city, route[0])
		_walk_clock = 0.0
		if leg == "home again":
			# Stood at the calm area with nothing sited, which is the state a walk out that dodged
			# the fire ends in: the director's clock only runs while she is walking, so putting her
			# at the far end of the route is a walk out during which no siting was ever due. What
			# is then measured is entirely the return leg's.
			rig.global_position = route[route.size() - 1]
			route = _a_route_out(day, false)
		# `_walk` stops on the frame the fire is sited, so where she is standing when it returns is
		# where she was standing when it happened, to within one step. A lambda cannot carry that
		# out of the walk instead: GDScript captures a local by value, so a closure assigning to one
		# writes to its own copy and the caller reads the value it started with.
		var heading := await _walk(t, rig, route, func() -> bool: return plan.is_placed())
		t.check(plan.is_placed(), "walking %s: the fire is sited at all" % leg)
		if not plan.is_placed():
			rig.free()
			continue
		var sited_from := rig.global_position
		var sited_at := _walk_clock
		t.check(not _branches_on(day, plan.position).is_empty(),
				"walking %s: and it stands on the day's own route tree, never off it" % leg)
		t.check(plan.position.distance_to(sited_from) > Tuning.EVENT_STREAM_RADIUS,
				("walking %s: %.0fpx out, past the %.0fpx streaming band, so it is neither visible "
				% [leg, plan.position.distance_to(sited_from), Tuning.EVENT_STREAM_RADIUS])
				+ "nor real when it is placed")
		t.check(_a_siting(day).still_ahead_of(sited_from, heading, plan.position),
				"walking %s: and it is ahead of her along the branch she is walking" % leg)
		var seen_at := -1.0
		await _walk(t, rig, route, func() -> bool: return _city.events.sees(plan.position))
		if _city.events.sees(plan.position):
			seen_at = _walk_clock
		t.check(seen_at >= 0.0,
				"walking %s: and continuing along the route brings it into view (%.1fs in)"
				% [leg, seen_at])
		if seen_at >= 0.0:
			print("      fire %s: sited %.1fs in, %.0fpx ahead, first seen %.1fs later"
					% [leg, sited_at, plan.position.distance_to(sited_from), seen_at - sited_at])
			# The engine is what the sight of it summons, and its warning goes up on that same frame.
			var engine := false
			for warning in _city.events.pending_warnings():
				engine = engine or warning.def.id == "fire_truck"
			t.check(engine, "walking %s: and seeing it calls the engine in" % leg)
		rig.free()
	_city.events.stream_radius = INF

## **The scar the run keeps is where it actually burned.** The whole point of siting the fire from
## her walk is that where it stands is not known at dawn, and a scar is the city's memory of a day —
## so this is the one property that would go wrong silently: a burnt-out shell standing for the rest
## of the run somewhere no fire ever was.
##
## The rule that keeps it true is that a plan stops being movable the moment it is *real*, which is
## the first time it streams in — `EventStreaming.stream_in` records the scar there. The rule itself
## is checked in `tests/test_events.gd`, against a director with the geometry written rather than
## walked; what is checked here is the wiring, against a real streaming manager and a real walk.
func _test_the_fire_burns_where_her_walk_put_it(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(Tuning.RUN_TAUGHT_DAY)
	var plan := _fire_plan()
	t.check(plan != null, "day 3 has a fire to walk into")
	if not plan:
		_city.events.stream_radius = INF
		return
	var route := _a_route_out(Tuning.RUN_TAUGHT_DAY)
	var rig := Rig.walker(t, _city, route[0])
	_walk_clock = 0.0
	await _walk(t, rig, route, func() -> bool: return plan.is_placed())
	t.check(plan.is_placed(), "walking the day's route sites it")
	if not plan.is_placed():
		rig.free()
		_city.events.stream_radius = INF
		return

	await _walk(t, rig, route, func() -> bool: return plan.was_live)
	t.check(plan.was_live, "and walking on puts it in the world")
	if plan.was_live:
		var burning_at := plan.position
		var scar_here := false
		for scar in _city.run.attempt_spend.scars:
			scar_here = scar_here or (String(scar["id"]) == "burnt_shell"
					and Vector2(scar["position"]).distance_to(burning_at) < 1.0)
		t.check(scar_here, "and the scar the run keeps is where it actually burned")
		# Back down the route she came up, which is the walk home: it is real now, so nothing about
		# turning round may move it.
		await _walk(t, rig, _a_route_out(Tuning.RUN_TAUGHT_DAY, false))
		t.check(plan.position == burning_at,
				"and turning round after it is real leaves it exactly where it burned")
	rig.free()
	_city.events.stream_radius = INF

## **A siting she did not choose owes her a way out of it.** She walks up to this fire because the
## day put it in front of her rather than because she picked the street, so the fire's own body,
## its field and the engine's must never be what closes the last way off the street she is on.
##
## Asked as reachability rather than as a radius: from the tile she is standing on when she first
## sees the fire, with every solid body the day has placed counted as blocked, she can still reach
## calm ground. `EventScheduler.WalkSiting` refuses a candidate that would break the same property
## measured from the home, and this is the other end of it — the property stated over *her*, at the
## one moment the milestone is about.
func _test_the_fire_she_did_not_choose_leaves_her_a_way_out(t) -> void:
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	_start(Tuning.RUN_TAUGHT_DAY)
	var plan := _fire_plan()
	if not plan:
		t.check(false, "day 3 has a fire to walk up to")
		_city.events.stream_radius = INF
		return
	var route := _a_route_out(Tuning.RUN_TAUGHT_DAY)
	var rig := Rig.walker(t, _city, route[0])
	_walk_clock = 0.0
	await _walk(t, rig, route,
			func() -> bool: return plan.is_placed() and _city.events.sees(plan.position))
	t.check(plan.is_placed() and _city.events.sees(plan.position),
			"she walks out and finds the fire")
	if not plan.is_placed():
		rig.free()
		_city.events.stream_radius = INF
		return

	var fire: EventInstance = plan.live
	t.check(fire != null, "the fire is in the world by the time it is on screen")
	if fire:
		# **What the first sight owes is the walk out of it, not a clear screen.** The fire is on the
		# route she is walking, so it can come into view from any direction — and the view is
		# `Tuning.VIEW_HALF_EXTENT` (320 x 180), narrower on its short axis than the fire's own
		# 260px outer radius, so an approach up or down the screen puts it in sight with the outer
		# edge of the field already on her. That is the telegraph contract's own worst case rather
		# than a hole in it: what it promises is that a player who turns round the instant she sees
		# a thing gets clear before it is at full strength, which is exactly this measurement.
		var range_to_it := rig.global_position.distance_to(fire.global_position)
		t.check(range_to_it > plan.def.inner_radius,
				("she first sees it %.0fpx off, outside the %.0fpx where its field is at full "
				% [range_to_it, plan.def.inner_radius]) + "strength")
		t.check((plan.def.outer_radius - range_to_it) / Tuning.WALK_SPEED
				<= plan.def.telegraph_time,
				("and walking away from it clears the field in %.2fs, inside the %.2fs its "
				% [maxf(plan.def.outer_radius - range_to_it, 0.0) / Tuning.WALK_SPEED,
				plan.def.telegraph_time]) + "telegraph buys her")
	var engines := 0
	var engine_in_the_world := false
	for instance in _city.events.instances():
		engine_in_the_world = engine_in_the_world or instance.def.id == "fire_truck"
	t.check(not engine_in_the_world,
			"and the engine it calls in is not in the world yet: its warning comes first")
	for warning in _city.events.pending_warnings():
		if warning.def.id != "fire_truck":
			continue
		engines += 1
		t.check(SpawnSiting.is_out_of_sight(VisibleView.around(rig.global_position, null),
				EventFootprints.footprint_of(warning.def), rig.global_position, warning.place),
				"and its badge points just out of sight, where it will come from")
		# **It is aimed at where the fire actually is**, which is the half a runtime siting could
		# break: the route is built from the live instance's position when it is first seen, and a
		# plan stops being movable at its first stream-in, so the two can never be a fire that moved
		# after the engine was sent to where it used to be. The end of the route is the near kerb
		# across from the frontage it is burning against — `EventSpawner._summon_the_sighted_row()`.
		var inward := _city.map.pavement_inward(_city.map.world_to_tile(plan.position))
		var kerb: Vector2 = plan.position - Vector2(inward) \
				* (Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
		# She stands where she first saw the fire while the warning runs on the manager's own ticks.
		var before := _city.events.instances().size()
		var her_at := rig.global_position
		while _city.events.pending_warnings().has(warning) \
				and warning.shown < Tuning.WARNING_ALONE_MAX + 5.0:
			await PhysicsTicks.pass_ticks_faster(t, 1, PhysicsTicks.FASTER, Callable(), Rig.WALK_SCALE)
		# To the tick: `put_up()` adds nothing to `shown`, only `tick()` does, so the badge is over on
		# the first tick that takes it to a second, at most one tick past it.
		t.check(warning.shown <= Tuning.WARNING_ALONE_MAX + Rig.WALK_STEP + 0.001,
				"its badge is up alone for %.2fs, at most a second (to the tick)" % warning.shown)
		var arrived: EventInstance = null
		for instance in _city.events.instances():
			if instance.def.id == "fire_truck":
				arrived = instance
		t.check(arrived != null and _city.events.instances().size() == before + 1,
				"and it is created once its warning is over")
		if arrived:
			# **Where it is created and how long after its badge it can reach her, on the real
			# siting.** Its forward reach (548px) is deeper than the view is from her, so standing on
			# its street she is inside its field from its first frame: what she is owed is the
			# warning before it existed, and that is what is held — at least the row's own minimum
			# (`EventDef.minimum_telegraph()`), from the badge to the first frame its field reaches
			# her (or, for a lethal row, its lethal reach does).
			t.check(SpawnSiting.is_out_of_sight(VisibleView.around(her_at, null),
					EventFootprints.footprint_of(arrived.def), her_at, arrived.path[0]),
					"and it is created just out of sight (%.0fpx from her)"
					% arrived.path[0].distance_to(her_at))
			# Counted from its creation: the tick that made it took its first step too.
			var to_reach := arrived.age
			var reaches := func() -> bool:
				return arrived.is_lethal_at(her_at) if arrived.def.hard_fail \
						else arrived.excitement.contribution_at(her_at) > 0.0
			var on_her_at_once: bool = reaches.call()
			while not reaches.call() and to_reach < 10.0:
				arrived.player_at = her_at
				arrived.step(Rig.WALK_STEP)
				to_reach += Rig.WALK_STEP
			print("      the engine is created %.0fpx from her after %.2fs of badge, its field %s"
					% [arrived.path[0].distance_to(her_at), warning.shown,
					"already on her" if on_her_at_once else "reaching her %.2fs later" % to_reach])
			t.check(warning.shown + to_reach + 0.001 >= arrived.def.minimum_telegraph(),
					("and from its badge to the earliest it reaches her is %.2fs, at least the "
					% (warning.shown + to_reach))
					+ "%.2fs it is owed" % arrived.def.minimum_telegraph())
			t.check(arrived.path.size() == 2, "and it is given a route down the fire's own street")
			t.close_to(arrived.path[0].distance_to(warning.place), 0.0,
					"starting where its badge pointed", 1.0)
			if arrived.path.size() == 2:
				t.close_to(arrived.path[1].distance_to(kerb), 0.0,
						"ending at the near kerb across from where the fire is actually burning",
						1.0)
	t.check(engines == 1, "seeing the fire calls in exactly one engine (%d)" % engines)

	# **The whole of what the pair owes, measured where she is standing when she meets it.** Both
	# fields are closed ground here, not only the bodies: the fire is 260px of field on a 30px body
	# and the parked engine is 340px on no body at all, and what she is asked to do is go another
	# way rather than walk through either. Rebuilt from the map rather than read off `WalkSiting`,
	# so a check that agreed with the siting only because it shared its arithmetic would not pass.
	var blocked := _city.map.closed_tiles.duplicate()
	for other in _city.events.plans():
		if not other.is_placed():
			continue
		var radius := maxf(other.def.obstructs_radius,
				other.def.inner_radius if other.def.hard_fail else 0.0)
		_block(blocked, other.position, radius)
	_block(blocked, plan.position, plan.def.outer_radius)
	var engine_def := EventCatalogue.by_id(plan.def.aftermath.on_sight)
	var parked := EventSpawner.where_the_summoned_row_stops(_city.map, plan.position)
	if engine_def and parked != Vector2.INF:
		_block(blocked, parked, engine_def.outer_radius)
	var grid := ReachabilityGrid.build(_city.map)
	# **From where she can retreat to, not from where she is standing.** She sees the fire the
	# moment it enters the view, which is 180px deep against a 260px field — so on an approach up or
	# down the screen she is already inside the field when she first sees it, and a flood started on
	# a blocked tile answers nothing. What the pair owes is that stepping back out of both fields is
	# possible and leaves her somewhere to go, so the retreat is the first thing measured.
	var her := _retreat_from(_city.map.world_to_tile(rig.global_position), blocked)
	t.check(her != Vector2i(-1, -1),
			"she can step back out of both fields from where she first sees the fire")
	if her == Vector2i(-1, -1):
		rig.free()
		_city.events.stream_radius = INF
		return
	var reached := grid.flood([her], blocked)
	t.check(grid.reaches(_city.map.home_rect.position, blocked, reached),
			"and from where she is standing when she first sees it the way home is still open "
			+ "without entering either field")
	var unused := _calm_she_has_not_used()
	var out := false
	for tile in unused:
		out = out or grid.reaches(tile, blocked, reached)
	t.check(out and not unused.is_empty(),
			("and so is a calm area she has not used (%d tiles of them)" % unused.size())
			+ " — the day still works around the pair")
	rig.free()
	_city.events.stream_radius = INF

## **A fire that was never lit was not spent.** *"What the run has spent stays spent ... a fire that
## burnt a block down did happen"* (`RunCalendar.finish_day`) — so a set piece the day owed her walk is
## consumed where it becomes real rather than where it is planned, and a day 3 lost before she ever
## got near it is offered it again. A day on which it burned is not: the city remembers that one, and
## the shell is standing in it.
func _test_a_fire_that_was_never_lit_was_not_spent(t) -> void:
	var consumed: Array[String] = []
	_city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
	var day := Tuning.RUN_TAUGHT_DAY
	_city.events.start_day(DaySpec.for_day(day), Rig.rng(day), consumed)
	t.check(not "burning_building" in consumed and _fire_plan() != null,
			"day 3 budgets the fire without spending it, because a plan with no position promises "
			+ "nothing yet")

	# Lost without her ever walking out to it. The same day, again, still owes her one.
	_city.events.start_day(DaySpec.for_day(day), Rig.rng(day), consumed)
	t.check(_fire_plan() != null, "a day 3 lost before she reached it is offered it again")

	# Now she walks into it. That is the fire the run remembers, and there is not a second one.
	var plan := _fire_plan()
	var route := _a_route_out(day)
	var rig := Rig.walker(t, _city, route[0])
	_walk_clock = 0.0
	await _walk(t, rig, route, func() -> bool: return plan.was_live)
	t.check(plan.was_live and "burning_building" in consumed,
			"walking into it is what spends it")
	_city.events.start_day(DaySpec.for_day(day), Rig.rng(day), consumed)
	t.check(_fire_plan() == null, "and no later day plans a second one")
	rig.free()
	_city.events.stream_radius = INF
