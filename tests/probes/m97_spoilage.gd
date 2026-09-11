extends RefCounted
## Measurement probe for M97, calm areas that hold — "Spoiling a returned-to calm area is not
## consistently effective" (playtest 20: "the spoilage of a calm area is not always effective I
## went to the same park 4 times and only the last time had a high enough density of events to
## actually prevent me from using it"). Not a suite: it prints rather than asserting, so it lives
## here under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m97_spoilage.gd
##
## Reproduces a "day N settle in a park, day N+1 spoils it" visit directly against
## `EventScheduler`, across many seeds, sample settle-days (one per act) and every calm block a
## seed's city has at the time. For each visit it measures two things separately, because the
## TODO item names two different candidate causes and this is how to tell them apart:
##
## 1. **The spoil roll alone** — `EventScheduler._spoil_the_parks_she_used` called on its own,
##    the way the "roll" telemetry line ("<ids> in the park she used yesterday, <tile>") reports
##    it. Its own count and how much of the park's open ground it actually denies.
## 2. **The full day's plan** — `EventScheduler.build_day` with the same park as `used_calm`,
##    filtered to whatever reaches the park the way `_ensure_one_usable_park` already asks the
##    question (`_reaches_rect`). This is what a player actually meets, which can be *more* than
##    the roll alone placed: the visited park is not protected from the day's ordinary fill the
##    way an unvisited one is (`_calm_to_leave_alone` only lists calm blocks not in `used_calm`).
##
## "Denies" is read the way `_denial_radius` defines it: a tile is denied if it is within the
## radius at which the source's field still outpaces the calm-ground decay, not merely within its
## outer radius. The fraction of a park's open tiles NOT denied is the walkable edge playtest 20
## described ("I could just walk at the edge of it").

const SEEDS := 8
const BASE_SEED := 419070
## The day she is imagined to have settled — one per act (`Tuning.ACT_START_DAYS` is
## `[1, 4, 8, 12]`) — so the visit the next day is checked once in each act's own catalogue and
## crowd conditions. The spoiled day is settle-day + 1.
const SETTLE_DAYS: Array[int] = [1, 4, 8, 12]

func run(t) -> void:
	_reproduce_zero_density_visits()
	t.check(true, "zz_m97_spoilage probe ran")

