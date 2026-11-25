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
## (`--start-escape city`: `RunState.start_run(seed)`, the city built from the run seed, the plan
## drawn from `run.calendar().day_rng(day, "finale")` under the city section's spec, as
## `DayDirector.start()` draws it): how many of the escape's four rows stand on its open
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

## Twenty-four run seeds: `tests/finale_rig.gd` (run by `test_finale_a.gd`, `_b.gd` and `_c.gd`)'s own four, the probe seeds the escape's other
## probes use, the seed the player could not win (inbox #771 in minty-lemur), and small primes.
const SEEDS: Array[int] = [4242, 1, 77, 9001, 23, 5, 31337, 2024, 7, 808, 4216201080, 11, 13, 17,
		19, 29, 31, 37, 41, 43, 47, 53, 59, 61]
const ROWS: Array[String] = ["military_convoy", "finale_explosion", "abduction", "roadblock"]
## The mixes planned: the bag's marbles, trucks, explosions, vans, roadblocks and empty, in the
## player's order, one drawn a street. `as built` is the city section's own spec, through
## `DayPlanner.plan_the_escape_city()` exactly as the game plans it, and the one walked; the others are the
## candidates it was chosen against, and the last stands nothing at all. `ESCAPE_WINNABLE_MIX`
## replaces the list, as `as built` or `<trucks>,<explosions>,<vans>,<roadblocks>,<empty>` mixes
## separated by `;`.
const MIXES: Array[Dictionary] = [
	{"name": "as built"},
	{"name": "5,4,3,2,1", "counts": [5, 4, 3, 2, 1]},
	{"name": "6,5,4,3,2", "counts": [6, 5, 4, 3, 2]},
	{"name": "0,0,0,0,1", "counts": [0, 0, 0, 0, 1]},
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
## The rows a walk meets as dangers of their own, as the run log's `near` lines name them.
## Craters and the seals are the city's, not the bag's.
const MET_ROWS: Array[String] = ["military_convoy", "abduction", "roadblock"]
## Two `near` lines of one row more than this many seconds or tiles apart are two meetings.
const MEETING_GAP_SECONDS := 5.0
const MEETING_GAP_TILES := 12.0

## `"<seed>|<exit>"` -> the streets that exit's walk runs through, as `{rect: Rect2i (tiles),
## takes: vans and roadblocks placed on it, blasts: explosions placed on it}`, read off the first
## mix's plan, which is the game's own bag when the mixes are not replaced.
var _exit_streets := {}

func run(t: TestRunner) -> void:
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
		var counts: Array[int] = []
		for word in text.split(","):
			counts.append(int(word))
		found.append({"name": text, "counts": counts})
	return found

# ------------------------------------------------------------------- the plans ---

## Every mix's plan for one seed, on the city a straight city boot builds.
func _plan_seed(t: TestRunner, seed_value: int, mixes: Array[Dictionary]) -> Array[Dictionary]:
	var run := RunCity.started_run(seed_value)
	var city: City = RunCity.new_city(CITY_SCENE)
	var day := run.header().day()
	t.add_child(city)
	RunCity.build(city, run, CityGenerator.generate(run.header().run_seed()))
	run.attempt_spend().block_arcs().begin_day(city.map().plans_by_block(), day)
	city.start_day(run.attempt_spend().block_arcs(), day, run.calendar().day_rng(day,
			"closures"), _city_spec())
	var found: Array[Dictionary] = []
	for mix in mixes:
		var walk := FinalePlanner.route(city.map())
		var placements := _plan(city.map(), run, walk, day, mix)
		var row := _street_counts(city.map(), walk, placements)
		if mix == mixes[0]:
			_note_exit_streets(seed_value, city.map(), walk, placements)
		row["mix"] = mix["name"]
		row["seed"] = seed_value
		print("ESCAPE_WINNABLE [%s] seed %d | %d streets, %d with none, %d dangers | %s" % [
				row["mix"], seed_value, row["streets"], row["empty"], row["dangers"],
				_counts(row["rows"])])
		found.append(row)
	city.free()
	return found

## The section's plan, drawn the way a straight city boot draws it; for a mix other than `as built`,
## the same plan under a spec whose bag is that mix's, drawn on the plan's own stream, the one the
## game's own bag is drawn on.
func _plan(map: CityMap, own_run: RunState, walk: FinalePlanner.Plan, day: int,
		mix: Dictionary) -> Array[EventPlan]:
	var rng := own_run.calendar().day_rng(day, "finale")
	var spec := _city_spec()
	if mix.has("counts"):
		var counts: Array = mix["counts"]
		spec.bag = {"military_convoy": counts[0], "finale_explosion": counts[1],
				"abduction": counts[2], "roadblock": counts[3], DaySpec.EMPTY_MARBLE: counts[4]}
	return DayPlanner.plan_the_escape_city(map, walk, rng, spec, GamePlanBuilder.over(map))

## Each exit's streets for `seed_value`, with the vans, roadblocks and explosions the plan stands on
## them, for the walks' reading of their run logs.
func _note_exit_streets(seed_value: int, map: CityMap, plan: FinalePlanner.Plan,
		placements: Array[EventPlan]) -> void:
	for chain in plan.chains:
		var streets: Array[Dictionary] = []
		for segment in plan.open_streets:
			if not SealPlanner.runs_through(segment, chain.cells):
				continue
			var rect := segment.tile_rect()
			var world := map.tile_rect_to_world(rect).grow(1.0)
			var takes := 0
			var blasts := 0
			for placement in placements:
				if not world.has_point(placement.placed_at()):
					continue
				if placement.row_id() == "finale_explosion":
					blasts += 1
				elif placement.row_id() == "abduction" or placement.row_id() == "roadblock":
					takes += 1
			streets.append({"rect": rect, "takes": takes, "blasts": blasts})
		var exit := "tunnel" if chain.exit_kind == CityExit.Kind.TUNNEL else "bridge"
		_exit_streets["%d|%s" % [seed_value, exit]] = streets

## `{streets, empty, dangers, rows}`: the open streets, those standing none of the four rows, how
## many of the four rows stand on them in all, and how many of each.
func _street_counts(map: CityMap, plan: FinalePlanner.Plan,
		placements: Array[EventPlan]) -> Dictionary:
	var empty := 0
	var dangers := 0
	var rows := {}
	for id in ROWS:
		rows[id] = 0
	for segment in plan.open_streets:
		var rect := map.tile_rect_to_world(segment.tile_rect()).grow(1.0)
		var here := 0
		for placement in placements:
			if ROWS.has(placement.row_id()) and rect.has_point(placement.placed_at()):
				here += 1
				rows[placement.row_id()] = int(rows[placement.row_id()]) + 1
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
				walk.merge(_read_the_walk(log_path,
						_exit_streets.get("%d|%s" % [walk["seed"], walk["exit"]], [])), true)
		print("ESCAPE_WINNABLE walk seed %d %s | %s%s" % [walk["seed"], walk["exit"],
				walk["outcome"], " at %.1fs" % float(walk["seconds"]) if walk.has("seconds") else ""])
	return batch

## The `run.log` the seed's own run wrote, found by folder name and modification time, the way
## `tests/probes/m184_route_timing.gd` finds its own.
func _find_log(started_at: float, seed_value: int) -> String:
	var base := DirAccess.open("user://telemetry")
	if base == null:
		return ""
	var best := ""
	var best_time := -1.0
	# Every day folder, not today's alone: a run that crosses midnight writes into the day it began
	# on, and the modification time is what tells this run's log from an older one.
	for day in base.get_directories():
		var root := "user://telemetry/%s" % day
		var dir := DirAccess.open(root)
		if dir == null:
			continue
		for name in dir.get_directories():
			if not name.contains("-seed%d-" % seed_value):
				continue
			var candidate := "%s/%s/run.log" % [root, name]
			var mtime := FileAccess.get_modified_time(candidate)
			if mtime >= started_at - 2.0 and mtime > best_time:
				best_time = mtime
				best = candidate
	return best

## How the walk ended, from `RouteRig`'s own `route` lines: `out` when the section was won, the
## day's loss (`LOST_CRYING`, `LOST_HARD_FAIL`, `LOST_TIMEOUT`) when it was lost, or why the walker
## never set off; and the section's clock when it ended. And what the walk met, from the run log's
## `near`, `ahead`, `taken` and `cue` lines: the meetings of each row in `MET_ROWS` (a row's `near`
## lines close in time and place are one meeting), the explosions' badges, the vans that took a
## bystander, the lowest sleep and the highest excitement rate the log shows, and how many of the
## exit's `streets` (`_exit_streets`) held something as she met it: a van, roadblock or explosion
## the plan stands there, or a truck the log has met in it.
func _read_the_walk(path: String, streets: Array) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {"outcome": "no run log"}
	var time_pattern := RegEx.new()
	time_pattern.compile("(\\d+\\.\\d+)s \\(day time\\)")
	var at_pattern := RegEx.new()
	at_pattern.compile(" at \\((\\d+),(\\d+)\\)")
	var sleep_pattern := RegEx.new()
	sleep_pattern.compile("sleep (\\d+)")
	var excite_pattern := RegEx.new()
	excite_pattern.compile("exc (\\d+)")
	var found := {"outcome": "no ending in the log", "meetings": {}, "blasts": 0, "taken": 0,
			"min_sleep": 100, "max_exc": 0}
	var last := {}
	var met_trucks_in := {}
	while not file.eof_reached():
		var line := file.get_line()
		var columns := line.strip_edges().split(" ", false)
		if columns.size() < 3:
			continue
		var kind := columns[1]
		var sleep_match := sleep_pattern.search(line)
		if sleep_match:
			found["min_sleep"] = mini(int(found["min_sleep"]), int(sleep_match.get_string(1)))
		var excite_match := excite_pattern.search(line)
		if excite_match:
			found["max_exc"] = maxi(int(found["max_exc"]), int(excite_match.get_string(1)))
		if kind == "taken":
			found["taken"] = int(found["taken"]) + 1
		elif kind == "cue" and line.contains("edge badge: finale_explosion"):
			found["blasts"] = int(found["blasts"]) + 1
		elif (kind == "near" or kind == "ahead") and MET_ROWS.has(columns[2]):
			var at_match := at_pattern.search(line)
			if at_match:
				var row: String = columns[2]
				var seconds := float(columns[0])
				var tile := Vector2i(int(at_match.get_string(1)), int(at_match.get_string(2)))
				if row == "military_convoy":
					for index in streets.size():
						var street: Dictionary = streets[index]
						var rect: Rect2i = street["rect"]
						if rect.grow(1).has_point(tile):
							met_trucks_in[index] = true
				var before: Dictionary = last.get(row, {})
				if before.is_empty() or seconds - float(before["at"]) > MEETING_GAP_SECONDS \
						or Vector2(tile).distance_to(Vector2(before["tile"])) > MEETING_GAP_TILES:
					var meetings: Dictionary = found["meetings"]
					meetings[row] = int(meetings.get(row, 0)) + 1
				last[row] = {"at": seconds, "tile": tile}
		if kind != "route":
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
	var occupied := 0
	var takes := 0
	for index in streets.size():
		var street: Dictionary = streets[index]
		if int(street["takes"]) > 0:
			takes += 1
		if int(street["takes"]) > 0 or int(street["blasts"]) > 0 or met_trucks_in.has(index):
			occupied += 1
	found["route_streets"] = streets.size()
	found["occupied"] = occupied
	found["taking"] = takes
	return found

func _print_walks(rows: Array[Dictionary]) -> void:
	for exit in EXITS:
		var outcomes := {}
		var out := 0
		var seconds := 0.0
		var walks := 0
		var no_truck := 0
		var totals := {"military_convoy": 0, "abduction": 0, "roadblock": 0, "blasts": 0,
				"taken": 0, "route_streets": 0, "occupied": 0, "taking": 0, "min_sleep": 0,
				"max_exc": 0}
		for row in rows:
			if row["exit"] != exit:
				continue
			walks += 1
			var outcome: String = row["outcome"]
			outcomes[outcome] = int(outcomes.get(outcome, 0)) + 1
			if outcome == "out":
				out += 1
				seconds += float(row.get("seconds", 0.0))
			if not row.has("meetings"):
				continue
			var meetings: Dictionary = row["meetings"]
			if int(meetings.get("military_convoy", 0)) == 0:
				no_truck += 1
			for id in MET_ROWS:
				totals[id] = int(totals[id]) + int(meetings.get(id, 0))
			for key: String in ["blasts", "taken", "route_streets", "occupied", "taking",
					"min_sleep", "max_exc"]:
				totals[key] = int(totals[key]) + int(row[key])
		print("ESCAPE_WINNABLE walks to the %s | %s | out in %.1fs on average"
				% [exit, outcomes, seconds / maxf(1.0, out)])
		var each := maxf(1.0, walks)
		var streets := maxf(1.0, int(totals["route_streets"]))
		print(("ESCAPE_WINNABLE met on the %s | %d walks | per walk: %.2f trucks, %.2f vans, "
				+ "%.2f guards, %.2f blasts heard, %.2f bystanders taken | %.0f%% of the route's "
				+ "streets held something (%.0f%% a van or a roadblock) | lowest sleep %.0f, "
				+ "highest excitement %.1f/s | %d walks met no truck") % [exit, walks,
				totals["military_convoy"] / each, totals["abduction"] / each,
				totals["roadblock"] / each, totals["blasts"] / each, totals["taken"] / each,
				100.0 * int(totals["occupied"]) / streets, 100.0 * int(totals["taking"]) / streets,
				totals["min_sleep"] / each, totals["max_exc"] / each, no_truck])

## The escape city's section spec, the one the run flow walks the city under.
static func _city_spec() -> DaySpec:
	return DaySpec.for_section(DaySpec.Section.CITY, RunConfig.FINALE_LENGTH_SECONDS)
