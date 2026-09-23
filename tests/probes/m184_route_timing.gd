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
	for day in DAYS:
		for seed_value in SEEDS:
			rows.append(_measure(day, seed_value))
	print("\nday  seed       mark    task    calm  settled    home  left  outcome")
	for row in rows:
		print(row)
	t.check(true, "m184 route timing probe ran")

## One subprocess, end to end: launch, wait for it to quit or to be killed at `_TIMEOUT_SECONDS`,
## find the telemetry log it wrote, and turn that log's own `route` lines into one printable row.
func _measure(day: int, seed_value: int) -> String:
	var godot := OS.get_executable_path()
	var project := ProjectSettings.globalize_path("res://")
	var args: PackedStringArray = ["--headless", "--path", project, "--",
			"--day", str(day), "--seed", str(seed_value),
			"--route", "mark,task,calm,home", "--no-save", "--no-title"]
	var started_at := Time.get_unix_time_from_system()
	var pid := OS.create_process(godot, args, false)
	if pid <= 0:
		return _row(day, seed_value, {}, "could not launch a subprocess")
	var waited := 0.0
	while OS.is_process_running(pid) and waited < _TIMEOUT_SECONDS:
		OS.delay_msec(_POLL_MSEC)
		waited += _POLL_MSEC / 1000.0
	if OS.is_process_running(pid):
		OS.kill(pid)
		return _row(day, seed_value, {}, "killed after %.0fs — never quit on its own" % _TIMEOUT_SECONDS)
	var log_path := _find_log(started_at, seed_value)
	if log_path == "":
		return _row(day, seed_value, {}, "no telemetry log found for this run")
	return _row(day, seed_value, _parse_log(log_path), "")

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
		elif text.contains("day ended"):
			outcome = "%s before '%s' at %.1fs" % [text.get_slice("(", 1).get_slice(")", 0),
					target, elapsed]
		elif text.contains("unavailable, skipping"):
			reached[target + "_skip"] = "unavailable"
		elif text.contains("no path to") or text.contains("no longer reachable"):
			reached[target + "_skip"] = "unreachable"
		elif text.contains("stuck fast"):
			reached[target + "_skip"] = "stuck fast"
	file.close()
	reached["outcome"] = outcome
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
	return "%3d  %-9d %6s  %6s  %6s  %6s  %6s  %4s  %s" \
			% [day, seed_value, mark, task, calm, settled, home, left, outcome]

func _cell(reached: Dictionary, key: String) -> String:
	if reached.has(key):
		return "%.1fs" % float(reached[key])
	if reached.has(key + "_skip"):
		return str(reached[key + "_skip"])
	return "-"
