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
## The log's own filename without its extension, so a screenshot can be named after the run it
## belongs to and sort next to it.
var _stem := ""

## Whether anything is being recorded. Everything else here is a no-op when this is false.
func is_active() -> bool:
	return _log != null

## Opens a log for a run. Called by `main.gd` and by nothing else — a system that wants to be
## traced calls `note()` and lets this decide whether anyone is listening.
##
## **`played` says whether a person was at the controls, and it is the caller's answer rather than
## something guessed here.** A pile of logs that does not say which of them a person played reads as
## a great many plays that never happened, and every inference drawn from it is skewed. A rig's log
## opens with the stem `rig-` instead of `run-`, so the question is answered by a directory listing
## — the same reason the commit is in the name.
##
## **The tool already had a proxy for this and the proxy is why it had to be said out loud.**
## `tools/telemetry.sh` calls anything under 3kB "a boot that never became a run", which catches
## `check.sh` and a doorstep screenshot and misses the case that matters most — a
## `shot.sh --walk 60` writes a large, busy, entirely unplayed log. That is this project's own
## recurring mistake in miniature: **a proxy that is equivalent in the ideal case is not equivalent
## in a street**, and every measurement taken of the proxy agrees with it.
##
## **Silently does nothing on a web export.** `user://` is browser storage there, nobody collects
## it, and it has no `tools/telemetry.sh` to prune it — see `KEEP_LOGS`, which only ever runs on
## the machine that wrote the logs it is counting. Checked here rather than by the one caller, so
## a future caller cannot reintroduce a run log on the one platform where nobody would ever read
## or clear it.
func begin_run(run_seed: int, played := true) -> void:
	end_run()
	if OS.has_feature("web"):
		return
	if not _prepare_directory():
		return
	var stamp := Time.get_datetime_string_from_system(false, false).replace(":", "").replace(" ", "-")
	# **The commit is in the name, not only on line 1.** On the first line it is no help when the
	# question is asked of a directory listing — and it is always asked of a listing, because what
	# a reader wants to know first is *which of these is still about this build*, in order to
	# delete the rest. `tools/telemetry.sh -p` is the other half.
	# The tag goes **last**, and that is not a cosmetic choice: the timestamp has dashes in it and so
	# does `abc1234-dirty`, so a tag in the middle cannot be parsed back out by anything simpler than
	# a real parser — and the thing that has to parse it is a bash script old enough to run on
	# macOS's bash 3.2. At the end it is "everything after `-seed<digits>-`".
	_stem = "%s-%s-seed%d-%s" % ["run" if played else "rig", stamp, run_seed, _file_tag()]
	_log = TelemetryLog.new("%s/%s.log" % [DIRECTORY, _stem])
	_clock = 0.0
	_day_open = false
	_shots_today = 0
	_last_shot = -INF
	_log.header("nappy %s log  %s  commit %s"
			% ["run" if played else "rig", Time.get_datetime_string_from_system(),
			source_version()])
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
	_shots_today = 0
	_last_shot = -INF
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

# ---------------------------------------------------------------- snapshots ---
# A trace says what happened and a screenshot says what it **looked like**, and the second question
# is the one this project keeps having to answer with a rig. The defects a log cannot see are a
# whole class: birds that freeze in the air, a cat drawn running backwards, a zzz a body's width
# off the pram, a caret over the wrong things.
#
# Three constraints, and the first is the one the whole file is built on:
#
# - **It must not touch gameplay.** A capture reads the viewport after the frame is drawn and writes
#   a file. It draws nothing, it changes no state, and it takes no RNG. The `await` is on
#   `RenderingServer.frame_post_draw`, which is where a frame that already exists becomes readable.
# - **The heuristic is the log's own.** There is no fixed interval. A shot is taken on the entries a
#   reader already stops at — a day lost, a chase, a lethal cue — because those are exactly the lines
#   that raise the question a picture answers. See `TelemetryObserver`.
# - **It has to stay small.** Capped per day and spaced, because a burst of near-identical frames is
#   a directory nobody opens.

## The most shots one day may produce, and the least time between two of them.
##
## Six is about one per losing attempt plus the moment before it. The spacing is longer than any cue
## in the game holds for, so a condition that is true for two seconds is one picture rather than a
## hundred and twenty.
const SHOTS_PER_DAY := 6
const SHOT_SPACING := 3.0

var _shots_today := 0
var _last_shot := -INF

## Writes a PNG of the current frame beside the log, named after the moment that asked for it.
##
## Silently does nothing when there is no run being traced, when the day's allowance is spent, when
## another shot was taken a moment ago, or when there is no screen to photograph — a headless test
## run has a viewport with nothing in it, and the suite must not start writing images.
func snapshot(kind: String) -> void:
	if not _log or _log.path == "" or _shots_today >= SHOTS_PER_DAY:
		return
	if _clock - _last_shot < SHOT_SPACING:
		return
	if DisplayServer.get_name() == "headless":
		return
	_shots_today += 1
	_last_shot = _clock
	_capture("%s/%s-%03.0fs-%s.png" % [DIRECTORY, _stem, _clock, kind])

