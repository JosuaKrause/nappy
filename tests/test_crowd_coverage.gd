extends RefCounted
## A city overview retains ordinary crowd density and real traffic in every quadrant,
## while the normal player-following field keeps its population and movement behavior.
##
## A crowd on a real generated map with **no city around it**: `Crowd.setup()` is handed a bare world, the map
## and its lights, as a task scene's rig hands it (`tests/crowd_street_rig.gd`'s `a_crowd()`), so this suite
## tests the crowd.

const Rig := preload("res://tests/crowd_street_rig.gd")
## The seed of the map the crowd is built on.
const MAP_SEED := 1917501

var _rig := Rig.new()

func run(t: TestRunner) -> void:
	var map := CityGenerator.generate(MAP_SEED)
	var crowd := _rig.a_crowd(t, map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var focus := map.doorstep_world_position()
	crowd.start_day(1, rng, focus, true, true)
	var middle := map.world_size() * 0.5
	t.check(_spans_the_map(crowd, map), "city crowd field covers the entire map")
	# The player moves to the far corner and the overview stays where it is: the frames below still
	# find the crowd moving in every quadrant (the per-quadrant checks of physical movement), where a
	# field that followed her would recycle the far quadrants' bodies into a box round the corner.
	crowd.set_focus(Vector2.ZERO)
	crowd.set_focus(map.world_size())
	var area_scale := map.world_size().x * map.world_size().y \
			/ pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0)
	var initial := crowd.recipe_coverage()
	t.check(initial.walkers == roundi(Tuning.crowd_pedestrians(1) * area_scale)
			and initial.cars == roundi(Tuning.crowd_cars(1) * area_scale),
			"city crowd preserves the existing population per covered field area")
	var positions := {}
	for agent in crowd.agents():
		positions[agent] = agent.global_position
	for frame in 90:
		crowd.step(1.0 / 30.0)
	var measured := {"nw": {"moving": 0, "moving_cars": 0}, "ne": {"moving": 0, "moving_cars": 0},
			"sw": {"moving": 0, "moving_cars": 0}, "se": {"moving": 0, "moving_cars": 0}}
	for agent in crowd.agents():
		var at := agent.global_position
		var moved: float = at.distance_to(positions[agent])
		# Recycling is not evidence of motion. Only a plausible physical displacement
		# during the three-second window contributes to the measured coverage.
		if moved <= 1.0 or moved > Tuning.CAR_SPEED.y * 3.0:
			continue
		var quadrant := ("n" if at.y < middle.y else "s") + ("w" if at.x < middle.x else "e")
		measured[quadrant].moving += 1
		if agent.kind == CrowdAgent.Kind.CAR:
			measured[quadrant].moving_cars += 1
	var coverage := crowd.recipe_coverage()
	t.check(coverage.scope == "city", "and the capture reports the city view it covers")
	for quadrant: String in coverage.quadrants:
		var counts: Dictionary = coverage.quadrants[quadrant]
		t.check(counts.walkers > 0 and counts.cars > 0,
				"%s contains both pedestrians and cars across the city view" % quadrant)
		t.check(counts.moving > 0 and counts.moving_cars > 0,
				"%s reports effective movement including traffic" % quadrant)
		t.check(measured[quadrant].moving > 0 and measured[quadrant].moving_cars > 0,
				("%s actors and cars physically move under production signals and queue updates, the "
				+ "city crowd's bounds staying fixed as the player moves") % quadrant)
	print("RECIPE_CROWD_COVERAGE ", JSON.stringify(coverage), " displacement ", JSON.stringify(measured))
	crowd.start_day(1, rng, focus)
	t.check(crowd.recipe_coverage().scope == "local" and _all_round(crowd, map, focus),
			"a normal day restores the moving field after a city-view recipe")
	t.check(crowd.agent_count() == Tuning.crowd_pedestrians(1) + Tuning.crowd_cars(1),
			"normal population is unchanged by the optional city view")
	# Somewhere a field round the doorstep does not reach, so a field that stayed put keeps people a
	# field round there would have recycled.
	var away := _farthest_quarter(map, focus)
	t.check(_offset(away, focus) > _reach(map, away), "the field has somewhere else to go")
	crowd.set_focus(away)
	for frame in 3:
		crowd.step(1.0 / 30.0)
	t.check(_all_round(crowd, map, away), "normal field follows focus again")
	crowd.start_day(1, rng, focus, false, true)
	t.check(crowd.agent_count() == 0, "city-view extent does not enable unrequested population")
	_rig.free_crowd(crowd)

## Whether the crowd stands over the whole map: its bodies reach within a block of every edge.
static func _spans_the_map(crowd: Crowd, map: CityMap) -> bool:
	var lo := map.world_size()
	var hi := Vector2.ZERO
	for agent in crowd.agents():
		lo = lo.min(agent.global_position)
		hi = hi.max(agent.global_position)
	var block := float(CityMap.period() * Tuning.TILE_SIZE)
	return lo.x < block and lo.y < block and hi.x > map.world_size().x - block \
			and hi.y > map.world_size().y - block

## How far from `at` a body of a field centred there may legitimately be: the field's half extent
## there (`CrowdField.half_extent()`), plus the depth of the band bodies enter through, plus a tile
## of slack, as `tests/crowd_rig.gd` measures the field she walks.
static func _reach(map: CityMap, at: Vector2) -> float:
	return CrowdField.new(map, at).half_extent() + CrowdAgent.ENTRY_SPREAD + Tuning.TILE_SIZE

## The larger of the two axis distances between two points, the distance the field's box measures.
static func _offset(a: Vector2, b: Vector2) -> float:
	return maxf(absf(a.x - b.x), absf(a.y - b.y))

## Whether every body of the crowd stands within a field's reach of `at`.
static func _all_round(crowd: Crowd, map: CityMap, at: Vector2) -> bool:
	var reach := _reach(map, at)
	for agent in crowd.agents():
		if _offset(agent.global_position, at) > reach:
			return false
	return not crowd.agents().is_empty()

## The quarter point of the map, half way from its middle to a corner, farthest from `from`.
static func _farthest_quarter(map: CityMap, from: Vector2) -> Vector2:
	var best := map.world_size() * 0.25
	for x: float in [0.25, 0.75]:
		for y: float in [0.25, 0.75]:
			var at := map.world_size() * Vector2(x, y)
			if _offset(at, from) > _offset(best, from):
				best = at
	return best
