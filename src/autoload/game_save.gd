class_name GameSave
extends RefCounted
## Persists a run to disk so the game can be closed and picked up again — see docs/MECHANICS.md,
## "Saving and resuming". Not an autoload: every member below is `static`, so the class is a
## namespace for file I/O and format policy rather than an object with a lifetime of its own. **It is
## handed the run it reads or writes** (`run: RunState`) on every call that touches one — `main` hands
## the run it plays, a test whichever run it built, and `RunState` itself for its checkpoint — and
## names no autoload for it. Handed per call rather than held: the web flush below and the operation
## ids outlive the scene reloads that free the `main` holding a run, and the run's own checkpoint
## calls `run_data()` and `restore_run_data()` too. Lives beside `RunState`, the one thing it reads
## and writes, rather than under `src/ui/` with the symbol that announces a write — a save module is
## data, the symbol is presentation, and the two only meet through `EventBus`.
##
## **The save is the run, never the moment inside a day.** The run's registered parts
## (`RunState.run_parts`) say what a run holds and where in the file each part sits; this file
## only adds the facts a run does not know about itself — whether a day was under way when the
## file was written, which section of the escape it is in, and which build
## wrote it — and turns the result into JSON. *Asked for "that exact state", the crowd included, and overturned by the player to a
## restart at dawn that costs a nerve* — see docs/MECHANICS.md, "Saving and resuming", for what
## that costs and why.
##
## **The escape's section rides beside those, not inside the snapshot.** `"escape_section"` is a
## top-level key like `"day_under_way"`, so a file written before the escape was a run's ending is
## still a complete snapshot (`RunState.snapshot_is_complete()` asks only about `"state"`) and
## still resumes, reading as `DaySpec.Section.NONE` by absence. Putting it in
## the snapshot instead would have made every save on disk unreadable for the sake of one int.
## `"completed_resistance_alley_tiles"` rides the same way, for the same reason, reading as "none
## recorded" by absence. `"fenced_park"`/`"fenced_park_act"` ride the same way too: a save from
## before the one calm area a run could fence existed loads with none chosen, which is exactly what
## a run that has not reached act III looks like anyway.
##
## **The mode and the checkpoint ride the same way.** `"hard_mode"` is absent from a save written
## before there were two modes, which reads as normal mode; `"checkpoint"` is absent from one
## written before there were checkpoints, which reads as checkpoint zero, day 1 of the same city —
## see `RunState.calendar.checkpoint`. **A checkpoint is the run in exactly the shape the file
## carries it**
## (`RunStateRegistry.run_data()`, every key below but the ones about the file itself), so a
## field a later build adds
## to the save is in every checkpoint the moment it is in `run_data()`, and
## `RunStateRegistry.restore_run_data()` is
## the one function that reads both back.
##
## **One save, no slots.** `_DEFAULT_PATH` is the only file this ever reads or writes on a real
## run; `set_path_override()` is the one seam a test uses to point at a scratch file instead, and
## `uses_save()` is the one gate every read and write goes through so a dev flag, a headless boot
## or the test runner never touches either.
##
## **A write is not a save until the storage behind `user://` has kept it.** *(cozy-pelican,
## 2026-10-02: "we should show it until it is fully confirmed saved. also, if saving is
## unavailable it should show up with a strike through".)* Off the web the file closing is that
## confirmation. On the web the file lives in Emscripten's in-memory filesystem until a flush copies
## it into the browser's IndexedDB, so `write()` answers `Result.PENDING` and the flush's own
## callback settles it later — see `_flush()`. Like a deletion, a write tells `EventBus` what it came
## to (`save_written`, and `save_write_settled` for a web flush), and `SaveIndicator` listens: the
## answer to a web save arrives seconds later, possibly after a scene reload has freed the `main`
## that saved, and a callable bound to `main` would then be dropped and leave the symbol shown for
## good.
##
## **Deleting the save is a change in the save state, and answers the same way.** *(cozy-pelican,
## 2026-10-02: "show deleting the save file with a save symbol as well. every change in the save
## state needs to show the symbol".)* `clear()` answers a `Result` like `write()` does and, on the
## web, is not kept until IndexedDB has dropped the file too, which only a flush's own answer says
## — see `_flush()`. It tells `EventBus` what it came to (`save_deleted`, and
## `save_deletion_settled` for a web flush), which is how the symbol shows a deletion made by
## `RunCalendar._end_run()`, which cannot reach `main`'s indicator.
##
## **Every write and every deletion is one operation with its own id**, from `_new_operation()`,
## carried on its announcement and on its later answer alike. *(golden-otter, 2026-10-02: "if a new
## save succeeds it doesn't really matter if an old save failed. only the latest save action
## matters".)* The id is what lets the symbol tell which change an answer belongs to: only the
## change begun last decides what it shows, and an answer to a change a symbol never began — one
## announced before a scene reload, to a symbol that did not survive it — settles nothing there.

