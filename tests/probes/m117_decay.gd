extends RefCounted
## What the meter actually does on each kind of ground, walked rather than derived. Not a suite:
## it prints numbers rather than asserting relationships, so it lives under `tests/probes/`, where
## the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m117_decay.gd
##
## The question is the one the decay constants are set from: **with the day's own crowd on the
## street and nothing authored in range, how fast does the bar fall while she walks?** That is a
## *net* rate — what the crowd loads minus what the ground gives back — and it is not derivable
## from `Tuning` alone, because the crowd half is emergent. `tests/test_crowd.gd`'s floor
## machinery is the instrument: a real generated `City`, the crowd focused where she is, stepped a
## whole frame at a time.
##
## Two things it measures that a standing floor cannot. The walk **moves the crowd's field with
## her**, which is what the crowd is a population of, and it **crosses junctions**, so the mean is
## over the ground a route is actually made of rather than over one lucky tile.
##
## The second half prints the cost table in `docs/EVENTS.md`, "What an event actually costs", from
## `EventDef.walk_through_cost()` — the same function the game asks for the danger caret and the
## same one `tests/test_events.gd` integrates, so the table cannot drift from either. Regenerate
## it from here whenever a rate in `Tuning` moves.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0
const SECONDS := 40.0
## Three cities rather than one: "the quietest pavement" is whichever corridor a seed happened to
## make quietest, and a rate read off a single city is a fact about that city.
const SEEDS := [4242, 90210, 1337]
const SAMPLE_DAYS := [1, 9]

func run(t) -> void:
	_ground_rates(t)
	_cost_table()
	t.check(true, "m117 decay probe ran")

# ------------------------------------------------------------------ ground rates ---

func _ground_rates(t) -> void:
	print("\n== net excitement rate by ground, %.0fs walks, %d seeds ==" % [SECONDS, SEEDS.size()])
	print("walking decay %.2f/s  ×  calm %.2f  precinct %.2f  street 1.00  main road %.2f"
			% [Tuning.EXCITEMENT_DECAY_WALKING, Tuning.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER,
			Tuning.EXCITEMENT_DECAY_PRECINCT_MULTIPLIER,
			Tuning.EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER])
	print("alley trickle %.2f/s" % Tuning.EXCITEMENT_FROM_ALLEY)

	for day in SAMPLE_DAYS:
		var totals := {}
		var counts := {}
		print("\n-- day %d (act %d) --" % [day, Tuning.act_for_day(day)])
		print("  %-16s %8s %8s %8s %10s %8s  %s"
				% ["ground", "crowd/s", "ground/s", "net/s", "clears in", "×", "seed"])
		for city_seed in SEEDS:
			var city: City = CITY_SCENE.instantiate()
			t.add_child(city)
			city.build(CityGenerator.generate(city_seed))
			for row in _legs(city):
				var name: String = row["name"]
				var result := _walk(city, row["from"], row["to"], day, city_seed)
				_print_row(name, result, city_seed)
				totals[name] = float(totals.get(name, 0.0)) + result["net"]
				counts[name] = int(counts.get(name, 0)) + 1
			city.free()
		print("  -- means --")
		for name in totals:
			var mean: float = totals[name] / maxf(1.0, float(counts[name]))
			print("  %-16s %8s %8s %8.2f %10s"
					% [name, "", "", mean, _clears_in(mean)])

## The five grounds, as a start and an end point she walks between. Each leg is a straight line she
## paces back and forth along for the whole measurement, which keeps her on the ground the row is
## about — a park is 704px across and forty seconds of walking is 3,680.
func _legs(city: City) -> Array:
	var map := city.map
	var legs: Array = []
	var height := float(map.size.y) * Tuning.TILE_SIZE

	var quiet := CrowdLanes.quietest_pavement(map)
	legs.append({"name": "quiet pavement", "from": Vector2(quiet.x, height * 0.3),
			"to": Vector2(quiet.x, height * 0.7)})

	var arterial := CrowdLanes.arterial_pavement(map)
	legs.append({"name": "main road", "from": Vector2(arterial.x, height * 0.3),
			"to": Vector2(arterial.x, height * 0.7)})

	var precinct := _precinct_leg(map)
	if precinct.size() == 2:
		legs.append({"name": "precinct", "from": precinct[0], "to": precinct[1]})

	var calm := _calm_leg(map)
	if calm.size() == 2:
		legs.append({"name": "calm", "from": calm[0], "to": calm[1]})

	var alley := _alley_leg(map)
	if alley.size() == 2:
		legs.append({"name": "alley", "from": alley[0], "to": alley[1]})

	return legs

