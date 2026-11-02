extends RefCounted
## Measurement probe for whether the escape's city section can be got through, and what its
## marble bag (`DaySpec.bag`) stands on its streets *(inbox #794 in minty-lemur: "make escape
## winnable with minimal changes (fixing event distribution in some cheap way)")*. Not a suite: it
## prints a table rather than asserting, so it lives under `tests/probes/` and runs only by name:
##
##     tools/test.sh probes/escape_winnable.gd          (prints ESCAPE_WINNABLE lines)
##
## `ESCAPE_WINNABLE_SEEDS` (comma-separated run seeds) and `ESCAPE_WINNABLE_MIX` (see `MIXES`)
## replace the seeds and the mixes; `ESCAPE_WINNABLE_WALK` set to `0` leaves the walking out and
## prints the plans alone; `ESCAPE_WINNABLE_PARALLEL` sets how many walks run at once
## (`PARALLEL`).
##
## **What it measures, per seed.** The section's plan as a straight city boot builds it
## (`--start-escape city`: `GameState.start_run(seed)`, the city built from the run seed, the plan
## drawn from `GameState.calendar.day_rng(day, "finale")` under the city section's spec, as
## `main._plan_the_finale_city()` draws it): how many of the escape's four rows stand on its open
## streets and how many streets stand none, for every mix. **And for the game's own bag, the game
## walking it**: one headless run of the real game per exit, booted `--start-escape city --seed
## <seed> --route tunnel|bridge --no-save --no-title`, in which `RouteRig` (`src/dev/route_rig.gd`)
## walks her from the service exit to that exit through the real city, its events, her real
## `Stroller` and `Baby`, their collisions and the meter, at walking pace from the sleeping baby a
## section starts with, with the section's own clock. Its run log says how the section ended and
## when (`RouteRig`'s `route` lines).
##
## **What the walker does, and what it does not.** It plans the cheapest walk off every live
## hazard's own kill reach and the carriageway, re-planning as the street changes and working
## itself free when a body holds it (see `RouteRig`'s class doc). It does not play the lure at a
## roadblock, settle the baby on calm ground or wait for a van to drive off, so what it measures is
## one plain walker's answer, not a player's: a walk it loses may still be one a player wins.
##
## **Why the mixes are planned and not walked.** The game boots its own bag, the city section's
## spec; a mix other than that one has no boot to walk it in, so the mixes are compared on what
## they stand and the game's own bag is the one walked.

const CITY_SCENE := preload("res://scenes/world/city.tscn")

## Twenty-four run seeds: `tests/test_finale.gd`'s own four, the probe seeds the escape's other
## probes use, the seed the player could not win (inbox #771 in minty-lemur), and small primes.
const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808, 4216201080, 11, 13, 17,
		19, 29, 31, 37, 41, 43, 47, 53, 59, 61]
const ROWS: Array[String] = ["military_convoy", "finale_explosion", "abduction", "roadblock"]
## The mixes planned: `slots` a street and the bag's marbles, trucks, explosions, vans, roadblocks
## and empty, in the player's order. `as built` is the city section's own spec, through
## `DayPlanner.plan_the_escape_city()` exactly as the game plans it, and the one walked; the others are the
## candidates it was chosen against, and the last stands nothing at all. `ESCAPE_WINNABLE_MIX`
## replaces the list, as `as built` or `<slots>:<trucks>,<explosions>,<vans>,<roadblocks>,<empty>`
## mixes separated by `;`.
const MIXES: Array[Dictionary] = [
	{"name": "as built"},
	{"name": "1:5,4,3,2,1", "slots": 1, "counts": [5, 4, 3, 2, 1]},
	{"name": "1:6,5,4,3,2", "slots": 1, "counts": [6, 5, 4, 3, 2]},
	{"name": "2:10,8,3,2,1", "slots": 2, "counts": [10, 8, 3, 2, 1]},
	{"name": "2:12,10,3,2,1", "slots": 2, "counts": [12, 10, 3, 2, 1]},
	{"name": "1:0,0,0,0,1", "slots": 1, "counts": [0, 0, 0, 0, 1]},
]
const EXITS: Array[String] = ["tunnel", "bridge"]
## How many walks run side by side by default: each is one Godot process at the game's own clock,
## on a machine several agents share, where agents' test runs have crashed Godot (minty-lemur #792),
## so two unless `ESCAPE_WINNABLE_PARALLEL` sets another number.
const PARALLEL := 2
## Well past the section's own `RunConfig.FINALE_LENGTH_SECONDS` and the boot before it: a walk still
## running then has hung, and is reported so rather than waited on.
const TIMEOUT_SECONDS := 260.0
const POLL_MSEC := 250

