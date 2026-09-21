extends RefCounted
## Measurement probe for M179, "the fire is on her way, guaranteed" — how long a walk takes to be
## handed the fire, how long after that she sees it, and what the fire and the engine parked at it
## cost her when she meets them. Not a suite: it prints rather than asserting, so it lives here
## under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m179_fire_on_her_way.gd
##
## Day 3's fire is budgeted with no position and sited by `EventDirector.site_what_is_on_her_way()`
## once she has been walking `ON_HER_WAY_AFTER` seconds and is clear of the doorstep, **on the
## branch of the day's route tree she is walking**, between the far edge of the streaming band and
## `ON_HER_WAY_SIGHT` seconds of walking past the edge of the view, measured along the route rather
## than along a straight line.
##
## **So the rigs walk the day's own routes.** A straight line through the lattice was the honest rig
## for a straight-line rule and is the wrong one for this: it spends most of its time off the tree,
## where there is no branch to be ahead on and the right answer is to wait. Two walks per seed:
##
## - **out and back** — the doorstep to a calm area down one of the day's routes, then home again.
##   The return leg is the whole of what PLAYTEST-120 asks for, so it is walked rather than assumed.
## - **turns back** — a few cells out along one branch, back to the doorstep and out along another,
##   all before the siting clock has run: the fire has to land on the branch she ended up on.
##
## `tests/test_event_manager.gd` holds the same two walks as regressions on one seed. What this adds
## is the spread over several cities, the refusals a long wait is made of, the frame cost of an
## attempt, and the two numbers the design is argued in: what walking past the pair costs and what
## going round costs.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 5150, 31337]
const STEP := 1.0 / 30.0
## Long enough for the whole of an out-and-back on the longest route a city offers, at walking pace.
const WALK_SECONDS := 240.0
## How far down the wrong branch the second rig goes before it changes its mind, in route cells.
const PAST_THE_FORK := 6

func run(t) -> void:
	print("seed   walk        sited at   lead px   seen after   total    widened  waited on")
	var met := 0
	var walks := 0
	var unmet_on_a_won_day := 0
	var lit_at_dusk := 0
	var refusals := {}
	var worst_frame := 0.0
	var attempt_frames: Array[float] = []
	for seed_value: int in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
		for walk_name: String in ["out and back", "turns back", "off the path", "stays near home"]:
			var result := _walk_one(t, city, seed_value, walk_name)
			walks += 1
			if result.get("met", false):
				met += 1
			if result.get("never_real", false):
				unmet_on_a_won_day += 1
				if result.get("lit_at_dusk", false):
					lit_at_dusk += 1
			for reason: String in result.get("refusals", {}) as Dictionary:
				refusals[reason] = int(refusals.get(reason, 0)) \
						+ int((result["refusals"] as Dictionary)[reason])
			worst_frame = maxf(worst_frame, float(result.get("worst_frame", 0.0)))
			for ms: float in result.get("attempt_frames", [] as Array[float]):
				attempt_frames.append(ms)
		city.free()

	print("")
	print("saw the fire: %d of %d walks" % [met, walks])
	print("ended with it never in the world: %d — of those, lit at dusk on %d"
			% [unmet_on_a_won_day, lit_at_dusk])
	print("what the waiting was: %s" % _refusal_summary(refusals))
	print("a siting attempt: %.1f ms mean over %d attempts, worst frame of any walk %.1f ms"
			% [_mean(attempt_frames), attempt_frames.size(), worst_frame])
	t.check(true, "m179_fire_on_her_way probe ran")

# ------------------------------------------------------------------ the walks ---

