extends RefCounted
## What `playground` and `busker` actually cost on real, generated parks, printed rather than
## asserted. Not a suite: it lives under `tests/probes/`, where the runner never discovers it,
## and runs only by name:
##
##     tools/test.sh probes/m128_park_beats.gd
##
## M128 asked for two things the cost table alone cannot answer: whether a one-block park with a
## playground in it has anywhere to settle, and how far a busker's field actually reaches onto
## the street beside its lot. Both are geometric questions about a real city rather than about
## `Tuning` in isolation, so this builds real maps with `CityGenerator` and real days with
## `EventScheduler.build_day()` rather than reasoning about the numbers on paper.
##
## The M117 numbers are kept here as constants purely so the busker's before-and-after prints
## side by side; nothing in the game reads them any more.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS := [4242, 90210, 1337]
const BUSKER_DAY := 2  # `busker.first_day`.

const OLD_BUSKER_INTENSITY := 13.0
const OLD_BUSKER_INNER := 45.0
const OLD_BUSKER_OUTER := 190.0

const _SIDEWALK_SEARCH_STEP := 8.0
const _SIDEWALK_SEARCH_MAX := 400.0

func run(t) -> void:
	_busker_never_fills_the_day(t)
	_busker_denial_and_inner_floor(t)
	_busker_street_side(t)
	_playground_settles(t)
	t.check(true, "m128 park-beats probe ran")

# --------------------------------------------------------------- sleep over a whole day ---

## `DAY_LENGTH_SECONDS` (210s, `busker.first_day` is day 2, an ordinary day) plus a 20s margin so
## a chosen intensity does not sit exactly on the line — see the sweep below.
const _SLEEP_CAP_SECONDS := 230.0
const _SWEEP_STEP := 0.1
const _SWEEP_TOP := 19.5  # The floor `_busker_denial_and_inner_floor` found; never exceeded.

## **The beat-mean question and "can she fall asleep here" are different questions.**
## `Baby._update_sleepiness()` only fills the sleep meter while excitement is under
## `EXCITEMENT_CALM_THRESHOLD`, at whatever rate the calm ground's own lot size sets
## (`Tuning.sleepiness_calm_multiplier()` — 42x for a one-block lot, the loudest of the three), and
## is otherwise frozen while awake, never given back. A dip under the threshold lasting a few
## tenths of a second, repeated every seven-second beat for a whole day, is worth far more than the
## beat's own average net rate suggests — so this asks the real question directly, with `Baby`'s
## own update functions (`_physics_process`, which calls `_update_excitement`/`_update_sleepiness`)
## and a real `EventInstance` for the busker, rather than a hand-derived rate.
##
## **One busker, alone, at the centre of a real one-block `PARK` block.** No crowd
## (`Crowd.start_day()` is never called, so `_agents` stays empty) and no other event
## (`city.events` never plans a day; the one instance under test is the only body appended to
## `_instances`) — so the only two things she is standing between are this one field and the
## ground's own 12.0/s. The rig stands exactly `inner_radius` from the busker's own centre,
## starting at `EXCITEMENT_CALM_THRESHOLD` with an empty sleep meter, matching the question
## exactly as asked. The instance is stepped past its own `telegraph_time` before she "arrives",
## since a busker that has been playing all morning has no telegraph left by the time anyone
## walks up to him.
func _busker_never_fills_the_day(t) -> void:
	var found := _find_one_block_park()
	if found.is_empty():
		print("\n== no one-block PARK found across seeds %s; skipped ==" % [SEEDS])
		return
	var map: CityMap = found["map"]
	var block: Vector2i = found["block"]
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(map)

	var busker_at: Vector2 = map.tile_rect_to_world(CityMap.block_rect(block)).get_center()
	var real := EventCatalogue.by_id("busker")
	var standing_at := busker_at + Vector2(real.inner_radius, 0.0)

	print("\n== time to a full sleep meter, standing at inner_radius from the busker's own core ==")
	print(("one-block PARK, starting excitement %.0f, sleepiness 0, capped at %.0fs "
			+ "(day length %.0fs plus a margin)")
			% [Tuning.EXCITEMENT_CALM_THRESHOLD, _SLEEP_CAP_SECONDS, Tuning.DAY_LENGTH_SECONDS])

	var chosen := -1.0
	var intensity := OLD_BUSKER_INTENSITY
	while intensity <= _SWEEP_TOP + 0.001:
		var filled_at := _time_to_full_sleep(t, city, busker_at, standing_at, real, intensity)
		print("intensity %.1f -> %s" % [intensity,
				("filled at %.1fs" % filled_at) if filled_at >= 0.0
				else "never (capped the run at %.0fs)" % _SLEEP_CAP_SECONDS])
		if chosen < 0.0 and filled_at < 0.0:
			chosen = intensity
		intensity += _SWEEP_STEP

	if chosen < 0.0:
		print(("no intensity up to %.1f keeps the sleep meter from filling within %.0fs — "
				+ "stopping at %.1f, the floor `_busker_denial_and_inner_floor` found, rather "
				+ "than exceeding it") % [_SWEEP_TOP, _SLEEP_CAP_SECONDS, _SWEEP_TOP])
		t.check(true, "no intensity under the beat-mean floor keeps a whole day from filling")
	else:
		print("chosen: %.1f — the lowest tested value whose day never fills within %.0fs"
				% [chosen, _SLEEP_CAP_SECONDS])
		var chosen_fill := _time_to_full_sleep(t, city, busker_at, standing_at, real, chosen)
		t.check(chosen_fill < 0.0,
				("the chosen intensity (%.1f) does not fill a sleep meter standing at his core for "
				+ "a whole day (%.0fs, capped at %.0fs)")
				% [chosen, Tuning.DAY_LENGTH_SECONDS, _SLEEP_CAP_SECONDS])

