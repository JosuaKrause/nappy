extends RefCounted
## How much of the city carries street trees, over a seed sweep — the measurement
## `Tuning.STREET_TREE_RUNS` is set from. Prints the fraction of ordinary streets that are
## tree-lined, the runs actually placed, and how many pits a run carries.
##
## Run it with `tools/test.sh probes/m115_tree_rarity.gd`.

const SEEDS := 30
const BASE_SEED := 505050

func run(t) -> void:
	var total_ordinary := 0
	var total_lined := 0
	var total_runs := 0
	var total_pits := 0
	var worst := 0.0
	var short_runs := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 13)
		var ordinary := 0
		for segment in StreetNetwork.segments():
			if not map.has_street(segment.key()):
				continue
			if StreetTrees._street_kind_of(map, segment) != GameEnums.StreetKind.ORDINARY:
				continue
			ordinary += 1
		var lined := StreetTrees.segment_keys_with_trees(map).size()
		var runs := StreetTrees.runs(map)
		var pits := StreetTrees.planted(map).size()
		if runs.size() < Tuning.STREET_TREE_RUNS:
			short_runs += 1
		total_ordinary += ordinary
		total_lined += lined
		total_runs += runs.size()
		total_pits += pits
		worst = maxf(worst, float(lined) / float(maxi(1, ordinary)))
		print("seed %d: %d ordinary streets, %d tree-lined (%.1f%%), %d runs, %d pits"
				% [map.seed_used, ordinary, lined, 100.0 * lined / maxf(1.0, ordinary),
				runs.size(), pits])
	print("MEAN tree-lined fraction %.3f (worst seed %.3f), mean %.1f runs, mean %.1f pits, %d seeds short of the run count"
			% [float(total_lined) / float(total_ordinary), worst,
			float(total_runs) / SEEDS, float(total_pits) / SEEDS, short_runs])
	t.check(true, "measured")
