extends RefCounted
## Measurement probe for the escape's roadblocks (inbox #771 in minty-lemur): what walking past the roadblocks on
## one of the escape's streets costs the meter with their guards at their post, what luring the
## guard on her side off costs, and what walking on past costs once he has gone. Not a suite: it
## prints rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_roadblock_cost.gd      (prints ESCAPE_ROADBLOCK lines)
##
## The rig is `tests/escape_roadblock_rig.gd`; `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`) pins what this prints.
## Every crossing is walked in both directions, twice: from 0 asleep, which is what every attempt
## at the city section starts on (`DayDirector.start()`: `Baby.reset()` then `force_sleep()`, as the section's spec starts her asleep),
## and from `Tuning.EXCITEMENT_WAKE_THRESHOLD` awake, the baby a bang earlier on
## the walk has just woken. Three walks each:
##
## - **posted**: straight past at a walk, the guards at their posts, round the first corner once a
##   charge is under way. Ends at a catch; a walk that turned no corner prints how far past the band
##   along her line he caught her.
## - **lure**: in at a walk until a guard's hand goes up, standing until he charges, then turned and
##   run straight back 0.3s later at `Tuning.ACCELERATION` until every charge has given up, then
##   standing until each guard who charged has left his post for good. Prints the nearest a charging
##   guard came to her.
## - **after**: on from where the lure left her, at a walk, past the band to the far end. A guard
##   who charges now is one the lure did not take off.

const Rig := preload("res://tests/escape_roadblock_rig.gd")
const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024]

func run(t: TestRunner) -> void:
	for awake: bool in [false, true]:
		_measure(t, awake)

func _measure(t: TestRunner, awake: bool) -> void:
	var start := Tuning.EXCITEMENT_WAKE_THRESHOLD if awake else 0.0
	var tag := "awake %2.0f" % start if awake else "asleep 0"
	var posted_walks: Array[Dictionary] = []
	var lure_walks: Array[Dictionary] = []
	var after_walks: Array[Dictionary] = []
	var tally := {"posted": posted_walks, "lure": lure_walks, "after": after_walks}
	var bands: Array[int] = []
	for seed_value in SEEDS:
		var built := Rig.plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventPlan] = built["placements"]
		for street: Array in Rig.roadblock_streets(map, plan, placements):
			var segment: StreetNetwork.Segment = street[0]
			var group: Array[EventPlan] = []
			group.assign(street[1])
			var line := Rig.her_line(t, map, segment, group)
			if line.is_empty():
				print("ESCAPE_ROADBLOCK %s seed %d street %s: no open line" % [tag, seed_value,
						segment.key()])
				continue
			bands.append(group.size())
			for forward: bool in [true, false]:
				var from: Vector2 = line[0] if forward else line[1]
				var to: Vector2 = line[1] if forward else line[0]
				var posted := Rig.walk(t, map, group, from, to, Rig.Meter.new(start, not awake))
				posted["past"] = _past_the_bands(group, from, to, posted["at"])
				var lured := Rig.lure(t, map, group, from, to, Rig.Meter.new(start, not awake))
				var lure: Dictionary = lured["lure"]
				var after: Dictionary = lured["after"]
				print("ESCAPE_ROADBLOCK %s seed %5d street %s %d band(s) %s | posted: %s | lure: %s | after: %s"
						% [tag, seed_value, segment.key(), group.size(), "->" if forward else "<-",
						_say(posted), _say(lure), _say(after)])
				posted_walks.append(posted)
				lure_walks.append(lure)
				if not after.is_empty():
					after_walks.append(after)
	var two := 0
	var total := 0
	for count in bands:
		total += count
		two += 1 if count > 1 else 0
	print("ESCAPE_ROADBLOCK %s | %d crossings over %d seeds | %d roadblocks | %d crossings with more than one"
			% [tag, bands.size(), SEEDS.size(), total, two])
	for key: String in ["posted", "lure", "after"]:
		var walks: Array[Dictionary] = tally[key]
		var costs: Array[float] = []
		var caught := 0
		var charged := 0
		var turned := 0
		var turned_caught := 0
		var frames := 0
		var usec := 0
		var worst := 0
		var pasts: Array[float] = []
		var nears: Array[float] = []
		for w: Dictionary in walks:
			costs.append(w["cost"])
			caught += 1 if w["caught"] else 0
			charged += 1 if w["charged"] > 0 else 0
			if int(w.get("turned", 0)) > 0:
				turned += 1
				turned_caught += 1 if w["caught"] else 0
			frames += int(w.get("chase_frames", 0))
			usec += int(w.get("chase_usec", 0))
			worst = maxi(worst, int(w.get("chase_worst_usec", 0)))
			if w["caught"] and int(w.get("turned", 0)) == 0 and w.has("past"):
				pasts.append(float(w["past"]))
			if w.has("nearest"):
				nears.append(float(w["nearest"]))
		costs.sort()
		if costs.is_empty():
			continue
		print("ESCAPE_ROADBLOCK %s | %-6s | %d walks | caught %d | charged in %d | cost min %.1f median %.1f max %.1f"
				% [tag, key, walks.size(), caught, charged, costs[0], costs[costs.size() / 2],
				costs[costs.size() - 1]])
		nears.sort()
		if key == "lure" and not nears.is_empty():
			print("ESCAPE_ROADBLOCK %s | lure   | nearest a charging guard came min %.0f median %.0f max %.0f px"
					% [tag, nears[0], nears[nears.size() / 2], nears[nears.size() - 1]])
		if key == "posted":
			print("ESCAPE_ROADBLOCK %s | posted | turned a corner %d | caught after turning %d | chase ticks %d, mean %.3f ms, worst %.3f ms"
					% [tag, turned, turned_caught, frames, usec / 1000.0 / maxi(frames, 1),
					worst / 1000.0])
			pasts.sort()
			if not pasts.is_empty():
				print("ESCAPE_ROADBLOCK %s | posted | caught walking straight on %d | past the band min %.0f median %.0f max %.0f px"
						% [tag, pasts.size(), pasts[0], pasts[pasts.size() / 2], pasts[pasts.size() - 1]])

## How far past the last band along her line from `from` to `to` she was at `at`, in px.
static func _past_the_bands(group: Array[EventPlan], from: Vector2, to: Vector2, at: Vector2) -> float:
	var heading := (to - from).normalized()
	var last := -INF
	for placement in group:
		last = maxf(last, (placement.placed_at() - from).dot(heading))
	return (at - from).dot(heading) - last

static func _say(w: Dictionary) -> String:
	if w.is_empty():
		return "not walked (caught in the lure)"
	var turned := int(w.get("turned", 0))
	var caught := ""
	if w["caught"]:
		caught = ", CAUGHT %.0fpx past" % float(w["past"]) if w.has("past") else ", CAUGHT"
	return "cost %.1f (peak %.1f end %.1f), %d charged%s%s" % [w["cost"], w["peak"], w["end"],
			w["charged"], ", turned %d" % turned if turned > 0 else "", caught]
