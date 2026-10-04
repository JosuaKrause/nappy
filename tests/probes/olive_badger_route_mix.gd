extends RefCounted
## Measurement probe for olive-badger, what she meets on her route is drawn from a marble bag. Not a
## suite: it prints rather than asserting, so it lives under `tests/probes/`, where the runner never
## discovers it, and runs only by name:
##
##     tools/test.sh probes/olive_badger_route_mix.gd
##
## **What it measures is the mix of rows `EventDirector` hands out over a day**, against the share
## each row's `weight` gives it among the rows the director sites that day (`AHEAD_OF_PLAYER` and
## `TOWARD_PLAYER`). It drives the director the way `tests/probes/m99_caps.gd` does — a whole day of
## continuous walking down a real pavement, bounced at the map's edges — so the count per day is the
## pacing's own (`Tuning.AHEAD_INTERVAL`), and what differs between a roll and a bag is only which
## row each handout is.
##
## Printed per day and over the whole sweep: how many route rows the dawn bought, how many she met,
## each row's share met against its intended share, the **mismatch** (the share of a day's handouts
## that would have to change row for the day to match the intended mix exactly, half the L1
## distance), and the longest run of one row back to back. Uses only `EventDirector.start_day()`,
## `due()` and `owe_the_return()`, so it measures the code before and after a change alike.
##
## **And whether the return leg's patrols land.** On every act III and IV day it walks a second time,
## owes the return `RETURN_LEG` seconds before the day ends — the leg lengths `Tuning.
## RETURN_PATROLS_PER_ACT` was sized against — and counts the patrols handed out in the leg against
## the number owed.

const SEEDS := 12
const DAYS: Array[int] = [1, 2, 3, 4, 6, 8, 10, 12, 14]
const BASE_SEED := 772041
const STEP := 0.2
## Seconds of walking home, act III and act IV — the return legs `Tuning.RETURN_PATROLS_PER_ACT` names.
const RETURN_LEG := {3: 33.0, 4: 47.0}

func run(t) -> void:
	_measure()
	_measure_the_return()
	t.check(true, "zz_olive_badger_route_mix probe ran")