## Bumped only when the shape `RunState.save_snapshot()` writes changes — never for an ordinary
## release. **This is the whole of what makes a save "the running build cannot read": a newer
## build with the same format keeps finding an older build's save, and only a format change drops
## one.** The build string below is recorded for a person to read, not for this comparison.
const FORMAT_VERSION := 1

const _DEFAULT_PATH := "user://save.json"

## What one save moment came to — a write (`EventBus.save_written` carries it to `SaveIndicator`) or
## a deletion (`EventBus.save_deleted` does).
enum Result {
	## Nothing was attempted: `uses_save()` refused the run, the run has already ended (a write), or
	## there is no file to delete (a deletion). The symbol draws nothing, since nothing was meant
	## to change.
	REFUSED,
	## Written or deleted, and handed to the browser, which has not yet said whether it kept the
	## change. The answer arrives later, on `EventBus.save_write_settled` or
	## `EventBus.save_deletion_settled` with the same operation id the announcement carried, and
	## through the `settled` callable `write()` or `clear()` was given, if any.
	PENDING,
	## Kept: off the web the file closed or was removed; on the web IndexedDB reported the flush
	## done.
	CONFIRMED,
	## Meant to be kept and not kept: the file could not be written or removed, the page's storage
	## was refused at boot, or the flush failed after its one retry or never answered.
	FAILED,
}

## How long a web flush may go unanswered before it counts as failed. A flush of a save this size
## normally answers within a fraction of a second, and its one retry (see `_FLUSH_JS`) reopens
## the database first, which takes longer on a phone; past this the browser is not going to answer,
## and the symbol, held fully shown the whole time, would otherwise stay up for the rest of the
## session. It is several times the symbol's own one-second minimum
## (`SaveIndicator.MIN_SHOWN_SECONDS`) and longer than its fade, so a slow but working flush is not
## mistaken for a failed one; and it is short enough that the struck picture a timeout raises,
## fully shown for ten seconds from the strike (`SaveIndicator.MIN_STRUCK_SECONDS`), starts to
## fade fifteen seconds after the save began. **Counted in frames, each clamped to
## `MAX_FLUSH_STEP_SECONDS`**, not on the wall clock: a hidden tab runs no frames, and the first one
## after it comes back reports the whole time it was away, which would time out a flush the browser
## was never given the chance to run — and strike through a save that IndexedDB then reports kept,
## since a flush answers only once. A page left in the background and brought back is the very case
## the retry exists for. A flush the browser really never answers still times out, after this many
## seconds of frames actually drawn.
const FLUSH_TIMEOUT_SECONDS := 5.0

## The most one frame adds to a flush's wait — a quarter second, several times a slow frame on a
## phone and far under `FLUSH_TIMEOUT_SECONDS`, so no single frame, however long since the last
## one, can by itself time a flush out.
const MAX_FLUSH_STEP_SECONDS := 0.25

