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
	_test_every_car_drives_on_its_own_right(t)
	_test_the_strike_box_never_crosses_the_kerb(t)
	_test_a_bump_costs_and_one_of_them_is_survivable(t)
	_test_walking_into_somebody_displaces_and_startles_them(t)
	_test_a_car_strikes_what_is_in_front_of_it_and_nothing_else(t)
	_test_traffic_gives_way_at_a_crossing(t)
	_test_the_crowd_stays_in_the_field(t)
	_test_the_field_is_wider_than_the_screen(t)
	_test_cars_do_not_drive_through_each_other(t)
	_test_a_car_can_honour_the_headway_it_keeps(t)
	_test_a_car_looks_before_it_turns(t)

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
		t.check(_city.crowd.total_excitement_at(centre) < Tuning.EXCITEMENT_DECAY_WALKING,
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

## Finding 4, and the reason the crowd exists at all: a day must not be winnable by walking any
## old street. The floor that stops it is emergent — no single car outruns the walking decay, but
## on the arterial there is always another one — so this measures the street rather than asserting
## anything about one agent. The back streets must fail the same test, or there is nowhere to
## recover and no route worth choosing.
##
## Stated against the **walking** decay since playtest 07 made standing still settle nothing at
## all. It was the idle rate, which was the fastest of the three and was therefore the right
## reference for "she stops here and waits"; now that waiting is never a plan, the only question a
## street has to answer is what it costs to *walk down*, which is what a route is made of.
func _test_a_busy_street_never_lets_the_meter_fall(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var arterial := _mean_excitement(CrowdLanes.arterial_pavement(_city.map), 60.0)
	_city.crowd.start_day(1, _rng(1))
	var quiet := _mean_excitement(CrowdLanes.quietest_pavement(_city.map), 60.0)

	t.check(arterial > Tuning.EXCITEMENT_DECAY_WALKING,
			"walking the arterial loses ground on average (%.1f vs %.1f decay)"
			% [arterial, Tuning.EXCITEMENT_DECAY_WALKING])
	# The other half of the same rule, and the mistake made first: the arterial has to be
	# expensive, not impassable. At three times the walking decay it fills the meter faster
	# than a player can cross it, and a street nobody can use is not a route decision.
	t.check(arterial < Tuning.EXCITEMENT_DECAY_WALKING * 3.0,
			"the arterial is expensive to cross, not impossible (%.1f vs %.1f decay)"
			% [arterial, Tuning.EXCITEMENT_DECAY_WALKING])
	t.check(quiet < Tuning.EXCITEMENT_DECAY_WALKING,
			"a back street is somewhere she can recover (%.1f vs %.1f decay)"
			% [quiet, Tuning.EXCITEMENT_DECAY_WALKING])
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
	# Since M29 the target is the stop line, not the paint, so the setback is part of the room
	# a car needs. Without it the guarantee is about a place no car is aiming for any more.
	var worst := Tuning.braking_distance(Tuning.CAR_SPEED.y) + Tuning.CAR_STOP_LINE_SETBACK
	t.check(Tuning.CAR_ZEBRA_SIGHT > worst,
			"a car sees a zebra %.0fpx out and needs %.0fpx to stop at the line"
			% [Tuning.CAR_ZEBRA_SIGHT, worst])
	t.check(Tuning.CAR_ZEBRA_SIGHT > worst * 2.0,
			"and with enough room left over that the slowing reads as giving way")
	# The car's nose ends up short of the paint rather than over it, which is the half of
	# finding 1 that made the zebra unreadable.
	t.check(Tuning.CAR_STOP_LINE_SETBACK > Tuning.CAR_STRIKE_HALF_LENGTH,
			"a car giving way stops with its nose %.0fpx clear of the zebra"
			% (Tuning.CAR_STOP_LINE_SETBACK - Tuning.CAR_STRIKE_HALF_LENGTH))
	# The approach has to *start* in sight of the kerb, or giving way is invisible until it has
	# already happened. Shaped by the gentle rate, not by `CAR_BRAKE` — with the hard rate the
	# onset of braking and the commit point are the same instant and no car ever stops.
	var eases_from := sqrt(2.0 * Tuning.CAR_ZEBRA_APPROACH_BRAKE * Tuning.CAR_ZEBRA_SIGHT)
	t.check(eases_from >= Tuning.CAR_SPEED.y,
			"the fastest car eases off as the zebra comes into sight (%.0f against %.0f)"
			% [eases_from, Tuning.CAR_SPEED.y])
	t.check(Tuning.CAR_ZEBRA_APPROACH_BRAKE < Tuning.CAR_BRAKE,
			"and the approach is gentler than the brake it keeps in reserve")

## Playtest 05, finding 2: *"the cars are not consistently driving on the right side."* True, and
## derivable — the convention was stated over the lane *offset*, and the side of the road that
## offset lands on flips with the axis. Nothing in the suite could see it: separation, headway,
## capacity and noise are all true whichever side anybody drives on.
##
## So this is the test nobody wrote. For both axes and both directions, the lane a car is in
## has to be on that car's own right.
func _test_every_car_drives_on_its_own_right(t) -> void:
	for vertical in [true, false]:
		for direction in [1.0, -1.0]:
			var lane := CrowdLanes.road_lane(vertical, direction)
			t.check(CrowdLanes.road_direction(vertical, lane) == direction,
					"lane and direction are inverses (%s, %.0f)"
					% ["vertical" if vertical else "horizontal", direction])

			# Which way the car points, in screen coordinates, where Y is down.
			var heading := Vector2(0.0, direction) if vertical else Vector2(direction, 0.0)
			# A driver's right, from that heading. Facing east (1,0) it is south (0,1).
			var right := Vector2(-heading.y, heading.x)
			# Which way the lane lies from the middle of the carriageway. A larger offset is a
			# larger cross-axis coordinate: further east on a vertical street, further south on
			# a horizontal one.
			var middle := (CrowdLanes.ROAD_OFFSETS[0] + CrowdLanes.ROAD_OFFSETS[1]) * 0.5
			var cross_axis := Vector2(1.0, 0.0) if vertical else Vector2(0.0, 1.0)
			var lane_lies := cross_axis * signf(float(lane) - middle)
			t.check(lane_lies == right,
					"a %s car heading %.0f drives in the lane on its right"
					% ["vertical" if vertical else "horizontal", direction])

	# And the real crowd agrees with the rule, rather than the rule being true on its own.
	_city.crowd.start_day(1, _rng(1))
	var checked := 0
	for agent in _city.crowd.agents():
		if agent.kind != CrowdAgent.Kind.CAR:
			continue
		checked += 1
		var heading := agent.heading()
		var right := Vector2(-heading.y, heading.x)
		var vertical := absf(heading.y) > absf(heading.x)
		var cross := agent.global_position.x if vertical else agent.global_position.y
		# The middle of the carriageway is the seam between the two road lanes, half a tile
		# past the centre of the lower one.
		var corridor := CrowdLanes.corridor_at(cross)
		var middle := CrowdLanes.lane_centre(corridor, CrowdLanes.ROAD_OFFSETS[0]) \
				+ Tuning.TILE_SIZE * 0.5
		var cross_axis := Vector2(1.0, 0.0) if vertical else Vector2(0.0, 1.0)
		t.check(corridor >= 0 and cross_axis.dot(right) * (cross - middle) > 0.0,
				"a live car at %s is on the right of its own carriageway"
				% agent.global_position)
	t.check(checked > 0, "and the day actually had cars on it")

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
	# Four rather than three since playtest 07, and the reason is the *mix* rather than the
	# difficulty: `falloff` grew a shoulder that milestone and roughly doubled what every event
	# is worth from a distance, so the crowd handed some of the day back to the authored content.
	# What has to stay true is the shape — one is survivable, a few in a row are not.
	t.check(one * 4.0 > Tuning.EXCITEMENT_CALM_THRESHOLD,
			"but walking through four people in a row does")
	# Ten, which a probe says is about what a forty-second walk straight down a busy pavement
	# collects. So the careless walk still ends the day and the careful one does not, which is
	# the ratio the crowd exists to create.
	t.check(one * 10.0 > Tuning.METER_MAX,
			"and a careless walk through a crowd still loses the day on its own")
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
			4.0 + (Tuning.BUMP_CLEAR_RADIUS - 4.0) * (1.0 - Tuning.BUMP_PLAYER_SHARE),
			"the person she walked into takes most of the separation", 0.01)
	# *(Playtest 07, finding 5.)* Resolved **past** the radius that releases the contact, not to
	# it. Resolving to it leaves the pair sitting on their own threshold, flickering across it and
	# firing a fresh jolt every other frame, which is the "instant death" the player reported.
	t.check(Tuning.BUMP_CLEAR_RADIUS > Tuning.BUMP_RADIUS,
			"a resolved contact is pushed past the radius that counts as touching")
	# Held against her — she is not moving in this rig, so only the walker's share of each
	# separation lands — the pair still converge on the clear radius and let go, and the
	# startle fires exactly **once** across the whole contact. The old code resolved to
	# `BUMP_RADIUS` itself, which is the release threshold, so the pair sat on it and re-fired
	# a fresh 26/s jolt every other frame for as long as she stayed there.
	var startles := 1
	for frame in 30:
		if _city.crowd._bump(walker, here) == Vector2.ZERO:
			break
		if not walker.touching:
			startles += 1
	t.check(not walker.touching,
			"a contact she stands in ends by itself (%.1fpx apart)"
			% walker.global_position.distance_to(here))
	t.check(startles == 1, "and it startles them once, not once per frame (%d)" % startles)
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
		# The crowd is a field around the player, and this rig has no player: without moving the
		# focus onto the car it is outside the box, recycles on the first frame, and every
		# measurement afterwards is of a different stretch of road. Two of the three cars this
		# test picks were doing exactly that, silently, since M27.
		_city.crowd.set_focus(agent.global_position)
		var cruising := agent.speed()
		agent.pedestrian_ahead = crossing
		_step(agent, 4.0)
		t.check(agent.speed() < 1.0,
				"a car doing %.0f stops for somebody waiting at the zebra ahead" % cruising)
		# Playtest 05, finding 1: *where* it stops is the complaint, not whether. Aiming at zero
		# speed instead of at a place put it most of a block short — `CAR_ZEBRA_SIGHT` is nearly
		# four times the distance a car needs — or, if it noticed late, on the paint.
		var gap := _distance_along(agent, crossing)
		t.check(gap > 0.0, "and stops short of the crossing rather than on it (%.0fpx)" % gap)
		t.check(gap < Tuning.CAR_STOP_LINE_SETBACK + Tuning.TILE_SIZE,
				"and stops *at* the line rather than wherever the braking ran out (%.0fpx)"
				% gap)

		agent.pedestrian_ahead = Vector2.INF
		_step(agent, 3.0)
		t.check(agent.speed() > Tuning.CAR_SPEED.x * 0.5,
				"and pulls away again once the crossing is clear")
	t.check(tested > 0, "at least one car had a zebra ahead of it to give way at")

# --------------------------------------------- the world near you (M27) ---
# Playtest 04: *"traffic feels too light — I can just ignore it and cross the street whenever"*,
# *"cars still bump into each other"*, and the emphasised one, *"don't load everything upfront —
# only spawn things in the surrounding few blocks of the player."* All three are one change:
# the crowd lives in a box that travels with the player, so the population buys density where
# somebody is looking instead of pavement nobody will ever walk down.

## Everybody stays in the patch being simulated, and keeps staying there while it moves. The
## second half is the one that can quietly fail: the player walks faster than a pedestrian, so
## anybody going her way is steadily left behind, and a field that only recycles at the *far*
## edge would drain the pavement in front of her into a crowd standing two streets back.
func _test_the_crowd_stays_in_the_field(t) -> void:
	# A quarter of the way down the arterial, so fifteen seconds of running stays in the city:
	# a field dragged over the boundary is a different bug and has its own test.
	var start := CrowdLanes.arterial_pavement(_city.map)
	start.y = _city.map.world_size().y * 0.2
	_city.crowd.start_day(1, _rng(1), start)
	var field := _city.crowd.field()

	# Walk the field down the city at running pace, the way a player who has decided the park
	# is that way does.
	# The furthest anybody may legitimately be: the far edge of the field, plus the depth of the
	# band agents enter through, plus the tile of slack the boundary test allows.
	var reach := field.radius + CrowdAgent.ENTRY_SPREAD + Tuning.TILE_SIZE
	var stragglers := 0
	var worst := 0.0
	var ahead := 0
	for step in 15:
		field.centre = start + Vector2(0.0, Tuning.RUN_SPEED * step)
		_advance(1.0)
		for agent in _city.crowd.agents():
			var offset := agent.global_position - field.centre
			worst = maxf(worst, maxf(absf(offset.x), absf(offset.y)))
			if absf(offset.x) > reach or absf(offset.y) > reach:
				stragglers += 1
		if step > 5 and _agents_in_front_of(field) < 8:
			ahead += 1
	t.check(stragglers == 0,
			"nobody is left behind when the field moves (%d were, worst %.0fpx of %.0f)"
			% [stragglers, worst, reach])
	t.check(ahead == 0,
			"and the street in front of her is never empty (%d seconds it was)" % ahead)

	# And the population is the field's, not the city's: the whole point of the change.
	var act := Tuning.act_for_day(1)
	t.check(_city.crowd.agent_count()
			== Tuning.crowd_pedestrians(act) + Tuning.crowd_cars(act),
			"the act's population is what is around her, not what is scattered over the map")

## How many agents are in the half of the field she is walking into.
func _agents_in_front_of(field: CrowdField) -> int:
	var found := 0
	for agent in _city.crowd.agents():
		if agent.global_position.y > field.centre.y:
			found += 1
	return found

## The floor under `CROWD_FIELD_RADIUS`, and the only one that matters: nothing may appear on
## screen. Half the viewport diagonal is the furthest anything visible can be from the camera,
## so an agent recycled outside that is always off-camera whichever way she is facing.
func _test_the_field_is_wider_than_the_screen(t) -> void:
	var viewport := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1280),
		ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	t.check(Tuning.CROWD_FIELD_RADIUS > viewport.length() * 0.5,
			"the field (%.0f) reaches past the corner of the screen (%.0f), so nothing is "
			% [Tuning.CROWD_FIELD_RADIUS, viewport.length() * 0.5]
			+ "ever seen to appear")
	t.check(Tuning.EVENT_STREAM_RADIUS > viewport.length() * 0.5,
			"and so does the event streaming radius")

