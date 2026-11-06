class_name Telemetry
extends Node
## The run log: one per sitting, handed to everything that writes a line into it.
##
## **Handed in, never fetched.** `main`, the composition root, makes one under the sitting on its
## first boot (`Sitting`), so it outlives the scene reloads a run makes as the save does, and finds
## it there after; it hands it to `RunSession`, which opens and closes it and hands it to the
## `TelemetryObserver`, and whatever else writes a line is handed the session's `RunTrace` over its
## `note()`. A suite makes one of its own and hands it the same way (`main.use_run_log()`), so no
## suite reads or leaves behind a log another can see.
##
## **Inert until `begin_run()`.** Nothing writes a file, opens a directory or costs a string
## concatenation until the game itself asks for a run to be traced. `note()` on a dormant log is a
## boolean check and a return.
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
##
## **The game never deletes anything under here.** *(2026-09-03: "no automatic cleanup anymore",
## "the folder structure allows for easily deleting old days/commits".)* Every run gets its own
## folder, `<day>/<run>/` (see `begin_run()`), precisely so a person can `rm -rf` a whole
## day or a single run by hand once the directory is bigger than they
## want — a run's own name carries the commit too, so a glob on that picks out every run played on a
## build that no longer exists. That is a decision for whoever is looking at the directory, not one
## the game makes behind them — `tools/telemetry.sh -p` is the one tool that still deletes anything,
## and it does that because somebody ran it, not on its own.
const DIRECTORY := "user://telemetry"

## The name `main` gives the sitting's log, and what the next boot looks for under the sitting.
const NODE_NAME := "RunLog"

## Where this log's day folders go: `DIRECTORY` for the game's, a scratch folder for a suite that
## opens a real run, or `""` for a log that keeps each run in memory only, writing no folder, no file
## and no picture, which is what a suite hands the game for a run it reads back.
var _directory := DIRECTORY

var _log: TelemetryLog
## Seconds into the current day, fed by the observer from the day clock so that a timestamp
## in the log and the clock in the HUD are the same number.
var _clock := 0.0
var _day_open := false
## The current run's own folder, absolute — every artefact of this run is written under it.
## `""` when the log is in memory only, which is what the test suite runs on.
var _run_dir := ""
## How many times `begin_day()` has opened each day number this run. A nerve buys another attempt
## at the same day without the calendar advancing — see `RunCalendar.finish_day()` — so
## `begin_day` is called again with the day number it just failed at, and this is what lets the
## second attempt's pictures say so instead of overwriting the first's. Reset at the start of a
## run.
var _day_attempts := {}
## The day currently open's attempt number, `1` on a first attempt — mirrors
## `_day_attempts[day]` for whichever day that is, kept as its own field so nothing that names a
## file has to be handed the day number back in just to look the count up again.
var _attempt := 1

## The run's configuration, handed in by `main` at boot (`configure()`), or `null` before then —
## read for `--invincible`'s header note and for the page's `?telemetry=1`.
var _config: RunConfig

## A log whose runs go under `directory`; the game makes one with none, which is the player's own
## folder (`DIRECTORY`).
func _init(directory := DIRECTORY) -> void:
	_directory = directory

## Hands this log the run's configuration. `null` puts it back to none, which reads as a run with
## no flag at all.
func configure(config: RunConfig) -> void:
	_config = config

func _invincible() -> bool:
	return _config != null and _config.invincible

## Whether anything is being recorded. Everything else here is a no-op when this is false.
func is_active() -> bool:
	return _log != null

