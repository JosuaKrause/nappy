extends RefCounted
## Measurement probe for M98, pressure in the empty acts — "Patrols for acts III and IV, built
## around encounter cost." Not a suite: it prints rather than asserting, so it lives here under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m98_return_phase.gd
##
## Playtest 03 measured the return phase — `DayPhase.RETURNING`, entered when the baby falls
## asleep on calm ground and lasting until she is home — as a formality: 26s, five crossings,
## zero encounters, 42% of the day left. This measures, across all four acts, the two numbers the
## TODO item asks for — **encounters per return, and how much of the day's clock the return
## actually spends** — **before** (the queue as it always paced) and **after**
## `EventDirector.owe_the_return()` has told it the return leg started, in the same run, so the two
## sit side by side rather than in two separate probes somebody has to remember to compare.
##
## Two things are measured separately, deliberately decoupled from each other:
##
## - **How long each leg takes** comes from the day's real corridor: `RouteTree.for_day`'s first
##   branch to a calm area, walked in cells (`ReachabilityGrid.CELL` = 2 tiles each) at
##   `Tuning.WALK_SPEED`. The outbound leg is the settle; the return leg retraces the same
##   distance, capped by whatever of the day's clock (`Tuning.day_length`) is left. This is the
##   same either way — `owe_the_return()` changes what the queue hands out, not how long the leg
##   is — so it is measured once and shared by both columns.
## - **How many things the single queue hands out in that time** comes from
##   `EventDirector.due()`, walked continuously on a real street (`CrowdLanes.arterial_pavement`,
##   bounced at the map's own edges so a long leg never asks for ground off it) for the leg's
##   own duration. `due()` only needs continuous motion on walkable ground to fire — the pacing
##   it is testing, `Tuning.AHEAD_INTERVAL` (11-26s) before the return is owed, is a property of
##   elapsed time, not of which street she is on, so this measures the queue's own throughput
##   against the leg's length without needing an exact world-position walk of the literal
##   corridor. The **same** director instance and its running timer carry from the outbound leg
##   into the return leg, the way one day's single queue actually does — one director for
##   "before", a second one seeded identically for "after" so the two walk the identical out leg
##   before diverging at the one call this milestone adds.
##
## What this does not measure: `MAP`-sited encounters (a `dog_walker`, a `cafe_tables`) along the
## literal return route, or anything about the crowd. Those are a property of the corridor's own
## geometry, which `m99_corridor_density.gd`'s sibling probe already covers; this item is
## specifically about the director's single-queue pacing during the empty second half of a day.

const SEEDS := 6
## One sample day per act (`Tuning.ACT_START_DAYS` is `[1, 4, 8, 12]`).
const ACT_SAMPLE_DAYS: Array[int] = [2, 5, 9, 13]
const BASE_SEED := 730105
const STEP := 0.2

func run(t) -> void:
	_measure_return_phase()
	t.check(true, "zz_m98_return_phase probe ran")