## The first `PARK`-purpose block, exactly one block to its lot, found across `SEEDS` — or an
## empty dictionary if none of them rolled one. `{}` rather than `null` because GDScript cannot
## type a dictionary-or-null return without a Variant, and an empty check reads the same either way.
func _find_one_block_park() -> Dictionary:
	for city_seed in SEEDS:
		var map := CityGenerator.generate(city_seed)
		for block in map.calm_blocks:
			if map.starting_purpose(map.anchor_of(block)) == GameEnums.BlockPurpose.PARK \
					and map.calm_lot_blocks(block) == 1:
				return {"map": map, "block": block}
	return {}

## One busker, alone, standing trial at `intensity` for up to `_SLEEP_CAP_SECONDS`. Returns the
## second the sleep meter filled, or `-1.0` if it never did.
func _time_to_full_sleep(t, city: City, busker_at: Vector2, standing_at: Vector2,
		real: EventDef, intensity: float) -> float:
	# A fresh `EventDef`, not the catalogue's own, so the sweep never has to mutate and restore the
	# live row — only `intensity` varies; everything else is read off the real def so the two can
	# never quietly drift apart.
	var def := EventDef.new()
	def.id = "busker"
	def.intensity = intensity
	def.inner_radius = real.inner_radius
	def.outer_radius = real.outer_radius
	def.pulse_period = real.pulse_period
	def.telegraph_time = real.telegraph_time

	var instance := EventInstance.new()
	instance.setup(def, busker_at)
	t.add_child(instance)
	instance.set_process(false)
	city.events._instances.append(instance)

	var step := 1.0 / 60.0
	var warm_up := int(ceil((def.telegraph_time + 0.1) / step))
	for i in warm_up:
		instance._process(step)

	var stroller := Stroller.new()
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	stroller.add_child(camera)
	t.add_child(stroller)
	stroller.set_physics_process(false)
	stroller.global_position = standing_at
	stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
	var baby := Baby.new()
	baby.name = "Baby"
	stroller.add_child(baby)
	baby.set_physics_process(false)
	baby.excitement = Tuning.EXCITEMENT_CALM_THRESHOLD
	baby.sleepiness = 0.0

	var result := -1.0
	var elapsed := 0.0
	while elapsed < _SLEEP_CAP_SECONDS:
		instance._process(step)
		baby._physics_process(step)
		elapsed += step
		if baby.sleepiness >= Tuning.METER_MAX:
			result = elapsed
			break

	city.events._instances.erase(instance)
	stroller.free()
	instance.free()
	return result

# ------------------------------------------------------------- denial radius, inner floor ---

## Diagnostic rather than the governing floor — see `_busker_never_fills_the_day` above for the
## question that actually decided the number, and its own doc comment for why the two disagree:
## a beat that averages flat can still fill a whole day's sleep meter, because sleepiness fills
## in bursts gated by a threshold rather than following the average continuously.

