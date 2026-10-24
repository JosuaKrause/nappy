extends RefCounted
## Measurement probe for the escape's density (inbox #785 in minty-lemur): how many of each of its own rows the
## finale's plan stands, and which row its alley-mouth walls are, per seed. Not a suite: it prints
## rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_density.gd      (prints ESCAPE_DENSITY lines)
##
## The plan is `FinalePlanner.plan()` built the way `tests/test_finale.gd` builds it, on the seeds
## below; "streets" is how many open streets the chains walk.

const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808]
const ROWS: Array[String] = ["military_convoy", "abduction", "roadblock", "finale_explosion"]

func run(t) -> void:
	var totals := {}
	for seed_value in SEEDS:
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var started := Time.get_ticks_msec()
		var plan := FinalePlanner.plan(map, rng, _city_spec())
		var took := Time.get_ticks_msec() - started
		var counts := {}
		for placement in plan.placements:
			counts[placement.def.id] = int(counts.get(placement.def.id, 0)) + 1
		var parts: Array[String] = []
		for id in ROWS:
			parts.append("%s %d" % [id, int(counts.get(id, 0))])
			totals[id] = int(totals.get(id, 0)) + int(counts.get(id, 0))
		totals["streets"] = int(totals.get("streets", 0)) + plan.open_streets.size()
		print("ESCAPE_DENSITY seed %5d | %d streets | %s | alley walls: %s | planned in %d ms"
				% [seed_value, plan.open_streets.size(), ", ".join(parts),
				SealPlanner._alley_mouth_def(SealPlanner.escape_candidates(), DaySpec.CITY_DAY),
				took])
	var parts: Array[String] = []
	for id in ROWS:
		parts.append("%s %d" % [id, int(totals.get(id, 0))])
	print("ESCAPE_DENSITY | %d seeds | %d streets | %s" % [SEEDS.size(),
			int(totals.get("streets", 0)), ", ".join(parts)])
	t.check(true, "a probe asserts nothing")

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
