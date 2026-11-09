@warning_ignore_start("untyped_declaration", "unsafe_method_access")
class_name TestRunner
extends Node
## Headless test runner.
##
##     tools/test.sh                 # everything, and the only thing a commit may rest on
##     tools/test.sh crowd balance   # just the suites whose name contains one of these
##     godot --headless --path . res://tests/tests.tscn -- crowd
##     tools/test.sh --shuffle 7 crowd    # the same suites in an order drawn from seed 7
##     tools/test.sh --repeat 3 crowd     # the same suites three times in one process
##
## **`--shuffle SEED` and `--repeat N`** (`USAGE` below is the list). `--shuffle` runs the chosen
## suites, after filtering, in an order drawn from SEED (a whole number, 0 or more): the same seed
## and the same suites give the same order, and the order is printed before anything runs together
## with a command that replays it, so an order-dependent failure is reproducible. `--repeat` runs
## the chosen suites N times in one process, so a leak between passes (a `static var`, an autoload
## field) shows too; with `--shuffle` each pass has an order of its own, from a seed derived from
## SEED and the pass (pass 1 uses SEED itself), printed per pass. Every failure of a repeated run
## carries the pass it came from. A repeated run prints its timings as `pass K/N | suite  T ms`,
## never as the `-- suite  T ms` line that `tools/test.sh --record-costs` and CI's cost merge read,
## so a repeat can never be taken for a measurement of one run.
##
## Runs as a scene rather than via `--script` so that the autoloads (`Tuning` and `EventBus`)
## actually exist — `--script` replaces the main loop and skips them.
##
## **No suite reads a global run.** The game's run lives on the `Sitting` (`Sitting.run`), which
## `main` takes it from; each suite makes a `RunState` of its own and hands it to what it tests (a
## part directly, a city through `RunCity`, a booted `main` through its sitting), so there is no
## run to put back between suites and `SharedState` compares every autoload's variables.
##
## Every file matching tests/test_*.gd is loaded and its `run(t)` called, where `t` is this
## runner. `run` may be a plain function or a coroutine: the runner awaits it, so a suite may
## `await` real frames, and lets a frame and a physics frame pass after each suite.
## A physics frame has passed before the first suite, so every suite meets the same engine state,
## and no suite meets an observer another left behind: the run log and the page counter are each
## boot's sitting's, or a suite's own, never a global. After
## each suite `SharedState` compares the shared state with what it was before, and a suite that
## left any of it changed fails by name (`tests/shared_state.gd` says what is compared).
##
## Suites report with `check()` / `close_to()`. A probe under `tests/probes/`, and the
## negative fixtures under `tests/runner_fixtures/` (`engine_error.gd`, which proves the engine-error
## scan; `quits_the_tree.gd`, which proves the missing-closing-line check; and `unparseable_suite.gd`
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
## The file name of the suite being run, from its start until the frames after it have passed, and
## whether the closing line has been printed: what `_exit_tree` needs to say which suite was running
## when something else quit the tree.
var _running := ""
var _finished := false

const USAGE := """usage: godot --headless --path . res://tests/tests.tscn -- [--help|-h] [--shuffle SEED] [--repeat N] [suite-name-substring...]

Runs the suites under tests/ (all of them, or those whose file name contains a substring).
  --shuffle SEED  run the suites in an order drawn from SEED (a whole number, 0 or more); the same
                  seed gives the same order, which is printed with a command that replays it
  --repeat N      run the chosen suites N times (a whole number, 1 or more) in this one process;
                  with --shuffle every pass has its own order, and a failure names its pass
  --help, -h      print this and run nothing"""

## What a pass seed is: pass 1 runs on SEED itself, so that `--shuffle <that seed>` replays it as a
## single run, and pass K on a number derived from SEED and K. The multiplier is a prime, the
## arithmetic wraps the same way on every machine and the result is masked to stay 0 or more, so
## it is a seed `--shuffle` accepts.
const PASS_SEED_STRIDE := 1000003

## The longest a seed or a repeat count may be, in digits: an int64 holds 18 without a doubt.
const MAX_DIGITS := 18

