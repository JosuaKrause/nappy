extends RefCounted
## Measurement probe for the escape's roadblocks (inbox #771 in minty-lemur): how many the finale's plan stands,
## and how near the nearest two stand, on any two streets. Not a suite: it prints rather than
## asserts. Run by name:
##
##     tools/test.sh probes/escape_roadblock_spacing.gd      (prints ESCAPE_SPACING lines)
##
## The plan is `FinalePlanner.plan()` on seeds 1 to 40, built the way `tests/test_finale.gd` builds
## it, and each band stands where `EventScheduler._stands_at()` puts it, which is where its guard
## notices her from. "Under" counts the pairs nearer than the two guards' notices together
## (`pursues_within` each), the ground on which both can come for her at once.

const SEEDS := 40

func run(t) -> void:
	var total := 0
	var pairs := 0
	var under := 0
	var nearest_of_all := INF
	for seed_value in range(1, SEEDS + 1):
		var map := CityGenerator.generate(seed_value)
		GameState.city_state.begin_day(map.block_plans, 1)
		map.repaint(GameState.city_state)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var plan := FinalePlanner.plan(map, rng, _city_spec())
		var bands: Array[EventScheduler.Planned] = []
		for placement in plan.placements:
			if placement.def.id == "roadblock":
				bands.append(placement)
		var nearest := INF
		var nearest_pair := ""
		for i in bands.size():
			for j in range(i + 1, bands.size()):
				var gap := EventScheduler._stands_at(map, bands[i]).distance_to(
						EventScheduler._stands_at(map, bands[j]))
				pairs += 1
				if gap < bands[i].def.pursues_within + bands[j].def.pursues_within:
					under += 1
				if gap < nearest:
					nearest = gap
					nearest_pair = "%s %s" % [map.world_to_tile(bands[i].position),
							map.world_to_tile(bands[j].position)]
		total += bands.size()
		nearest_of_all = minf(nearest_of_all, nearest)
		print("ESCAPE_SPACING seed %2d | %2d roadblocks | nearest two %.0fpx apart, %s"
				% [seed_value, bands.size(), nearest, nearest_pair])
	print("ESCAPE_SPACING | %d seeds | %d roadblocks | %d pairs, %d nearer than their two notices | nearest %.0fpx"
			% [SEEDS, total, pairs, under, nearest_of_all])
	t.check(true, "a probe asserts nothing")

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, Tuning.FINALE_LENGTH_SECONDS)