## The page-side half of a web flush, defined once on `window` by `_flush()`. **Evaluated in
## `JavaScriptBridge.eval()`'s default, non-global context on purpose**: that is a direct `eval`
## inside the engine's own JavaScript module, which is the only scope where Emscripten's `FS` and
## `IDBFS` are visible at all — they are module-level variables, not properties of `window`. The
## function it defines closes over that scope, so calling it later from `window` still reaches
## them.
##
## `FS.syncfs(false, …)` pushes the in-memory filesystem into IndexedDB. A failure is retried once
## after closing and forgetting every connection Emscripten has cached in `IDBFS.dbs`, since it
## opens one per mount for the page's lifetime and never reopens one the browser has dropped —
## iOS Safari drops it from a page left in the background, and every later flush then fails until
## a reload. Only the second failure is reported as one. `answer(token, "")` is success;
## any other message is the failure's own text.
const _FLUSH_JS := """
window.nappySaveFlush = function (token, answer) {
	if (typeof FS === 'undefined' || typeof IDBFS === 'undefined') {
		answer(token, 'FS or IDBFS is not reachable');
		return;
	}
	function describe(err) {
		return String((err && (err.message || err.name)) || err || 'unknown error');
	}
	function attempt(retry) {
		function failed(err) {
			if (!retry) {
				answer(token, describe(err));
				return;
			}
			for (var name in IDBFS.dbs) {
				try { IDBFS.dbs[name].close(); } catch (e) {}
			}
			IDBFS.dbs = {};
			attempt(false);
		}
		try {
			FS.syncfs(false, function (err) {
				if (err) { failed(err); } else { answer(token, ''); }
			});
		} catch (e) {
			failed(e);
		}
	}
	attempt(true);
};
"""

## The two page-side objects a web flush needs, made once and **held for the page's lifetime**: a
## `JavaScriptObject` made by `create_callback()` stops answering the moment GDScript lets go of
## it, silently, so a callback held only by a local would never settle a flush.
static var _window: JavaScriptObject = null
static var _flush_answer: JavaScriptObject = null

## Every flush still waiting for its answer, by the operation id of the write or deletion it
## carries, which is also the token the page's answer names: `{"settled": Callable, "deleting":
## bool, "waited": float}`, the callable its `write()` or `clear()` was given, whether the flush
## carries a deletion, and the seconds of clamped frames it has waited so far. The first of the
## answer and the timeout to arrive removes the entry; the second finds nothing and does nothing.
static var _pending_flushes: Dictionary = {}
## The id `_new_operation()` handed out last. Only ever grows, for the life of the process, so a
## larger id is always a change begun later — which is how `SaveIndicator` knows the newest — and
## no id is reused across the scene reloads a held restart and the day-14 hand-over make.
static var _last_operation := 0
## When the last frame ticked the flushes' clocks, in `Time.get_ticks_usec()`. Set when the first
## flush begins waiting, so the step it first counts is the time since then.
static var _last_tick_usec := 0

## Set by a test to redirect every read and write at a scratch file instead of the player's own —
## see the **verify** skill's testing policy: an agent's run never lands in a saved game. `""`
## (the default) means "answer normally"; a test sets this before calling
## `_write_now()`/`_read_now()` directly (bypassing `uses_save()`'s gate, which a headless test
## runner would otherwise always fail) and clears it back to `""` when done.
static var _path_override := ""

static func set_path_override(path: String) -> void:
	_path_override = path

static func _path() -> String:
	return _path_override if _path_override != "" else _DEFAULT_PATH

## Set by a test to force `uses_save()`'s own answer, bypassing the headless display server this
## suite always boots against: a headless runner can drive `write()`/`try_resume()` (the gated
## names `main.gd` actually calls) no other way, since `uses_save()` refuses a headless run
## unconditionally. `null` (the
## default) means "answer normally"; a test sets this to `true` before exercising the gated path
## against a scratch file (`set_path_override()` first, never `_DEFAULT_PATH`) and clears it back
## to `null` when done, or the override leaks into every suite that runs after it.
static var _uses_save_override: Variant = null

## The run's configuration, handed in by `main` at boot (`configure()`), or `null` before then,
## which `uses_save()` answers with no save at all: nothing reads or writes the player's save
## before the run has said which flags it carries.
static var _config: RunConfig

static func configure(config: RunConfig) -> void:
	_config = config