func run(t) -> void:
	var saved_seed := GameState.header.run_seed
	var saved_day := GameState.header.day
	var mixes := _mixes()
	var seeds := _seeds()
	var plans: Array[Dictionary] = []
	for seed_value in seeds:
		plans.append_array(_plan_seed(t, seed_value, mixes))
	for mix in mixes:
		var own: Array[Dictionary] = []
		for row in plans:
			if row["mix"] == mix["name"]:
				own.append(row)
		_print_plans(mix["name"], own)
	GameState.header.run_seed = saved_seed
	GameState.header.day = saved_day
	if OS.get_environment("ESCAPE_WINNABLE_WALK") != "0":
		_print_walks(_walk_every_seed(seeds))
	t.check(true, "a probe asserts nothing")

## `SEEDS`, or the comma-separated seeds in `ESCAPE_WINNABLE_SEEDS` when it is set, for a quick look
## at one city.
func _seeds() -> Array[int]:
	var given := OS.get_environment("ESCAPE_WINNABLE_SEEDS")
	if given == "":
		return SEEDS
	var found: Array[int] = []
	for word in given.split(",", false):
		found.append(int(word))
	return found

## `MIXES`, or the ones `ESCAPE_WINNABLE_MIX` names.
func _mixes() -> Array[Dictionary]:
	var given := OS.get_environment("ESCAPE_WINNABLE_MIX")
	if given == "":
		return MIXES
	var found: Array[Dictionary] = []
	for text in given.split(";", false):
		if text == "as built":
			found.append({"name": text})
			continue
		var halves := text.split(":")
		var counts: Array[int] = []
		for word in halves[1].split(","):
			counts.append(int(word))
		found.append({"name": text, "slots": int(halves[0]), "counts": counts})
	return found

# ------------------------------------------------------------------- the plans ---

## Every mix's plan for one seed, on the city a straight city boot builds.
func _plan_seed(t, seed_value: int, mixes: Array[Dictionary]) -> Array[Dictionary]:
	GameState.start_run(seed_value)
	var day := GameState.header.day
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(CityGenerator.generate(GameState.header.run_seed))
	GameState.attempt_spend.city_state.begin_day(city.map.block_plans, day)
	city.start_day(GameState.attempt_spend.city_state, day, GameState.calendar.day_rng(day, "closures"), _city_spec())
	var found: Array[Dictionary] = []
	for mix in mixes:
		var walk := FinalePlanner.route(city.map)
		var row := _street_counts(city.map, walk, _plan(city.map, walk, day, mix))
		row["mix"] = mix["name"]
		row["seed"] = seed_value
		print("ESCAPE_WINNABLE [%s] seed %d | %d streets, %d with none, %d dangers | %s" % [
				row["mix"], seed_value, row["streets"], row["empty"], row["dangers"],
				_counts(row["rows"])])
		found.append(row)
	city.free()
	return found

