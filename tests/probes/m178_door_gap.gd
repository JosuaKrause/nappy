extends RefCounted
## Measurement probe for M178, "a gate lets her out alive": how many of a day's events sit inside a
## region door's own clear ground, and what refusing them costs the day's density. Not a suite — it
## prints numbers rather than asserting relationships — so it lives under `tests/probes/`, where the
## runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m178_door_gap.gd
##
## **Before and after in one run, from the same seed and the same day.** `EventScheduler.build_day`
## takes today's door positions as an argument, so "before" is the identical call with that argument
## empty — no code is changed to take the measurement, and the two numbers come out of the same
## RNG stream planning the same city. What moves between them is only which candidates were
## refused.
##
## **Inside the gap** is `EventScheduler.clear_of_the_doors()` answering false: the candidate's own
## `EventDef.field_reach()` arrives within `Tuning.CHECKPOINT_EVENT_GAP` of a door body, measured to
## the nearest point of its route rather than to the spot it starts at. That is the rule itself
## rather than a second copy of it, which is the only way the count can be trusted.
##
## Days 7 and 11 are the sample: `Tuning.REGION_WALL_FIRST_DAY` is 7, so day 7 is the first day a
## door exists at all and day 11 is a late, dense one in a different act.

const SEEDS := 6
const BASE_SEED := 305117
const DAYS := [7, 11]

func run(_t) -> void:
	print("\n== events inside a region door's gap (%.0fpx of clear ground, field-to-body) =="
			% Tuning.CHECKPOINT_EVENT_GAP)
	print("%-12s %5s %6s %8s %8s %8s %8s" % [
			"seed", "day", "doors", "in-before", "in-after", "placed-b", "placed-a"])
	var total_before := 0
	var total_after := 0
	var placed_before := 0
	var placed_after := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 977)
		for day: int in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var plan := RegionPlanner.plan_day(map, day, tree)
			var doors := PackedVector2Array()
			for body in plan.door_bodies:
				doors.append(body.position)

			var before := _plan_day(map, day, tree, PackedVector2Array())
			var after := _plan_day(map, day, tree, doors)
			var in_before := _inside(before, doors)
			var in_after := _inside(after, doors)
			var count_before := _placed(before)
			var count_after := _placed(after)
			total_before += in_before
			total_after += in_after
			placed_before += count_before
			placed_after += count_after
			print("%-12d %5d %6d %8d %8d %8d %8d" % [
					map.seed_used, day, doors.size(), in_before, in_after,
					count_before, count_after])
	print("total inside the gap: %d before, %d after" % [total_before, total_after])
	print("total placed: %d before, %d after (%.1f%%)"
			% [placed_before, placed_after,
			100.0 * float(placed_after) / maxf(1.0, float(placed_before))])

## One day's catalogue placements, with `doors` as the clear ground to keep. Everything else is
## `EventManager.start_day()`'s own call with a rig's empty run history: no scars, no settled calm,
## no heat, so the two halves of the comparison differ in the door argument and nothing else.
func _plan_day(map: CityMap, day: int, tree: RouteTree,
		doors: PackedVector2Array) -> Array[EventScheduler.Planned]:
	var rng := RandomNumberGenerator.new()
	rng.seed = map.seed_used * 31 + day
	var consumed: Array[String] = []
	var scars: Array[Dictionary] = []
	var used_calm: Array[Vector2i] = []
	return EventScheduler.build_day(day, rng, map, consumed, scars, used_calm, tree, 0, doors)

func _placed(plans: Array[EventScheduler.Planned]) -> int:
	var total := 0
	for plan in plans:
		if plan.is_placed():
			total += 1
	return total

func _inside(plans: Array[EventScheduler.Planned], doors: PackedVector2Array) -> int:
	var total := 0
	for plan in plans:
		if not plan.is_placed():
			continue
		if not EventScheduler.clear_of_the_doors(plan.position, plan.path, doors,
				plan.def.field_reach()):
			total += 1
	return total