## The same picture, asked for by a person rather than by a heuristic. A debugging aid rather than
## a game feature.
##
## **It bypasses `SHOTS_PER_DAY` and `SHOT_SPACING`, and that is the whole difference.** Those two
## exist because a heuristic firing on a condition that stays true for two seconds would write a
## hundred and twenty near-identical frames; somebody pressing a key has already decided this frame
## is worth keeping, and a cap that silently swallows the seventh press is a tool that lies about
## having worked. It still writes nothing headless, because there is nothing to photograph.
##
## The `note` is what makes it more than a screenshot: a picture in a directory is a mystery a week
## later, and a picture with a line of the trace beside it is evidence. The caller supplies the
## context, because this file must not start asking the world questions.
## **The note is written whenever there is a log at all, and only the picture needs a file to sit
## beside.** The two halves are guarded separately on purpose: a log with no path is a real state —
## it is what `begin_memory_log()` produces and what the whole suite runs on — and folding the two
## guards together made the entry disappear along with the PNG, which is the valuable half going
## missing in exactly the configuration that can still keep it.
func snapshot_now(context: String) -> void:
	if not _log:
		return
	note("shot", context)
	if _log.path == "" or DisplayServer.get_name() == "headless":
		return
	_shots_today += 1
	_capture("%s/%s-%03.0fs-asked.png" % [DIRECTORY, _stem, _clock])

# --------------------------------------------------------------- the city grid ---

## Writes a picture of the whole tile grid beside the log.
##
## Called once per day rather than once per run, because the lattice is fixed and **what a block is
## is not**: an arc requisitions a park, a fire leaves a shell, and today's closures are down. See
## `TelemetryMap`, which does the drawing and carries the reasoning.
##
## It takes the day rather than reading `GameState`, for the reason everything in this file takes
## what it needs: the telemetry asks the world no questions, so it can never be the thing that
## changed one.
## It also draws the day's **corridor**. The tree is grown here when the caller has none
## to hand, and that is safe rather than convenient: `RouteTree.for_day` is a pure function of the
## city's seed, the day and what is shut, so the tree drawn is the same tree anything else that
## asks for today's would get. Growing one touches no gameplay stream and cannot move a placement,
## which is the invariant this whole file is built on.
## It also draws what the day **placed**, and that is why it is written twice.
##
## `at_dusk` is only the filename, and the difference between the two pictures is entirely in
## `trail` and `met`: at dawn there is no walk yet, so both are left at their empty default and the
## picture is purely *what the day intended*; at dusk `TelemetryObserver` hands over where she
## actually went and which of `plans` she came close enough to for it to have cost her anything, so
## the same picture also says **what she did about it**. Neither picture is derivable from the
## other and neither is the more useful one — a wall in the wrong place is visible in the first, and
## a corridor nothing on it was ever met is visible only in the second.
##
## `trail` and `met` are `TelemetryObserver`'s own lists — see `TelemetryObserver.trail()` and
## `.met_events()` — passed through untouched. Reading them here takes no RNG and changes nothing
## about either list, the same promise every other argument to this function already keeps.
func write_map(map: CityMap, day: int, closures: Array[RoadClosure] = [],
		tree: RouteTree = null, plans: Array[EventScheduler.Planned] = [],
		at_dusk := false, trail: Array[Vector3] = [], met: Dictionary = {}) -> void:
	if not _log or _log.path == "":
		return
	var path := "%s/%s-map-day%02d%s.png" % [DIRECTORY, _stem, day, "-dusk" if at_dusk else ""]
	var drawn := tree if tree else RouteTree.for_day(map, day)
	if TelemetryMap.render(map, closures, drawn, plans, trail, met).save_png(path) != OK:
		push_warning("telemetry: could not write %s" % path)

## The capture itself, split out because it is the only thing here that has to wait for a frame.
##
## The `await` is why this is not inlined: `snapshot()` is called from the middle of an observer's
## `_process`, and a caller that had to be a coroutine would put an `await` in the telemetry's
## consumers — which is the shape of a rule ("telemetry never touches gameplay") quietly becoming
## untrue.
func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var viewport := get_viewport()
	if not viewport:
		return
	var image := viewport.get_texture().get_image()
	if image.save_png(path) != OK:
		push_warning("telemetry: could not write %s" % path)

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

## The same thing in a form a filename can carry, and a shell script can match on.
##
## `*` is the dirty marker on line 1 of the log and is a glob character everywhere else, so it
## becomes a word: `tools/telemetry.sh -p` compares the tag against `git rev-parse --short HEAD` and
## a marker that expanded in a shell would make that comparison delete the wrong things.
static func _file_tag() -> String:
	return source_version().replace("*", "-dirty")

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
		_remove_run(dir, ours[i].trim_suffix(".log"))

## Deletes a log and the snapshots taken during it. They are one artefact — a line and the
## picture of it — so a pruned run must not leave its images behind, which would otherwise be the
## only thing in the directory nothing ever cleans up.
func _remove_run(dir: DirAccess, stem: String) -> void:
	dir.remove(stem + ".log")
	for file in dir.get_files():
		if file.begins_with(stem + "-") and file.ends_with(".png"):
			dir.remove(file)
