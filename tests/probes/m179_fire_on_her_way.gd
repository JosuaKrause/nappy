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
		for walk_name: String in ["out and back", "turns back"]:
			var result := _walk_one(t, city, seed_value, walk_name)
			walks += 1
			if result.get("met", false):
				met += 1
			else:
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
	print("met the fire: %d of %d walks" % [met, walks])
	print("won with it unmet: %d — lit at dusk on %d of those" % [unmet_on_a_won_day, lit_at_dusk])
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

	var route := _out_and_back(city, day) if walk_name == "out and back" \
			else _turns_back_at_the_first_junction(city, day)
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
	else:
		print("%-6d %-12s never seen (sited at %.1fs) %25d  %s"
				% [seed_value, walk_name, state["sited_at"], widened,
				_refusal_summary(state["refusals"])])

	rig.free()
	GameState.scars = scars
	var out := state.duplicate()
	out["met"] = met
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

# ------------------------------------------------------------- the two routes ---

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
