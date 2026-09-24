extends RefCounted
## Whether days 6 to 13 fit their clock, walked mark → task → calm → home by `RouteRig`
## (`src/dev/route_rig.gd`, `--route`) rather than guessed at with `--walk`'s own timed headings.
## Not a suite: it prints a table rather than asserting relationships, so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m184_route_timing.gd
##
## **Spawns the real game once per (day, seed) rather than driving `RouteRig` inside this probe's
## own process.** `RouteRig`'s whole point is walking through the real `Stroller`'s real
## collision, and a manually-stepped test scene cannot make `move_and_slide()` apply a
## displacement without a live physics frame between two calls — see `tests/test_route_rig.gd`'s
## own doc on why its one live leg integrates position by hand instead, which is honest for a
## short regression check and would understate every collision this measurement is supposed to
## be honest about. `OS.get_executable_path()` is the Godot binary already running this probe, so
## nothing external has to be configured to find it.
##
## Each run is headless, carries `--no-save` and `--no-title` (a title screen left up is a title
## screen `RouteRig` never gets past — `main.gd` pauses everything behind it), and is given no
## `--day-length`: the whole question is whether the *real* clock is enough, so compressing it
## would answer a different one. `_TIMEOUT_SECONDS` is a safety net well past every day 6-13's own
## length (`Tuning.day_length()`, 144.0s for all eight), not a budget this probe is trying to fit.
##
## **Carries `--invincible`.** The question this table answers is "does the route fit the day's
## clock", not "does she survive the ordinary risk of the streets she walks" — the second is a
## real fact about the game and not a defect in the rig, but it would show up in this table as a
## day that "did not fit" when what actually happened is a fair loss to a crowd or an event, which
## answers a different question than the one asked. `--invincible` freezes the excitement meter
## and the clock's own hard stop the same way the verify skill's capture guidance already leans on
## it, without changing where she walks or how long a leg honestly takes; a non-invincible run is
## still worth taking once by hand when this table wants explaining, and its own outcome column
## (`LOST_CRYING`, `LOST_HARD_FAIL`, `LOST_TIMEOUT`) is exactly what to read for that.

const DAYS := [6, 7, 8, 9, 10, 11, 12, 13]
## The same spread `tests/test_full_run.gd` already uses, for the same reason: a single city can
## be lucky, and a fact about one seed is not yet a fact about the day.
const SEEDS := [4242, 90210, 1234567]
const _TIMEOUT_SECONDS := 220.0
const _POLL_MSEC := 250

func run(t) -> void:
	print("\n== M184 — does day N fit its clock, mark -> task -> calm -> home ==")
	print("%d days x %d seeds, day length %.0fs" % [DAYS.size(), SEEDS.size(), Tuning.day_length(6)])
	var rows: Array[String] = []
	var stuck_legs := 0
	for day in DAYS:
		for row: Dictionary in _measure_day(day):
			rows.append(row["text"])
			stuck_legs += int(row["stuck"])
	print("\nday  seed       mark    task    calm  settled    home  left  outcome")
	for row in rows:
		print(row)
	print("\n%d legs stuck fast, over %d runs" % [stuck_legs, rows.size()])
	t.check(true, "m184 route timing probe ran")

## One subprocess per seed for `day`, all running at once, end to end: launch, wait for each to
## quit or to be killed at `_TIMEOUT_SECONDS`, find the telemetry log each wrote, and turn that
## log's own `route` lines into one printable row, with the count of its legs stuck fast. **The
## seeds run side by side and the days one after another** because a run's log folder is named by
## its seed and start time (`Telemetry.begin_run()`), not its day: two live runs never share a seed,
## so `_find_log()` always finds the one run of that seed still writing.
func _measure_day(day: int) -> Array[Dictionary]:
	var godot := OS.get_executable_path()
	var project := ProjectSettings.globalize_path("res://")
	var started_at := Time.get_unix_time_from_system()
	var pids := {}
	for seed_value: int in SEEDS:
		var args: PackedStringArray = ["--headless", "--path", project, "--",
				"--day", str(day), "--seed", str(seed_value),
				"--route", "mark,task,calm,home", "--no-save", "--no-title", "--invincible"]
		pids[seed_value] = OS.create_process(godot, args, false)
	var waited := 0.0
	while waited < _TIMEOUT_SECONDS and pids.values().any(
			func(pid: int) -> bool: return pid > 0 and OS.is_process_running(pid)):
		OS.delay_msec(_POLL_MSEC)
		waited += _POLL_MSEC / 1000.0
	var rows: Array[Dictionary] = []
	for seed_value: int in SEEDS:
		var pid: int = pids[seed_value]
		var note := ""
		var reached := {}
		if pid <= 0:
			note = "could not launch a subprocess"
		elif OS.is_process_running(pid):
			OS.kill(pid)
			note = "killed after %.0fs — never quit on its own" % _TIMEOUT_SECONDS
		else:
			var log_path := _find_log(started_at, seed_value)
			if log_path == "":
				note = "no telemetry log found for this run"
			else:
				reached = _parse_log(log_path)
		rows.append({"text": _row(day, seed_value, reached, note),
				"stuck": reached.get("stuck_legs", 0)})
	return rows

