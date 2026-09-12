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

var _log: TelemetryLog
## Seconds into the current day, fed by the observer from the day clock so that a timestamp
## in the log and the clock in the HUD are the same number.
var _clock := 0.0
var _day_open := false
## The current run's own folder, absolute — every artefact of this run is written under it.
## `""` when the log is in memory only, which is what the test suite runs on.
var _run_dir := ""
## How many times `begin_day()` has opened each day number this run. A nerve buys another attempt
## at the same day without the calendar advancing — see `GameState.finish_day()` — so `begin_day`
## is called again with the day number it just failed at, and this is what lets the second
## attempt's pictures say so instead of overwriting the first's. Reset at the start of a run.
var _day_attempts := {}
## The day currently open's attempt number, `1` on a first attempt — mirrors
## `_day_attempts[day]` for whichever day that is, kept as its own field so nothing that names a
## file has to be handed the day number back in just to look the count up again.
var _attempt := 1

## Whether anything is being recorded. Everything else here is a no-op when this is false.
func is_active() -> bool:
	return _log != null

## Opens a log for a run, in its own folder under `DIRECTORY`. Called by `main.gd` and by nothing
## else — a system that wants to be traced calls `note()` and lets this decide whether anyone is
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
## Whether the deployed page has asked, this run, to be logged anyway. Read through
## `JavaScriptBridge.eval("window.location.search")` — the one channel that reaches a Web export at
## all, since the page it runs on has no command line for `DevFlags` to parse.
##
## **Gated behind `DevFlags.enabled()` (`OS.is_debug_build()`), the same as every other developer
## flag now.** *(2026-09-06, the player: "I never asked for telemetry on web. you added that to
## debug in a browser. that browser build should be dev only the CI build is release.")* A release
## build must answer nothing here — the published page collecting from a stranger's browser because
## of a query string nobody documented is exactly what a release build carrying no modifiers rules
## out. A debug build answers immediately, with nothing else to unlock: the browser used to debug a
## web build is its own debug export (`tools/export-web.sh debug`), and the published build is the
## release export. `_reads_the_url()` below is the gate itself, pulled out to a pure function so the
## promise is a truth table a test can check rather than a build type nothing can fake.
static func _web_override_requested() -> bool:
	if not _reads_the_url(DevFlags.enabled(), OS.get_name() == "Web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search")
	if typeof(search) != TYPE_STRING:
		return false
	return _telemetry_flag_from_query(search)

## The decision behind `_web_override_requested()`'s own gate, pulled out to a pure function of its
## two inputs so the promise is a truth table a test can check rather than a build type nothing can
## fake: a one-line boolean `and` is not worth a module this file would have to import for one call
## site, and the next modifier this project gains should have an obvious static function to copy,
## not a dependency to go find. debug and web is the one case `?telemetry=1`
## exists for; release and web — the published page — is the case the promise is actually about.
static func _reads_the_url(is_debug: bool, on_web: bool) -> bool:
	return is_debug and on_web

## `"?telemetry=1"` (with or without a leading `?`, alongside any other parameter) reads as "log
## this run"; anything else — absent, or any other value — leaves the platform's own default in
## place. Pulled out from `_web_override_requested()` so a test can ask the parsing question
## directly, without a Web export to produce a real `window.location.search` to parse.
static func _telemetry_flag_from_query(query: String) -> bool:
	var trimmed := query.trim_prefix("?")
	for pair in trimmed.split("&"):
		var parts := pair.split("=")
		if parts.size() == 2 and parts[0] == "telemetry":
			return parts[1] == "1"
	return false

