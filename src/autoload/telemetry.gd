extends Node
## The run log, as a global every system can write one line into.
##
## **Inert until `begin_run()`.** Nothing writes a file, opens a directory or costs a string
## concatenation until the game itself asks for a run to be traced — which is why the test
## suite, which never calls it, neither writes logs nor slows down. `note()` on a dormant
## Telemetry is a boolean check and a return.
##
## Three constraints govern everything here, and all three are non-negotiable:
##
## - **It must not touch gameplay.** No RNG, no `day_rng()` stream, nothing that changes a
##   placement or a roll. A trace that perturbs the run it is measuring is worse than no
##   trace, and this project's determinism invariant is what makes replaying a bad run
##   possible at all. Callers hoist a roll into a variable to log it; they never add one.
## - **It must be readable without a tool.** It is for a human deciding whether day one is
##   too hard. If reading it needs a script that does not exist yet, it will not get read.
## - **Order is the record.** One line per thing that happened, timestamped, in the order it
##   happened. See `TelemetryLog`.
##
## What belongs in the log and what does not is docs/TELEMETRY.md; the short version is that
## a run is deterministic from a seed, so only what the code *cannot* recompute is worth
## writing down — above all the random outcomes that branch a run.

## Where logs go. Printed at the start of a run, because a trace nobody can find is a trace
## nobody reads.
const DIRECTORY := "user://telemetry"
## Logs kept before the oldest are pruned. `check.sh` and `shot.sh` boot the game too, so the
## directory would otherwise fill with two-line traces of a run that never started.
const KEEP_LOGS := 50

var _log: TelemetryLog
## Seconds into the current day, fed by the observer from the day clock so that a timestamp
## in the log and the clock in the HUD are the same number.
var _clock := 0.0
var _day_open := false

## Whether anything is being recorded. Everything else here is a no-op when this is false.
func is_active() -> bool:
	return _log != null

## Opens a log for a run. Called by `main.gd` and by nothing else — a system that wants to be
## traced calls `note()` and lets this decide whether anyone is listening.
func begin_run(run_seed: int) -> void:
	end_run()
	if not _prepare_directory():
		return
	var stamp := Time.get_datetime_string_from_system(false, false).replace(":", "").replace(" ", "-")
	_log = TelemetryLog.new("%s/run-%s-seed%d.log" % [DIRECTORY, stamp, run_seed])
	_clock = 0.0
	_day_open = false
	_log.header("nappy run log  %s  commit %s"
			% [Time.get_datetime_string_from_system(), source_version()])
	if _log.path != "":
		print("[Telemetry] %s" % ProjectSettings.globalize_path(_log.path))

## Opens a log that goes nowhere, for tests.
##
## The load-bearing promise here is that switching the log on changes nothing about the run,
## and the only way to check a promise like that is to run something twice with it on and off.
## Doing that against `begin_run()` would put a file on disk for every check in the suite, so
## the same log with no file behind it is the honest way to test it. See tests/test_telemetry.gd.
func begin_memory_log() -> void:
	end_run()
	_log = TelemetryLog.new()
	_clock = 0.0
	_day_open = false
	_log.header("nappy run log  (memory)")

## Starts a day's section. Everything after this is timestamped from zero.
func begin_day(day: int, act: int, run_seed: int, city_seed: int, length: float) -> void:
	if not _log:
		return
	_clock = 0.0
	_day_open = true
	_log.header("")
	_log.header("day %-2d act %d  run seed %d  city seed %d  length %.1fs"
			% [day, act, run_seed, city_seed, length])

## Closes a day's section. The clock stops here, so the between-days screen — during which the
## tree is paused anyway — cannot advance it.
func end_day() -> void:
	_day_open = false

func end_run() -> void:
	if not _log:
		return
	_log.close()
	_log = null
	_day_open = false

## One thing that happened. `kind` is the column a reader scans down; reuse the kinds listed
## in docs/TELEMETRY.md rather than inventing a synonym for one of them.
func note(kind: String, text: String) -> void:
	if not _log:
		return
	_log.note(_clock, kind, text)

## The day clock, in seconds since dawn. Pushed in rather than counted here so that the log
## and the HUD never disagree: there is one clock in the game and this is a mirror of it.
func set_clock(seconds: float) -> void:
	if _day_open:
		_clock = seconds

func clock() -> float:
	return _clock

## The live log, for tests. Null unless a run is being traced.
func current_log() -> TelemetryLog:
	return _log

# ----------------------------------------------------------------- provenance ---

## The commit the run was played on, with a `*` if the working tree was dirty.
##
## Without it a trace cannot be checked against anything: "day one was brutal" is only a
## finding if the code that produced it can be got back. A dirty tree is worth marking rather
## than hiding, because it means the log describes something no commit reproduces — the
## reading is still useful, it just cannot be replayed by checking a hash out.
##
## Asked of `git` at runtime rather than baked in, because the project has no build step to
## bake it during — `tools/run.sh` starts the engine on the working tree. An exported build
## has no repository to ask, which is what "unknown" means; the traces worth reading come off
## a developer's machine either way.
static func source_version() -> String:
	var repository := ProjectSettings.globalize_path("res://")
	var hash_out: Array = []
	if OS.execute("git", ["-C", repository, "rev-parse", "--short", "HEAD"], hash_out) != 0:
		return "unknown"
	var commit := ("\n".join(hash_out)).strip_edges()
	if commit == "":
		return "unknown"
	var status: Array = []
	# Untracked files count as dirty. The conservative reading is the right one: the mark
	# only claims "this is not exactly that commit", and it should never claim otherwise.
	if OS.execute("git", ["-C", repository, "status", "--porcelain"], status) != 0:
		return commit
	return commit + ("*" if ("\n".join(status)).strip_edges() != "" else "")

# ------------------------------------------------------------------ the files ---

func _prepare_directory() -> bool:
	if not DirAccess.dir_exists_absolute(DIRECTORY):
		if DirAccess.make_dir_recursive_absolute(DIRECTORY) != OK:
			push_warning("telemetry: cannot create %s" % DIRECTORY)
			return false
	_prune()
	return true

## Keeps the newest `KEEP_LOGS` and deletes the rest. Only files this class named: the
## directory is ours, but deleting by pattern rather than by "everything else" means a note
## somebody dropped in there by hand survives.
func _prune() -> void:
	var dir := DirAccess.open(DIRECTORY)
	if not dir:
		return
	var ours: Array[String] = []
	for file in dir.get_files():
		if file.begins_with("run-") and file.ends_with(".log"):
			ours.append(file)
	if ours.size() < KEEP_LOGS:
		return
	# The name carries the timestamp, so sorting by name sorts by age.
	ours.sort()
	for i in ours.size() - KEEP_LOGS + 1:
		dir.remove(ours[i])