## The `run.log` this seed's own subprocess wrote, found by folder name and modification time
## rather than by capturing stdout — `rig-HHMMSS-seed<seed>-<version>` names the seed but not the
## day, and more than one day in this sweep shares a seed, so `started_at` (with a two-second
## grace for clock rounding) is what tells this run's folder from an earlier one for the same seed.
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

## Every `route` line, in order — the exact sentences `RouteRig`'s own `Telemetry.note()` calls
## write (`src/dev/route_rig.gd`), read back rather than re-derived. Two regexes carry the whole
## grammar: the day-time before `s (day time)`, and the first quoted target name.
func _parse_log(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var time_pattern := RegEx.new()
	time_pattern.compile("(\\d+\\.\\d+)s \\(day time\\)")
	var target_pattern := RegEx.new()
	target_pattern.compile("'([a-z]+)'")
	var reached := {}
	var outcome := ""
	var held: Array[String] = []
	while not file.eof_reached():
		var line := file.get_line()
		var columns := line.strip_edges().split(" ", false)
		if columns.size() < 2 or columns[1] != "route":
			continue
		var text := " ".join(columns.slice(2))
		var time_match := time_pattern.search(text)
		var elapsed := float(time_match.get_string(1)) if time_match else -1.0
		var target_match := target_pattern.search(text)
		var target := target_match.get_string(1) if target_match else ""
		if text.contains("reached '"):
			reached[target] = elapsed
		elif text.contains("baby settled at"):
			reached["settled"] = elapsed
		elif text.contains("route done"):
			reached["done"] = elapsed
		elif text.contains("day won"):
			# `_on_day_finished()`'s own report of the race its own doc names: `DayController`'s
			# `WON` can fire before `_arrive()`'s tighter `_ARRIVE_RADIUS` does, so a day this
			# table calls "home" may never print `RouteRig`'s own "reached 'home'" line at all —
			# this is the only record of when she actually got there. `target` is always `home`,
			# the one word `_current_word` can be while `DayController.phase` is `RETURNING`.
			reached[target] = elapsed
			outcome = "won (before the rig's own arrival check)"
		elif text.contains("day ended"):
			outcome = "%s before '%s' at %.1fs" % [text.get_slice("(", 1).get_slice(")", 0),
					target, elapsed]
		elif text.contains("ran out before reaching"):
			# `RouteRig._out_of_day()`: under `--invincible` nothing else ends a route that does not
			# fit its day, so this is the "no" this table exists to find.
			outcome = "out of day before '%s'" % target
		elif text.contains("unavailable, skipping"):
			reached[target + "_skip"] = "unavailable"
		elif text.contains("no path to") or text.contains("no longer reachable"):
			reached[target + "_skip"] = "unreachable"
		elif text.contains("stuck fast"):
			reached[target + "_skip"] = "stuck fast"
			reached["stuck_legs"] = int(reached.get("stuck_legs", 0)) + 1
			# "'<target>' stuck fast at (x,y) against <what>, skipping" — where she was and what
			# held her, so the table says which chokepoint each stuck leg met.
			held.append("%s at %s" % [target,
					text.get_slice("stuck fast at ", 1).get_slice(", skipping", 0)])
	file.close()
	reached["outcome"] = outcome
	reached["held"] = "; ".join(held)
	return reached

func _row(day: int, seed_value: int, reached: Dictionary, note: String) -> String:
	if note != "":
		return "%3d  %-9d %s" % [day, seed_value, note]
	var mark := _cell(reached, "mark")
	var task := _cell(reached, "task")
	var calm := _cell(reached, "calm")
	var settled := _cell(reached, "settled")
	var home := _cell(reached, "home")
	var left := "-"
	if reached.has("home"):
		left = "%.0fs" % (Tuning.day_length(day) - float(reached["home"]))
	var outcome: String = reached.get("outcome", "")
	if outcome == "" and reached.has("done"):
		outcome = "route done"
	var held: String = reached.get("held", "")
	if held != "":
		outcome += " | stuck: " + held
	return "%3d  %-9d %6s  %6s  %6s  %6s  %6s  %4s  %s" \
			% [day, seed_value, mark, task, calm, settled, home, left, outcome]

func _cell(reached: Dictionary, key: String) -> String:
	if reached.has(key):
		return "%.1fs" % float(reached[key])
	if reached.has(key + "_skip"):
		return str(reached[key + "_skip"])
	return "-"