func _walk_one(t, city: City, seed_value: int, walk_name: String) -> Dictionary:
	var day := Tuning.RUN_TAUGHT_DAY
	var scars := GameState.scars.duplicate()
	var consumed: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [seed_value, day])
	city.events.start_day(day, rng, consumed)
	var plan: EventScheduler.Planned = null
	for candidate in city.events.plans():
		if candidate.def.id == "burning_building":
			plan = candidate
	if not plan:
		print("%-6d %-12s no fire planned" % [seed_value, walk_name])
		return {}

	var route := _the_walk(city, day, walk_name)
	if route.size() < 2:
		print("%-6d %-12s no route to walk" % [seed_value, walk_name])
		return {}

	var rig := _walker(t, route[0])
	var state := {
		"clock": 0.0, "sited_at": -1.0, "lead": 0.0, "seen_at": -1.0,
		"refusals": {}, "worst_frame": 0.0, "attempt_frames": [] as Array[float],
	}
	_follow(city, rig, route, plan, state)

	var siting := city.events.walk_siting()
	var widened := siting.widened if siting else 0
	state["refusals"] = siting.waits.duplicate() if siting else {}
	var met: bool = float(state["seen_at"]) >= 0.0
	if met:
		print("%-6d %-12s %7.1fs %9.0f %10.1fs %7.1fs %8d  %s"
				% [seed_value, walk_name, state["sited_at"], state["lead"],
				float(state["seen_at"]) - float(state["sited_at"]), state["seen_at"], widened,
				_refusal_summary(state["refusals"])])
		_what_the_pair_costs(city, rig, plan)
	else:
		print("%-6d %-12s never seen (sited at %.1fs) %25d  %s"
				% [seed_value, walk_name, state["sited_at"], widened,
				_refusal_summary(state["refusals"])])

	# E's case: the day is won with the fire never in the world, so it is lit at dusk off her path.
	# Asked before the lighting, which is itself what puts it in the world.
	var never_real := not plan.was_live
	var lit := false
	if never_real:
		lit = city.events.light_what_she_never_met(rig.global_position)
		if lit:
			print("      lit at dusk at %s, %.0fpx from where she finished"
					% [TelemetryLog.tile(city.map.world_to_tile(plan.position)),
					plan.position.distance_to(rig.global_position)])
	rig.free()
	GameState.scars = scars
	var out := state.duplicate()
	out["met"] = met
	out["never_real"] = never_real
	out["lit_at_dusk"] = lit
	return out

## Walks `route` end to end, stepping the manager every frame and recording when the fire was sited
## and when it first came on screen. Stops early once it has been seen: everything after that is
## measured by `_what_the_pair_costs()` from where she is standing.
func _follow(city: City, rig: Stroller, route: PackedVector2Array, plan: EventScheduler.Planned,
		state: Dictionary) -> void:
	for i in range(1, route.size()):
		var toward := route[i] - rig.global_position
		while toward.length() > Tuning.WALK_SPEED * STEP and float(state["clock"]) < WALK_SECONDS:
			var heading := toward.normalized()
			var was_placed := plan.is_placed()
			var here := rig.global_position
			rig.velocity = heading * Tuning.WALK_SPEED
			rig.global_position += heading * Tuning.WALK_SPEED * STEP
			var before := Time.get_ticks_usec()
			city.events._physics_process(STEP)
			var spent := (Time.get_ticks_usec() - before) / 1000.0
			state["worst_frame"] = maxf(float(state["worst_frame"]), spent)
			# A frame that cost more than a tenth of a physics frame while the fire was still owed
			# is a frame a siting attempt ran in; nothing else here is anywhere near that.
			if not plan.is_placed() and spent > 1.0:
				(state["attempt_frames"] as Array[float]).append(spent)
			state["clock"] = float(state["clock"]) + STEP
			if not was_placed and plan.is_placed():
				state["sited_at"] = state["clock"]
				state["lead"] = plan.position.distance_to(here)
			if plan.is_placed() and city.events._is_on_screen(plan.position):
				state["seen_at"] = state["clock"]
				return
			toward = route[i] - rig.global_position
		if float(state["clock"]) >= WALK_SECONDS:
			return

# ------------------------------------------------------ what the pair costs ---

## The two numbers the wall is argued in, measured once the pair is actually standing: the walk is
## stopped where she first sees the fire, so the engine is still coming down the street and the fire
## is still inside its own telegraph. `SETTLE_SECONDS` of standing still is what it takes for the
## engine to arrive, park and come up to full strength — and standing still sites nothing, since the
## director's clock only runs while she walks.
##
## **Passing** is a walk straight past the pair down the fire's own sidewalk, from outside both
## fields to outside both fields at `Tuning.WALK_SPEED`, summed as excitement x seconds — the meter
## she pays for refusing to go round. **The detour** is the way round: the shortest walk on the
## reachability grid between those same two points with both fields taken as closed ground, against
## the straight line it replaces. Counted in grid steps and multiplied out, so it is the length of a
## cell-grained walk rather than a measured route — what is asked is how much further round is, not
## exactly where.
const SETTLE_SECONDS := 14.0