func _measure_return_phase() -> void:
	print("\n== M98 return phase: %d seeds x one day per act %s ==" % [SEEDS, ACT_SAMPLE_DAYS])

	var out_seconds_by_act := {1: [], 2: [], 3: [], 4: []}
	var return_seconds_by_act := {1: [], 2: [], 3: [], 4: []}
	var return_fraction_by_act := {1: [], 2: [], 3: [], 4: []}
	var out_encounters_by_act := {1: [], 2: [], 3: [], 4: []}
	## Before `owe_the_return()` — the queue exactly as it paced before this milestone.
	var return_encounters_before_by_act := {1: [], 2: [], 3: [], 4: []}
	## After it — the same out leg, then `owe_the_return(day, 0)` before the return leg walks.
	var return_encounters_after_by_act := {1: [], 2: [], 3: [], 4: []}

	var examples: Array[String] = []
	const MAX_EXAMPLES := 8

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in ACT_SAMPLE_DAYS:
			var act := Tuning.act_for_day(day)
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			if tree.branches.is_empty():
				continue
			var branch: RouteTree.Branch = tree.branches[0]
			if branch.routes.is_empty():
				continue
			var route: Array = branch.routes[0]

			var day_len := Tuning.day_length(day)
			var leg_cells := maxi(route.size() - 1, 0)
			var out_seconds := minf(day_len,
					float(leg_cells) * float(ReachabilityGrid.CELL) * Tuning.TILE_SIZE / Tuning.WALK_SPEED)
			var return_seconds := minf(out_seconds, maxf(0.0, day_len - out_seconds))

			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("m98:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], tree, 0)

			var y_min := 0.0
			var y_max: float = map.world_size().y
			var start_pos := CrowdLanes.arterial_pavement(map)
			start_pos.y = y_max * 0.5
			var start_vel := Vector2(0.0, -Tuning.WALK_SPEED)

			# "Before": the queue exactly as `tests/probes/m98_return_phase.gd` always drove it —
			# no call to `owe_the_return()` at all.
			var before := EventDirector.new(map)
			var before_rng := RandomNumberGenerator.new()
			before_rng.seed = hash("m98:ahead:%d:%d" % [map.seed_used, day])
			before.start_day(day, planned, before_rng)
			var out_result := _walk_and_count(before, start_pos, start_vel, out_seconds, y_min, y_max)
			var out_count: int = out_result[0]
			var return_before := _walk_and_count(before, out_result[2], out_result[3],
					return_seconds, y_min, y_max)
			var before_count: int = return_before[0]

			# "After": a second director, seeded identically, walking the identical out leg — so
			# the two are the same day up to the one call this milestone adds — then told the
			# return has started, the same call `EventManager._owe_the_return()` makes, before its
			# own return leg walks.
			var after := EventDirector.new(map)
			var after_rng := RandomNumberGenerator.new()
			after_rng.seed = hash("m98:ahead:%d:%d" % [map.seed_used, day])
			after.start_day(day, planned, after_rng)
			var out_result_after := _walk_and_count(after, start_pos, start_vel, out_seconds,
					y_min, y_max)
			after.owe_the_return(day, 0)
			var return_after := _walk_and_count(after, out_result_after[2], out_result_after[3],
					return_seconds, y_min, y_max)
			var after_count: int = return_after[0]
			var after_ids: Array[String] = return_after[1]

			out_seconds_by_act[act].append(out_seconds)
			return_seconds_by_act[act].append(return_seconds)
			return_fraction_by_act[act].append(return_seconds / maxf(1.0, day_len))
			out_encounters_by_act[act].append(out_count)
			return_encounters_before_by_act[act].append(before_count)
			return_encounters_after_by_act[act].append(after_count)

			if examples.size() < MAX_EXAMPLES:
				examples.append(
						("  seed=%d day=%d act=%d: out=%.1fs (%d owed) return=%.1fs (%.1f%% of "
								% [i, day, act, out_seconds, out_count, return_seconds,
								100.0 * return_seconds / maxf(1.0, day_len)])
						+ ("%.0fs day) before=%d owed, after=%d owed%s"
								% [day_len, before_count, after_count,
								"" if after_ids.is_empty() else ": " + ", ".join(after_ids)]))

	print("\n-- per act (mean over %d seeds) --" % SEEDS)
	print("  act  out-leg(s)  return-leg(s)  return-of-day   owed-out  owed-return-before  owed-return-after")
	for act in [1, 2, 3, 4]:
		var n: Array = out_seconds_by_act[act]
		if n.is_empty():
			print("  %-4d (no sampled day reached a calm area)" % act)
			continue
		print("  %-4d %10.1f %13.1f %13.1f%% %10.2f %19.2f %17.2f"
				% [act, _mean_f(out_seconds_by_act[act]), _mean_f(return_seconds_by_act[act]),
				100.0 * _mean_f(return_fraction_by_act[act]), _mean_i(out_encounters_by_act[act]),
				_mean_i(return_encounters_before_by_act[act]),
				_mean_i(return_encounters_after_by_act[act])])

	for label in ["before", "after"]:
		var counts: Dictionary = return_encounters_before_by_act if label == "before" \
				else return_encounters_after_by_act
		var all_counts: Array = []
		for act in [1, 2, 3, 4]:
			all_counts.append_array(counts[act])
		var zero := 0
		for c in all_counts:
			if int(c) == 0:
				zero += 1
		if not all_counts.is_empty():
			print("\nreturn legs with zero owed encounters, %s: %d of %d (%.1f%%)"
					% [label, zero, all_counts.size(), 100.0 * float(zero) / float(all_counts.size())])

	if not examples.is_empty():
		print("\n-- examples --")
		for line in examples:
			print(line)

## Advances `director`'s queue for `seconds` of continuous walking, bounced at `y_min`/`y_max` so
## a long leg never asks the map for ground off its own edge. Returns
## `[count: int, ids: Array[String], end_pos: Vector2, end_vel: Vector2]` so the caller can chain
## the next leg from where this one left off — the same running queue and timer one day's single
## `EventDirector` actually carries from the walk out into the walk back.
func _walk_and_count(director: EventDirector, start_pos: Vector2, start_vel: Vector2,
		seconds: float, y_min: float, y_max: float) -> Array:
	var pos := start_pos
	var vel := start_vel
	var count := 0
	var ids: Array[String] = []
	var t := 0.0
	while t < seconds:
		var step := minf(STEP, seconds - t)
		var due: Array = director.due(step, pos, vel)
		if not due.is_empty():
			count += 1
			var def: EventDef = due[0]
			ids.append(def.id)
		pos += vel * step
		if pos.y < y_min or pos.y > y_max:
			vel.y = -vel.y
			pos.y = clampf(pos.y, y_min, y_max)
		t += step
	return [count, ids, pos, vel]

func _mean_f(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += float(v)
	return total / float(values.size())

func _mean_i(values: Array) -> float:
	return _mean_f(values)