func _ready() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	if options.has("help"):
		print(USAGE)
		get_tree().quit(0)
		return
	if options.has("error"):
		printerr("tests/run_tests.gd: %s\n" % options["error"])
		printerr(USAGE)
		_finished = true
		get_tree().quit(2)
		return
	var filters: PackedStringArray = options["filters"]
	var shuffle_seed: int = options["seed"]
	var shuffled: bool = shuffle_seed >= 0
	var repeat: int = options["repeat"]
	# In a process where no physics frame has run, `move_and_slide()` moves a body 0 px, and after
	# one it moves the full step. A frame passes before the first suite so that no suite, the first
	# included, runs before the engine has stepped physics once.
	await get_tree().physics_frame
	var chosen := _discover(filters)
	var orders: Array = []
	for pass_number in range(1, repeat + 1):
		var order := chosen.duplicate()
		var pass_seed := _pass_seed(shuffle_seed, pass_number)
		if shuffled:
			_shuffle(order, pass_seed)
		orders.append(order)
		if shuffled:
			var names: PackedStringArray = []
			for path in order:
				names.append(path.trim_prefix("res://tests/"))
			print("ORDER  seed %d  pass %d/%d  %s" % [pass_seed, pass_number, repeat, " ".join(names)])
			print("REPLAY tools/test.sh --shuffle %d %s" % [pass_seed, " ".join(names)])
	for pass_number in range(1, repeat + 1):
		var failures_before := failures.size()
		for path in orders[pass_number - 1]:
			await _run_suite(path, pass_number, repeat)
		if repeat > 1:
			for i in range(failures_before, failures.size()):
				failures[i] = "[pass %d/%d] %s" % [pass_number, repeat, failures[i]]

	print("")
	for failure in failures:
		print("FAIL  %s" % failure)
	_finished = true
	print("%d checks, %d failures" % [checks, failures.size()])
	if repeat > 1:
		print("REPEATED RUN — %d passes of the same suites; the check count is the sum of all of them." % repeat)
	if not filters.is_empty():
		print("PARTIAL RUN — only suites matching %s. Not a green build." % ", ".join(filters))
	get_tree().quit(1 if not failures.is_empty() else 0)

## One suite, one pass: load it, run it, and say what it left behind and how long it took.
func _run_suite(path: String, pass_number: int, repeat: int) -> void:
	var started := Time.get_ticks_msec()
	# **The snapshot comes before the suite is loaded.** A snapshot `load()`s every script that holds
	# a `static var`, and a suite parsed before that first snapshot (the first suite of a process,
	# which `--shuffle` makes any suite) reaches the script graph from the other side; the process
	# then ended with "10 ObjectDB instances were leaked at exit" and exit code 1 though every check
	# passed (`test_run_state.gd` first did it, deterministically).
	var shared_before := SharedState.snapshot(self)
	# `load()` on a suite with a parse error returns a non-null GDScript that this guard
	# catches before `.new()` ever runs — `.new()` on it is a runtime error with nothing to
	# catch it, which is what used to abort `_ready()` before `quit()` and leave the headless
	# process idling forever. A missing file takes the same branch: `load()` returns null,
	# and `null as GDScript` is null too, so `can_instantiate()` never runs on it.
	var script := load(path) as GDScript
	if script == null or not script.can_instantiate():
		failures.append("%s failed to load (parse error or missing script)" % path)
		print("-- %-36s %7s" % [path.get_file(), "LOAD FAIL"])
		return
	var suite: Object = script.new()
	_running = path.get_file()
	# `suite` is typed `Object`, so the call is dynamic: `await` on a `run` that is a plain
	# function returns at once and raises no REDUNDANT_AWAIT warning, and on one that is a
	# coroutine waits for it.
	await suite.run(self)
	# One frame and one physics frame between suites let the message queue (deferred calls,
	# `queue_redraw`, Control layout) and the delete queue (`queue_free`) drain, which a
	# synchronous run never lets happen.
	await get_tree().process_frame
	await get_tree().physics_frame
	for leak in SharedState.diff(shared_before, SharedState.snapshot(self)):
		failures.append("%s left shared state changed, %s" % [path.get_file(), leak])
		print("LEAK  %s%s left shared state changed, %s" % [_pass_tag(pass_number, repeat), path.get_file(), leak])
	_running = ""
	# Per-suite timing, because "the suite got slow" is otherwise a guessing game — and
	# the integration suites can be five orders of magnitude heavier than the rest: the
	# spread runs from `test_quit_option.gd` at 3ms to the heaviest scene suites at over a hundred thousand.
	#
	# **Both columns are sized for the worst case rather than the common one**, since a
	# single overflowing row pushes only its own line and the misalignment reads as a
	# glitch rather than as the outlier it is pointing at. 36 clears the longest name on
	# disk (`test_resistance_placement_kinds.gd`, 34) with a space to spare; 7 digits reach nearly
	# three hours, which no suite will approach without that being the news.
	#
	# **A repeated run prints `pass K/N | suite  T ms` instead**: the `-- suite  T ms` shape is the
	# one `--record-costs` and CI's cost merge read as one measurement per suite, and N of them per
	# suite would be N rows for one name.
	if repeat > 1:
		print("pass %d/%d | %-36s %7d ms" % [pass_number, repeat, path.get_file(), Time.get_ticks_msec() - started])
	else:
		print("-- %-36s %7d ms" % [path.get_file(), Time.get_ticks_msec() - started])

