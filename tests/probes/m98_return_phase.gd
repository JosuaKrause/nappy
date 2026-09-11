extends RefCounted
## Measurement probe for M98, pressure in the empty acts — "Patrols for acts III and IV, built
## around encounter cost." Not a suite: it prints rather than asserting, so it lives here under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m98_return_phase.gd
##
## Playtest 03 measured the return phase — `DayPhase.RETURNING`, entered when the baby falls
## asleep on calm ground and lasting until she is home — as a formality: 26s, five crossings,
## zero encounters, 42% of the day left. This is a "before" measurement only, across all four
## acts, of the two numbers the TODO item asks for: **encounters per return, and how much of the
## day's clock the return actually spends.**
##
## Two things are measured separately, deliberately decoupled from each other:
##
## - **How long each leg takes** comes from the day's real corridor: `RouteTree.for_day`'s first
##   branch to a calm area, walked in cells (`ReachabilityGrid.CELL` = 2 tiles each) at
##   `Tuning.WALK_SPEED`. The outbound leg is the settle; the return leg retraces the same
##   distance, capped by whatever of the day's clock (`Tuning.day_length`) is left.
## - **How many things the single queue hands out in that time** comes from
##   `EventDirector.due()`, walked continuously on a real street (`CrowdLanes.arterial_pavement`,
##   bounced at the map's own edges so a long leg never asks for ground off it) for the leg's
##   own duration. `due()` only needs continuous motion on walkable ground to fire — the pacing
##   it is testing, `Tuning.AHEAD_INTERVAL` (11-26s), is a property of elapsed time, not of which
##   street she is on, so this measures the queue's own throughput against the leg's length
##   without needing an exact world-position walk of the literal corridor. The **same** director
##   instance and its running timer carry from the outbound leg into the return leg, the way one
##   day's single queue actually does.
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
	var return_encounters_by_act := {1: [], 2: [], 3: [], 4: []}

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

			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("m98:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, director_rng)

			var y_min := 0.0
			var y_max: float = map.world_size().y
			var pos := CrowdLanes.arterial_pavement(map)
			pos.y = y_max * 0.5
			var vel := Vector2(0.0, -Tuning.WALK_SPEED)

			var out_result := _walk_and_count(director, pos, vel, out_seconds, y_min, y_max)
			var out_count: int = out_result[0]
			var return_result := _walk_and_count(director, out_result[2], out_result[3],
					return_seconds, y_min, y_max)
			var return_count: int = return_result[0]
			var return_ids: Array[String] = return_result[1]

			out_seconds_by_act[act].append(out_seconds)
			return_seconds_by_act[act].append(return_seconds)
			return_fraction_by_act[act].append(return_seconds / maxf(1.0, day_len))
			out_encounters_by_act[act].append(out_count)
			return_encounters_by_act[act].append(return_count)

			if examples.size() < MAX_EXAMPLES:
				examples.append(
						"  seed=%d day=%d act=%d: out=%.1fs (%d owed) return=%.1fs (%.1f%% of %.0fs day, %d owed%s)"
						% [i, day, act, out_seconds, out_count, return_seconds,
						100.0 * return_seconds / maxf(1.0, day_len), day_len, return_count,
						"" if return_ids.is_empty() else ": " + ", ".join(return_ids)])

	print("\n-- per act (mean over %d seeds) --" % SEEDS)
	print("  act  out-leg(s)  return-leg(s)  return-of-day   owed-out  owed-return")
	for act in [1, 2, 3, 4]:
		var n: Array = out_seconds_by_act[act]
		if n.is_empty():
			print("  %-4d (no sampled day reached a calm area)" % act)
			continue
		print("  %-4d %10.1f %13.1f %13.1f%% %10.2f %11.2f"
				% [act, _mean_f(out_seconds_by_act[act]), _mean_f(return_seconds_by_act[act]),
				100.0 * _mean_f(return_fraction_by_act[act]), _mean_i(out_encounters_by_act[act]),
				_mean_i(return_encounters_by_act[act])])

	var all_return_counts: Array = []
	for act in [1, 2, 3, 4]:
		all_return_counts.append_array(return_encounters_by_act[act])
	var zero_return := 0
	for c in all_return_counts:
		if int(c) == 0:
			zero_return += 1
	if not all_return_counts.is_empty():
		print("\nreturn legs with zero owed encounters: %d of %d (%.1f%%)"
				% [zero_return, all_return_counts.size(),
				100.0 * float(zero_return) / float(all_return_counts.size())])

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