func _what_the_pair_costs(city: City, rig: Stroller, plan: EventScheduler.Planned) -> void:
	rig.velocity = Vector2.ZERO
	for i in int(round(SETTLE_SECONDS / STEP)):
		city.events._physics_process(STEP)
		# **The instances have to be ticked by hand.** `EventInstance` moves in `_process`, a drawn
		# frame, and the test runner runs synchronously without drawing any — so an engine left to
		# the tree never leaves the top of its street and a fire never finishes its telegraph.
		for instance in city.events.instances().duplicate():
			if is_instance_valid(instance):
				instance._process(STEP)
	var engine_at := EventManager.where_the_summoned_row_stops(city.map, plan.position)
	var engine := EventCatalogue.by_id(plan.def.spawns_on_sight)
	var along := Vector2.RIGHT
	var inward := city.map.pavement_inward(city.map.world_to_tile(plan.position))
	if inward != Vector2i.ZERO:
		along = Vector2(inward.y, inward.x)
	var from := _clear_of_the_pair(plan, engine, engine_at, -along)
	var to := _clear_of_the_pair(plan, engine, engine_at, along)
	var cost := 0.0
	var steps := int(from.distance_to(to) / (Tuning.WALK_SPEED * STEP))
	for i in steps:
		var at: Vector2 = from.lerp(to, float(i) / float(maxi(steps - 1, 1)))
		cost += city.events.total_excitement_at(at) * STEP
	var parked := 0
	for instance in city.events.instances():
		parked += 1 if instance.def.id == "fire_truck" and instance.is_parked else 0
	var straight := from.distance_to(to)
	var round_about := _the_way_round(city, from, to, plan, engine, engine_at)
	print("      %d engine parked; passing costs %.0f excitement-seconds over %.0fpx; round is %s"
			% [parked, cost, straight,
			"nowhere to be found" if round_about < 0.0
			else "%.0fpx, %+.0fpx on the straight line" % [round_about, round_about - straight]])

## The first point out along `direction` from the fire that is outside both fields — where a walk
## past the pair starts and ends.
func _clear_of_the_pair(plan: EventScheduler.Planned, engine: EventDef, engine_at: Vector2,
		direction: Vector2) -> Vector2:
	var reach: float = plan.def.outer_radius
	if engine and engine_at != Vector2.INF:
		reach = maxf(reach, engine_at.distance_to(plan.position) + engine.outer_radius)
	return plan.position + direction * (reach + Tuning.TILE_SIZE)

func _the_way_round(city: City, from: Vector2, to: Vector2, plan: EventScheduler.Planned,
		engine: EventDef, engine_at: Vector2) -> float:
	var grid := ReachabilityGrid.build(city.map)
	var start := grid.node_at(city.map.world_to_tile(from))
	var goal := grid.node_at(city.map.world_to_tile(to))
	if start < 0 or goal < 0:
		return -1.0
	var seen := {start: 0}
	var queue: Array[int] = [start]
	var head := 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		if node == goal:
			return float(seen[node]) * ReachabilityGrid.CELL * Tuning.TILE_SIZE
		for edge: Array in grid.neighbours(node):
			var next: int = edge[0]
			if seen.has(next):
				continue
			var centre := EventScheduler.WalkSiting._cell_centre(city.map, grid.cell_of(next))
			if next != goal:
				if centre.distance_to(plan.position) <= plan.def.outer_radius:
					continue
				if engine and engine_at != Vector2.INF \
						and centre.distance_to(engine_at) <= engine.outer_radius:
					continue
			seen[next] = int(seen[node]) + 1
			queue.append(next)
	return -1.0

# ------------------------------------------------------------- the two routes ---

func _the_walk(city: City, day: int, walk_name: String) -> PackedVector2Array:
	match walk_name:
		"out and back":
			return _out_and_back(city, day)
		"turns back":
			return _turns_back_at_the_first_junction(city, day)
		"off the path":
			return _off_the_path(city)
		_:
			return _stays_near_home(city, day)

## **A player walking her own line rather than the day's.** She leaves the doorstep due east and
## keeps going, through the lattice, turning round at the border — which is off the tree most of the
## way, so most attempts find no branch to be ahead on and the fire waits. It is the case the
## acceptance rules are meant to answer with patience, and the case E exists for: a day she can win
## without ever having been offered the fire at all.
func _off_the_path(city: City) -> PackedVector2Array:
	var points := PackedVector2Array()
	var at := city.map.doorstep_world_position()
	var heading := Vector2.DOWN
	var step := Tuning.TILE_SIZE * 4.0
	for i in 80:
		var next := at + heading * step
		if not city.map.in_bounds(city.map.world_to_tile(next + heading * step * 4.0)):
			heading = Vector2.RIGHT if heading == Vector2.DOWN else -heading
			next = at + heading * step
		at = next
		points.append(at)
	return points