## The section's plan, drawn the way a straight city boot draws it; for a mix other than `as built`,
## the same plan under a spec whose bag and slots are that mix's, drawn on the stream the game's own
## bag is drawn on (`EventScheduler.street_bag_seed()`).
func _plan(map: CityMap, walk: FinalePlanner.Plan, day: int,
		mix: Dictionary) -> Array[EventScheduler.Planned]:
	var rng := GameState.calendar.day_rng(day, "finale")
	var spec := _city_spec()
	if mix.has("slots"):
		var counts: Array = mix["counts"]
		spec.bag = {"military_convoy": counts[0], "finale_explosion": counts[1],
				"abduction": counts[2], "roadblock": counts[3], DaySpec.EMPTY_MARBLE: counts[4]}
		spec.slots_per_street = int(mix["slots"])
	return DayPlanner.plan_the_escape_city(map, walk, rng, spec)

## `{streets, empty, dangers, rows}`: the open streets, those standing none of the four rows, how
## many of the four rows stand on them in all, and how many of each.
func _street_counts(map: CityMap, plan: FinalePlanner.Plan,
		placements: Array[EventScheduler.Planned]) -> Dictionary:
	var empty := 0
	var dangers := 0
	var rows := {}
	for id in ROWS:
		rows[id] = 0
	for segment in plan.open_streets:
		var rect := map.tile_rect_to_world(segment.tile_rect()).grow(1.0)
		var here := 0
		for placement in placements:
			if ROWS.has(placement.def.id) and rect.has_point(placement.position):
				here += 1
				rows[placement.def.id] = int(rows[placement.def.id]) + 1
		dangers += here
		if here == 0:
			empty += 1
	return {"streets": plan.open_streets.size(), "empty": empty, "dangers": dangers, "rows": rows}

func _print_plans(mix: String, rows: Array[Dictionary]) -> void:
	var streets := 0
	var empty := 0
	var dangers := 0
	var each := {}
	for row in rows:
		streets += int(row["streets"])
		empty += int(row["empty"])
		dangers += int(row["dangers"])
		for id in ROWS:
			each[id] = int(each.get(id, 0)) + int(row["rows"][id])
	print("ESCAPE_WINNABLE [%s] | %d seeds | %.2f dangers a street, %.0f%% of streets with none | %s"
			% [mix, rows.size(), float(dangers) / maxf(1.0, streets),
			100.0 * empty / maxf(1.0, streets), _counts(each)])

static func _counts(counts: Dictionary) -> String:
	var parts: Array[String] = []
	for id in ROWS:
		parts.append("%s %d" % [id, int(counts.get(id, 0))])
	return ", ".join(parts)

# ------------------------------------------------------------------- the walks ---

## One walk of the game's own walker per seed and exit, `_parallel()` at a time: launch, wait for each
## to quit or to be killed at `TIMEOUT_SECONDS`, find the run log each wrote, and read how it ended.
## **The two exits of one seed never run side by side**, because a run's log folder is named by its
## seed and start time (`Telemetry.begin_run()`), so `_find_log()` tells two runs of one seed apart
## only by when they wrote.
func _walk_every_seed(seeds: Array[int]) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	for exit in EXITS:
		for seed_value in seeds:
			queue.append({"seed": seed_value, "exit": exit})
	var rows: Array[Dictionary] = []
	while not queue.is_empty():
		var batch: Array[Dictionary] = []
		var seeds_in_batch := {}
		var i := 0
		while i < queue.size() and batch.size() < _parallel():
			if seeds_in_batch.has(queue[i]["seed"]):
				i += 1
				continue
			seeds_in_batch[queue[i]["seed"]] = true
			batch.append(queue[i])
			queue.remove_at(i)
		rows.append_array(_walk_batch(batch))
	return rows

## `PARALLEL`, or `ESCAPE_WINNABLE_PARALLEL` when it is set to a positive whole number.
func _parallel() -> int:
	var given := int(OS.get_environment("ESCAPE_WINNABLE_PARALLEL"))
	return given if given > 0 else PARALLEL