## Opens a log for a run, in its own folder under the log's directory (`_directory`). Called by
## `RunSession.open()` and by nothing else — a system that wants to be traced calls `note()` and lets this decide whether anyone is
## listening.
##
## **The folder is `<day>/<run>`; the date and each run are independently removable.**
## *(2026-09-03: "hmm, the commit hash makes it hard to find a run maybe let's remove it from the
## folder structure" — a level per commit split a day's runs across folders, so listing a day did
## not list its runs; "and add a more granular timestamp as an intermediate folder", "minute
## precision".)*
##
## - `<day>` is the calendar date the run was played (not the in-game day), so a bad week can go
##   with one `rm -rf` of its date folders.
## - `<run>` is the individual run, and its name now carries what used to be split across two
##   folder levels: `run-` or `rig-` (see `played` below — the distinction `tools/stats.sh` counts
##   separately and `tools/telemetry.sh -l` lists), the full `HHMMSS` time of day, the seed, and
##   last `_file_tag()` — the `git describe` form the run was played on (`v0.0.0-49-gab12cd3`), or
##   the same with `-dirty` appended. `tools/telemetry.sh -p` compares that tail against the same
##   `git describe`, computed once as `HEAD_COMMIT`, by path alone, to say what is stale. Repeating
##   the hour and minute the parent folder already carries is a few redundant characters, and what
##   it buys is that the run folder still identifies itself once copied out on its own — into
##   `docs/evidence/`, or pasted into a message. The version goes **last** so that sorting the
##   folder names within one `<day>` still sorts by age, the time leading the name.
## - The log itself is `run.log`, directly in the run's folder rather than a suffix on a shared
##   stem — the folder is what says which run a file belongs to now, so the file only has to say
##   which file *within* the run it is.
##
## **`played` says whether a person was at the controls, and it is the caller's answer rather than
## something guessed here.** A pile of runs that does not say which of them a person played reads as
## a great many plays that never happened, and every inference drawn from it is skewed.
##
## Whether the deployed page has asked, this run, to be logged anyway: the page's own query, as the
## run read it at boot (`RunConfig.page_query`), since the page has no command line.
##
## **A debug build's alone, like every other developer flag** (2026-09-06, the player: "I never
## asked for telemetry on web. you added that to debug in a browser. that browser build should be
## dev only the CI build is release"). A release build answers nothing here — the published page
## collecting from a stranger's browser because of a query string nobody documented is exactly what
## a release build carrying no modifiers rules out. A debug build answers immediately: the browser
## used to debug a web build is its own debug export (`tools/export-web.sh debug`).
## `TelemetryPage.reads_the_url()` is the gate itself, pure so the promise is a truth table a test
## can check.
func _web_override_requested() -> bool:
	if _config == null \
			or not TelemetryPage.reads_the_url(_config.debug_build, OS.get_name() == "Web"):
		return false
	return TelemetryPage.asks_for_telemetry(_config.page_query)

## **Silently does nothing on a web export, unless the page's own `?telemetry=1` says otherwise.**
## `user://` is browser storage there — a stranger's browser rather than a developer's disk — so by
## default nobody collects what lands in it and nobody would ever run `tools/telemetry.sh` against
## it. Checked here rather than by the one caller, so a future caller cannot reintroduce a run log
## on the one platform where nobody would ever read or clear it without also reintroducing the one
## way to override that. See `_web_override_requested()` for what turns it back on.
##
## **The day folders go under the directory the log was made with** (`_init()`): the game's makes
## its runs under `DIRECTORY`; a suite that opens a real run makes its log over a scratch one, so it
## writes nothing under the player's own, and a log made over `""` keeps the run in memory, with no
## folder and no file, the same in-memory log `TelemetryLog` falls back to.
func begin_run(run_seed: int, played := true) -> void:
	end_run()
	if OS.has_feature("web") and not _web_override_requested():
		return
	_run_dir = ""
	if _directory != "" and not _open_the_run_folder(run_seed, played):
		return
	_log = TelemetryLog.new("%s/run.log" % _run_dir if _run_dir != "" else "")
	_clock = 0.0
	_day_open = false
	_shots.restart_schedule()
	_shots.restart_names()
	_day_attempts = {}
	_attempt = 1
	# A log in memory has no folder for a person to find, so its header names no time or version,
	# which would cost two `git` calls a suite makes for every log it opens.
	if _run_dir == "":
		_log.header("nappy %s log  (memory)" % ("run" if played else "rig"))
		return
	_log.header("nappy %s log  %s  version %s"
			% ["run" if played else "rig", Time.get_datetime_string_from_system(),
			BuildInfo.source_version()])
	if _log.path != "":
		print("[Telemetry] %s" % ProjectSettings.globalize_path(_log.path))