## **Silently does nothing on a web export, unless the page's own `?telemetry=1` says otherwise.**
## `user://` is browser storage there — a stranger's browser rather than a developer's disk — so by
## default nobody collects what lands in it and nobody would ever run `tools/telemetry.sh` against
## it. Checked here rather than by the one caller, so a future caller cannot reintroduce a run log
## on the one platform where nobody would ever read or clear it without also reintroducing the one
## way to override that. See `_web_override_requested()` for what turns it back on.
func begin_run(run_seed: int, played := true) -> void:
	end_run()
	if OS.has_feature("web") and not _web_override_requested():
		return
	if not DirAccess.dir_exists_absolute(DIRECTORY) \
			and DirAccess.make_dir_recursive_absolute(DIRECTORY) != OK:
		push_warning("telemetry: cannot create %s" % DIRECTORY)
		return
	# "YYYY-MM-DDTHH:MM:SS" — split rather than reformatted, so the date half is exactly what a
	# person reads as today's date and the time half needs only its colons stripped to be a
	# folder-safe word.
	var stamp := Time.get_datetime_string_from_system(false, false)
	var day_folder := stamp.get_slice("T", 0)
	var time_part := stamp.get_slice("T", 1).replace(":", "")
	_run_dir = "%s/%s/%s-%s-seed%d-%s" % [DIRECTORY, day_folder,
			"run" if played else "rig", time_part, run_seed, _file_tag()]
	if DirAccess.make_dir_recursive_absolute(_run_dir) != OK:
		push_warning("telemetry: cannot create %s" % _run_dir)
		_run_dir = ""
		return
	_log = TelemetryLog.new("%s/run.log" % _run_dir)
	_clock = 0.0
	_day_open = false
	_shots_today = 0
	_last_shot = -INF
	_day_attempts = {}
	_attempt = 1
	_log.header("nappy %s log  %s  version %s"
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
	_run_dir = ""
	_clock = 0.0
	_day_open = false
	_day_attempts = {}
	_attempt = 1
	_log.header("nappy run log  (memory)")

## Starts a day's section. Everything after this is timestamped from zero.
##
## **Also where the attempt is counted.** A nerve retries a lost day without the calendar
## advancing — see `GameState.finish_day()` — so this is called again with the same `day`, and
## `_day_attempts[day]` counts how many times that has happened. `_attempt` is a first attempt
## (`1`) until it is not, and `_attempt_suffix()` is what turns that into a filename fragment.
func begin_day(day: int, act: int, run_seed: int, city_seed: int, length: float) -> void:
	if not _log:
		return
	_day_attempts[day] = int(_day_attempts.get(day, 0)) + 1
	_attempt = _day_attempts[day]
	_clock = 0.0
	_day_open = true
	_shots_today = 0
	_last_shot = -INF
	_log.header("")
	var line := "day %-2d act %d  run seed %d  city seed %d  length %.1fs" \
			% [day, act, run_seed, city_seed, length]
	# Noted the same way the seed is, once per day rather than as a per-frame entry, so a log
	# from an --invincible day cannot be mistaken for one where a loss actually meant anything.
	if DevFlags.invincible():
		line += "  invincible"
	_log.header(line)

## Closes a day's section. The clock stops here, so the between-days screen — during which the
## tree is paused anyway — cannot advance it.
func end_day() -> void:
	_cancel_burst("day ended")
	_day_open = false

func end_run() -> void:
	_cancel_burst("run ended")
	if not _log:
		return
	_log.close()
	_log = null
	_day_open = false

func _cancel_burst(reason: String) -> void:
	if _burst.size() == 0:
		return
	_finish_burst(int(_burst["token"]), "cancelled", reason)

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

const BURST_VERSION := 1
const BURST_TARGET_FPS := 12
const BURST_DURATION_SECONDS := 3.0
const BURST_MAX_FRAMES := 36
var _burst: Dictionary = {}
var _burst_serial := 0
var _burst_token := 0

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
	_capture(_real_time_path(_type_dir("auto"), kind))

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
	_capture(_real_time_path(_type_dir("asked"), "asked"))

## Starts one bounded animation sequence in the current run's `asked/` folder. The sequence is
## serialized one frame at a time so a slow PNG write cannot create an unbounded backlog, and the
## timestamps record what the capture actually achieved rather than claiming the target rate.
func start_burst(context: String) -> bool:
	if _burst.size() > 0:
		note("shot", "burst refused: another burst is active")
		return false
	if not _log or _log.path == "" or DisplayServer.get_name() == "headless":
		if _log:
			note("shot", "burst refused: no drawable viewport")
		print("[Telemetry] burst refused: no drawable viewport")
		return false
	var asked_dir := _type_dir("asked")
	var burst_path := _next_burst_path(asked_dir)
	if DirAccess.make_dir_recursive_absolute(burst_path) != OK:
		note("shot", "burst refused: could not create %s" % burst_path)
		push_warning("telemetry: could not create burst directory %s" % burst_path)
		return false
	var started_usec := Time.get_ticks_usec()
	_burst_token += 1
	_burst = {
		"dir": burst_path,
		"context": context,
		"started_usec": started_usec,
		"frames": [],
		"status": "active",
		"reason": "",
		"token": _burst_token,
	}
	if not _write_burst_metadata():
		_burst.clear()
		note("shot", "burst refused: could not write metadata")
		push_warning("telemetry: burst metadata could not be written")
		return false
	note("shot", "burst started: %s | asked/%s" % [context, burst_path.get_file()])
	print("[Telemetry] burst started: %s" % ProjectSettings.globalize_path(burst_path))
	var deadline := get_tree().create_timer(BURST_DURATION_SECONDS, true)
	deadline.timeout.connect(_on_burst_deadline.bind(_burst_token), CONNECT_ONE_SHOT)
	_capture_burst(_burst_token)
	return true

func _next_burst_path(asked_dir: String) -> String:
	_burst_serial += 1
	var stamp := Time.get_ticks_usec()
	var candidate := "%s/burst-%d-%03d" % [asked_dir, stamp, _burst_serial]
	while DirAccess.dir_exists_absolute(candidate) or FileAccess.file_exists(candidate):
		_burst_serial += 1
		candidate = "%s/burst-%d-%03d" % [asked_dir, stamp, _burst_serial]
	return candidate

func _on_burst_deadline(token: int) -> void:
	_finish_burst(token, "duration")

func _burst_is_current(token: int) -> bool:
	return _burst.size() > 0 and int(_burst.get("token", -1)) == token

## Chooses the terminal condition before a render wait, so a stalled renderer cannot add a frame
## beyond either bound. Duration wins at the shared boundary because it describes the elapsed run.
static func _burst_finish_reason(elapsed: float, frame_count: int) -> String:
	if elapsed >= BURST_DURATION_SECONDS:
		return "duration"
	if frame_count >= BURST_MAX_FRAMES:
		return "frame_cap"
	return ""

func _capture_burst(token: int) -> void:
	if not _burst_is_current(token):
		return
	var burst_dir := str(_burst.get("dir", ""))
	var started_usec := int(_burst.get("started_usec", 0))
	while _burst_is_current(token):
		var elapsed := float(Time.get_ticks_usec() - started_usec) / 1000000.0
		var frames: Array = _burst["frames"]
		var finish_reason := _burst_finish_reason(elapsed, frames.size())
		if finish_reason != "":
			_finish_burst(token, finish_reason)
			return
		await RenderingServer.frame_post_draw
		if not _burst_is_current(token):
			return
		elapsed = float(Time.get_ticks_usec() - started_usec) / 1000000.0
		if elapsed >= BURST_DURATION_SECONDS:
			_finish_burst(token, "duration")
			return
		var viewport := get_viewport()
		if not viewport:
			_finish_burst(token, "write_failed", "viewport disappeared")
			return
		var image := viewport.get_texture().get_image()
		var captured_usec := Time.get_ticks_usec()
		elapsed = float(captured_usec - started_usec) / 1000000.0
		frames = _burst["frames"]
		var frame_number: int = frames.size() + 1
		var file_name := "frame-%04d.png" % frame_number
		var result := image.save_png("%s/%s" % [burst_dir, file_name])
		if result != OK:
			_finish_burst(token, "write_failed", "could not write %s" % file_name)
			return
		frames.append({"file": file_name, "elapsed_seconds": elapsed})
		if not _write_burst_metadata():
			_finish_burst(token, "write_failed", "could not update burst metadata")
			return
		if not _burst_is_current(token):
			return
		var wait_seconds := (float(frames.size()) / float(BURST_TARGET_FPS)) - elapsed
		if wait_seconds > 0.0:
			await get_tree().create_timer(wait_seconds, true).timeout
	if _burst_is_current(token):
		_finish_burst(token, "duration")

func _finish_burst(token: int, reason: String, detail := "") -> void:
	if not _burst_is_current(token):
		return
	var path := str(_burst["dir"])
	var count: int = (_burst["frames"] as Array).size()
	var finished_with_frames := (reason == "duration" or reason == "frame_cap") and count > 0
	var ending := detail if detail != "" else reason
	if not finished_with_frames and count == 0 and reason == "duration":
		ending = "no frames captured before deadline"
	_burst["status"] = "complete" if finished_with_frames else "cancelled"
	_burst["reason"] = ending
	var outcome := str(_burst["status"])
	var wrote_metadata := _write_burst_metadata()
	_burst.clear()
	if not wrote_metadata:
		note("shot", "burst abandoned: metadata write failed")
		push_warning("telemetry: burst metadata could not be finalized")
		return
	note("shot", "burst %s: %d frames | %s" % [outcome, count, ending])
	print("[Telemetry] burst %s: %s (%d frames)"
			% [outcome, ProjectSettings.globalize_path(path), count])

func _write_burst_metadata() -> bool:
	if _burst.size() == 0:
		return false
	var elapsed := float(Time.get_ticks_usec() - int(_burst["started_usec"])) / 1000000.0
	var metadata := {
		"schema_version": BURST_VERSION,
		"frames": _burst["frames"],
		"duration_seconds": elapsed,
		"target_fps": BURST_TARGET_FPS,
		"context": _burst["context"],
		"status": _burst["status"],
		"reason": _burst["reason"],
	}
	var file := FileAccess.open("%s/burst.json" % _burst["dir"], FileAccess.WRITE)
	if not file:
		push_warning("telemetry: could not write burst metadata")
		return false
	file.store_string(JSON.stringify(metadata, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_warning("telemetry: could not flush burst metadata")
		return false
	return true

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
##
## **A day played twice writes two pictures.** A nerve retries a lost day without the calendar
## advancing, so this is called again for the same `day` — and without the attempt in the name the
## second attempt's maps would overwrite the first's, destroying the picture of the day that went
## wrong. `_attempt_suffix()` names the attempt every time, including the first, so a filename is
## never ambiguous about which attempt it came from and there is only one shape to read.
func write_map(map: CityMap, day: int, closures: Array[RoadClosure] = [],
		tree: RouteTree = null, plans: Array[EventScheduler.Planned] = [],
		at_dusk := false, trail: Array[Vector3] = [], met: Dictionary = {}) -> void:
	if not _log or _log.path == "":
		return
	var path := "%s/day%02d%s%s.png" % [_type_dir("maps"), day, _attempt_suffix(),
			"-dusk" if at_dusk else ""]
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

## The version the run was played on: `git describe`'s own form, `<tag>-<commits-since>-g<hash>`
## (e.g. `v0.0.0-49-gab12cd3`), or a bare abbreviated hash where no tag is reachable, with
## `-dirty` appended if the working tree was not clean.
##
## Without it a trace cannot be checked against anything: "day one was brutal" is only a finding
## if the code that produced it can be got back. Naming the tag as well as the hash is what lets a
## reader tell *which release this is close to* without opening a shell — the same question
## `tools/release.sh` exists to answer when cutting one.
##
## **Dirty is asked separately from `git describe`, not folded into its own `--dirty` flag.**
## `git describe --dirty` only looks at tracked files (`git diff-index`), so a file that has never
## been committed leaves it silent — checked empirically, since the difference is easy to miss
## reading the manual. The `status --porcelain` check below is the one this file always used, and
## untracked files still count as dirty under it: the mark only ever claims "this is not exactly
## that commit", and it must never claim otherwise.
##
## Asked of `git` at runtime rather than baked in, because the project has no build step to
## bake it during — `tools/run.sh` starts the engine on the working tree. An exported build
## has no repository to ask, which is what "unknown" means; `application/config/version` is what
## a deployed build shows instead — see `TitleScreen`.
static func source_version() -> String:
	var repository := ProjectSettings.globalize_path("res://")
	var describe_out: Array = []
	if OS.execute("git", ["-C", repository, "describe", "--tags", "--always"], describe_out) != 0:
		return "unknown"
	var version := ("\n".join(describe_out)).strip_edges()
	if version == "":
		return "unknown"
	var status: Array = []
	if OS.execute("git", ["-C", repository, "status", "--porcelain"], status) != 0:
		return version
	return version + ("-dirty" if ("\n".join(status)).strip_edges() != "" else "")

## The same thing, kept as its own name because the run folder and `tools/telemetry.sh -p` both
## call this rather than `source_version()` directly.
##
## The two used to differ: `source_version()` wrote a bare `*` for a dirty tree — the log's own
## first-line mark — and this turned it into the shell-safe word `-dirty` for a folder name and a
## `sed` match. `git describe` now writes `-dirty` itself, so what this function does changed even
## though what it produces for a caller did not.
static func _file_tag() -> String:
	return source_version()

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

## Names a snapshot from the wall clock, not the day clock. *(2026-09-11, playtest 56: "phot
## capture must use real time not game time otherwise at the end of the day all pictures get
## overwritten".)* `--invincible` clamps the countdown to exactly zero once a day runs out rather
## than ending it (`DayController._process()`), which holds the elapsed day clock this file reads
## (`time_total - time_remaining`) at the day's own length for as long as the day keeps running
## afterward — so every picture taken past dusk that day named itself identically and each
## overwrote the last; even off that flag, two pictures within the same in-game second collided
## the same way. The wall clock a picture was actually taken at can only repeat if two calls land
## in the same **millisecond**, which `_unique_path()` still catches with a serial rather than
## silently overwriting.
##
## `<HHMMSS>-<mmm><attempt suffix>-<kind>.png` — hour, minute and second so a directory listing
## already sorts by time of day, then milliseconds for the precision a day clock could not give,
## then the existing attempt suffix and kind so a name is unique both across a retried day and
## across what asked for the picture. Split from `_unique_path()` so a test can check the format
## without touching disk.
static func _real_time_stem(kind: String, attempt_suffix: String) -> String:
	var now := Time.get_datetime_dict_from_system()
	var millisecond := int(fmod(Time.get_unix_time_from_system(), 1.0) * 1000.0)
	return "%02d%02d%02d-%03d%s-%s" % [now["hour"], now["minute"], now["second"], millisecond,
			attempt_suffix, kind]

## `dir/stem.png`, or `dir/stem-<serial>.png` the first time that name is already taken — the
## guard `_real_time_stem()` alone cannot give, since two calls in the same millisecond still ask
## for the same name. The serial starts at 2 so the first picture with a given stem keeps the
## plain name and only a genuine collision grows a suffix.
static func _unique_path(dir: String, stem: String) -> String:
	var path := "%s/%s.png" % [dir, stem]
	var serial := 1
	while FileAccess.file_exists(path):
		serial += 1
		path = "%s/%s-%d.png" % [dir, stem, serial]
	return path

## What `snapshot()` and `snapshot_now()` both name their picture with — one helper so the two
## call sites cannot drift into two different shapes of filename.
func _real_time_path(dir: String, kind: String) -> String:
	return _unique_path(dir, _real_time_stem(kind, _attempt_suffix()))
