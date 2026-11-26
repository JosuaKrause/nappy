extends RefCounted
## Measurement probe for grassy-beaver's day two (the dead end met early, and day 1's walk left
## open): on each city, day 1's tutorial route (`TutorialRoute.for_city()`), then day 2 planned
## the way its dawn plans it after she settled in the tutorial park (the park handed to
## `CityMap.set_spent_calm()` and the map repainted, the tree grown with no tutorial route), and
## per city:
##
## - **the dead ends at the doorstep**: the side streets at the doorstep street's two junctions that
##   are off day 2's tree and so carry a seal, day 1's walk aside, since it is left open;
## - **the walk left open**: how many of the route's lesson streets are off day 2's tree, how many
##   seals and closures stand on them without the walk handed in, and how many with it (zero);
## - whether the tutorial park was taken off day 2's tree (`CityMap.shut_calm()`).
##
## Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/grassy_beaver_day_two.gd      (prints DAY_TWO lines)

const FIRST_SEED := 1
const LAST_SEED := 30
const DAY := 2

func run(t: TestRunner) -> void:
	var cities := 0
	var no_route := 0
	var with_a_dead_end := 0
	var dead_ends := 0
	var opened := 0
	var sealed_before := 0
	var closed_before := 0
	var left_on_the_walk := 0
	var park_shut := 0
	var spec := DaySpec.for_day(DAY)
	for seed_value in range(FIRST_SEED, LAST_SEED + 1):
		var map := CityGenerator.generate(seed_value)
		var route := TutorialRoute.for_city(map)
		if route == null:
			no_route += 1
			continue
		cities += 1
		var spent: Array[Vector2i] = [route.park_block()]
		map.set_spent_calm(spent)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), DAY)
		map.repaint(state)
		if map.shut_calm().has(route.park_block()):
			park_shut += 1
		var tree := RouteTree.for_day(map, DAY, null)
		var walk := {}
		for segment in route.lesson_streets():
			walk[segment.key()] = true
			if not tree.is_on_the_tree(segment.key()):
				opened += 1
		var before := _streets_of(map, SealPlanner.plan_day(map, spec, tree, _rng(map, "seals"),
				{}, null, null, null))
		var seals := SealPlanner.plan_day(map, spec, tree, _rng(map, "seals"), {}, null, null, route)
		var after := _streets_of(map, seals)
		for key: Vector3i in walk:
			if before.has(key):
				sealed_before += 1
			if after.has(key):
				left_on_the_walk += 1
		for closure in ClosurePlanner.plan_day(map, spec, _rng(map, "closures"), tree):
			if walk.has(closure.street_key()):
				closed_before += 1
		for closure in ClosurePlanner.plan_day(map, spec, _rng(map, "closures"), tree, null, null,
				route):
			if walk.has(closure.street_key()):
				left_on_the_walk += 1
		var home := ClosurePlanner.home_street(map)
		var here := 0
		for junction: Vector2i in [home.a, home.b]:
			for arm in map.street_network().at_junction(junction):
				if arm.key() == home.key() or walk.has(arm.key()):
					continue
				if after.has(arm.key()):
					here += 1
		dead_ends += here
		if here > 0:
			with_a_dead_end += 1
		print("DAY_TWO seed %d | dead ends at the doorstep %d | lesson streets off the tree %d"
				% [seed_value, here, _off_the_tree(route, tree)])
	print("DAY_TWO seeds %d-%d | cities with a route %d, none %d | park off day 2's tree %d"
			% [FIRST_SEED, LAST_SEED, cities, no_route, park_shut])
	print("DAY_TWO cities with a dead end at the doorstep %d of %d | dead ends %d"
			% [with_a_dead_end, cities, dead_ends])
	print("DAY_TWO lesson streets off day 2's tree %d | sealed without the walk %d, closed %d | seals or closures on it with the walk %d"
			% [opened, sealed_before, closed_before, left_on_the_walk])
	t.check(true, "a probe asserts nothing")

static func _off_the_tree(route: TutorialRoute, tree: RouteTree) -> int:
	var count := 0
	for segment in route.lesson_streets():
		if not tree.is_on_the_tree(segment.key()):
			count += 1
	return count

static func _rng(map: CityMap, stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%d" % [stream, map.city_seed(), DAY])
	return rng

## The streets the plans stand on, by segment key; an alley mouth stands on none.
static func _streets_of(map: CityMap, plans: Array[EventPlan]) -> Dictionary:
	var found := {}
	for plan in plans:
		var segment := map.street_network().segment_containing(map.world_to_tile(plan.placed_at()))
		if segment:
			found[segment.key()] = true
	return found
