extends RefCounted
## Measurement probe for M180, posters she notices: whether the day's poster crews are met, now that
## her walk sites them (`EventDef.sited_on_her_way`, `pastes_a_front`), and how much they paste while
## she is in sight of them. Not a suite: it prints rather than asserting, so it lives under
## `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/m180_crews_on_her_way.gd
##
## The rigs are the M179 fire probe's own walks of the day's routes, since a crew is sited the way
## the fire is: on the branch of the day's route tree she is walking, one crew at a time.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 5150, 31337]
const DAYS := [4, 8, 12]
const STEP := 1.0 / 30.0
const WALK_SECONDS := 240.0
const PAST_THE_FORK := 6

func run(t) -> void:
	print("seed   day walk          crews  sited  met  first sited  sheets pasted  waited on")
	for seed_value: int in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		city.events.stream_radius = Tuning.EVENT_STREAM_RADIUS
		for day: int in DAYS:
			for walk_name: String in ["out and back", "turns back"]:
				_walk_one(t, city, seed_value, day, walk_name)
		city.free()
	t.check(true, "m180_crews_on_her_way probe ran")

func _walk_one(t, city: City, seed_value: int, day: int, walk_name: String) -> void:
	GameState.run_seed = seed_value
	GameState.posters.reset()
	var tree := RouteTree.for_day(city.map, day)
	city.poster_walls().start_day(day, tree)
	var before := _pasted_cells()
	var consumed: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [seed_value, day])
	city.events.start_day(day, rng, consumed)
	var crews: Array[EventScheduler.Planned] = []
	for plan in city.events.plans():
		if plan.def.id == "poster_crew":
			crews.append(plan)
	var route := _the_walk(city, day, walk_name)
	if route.size() < 2 or crews.is_empty():
		print("%-6d %3d %-13s no route or no crews" % [seed_value, day, walk_name])
		return
	var rig := _walker(t, route[0])
	var clock := 0.0
	var first_sited := -1.0
	for i in range(1, route.size()):
		var toward := route[i] - rig.global_position
		while toward.length() > Tuning.WALK_SPEED * STEP and clock < WALK_SECONDS:
			var heading := toward.normalized()
			rig.velocity = heading * Tuning.WALK_SPEED
			rig.global_position += heading * Tuning.WALK_SPEED * STEP
			city.events._physics_process(STEP)
			city.poster_walls()._physics_process(STEP)
			clock += STEP
			if first_sited < 0.0:
				for plan in crews:
					if plan.is_placed():
						first_sited = clock
			toward = route[i] - rig.global_position
	var sited := 0
	var met := 0
	for plan in crews:
		sited += 1 if plan.is_placed() else 0
		met += 1 if plan.was_live else 0
	var siting := city.events.walk_siting()
	print("%-6d %3d %-13s %5d %6d %4d %11.1fs %14d  %s" % [seed_value, day, walk_name, crews.size(),
			sited, met, first_sited, _pasted_cells() - before,
			_refusal_summary(siting.waits if siting else {})])
	rig.free()

## Every cell with a sheet on it, however it got there.
func _pasted_cells() -> int:
	var count := 0
	for tile: Vector2i in GameState.posters.cells:
		count += 1
	return count

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