## The one function every read and write of the player's save goes through. Every checkout and
## worktree of this repository shares one `user://`, so a dev flag, a headless run, the test
## runner and `tools/check.sh`'s boot must all fall through to an ordinary, unsaved run rather than
## any of them reading or writing what may be the player's own day 9.
##
## `DisplayServer.get_name() == "headless"` answers the null display server a headless run boots
## against (see the **verify** skill on `AutoScreenshot.can_photograph()`, the same check) —
## checked first and unconditionally, since a headless boot carries no dev flag at all and would
## otherwise read as an ordinary release run. On a debug build any dev flag at all keeps the run off
## the save (`config.active_args` is not empty), which reaches `--seed`, `--day`, `--walk` and the
## rest by construction rather than by naming each one again; `--no-save` and a flagless debug
## run's own empty argument list are the two ways a *windowed* debug session still answers "no" —
## the first because it asked to, the second because nothing here can tell a bare `tools/run.sh`
## apart from the player's own desktop build otherwise, and the flag exists exactly so an agent
## can ask for one anyway.
##
## **A web page keeps its ordinary save too, debug build or release, unless it actually used one
## of the release-safe bundle's own parameters** (M193, the live page's ?debug=1 reaches the debug
## flags: "a visitor who tries `?day=12` does not lose their own day 3").
## `config.web_debug_flag_used` answers that — `false` for the ordinary release page everyone else
## gets, and for `?debug=1` alone with none of the bundle's own parameters named, since neither one
## is a run built any differently from the one every other visitor gets.
static func uses_save() -> bool:
	if _uses_save_override != null:
		return bool(_uses_save_override)
	if DisplayServer.get_name() == "headless" or _config == null:
		return false
	if not _config.debug_build:
		return not _config.web_debug_flag_used
	return _debug_run_uses_save(_config.active_args, _config.no_save) \
			and not _config.web_debug_flag_used

## The one piece of `uses_save()`'s policy that does not depend on the live environment — pulled
## out so a test can drive every combination of flags directly rather than only through whichever
## shape `OS.is_debug_build()` happens to answer under the runner. Called only on a debug build, so
## a release build's own empty argument list never reaches this at all.
static func _debug_run_uses_save(args: PackedStringArray, no_save: bool) -> bool:
	return not no_save and args.is_empty()

## Whether a save file is currently on disk — read by `main.gd` for nothing gameplay-facing; a
## test's own way to check `clear()`/`write()` actually touched the filesystem.
static func has_save() -> bool:
	return FileAccess.file_exists(_path())

## Deletes the save, if there is one, and answers what the deletion came to — which is also what
## the save symbol shows, through `EventBus.save_deleted`. `RunCalendar._end_run()` (a run that is
## over) and `main._restart_run()` (the held restart) both call this; a run that is over or has been
## thrown away leaves nothing to resume.
##
## `Result.REFUSED` for a dev run or a headless run (`uses_save()`) and when there is no file to
## delete: a restart after the run already ended and deleted the save changes nothing, so it draws
## nothing. *(cozy-pelican, 2026-10-02: "A restart with no save left to delete ... changes nothing,
## so it shows nothing.")* `Result.PENDING` on the web while the browser has not yet said whether
## IndexedDB dropped the file, in which case `settled` is called later with `Result.CONFIRMED` or
## `Result.FAILED`, exactly once, and only if its object still exists then — `EventBus`
## `save_deletion_settled` says the same to anything listening, which is how a symbol outlives the
## `main` that raised it. `settled` is never called for any other answer.
static func clear(settled := Callable()) -> Result:
	if not uses_save() or not has_save():
		return Result.REFUSED
	var operation := _new_operation()
	var on_web := OS.has_feature("web")
	var persistent := OS.is_userfs_persistent()
	var removed := _clear_now()
	var result := _moment_result(removed, on_web, persistent)
	if result == Result.FAILED:
		Telemetry.note("save", "the deletion was not kept (%s)"
				% ("the file could not be removed" if not removed else "the browser refused storage"))
	# Before the flush starts, so a symbol has begun by the time any answer reaches it.
	EventBus.save_deleted.emit(operation, int(result))
	if result == Result.PENDING:
		_flush(operation, settled, true)
	return result