## Makes the run's own folder under `_directory` and sets `_run_dir` to it, or warns and answers
## false when it cannot be made, which leaves the run untraced.
func _open_the_run_folder(run_seed: int, played: bool) -> bool:
	if not DirAccess.dir_exists_absolute(_directory) \
			and DirAccess.make_dir_recursive_absolute(_directory) != OK:
		push_warning("telemetry: cannot create %s" % _directory)
		return false
	# "YYYY-MM-DDTHH:MM:SS" — split rather than reformatted, so the date half is exactly what a
	# person reads as today's date and the time half needs only its colons stripped to be a
	# folder-safe word.
	var stamp := Time.get_datetime_string_from_system(false, false)
	var day_folder := stamp.get_slice("T", 0)
	var time_part := stamp.get_slice("T", 1).replace(":", "")
	_run_dir = "%s/%s/%s-%s-seed%d-%s" % [_directory, day_folder,
			"run" if played else "rig", time_part, run_seed, _file_tag()]
	if DirAccess.make_dir_recursive_absolute(_run_dir) != OK:
		push_warning("telemetry: cannot create %s" % _run_dir)
		_run_dir = ""
		return false
	return true

## Starts a day's section. Everything after this is timestamped from zero.
##
## **Also where the attempt is counted.** A nerve retries a lost day without the calendar
## advancing — see `RunCalendar.finish_day()` — so this is called again with the same
## `day`, and `_day_attempts[day]` counts how many times that has happened. `_attempt` is a
## first attempt (`1`) until it is not, and `_attempt_suffix()` is what turns that into a
## filename fragment.
func begin_day(day: int, act: int, run_seed: int, city_seed: int, length: float) -> void:
	_open_a_day(day, "day %-2d act %d  run seed %d  city seed %d  length %.1fs"
			% [day, act, run_seed, city_seed, length])

## Starts one of the **escape's** sections, each a day of its own with its own day number — the
## building's and the city's, after the last day — and an attempt counted the way a day's is, so a
## retried section's lines are timed from its own start and its pictures carry its attempt. What
## heads it is the section's own words where a day has its act and its city seed: the city is the
## run's, already named by the run seed.
func begin_section(day: int, title: String, run_seed: int, length: float) -> void:
	_open_a_day(day, "day %-2d %s  run seed %d  length %.1fs" % [day, title, run_seed, length])

## The section either of the two above opens: the attempt counted, the clock at zero, the shot
## schedule cleared and the header written.
func _open_a_day(day: int, line: String) -> void:
	if not _log:
		return
	_day_attempts[day] = int(_day_attempts.get(day, 0)) + 1
	_attempt = _day_attempts[day]
	_clock = 0.0
	_day_open = true
	_shots.restart_schedule()
	_log.header("")
	# Noted the same way the seed is, once per day rather than as a per-frame entry, so a log
	# from an --invincible day cannot be mistaken for one where a loss actually meant anything.
	if _invincible():
		line += "  invincible"
	_log.header(line)

## Closes a day's section. The clock stops here, so the between-days screen — during which the
## tree is paused anyway — cannot advance it.
func end_day() -> void:
	_bursts.cancel("day ended")
	_day_open = false

func end_run() -> void:
	_bursts.cancel("run ended")
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

## The clock of whatever section is open, in seconds since it began — since dawn on a day, since
## the escape started on the escape. Pushed in rather than counted here so that the log and the
## HUD never disagree: there is one clock in the game and this is a mirror of it.
func set_clock(seconds: float) -> void:
	if _day_open:
		_clock = seconds