func _measure() -> void:
	print("\n== olive-badger route mix: %d seeds x days %s, a whole day of continuous walking =="
			% [SEEDS, DAYS])
	var met_total := {}
	var expected_total := {}
	var mismatch_sum := 0.0
	var mismatch_max := 0.0
	var streak_max := 0
	var streak_sum := 0
	var days_run := 0
	var handouts_sum := 0
	var bought_sum := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in DAYS:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("olive-badger:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], tree, 0)
			var bought := 0
			for plan in planned:
				var mode := plan.def.spawn_mode_on(day)
				if mode == EventDef.SpawnMode.AHEAD_OF_PLAYER \
						or mode == EventDef.SpawnMode.TOWARD_PLAYER:
					bought += 1
			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("olive-badger:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, director_rng)
			var met := _walk_a_day(map, director, day)
			var shares := _intended_shares(day)
			var counts := {}
			for id: String in met:
				counts[id] = int(counts.get(id, 0)) + 1
			var distance := 0.0
			var ids := {}
			for id: String in shares:
				ids[id] = true
			for id: String in counts:
				ids[id] = true
			for id: String in ids:
				var expected := float(shares.get(id, 0.0)) * met.size()
				var got := float(counts.get(id, 0))
				distance += absf(got - expected)
				met_total[id] = int(met_total.get(id, 0)) + int(got)
				expected_total[id] = float(expected_total.get(id, 0.0)) + expected
			var mismatch := 0.0 if met.is_empty() else distance * 0.5 / met.size()
			var streak := _longest_run(met)
			mismatch_sum += mismatch
			mismatch_max = maxf(mismatch_max, mismatch)
			streak_max = maxi(streak_max, streak)
			streak_sum += streak
			handouts_sum += met.size()
			bought_sum += bought
			days_run += 1
			print("  seed %d day %2d: bought %2d, met %2d, mismatch %4.0f%%, longest run %d  %s"
					% [map.seed_used, day, bought, met.size(), mismatch * 100.0, streak,
					" ".join(_short(met))])
	print("\n-- over %d days --" % days_run)
	print("  mean bought/day %.1f, mean met/day %.1f" % [float(bought_sum) / days_run,
			float(handouts_sum) / days_run])
	print("  mismatch: mean %.1f%%, worst day %.0f%%" % [mismatch_sum / days_run * 100.0,
			mismatch_max * 100.0])
	print("  longest run of one row: mean %.2f, worst %d" % [float(streak_sum) / days_run,
			streak_max])
	for id: String in expected_total:
		print("  %-13s met %4d, intended %6.1f (%+.1f%%)" % [id, int(met_total.get(id, 0)),
				float(expected_total[id]), (float(met_total.get(id, 0)) / maxf(
				float(expected_total[id]), 0.001) - 1.0) * 100.0])

func _measure_the_return() -> void:
	print("\n== return patrols: %d seeds x act III/IV days, owed %s s before the day ends ==" % [
			SEEDS, RETURN_LEG])
	var owed := 0
	var landed := 0
	var legs := 0
	var legs_with_one := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for day in DAYS:
			var act := Tuning.act_for_day(day)
			if not RETURN_LEG.has(act):
				continue
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)
			var plan_rng := RandomNumberGenerator.new()
			plan_rng.seed = hash("olive-badger:plan:%d:%d" % [map.seed_used, day])
			var planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
					day, plan_rng, map, [], [], [], tree, 0)
			var director := EventDirector.new(map)
			var director_rng := RandomNumberGenerator.new()
			director_rng.seed = hash("olive-badger:ahead:%d:%d" % [map.seed_used, day])
			director.start_day(day, planned, director_rng)
			var day_len := Tuning.day_length(day)
			var leg: float = RETURN_LEG[act]
			var y_max: float = map.world_size().y
			var pos := CrowdLanes.arterial_pavement(map)
			pos.y = y_max * 0.5
			var vel := Vector2(0.0, -Tuning.WALK_SPEED)
			var t := 0.0
			var in_leg := 0
			var returned := false
			while t < day_len:
				if not returned and t >= day_len - leg:
					returned = true
					director.owe_the_return(day, 0)
				var step := minf(STEP, day_len - t)
				var due: Array = director.due(step, pos, vel)
				if returned and not due.is_empty() and (due[0] as EventDef).id == "police_patrol":
					in_leg += 1
				pos += vel * step
				if pos.y < 0.0 or pos.y > y_max:
					vel.y = -vel.y
					pos.y = clampf(pos.y, 0.0, y_max)
				t += step
			var count: int = Tuning.RETURN_PATROLS_PER_ACT[act - 1]
			owed += count
			landed += in_leg
			legs += 1
			if in_leg > 0:
				legs_with_one += 1
			print("  seed %d day %2d (act %d): %d of %d return patrols land in the %.0fs leg"
					% [map.seed_used, day, act, in_leg, count, leg])
	print("  over %d legs: %d of %d owed patrols land, %d legs meet at least one" % [legs, landed,
			owed, legs_with_one])

## Every row the director hands out over one day of walking, in order.
func _walk_a_day(map: CityMap, director: EventDirector, day: int) -> Array[String]:
	var met: Array[String] = []
	var y_max: float = map.world_size().y
	var pos := CrowdLanes.arterial_pavement(map)
	pos.y = y_max * 0.5
	var vel := Vector2(0.0, -Tuning.WALK_SPEED)
	var day_len := Tuning.day_length(day)
	var t := 0.0
	while t < day_len:
		var step := minf(STEP, day_len - t)
		var due: Array = director.due(step, pos, vel)
		if not due.is_empty():
			met.append((due[0] as EventDef).id)
		pos += vel * step
		if pos.y < 0.0 or pos.y > y_max:
			vel.y = -vel.y
			pos.y = clampf(pos.y, 0.0, y_max)
		t += step
	return met

## Each director-sited row's share of the day by `weight`, among the rows available that day.
func _intended_shares(day: int) -> Dictionary:
	var shares := {}
	var total := 0.0
	for def in EventCatalogue.of_kind(GameEnums.EventKind.RECURRING, day):
		var mode := def.spawn_mode_on(day)
		if mode != EventDef.SpawnMode.AHEAD_OF_PLAYER and mode != EventDef.SpawnMode.TOWARD_PLAYER:
			continue
		shares[def.id] = def.weight
		total += def.weight
	for id: String in shares:
		shares[id] = float(shares[id]) / total
	return shares

func _longest_run(met: Array[String]) -> int:
	var best := 0
	var run := 0
	for i in met.size():
		run = run + 1 if i > 0 and met[i] == met[i - 1] else 1
		best = maxi(best, run)
	return best

func _short(met: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id in met:
		out.append(id.substr(0, 3))
	return out
