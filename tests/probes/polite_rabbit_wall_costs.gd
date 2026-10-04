extends RefCounted
## What stopping excitement at walls does to the price of the day's own routes, walked rather than
## derived. Not a suite: it prints numbers rather than asserting relationships, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/polite_rabbit_wall_costs.gd
##
## *(plaid-wombat, inbox #554: "Excitement should not go through any wall".)* `docs/COSTS.md` prices
## a row met on open ground and does not move; the question here is what a walk through the real
## city pays once a building between a source and her silences it. Each (seed, day) builds the day
## the game builds — `City.start_day()` for the closures and the route tree, `EventManager.
## start_day()` for the catalogue, the seals and the region's bodies — and walks every route of
## every branch of the day's `RouteTree` from the doorstep to its calm area at `Tuning.WALK_SPEED`,
## streaming the events and stepping the crowd around her as she goes. At every step each source's
## field is asked three ways: through walls (no wall test, what the game charged before), blocked at
## `Tuning.WALL_SHIELD_DEPTH` (what it charges now), and blocked one whole tile in (the other
## reading of "the middle of the wall (or one tile deep)"). The built depth is also summed through
## the real `contribution_at()`, and the probe fails if the two disagree.
##
## **Limits.** The events are not ticked: each is priced at its own live rate
## (`EventInstance._caret_intensity_over_horizon()`, the telegraph's damping undone) where it
## stands when streamed in, so a mobile row is met where it starts and nothing pursues. The
## barrier structures charge as their strongest one, as `EventManager.excitement_sources_at()`
## does. Gross points only: the decay is the same with or without walls, so it is left out.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 30.0
const SEEDS: Array[int] = [4242, 90210, 1337]
const DAYS: Array[int] = [1, 5, 9, 13]

## The three ways of asking, in print order: no wall test, the built depth, a whole tile.
const NONE := 0
const BUILT := 1
const TILE := 2

var _depths: Array[float] = [INF, Tuning.WALL_SHIELD_DEPTH, float(Tuning.TILE_SIZE)]

func run(t) -> void:
	var mismatches := 0
	var grand_events := [0.0, 0.0, 0.0]
	var grand_crowd := [0.0, 0.0, 0.0]
	var grand_seconds := 0.0
	var grand_routes := 0
	print("\n== gross points over the day's routes: through walls | blocked at %.0fpx | at %dpx =="
			% [Tuning.WALL_SHIELD_DEPTH, Tuning.TILE_SIZE])
	print("  %6s %4s %6s %8s   %-26s   %-26s" % ["seed", "day", "routes", "seconds",
			"events", "crowd"])
	for city_seed in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		for day in DAYS:
			GameState.day = day
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("polite-rabbit-walls:%d:%d" % [city_seed, day])
			city.start_day(CityState.new(), day, rng)
			var consumed: Array[String] = []
			city.events.start_day(day, rng, consumed, city.map.doorstep_world_position())
			var events := [0.0, 0.0, 0.0]
			var crowd := [0.0, 0.0, 0.0]
			var seconds := 0.0
			var routes := 0
			var tree := city.route_tree()
			for branch in tree.branches:
				for route: Array in branch.routes:
					var path := _waypoints(city.map, route)
					if path.size() < 2:
						continue
					routes += 1
					var walked := _walk(city, path, day, rng, events, crowd)
					seconds += walked.x
					mismatches += int(walked.y)
			city.events.clear()
			print("  %6d %4d %6d %8.0f   %s   %s" % [city_seed, day, routes, seconds,
					_three(events), _three(crowd)])
			for i in 3:
				grand_events[i] += events[i]
				grand_crowd[i] += crowd[i]
			grand_seconds += seconds
			grand_routes += routes
		city.free()
	print("  %11s %6d %8.0f   %s   %s" % ["all", grand_routes, grand_seconds,
			_three(grand_events), _three(grand_crowd)])
	print("  per minute walked: events %s, crowd %s" % [
			_three(_per_minute(grand_events, grand_seconds)),
			_three(_per_minute(grand_crowd, grand_seconds))])
	print("  share kept: events %.1f%% / %.1f%%, crowd %.1f%% / %.1f%%" % [
			100.0 * grand_events[BUILT] / maxf(grand_events[NONE], 1e-9),
			100.0 * grand_events[TILE] / maxf(grand_events[NONE], 1e-9),
			100.0 * grand_crowd[BUILT] / maxf(grand_crowd[NONE], 1e-9),
			100.0 * grand_crowd[TILE] / maxf(grand_crowd[NONE], 1e-9)])
	t.check(grand_routes > 0, "the probe walked routes (%d)" % grand_routes)
	t.check(mismatches == 0,
			"the built depth summed here is what contribution_at() charges (%d steps differed)"
			% mismatches)