## The ungated mechanics `clear()` calls through, and the seam `tests/test_save.gd` calls directly
## (pointed at a scratch path with `set_path_override()`) to put the scratch file away, since
## `clear()` itself refuses a headless run. Returns whether the file is gone; a file that was not
## there to begin with is already gone, so that is `true` and writes nothing to the run log.
static func _clear_now() -> bool:
	if not has_save():
		return true
	var removed := DirAccess.remove_absolute(ProjectSettings.globalize_path(_path())) == OK
	if not removed:
		push_warning("GameSave: could not remove %s" % _path())
		return false
	Telemetry.note("save", "deleted the save")
	return true

## Writes `run` to disk and answers what the save moment came to, which is also
## what the save symbol shows, through `EventBus.save_written` — `main._save_now()` is just the one
## place the game calls this from, and relays nothing. `Result.REFUSED` for a dev run, a headless
## run and a run that has already ended, which draw nothing for a write that was never meant to
## happen and announce nothing; `Result.PENDING` on the web while the browser has not yet answered,
## in which case `EventBus.save_write_settled` carries the answer later, and `settled`, if given,
## is called with `Result.CONFIRMED` or `Result.FAILED`, exactly once, and only if its object still
## exists then. `settled` is never called for any other answer. **The symbol is answered by the bus,
## not by `settled`**, because a scene reload may free the caller before the browser answers.
static func write(run: RunState, day_under_way: bool, settled := Callable()) -> Result:
	if not uses_save() or _run_has_ended(run):
		return Result.REFUSED
	var operation := _new_operation()
	var on_web := OS.has_feature("web")
	# Read at every save moment rather than once, so the answer is the engine's own at the moment
	# the save is meant to be kept.
	var persistent := OS.is_userfs_persistent()
	var wrote := _write_now(run, day_under_way)
	var result := _moment_result(wrote, on_web, persistent)
	if result == Result.FAILED:
		Telemetry.note("save", "the save was not kept (%s)"
				% ("the file could not be written" if not wrote else "the browser refused storage"))
	# Before the flush starts, so a symbol has begun by the time any answer reaches it.
	EventBus.save_written.emit(operation, int(result))
	if result == Result.PENDING:
		_flush(operation, settled)
	return result

## What a save moment comes to before any browser has answered — the pure half of `write()` and of
## `clear()`, so a test can reach the web's branches from a desktop runner. `done` is
## `_write_now()`'s or `_clear_now()`'s own answer, `persistent` is `OS.is_userfs_persistent()`:
## false on a web page whose browser refused IndexedDB at boot, where Godot carries on from memory
## alone and a flush would report success for a copy no reload will ever find — so a page in that
## state is a failed change without ever flushing. For a deletion that is the right answer too: a
## stored copy this page could not reach is one a later visit can bring back.
static func _moment_result(done: bool, on_web: bool, persistent: bool) -> Result:
	if not done:
		return Result.FAILED
	if not on_web:
		return Result.CONFIRMED
	if not persistent:
		return Result.FAILED
	return Result.PENDING

## A fresh id for one write or deletion — see the class doc. Called only for a change that is
## announced, never for a refused one, which announces nothing.
static func _new_operation() -> int:
	_last_operation += 1
	return _last_operation

## Whether `run` has an ending, after which nothing is written — see `_write_now()`.
static func _run_has_ended(run: RunState) -> bool:
	return run.header.ending != GameEnums.Ending.NONE

