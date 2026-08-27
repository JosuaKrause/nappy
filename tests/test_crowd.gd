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
	_test_the_traffic_contract_is_fair(t)
	_test_a_car_can_always_stop_for_a_zebra_it_can_see(t)
	_test_the_strike_box_never_crosses_the_kerb(t)
	_test_a_bump_costs_and_one_of_them_is_survivable(t)
	_test_walking_into_somebody_displaces_and_startles_them(t)
	_test_a_car_strikes_what_is_in_front_of_it_and_nothing_else(t)
	_test_traffic_gives_way_at_a_crossing(t)

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
	for block in _city.map.calm_blocks:
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

# -------------------------------------------------- bodies on the street (M19) ---
# The street's physics: a body is solid, the carriageway is lethal, and the zebra is a
# negotiation. These are the checks a screenshot cannot make — a strike box that reaches over
# the kerb kills people standing on the pavement, and it looks exactly like a fair death.

## The traffic fairness contract. A car is not an event, so `validate_event()` never sees it:
## what stands in for the telegraph is the painted road plus the horn, and the horn has to be
## long enough to walk the whole carriageway with the doubled margin a hard fail is owed.
func _test_the_traffic_contract_is_fair(t) -> void:
	t.check(Tuning.validate_traffic(), "a lethal car gives the player time to reach the kerb")
	t.check(Tuning.CAR_HORN_TIME >= Tuning.required_horn_time(),
			"horn %.2fs >= the %.2fs it takes to walk %.0fpx of carriageway, doubled"
			% [Tuning.CAR_HORN_TIME, Tuning.required_horn_time(),
			Tuning.carriageway_width()])
	# The other end of the same contract: the warning has to arrive before the car does, at
	# the slowest a car ever goes as well as the fastest.
	t.check(Tuning.CAR_SPEED.x * Tuning.CAR_HORN_TIME > Tuning.CAR_STRIKE_HALF_LENGTH * 2.0,
			"even the slowest car sounds its horn from further off than its own length")

## Giving way has to be *visible from the kerb*, which means the braking starts well before
## the crossing rather than at it. Stated as a relationship so a faster car or a softer brake
## cannot quietly turn a courtesy into a screech.
func _test_a_car_can_always_stop_for_a_zebra_it_can_see(t) -> void:
	var worst := Tuning.braking_distance(Tuning.CAR_SPEED.y)
	t.check(Tuning.CAR_ZEBRA_SIGHT > worst,
			"a car sees a zebra %.0fpx out and needs %.0fpx to stop"
			% [Tuning.CAR_ZEBRA_SIGHT, worst])
	t.check(Tuning.CAR_ZEBRA_SIGHT > worst * 2.0,
			"and with enough room left over that the slowing reads as giving way")

## The one geometric mistake that would make the lethal car unfair: a box wide enough to
## reach over the kerb kills people who never stepped off it, and from the outside that is
## indistinguishable from a bug in the pavement.
func _test_the_strike_box_never_crosses_the_kerb(t) -> void:
	# The far edge of a car in its own lane, measured from the middle of the carriageway.
	var reach := Tuning.TILE_SIZE * 0.5 + Tuning.CAR_STRIKE_HALF_WIDTH
	t.check(reach < Tuning.carriageway_width() * 0.5,
			"a car's strike box stops %.0fpx short of the kerb"
			% [Tuning.carriageway_width() * 0.5 - reach])

## Finding 2: bumping into somebody has to cost something, and it has to be *avoidable*, or it
## is a toll rather than a decision. The second check is the one that keeps a crowded pavement
## playable: a crowd is expensive, one person is not.
func _test_a_bump_costs_and_one_of_them_is_survivable(t) -> void:
	t.check(Tuning.BUMP_INTENSITY > Tuning.EXCITEMENT_DECAY_WALKING,
			"a contact outruns the walking decay, so it is a spike and not a ripple")
	# The jolt fades linearly over its duration, so the area under it is half the rectangle.
	var one := Tuning.BUMP_INTENSITY * Tuning.BUMP_DURATION * 0.5
	t.check(one < Tuning.EXCITEMENT_CALM_THRESHOLD,
			"one bump (%.0f) does not on its own freeze the meter (%.0f)"
			% [one, Tuning.EXCITEMENT_CALM_THRESHOLD])
	t.check(one * 3.0 > Tuning.EXCITEMENT_CALM_THRESHOLD,
			"but walking through three people in a row does")
	# The relationship that decides whether the crowd is a decision or a toll, and the one a
	# walking probe found the hard way. Pedestrian lanes are a tile apart, so the line to walk
	# is the midline between two of them — and at a contact radius of 18 there was no such
	# line anywhere on a two-tile pavement: walking the arterial cost eleven bumps in forty
	# seconds however carefully it was done. Under half a lane spacing there is one, and
	# holding it takes the same forty seconds down to two.
	t.check(Tuning.BUMP_RADIUS < Tuning.TILE_SIZE * 0.5,
			"there is a line between two pavement lanes with no contact on it (%.0f < %.0f)"
			% [Tuning.BUMP_RADIUS, Tuning.TILE_SIZE * 0.5])