## Playtest 04: *"cars still bump into each other."* Two cars in a lane at different speeds used
## to pass straight through one another, which at M27's density stops being an occasional glitch
## and becomes what the road looks like.
##
## The check is over a real minute of a real day rather than over a contrived pair, because the
## interesting case is the one a contrived pair cannot produce: a car recycled *into* a lane
## materialises inside one already there, and no speed either of them can choose separates them.
## That is why the separation is positional and not a brake.
func _test_cars_do_not_drive_through_each_other(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var worst := INF
	var overlapping := 0
	for i in int(round(60.0 / STEP)):
		# Movement first and the separation after it, which is the order the world settles in:
		# a car recycles into a lane during its own `_process`, and the pass that pulls it clear
		# of whatever it landed on is the next one. That single frame is off-screen by
		# construction — recycling only ever happens at the edge of the field, which is further
		# out than the corner of the screen.
		for agent in _city.crowd.agents():
			agent._process(STEP)
		_city.crowd.space_out_the_traffic()
		var closest := _closest_two_cars_in_a_lane()
		worst = minf(worst, closest)
		if closest < Tuning.CAR_STRIKE_HALF_LENGTH * 2.0:
			overlapping += 1
	# A car is two tiles long. Anything closer than that is one car inside another.
	t.check(overlapping == 0,
			"no frame of a minute's traffic has one car inside another (%d did, worst %.0fpx)"
			% [overlapping, worst])

## **A turn is a placement, and it has to look before it commits.** *(M38: "when a car turns into an
## occupied lane the other car just disappears.")*
##
## The test above is the one that has always been here, and it passes either way: the separation
## works, and that is the problem. `_divert()` picked an arm of a junction out of the tile map alone,
## so a car diverting round a closure materialised wherever that lane happened to be occupied — and
## the M27 rule that separation is positional then resolved it the only way it can, by *moving* a
## body. Resolving a queue front-to-back cascades, so the correction is the shortfall plus everything
## ahead of it. A probe parked at a closure measured turns landing 66px from another car 152px from
## the player, and **1627 corrections over ninety seconds with a worst of 134px** — two car lengths
## of road, gone in one frame, in plain sight. It is 146 and 66px now. The queue was always legal
## afterwards, which is exactly why nothing caught it.
##
## Two halves. The index, on its own, is the question a turning car asks; and the whole crowd, run
## for a minute, must not correct anybody by more than a car's own length in a single frame — a
## *relationship* ("a correction is a nudge, not a teleport") rather than a measured number.
func _test_a_car_looks_before_it_turns(t) -> void:
	var index := TrafficIndex.new()
	index.rebuild({"v:3:2:1": PackedFloat32Array([0.0, 400.0])})
	t.check(not index.room_at("v:3:2:1", 20.0, Tuning.CAR_GAP_MIN),
			"there is no room a fifth of a car length behind a car")
	t.check(not index.room_at("v:3:2:1", -30.0, Tuning.CAR_GAP_MIN),
			"nor just in front of one — a turn lands *in* a queue, so both sides count")
	t.check(index.room_at("v:3:2:1", 200.0, Tuning.CAR_GAP_MIN),
			"and there is room in the gap between the two of them")
	t.check(index.room_at("h:1:2:1", 0.0, Tuning.CAR_GAP_MIN),
			"a lane with nobody in it is free")

	_city.crowd.start_day(1, _rng(1))
	var was: Dictionary = {}
	var worst := 0.0
	for i in int(round(60.0 / STEP)):
		for agent in _city.crowd.agents():
			agent._process(STEP)
		# Read the positions **between** the movement and the separation, so what is measured is
		# what the separation pass did and nothing else. Inferring it from a whole frame does not
		# work: a recycle is a teleport by design, and re-rolling a lane can land in the one it
		# just left, so there is no property of the agent that tells the two apart afterwards.
		for agent in _city.crowd.agents():
			if agent.kind == CrowdAgent.Kind.CAR:
				was[agent] = agent.global_position
		_city.crowd.space_out_the_traffic()
		if i == 0:
			# The first frame is the **day being built**, and it is the one frame where a large
			# correction is right: cars are placed along their corridors without consulting each
			# other, so a busy lane opens with ten of them inside each other and this pass is what
			# unpacks it. Nobody sees it — there is no previous frame of that street to have seen it
			# in — and pre-spacing them in `start_day` instead turns the random morning into tight
			# platoons at minimum headway, which three balance tests correctly object to.
			continue
		for agent: CrowdAgent in was:
			worst = maxf(worst, agent.global_position.distance_to(was[agent]))
	t.check(worst <= Tuning.CAR_GAP_MIN,
			"the separation pass never moves a running car more than its own length in one frame "
			+ "(worst %.0fpx)" % worst)

## The tightest two cars sharing a lane got, in px.
func _closest_two_cars_in_a_lane() -> float:
	var lanes := {}
	for agent in _city.crowd.agents():
		if agent.kind != CrowdAgent.Kind.CAR:
			continue
		var key := agent.lane_key()
		if not lanes.has(key):
			lanes[key] = [] as Array[float]
		lanes[key].append(agent.queue_position())
	var closest := INF
	for key: String in lanes:
		var queue: Array[float] = lanes[key]
		queue.sort()
		for i in queue.size() - 1:
			closest = minf(closest, queue[i + 1] - queue[i])
	return closest

## The relationship the headway rests on, stated rather than measured: a car has to be able to
## *reach* the speed its gap allows. If the headway were shorter than the time it takes to brake
## from cruise, the queue would resolve by interpenetration again however good the controller is.
func _test_a_car_can_honour_the_headway_it_keeps(t) -> void:
	var braking := Tuning.CAR_SPEED.y / Tuning.CAR_BRAKE
	t.check(Tuning.CAR_HEADWAY_TIME > braking,
			"the headway (%.2fs) outlasts the time to stop from full speed (%.2fs)"
			% [Tuning.CAR_HEADWAY_TIME, braking])
	t.check(Tuning.CAR_GAP_MIN > Tuning.CAR_STRIKE_HALF_LENGTH * 2.0,
			"and a stopped queue leaves a car's length between bumpers (%.0f > %.0f)"
			% [Tuning.CAR_GAP_MIN, Tuning.CAR_STRIKE_HALF_LENGTH * 2.0])

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
## than the braking distance it legitimately cannot stop for — since M29 it *commits* and clears
## the crossing instead — and the horn is the contract there rather than the brake.
##
## The floor is written out of the constants rather than as a tile count, because it moved when
## the stop line arrived: a car now needs its braking distance **plus the setback**, and a
## hard-coded "three tiles" was silently a tile short of that.
func _crossing_ahead_of(agent: CrowdAgent) -> Vector2:
	var forward := agent.heading()
	var floor_px := Tuning.braking_distance(Tuning.CAR_SPEED.y) + Tuning.CAR_STOP_LINE_SETBACK
	var first := ceili((floor_px + Tuning.TILE_SIZE) / float(Tuning.TILE_SIZE))
	for step in range(first, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var at := agent.global_position + forward * float(step * Tuning.TILE_SIZE)
		if _city.map.tile_type_at_world(at) == GameEnums.TileType.CROSSING:
			return at
	return Vector2.INF

## How far a point is in front of an agent, along the street it is on. Negative once the agent
## has gone past it.
func _distance_along(agent: CrowdAgent, point: Vector2) -> float:
	return agent.heading().dot(point - agent.global_position)

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