## **A player who spends the day on her own street.** She walks the first few cells of the day's
## route and back, over and over — so she is either inside `ON_HER_WAY_BEYOND_HOME` of the doorstep,
## where no siting is due at all, or on the tree with the fire sited a streaming band away that she
## never closes. Either way it is a day 3 she can win with the fire owed and never once in the
## world, which is exactly what the end-of-day lighting is for.
func _stays_near_home(city: City, day: int) -> PackedVector2Array:
	var route := _out_and_back(city, day)
	var near := PackedVector2Array()
	var stretch := mini(NEAR_HOME_CELLS, route.size())
	for lap in 8:
		for i in stretch:
			near.append(route[i])
		for i in range(stretch - 1, -1, -1):
			near.append(route[i])
	return near

## How much of the route out a player who stays near home walks, in cells.
const NEAR_HOME_CELLS := 8

## The day's longest route, walked from the doorstep out to its calm area and back again.
func _out_and_back(city: City, day: int) -> PackedVector2Array:
	var route := _longest_route(RouteTree.for_day(city.map, day))
	if route.is_empty():
		return PackedVector2Array()
	var out := _as_world(city, route, true)
	var back := _as_world(city, route, false)
	var whole := PackedVector2Array(out)
	whole.append_array(back)
	return whole

## Out along one branch for `PAST_THE_FORK` cells, back to the doorstep, and out along another —
## a player who changes her mind at the first junction, before she has been walking long enough for
## anything to be sited at all. What it asks is that the fire lands on the branch she ended up on
## rather than the one she started down.
func _turns_back_at_the_first_junction(city: City, day: int) -> PackedVector2Array:
	var tree := RouteTree.for_day(city.map, day)
	var first := _longest_route(tree)
	var second := _a_different_route(tree, first)
	if first.is_empty() or second.is_empty():
		return _out_and_back(city, day)
	var wrong_way := _as_world(city, first, true)
	var whole := PackedVector2Array()
	var stop := mini(PAST_THE_FORK, wrong_way.size())
	for i in stop:
		whole.append(wrong_way[i])
	for i in range(stop - 1, -1, -1):
		whole.append(wrong_way[i])
	whole.append_array(_as_world(city, second, true))
	whole.append_array(_as_world(city, second, false))
	return whole

func _longest_route(tree: RouteTree) -> Array:
	var best: Array = []
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route.size() > best.size():
				best = route
	return best

## The route that parts from `unlike` as late as possible — the one whose shared stretch home is
## longest, so the rig walks a real fork rather than two ways out that never touched.
func _a_different_route(tree: RouteTree, unlike: Array) -> Array:
	var shared := {}
	for cell: Vector2i in unlike:
		shared[cell] = true
	var best: Array = []
	var best_shared := -1
	for branch in tree.branches:
		for route: Array in branch.routes:
			if route == unlike or route.is_empty():
				continue
			var together := 0
			for i in route.size():
				if not shared.has(route[route.size() - 1 - i]):
					break
				together += 1
			if together > best_shared:
				best_shared = together
				best = route
	return best

## A route's cells as world points. `outward` reverses it, because a route is grown from the calm
## area to the doorstep and the walk out is the other way.
func _as_world(city: City, route: Array, outward: bool) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in route.size():
		var cell: Vector2i = route[route.size() - 1 - i] if outward else route[i]
		points.append(EventScheduler.WalkSiting._cell_centre(city.map, cell))
	return points

# ------------------------------------------------------------------- the rig ---

func _walker(t, at: Vector2) -> Stroller:
	var rig := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	rig.add_child(camera)
	t.add_child(rig)
	rig.set_physics_process(false)
	rig.global_position = at
	return rig

func _refusal_summary(reasons: Dictionary) -> String:
	if reasons.is_empty():
		return "nothing"
	var parts: Array[String] = []
	for reason: String in reasons:
		parts.append("%s x%d" % [reason, reasons[reason]])
	parts.sort()
	return "; ".join(parts)

func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())
