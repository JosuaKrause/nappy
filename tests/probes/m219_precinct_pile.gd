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

func run(t: TestRunner) -> void:
	for case: Array in CASES:
		var seed_value: int = case[0]
		var day: int = case[1]
		var map := CityGenerator.generate(seed_value)
		var city: City = RunCity.with_own_run(CITY_SCENE, seed_value)
		city.run.header().set_day(day)
		t.add_child(city)
		RunCity.build(city, map)
		city.run.attempt_spend().block_arcs().begin_day(map.plans_by_block(), day)
		city.start_day(city.run.attempt_spend().block_arcs(), day, city.run.calendar().day_rng(day, "closures"))
		var doorstep := map.doorstep_world_position()
		RunCity.events(city).start_day(DaySpec.for_day(day), city.run.calendar().day_rng(), city.run.attempt_spend().consumed_one_shots(), doorstep)
		var at := map.tile_to_world(case[2])
		RunCity.events(city).stream_around(at)
		RunCity.crowd(city).start_day(day, city.run.calendar().day_rng(day, "crowd"), at)
		RunCity.crowd(city).set_gates(city.streets().region_plan().gate_states())
		var most := 0
		var total := 0
		var frames := int(round(30.0 / STEP))
		RunCity.crowd(city).use_focus(FakeCrowdFocus.new(at))
		for frame in frames:
			RunCity.crowd(city).step(STEP)
			var near := 0
			for agent in RunCity.crowd(city).agents():
				if agent.lane().kind() == CrowdAgent.Kind.WALKER \
						and agent.position.distance_to(at) < 1.5 * Tuning.TILE_SIZE:
					near += 1
			most = maxi(most, near)
			total += near
		print("M219 seed %d day %d at %s: most at once %d, mean %.2f"
				% [seed_value, day, case[2], most, float(total) / frames])
		city.free()
	t.check(true, "m219_precinct_pile probe ran")
