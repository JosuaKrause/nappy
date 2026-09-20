extends Node
## Headless test runner.
##
##     tools/test.sh                 # everything, and the only thing a commit may rest on
##     tools/test.sh crowd balance   # just the suites whose name contains one of these
##     godot --headless --path . res://tests/tests.tscn -- crowd
##
## Runs as a scene rather than via `--script` so that the autoloads (Tuning, EventBus,
## GameState) actually exist — `--script` replaces the main loop and skips them.
##
## Every file matching tests/test_*.gd is loaded and its `run(t)` called, where `t` is this
## runner. Suites report with `check()` / `close_to()`. A probe under `tests/probes/`, and the
## negative fixtures under `tests/runner_fixtures/` (`engine_error.gd`, and `unparseable_suite.gd`
## once `tools/test.sh` has staged it from its committed `.gd.src` — see that file's own header),
## run only when named by path — see `_discover`.
##
## **A suite that fails to load is a recorded failure, never a hang.** `load()` on a
## script with a parse error returns a non-null `GDScript` that `can_instantiate()` refuses, and
## calling `.new()` on it anyway is itself a runtime error that aborts `_ready()` before `quit()`
## — the whole engine then idles forever with nothing left to drive it, since nothing else is
## running. The `can_instantiate()` guard below is what turns that into a named `FAIL` line and a
## normal, non-zero exit.
##
## The filter exists because the whole suite is minutes and a single suite is seconds, and a
## check you only run at the end tells you *that* something broke rather than *what*. It says
## so loudly on every filtered run: a partial pass has to be impossible to mistake for a green
## build, or the filter becomes a way of not running the tests.
##
## **A suite over two minutes serial is a suite to split or to cut, not a suite to leave.**
## `tools/test.sh` shards the full run across four processes, and the longest suite alone sets
## the floor every other shard waits on — a two-minute suite costs the run two minutes no matter
## how quickly the other three shards clear, and past that floor a suite is buying itself nothing
## a fourth process would not buy back faster. The per-suite line below, printed for every suite
## on every run, is what says which one that is.

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	var filters := OS.get_cmdline_user_args()
	for path in _discover(filters):
		var started := Time.get_ticks_msec()
		# `load()` on a suite with a parse error returns a non-null GDScript that this guard
		# catches before `.new()` ever runs — `.new()` on it is a runtime error with nothing to
		# catch it, which is what used to abort `_ready()` before `quit()` and leave the headless
		# process idling forever. A missing file takes the same branch: `load()` returns null,
		# and `null as GDScript` is null too, so `can_instantiate()` never runs on it.
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			failures.append("%s failed to load (parse error or missing script)" % path)
			print("-- %-26s %7s" % [path.get_file(), "LOAD FAIL"])
			continue
		var suite: Object = script.new()
		suite.run(self)
		# Per-suite timing, because "the suite got slow" is otherwise a guessing game — and
		# the integration suites can be five orders of magnitude heavier than the rest: the
		# spread runs from `test_quit_option.gd` at 3ms to `test_events.gd` at about 259_000.
		#
		# **Both columns are sized for the worst case rather than the common one**, since a
		# single overflowing row pushes only its own line and the misalignment reads as a
		# glitch rather than as the outlier it is pointing at. 26 clears the longest name on
		# disk (`test_reachability_grid.gd`, 25) with a space to spare; 7 digits reach nearly
		# three hours, which no suite will approach without that being the news.
		print("-- %-26s %7d ms" % [path.get_file(), Time.get_ticks_msec() - started])

	print("")
	for failure in failures:
		print("FAIL  %s" % failure)
	print("%d checks, %d failures" % [checks, failures.size()])
	if not filters.is_empty():
		print("PARTIAL RUN — only suites matching %s. Not a green build." % ", ".join(filters))
	get_tree().quit(1 if not failures.is_empty() else 0)

## Every suite, or the ones whose file name contains one of `filters`.
##
## Substring rather than exact, so `crowd` finds `test_crowd.gd` without anybody having to
## remember the prefix — and a filter that matches nothing is an error rather than a run of
## nought suites reporting no failures.
##
## **Only the top of `tests/` is a suite.** `tests/probes/` holds measurement probes — scripts
## with the same `run(t)` shape that print numbers rather than assert relationships — and nothing
## finds them by walking the directory, so the full run and CI never pay for them. A probe runs
## only by being named as a path under `tests/`: `tools/test.sh probes/m64_density.gd`.
## `tests/runner_fixtures/` holds the same kind of exception the other way round: a script whose
## job is to fail a real check on the runner itself (a Godot engine diagnostic, not a bad
## assertion), named the same way: `tools/test.sh runner_fixtures/engine_error.gd`.
func _discover(filters: PackedStringArray) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open("res://tests")
	if not dir:
		push_error("cannot open res://tests")
		return paths
	for file in dir.get_files():
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		if filters.is_empty() or _matches(file, filters):
			paths.append("res://tests/" + file)
	for filter in filters:
		var explicit := "res://tests/" + filter
		if filter.contains("/") and FileAccess.file_exists(explicit) and not explicit in paths:
			paths.append(explicit)
	paths.sort()
	if paths.is_empty():
		failures.append("no test suite matches %s" % ", ".join(filters))
	return paths

func _matches(file: String, filters: PackedStringArray) -> bool:
	for filter in filters:
		if file.contains(filter):
			return true
	return false

# --------------------------------------------------------------- assertions ---

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func close_to(actual: float, expected: float, message: String, epsilon := 0.02) -> void:
	checks += 1
	if absf(actual - expected) > epsilon:
		failures.append("%s (got %.4f, want %.4f)" % [message, actual, expected])
