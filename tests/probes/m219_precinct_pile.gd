extends RefCounted
## Walkers standing at a blockage made of partial bodies in neighbouring rows of a precinct. Printed,
## not asserted; not a suite, run by name:
##
##     tools/test.sh probes/m219_precinct_pile.gd
##
## Boots seed 67 day 3 and seed 24757 day 5 the way `main.gd` boots a day, puts the crowd's focus on
## the tile the blockage stands at ((10,156) and (122,156)), and for thirty seconds counts the
## walkers within a tile and a half of it: the most at once and the mean per frame.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0
const CASES := [[67, 3, Vector2i(10, 156)], [24757, 5, Vector2i(122, 156)]]

func run(t) -> void:
	for case: Array in CASES:
		var seed_value: int = case[0]
		var day: int = case[1]
		GameState.start_run(seed_value)
		GameState.header.day = day
		var map := CityGenerator.generate(seed_value)
		var city: City = RunCity.of_the_run(CITY_SCENE)
		t.add_child(city)
		city.build(map)
		GameState.attempt_spend.city_state.begin_day(map.block_plans, day)
		city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"))
		var doorstep := map.doorstep_world_position()
		city.events.start_day(DaySpec.for_day(day), GameState.calendar.day_rng(), GameState.attempt_spend.consumed_one_shots, doorstep)
		var at := map.tile_to_world(case[2])
		city.events.stream_around(at)
		city.crowd.start_day(day, GameState.calendar.day_rng(day, "crowd"), at)
		city.crowd.set_gates(city.region_plan().gates)
		var most := 0
		var total := 0
		var frames := int(round(30.0 / STEP))
		for frame in frames:
			city.crowd.set_focus(at)
			city.crowd.step(STEP)
			var near := 0
			for agent in city.crowd.agents():
				if agent.kind == CrowdAgent.Kind.WALKER \
						and agent.position.distance_to(at) < 1.5 * Tuning.TILE_SIZE:
					near += 1
			most = maxi(most, near)
			total += near
		print("M219 seed %d day %d at %s: most at once %d, mean %.2f"
				% [seed_value, day, case[2], most, float(total) / frames])
		city.free()
	t.check(true, "m219_precinct_pile probe ran")
