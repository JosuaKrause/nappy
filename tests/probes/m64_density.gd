extends RefCounted
## Measurement probe for "the city feels way empty now", read as the player meant it: **nothing on
## the street she is walking down.** Not a suite: it prints rather than asserting, so it lives here
## under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m64_density.gd
##
## The first probe counted placements per depth band and concluded the corridor was the densest
## ground in the city. That was counting without dividing. A band's total says nothing about what a
## street in it looks like unless you know how many streets the band has — and the day's corridor
## turns out to be a large share of the whole lattice, so its total is spread very thin.
##
## So this asks the only question the complaint is actually about: **walking down one street on the
## corridor, how many events are on it?**

const SEEDS := 8
const SAMPLE_DAYS := [1, 5, 8, 11, 14]

func run(t) -> void:
	_events_per_street_by_band()
	t.check(true, "zz_m64_density probe ran")

func _events_per_street_by_band() -> void:
	print("\n== streets and events per band, %d seeds x days %s ==" % [SEEDS, SAMPLE_DAYS])
	var lattice := StreetNetwork.segments().size()
	# depth bucket 0 = on the tree, 1 = rim, 2 = everything further out.
	var streets := [0, 0, 0]
	var events := [0, 0, 0]
	var friction := [0, 0, 0]
	var days := 0
	var placed_total := 0
	var on_street_total := 0

	for i in SEEDS:
		var map := CityGenerator.generate(90210 + i * 31)
		for day in SAMPLE_DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var corridor := Corridor.of(tree)
			days += 1

			# How much ground each band actually has, counted in streets — the denominator the
			# first probe never took.
			var depths := tree.segment_depths()
			var seen := {}
			for key: Vector3i in depths:
				seen[key] = true
				streets[mini(int(depths[key]), 2)] += 1
			# A street the tree never reached is as far out as this counts.
			for segment in StreetNetwork.segments():
				if not seen.has(segment.key()):
					streets[2] += 1

			var rng := RandomNumberGenerator.new()
			rng.seed = hash("zz_m64d:%d:%d" % [map.seed_used, day])
			var consumed: Array[String] = []
			for plan in EventScheduler.build_day(day, rng, map, consumed, [], [], tree):
				if not plan.is_placed():
					continue
				placed_total += 1
				var tile := map.world_to_tile(plan.position)
				# Only a thing standing on a street can be met by somebody walking down it.
				if not StreetNetwork.segment_containing(tile):
					continue
				on_street_total += 1
				var band := mini(corridor.depth(tile), 2)
				events[band] += 1
				if plan.role == GameEnums.BlockerRole.FRICTION:
					friction[band] += 1

	var d := maxf(1.0, float(days))
	print("lattice streets: %d" % lattice)
	print("placed per day: %.1f, of which standing on a street: %.1f"
			% [placed_total / d, on_street_total / d])
	print("")
	print("  band        streets/day   events/day   events per street   friction per street")
	var names := ["on the tree", "the rim", "further out"]
	for band in range(3):
		var s: float = streets[band] / d
		var e: float = events[band] / d
		var f: float = friction[band] / d
		print("  %-12s %8.1f %12.1f %17.2f %20.2f"
				% [names[band], s, e, (e / s if s > 0.0 else 0.0), (f / s if s > 0.0 else 0.0)])
	var all_streets: float = (streets[0] + streets[1] + streets[2]) / d
	var all_events := on_street_total / d
	print("  %-12s %8.1f %12.1f %17.2f" % ["whole city", all_streets, all_events,
			(all_events / all_streets if all_streets > 0.0 else 0.0)])
	print("")
	print("share of the lattice the day's own corridor covers: %.1f%%"
			% (100.0 * (streets[0] / d) / float(lattice)))
