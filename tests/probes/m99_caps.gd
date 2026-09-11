extends RefCounted
## Measurement probe for M99, the corridor's density after the sealing — "`cyclist` and
## `loose_dog`'s caps no longer mean what they say." Not a suite: it prints rather than asserting,
## so it lives here under `tests/probes/`, where the runner never discovers it, and runs only by
## name:
##
##     tools/test.sh probes/m99_caps.gd
##
## Both rows carry `EventDef.max_per_day` (`cyclist` 14, `loose_dog` 24) but arrive through
## `EventDirector`'s single FIFO queue at `Tuning.AHEAD_INTERVAL` (11-26s) pacing rather than
## being map-placed, sharing that queue with every other `AHEAD_OF_PLAYER`/`TOWARD_PLAYER` row a
## day budgets — `cat_dash`, `charging_dog`, and each other. `cyclist`'s own catalogue comment
## already states the claim this measures: *"how many of fourteen she could ever actually meet is
## bounded by the day's own length long before the cap is."* This counts how many the queue
## actually hands out over a whole day of continuous walking, across every act, and holds it next
## to the two numbers on the row.
##
## Walked the same way `tests/test_events.gd`'s `_test_a_rig_meets_the_three_things_that_arrive`
## drives `EventDirector` — continuous motion on a real street
## (`CrowdLanes.arterial_pavement`) — bounced at the map's own edges so a whole day's walk never
## asks for ground off it. `due()`'s pacing is a property of elapsed walking time, not of which
## street she is on, so a straight bounced line is the right instrument for the queue's own
## throughput, the same way `m98_return_phase.gd` uses it for one leg.

const SEEDS := 6
## One sample day per act (`Tuning.ACT_START_DAYS` is `[1, 4, 8, 12]`), the earliest each row
## could actually appear at all — day 2 rather than day 1, since `cyclist.first_day == 2`.
const ACT_SAMPLE_DAYS: Array[int] = [2, 5, 9, 13]
const BASE_SEED := 550209
const STEP := 0.2
const TRACKED_IDS := ["cyclist", "loose_dog"]

func run(t) -> void:
	_measure_caps()
	t.check(true, "zz_m99_caps probe ran")

func _measure_caps() -> void:
	print("\n== M99 caps: %d seeds x one day per act %s, whole day of continuous walking =="
			% [SEEDS, ACT_SAMPLE_DAYS])
	for id in TRACKED_IDS:
		var def := EventCatalogue.by_id(id)
		print("  %-10s max_per_day=%d weight=%.1f" % [id, def.max_per_day, def.weight])

	# act -> id -> Array[int] per-day counts
	var by_act_id := {}
	for act in [1, 2, 3, 4]:
		by_act_id[act] = {}
		for id in TRACKED_IDS:
			by_act_id[act][id] = []
	var by_act_total_owed := {1: [], 2: [], 3: [], 4: []}
	var by_act_budgeted := {}
	for act in [1, 2, 3, 4]:
		by_act_budgeted[act] = {}
		for id in TRACKED_IDS:
			by_act_budgeted[act][id] = []

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in ACT_SAMPLE_DAYS:
			var act := Tuning.act_for_day(day)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)

			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("m99:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], tree, 0)

			var budgeted := {}
			for id in TRACKED_IDS:
				budgeted[id] = 0
			for plan: EventScheduler.Planned in planned:
				if plan.def.id in budgeted:
					budgeted[plan.def.id] += 1

			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("m99:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, director_rng)

			var y_min := 0.0
			var y_max: float = map.world_size().y
			var pos := CrowdLanes.arterial_pavement(map)
			pos.y = y_max * 0.5
			var vel := Vector2(0.0, -Tuning.WALK_SPEED)

			var counts := {}
			for id in TRACKED_IDS:
				counts[id] = 0
			var total_owed := 0
			var day_len := Tuning.day_length(day)
			var t := 0.0
			while t < day_len:
				var step := minf(STEP, day_len - t)
				var due: Array = director.due(step, pos, vel)
				if not due.is_empty():
					total_owed += 1
					var def: EventDef = due[0]
					if def.id in counts:
						counts[def.id] += 1
				pos += vel * step
				if pos.y < y_min or pos.y > y_max:
					vel.y = -vel.y
					pos.y = clampf(pos.y, y_min, y_max)
				t += step

			by_act_total_owed[act].append(total_owed)
			for id in TRACKED_IDS:
				by_act_id[act][id].append(counts[id])
				by_act_budgeted[act][id].append(budgeted[id])

	print("\n-- per act (mean over %d seeds) --" % SEEDS)
	for act in [1, 2, 3, 4]:
		print("  act %d — mean total AHEAD/TOWARD encounters/day: %.2f"
				% [act, _mean(by_act_total_owed[act])])
		for id in TRACKED_IDS:
			var def := EventCatalogue.by_id(id)
			print("    %-10s budgeted/day (mean)=%.2f  actually met/day (mean)=%.2f  of max_per_day=%d"
					% [id, _mean(by_act_budgeted[act][id]), _mean(by_act_id[act][id]), def.max_per_day])

	print("\n-- across every sampled act/seed --")
	for id in TRACKED_IDS:
		var all_met: Array = []
		var all_budgeted: Array = []
		for act in [1, 2, 3, 4]:
			all_met.append_array(by_act_id[act][id])
			all_budgeted.append_array(by_act_budgeted[act][id])
		var def := EventCatalogue.by_id(id)
		var max_met := 0
		for v in all_met:
			max_met = maxi(max_met, int(v))
		print("  %-10s mean budgeted/day=%.2f mean met/day=%.2f max met on any sampled day=%d (cap %d)"
				% [id, _mean(all_budgeted), _mean(all_met), max_met, def.max_per_day])

func _mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / float(values.size())