## The pulse's own shape, replicated from `EventInstance.current_intensity()`: a quarter of
## `intensity` at the bottom of the beat, all of it at the top.
func _pulse_multiplier(phase: float) -> float:
	return 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))

## The multiplier's mean over one full period, integrated numerically rather than assumed — a
## hand-derived constant is exactly the kind of thing that goes stale silently if the pulse shape
## ever changes. A peak-only floor (clearing the ground's decay only at the top of the beat) is not
## the same claim as "the meter does not come down over a whole beat": the pulse spends most of a
## cycle well under its peak, so the two floors sit at different intensities entirely.
func _pulse_mean_multiplier() -> float:
	var steps := 10000
	var total := 0.0
	for i in steps:
		var phase := TAU * (float(i) + 0.5) / float(steps)
		total += _pulse_multiplier(phase)
	return total / float(steps)

## `EventScheduler._denial_radius` reads live off `EventCatalogue`, so "after" is asked of the
## real def; "before" is the same formula asked of the M117 numbers, kept as constants above.
func _busker_denial_and_inner_floor(t) -> void:
	var def := EventCatalogue.by_id("busker")
	var before_denial := _denial_radius(OLD_BUSKER_INTENSITY, OLD_BUSKER_INNER, OLD_BUSKER_OUTER)
	var after_denial := EventScheduler._denial_radius(def)

	print("\n== busker denial radius (Tuning.CALM_ZONE_DENIAL_RATE = %.1f/s) =="
			% Tuning.CALM_ZONE_DENIAL_RATE)
	print("before: intensity %.1f, inner %.0fpx, outer %.0fpx -> %.1fpx"
			% [OLD_BUSKER_INTENSITY, OLD_BUSKER_INNER, OLD_BUSKER_OUTER, before_denial])
	print("after:  intensity %.1f, inner %.0fpx, outer %.0fpx -> %.1fpx"
			% [def.intensity, def.inner_radius, def.outer_radius, after_denial])

	# The floor stated over a whole beat, not just its peak: standing at (or inside) inner_radius,
	# the meter must not trend down over a full pulse cycle. `mean_multiplier` (0.625 for this
	# pulse shape) is what a peak-only floor missed — a row cleared only at the top of its beat
	# still nets negative on average, because the beat spends more of its seven seconds below the
	# peak than at it.
	var calm_decay := Tuning.EXCITEMENT_DECAY_WALKING * Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER
	var mean_multiplier := _pulse_mean_multiplier()
	print("\n== net rate at inner_radius on grass, over a whole beat (must not trend down) ==")
	print("calm ground gives back %.2f/s; the beat's own mean multiplier is %.4f"
			% [calm_decay, mean_multiplier])
	for row in [
		{"label": "before", "intensity": OLD_BUSKER_INTENSITY},
		{"label": "after", "intensity": def.intensity},
	]:
		var intensity: float = row["intensity"]
		var top: float = intensity * 1.0 - calm_decay
		var bottom: float = intensity * 0.25 - calm_decay
		var average: float = intensity * mean_multiplier - calm_decay
		print("%s: intensity %.1f -> top %+.3f/s, bottom %+.3f/s, mean over the beat %+.4f/s"
				% [row["label"], intensity, top, bottom, average])
	t.check(true, "beat-mean and denial radius measured (see above and _busker_never_fills_the_day)")

func _denial_radius(intensity: float, inner: float, outer: float) -> float:
	var decay := Tuning.CALM_ZONE_DENIAL_RATE
	if intensity <= decay:
		return inner
	var frac := sqrt(1.0 - decay / intensity)
	return inner + frac * (outer - inner)

# --------------------------------------------------------------------- street-side reach ---

