extends RefCounted
## Measurement probe for the escape's roadblocks (inbox #771 in minty-lemur): what walking past the roadblocks on
## one of the escape's streets costs the meter with their guards at their post, what luring the
## guard on her side off costs, and what walking on past costs once he has gone. Not a suite: it
## prints rather than asserts. Run by name:
##
##     tools/test.sh probes/escape_roadblock_cost.gd      (prints ESCAPE_ROADBLOCK lines)
##
## The rig is `tests/escape_roadblock_rig.gd`; `tests/test_finale.gd` pins what this prints.
## Every crossing is walked in both directions, twice: from 0 asleep, which is what every attempt
## at the city section starts on (`main._start_section()`: `Baby.reset()` then `force_sleep()`),
## and from `Tuning.EXCITEMENT_WAKE_THRESHOLD` awake, the baby a bang earlier on
## the walk has just woken. Three walks each:
##
## - **posted**: straight past at a walk, the guards at their posts. Ends at a catch.
## - **lure**: in at a walk until a guard's hand goes up, standing until he charges, then turned and
##   run straight back 0.3s later at `Tuning.ACCELERATION` until every charge has given up, then
##   standing until each guard who charged has left his post for good.
## - **after**: on from where the lure left her, at a walk, past the band to the far end. A guard
##   who charges now is one the lure did not take off.

const Rig := preload("res://tests/escape_roadblock_rig.gd")
const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024]

func run(t) -> void:
	for awake in [false, true]:
		_measure(t, awake)

func _measure(t, awake: bool) -> void:
	var start := Tuning.EXCITEMENT_WAKE_THRESHOLD if awake else 0.0
	var tag := "awake %2.0f" % start if awake else "asleep 0"
	var tally := {"posted": [], "lure": [], "after": []}
	var bands: Array[int] = []
	for seed_value in SEEDS:
		var built := Rig.plan_for(seed_value)
		var map: CityMap = built["map"]
		var plan: FinalePlanner.Plan = built["plan"]
		var placements: Array[EventScheduler.Planned] = built["placements"]
		for street: Array in Rig.roadblock_streets(map, plan, placements):
			var segment: StreetNetwork.Segment = street[0]
			var group: Array[EventScheduler.Planned] = []
			group.assign(street[1])
			var line := Rig.her_line(t, map, segment, group)
			if line.is_empty():
				print("ESCAPE_ROADBLOCK %s seed %d street %s: no open line" % [tag, seed_value,
						segment.key()])
				continue
			bands.append(group.size())
			for forward in [true, false]:
				var from: Vector2 = line[0] if forward else line[1]
				var to: Vector2 = line[1] if forward else line[0]
				var posted := Rig.walk(t, map, group, from, to, Rig.Meter.new(start, not awake))
				var lured := Rig.lure(t, map, group, from, to, Rig.Meter.new(start, not awake))
				var after: Dictionary = lured["after"]
				print("ESCAPE_ROADBLOCK %s seed %5d street %s %d band(s) %s | posted: %s | lure: %s | after: %s"
						% [tag, seed_value, segment.key(), group.size(), "->" if forward else "<-",
						_say(posted), _say(lured["lure"]), _say(after)])
				tally["posted"].append(posted)
				tally["lure"].append(lured["lure"])
				if not after.is_empty():
					tally["after"].append(after)
	var two := 0
	var total := 0
	for count in bands:
		total += count
		two += 1 if count > 1 else 0
	print("ESCAPE_ROADBLOCK %s | %d crossings over %d seeds | %d roadblocks | %d crossings with more than one"
			% [tag, bands.size(), SEEDS.size(), total, two])
	for key in ["posted", "lure", "after"]:
		var walks: Array = tally[key]
		var costs: Array[float] = []
		var caught := 0
		var charged := 0
		for w: Dictionary in walks:
			costs.append(w["cost"])
			caught += 1 if w["caught"] else 0
			charged += 1 if w["charged"] > 0 else 0
		costs.sort()
		if costs.is_empty():
			continue
		print("ESCAPE_ROADBLOCK %s | %-6s | %d walks | caught %d | charged in %d | cost min %.1f median %.1f max %.1f"
				% [tag, key, walks.size(), caught, charged, costs[0], costs[costs.size() / 2],
				costs[costs.size() - 1]])

static func _say(w: Dictionary) -> String:
	if w.is_empty():
		return "not walked (caught in the lure)"
	return "cost %.1f (peak %.1f end %.1f), %d charged%s" % [w["cost"], w["peak"], w["end"],
			w["charged"], ", CAUGHT" if w["caught"] else ""]
