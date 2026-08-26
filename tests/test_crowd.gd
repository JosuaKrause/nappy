extends RefCounted
## The crowd: the city's own traffic, and the noise floor it makes.
##
## This runs against a real generated City, like `test_event_manager.gd`, because the
## interesting failures are geometric — a walker that drifts into a park, a car that ends up
## on the pavement, a lane whose centre is a tile off. None of those are visible to a
## data-level test and a screenshot cannot judge whether they *always* hold.
##
## The relationships asserted here are the ones the design rests on. Values move during
## balancing; these must not.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242
const STEP := 1.0 / 60.0

var _city: City

func run(t) -> void:
	_city = CITY_SCENE.instantiate()
	t.add_child(_city)
	_city.build(CityGenerator.generate(SEED))

	_test_population_follows_the_act(t)
	_test_the_streets_empty_out_after_act_two(t)
	_test_the_same_day_makes_the_same_crowd(t)
	_test_walkers_stay_on_foot_and_cars_stay_on_the_road(t)
	_test_a_close_pass_costs_and_a_wide_one_does_not(t)
	_test_a_car_is_louder_and_carries_further_than_a_person(t)
	_test_a_park_is_out_of_earshot_of_the_traffic(t)
	_test_a_busy_street_never_lets_the_meter_fall(t)
	_test_the_arterial_is_the_busiest_street(t)

	_city.free()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd:%d:%d" % [SEED, day])
	return rng

