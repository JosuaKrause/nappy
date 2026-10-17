extends RefCounted
## Measurement probe for the basement's cost (inbox #765): from an empty meter, awake and asleep,
## what walking the corridor past its three vents does to the meter, over many arrival phases.
## Not a suite: it prints rather than asserts. Run by name:
##
##     tools/test.sh probes/basement_meter.gd      (prints BASEMENT lines)
##
## The rig is `tests/basement_walk_rig.gd`; `tests/test_interior.gd` pins what this prints.
## A case is a set of vents that held her. For each arrival phase every start delay is walked and
## the walks are sorted by which vents held them: "straight" is the walk with no delay at all, and
## every other case is the best (lowest peak) walk of its set over the delays, with the worst
## (highest peak) of that set alongside.

const Rig := preload("res://tests/basement_walk_rig.gd")
const PHASES := 22
const SPACING := 8.3
const DELAYS := 25
const DELAY_STEP := 0.5

func run(t) -> void:
	var rig := Rig.new(t)
	for asleep in [false, true]:
		var straight: Array = []
		var best := {}
		var worst := {}
		var phases_with := {}
		for i in PHASES:
			var seen := {}
			for d in DELAYS:
				var r: Dictionary = rig.walk(float(i) * SPACING, float(d) * DELAY_STEP, asleep)
				if d == 0:
					straight.append(r)
				var key := str(r["held"])
				if not best.has(key) or r["peak"] < best[key]["lo"]:
					best[key] = best.get(key, {"lo": 1000.0, "hi": 0.0, "lost_all": true})
					best[key]["lo"] = r["peak"]
				best[key]["hi"] = maxf(best[key]["hi"], r["peak"])
				best[key]["lost_all"] = best[key]["lost_all"] and r["lost"]
				seen[key] = true
			for key in seen:
				phases_with[key] = phases_with.get(key, 0) + 1
		var lost := 0
		var mean := 0.0
		var lo := 1000.0
		for r in straight:
			lost += 1 if r["lost"] else 0
			mean += r["peak"] / float(PHASES)
			lo = minf(lo, r["peak"])
		var held_none := 0
		for r in straight:
			held_none += 1 if r["held"].is_empty() else 0
		var tag := "asleep" if asleep else "awake "
		print("BASEMENT %s | straight, no delay | peak mean %5.1f min %5.1f | lost %2d of %d | never held %d"
				% [tag, mean, lo, lost, PHASES, held_none])
		var keys := best.keys()
		keys.sort()
		for key in keys:
			print("BASEMENT %s | held %-10s | in %2d of %d phases | best peak %5.1f worst peak %5.1f%s"
					% [tag, key, phases_with[key], PHASES, best[key]["lo"], best[key]["hi"],
					" (all lost)" if best[key]["lost_all"] else ""])
	rig.free_rig()