## Starts a web flush for `operation` and settles it through `settled` — see `_FLUSH_JS` for the
## page's half and `FLUSH_TIMEOUT_SECONDS` for the backstop. The operation id is the flush's token,
## so the answer and the timeout settle the flush they belong to, whichever arrives first.
## `deleting` says the flush carries a removal, which it names as a deletion in the run log. Either
## kind is settled on `EventBus` too (`save_deletion_settled` or `save_write_settled`, with the
## operation id), which is what reaches a symbol when the `settled` callable's object is gone.
##
## Godot's web platform also flushes a persistent path on its own, after a file open for writing is
## closed and after a file is removed alike (the engine's `OS_Web` marks the store for a sync from
## both notifications, `file_access_close_callback` and `dir_access_remove_callback`), but only on
## the *next* main-loop iteration, and it reports the outcome to nobody. So a deletion would reach
## IndexedDB without this flush too; this one starts at once and **is the one whose answer the
## symbol waits for**, for a write and a deletion alike — without it there would be nothing to say
## whether the browser kept the change. `FS.syncfs(false, …)` reconciles the stored copy with the
## in-memory filesystem in both directions, dropping what is gone from it.
## **Neither is a guarantee against a tab killed with no JavaScript tick left to run at all** — that
## gap is why every write carries the whole run rather than a change to it: the next write lands
## during the next ordinary session, long before the following quit, so a save that never reached
## IndexedDB on one close is caught up by the time the game is closed again.
static func _flush(operation: int, settled: Callable, deleting := false) -> void:
	var token := _register_flush(operation, settled, deleting)
	_start_the_clock()
	if _flush_answer == null:
		JavaScriptBridge.eval(_FLUSH_JS)
		_window = JavaScriptBridge.get_interface("window")
		_flush_answer = JavaScriptBridge.create_callback(_on_flush_answered)
	if _window == null or _flush_answer == null:
		# Deferred, so the answer never arrives before the caller has been handed `PENDING` and
		# had the chance to begin whatever waits for it — an answer to nothing begun is dropped.
		_settle.call_deferred(token, Result.FAILED, "the page's JavaScript is not reachable")
		return
	_window.call("nappySaveFlush", token, _flush_answer)

## Starts counting frames for the flushes' timeout, if no flush is already being counted. The
## `SceneTree`'s `process_frame` fires every frame whether or not the tree is paused, so a flush
## started as the summary pauses the tree still times out, and it needs no node of its own to
## survive the held restart's scene reload.
static func _start_the_clock() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.process_frame.is_connected(_tick):
		return
	_last_tick_usec = Time.get_ticks_usec()
	tree.process_frame.connect(_tick)

static func _tick() -> void:
	var now := Time.get_ticks_usec()
	var elapsed := float(now - _last_tick_usec) / 1000000.0
	_last_tick_usec = now
	_advance(_clamped_step(elapsed))

## What one frame adds to a flush's wait, however long it was since the last frame.
static func _clamped_step(elapsed_seconds: float) -> float:
	return clampf(elapsed_seconds, 0.0, MAX_FLUSH_STEP_SECONDS)

## Adds `step` seconds to every flush's wait and fails the ones past `FLUSH_TIMEOUT_SECONDS`, then
## stops the clock once nothing waits. The seam `tests/test_save.gd` drives without a browser.
static func _advance(step: float) -> void:
	for token: int in _pending_flushes.keys():
		var entry: Dictionary = _pending_flushes[token]
		entry["waited"] = float(entry["waited"]) + step
		if float(entry["waited"]) >= FLUSH_TIMEOUT_SECONDS:
			_settle(token, Result.FAILED, "no answer within %.0fs" % FLUSH_TIMEOUT_SECONDS)
	if _pending_flushes.is_empty():
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.process_frame.is_connected(_tick):
			tree.process_frame.disconnect(_tick)

## The page's answer to one flush: `[token, message]`, `message` empty on success.
static func _on_flush_answered(args: Array) -> void:
	if args.size() < 2:
		return
	var message := str(args[1])
	if message.is_empty():
		_settle(int(args[0]), Result.CONFIRMED, "")
	else:
		_settle(int(args[0]), Result.FAILED, message)

## Puts `operation`'s flush in the table of flushes waiting for an answer, and answers its token,
## which is the operation id itself.
static func _register_flush(operation: int, settled: Callable, deleting := false) -> int:
	_pending_flushes[operation] = {"settled": settled, "deleting": deleting, "waited": 0.0}
	return operation