## A route's cells, doorstep first, each as the middle of its walkable tiles.
func _waypoints(map: CityMap, route: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(route.size() - 1, -1, -1):
		var cell: Vector2i = route[i]
		var sum := Vector2.ZERO
		var count := 0
		for dy in ReachabilityGrid.CELL:
			for dx in ReachabilityGrid.CELL:
				var tile := cell * ReachabilityGrid.CELL + Vector2i(dx, dy)
				if map.is_walkable(tile):
					sum += map.tile_to_world(tile)
					count += 1
		if count > 0:
			points.append(sum / float(count))
	return points

## Walks `path` at walking pace, adding each step's gross points into `events` and `crowd` three
## ways. Answers the seconds walked and how many steps the built depth disagreed with the game's own
## `contribution_at()`.
func _walk(city: City, path: PackedVector2Array, day: int, rng: RandomNumberGenerator,
		events: Array, crowd: Array) -> Vector2:
	var map := city.map
	var here := path[0]
	city.crowd.start_day(day, rng, here)
	var next := 1
	var seconds := 0.0
	var mismatches := 0
	while next < path.size():
		var step := Tuning.WALK_SPEED * STEP
		while next < path.size() and here.distance_to(path[next]) <= step:
			step -= here.distance_to(path[next])
			here = path[next]
			next += 1
		if next < path.size():
			here += (path[next] - here).normalized() * step
		seconds += STEP
		city.events.stream_around(here)
		city.crowd.set_focus(here)
		city.crowd.step(STEP)
		var rates := [0.0, 0.0, 0.0]
		var barrier := [0.0, 0.0, 0.0]
		var charged := 0.0
		var charged_barrier := 0.0
		for instance in city.events.instances():
			var live := instance._caret_intensity_over_horizon()
			var field := instance._field_at(here, live, Vector2.INF)
			if field <= 0.0:
				continue
			var actual := instance.contribution_at(here, live)
			if instance.def.barrier_structure:
				charged_barrier = maxf(charged_barrier, actual)
			else:
				charged += actual
			for i in 3:
				if i != NONE and map.wall_between(instance.global_position, here, _depths[i]):
					continue
				if instance.def.barrier_structure:
					barrier[i] = maxf(barrier[i], field)
				else:
					rates[i] += field
		if not is_equal_approx(charged + charged_barrier, rates[BUILT] + barrier[BUILT]):
			mismatches += 1
		for i in 3:
			events[i] += (rates[i] + barrier[i]) * STEP
		var heard := 0.0
		var noise := [0.0, 0.0, 0.0]
		for agent in city.crowd.agents():
			var field := agent._field_at(here)
			if field <= 0.0:
				continue
			heard += agent.contribution_at(here)
			for i in 3:
				if i != NONE and map.wall_between(agent.global_position, here, _depths[i]):
					continue
				noise[i] += field
		if not is_equal_approx(heard, noise[BUILT]):
			mismatches += 1
		for i in 3:
			crowd[i] += noise[i] * STEP
	return Vector2(seconds, mismatches)

func _three(values: Array) -> String:
	return "%8.1f %8.1f %8.1f" % [values[0], values[1], values[2]]

func _per_minute(values: Array, seconds: float) -> Array:
	var minutes := maxf(seconds / 60.0, 1e-9)
	return [values[0] / minutes, values[1] / minutes, values[2] / minutes]
