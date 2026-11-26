extends RefCounted
## Measurement probe for grassy-beaver's park signs at junctions (a day one that teaches): over the
## tutorial route probe's seeds, how many cities stand a sign at the route's first junction, how
## many a second at the doorstep street's other end, how many none because the tutorial park does
## not stay calm all run, and how many have no tutorial route at all; and for each sign, which way
## it points against the arm she arrives along (a turn, or straight on).
##
## Not a suite: it prints rather than asserts.
## Run by name:
##
##     tools/test.sh probes/grassy_beaver_park_signs.gd   (prints PARK_SIGNS lines)

const Routes := preload("res://tests/probes/grassy_beaver_tutorial_routes.gd")

func run(t: TestRunner) -> void:
	var counts := {"cities": 0, "no route": 0, "park not calm all run": 0, "no corner": 0,
		"one sign": 0, "two signs": 0, "first turns": 0, "first straight on": 0}
	for seed_value in Routes._seeds():
		var map := CityGenerator.generate(seed_value)
		var state := CityState.new()
		state.begin_day(map.plans_by_block(), 1)
		map.repaint(state)
		counts["cities"] += 1
		var route := TutorialRoute.for_city(map)
		if route == null:
			counts["no route"] += 1
			continue
		var plan := map.plan_of(route.park_block())
		if not plan.stays_calm():
			counts["park not calm all run"] += 1
			var arc: Array[String] = []
			for step in plan.steps_in_order():
				arc.append("%s from %d" % [GameEnums.BlockPurpose.keys()[step.becomes()],
						step.earliest_day()])
			print("PARK_SIGNS seed %d: no sign, the park's arc %s%s" % [seed_value,
					" then ".join(arc), " (the swing park)" if plan.is_swing_park() else ""])
			continue
		var signs := ParkSigns.for_route(map, route).signs()
		if signs.is_empty():
			counts["no corner"] += 1
			continue
		counts["one sign" if signs.size() == 1 else "two signs"] += 1
		var toward_home := route.doorstep_street().other_end(route.turning_junction()) \
				- route.turning_junction()
		var first := signs[0]
		counts["first turns" if first.points().x * toward_home.x + first.points().y * toward_home.y == 0
				else "first straight on"] += 1
		print("PARK_SIGNS seed %d: %s" % [seed_value, ", ".join(signs.map(
				func(placed: ParkSigns.Sign) -> String:
					return "%s points %s from %s" % [placed.junction(), placed.points(),
							placed.tile()]))])
	print("PARK_SIGNS totals: %s" % [counts])
	t.check(true, "a probe asserts nothing")