func _reproduce_zero_density_visits() -> void:
	print("\n== M97 spoilage: day-N settle, day-N+1 roll and full-day density, %d seeds x settle-days %s x every calm block =="
			% [SEEDS, SETTLE_DAYS])

	var trials := 0
	var not_calm_count := 0
	var open_empty_count := 0
	var pool_empty_count := 0

	var roll_counts: Array[int] = []
	var full_counts: Array[int] = []
	var roll_denied: Array[float] = []
	var full_denied: Array[float] = []

	var zero_examples: Array[String] = []
	var low_examples: Array[String] = []
	const MAX_EXAMPLES := 6

	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 31)
		for settle_day: int in SETTLE_DAYS:
			var day: int = settle_day + 1
			if day > Tuning.RUN_LENGTH_DAYS:
				continue

			# The city as it was the day she settled, to get the list of parks she could have
			# used that day — a fresh CityState per sampled day, the same shape `m64_density.gd`
			# and `m64_measure.gd` use, since `begin_day` replays every scheduled step up to the
			# day asked for rather than requiring the days in between.
			var settle_state := CityState.new()
			settle_state.begin_day(map.block_plans, settle_day)
			map.repaint(settle_state)
			var candidates := map.calm_blocks.duplicate()

			# The city as it is the next day, when the roll fires.
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			map.repaint(state)
			var tree := RouteTree.for_day(map, day)

			for block: Vector2i in candidates:
				trials += 1
				var lot_tiles := EventScheduler._calm_rect(map, block)
				var lot_world := map.tile_rect_to_world(lot_tiles)
				var open_tiles: Array[Vector2i] = []
				for tile in map.rect_tiles(lot_tiles):
					if not map.is_closed(tile):
						open_tiles.append(tile)

				var still_calm := block in map.calm_blocks
				if not still_calm:
					not_calm_count += 1
					continue
				if open_tiles.is_empty():
					open_empty_count += 1
					continue
				var pool := EventScheduler._things_to_put_in_a_park(day, lot_world, 0)
				if pool.is_empty():
					pool_empty_count += 1
					continue

				# 1. The roll alone, on its own RNG stream — an independent sample of what the
				# spoil mechanism by itself produces for this park.
				var roll_planned: Array[EventScheduler.Planned] = []
				var rng1 := RandomNumberGenerator.new()
				rng1.seed = hash("m97:roll:%d:%d:%d" % [map.seed_used, day, block.x * 100000 + block.y])
				EventScheduler._spoil_the_parks_she_used(day, rng1, map, roll_planned, [block], 0)
				var rc := roll_planned.size()
				roll_counts.append(rc)
				var rd := _tiles_denied_fraction(map, open_tiles, roll_planned)
				roll_denied.append(rd)

				# 2. The full day, exactly as `build_day` plans it with this park as `used_calm`,
				# filtered to whatever actually reaches the park — matching
				# `_ensure_one_usable_park`'s own question.
				var rng2 := RandomNumberGenerator.new()
				rng2.seed = hash("m97:full:%d:%d:%d" % [map.seed_used, day, block.x * 100000 + block.y])
				var full_planned: Array[EventScheduler.Planned] = EventScheduler.build_day(
						day, rng2, map, [], [], [block], tree, 0)
				var full_in_lot: Array[EventScheduler.Planned] = []
				for plan: EventScheduler.Planned in full_planned:
					if plan.def.kind == GameEnums.EventKind.AMBIENT or plan.permanent \
							or not plan.is_placed():
						continue
					if EventScheduler._reaches_rect(plan, lot_world):
						full_in_lot.append(plan)
				var fc := full_in_lot.size()
				full_counts.append(fc)
				var fd := _tiles_denied_fraction(map, open_tiles, full_in_lot)
				full_denied.append(fd)

				if fc == 0 and zero_examples.size() < MAX_EXAMPLES:
					zero_examples.append("  seed=%d day=%d block=%s: roll placed %d (denied %.0f%%), full day placed 0 (denied 0%%)"
							% [i, day, block, rc, rd * 100.0])
				elif fd < 0.34 and low_examples.size() < MAX_EXAMPLES:
					var ids: Array[String] = []
					for plan: EventScheduler.Planned in full_in_lot:
						ids.append(plan.def.id)
					low_examples.append("  seed=%d day=%d block=%s: %s in the park she used yesterday, %s — denied %.0f%% of open ground (roll alone: %d placed, denied %.0f%%)"
							% [i, day, block, ", ".join(ids), TelemetryLog.tile(block), fd * 100.0, rc, rd * 100.0])

	print("trials (seed x settle-day x calm block): %d" % trials)
	print("structurally zero — block no longer calm the next day: %d (%.1f%%)"
			% [not_calm_count, 100.0 * float(not_calm_count) / maxf(1.0, float(trials))])
	print("structurally zero — every lot tile closed: %d (%.1f%%)"
			% [open_empty_count, 100.0 * float(open_empty_count) / maxf(1.0, float(trials))])
	print("structurally zero — no eligible row for that day/heat: %d (%.1f%%)"
			% [pool_empty_count, 100.0 * float(pool_empty_count) / maxf(1.0, float(trials))])
	var valid := roll_counts.size()
	print("valid visits (calm, open, and a pool to draw from): %d" % valid)

	if valid > 0:
		print("\n-- the roll alone (Tuning.SPOILERS_TO_DENY_A_PARK = %d cells at most) --"
				% Tuning.SPOILERS_TO_DENY_A_PARK)
		_print_int_distribution("placements", roll_counts)
		_print_float_distribution("open ground denied", roll_denied)

		print("\n-- the full day's plan, filtered to whatever reaches the park --")
		_print_int_distribution("placements", full_counts)
		_print_float_distribution("open ground denied", full_denied)

		var zero_roll := 0
		var zero_full := 0
		var full_gt_roll := 0
		for idx in valid:
			if roll_counts[idx] == 0:
				zero_roll += 1
			if full_counts[idx] == 0:
				zero_full += 1
			if full_counts[idx] > roll_counts[idx]:
				full_gt_roll += 1
		print("\nzero placements from the roll alone: %d of %d (%.1f%%)"
				% [zero_roll, valid, 100.0 * float(zero_roll) / float(valid)])
		print("zero placements in the full day (what she actually meets): %d of %d (%.1f%%)"
				% [zero_full, valid, 100.0 * float(zero_full) / float(valid)])
		print("visits where the full day placed MORE than the roll alone (incidental fill landed"
				+ " in the park too, since a used park is not protected from it): %d of %d (%.1f%%)"
				% [full_gt_roll, valid, 100.0 * float(full_gt_roll) / float(valid)])

	if not zero_examples.is_empty():
		print("\n-- examples: full day placed nothing despite calm ground, open tiles and an eligible pool --")
		for line in zero_examples:
			print(line)
	if not low_examples.is_empty():
		print("\n-- examples: full day denied under a third of the open ground (a walkable edge remains) --")
		for line in low_examples:
			print(line)