## "[pass K/N] " in a repeated run, else nothing: how a line that is not a failure names its pass.
func _pass_tag(pass_number: int, repeat: int) -> String:
	return "[pass %d/%d] " % [pass_number, repeat] if repeat > 1 else ""

## The options and the suite-name filters in `args`, as a dictionary: `filters`, `seed` (-1 when
## not shuffling) and `repeat`; or `help`; or `error` with a sentence, for an option that is
## malformed or not understood. Nothing has run when this returns.
func _parse_args(args: PackedStringArray) -> Dictionary:
	var filters := PackedStringArray()
	var shuffle_seed := -1
	var repeat := 1
	var seen_shuffle := false
	var seen_repeat := false
	var i := 0
	while i < args.size():
		var arg := args[i]
		if arg == "--help" or arg == "-h":
			return {"help": true}
		elif arg == "--shuffle" or arg == "--repeat":
			var is_shuffle := arg == "--shuffle"
			if (seen_shuffle if is_shuffle else seen_repeat):
				return {"error": "%s is given twice" % arg}
			if i + 1 >= args.size():
				return {"error": "%s needs a whole number after it" % arg}
			var value := args[i + 1]
			if not _is_whole_number(value):
				return {"error": "%s wants a whole number, got '%s'" % [arg, value]}
			if is_shuffle:
				seen_shuffle = true
				shuffle_seed = value.to_int()
			else:
				seen_repeat = true
				repeat = value.to_int()
				if repeat < 1:
					return {"error": "--repeat wants 1 or more, got '%s'" % value}
			i += 2
			continue
		else:
			# Any other argument is a filter, as before: a probe reads its own flags (`--all-events`)
			# off the same command line, so only this runner's own options are checked here.
			filters.append(arg)
		i += 1
	return {"filters": filters, "seed": shuffle_seed, "repeat": repeat}

## Digits only (no sign, no point, no spaces) and short enough for an int64.
func _is_whole_number(text: String) -> bool:
	if text.is_empty() or text.length() > MAX_DIGITS:
		return false
	for c in text:
		if c < "0" or c > "9":
			return false
	return true

## The seed pass `pass_number` (1-based) shuffles with; see PASS_SEED_STRIDE.
func _pass_seed(shuffle_seed: int, pass_number: int) -> int:
	if shuffle_seed < 0 or pass_number == 1:
		return shuffle_seed
	return (shuffle_seed * PASS_SEED_STRIDE + (pass_number - 1)) & 0x7FFFFFFFFFFFFFFF

## Fisher-Yates over `items` in place, drawn from a generator seeded with `seed_value`: the same
## seed and the same list give the same order on any machine (the generator is Godot's PCG, not
## the global one, which nothing else may disturb).
func _shuffle(items: Array, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held = items[i]
		items[i] = items[j]
		items[j] = held

## A suite that quits the tree takes effect at the frame the runner lets pass after it, ending the
## process with exit 0 before the closing line prints. The runner cannot cancel that, but it can say
## which suite was running; `tools/test.sh` fails the run for the missing closing line.
func _exit_tree() -> void:
	if not _finished and _running != "":
		print("QUIT  the tree went away while %s was running; the run did not finish" % _running)

## Every suite, or the ones whose file name contains one of `filters`.
##
## Substring rather than exact, so `crowd` finds `test_crowd_bodies.gd` without anybody having to
## remember the prefix — and a filter that matches nothing is an error rather than a run of
## nought suites reporting no failures.
##
## **Only the top of `tests/` is a suite.** `tests/probes/` holds measurement probes — scripts
## with the same `run(t)` shape that print numbers rather than assert relationships — and nothing
## finds them by walking the directory, so the full run and CI never pay for them. A probe runs
## only by being named as a path under `tests/`: `tools/test.sh probes/m64_density.gd`.
## `tests/runner_fixtures/` holds the same kind of exception the other way round: a script whose
## job is to fail a real check on the runner itself, named the same way:
## `tools/test.sh runner_fixtures/engine_error.gd` (a Godot engine diagnostic, not a bad assertion)
## or `runner_fixtures/quits_the_tree.gd` (the process ends before the closing line prints).
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