## Settles one pending flush, once: whichever of the page's answer and the timeout arrives second
## finds the token gone and does nothing, so a flush that answers after timing out stays failed
## rather than flipping the symbol it already struck through. A `settled` whose object is gone — a
## held restart reloads `main` while a flush is still out — is skipped. **The answer always goes out
## on `EventBus` first** (`save_deletion_settled` for a deletion, `save_write_settled` for a write,
## each with the operation id), which is what reaches the symbol that outlived the `main` a reload
## freed.
static func _settle(token: int, result: Result, reason: String) -> void:
	if not _pending_flushes.has(token):
		return
	var entry: Dictionary = _pending_flushes[token]
	var settled: Callable = entry["settled"]
	var deleting: bool = entry["deleting"]
	_pending_flushes.erase(token)
	var kept := result == Result.CONFIRMED
	if deleting:
		if kept:
			Telemetry.note("save", "the browser dropped the deleted save")
		else:
			Telemetry.note("save", "the browser did not drop the deleted save (%s)" % reason)
		EventBus.save_deletion_settled.emit(token, kept)
	else:
		if kept:
			Telemetry.note("save", "the browser kept the save")
		else:
			Telemetry.note("save", "the browser did not keep the save (%s)" % reason)
		EventBus.save_write_settled.emit(token, kept)
	if settled.is_valid():
		settled.call(result)

## The ungated mechanics `write()` calls through, and the seam `tests/test_save.gd` calls directly
## so a headless test (where `uses_save()` always answers `false`, see its own doc) can still
## exercise the actual file format — pointed at a scratch path with `set_path_override()` first,
## never at `_DEFAULT_PATH`.
##
## **Refuses once `run.header.ending` is set**, checked here rather than only in `write()` so a test
## can drive it without also having to make `uses_save()` answer `true` under the headless runner.
## A finished run already had its save cleared in `RunCalendar._end_run()`; this is the second line
## of the same reasoning `CLAUDE.md`'s "check before accepting, never repair afterwards" asks for
## elsewhere in this project — a stray write between the ending firing and the player being shown
## it must not resurrect a file that answering the ending question already deleted.
##
## Returns whether the file was written and closed; on the web that is not yet a kept save — see
## `write()`.
static func _write_now(run: RunState, day_under_way: bool) -> bool:
	if _run_has_ended(run):
		return false
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if not file:
		push_warning("GameSave: could not open %s for writing" % _path())
		return false
	var stored := file.store_string(JSON.stringify(file_data(run, day_under_way)))
	file.close()
	if not stored:
		push_warning("GameSave: could not write %s" % _path())
		return false
	var state_word := "day under way" if day_under_way else "between days"
	Telemetry.note("save", "wrote the save (%s)" % state_word)
	return true

## Everything the save file holds of `run`, as the plain JSON-safe dictionary `_write_now()`
## stringifies: `RunStateRegistry.run_data()`, plus the facts about the file and the run's mode
## rather than about where the run
## stands — the format and the build that wrote it, whether a day was under way, the mode, and the
## checkpoint. `FILE_KEYS` names those, and `tests/test_run_checkpoints.gd` reads every other key
## off this function to check a checkpoint gives each one back.
static func file_data(run: RunState, day_under_way: bool) -> Dictionary:
	var data := run.run_parts.run_data()
	data["format_version"] = FORMAT_VERSION
	data["build"] = BuildInfo.build_text()
	data["day_under_way"] = day_under_way
	data["hard_mode"] = run.calendar.hard_mode
	data["checkpoint"] = run.calendar.checkpoint.duplicate(true)
	return data

## The keys of `file_data()` that are not the run's own state, and so are neither part of a
## checkpoint nor given back by one: the file's format and build, whether a day was under way when
## it was written, the mode (fixed for the run) and the checkpoint itself.
const FILE_KEYS: Array[String] = [
	"format_version", "build", "day_under_way", "hard_mode", "checkpoint",
]

## Connects the deletion of the save to the end of a run: **a finished run leaves no save**, since a
## save that named an ended run would have to be specially refused on load rather than simply not
## existing. `main` calls this once a boot, before anything can end the run, and a suite that ends a
## run calls it too; connecting twice changes nothing. (`main._restart_run()` also clears the save,
## for the held restart that abandons a run before it ends on its own.)
static func clear_when_a_run_ends() -> void:
	if not EventBus.run_ended.is_connected(_on_run_ended):
		EventBus.run_ended.connect(_on_run_ended)