## The section's clock, put back to zero for a fresh walk — a retried section, or the second
## section beginning after the first — with the automatic-snapshot schedule reset alongside it.
##
## **`set_clock(0.0)` alone is not this.** It leaves the last shot's time wherever the previous walk's
## last automatic shot fell, so `snapshot()`'s spacing gate (the clock less the last shot's time under
## `SHOT_SPACING`)
## would stay true — the new clock read as still inside the old walk's three-second window — until
## the new walk's own clock climbed back past whatever the old one had reached, holding every
## automatic snapshot back for exactly that long. This gives a walk the same clean slate
## `begin_day()` gives a day's; `TelemetryObserver.start_section()` asks it as each section of the
## escape begins, after its own `begin_section()`.
func restart_section_clock() -> void:
	if not _day_open:
		return
	_clock = 0.0
	_shots.restart_schedule()

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
#   a file. It changes no state and it takes no RNG. The `await` is `DrawnFrame.wait()`,
#   which returns after `RenderingServer.frame_post_draw`, where a drawn frame becomes readable; the
#   one thing it may draw is that frame, on demand, when the window is hidden and the render loop is
#   drawing none — a picture of the state as it is, not a change to it.
# - **The heuristic is the log's own.** There is no fixed interval. A shot is taken on the entries a
#   reader already stops at — a day lost, a chase, a lethal cue — because those are exactly the lines
#   that raise the question a picture answers. See `TelemetryObserver`.
# - **It has to stay small.** Capped per day and spaced, because a burst of near-identical frames is
#   a directory nobody opens.

## The least time between two shots — `TelemetryShots` holds it, with the most shots one day may
## produce (`TelemetryShots.PER_DAY`) and the day's count; this is where it is named for the callers
## that read it.
const SHOT_SPACING := TelemetryShots.SPACING

## The day's allowance, the spacing and the run-wide counter that names every picture.
var _shots := TelemetryShots.new()

## What the run log photographs, asked by every still picture whether a frame can be drawn at all.
## `main` hands the log it makes the game's own viewport (`use_screen()`); a log `main` did not make
## (a suite's own) keeps the same viewport screen built here, over itself.
var _screen: TelemetryScreen = TelemetryViewportScreen.new(self)

## The animation bursts a person asks for (`start_burst()`), over the screen, the engine's clock and
## the tree's timers, and this log's `note`. A day or the run ending cuts its sequence short.
## `main` hands the log it makes the game's recorder (`use_bursts()`); a log `main` did not make
## keeps the one built here over the screen above.
var _bursts := _default_bursts()

## Hands this log the screen it photographs, and returns the one it had. `main` calls it on the log
## it makes, with the game's viewport; a suite hands its own log one that can draw into a scratch
## folder. It does not rebuild the bursts, which hold the screen they
## were built over (`use_bursts()`).
func use_screen(screen: TelemetryScreen) -> TelemetryScreen:
	var before := _screen
	_screen = screen
	return before

## Hands this log the recorder of the bursts a person asks for, and returns the one it had. `main`
## calls it on the log it makes, with the recorder it builds over the game's screen; a suite hands
## its own log one over a bench screen and clock.
func use_bursts(recorder: BurstRecorder) -> BurstRecorder:
	var before := _bursts
	_bursts = recorder
	return before

func _default_bursts() -> BurstRecorder:
	return BurstRecorder.new(_screen, BurstRecorder.Clock.new(self), note)

## Writes a PNG of the current frame beside the log, named after the moment that asked for it.
##
## Silently does nothing when there is no run being traced, when the day's allowance is spent, when
## another shot was taken a moment ago, or when there is no screen to photograph — a headless test
## run has a viewport with nothing in it, and the suite must not start writing images.
func snapshot(kind: String) -> void:
	if not _log or _log.path == "" or not _shots.allows(_clock):
		return
	if not _screen.can_draw():
		return
	_shots.take(_clock)
	_capture("%s/%s" % [_type_dir("auto"), _shots.next_name(kind, _attempt_suffix())])

## The same picture, asked for by a person rather than by a heuristic. A debugging aid rather than
## a game feature.
##
## **It bypasses `TelemetryShots.PER_DAY` and `SHOT_SPACING`, and that is the whole difference.** Those two
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
## it is what a log made over no directory opens, and what the whole suite runs on — and folding the two
## guards together made the entry disappear along with the PNG, which is the valuable half going
## missing in exactly the configuration that can still keep it.
func snapshot_now(context: String) -> void:
	if not _log:
		return
	note("shot", context)
	if _log.path == "" or not _screen.can_draw():
		return
	_shots.take_asked()
	_capture("%s/%s" % [_type_dir("asked"), _shots.next_name("asked", _attempt_suffix())])

