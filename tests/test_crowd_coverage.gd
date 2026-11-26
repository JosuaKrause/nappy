extends RefCounted
## A city overview retains ordinary crowd density and real traffic in every quadrant,
## while the normal player-following field keeps its population and movement behavior.
##
## A crowd on a real generated map with **no city around it**: `Crowd.setup()` is handed a bare world, the map
## and its lights, as a task scene's rig hands it (`tests/crowd_street_rig.gd`'s `a_crowd()`), so this suite
## tests the crowd.

const Rig := preload("res://tests/crowd_street_rig.gd")
const LANE_KEYS := preload("res://tests/lane_key_search.gd")
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
	crowd.use_focus(FakeCrowdFocus.new(Vector2.ZERO))
	crowd.use_focus(FakeCrowdFocus.new(map.world_size()))
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
		if agent.lane().kind() == CrowdAgent.Kind.CAR:
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
	var source := FakeCrowdFocus.new(focus)
	crowd.use_focus(source)
	source.move_to(away)
	for frame in 3:
		crowd.step(1.0 / 30.0)
	t.check(_all_round(crowd, map, away),
			"the field follows its focus source on the rig's step(), which has no player in it")
	crowd.start_day(1, rng, focus, false, true)
	t.check(crowd.agent_count() == 0, "city-view extent does not enable unrequested population")
	_rig.free_crowd(crowd)
	_test_a_uniform_population_and_the_ordinary_day(t)

## How many of the crowd's walkers stand on each corridor, keyed `v<n>` or `h<n>` by the axis and
## the corridor their own lane key names.
static func _walkers_by_corridor(crowd: Crowd) -> Dictionary:
	var counts := {}
	for agent in crowd.agents():
		if agent.lane().kind() == CrowdAgent.Kind.CAR:
			continue
		var parts := LANE_KEYS.parts_of(agent.lane_key())
		var key := "%s%d" % ["v" if parts[0] else "h", parts[1]]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts

## **A scene recipe's uniform walkers** (`start_day()`'s `uniform_walkers` and
## `walker_multiplier`) on the map its recipe builds: an authored walker overlapping the crowd
## is refused without losing population; the walkers keep varied seeded headings within their
## lanes, double only the walkers and leave the ordinary car population, and do not concentrate
## on the main road, while still moving; and an ordinary day round the same point restores its
## density and its street hierarchy, the main road holding clearly more walkers against the
## busiest ordinary corridor than the uniform day's level.
func _test_a_uniform_population_and_the_ordinary_day(t: TestRunner) -> void:
	var recipe: Dictionary = SceneRecipe.load_file("res://scene-recipes/trailer-dog.json").data
	var built := RecipeCityBuilder.build(Shipped.rows(), recipe)
	var build_errors: Array = built.errors
	t.check(build_errors.is_empty(), "the recipe's map builds: %s" % [build_errors])
	if not build_errors.is_empty():
		return
	var map: CityMap = built.map
	var crowd := _rig.a_crowd(t, map)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	crowd.start_day(1, rng, Vector2(1952, 1936), true, false, true, 2)
	var existing: CrowdAgent = crowd.agents()[0]
	var population := crowd.agent_count()
	var duplicate := crowd.add_recipe_actor("overlap", CrowdAgent.Kind.WALKER,
			existing.position, existing.heading(), -1, 1)
	t.check(str(duplicate.error).contains("overlaps an existing walker")
			and crowd.agent_count() == population,
			"authored walker overlapping background crowd is rejected without losing population")
	var counts := {}
	var before := {}
	var cars := 0
	var lane_directions := {}
	for agent in crowd.agents():
		if agent.lane().kind() == CrowdAgent.Kind.CAR:
			cars += 1
			continue
		# The agent's own lane key says its axis, corridor, lane and heading.
		var parts := LANE_KEYS.parts_of(agent.lane_key())
		var key := "%s%d" % ["v" if parts[0] else "h", parts[1]]
		counts[key] = int(counts.get(key, 0)) + 1
		var lane := "%s:%s" % [key, parts[2]]
		if not lane_directions.has(lane):
			lane_directions[lane] = {}
		lane_directions[lane][parts[3]] = true
		before[agent] = agent.position
	var mixed := 0
	for directions: Dictionary in lane_directions.values():
		mixed += int(directions.size() == 2)
	t.check(mixed > lane_directions.size() / 2,
			"even density retains varied seeded headings within sidewalk lanes")
	t.check(cars == Tuning.crowd_cars(1) and before.size() == Tuning.crowd_pedestrians(1) * 2,
			"recipe increases only walkers while retaining ordinary car population")
	var main_key := "v%d" % map.main_road_corridor()
	var main_count := int(counts.get(main_key, 0))
	var ordinary_max := 0
	for key: String in counts:
		if key != main_key:
			ordinary_max = maxi(ordinary_max, counts[key])
	t.check(main_count > 0 and ordinary_max > 0 and main_count < ordinary_max * 1.25,
			("uniform pedestrian selection does not concentrate the field on the main road (%d of "
			+ "the busiest other corridor's %d)") % [main_count, ordinary_max])
	for frame in 30:
		crowd.step(1.0 / 30.0)
	var moving := 0
	for agent: CrowdAgent in before:
		var distance := agent.position.distance_to(before[agent])
		moving += int(distance > 1 and distance < Tuning.PEDESTRIAN_SPEED.y * 1.5)
	t.check(moving > before.size() / 2,
			"authored density retains physically moving production walkers")
	crowd.start_day(1, rng, Vector2(1952, 1936))
	var ordinary_counts := _walkers_by_corridor(crowd)
	var ordinary_main := int(ordinary_counts.get(main_key, 0))
	var ordinary_rest := 0
	for key: String in ordinary_counts:
		if key != main_key:
			ordinary_rest = maxi(ordinary_rest, ordinary_counts[key])
	var uniform_share := float(main_count) / float(maxi(ordinary_max, 1))
	var ordinary_share := float(ordinary_main) / float(maxi(ordinary_rest, 1))
	t.check(ordinary_share > uniform_share * 1.25
			and crowd.agent_count() == Tuning.crowd_pedestrians(1) + Tuning.crowd_cars(1),
			("ordinary day restores its density and street hierarchy (the main road holds %.2f of the "
			+ "busiest other corridor's walkers, against %.2f on the uniform day)")
			% [ordinary_share, uniform_share])
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