## Every busker `EventScheduler.build_day()` actually places on day `BUSKER_DAY`, across several
## seeds, measured by how far its own siting sits from the nearest sidewalk tile — the real
## distance its field has to clear to be felt from the street, rather than a distance assumed
## from the lot's nominal size. `emission_at()` is the peak, undamped reading (the top of the
## beat), which is the worst case a passer-by meets.
func _busker_street_side(t) -> void:
	print("\n== busker contribution on the pavement beside its lot, top of the beat ==")
	print("  %-8s %10s %10s %10s %10s" % ["seed", "to street", "before", "after", "ratio"])
	# A plain `EventDef`, not the catalogue's own — `emission_at()` only reads `intensity`,
	# `inner_radius`, `outer_radius` and `flock_size` (0 by default), so this is the M117 busker
	# in every field the comparison cares about.
	var before_def := EventDef.new()
	before_def.intensity = OLD_BUSKER_INTENSITY
	before_def.inner_radius = OLD_BUSKER_INNER
	before_def.outer_radius = OLD_BUSKER_OUTER
	var after_def := EventCatalogue.by_id("busker")
	var samples := 0
	var before_total := 0.0
	var after_total := 0.0
	for city_seed in SEEDS:
		var map := CityGenerator.generate(city_seed)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("m128:%d" % city_seed)
		var no_one_shots: Array[String] = []
		var planned := EventScheduler.build_day(BUSKER_DAY, rng, map, no_one_shots)
		for plan in planned:
			if plan.def.id != "busker":
				continue
			var to_street := _distance_to_sidewalk(map, plan.position)
			if to_street == INF:
				continue
			var before := before_def.emission_at(Vector2(to_street, 0.0))
			var after := after_def.emission_at(Vector2(to_street, 0.0))
			print("  %-8d %9.1fpx %10.2f %10.2f %9.2f%%"
					% [city_seed, to_street, before, after,
					100.0 * after / maxf(before, 0.001)])
			before_total += before
			after_total += after
			samples += 1
	if samples > 0:
		print("  -- mean over %d busker(s) --  before %.2f  after %.2f  (%.1f%% of before)"
				% [samples, before_total / samples, after_total / samples,
				100.0 * after_total / maxf(before_total, 0.001)])
	t.check(samples > 0, "at least one busker was placed to measure (day %d, %d seeds)"
			% [BUSKER_DAY, SEEDS.size()])

## The straight-line distance from `from` to the nearest sidewalk tile, searched along the four
## cardinal rays a street actually runs along in this city's lattice — the same shape every leg in
## `m117_decay.gd` walks. `INF` if none of the four rays finds one within a block's own depth.
func _distance_to_sidewalk(map: CityMap, from: Vector2) -> float:
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	var best := INF
	for direction in directions:
		var travelled := 0.0
		while travelled < _SIDEWALK_SEARCH_MAX:
			travelled += _SIDEWALK_SEARCH_STEP
			var at: Vector2 = from + direction * travelled
			if map.tile_type_at_world(at) == GameEnums.TileType.SIDEWALK:
				best = minf(best, travelled)
				break
	return best

# -------------------------------------------------------------------------- the playground ---

## Every playground this city has, standing exactly at its own centre — where `_place_ambient`
## puts the ambient source, and so the worst point in the park for it. `_walk_until_asleep` is
## `tests/test_balance.gd`'s own rig, duplicated here rather than shared because a probe under
## `tests/probes/` is not discovered by anything that could import it as a dependency.
func _playground_settles(t) -> void:
	print("\n== a one-block park with a playground in it: can she settle at its own centre? ==")
	var step := 1.0 / 60.0
	for city_seed in SEEDS:
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(city_seed))
		var consumed: Array[String] = []
		city.events.start_day(1, _rng(city_seed), consumed)
		for rect in city.map.playgrounds:
			var at: Vector2 = city.map.tile_rect_to_world(rect).get_center()
			city.events.stream_around(at)
			city.crowd.start_day(1, _rng(city_seed), at)
			var stroller := Stroller.new()
			var camera := Camera2D.new()
			camera.name = "Camera2D"
			stroller.add_child(camera)
			t.add_child(stroller)
			stroller.set_physics_process(false)
			stroller.global_position = at
			stroller.velocity = Vector2(Tuning.WALK_SPEED, 0.0)
			var baby := Baby.new()
			stroller.add_child(baby)
			baby.set_physics_process(false)

			var settled := -1.0
			var duration := Tuning.day_length(1)
			for i in int(round(duration / step)):
				city.crowd.step(step)
				for instance in city.events.instances():
					if not instance.is_finished:
						instance._process(step)
				baby._physics_process(step)
				if baby.state == GameEnums.BabyState.ASLEEP:
					settled = i * step
					break
			print("  seed %-8d settled: %s" % [city_seed,
					("%.0fs" % settled) if settled > 0.0 else "never"])
			stroller.free()
		city.free()

func _rng(city_seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m128:%d" % city_seed)
	return rng