## Starts one bounded animation sequence in the current run's `asked/` folder (`BurstRecorder`),
## refused with a line in the log while another is active or when there is no screen to read or no
## run folder to write in.
func start_burst(context: String) -> bool:
	var asked_dir := ""
	if _log and _log.path != "" and _screen.can_draw():
		asked_dir = _type_dir("asked")
	return _bursts.start(asked_dir, context)

# --------------------------------------------------------------- the city grid ---

## Writes a picture of the whole tile grid beside the log.
##
## Called once per day rather than once per run, because the lattice is fixed and **what a block is
## is not**: an arc requisitions a park, a fire leaves a shell, and today's closures are down. See
## `TelemetryMap`, which does the drawing and carries the reasoning.
##
## It takes the day rather than reading the run, for the reason everything in this file takes
## what it needs: the telemetry asks the world no questions, so it can never be the thing that
## changed one.
## It also draws the day's **corridor**, unless `corridor` says the walk has none (the escape's
## city). The tree is grown here when the caller has none to hand, and that is safe rather than
## convenient: `RouteTree.for_day` is a pure function of the
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
##
## **A day played twice writes two pictures.** A nerve retries a lost day without the calendar
## advancing, so this is called again for the same `day` — and without the attempt in the name the
## second attempt's maps would overwrite the first's, destroying the picture of the day that went
## wrong. `_attempt_suffix()` names the attempt every time, including the first, so a filename is
## never ambiguous about which attempt it came from and there is only one shape to read.
func write_map(map: CityMap, day: int, closures: Array[RoadClosure] = [],
		tree: RouteTree = null, plans: Array[EventScheduler.Planned] = [],
		at_dusk := false, trail: Array[Vector3] = [], met: Dictionary = {},
		corridor := true) -> void:
	if not _log or _log.path == "":
		return
	var path := "%s/day%02d%s%s.png" % [_type_dir("maps"), day, _attempt_suffix(),
			"-dusk" if at_dusk else ""]
	# The escape's city has no corridor — its walk is two chains, not a tree — so its map draws none
	# (`corridor` false) rather than one grown for a day that is not being walked.
	var drawn: RouteTree = null
	if corridor:
		drawn = tree if tree else RouteTree.for_day(map, day)
	if TelemetryMap.render(map, closures, drawn, plans, trail, met).save_png(path) != OK:
		push_warning("telemetry: could not write %s" % path)

## The capture itself, split out because it is the only thing here that has to wait for a frame.
##
## The `await` is why this is not inlined: `snapshot()` is called from the middle of an observer's
## `_process`, and a caller that had to be a coroutine would put an `await` in the telemetry's
## consumers — which is the shape of a rule ("telemetry never touches gameplay") quietly becoming
## untrue.
func _capture(path: String) -> void:
	await _screen.drawn()
	var image := _screen.picture()
	if image == null:
		return
	if image.save_png(path) != OK:
		push_warning("telemetry: could not write %s" % path)

# ----------------------------------------------------------------- provenance ---

## The version a run folder's name ends in — `BuildInfo.source_version()`, the `git describe` form
## with `-dirty` on a working tree that is not clean. `tools/telemetry.sh -p` compares a folder's
## tail against the same `git describe` to say what is stale.
static func _file_tag() -> String:
	return BuildInfo.source_version()

# ------------------------------------------------------------------ the files ---

## `-attempt<N>` on every name a run writes, including the first, so every filename has the same
## shape and nothing that reads or matches one has to handle a suffix that is sometimes there and
## sometimes not. See `begin_day()`, which is where `_attempt` is counted.
func _attempt_suffix() -> String:
	return "-attempt%d" % _attempt

## The folder one kind of picture lives in, within the current run — `auto` for the heuristic's own
## screenshots (`snapshot()`), `maps` for the day maps (`write_map()`), `asked` for a picture a
## person pressed a key for (`snapshot_now()`). Created the first time something is actually
## written there rather than eagerly at `begin_run()`, so a run that never triggers the heuristic
## — most of them — does not leave an empty `auto/` folder behind for a person to wonder about.
func _type_dir(name: String) -> String:
	var dir := "%s/%s" % [_run_dir, name]
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		push_warning("telemetry: cannot create %s" % dir)
	return dir