## Walks the leg for `SECONDS`, turning round at each end, with the crowd's field following her.
##
## The net rate is summed **per sample from the ground she is actually on**, the same way
## `Baby._decay_rate()` asks it, rather than from one multiplier assumed for the whole leg: a walk
## down an ordinary corridor crosses junctions, and a mean taken against the wrong multiplier is
## the trap the balance skill names.
func _walk(city: City, from: Vector2, to: Vector2, day: int, city_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("m117:%d:%d" % [city_seed, day])
	var at := (from + to) * 0.5
	city.crowd.start_day(day, rng, at)

	var toward := to
	var crowd_total := 0.0
	var ground_total := 0.0
	var samples := 0
	var multipliers := {}
	for i in int(round(SECONDS / STEP)):
		var step := Tuning.WALK_SPEED * STEP
		var gap := at.distance_to(toward)
		if gap <= step:
			toward = from if toward == to else to
			gap = at.distance_to(toward)
		if gap > 0.0:
			at += (toward - at) / gap * step
		city.crowd.set_focus(at)
		city.crowd.step(STEP)

		var multiplier := city.decay_multiplier(at)
		var incoming := city.crowd.total_excitement_at(at)
		if city.is_alley(at):
			incoming += Tuning.EXCITEMENT_FROM_ALLEY
		crowd_total += incoming
		ground_total += Tuning.EXCITEMENT_DECAY_WALKING * multiplier
		var key := "%.2f" % multiplier
		multipliers[key] = int(multipliers.get(key, 0)) + 1
		samples += 1

	var divisor := maxf(1.0, float(samples))
	var crowd := crowd_total / divisor
	var ground := ground_total / divisor
	return {"crowd": crowd, "ground": ground, "net": crowd - ground,
			"multipliers": multipliers, "samples": samples}

func _print_row(name: String, result: Dictionary, city_seed: int) -> void:
	print("  %-16s %8.2f %8.2f %8.2f %10s %8s  %d"
			% [name, result["crowd"], result["ground"], result["net"],
			_clears_in(result["net"]), _dominant_multiplier(result["multipliers"]), city_seed])

## How long a full meter takes to leave the bar at this net rate, which is the sentence the player's
## instruction is written in — "excitement should go visibly down".
func _clears_in(net: float) -> String:
	if net >= 0.0:
		return "never"
	return "%.1fs" % (Tuning.METER_MAX / -net)

## The multiplier the walk spent most of its samples on, with the share, so a leg that wandered off
## its own ground says so instead of averaging quietly.
func _dominant_multiplier(multipliers: Dictionary) -> String:
	var best := ""
	var best_count := 0
	var total := 0
	for key in multipliers:
		total += int(multipliers[key])
		if int(multipliers[key]) > best_count:
			best_count = int(multipliers[key])
			best = key
	return "%s/%d%%" % [best, int(round(100.0 * float(best_count) / maxf(1.0, float(total))))]

# ---------------------------------------------------------------- finding a leg ---

## A line along whichever precinct this city put inland, taken down the middle of its corridor.
func _precinct_leg(map: CityMap) -> Array:
	if map.precinct_spans.is_empty():
		return []
	var span: Vector4i = map.precinct_spans[map.precinct_spans.size() - 1]
	var vertical := span.x == 1
	var across := span.y * CityMap.period() + Tuning.STREET_WIDTH / 2
	var from_along := span.z * CityMap.period() + Tuning.STREET_WIDTH
	var to_along := span.w * CityMap.period() + Tuning.STREET_WIDTH
	var from := Vector2i(across, from_along) if vertical else Vector2i(from_along, across)
	var to := Vector2i(across, to_along) if vertical else Vector2i(to_along, across)
	return [map.tile_to_world(from), map.tile_to_world(to)]

## A diagonal across the largest calm block, so the walk stays on grass while it paces.
func _calm_leg(map: CityMap) -> Array:
	if map.calm_blocks.is_empty():
		return []
	var rect := CityMap.block_rect(map.calm_blocks[0])
	var from := map.tile_to_world(rect.position + Vector2i.ONE)
	var to := map.tile_to_world(rect.position + rect.size - Vector2i.ONE * 2)
	return [from, to]

## The longest straight run of alley tiles this city has, found by walking the grid rather than by
## guessing at the layout: an alley is cut where a block plan wanted one, not at a fixed place.
func _alley_leg(map: CityMap) -> Array:
	var best_from := Vector2i(-1, -1)
	var best_to := Vector2i(-1, -1)
	var best_length := 0
	for y in map.size.y:
		var run_start := -1
		for x in map.size.x + 1:
			var alley := x < map.size.x \
					and Tile.is_alley(map.tile_at(Vector2i(x, y)))
			if alley and run_start < 0:
				run_start = x
			elif not alley and run_start >= 0:
				if x - run_start > best_length:
					best_length = x - run_start
					best_from = Vector2i(run_start, y)
					best_to = Vector2i(x - 1, y)
				run_start = -1
	for x in map.size.x:
		var run_start := -1
		for y in map.size.y + 1:
			var alley := y < map.size.y \
					and Tile.is_alley(map.tile_at(Vector2i(x, y)))
			if alley and run_start < 0:
				run_start = y
			elif not alley and run_start >= 0:
				if y - run_start > best_length:
					best_length = y - run_start
					best_from = Vector2i(x, run_start)
					best_to = Vector2i(x, y - 1)
				run_start = -1
	if best_length == 0:
		return []
	return [map.tile_to_world(best_from), map.tile_to_world(best_to)]

# ------------------------------------------------------------------ the cost table ---

## The `docs/EVENTS.md` cost table, sorted the way the document keeps it. `walk_through_cost()` and
## the running integral both net off a decay constant, so both columns move whenever the walking or
## the running rate does — which is the whole reason this is regenerated rather than remembered.
func _cost_table() -> void:
	print("\n== docs/EVENTS.md, \"What an event actually costs\" ==")
	print("walking decay %.2f/s, running decay %.2f/s, running penalty %.2f/s"
			% [Tuning.EXCITEMENT_DECAY_WALKING, Tuning.EXCITEMENT_DECAY_RUNNING,
			Tuning.EXCITEMENT_FROM_RUNNING])
	var rows: Array = []
	for def in EventCatalogue.all():
		rows.append({"id": def.id, "walk": def.walk_through_cost(),
				"run": _run_through_cost(def), "city_wide": def.city_wide,
				"hard_fail": def.hard_fail, "flock": def.flock_size > 1,
				"pursues": def.pursues, "emission": def.mean_emission_along_the_line(),
				"intensity": def.intensity, "outer": def.outer_radius})
	# City-wide rows first, the way the document keeps them: they have no line through them, so
	# `walk_through_cost()` answers zero for them and sorting on that number would file them among
	# the rows that genuinely cost nothing.
	rows.sort_custom(func(a, b):
		if a["city_wide"] != b["city_wide"]:
			return a["city_wide"]
		return a["walk"] < b["walk"])
	print("| Event | walk through | run through |")
	print("| --- | ---: | ---: |")
	for row in rows:
		var mark := ""
		if row["hard_fail"]:
			mark = " *"
		elif row["flock"]:
			mark = " †"
		var walk := "—" if row["city_wide"] else "%+.1f" % row["walk"]
		var run := "—" if row["city_wide"] or row["pursues"] else "%+.1f" % row["run"]
		print("| `%s`%s | %s | %s |" % [row["id"], mark, walk, run])

	# What the table above is *made* of, and the column a decay change is read against. A row is
	# more expensive to walk through than around exactly while its mean emission along the line
	# out-emits the walking decay on the ground it stands on, so this is the number that says which
	# rows a change to that decay would turn free — `walk` is that comparison already taken.
	print("\n-- mean emission along the line, against a candidate walking decay --")
	print("  %-20s %9s %9s %9s %9s" % ["event", "emission", "intensity", "outer", "walk@now"])
	for row in rows:
		if row["city_wide"]:
			continue
		print("  %-20s %9.2f %9.2f %9.0f %9.1f"
				% [row["id"], row["emission"], row["intensity"], row["outer"], row["walk"]])

## The same integral at running pace, with the running penalty in place of the walking decay —
## `tests/test_events.gd._cost_to_run_through`, which is where the assertion lives.
func _run_through_cost(def: EventDef) -> float:
	var seconds := def.outer_radius * 2.0 / Tuning.RUN_SPEED
	return (def.mean_emission_along_the_line() - Tuning.EXCITEMENT_DECAY_RUNNING
			+ Tuning.EXCITEMENT_FROM_RUNNING) * seconds
