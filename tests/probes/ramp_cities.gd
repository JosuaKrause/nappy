extends RefCounted
## Measurement probe: `tests/test_events_costs.gd`'s ramp check (non-ambient rows
## placed on day 14 against day 1, its bar a fifth more) planned the same way, `GameDawn` on a fresh
## city with the suite's rng formula on the city's seed, on the suite's city (4242) and nine others.
## Run with `tools/test.sh probes/ramp_cities.gd`. Prints
## `RAMP city <seed> day1 <placed> day14 <placed> ratio <day 14 over day 1>`.

const CITIES: Array[int] = [4242, 77, 1301, 90210, 90241, 90272, 90303, 90334, 2024, 31337]

func run(t: TestRunner) -> void:
	for city_seed: int in CITIES:
		var map := CityGenerator.generate(city_seed)
		var sites := MastSites.compute(map)
		var counts: Array[int] = []
		for day: int in [1, 14]:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d:%d" % [city_seed, day])
			var consumed: Array[String] = []
			var dawn: DawnContext = GameDawn.of(DaySpec.for_day(day), rng, map).masts(sites) \
					.spent(consumed).planned()
			var n := 0
			for plan in dawn.events().placements():
				if plan.def.kind != GameEnums.EventKind.AMBIENT and plan.is_placed():
					n += 1
			counts.append(n)
		print("RAMP city %d day1 %d day14 %d ratio %.2f" % [city_seed, counts[0], counts[1],
				float(counts[1]) / float(counts[0])])
	t.check(true, "printed")