## The contact resolves as a *position*, so two bodies can never end up inside each other
## however fast she is going, and the person she walked into is the thing that gets loud —
## nothing writes to `Baby.excitement` from outside. See the invariant in CLAUDE.md.
func _test_walking_into_somebody_displaces_and_startles_them(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var walker := _first_of(CrowdAgent.Kind.WALKER)
	t.check(walker != null, "there is somebody on the pavement to walk into")
	if not walker:
		return

	var here := walker.global_position
	var quiet := walker.contribution_at(here)
	walker.global_position = here + Vector2(4.0, 0.0)
	var share: Vector2 = _city.crowd._bump(walker, here)

	# They take the larger share of the separation and she takes the rest, so a contact moves
	# them both — finding 2 asked for exactly that, and it is why a crowd is somewhere you get
	# pushed around rather than a wall you bounce off.
	t.close_to(walker.global_position.distance_to(here),
			4.0 + (Tuning.BUMP_RADIUS - 4.0) * (1.0 - Tuning.BUMP_PLAYER_SHARE),
			"the person she walked into takes most of the separation", 0.01)
	t.check(share.length() > 0.0 and share.dot(walker.global_position - here) < 0.0,
			"and she is pushed the other way")
	t.check(walker.is_startled(), "the person is startled")
	t.check(walker.contribution_at(here) > quiet + Tuning.EXCITEMENT_DECAY_WALKING,
			"which is what reaches the baby — a source on a body, not a write to the meter")

	# The property that actually matters: standing in somebody resolves rather than sticking.
	# A single frame does not clear the overlap, and it must not have to.
	var frames := 0
	while _city.crowd._bump(walker, here) != Vector2.ZERO and frames < 60:
		frames += 1
	t.check(frames < 60 and walker.global_position.distance_to(here) >= Tuning.BUMP_RADIUS,
			"and a few frames of contact push them clear of each other (%d)" % frames)

	# A contact well outside the radius does nothing at all.
	var other := _first_of(CrowdAgent.Kind.WALKER, walker)
	if other:
		other.global_position = here + Vector2(Tuning.BUMP_RADIUS * 3.0, 0.0)
		var was := other.global_position
		t.check(_city.crowd._bump(other, here) == Vector2.ZERO
				and other.global_position == was,
				"passing somebody wide is free, which is what makes it a choice")

## The lethal half. Checked directly rather than by walking a player into traffic, because the
## interesting cases are the ones that must *not* fire.
func _test_a_car_strikes_what_is_in_front_of_it_and_nothing_else(t) -> void:
	var car := _first_of(CrowdAgent.Kind.CAR)
	t.check(car != null, "there is traffic on the roads")
	if not car:
		return
	var forward := car.heading()
	var across := Vector2(-forward.y, forward.x)
	var at := car.global_position

	t.check(_strike(car, at), "standing where the car is ends the day")
	t.check(not _strike(car, at + forward * (Tuning.CAR_STRIKE_HALF_LENGTH + 4.0)),
			"standing beyond its bumper does not")
	t.check(not _strike(car, at + across * (Tuning.CAR_STRIKE_HALF_WIDTH + 4.0)),
			"and neither does standing beside it")

	# A car halted at a zebra is scenery. Walking into one must never end the day, or giving
	# way would be a trap rather than a courtesy.
	var cruising := car._speed
	car._speed = 0.0
	t.check(not _strike(car, at), "a car that has stopped cannot run anybody over")
	car._speed = cruising

## Finding 3: *"cars should stop at crossings when I am close."* A zebra is only the safe way
## over if the traffic honours it — otherwise it is paint, and the choice between crossing here
## and jaywalking there has one arm missing.
func _test_traffic_gives_way_at_a_crossing(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var tested := 0
	var extent := _city.map.world_size()
	for agent in _city.crowd.agents():
		if tested >= 3 or agent.kind != CrowdAgent.Kind.CAR:
			continue
		# Away from the edge, or the car is recycled mid-test and comes back somewhere else.
		var at := agent.global_position
		if at.x < 400.0 or at.y < 400.0 or at.x > extent.x - 400.0 or at.y > extent.y - 400.0:
			continue
		var crossing := _crossing_ahead_of(agent)
		if crossing == Vector2.INF:
			continue
		tested += 1
		var cruising := agent.speed()
		agent.pedestrian_ahead = crossing
		_step(agent, 4.0)
		t.check(agent.speed() < 1.0,
				"a car doing %.0f stops for somebody waiting at the zebra ahead" % cruising)
		t.check(agent.global_position.distance_to(crossing) > 1.0,
				"and stops short of the crossing rather than on it")

		agent.pedestrian_ahead = Vector2.INF
		_step(agent, 3.0)
		t.check(agent.speed() > Tuning.CAR_SPEED.x * 0.5,
				"and pulls away again once the crossing is clear")
	t.check(tested > 0, "at least one car had a zebra ahead of it to give way at")

# ------------------------------------------------------------------- helpers ---

func _first_of(kind: CrowdAgent.Kind, except: CrowdAgent = null) -> CrowdAgent:
	for agent in _city.crowd.agents():
		if agent.kind == kind and agent != except:
			return agent
	return null

## `Crowd` refuses to strike twice, so a test asking several questions has to clear the flag
## between them — the day is over after the first one in the game.
func _strike(car: CrowdAgent, at: Vector2) -> bool:
	_city.crowd._struck = false
	return _city.crowd._strike(car, at)

func _step(agent: CrowdAgent, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		agent._process(STEP)

## The first zebra far enough ahead of a car that it has room to stop for it. Anything closer
## than the braking distance it legitimately cannot stop for, and the horn is the contract
## there rather than the brake.
func _crossing_ahead_of(agent: CrowdAgent) -> Vector2:
	var forward := agent.heading()
	for step in range(3, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var at := agent.global_position + forward * float(step * Tuning.TILE_SIZE)
		if _city.map.tile_type_at_world(at) == GameEnums.TileType.CROSSING:
			return at
	return Vector2.INF

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