func _walk_batch(batch: Array[Dictionary]) -> Array[Dictionary]:
	var godot := OS.get_executable_path()
	var project := ProjectSettings.globalize_path("res://")
	var started_at := Time.get_unix_time_from_system()
	for walk in batch:
		var args: PackedStringArray = ["--headless", "--path", project, "--",
				"--start-escape", "city", "--seed", str(walk["seed"]), "--route", walk["exit"],
				"--no-save", "--no-title"]
		walk["pid"] = OS.create_process(godot, args, false)
	var waited := 0.0
	while waited < TIMEOUT_SECONDS and batch.any(
			func(walk: Dictionary) -> bool: return int(walk["pid"]) > 0 \
					and OS.is_process_running(int(walk["pid"]))):
		OS.delay_msec(POLL_MSEC)
		waited += POLL_MSEC / 1000.0
	for walk in batch:
		var pid: int = walk["pid"]
		if pid <= 0:
			walk["outcome"] = "not launched"
		elif OS.is_process_running(pid):
			OS.kill(pid)
			walk["outcome"] = "killed after %.0fs" % TIMEOUT_SECONDS
		else:
			var log_path := _find_log(started_at, int(walk["seed"]))
			if log_path == "":
				walk["outcome"] = "no run log"
			else:
				walk.merge(_read_the_walk(log_path), true)
		print("ESCAPE_WINNABLE walk seed %d %s | %s%s" % [walk["seed"], walk["exit"],
				walk["outcome"], " at %.1fs" % float(walk["seconds"]) if walk.has("seconds") else ""])
	return batch

## The `run.log` the seed's own run wrote, found by folder name and modification time, the way
## `tests/probes/m184_route_timing.gd` finds its own.
func _find_log(started_at: float, seed_value: int) -> String:
	var root := "user://telemetry/%s" % Time.get_date_string_from_system()
	var dir := DirAccess.open(root)
	if dir == null:
		return ""
	var best := ""
	var best_time := -1.0
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir() and name.contains("-seed%d-" % seed_value):
			var candidate := "%s/%s/run.log" % [root, name]
			var mtime := FileAccess.get_modified_time(candidate)
			if mtime >= started_at - 2.0 and mtime > best_time:
				best_time = mtime
				best = candidate
		name = dir.get_next()
	dir.list_dir_end()
	return best

## How the walk ended, from `RouteRig`'s own `route` lines: `out` when the section was won, the
## day's loss (`LOST_CRYING`, `LOST_HARD_FAIL`, `LOST_TIMEOUT`) when it was lost, or why the walker
## never set off; and the section's clock when it ended.
func _read_the_walk(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"outcome": "no run log"}
	var time_pattern := RegEx.new()
	time_pattern.compile("(\\d+\\.\\d+)s \\(day time\\)")
	var found := {"outcome": "no ending in the log"}
	while not file.eof_reached():
		var columns := file.get_line().strip_edges().split(" ", false)
		if columns.size() < 2 or columns[1] != "route":
			continue
		var text := " ".join(columns.slice(2))
		var time_match := time_pattern.search(text)
		if time_match:
			found["seconds"] = float(time_match.get_string(1))
		if text.contains("day won"):
			found["outcome"] = "out"
		elif text.contains("day ended"):
			found["outcome"] = text.get_slice("(", 1).get_slice(")", 0)
		elif text.contains("no path to"):
			found["outcome"] = "no walk"
		elif text.contains("unavailable"):
			found["outcome"] = "no exit"
		elif text.contains("stuck fast"):
			found["stuck"] = int(found.get("stuck", 0)) + 1
	file.close()
	return found

func _print_walks(rows: Array[Dictionary]) -> void:
	for exit in EXITS:
		var outcomes := {}
		var out := 0
		var seconds := 0.0
		for row in rows:
			if row["exit"] != exit:
				continue
			var outcome: String = row["outcome"]
			outcomes[outcome] = int(outcomes.get(outcome, 0)) + 1
			if outcome == "out":
				out += 1
				seconds += float(row.get("seconds", 0.0))
		print("ESCAPE_WINNABLE walks to the %s | %s | out in %.1fs on average"
				% [exit, outcomes, seconds / maxf(1.0, out)])

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