static func _on_run_ended(_ending: GameEnums.Ending) -> void:
	clear()

## Tries to resume a run into `run`. Returns `{}` when there is nothing to resume — no file, a file
## this build cannot read, or a dev/headless run `uses_save()` already refused — and
## `{"day_under_way": bool}` once `run` has been overwritten with the save's own fields. The caller
## (`main._ready()`) still owns what a `true` costs: the same lost-day path an ordinary loss takes,
## through `RunState.calendar.finish_day()`, so this function only ever reads and restores,
## never spends a
## nerve.
static func try_resume(run: RunState) -> Dictionary:
	if not uses_save():
		return {}
	return _read_now(run)

## The ungated mechanics `try_resume()` calls through — the seam `tests/test_save.gd` uses to
## exercise a garbled or version-mismatched file directly, since `uses_save()` always answers
## `false` under the headless test runner (see its own doc).
##
## Every way a file fails to become a resumable run answers the same "drop it for a fresh title
## screen" the design asks for, rather than a half-loaded run: no file at that path, text that is
## not valid JSON, JSON that is not an object, a `format_version` this build does not carry, or a
## `"state"` missing a field this build's own `RunState.save_snapshot()` writes — see
## `RunState.snapshot_is_complete()`. Only past every one of those does `run` actually change.
static func _read_now(run: RunState) -> Dictionary:
	var path := _path()
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	# A garbled save is expected input here, not a defect — the whole point of this function is to
	# drop one for a fresh title screen. `JSON.parse_string()` reports the same failure by printing
	# an engine `ERROR: Parse JSON failed…` on its way to returning null, which is right for code
	# that never expects bad JSON and wrong here; the instance form reports through its own return
	# value instead and prints nothing, the same shape `GroundLayers._load_manifest()` already uses
	# for a manifest file that also may not parse.
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	if int(data.get("format_version", -1)) != FORMAT_VERSION:
		return {}
	if typeof(data.get("state", null)) != TYPE_DICTIONARY:
		return {}
	var state: Dictionary = data["state"]
	if not run.snapshot_is_complete(state):
		return {}
	return _apply(run, data)

## Everything a readable save puts back on `run`, from `_read_now()`'s file and from
## `load_in_memory()`'s copy alike, and what it says about the day: `{"day_under_way": bool}`.
static func _apply(run: RunState, data: Dictionary) -> Dictionary:
	run.run_parts.restore_run_data(data)
	# The mode and the checkpoint, the same way again: a save from before there were two modes is a
	# normal run, and one from before there were checkpoints goes back to day 1 of its own city.
	run.calendar.hard_mode = bool(data.get("hard_mode", false))
	var kept: Variant = data.get("checkpoint", {})
	run.calendar.checkpoint = _usable_checkpoint(run, kept)
	return {"day_under_way": bool(data.get("day_under_way", false))}

## `run` written out the way a save is and read straight back into it the way a save is —
## through JSON and `_apply()` — without touching the disk. **A normal run sent back to its
## checkpoint boots on this** (`main._carry_the_run_into_the_next_boot()`): the scene is reloaded,
## so no node remembers anything after the checkpoint, and the run it boots on is exactly what a
## load would give it, on every run, a dev-flagged or headless one with no save at all included.
## Never reads the file, so a write the storage did not keep cannot hand the reload an older run.
static func load_in_memory(run: RunState) -> void:
	var parser := JSON.new()
	if parser.parse(JSON.stringify(file_data(run, false))) != OK:
		push_error("GameSave: the run could not be written out as JSON")
		return
	_apply(run, parser.data)

## A checkpoint read off disk, kept only when it could be given back: a dictionary whose `"state"`
## carries every field this build's snapshot does. Anything else — absent, garbled, or from a
## snapshot shape this build no longer reads — falls back to checkpoint zero (`{}`) rather than a
## half-applied run, the same answer `_read_now()` gives a whole save it cannot read.
static func _usable_checkpoint(run: RunState, raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var kept: Dictionary = raw
	var state: Variant = kept.get("state", null)
	if not state is Dictionary or not run.snapshot_is_complete(state):
		return {}
	return kept
