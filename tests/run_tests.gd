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
## runner. Suites report with `check()` / `close_to()`.
##
## The filter exists because the whole suite is minutes and a single suite is seconds, and a
## check you only run at the end tells you *that* something broke rather than *what*. It says
## so loudly on every filtered run: a partial pass has to be impossible to mistake for a green
## build, or the filter becomes a way of not running the tests.

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	var filters := OS.get_cmdline_user_args()
	for path in _discover(filters):
		var started := Time.get_ticks_msec()
		var suite: Object = (load(path) as GDScript).new()
		suite.run(self)
		# Per-suite timing, because "the suite got slow" is otherwise a guessing game — and
		# the integration suites can be three orders of magnitude heavier than the rest.
		print("-- %-24s %5d ms" % [path.get_file(), Time.get_ticks_msec() - started])

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
