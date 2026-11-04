extends RefCounted
## `--route` booted into the escape's building follows the run from the building to a city exit with
## nobody touching it: `BuildingWalker` (`src/dev/building_walker.gd`) presses the building's brief and
## walks her door to door to the service exit, and `RouteRig` takes the city on from there. Driven as
## the flag is driven, by a headless run of the game itself (`--start-escape --route tunnel`), and read
## through the one thing such a run leaves, its run log (`docs/TELEMETRY.md`, the `route` kind) --
## nothing here reaches a private member.
##
## One run is the whole building walked at the game's own pace, so the suite makes one, and ends it
## once the run has shown what it checks rather than waiting out the city's walk to its exit.

const SEED := 7351
## A run still short of the city after this has hung. Generous, since a machine shared with other
## runs plays the game slower than its own clock.
const TIMEOUT_SECONDS := 420.0
const POLL_MSEC := 500

func run(t) -> void:
	var started_at := Time.get_unix_time_from_system()
	var pid := OS.create_process(OS.get_executable_path(), PackedStringArray([
			"--headless", "--path", ProjectSettings.globalize_path("res://"), "--",
			"--start-escape", "--seed", str(SEED), "--route", "tunnel", "--no-save", "--no-title"]), false)
	t.check(pid > 0, "the game is launched")
	var log := PackedStringArray()
	var waited := 0.0
	while pid > 0 and waited < TIMEOUT_SECONDS:
		log = _route_lines(started_at)
		if _has(log, "section ended (LOST") or _in_the_city(log) or not OS.is_process_running(pid):
			break
		OS.delay_msec(POLL_MSEC)
		waited += POLL_MSEC / 1000.0
	log = _route_lines(started_at)
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
	t.check(not log.is_empty(), "the run leaves route lines in its run log")
	t.check(_has(log, "building: walking out in"),
			"the building is planned as a walk out (%s)" % [_first(log, "building:")])
	t.check(not _has(log, "section ended (LOST"),
			"the building is not lost (%s)" % [_first(log, "section ended")])
	t.check(_has(log, "section ended (WON)"), "the building is won (%s)" % [_first(log, "section ended")])
	t.check(_in_the_city(log), "and the city's rig takes the walk on (%s)" % [log[-1] if not log.is_empty() else ""])

## Whether the city's rig has said anything: it plans its first leg or reaches a target.
func _in_the_city(lines: PackedStringArray) -> bool:
	return _has(lines, "day 16:")

## The `route` lines of the newest run log of `SEED`'s run written since `started_at`, text only.
func _route_lines(started_at: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var root := "user://telemetry/%s" % Time.get_date_string_from_system()
	var dir := DirAccess.open(root)
	if dir == null:
		return lines
	var best := ""
	var best_time := -1.0
	for name in dir.get_directories():
		if not name.contains("-seed%d-" % SEED):
			continue
		var candidate := "%s/%s/run.log" % [root, name]
		var modified := FileAccess.get_modified_time(candidate)
		if modified >= started_at - 2.0 and modified > best_time:
			best_time = modified
			best = candidate
	if best == "":
		return lines
	var file := FileAccess.open(best, FileAccess.READ)
	if file == null:
		return lines
	while not file.eof_reached():
		var columns := file.get_line().strip_edges().split(" ", false)
		if columns.size() >= 2 and columns[1] == "route":
			lines.append(" ".join(columns.slice(2)))
	return lines

func _has(lines: PackedStringArray, text: String) -> bool:
	return not _first(lines, text).is_empty()

func _first(lines: PackedStringArray, text: String) -> String:
	for line in lines:
		if line.contains(text):
			return line
	return ""