## The fraction of `open_tiles` within `EventScheduler._denial_radius` of at least one placed
## plan — the same question `_denial_radius`'s own doc states: not the outer radius, the radius at
## which the source still outpaces the calm-ground decay. Everything in `plans` is stationary
## (`_things_to_put_in_a_park` excludes `mobile`), so a point-to-position distance is exact rather
## than an approximation of a route.
func _tiles_denied_fraction(map: CityMap, open_tiles: Array[Vector2i],
		plans: Array[EventScheduler.Planned]) -> float:
	if open_tiles.is_empty():
		return 1.0
	if plans.is_empty():
		return 0.0
	var denied := 0
	for tile in open_tiles:
		var world := map.tile_to_world(tile)
		var is_denied := false
		for plan: EventScheduler.Planned in plans:
			if not plan.is_placed():
				continue
			if world.distance_to(plan.position) <= EventScheduler._denial_radius(plan.def):
				is_denied = true
				break
		if is_denied:
			denied += 1
	return float(denied) / float(open_tiles.size())

func _print_int_distribution(label: String, values: Array[int]) -> void:
	if values.is_empty():
		print("  %s: no valid visits" % label)
		return
	var total := 0
	var lo := values[0]
	var hi := values[0]
	var zeros := 0
	for v in values:
		total += v
		lo = mini(lo, v)
		hi = maxi(hi, v)
		if v == 0:
			zeros += 1
	print("  %s: mean=%.2f min=%d max=%d zero=%d of %d (%.1f%%)"
			% [label, float(total) / float(values.size()), lo, hi, zeros, values.size(),
			100.0 * float(zeros) / float(values.size())])

func _print_float_distribution(label: String, values: Array[float]) -> void:
	if values.is_empty():
		print("  %s: no valid visits" % label)
		return
	var buckets := [0, 0, 0, 0]   # 0-10%, 10-33%, 33-66%, 66-100%
	var total := 0.0
	for v in values:
		total += v
		if v < 0.10:
			buckets[0] += 1
		elif v < 0.34:
			buckets[1] += 1
		elif v < 0.67:
			buckets[2] += 1
		else:
			buckets[3] += 1
	print("  %s: mean=%.1f%% buckets under10%%=%d 10-33%%=%d 33-66%%=%d over66%%=%d (of %d)"
			% [label, 100.0 * total / float(values.size()), buckets[0], buckets[1], buckets[2],
			buckets[3], values.size()])