## Runs the crowd forward. Agents are stepped by hand rather than by the tree, so a suite
## can cover a minute of traffic without waiting a minute.
func _advance(seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		for agent in _city.crowd.agents():
			agent._process(STEP)

# ------------------------------------------------------------------ population ---

func _test_population_follows_the_act(t) -> void:
	for day in [1, 5, 9, 13]:
		_city.crowd.start_day(day, _rng(day))
		var act := Tuning.act_for_day(day)
		t.check(_city.crowd.agent_count()
				== Tuning.crowd_pedestrians(act) + Tuning.crowd_cars(act),
				"day %d (act %d) puts the act's whole population on the streets"
				% [day, act])

## The point of the number, not the number: from act III there is nobody left going out, and
## the city becomes an easier place to put a baby to sleep. If that ever inverts, the horror
## inverts with it.
func _test_the_streets_empty_out_after_act_two(t) -> void:
	for act in range(1, 5):
		t.check(Tuning.crowd_pedestrians(act) > 0 and Tuning.crowd_cars(act) > 0,
				"act %d has somebody on the streets" % act)
	t.check(Tuning.crowd_pedestrians(3) < Tuning.crowd_pedestrians(1) * 0.5,
			"act III is drastically emptier than act I, not merely quieter")
	t.check(Tuning.crowd_cars(3) < Tuning.crowd_cars(1) * 0.5,
			"act III's roads are drastically emptier too")
	t.check(Tuning.crowd_pedestrians(4) > Tuning.crowd_pedestrians(3),
			"act IV puts a little life back on the streets")

func _test_the_same_day_makes_the_same_crowd(t) -> void:
	_city.crowd.start_day(4, _rng(4))
	_advance(6.0)
	var first: Array[Vector2] = []
	for agent in _city.crowd.agents():
		first.append(agent.position)

	_city.crowd.start_day(4, _rng(4))
	_advance(6.0)
	var same := true
	var agents := _city.crowd.agents()
	for i in agents.size():
		if agents[i].position.distance_to(first[i]) > 0.01:
			same = false
	t.check(same, "the same day and seed rebuild the same crowd in the same places")

# -------------------------------------------------------------------- geometry ---

## Walkers belong on the pavement and cars on the carriageway, and they have to still be
## there after a minute of turning corners — the turn is where a lane change could put
## somebody through a wall.
func _test_walkers_stay_on_foot_and_cars_stay_on_the_road(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	_advance(60.0)

	var strays := 0
	var wrong_surface := 0
	for agent in _city.crowd.agents():
		var tile := _city.map.world_to_tile(agent.position)
		if not _city.map.in_bounds(tile):
			continue  # Recycled agents legitimately sit just off the edge.
		var type := _city.map.tile_at(tile)
		if not Tile.is_walkable(type):
			strays += 1
		elif agent.kind == CrowdAgent.Kind.CAR:
			if not Tile.is_road(type):
				wrong_surface += 1
		elif Tile.is_road(type) and type != GameEnums.TileType.CROSSING:
			wrong_surface += 1
	t.check(strays == 0, "no agent has walked into a building (%d did)" % strays)
	t.check(wrong_surface == 0,
			"every walker is on foot and every car is on the road (%d were not)"
			% wrong_surface)

## The whole crowd is on the street lattice, so a park keeps its quiet. This is the
## structural half of "a park is quiet because nobody is in it".
func _test_a_park_is_out_of_earshot_of_the_traffic(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	_advance(45.0)
	for block in _city.map.park_blocks:
		var centre := _city.map.tile_rect_to_world(CityMap.block_rect(block)).get_center()
		t.check(_city.crowd.total_excitement_at(centre) < Tuning.EXCITEMENT_DECAY_IDLE,
				"the middle of park %s recovers faster than the traffic loads it"
				% [block])

# ------------------------------------------------------------------- the floor ---

## Finding 9: passing a person barely moved the meter, so the crowd was scenery. It has to
## cost something up close — and it has to be avoidable, or the cost is not a decision.
## The pavement is two tiles, which is what makes "how close do I pass" a real choice.
func _test_a_close_pass_costs_and_a_wide_one_does_not(t) -> void:
	t.check(Tuning.PEDESTRIAN_INTENSITY > Tuning.EXCITEMENT_DECAY_WALKING,
			"brushing past somebody (%.1f) outruns the walking decay (%.1f)"
			% [Tuning.PEDESTRIAN_INTENSITY, Tuning.EXCITEMENT_DECAY_WALKING])

	var pavement := float(Tuning.SIDEWALK_WIDTH * Tuning.TILE_SIZE)
	var wide := Tuning.falloff(pavement, Tuning.PEDESTRIAN_INTENSITY,
			Tuning.PEDESTRIAN_INNER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS)
	t.check(wide < Tuning.EXCITEMENT_DECAY_WALKING,
			"giving somebody the width of the pavement (%.1f) stays under the decay (%.1f)"
			% [wide, Tuning.EXCITEMENT_DECAY_WALKING])
	t.check(Tuning.PEDESTRIAN_INNER_RADIUS < pavement,
			"the close-pass band is narrower than the pavement, so it can be walked around")

func _test_a_car_is_louder_and_carries_further_than_a_person(t) -> void:
	t.check(Tuning.CAR_INTENSITY > Tuning.PEDESTRIAN_INTENSITY,
			"a car is louder than a person")
	t.check(Tuning.CAR_OUTER_RADIUS > Tuning.PEDESTRIAN_OUTER_RADIUS,
			"a car is heard from further away than a person")
	t.check(Tuning.CAR_SPEED.x > Tuning.WALK_SPEED,
			"even the slowest car outpaces a walk, so a road cannot be strolled alongside")
	t.check(Tuning.CAR_SPEED.y <= EventCatalogue.by_id("fire_truck").speed,
			"an emergency vehicle is still the fastest thing on the road")

## Finding 4, and the reason the crowd exists at all: a day must not be winnable by standing
## still on a street. The floor that stops it is emergent — no single car outruns the idle
## decay, but on the arterial there is always another one — so this measures the street
## rather than asserting anything about one agent. The back streets must fail the same test,
## or there is nowhere to recover and no route worth choosing.
func _test_a_busy_street_never_lets_the_meter_fall(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var arterial := _mean_excitement(CrowdLanes.arterial_pavement(_city.map), 60.0)
	_city.crowd.start_day(1, _rng(1))
	var quiet := _mean_excitement(CrowdLanes.quietest_pavement(_city.map), 60.0)

	t.check(arterial > Tuning.EXCITEMENT_DECAY_IDLE,
			"standing on the arterial loses ground on average (%.1f vs %.1f decay)"
			% [arterial, Tuning.EXCITEMENT_DECAY_IDLE])
	# The other half of the same rule, and the mistake made first: the arterial has to be
	# expensive, not impassable. At three times the idle decay it fills the meter faster
	# than a player can cross it, and a street nobody can use is not a route decision.
	t.check(arterial < Tuning.EXCITEMENT_DECAY_IDLE * 3.0,
			"the arterial is expensive to cross, not impossible (%.1f vs %.1f decay)"
			% [arterial, Tuning.EXCITEMENT_DECAY_IDLE])
	t.check(quiet < Tuning.EXCITEMENT_DECAY_IDLE,
			"a back street is somewhere she can recover (%.1f vs %.1f decay)"
			% [quiet, Tuning.EXCITEMENT_DECAY_IDLE])
	t.check(arterial > quiet * 2.0,
			"the main road is not merely busier than a back street, it is a different place")

## Mean crowd excitement at a point over `seconds` of traffic. A single instant says nothing
## — the whole character of a street is how often the next car comes.
func _mean_excitement(at: Vector2, seconds: float) -> float:
	var total := 0.0
	var samples := 0
	for i in int(round(seconds / STEP)):
		for agent in _city.crowd.agents():
			agent._process(STEP)
		total += _city.crowd.total_excitement_at(at)
		samples += 1
	return total / maxi(1, samples)

## A grid where every street is equally loud is a grid with nothing to choose between. The
## arterial has to be the loud one, and it has to be the *same* one every morning.
func _test_the_arterial_is_the_busiest_street(t) -> void:
	var arterial := CrowdLanes.arterial_index(Tuning.CITY_BLOCKS.x)
	var busiest := CrowdLanes.busyness(_city.map.seed_used, true, arterial)
	for index in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x):
		if index == arterial:
			continue
		t.check(CrowdLanes.busyness(_city.map.seed_used, true, index) < busiest,
				"corridor %d is quieter than the arterial" % index)
	t.check(CrowdLanes.busyness(_city.map.seed_used, true, arterial)
			== CrowdLanes.busyness(_city.map.seed_used, true, arterial),
			"a street's character is stable, not rolled afresh on every question")
