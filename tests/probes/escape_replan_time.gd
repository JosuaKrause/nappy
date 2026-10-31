extends RefCounted
## Measurement probe for what the escape's plan costs on a restart of the city section, which
## replans on the same city (`main._plan_the_finale_city()`): per seed, the escape plan's
## wall time on the city's first plan and on three restarts after it, each with the same rng the
## game hands it. Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_replan_time.gd      (prints ESCAPE_REPLAN lines)

const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024]
const RESTARTS := 3

func run(t) -> void:
	var firsts: Array[int] = []
	var restarts: Array[int] = []
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.attempt_spend.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.attempt_spend.city_state)
		var took: Array[int] = []
		var placed: Array[int] = []
		for attempt in RESTARTS + 1:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var started := Time.get_ticks_msec()
			var placements := DayPlanner.plan_the_escape_city(map, FinalePlanner.route(map), rng,
					_city_spec())
			took.append(Time.get_ticks_msec() - started)
			placed.append(placements.size())
		firsts.append(took[0])
		restarts.append_array(took.slice(1))
		print("ESCAPE_REPLAN seed %5d | first %d ms | restarts %s ms | placements %s"
				% [seed_value, took[0], took.slice(1), placed])
	firsts.sort()
	restarts.sort()
	print("ESCAPE_REPLAN | %d seeds | first %d-%d ms, median %d | restarts %d-%d ms, median %d"
			% [SEEDS.size(), firsts[0], firsts[-1], firsts[firsts.size() / 2], restarts[0],
			restarts[-1], restarts[restarts.size() / 2]])
	t.check(true, "a probe asserts nothing")

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
