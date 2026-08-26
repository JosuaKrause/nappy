extends Node
## Headless test runner.
##
##     tools/test.sh
##     godot --headless --path . res://tests/tests.tscn
##
## Runs as a scene rather than via `--script` so that the autoloads (Tuning, EventBus,
## GameState) actually exist — `--script` replaces the main loop and skips them.
##
## Every file matching tests/test_*.gd is loaded and its `run(t)` called, where `t` is this
## runner. Suites report with `check()` / `close_to()`.

var checks := 0
var failures: Array[String] = []

func _ready() -> void:
	for path in _discover():
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
	get_tree().quit(1 if not failures.is_empty() else 0)

func _discover() -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open("res://tests")
	if not dir:
		push_error("cannot open res://tests")
		return paths
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			paths.append("res://tests/" + file)
	paths.sort()
	return paths

# --------------------------------------------------------------- assertions ---

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)

func close_to(actual: float, expected: float, message: String, epsilon := 0.02) -> void:
	checks += 1
	if absf(actual - expected) > epsilon:
		failures.append("%s (got %.4f, want %.4f)" % [message, actual, expected])
