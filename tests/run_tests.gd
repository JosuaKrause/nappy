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
## runner. `run` may be a plain function or a coroutine: the runner awaits it, so a suite may
## `await` real frames, and lets a frame and a physics frame pass after each suite.
## Before each suite `_reset_globals` puts back the run state and the static test seams, and a
## physics frame has passed before the first, so every suite meets the same engine state.
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

func _ready() -> void:
	var filters := OS.get_cmdline_user_args()
	# In a process where no physics frame has run, `move_and_slide()` moves a body 0 px, and after
	# one it moves the full step. A frame passes before the first suite so that no suite, the first
	# included, runs before the engine has stepped physics once.
	await get_tree().physics_frame
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
		_running = path.get_file()
		_reset_globals()
		# `suite` is typed `Object`, so the call is dynamic: `await` on a `run` that is a plain
		# function returns at once and raises no REDUNDANT_AWAIT warning, and on one that is a
		# coroutine waits for it.
		await suite.run(self)
		# One frame and one physics frame between suites let the message queue (deferred calls,
		# `queue_redraw`, Control layout) and the delete queue (`queue_free`) drain, which a
		# synchronous run never lets happen.
		await get_tree().process_frame
		await get_tree().physics_frame
		_running = ""
		# Per-suite timing, because "the suite got slow" is otherwise a guessing game — and
		# the integration suites can be five orders of magnitude heavier than the rest: the
		# spread runs from `test_quit_option.gd` at 3ms to `test_resistance.gd` at about 192_000.
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
	_finished = true
	print("%d checks, %d failures" % [checks, failures.size()])
	if not filters.is_empty():
		print("PARTIAL RUN — only suites matching %s. Not a green build." % ", ".join(filters))
	get_tree().quit(1 if not failures.is_empty() else 0)

## A suite that quits the tree takes effect at the frame the runner lets pass after it, ending the
## process with exit 0 before the closing line prints. The runner cannot cancel that, but it can say
## which suite was running; `tools/test.sh` fails the run for the missing closing line.
func _exit_tree() -> void:
	if not _finished and _running != "":
		print("QUIT  the tree went away while %s was running; the run did not finish" % _running)

## A fixed seed rather than a random one, so a suite that reads `GameState.run_rng` meets the same
## run on every machine and in every order. For determinism only: no suite may rely on it, and one
## that depends on the run's seed calls `GameState.start_run(<seed>)` itself.
const RESET_SEED := 2

## The one place the globals a suite may leave behind are put back, called before each suite so
## that no suite starts on another's state: the run state and the trace it writes to (a silent
## one), the run configuration a booted `main` handed the observers (none, as before any boot, with
## the counter handed the live run, since the bus reaches it in suites that boot no `main`),

## and the static seams a suite sets by hand (the save's override hooks, the frame recorder, the
## remembered controls and the title's restart stamp). The run log and `VisitCounter`'s own state
## and the `EventBus` connections are left alone.
func _reset_globals() -> void:
	GameState.start_run(RESET_SEED)
	Telemetry.configure(null)
	GameState.use_trace(RunTrace.new())
	VisitCounter.configure(null, GameState)

	GameSave.configure(null)
	GameSave._path_override = ""
	GameSave._uses_save_override = null
	SaveIndicator._home_override = null
	FrameRecord.on = false
	FrameRecord.ledger = null
	ControlsMode._remembered = false
	ControlsMode._remembered_mode = ControlsMode.Mode.TAP
	ControlsMode._remembered_side = ControlsMode.Side.LEFT
	TitleScreen._restarted_at_msec = -INF

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
