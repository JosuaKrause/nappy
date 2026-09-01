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
	_test_the_crowd_does_not_bunch_against_the_wall(t)
	_test_the_field_is_wider_than_the_screen(t)
	_test_cars_do_not_drive_through_each_other(t)
	_test_a_car_can_honour_the_headway_it_keeps(t)
	_test_a_car_looks_before_it_turns(t)
	_test_the_traffic_index_is_emptied_every_frame(t)
	_test_a_main_road_is_kept_by_its_lights(t)
	_test_a_signal_gives_her_time_to_cross(t)
	_test_a_precinct_has_no_cars_in_it(t)
	_test_cars_do_not_enter_a_junction_they_cannot_leave(t)
	_test_nothing_walks_into_a_hard_blocker(t)
	_test_only_cars_go_over_the_bridge(t)

	_city.free()

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd:%d:%d" % [SEED, day])
	return rng

## Runs the crowd forward. Stepped by hand rather than by the tree, so a suite can cover a
## minute of traffic without waiting a minute — but a whole frame of it, separation pass
## included, because a crowd without one is not the crowd the game runs. See `Crowd.step`.
func _advance(seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		_city.crowd.step(STEP)

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
	var arterial := _floor_on(CrowdLanes.arterial_pavement(_city.map))
	var quiet := _floor_on(CrowdLanes.quietest_pavement(_city.map))

	t.check(arterial > Tuning.EXCITEMENT_DECAY_WALKING,
			"walking the arterial loses ground on average (%.1f vs %.1f decay)"
			% [arterial, Tuning.EXCITEMENT_DECAY_WALKING])
	# The other half of the same rule: the main road has to be expensive, not impassable, because
	# a street nobody can use is not a route decision.
	#
	# **Stated over the crossing now, not over the standing floor.** *(Playtest 13, finding 7.)*
	# It used to be `arterial < decay * 3`, and that is a proxy for the thing it cares about —
	# whether she can *get across* — measured by standing still on a street the design says to
	# cross. The two came apart the moment the spine got the traffic M41 always intended it to
	# have: the floor went over the ceiling while a crossing still cost about a sixth of the
	# meter. This is M35's lesson in the crowd's half of the game — **when a rule is about a
	# journey, state it over the walk and check it by walking.**
	# Hoisted, because it walks eight crossings with fifteen seconds of traffic between them and
	# calling it twice would put two minutes of simulation into a message string.
	#
	# Half the meter is where "not fatal" falls: a crossing that costs more than that can end a
	# day started in perfect health, and one that costs less always leaves her the room to get
	# back off the road and recover. It measures about 35 at act I density, so the spine is a
	# third of the meter to cross — which is a **soft block**, and is what finding 7 asked for in
	# its second half.
	var crossing := _crossing_the_main_road_costs()
	t.check(crossing < Tuning.METER_MAX / 2.0,
			"crossing the main road is expensive, not fatal (%.0f of %d)"
			% [crossing, Tuning.METER_MAX])
	t.check(quiet < Tuning.EXCITEMENT_DECAY_WALKING,
			"a back street is somewhere she can recover (%.1f vs %.1f decay)"
			% [quiet, Tuning.EXCITEMENT_DECAY_WALKING])
	t.check(arterial > quiet * 2.0,
			"the main road is not merely busier than a back street, it is a different place")

## The noise floor of a street, measured with the crowd **actually on it**.
##
## *(Playtest 13, and it is M44's lesson in the one test that pins the floor.)* This used to call
## `start_day(1, rng)` with no focus, which parks the field on the map centre — and then measured
## at `quietest_pavement`, which is whichever north-south corridor this city made quietest and is
##1968px from that centre on seed 4242. Measured: **zero agents within 400px**, so "a back street
## is somewhere she can recover" was 0.00 against a decay of 3.50 and "the arterial is a different
## place" was 7.58 against 0.00. Three of this test's four checks were passing against a street
## with nobody on it.
##
## The crowd is a population of the box around the player, so a floor is only a floor where she
## is standing. Focusing it is what makes the number mean anything: the same point reads 3.12
## rather than 0.00.
func _floor_on(at: Vector2) -> float:
	_city.crowd.start_day(1, _rng(1), at)
	return _mean_excitement(at, 60.0)

## What a kerb-to-kerb crossing of the main road actually costs her, worst of eight attempts.
##
## Walked rather than asserted, and the **worst** rather than the mean, because the rule is about
## whether the road is passable at all — a mean crossing that is cheap and a worst one that ends
## the day is a road she cannot use, and the mean would hide it. Fifteen seconds of traffic
## between attempts, so each crossing meets a different road rather than the same eight cars.
##
## The ground's own decay is netted off inside the loop: the spine is `EXCITEMENT_DECAY_MAIN_ROAD_
## MULTIPLIER` ground, so what she pays is what the crowd loads minus what that ground gives back,
## and pricing it against the flat walking decay would flatter it by a third.
func _crossing_the_main_road_costs() -> float:
	var corridor := _city.map.main_road
	var from_x := CrowdLanes.lane_centre(corridor, 0)
	var to_x := CrowdLanes.lane_centre(corridor, CrowdLanes.SIDEWALK_OFFSETS[-1])
	var start := Vector2(from_x, float(_city.map.size.y / 2) * Tuning.TILE_SIZE)
	_city.crowd.start_day(1, _rng(1), start)
	var worst := 0.0
	for attempt in 8:
		for i in int(round(15.0 / STEP)):
			_city.crowd.step(STEP)
		var walker := start
		var paid := 0.0
		var took := 0.0
		while walker.x < to_x and took < 12.0:
			walker.x += Tuning.WALK_SPEED * STEP
			_city.crowd.set_focus(walker)
			_city.crowd.step(STEP)
			paid += (_city.crowd.total_excitement_at(walker)
					- Tuning.EXCITEMENT_DECAY_WALKING * _city.decay_multiplier(walker)) * STEP
			took += STEP
		worst = maxf(worst, paid)
		_city.crowd.set_focus(start)
	return worst

## Mean crowd excitement at a point over `seconds` of traffic. A single instant says nothing
## — the whole character of a street is how often the next car comes.
func _mean_excitement(at: Vector2, seconds: float) -> float:
	var total := 0.0
	var samples := 0
	for i in int(round(seconds / STEP)):
		_city.crowd.step(STEP)
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
	var spacing := float(Tuning.TILE_SIZE) + CrowdLanes.SIDEWALK_LANE_SPREAD * 2.0
	t.check(Tuning.BUMP_RADIUS < spacing * 0.5,
			"there is a line between two pavement lanes with no contact on it (%.0f < %.0f)"
			% [Tuning.BUMP_RADIUS, spacing * 0.5])
	# **And it has to be wide enough to aim at.** *(M46, playtest 13 finding 1.)* The line is
	# `spacing - 2 * BUMP_RADIUS` across, and while the lanes sat on their tile centres that was
	# **four pixels** — something a player is occasionally on rather than something she can
	# choose — with 165 points of a hundred riding on it: measured over three seeds, forty seconds
	# down an arterial lane centre costs 15.3 contacts and the midline costs none.
	# `CrowdLanes.SIDEWALK_LANE_SPREAD` widens the *street* instead of narrowing the body, which is
	# the half of this that must not be traded away — `BUMP_RADIUS` is what makes a contact mean
	# walking into somebody.
	var clear_line := spacing - Tuning.BUMP_RADIUS * 2.0
	t.check(clear_line >= Tuning.PLAYER_BODY_RADIUS,
			"and it is wide enough to aim at rather than to land on (%.0fpx against a %.0fpx pram)"
			% [clear_line, Tuning.PLAYER_BODY_RADIUS])
	# The lanes it makes still have to be on the pavement. `CrowdAgent._pavement_band` measures the
	# footway from the **tile** centres rather than from the lanes, so a spread of half a tile would
	# put somebody in a shopfront or off a kerb and nothing else in the suite would object.
	t.check(CrowdLanes.SIDEWALK_LANE_SPREAD < float(Tuning.TILE_SIZE) * 0.5,
			"a spread lane is still on the footway (%.0f of a %d tile)"
			% [CrowdLanes.SIDEWALK_LANE_SPREAD, Tuning.TILE_SIZE])

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
##
## **Ordinary streets only, since M41.** A main road's zebras are kept by the light rather than by
## the drivers, which is the difference between the two kinds of street and is checked by
## `_test_a_main_road_is_kept_by_its_lights` below. A car on the spine driving straight past
## somebody at the kerb is this suite watching the design work.
func _test_traffic_gives_way_at_a_crossing(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	var tested := 0
	var extent := _city.map.world_size()
	for agent in _city.crowd.agents():
		if tested >= 3 or agent.kind != CrowdAgent.Kind.CAR:
			continue
		if _street_of(agent) != GameEnums.StreetKind.ORDINARY:
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
		# Measured to the **near edge of the paint**, which is what the car aims at, rather than to
		# the point the scan above happened to sample. A zebra is two tiles deep and the scan
		# starts far enough out to guarantee stopping room, so it can land on the far tile — which
		# made this read as a car stopping a hundred pixels short when it had stopped exactly
		# where it should. A test that measures a different thing from the code is a test that
		# fails when the map changes shape.
		t.check(_city.map.tile_type_at_world(agent.global_position)
				!= GameEnums.TileType.CROSSING, "and comes to rest off the paint, not on it")
		var gap := _distance_to_the_paint(agent)
		t.check(gap > 0.0 and gap < Tuning.CAR_STOP_LINE_SETBACK + Tuning.TILE_SIZE,
				"and stops *at* the line rather than wherever the braking ran out (%.0fpx)"
				% gap)

		agent.pedestrian_ahead = Vector2.INF
		_step(agent, 3.0)
		t.check(agent.speed() > Tuning.CAR_SPEED.x * 0.5,
				"and pulls away again once the crossing is clear")
	t.check(tested > 0, "at least one car had a zebra ahead of it to give way at")

## Distance from a car's centre to the near edge of the first zebra in front of it, walked tile by
## tile the way the car walks it. `INF` when there is none within sight.
func _distance_to_the_paint(agent: CrowdAgent) -> float:
	var forward := agent.heading()
	var step_tile := Vector2i(roundi(forward.x), roundi(forward.y))
	var here := _city.map.world_to_tile(agent.global_position)
	for step in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var tile := here + step_tile * step
		if _city.map.tile_at(tile) != GameEnums.TileType.CROSSING:
			continue
		var vertical := absf(forward.y) > 0.0
		var along: int = tile.y if vertical else tile.x
		var edge: int = along + (0 if (forward.y if vertical else forward.x) > 0.0 else 1)
		var at: float = agent.global_position.y if vertical else agent.global_position.x
		return (float(edge * Tuning.TILE_SIZE) - at) * (1.0 if (forward.y if vertical
				else forward.x) > 0.0 else -1.0)
	return INF

## What kind of street an agent is travelling down right now.
func _street_of(agent: CrowdAgent) -> GameEnums.StreetKind:
	return _city.map.street_kind_at(agent.travelling_vertically(),
			_city.map.world_to_tile(agent.global_position))

# ------------------------------------------------ the shape of the city (M41) ---
# Playtest 11, finding 7: *"we need a separation between easy-to-navigate road and heavily
# trafficked and pedestrianised road."* Three kinds of street where there was one, and the tests
# below are the ones that say the kinds are a **difference** rather than three names for the same
# street. None of them asserts a value; all of them assert what a kind promises.

## **A main road is kept by its lights, not by its drivers.** That is the whole content of the
## distinction: an ordinary crossing is a negotiation with somebody who can see you, and a
## signalled one is a wait with a known end. If traffic on the spine also gave way at the kerb,
## the signals would be scenery on top of a courtesy that was already sufficient.
func _test_a_main_road_is_kept_by_its_lights(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	# **Where the spine runs is a fact about this city, not a constant.** *(Playtest 14: "I have
	# the feeling the main road is now always left to home — it should move around more.")* It was
	# always the middle corridor, so this used to assert `main_road == arterial_index`, which is
	# the shape M46 found in `CrowdLanes.busyness`: a question about a city answered from a
	# constant. What is worth pinning is that it is somewhere a main road can *be*.
	var spine := _city.map.main_road
	var corridors := CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x)
	t.check(spine >= 3 and spine <= corridors - 4,
			"the spine leaves a city on both sides of it (corridor %d of %d)" % [spine, corridors])
	t.check(CrowdLanes.busyness(_city.map, true, spine) == CrowdLanes.ARTERIAL_BUSYNESS,
			"and the busiest street and the main road are the same street")
	t.check(_city.crowd.signals_for_tests().is_signalled(Vector2i(spine, 3)),
			"every junction on the spine is signalled")
	t.check(not _city.crowd.signals_for_tests().is_signalled(Vector2i(spine + 1, 3)),
			"and a junction of two ordinary streets is not")

	# A car on the spine, with somebody standing at the zebra it is coming to, does not slow for
	# them. It is stated over the car's own give-way probe rather than by walking one, because the
	# thing being asserted is that the probe never fires at all.
	#
	# **Focused on the spine to find one.** *(Playtest 14.)* The crowd is a population of the box
	# around her, and this used to open the day with no focus at all — which parks the box on the
	# middle of the map. That found cars on the spine only for as long as the spine *was* the
	# middle corridor; the day it started moving, there were none in the box to test. Same defect
	# M46 found in the floor test, in the test next door to it.
	_city.crowd.start_day(1, _rng(1), CrowdLanes.arterial_pavement(_city.map))
	var tested := 0
	for agent in _city.crowd.agents():
		if tested >= 2 or agent.kind != CrowdAgent.Kind.CAR:
			continue
		if _street_of(agent) != GameEnums.StreetKind.MAIN:
			continue
		var crossing := _crossing_ahead_of(agent)
		if crossing == Vector2.INF:
			continue
		tested += 1
		_city.crowd.set_focus(agent.global_position)
		agent.junction_hold = INF
		agent.pedestrian_ahead = crossing
		var cruising := agent.speed()
		_step(agent, 2.0)
		t.check(agent.speed() > cruising * 0.9,
				"a car on the spine does not give way to somebody at the kerb (%.0f to %.0f)"
				% [cruising, agent.speed()])
	t.check(tested > 0, "at least one car on the spine had a zebra ahead of it")

## The contract the light replaces the courtesy with. Stated over the **side** street's green,
## because that is what is running while the main road is stopped and she is on the paint.
func _test_a_signal_gives_her_time_to_cross(t) -> void:
	t.check(Tuning.validate_signals(), "the side street's green clears the carriageway fairly")
	t.check(Tuning.SIGNAL_SIDE_GREEN_SECONDS > Tuning.required_horn_time(),
			"a green is longer than the walk across it (%.2fs vs %.2fs)"
			% [Tuning.SIGNAL_SIDE_GREEN_SECONDS, Tuning.required_horn_time()])
	# The amber is a clearance period, so a car that has just committed has to be out of the box
	# before the crossing arm goes green. Slowest car, longest box.
	var box := Tuning.STREET_WIDTH * float(Tuning.TILE_SIZE) + Tuning.CAR_STRIKE_HALF_LENGTH * 2.0
	t.check(Tuning.SIGNAL_AMBER_SECONDS * Tuning.CAR_SPEED.x > box,
			"the amber clears the junction it is protecting (%.0fpx of %.0f)"
			% [Tuning.SIGNAL_AMBER_SECONDS * Tuning.CAR_SPEED.x, box])
	# And the wave. This used to assert that the cycle is an even multiple of the travelling time,
	# on the grounds that it "lets both directions progress" — which is the condition upside down
	# and was true of an arrangement that has never existed. *(M46.)* The property that is real is
	# behavioural, so it is walked rather than restated: a car holding the progression speed down
	# the spine **the way the wave runs** meets a green at every junction it comes to. The other
	# direction is at chance and cannot be rescued on this geometry — see
	# `Tuning.SIGNAL_PROGRESSION_BLOCKS`, which carries the derivation.
	var signals := _city.crowd.signals_for_tests()
	var was := signals.elapsed
	var travel := Tuning.signal_travel_seconds()
	var greens := 0
	var arrivals := 0
	for departure in 12:
		signals.elapsed = float(departure) / 12.0 * Tuning.signal_cycle_seconds()
		# Start where the wave has just turned green for this junction, which is what a car that
		# has already joined the platoon has done. Bounded rather than `while green_for(...)`,
		# because a suite that spins prints nothing at all and reads as a hang rather than a
		# failure — see `run_tests.gd`.
		for tick in int(Tuning.signal_cycle_seconds() / 0.01) + 1:
			if signals.green_for(Vector2i(_city.map.main_road, 8), true):
				break
			signals.elapsed += 0.01
		for hop in 6:
			signals.elapsed += travel
			arrivals += 1
			if signals.green_for(Vector2i(_city.map.main_road, 8 - hop - 1), true):
				greens += 1
	signals.elapsed = was
	t.check(greens == arrivals,
			"a car in the platoon never meets a red going the way the wave runs (%d of %d)"
			% [greens, arrivals])

## **A precinct has no cars in it.** Not few: none. The tile map alone cannot enforce it — a
## pedestrianised corridor is paved end to end, so every tile of it says "street" — so this is
## the check that the corridor kind is actually reaching the two places a car picks a road.
func _test_a_precinct_has_no_cars_in_it(t) -> void:
	# **Whichever axis this city put its inland precinct on.** *(Playtest 14.)* This used to require
	# a north-south one and stand in it, which was never a rule — one precinct is the shore, which
	# is always east-west, and the other is inland *on either axis*. Seed 4242 happened to roll a
	# vertical one for eleven milestones, and moving the main road (which draws from the same city
	# stream) rolled it the other way. A fixture that only exists on one seed is not a fixture.
	t.check(_city.map.precinct_spans.size() == 2, "there are exactly two precincts in all (%d)"
			% _city.map.precinct_spans.size())
	for span in _city.map.precinct_spans:
		t.check(span.w - span.z + 1 == Tuning.PRECINCT_BLOCKS,
				"a precinct is %d blocks long" % Tuning.PRECINCT_BLOCKS)
	var chosen: Vector4i = _city.map.precinct_spans[_city.map.precinct_spans.size() - 1]
	var vertical := chosen.x == 1

	# Built around one, so the field is looking at it rather than at the middle of the map.
	var along := (chosen.z + chosen.w) / 2 * CityMap.period() + Tuning.STREET_WIDTH
	var across := chosen.y * CityMap.period() + Tuning.STREET_WIDTH / 2
	var at := _city.map.tile_to_world(Vector2i(across, along) if vertical
			else Vector2i(along, across))
	_city.crowd.start_day(1, _rng(1), at)
	_advance(45.0)

	# **An intruder is a car on ground no axis lets it drive on, not a car whose tile is inside the
	# span.** *(Corrected under M51.)* A span covers the junctions between its blocks, and a car
	# crossing the precinct on a north-south street drives through those junctions perfectly
	# legally — sixteen of them do in this forty-five seconds, measured. Asking `street_kind_at`
	# about the *precinct's* axis calls every one of them an intruder, and the assertion only
	# passed because none of them happened to be inside a junction on the frame it sampled. A
	# change to the crowd's divert rule moved the timing by a few frames and one was, which is a
	# test that has been true by luck for eleven milestones failing for a reason that has nothing
	# to do with what it is about.
	var intruders := 0
	var walkers := 0
	for agent in _city.crowd.agents():
		var tile := _city.map.world_to_tile(agent.position)
		if not _city.map.in_bounds(tile):
			continue
		if _city.map.street_kind_at(vertical, tile) != GameEnums.StreetKind.PEDESTRIAN:
			continue
		if agent.kind != CrowdAgent.Kind.CAR:
			walkers += 1
		elif not _city.map.is_driveable_at(true, tile) \
				and not _city.map.is_driveable_at(false, tile):
			intruders += 1
	t.check(intruders == 0, "no car is standing where no street lets it drive (%d were)"
			% intruders)
	t.check(walkers > 0, "and the pavement it replaced the road with has people on it (%d)"
			% walkers)

## **Cars do not enter a junction they cannot leave.** *(Playtest 11, finding 7: "cars overlap on
## intersections — they should not go somewhere if they will run into another car.")*
##
## The M38 test above is about a *lane* and it passes either way, which is the whole reason this
## one had to be written separately: a lane is a queue and a junction is a **box**, and two cars
## on crossing arms can each have a clear lane ahead while both are about to be in the same box.
## Measured before the rule, over ninety seconds of the arterial: **3,776 overlapping
## crossing-axis pairs, one in half of all frames, the deepest 39px into a 40px footprint.**
##
## Stated as a rate rather than as zero, because the commit rule is deliberate: a car too close to
## stop carries on, which is the only safe thing it can do and is what makes a collision an
## accident rather than a routine outcome. What must not come back is the routine outcome.
func _test_cars_do_not_enter_a_junction_they_cannot_leave(t) -> void:
	var focus := CrowdLanes.arterial_pavement(_city.map)
	_city.crowd.start_day(1, _rng(1), focus)
	_city.crowd.set_focus(focus)
	var frames := 0
	var overlapping := 0
	for i in int(60.0 / STEP):
		_city.crowd.step(STEP)
		frames += 1
		var boxes := {}
		for agent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.CAR:
				continue
			var junction := agent.junction_occupied()
			if junction.x < 0:
				continue
			if not boxes.has(junction):
				boxes[junction] = [] as Array[CrowdAgent]
			boxes[junction].append(agent)
		for junction: Vector2i in boxes:
			var here: Array[CrowdAgent] = boxes[junction]
			for a in here.size():
				for b in range(a + 1, here.size()):
					if here[a].heading().dot(here[b].heading()) != 0.0:
						continue
					if here[a].global_position.distance_to(here[b].global_position) \
							<= Tuning.CAR_STRIKE_HALF_LENGTH + Tuning.CAR_STRIKE_HALF_WIDTH:
						overlapping += 1
	t.check(overlapping < frames / 20,
			"two cars are almost never inside each other in a junction (%d in %d frames)"
			% [overlapping, frames])

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

## The box holds the same amount of *city* wherever she stands, so the crowd does not bunch
## against the boundary wall. *(M46.)*
##
## `CrowdField.corridor_range` clamps to the city and the population does not clamp with it, so a
## box that is half wall put the same two hundred people on half the streets: measured before the
## fix, the corridor against the west wall showed 67 walkers on 54% of a screen of city — the same
## count as mid-map in half the ground — and read as 1.6x an ordinary middle corridor, beating the
## main road on two seeds of five.
##
## Two checks, because the mechanism and the thing the player feels are different statements and
## either could hold while the other fails. The first is the rule itself and is free. The second
## is short on purpose — five seconds of settling and five of counting, which is enough to
## separate a doubling and not enough to pin a value, and pinning a value is not what it is for.
func _test_the_crowd_does_not_bunch_against_the_wall(t) -> void:
	var field := _city.crowd.field()
	var extent := _city.map.world_size()
	var middle := extent * 0.5
	var corner := Vector2(Tuning.TILE_SIZE, Tuning.TILE_SIZE)
	var worst := 0.0
	for at in [middle, corner, Vector2(Tuning.TILE_SIZE, middle.y),
			Vector2(extent.x - Tuning.TILE_SIZE, middle.y)]:
		field.centre = at
		var across := minf(extent.x, at.x + field.radius) - maxf(0.0, at.x - field.radius)
		var down := minf(extent.y, at.y + field.radius) - maxf(0.0, at.y - field.radius)
		worst = maxf(worst, absf(across * down / pow(Tuning.CROWD_FIELD_RADIUS * 2.0, 2.0) - 1.0))
	t.check(worst < 0.02,
			"the box holds the same city at the wall as in the middle (worst %.0f%% out)"
			% [worst * 100.0])

	# Two ordinary corridors at the same height, one against the west wall and one three blocks
	# in. Not the middle of the map, which is the main road: the busiest pavement in the city is
	# the wrong yardstick for an ordinary one, in either direction.
	var open := _density_around(_pavement_beside(3))
	var walled := _density_around(_pavement_beside(0))
	t.check(walled < open * 1.5,
			"and a street beside the wall is not denser than one mid-map (%.0f vs %.0f walkers "
			% [walled, open] + "per screen of city)")

func _pavement_beside(corridor: int) -> Vector2:
	var x := corridor * CityMap.period() + Tuning.SIDEWALK_WIDTH - 1
	return _city.map.tile_to_world(Vector2i(x, _city.map.size.y / 2))

## Walkers on screen per *screen of city*, standing at a point. Normalised because half a screen
## against the boundary wall is half a screen of wall, and counting what is on it without saying
## so is how the bug being tested for got in.
func _density_around(at: Vector2) -> float:
	_city.crowd.start_day(1, _rng(1), at)
	_advance(10.0)
	var extent := _city.map.world_size()
	var visible := (minf(extent.x, at.x + 640.0) - maxf(0.0, at.x - 640.0)) \
			* (minf(extent.y, at.y + 360.0) - maxf(0.0, at.y - 360.0))
	var walkers := 0.0
	var samples := 0
	for i in int(round(10.0 / STEP)):
		_city.crowd.step(STEP)
		samples += 1
		for agent in _city.crowd.agents():
			if agent.kind != CrowdAgent.Kind.WALKER:
				continue
			var away: Vector2 = agent.global_position - at
			if absf(away.x) <= 640.0 and absf(away.y) <= 360.0:
				walkers += 1.0
	return walkers / float(maxi(1, samples)) * (1280.0 * 720.0) / maxf(1.0, visible)

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

## **The index is thrown away once a frame, and something has to be doing the throwing.**
##
## `TrafficIndex.claim()` is written to outlive the frame it was made in and no longer — the next
## rebuild replaces the lot — so nothing in it bounds its own growth. A rig that walks the agents
## without running the separation pass therefore leaves every recycle in a lane that never empties:
## sixty-five thousand entries after three thousand frames of the arterial, with `_recycle` scanning
## all of them six times over. That was **240 of the suite's 495 seconds**, spent inside a single
## test, and nothing could say so — a lane full of cars that left an hour ago is still a legal lane,
## and every assertion about the traffic passed the whole time.
##
## Stated as the exact car count rather than as a bound, because there is an exact answer: the
## rebuild buckets every car once and claims are gone by then.
func _test_the_traffic_index_is_emptied_every_frame(t) -> void:
	_city.crowd.start_day(1, _rng(1))
	# Long enough that plenty of cars have left the field and come back, which is what claims a
	# place in a lane. The growth is visible within a frame or two of the first recycle, so this
	# does not need the minute the tests either side of it do.
	_advance(10.0)
	t.check(_city.crowd.traffic().entry_count() == Tuning.crowd_cars(1),
			"ten seconds on, the index holds one entry per car rather than a day's worth (%d of %d)"
			% [_city.crowd.traffic().entry_count(), Tuning.crowd_cars(1)])

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
## Since M41 it returns the tile that **begins** a run of paint, not any tile of one. A car stops
## short of the whole zebra, and a zebra is two tiles on an ordinary street and six where a road
## crosses a pedestrianised one — so a person standing on the far tile of a deep one is somebody
## the car legitimately cannot stop for, which read as the give-way being broken.
func _crossing_ahead_of(agent: CrowdAgent) -> Vector2:
	var forward := agent.heading()
	var floor_px := Tuning.braking_distance(Tuning.CAR_SPEED.y) + Tuning.CAR_STOP_LINE_SETBACK
	var first := ceili((floor_px + Tuning.TILE_SIZE) / float(Tuning.TILE_SIZE))
	var was_paint := false
	for step in range(0, ceili(Tuning.CAR_ZEBRA_SIGHT / float(Tuning.TILE_SIZE)) + 1):
		var at := agent.global_position + forward * float(step * Tuning.TILE_SIZE)
		var paint := _city.map.tile_type_at_world(at) == GameEnums.TileType.CROSSING
		if paint and not was_paint and step >= first:
			return at
		was_paint = paint
	return Vector2.INF

## How far a point is in front of an agent, along the street it is on. Negative once the agent
## has gone past it.
func _distance_along(agent: CrowdAgent, point: Vector2) -> float:
	return agent.heading().dot(point - agent.global_position)

## A grid where every street is equally loud is a grid with nothing to choose between. The
## arterial has to be the loud one, and it has to be the *same* one every morning.
func _test_the_arterial_is_the_busiest_street(t) -> void:
	var arterial := _city.map.main_road
	var busiest := CrowdLanes.busyness(_city.map, true, arterial)
	for index in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.x):
		if index == arterial:
			continue
		t.check(CrowdLanes.busyness(_city.map, true, index) < busiest,
				"corridor %d is quieter than the arterial" % index)
	t.check(CrowdLanes.busyness(_city.map, true, arterial)
			== CrowdLanes.busyness(_city.map, true, arterial),
			"a street's character is stable, not rolled afresh on every question")
	# And there is exactly **one** of it. *(Playtest 13, finding 7.)* `busyness` used to answer
	# `index == arterial_index(blocks)` with `blocks` taken from whichever axis it was asked
	# about, so the middle corridor of the east-west axis was weighted as an arterial too —
	# M41 abolished the second main road everywhere except here, and the phantom held more cars
	# than the real one. A hierarchy is only a hierarchy if there is one of the top thing.
	for index in CrowdLanes.corridor_count(Tuning.CITY_BLOCKS.y):
		t.check(CrowdLanes.busyness(_city.map, false, index) < CrowdLanes.ARTERIAL_BUSYNESS,
				"east-west corridor %d is an ordinary street, not a second spine" % index)

## **Nothing walks into a cul-de-sac's wall.** *(Playtest 15, finding 1: "cars and people go
## through cul-de-sacs".)*
##
## The crowd is the one thing in the game that travels the lattice without consulting
## `blocked_segments()`, and it did not need to: a dead end is one street with its far end **built
## over**, so the tiles say so. What it did need was to *look* at them. The avoidance was a single
## probe fired seven tiles ahead, which answers "is there something coming up" and looks straight
## past a two-tile wall into the open road behind it — so an agent that entered the street from the
## junction beside the wall never saw it and walked into the building.
##
## Measured before the fix, over forty seconds at a dead end: **eight agents inside a wall at once,
## and something in one on 87% of frames** across three seeds. Zero after.
##
## The field is built **at a dead end** rather than at the doorstep, and that is the whole reason
## this test can see anything: the crowd is a population of the box around the player, so a wall
## the box never contains is a wall nothing was ever going to reach. The first version of this
## probe stood at the front door and reported a clean bill of health on a build that was visibly
## broken.
func _test_nothing_walks_into_a_hard_blocker(t) -> void:
	var walls := {}
	for key: Vector3i in _city.map.built_over:
		var rect: Rect2i = _city.map.built_over[key]
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				walls[Vector2i(x, y)] = true
	t.check(not walls.is_empty(), "this city has hard blockers to walk into (%d dead ends)"
			% _city.map.dead_ends.size())

	var at := _city.map.doorstep_world_position()
	for key: Vector3i in _city.map.dead_ends:
		var segment := StreetNetwork.by_key(key)
		at = _city.map.tile_rect_to_world(segment.tile_rect()).get_center()
		break
	_city.crowd.start_day(1, _rng(1), at)
	_city.crowd.set_focus(at)

	var frames_with_one := 0
	var worst := 0
	var frames := int(round(40.0 / STEP))
	for frame in frames:
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		var inside := 0
		for agent in _city.crowd.agents():
			if walls.has(_city.map.world_to_tile(agent.position)):
				inside += 1
		frames_with_one += 1 if inside > 0 else 0
		worst = maxi(worst, inside)
	t.check(frames_with_one == 0,
			"nobody is standing inside a hard blocker (%d frames of %d, worst %d at once)"
			% [frames_with_one, frames, worst])

## M53: **the overrun permission was narrowed to a car on the spine, and the lane was not** — the
## entry-side fallback (`CrowdAgent._keep_within_the_room_beyond_the_map`) used to hand every kind
## the same `ENTRY_SPREAD` reach past the true edge, so a walker whose six recycle rolls all missed
## could appear already standing on the bridge. The bridge is not made safe by this: a car on the
## spine still overruns the map by `Tuning.OUT_OF_SIGHT`, which is the whole of how it looks like it
## drives across rather than stopping dead at the kerb.
func _test_only_cars_go_over_the_bridge(t) -> void:
	var spine_x := (_city.map.main_road * CityMap.period() + Tuning.STREET_WIDTH * 0.5) \
			* float(Tuning.TILE_SIZE)
	var limit := _city.map.world_size().y
	var at := Vector2(spine_x, limit - Tuning.TILE_SIZE)
	_city.crowd.start_day(1, _rng(1), at)

	var worst_walker := 0.0
	var worst_car := 0.0
	for frame in int(round(30.0 / STEP)):
		_city.crowd.set_focus(at)
		_city.crowd.step(STEP)
		for agent in _city.crowd.agents():
			var overrun: float = agent.position.y - limit
			if agent.kind == CrowdAgent.Kind.WALKER:
				worst_walker = maxf(worst_walker, overrun)
			else:
				worst_car = maxf(worst_car, overrun)

	t.check(worst_walker <= Tuning.TILE_SIZE + 1.0,
			"no walker overruns the map's south edge by more than a tile (worst %.0fpx)"
			% worst_walker)
	t.check(worst_car > Tuning.TILE_SIZE * 2.0,
			"and a car on the spine still overruns it — the bridge is not made safe (worst %.0fpx)"
			% worst_car)
