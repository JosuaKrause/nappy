class_name GameSave
extends RefCounted
## Persists a run to disk so the game can be closed and picked up again — see docs/MECHANICS.md,
## "Saving and resuming". Not an autoload, the same shape `DevFlags` already uses: every member
## below is `static`, so the class is a namespace for file I/O and format policy rather than an
## object with a lifetime of its own. Lives beside `GameState`, the one thing it reads and writes,
## rather than under `src/ui/` with the symbol that announces a write — a save module is data, the
## symbol is presentation, and the two only meet through `EventBus`.
##
## **The save is the run, never the moment inside a day.** `GameState.save_snapshot()` says what a
## run holds; this file only adds the facts a run does not know about itself — whether a day was
## under way when the file was written, which section of the escape it is in, and which build
## wrote it — and turns the result into JSON. *Asked for "that exact state", the crowd included, and overturned by the player to a
## restart at dawn that costs a nerve* — see docs/MECHANICS.md, "Saving and resuming", for what
## that costs and why.
##
## **The escape's section rides beside those, not inside the snapshot.** `"escape_section"` is a
## top-level key like `"day_under_way"`, so a file written before the escape was a run's ending is
## still a complete snapshot (`GameState.snapshot_is_complete()` asks only about `"state"`) and
## still resumes, reading as `FinaleController.Section.NONE` by absence. Putting it in
## `_SAVE_FIELDS` instead would have made every save on disk unreadable for the sake of one int.
## `"completed_resistance_alley_tiles"` rides the same way, for the same reason, reading as "none
## recorded" by absence. `"fenced_park"`/`"fenced_park_act"` ride the same way too: a save from
## before the one calm area a run could fence existed loads with none chosen, which is exactly what
## a run that has not reached act III looks like anyway.
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
## web, is not kept until IndexedDB has dropped the file too — Godot's own flush runs only after a
## file open for writing is closed, which a removal never is, so without `clear()`'s own flush a
## reload could bring back a run that already ended. It tells `EventBus` what it came to
## (`save_deleted`, and `save_deletion_settled` for a web flush), which is how the symbol shows a
## deletion made by `GameState._end_run()`, an autoload that cannot reach `main`'s indicator.

## Bumped only when the shape `GameState.save_snapshot()` writes changes — never for an ordinary
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
	## `EventBus.save_deletion_settled`, and through the `settled` callable `write()` or `clear()` was
	## given, if any.
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

## Every flush still waiting for its answer, by token: `{"settled": Callable, "deleting": bool,
## "waited": float}`, the callable its `write()` or `clear()` was given, whether the flush carries a
## deletion, and the seconds of clamped frames it has waited so far. The
## first of the answer and the timeout to arrive removes the entry; the second finds nothing and
## does nothing.
static var _pending_flushes: Dictionary = {}
static var _next_flush_token := 0
## When the last frame ticked the flushes' clocks, in `Time.get_ticks_usec()`. Set when the first
## flush begins waiting, so the step it first counts is the time since then.
static var _last_tick_usec := 0

## Set by a test to redirect every read and write at a scratch file instead of the player's own —
## see the **verify** skill's testing policy: an agent's run never lands in a saved game. `""`
## (the default) means "answer normally"; a test sets this before calling
## `_write_now()`/`_read_now()` directly (bypassing `uses_save()`'s gate, which a headless test
## runner would otherwise always fail) and clears it back to `""` when done, the same shape
## `DevFlags._invincible_override` already uses for the same reason.
static var _path_override := ""

static func set_path_override(path: String) -> void:
	_path_override = path

static func _path() -> String:
	return _path_override if _path_override != "" else _DEFAULT_PATH

## Set by a test to force `uses_save()`'s own answer, bypassing the headless display server this
## suite always boots against — the same seam `DevFlags._invincible_override` is for the same
## reason: a headless runner can drive `write()`/`try_resume()` (the gated names `main.gd` actually
## calls) no other way, since `uses_save()` refuses a headless run unconditionally. `null` (the
## default) means "answer normally"; a test sets this to `true` before exercising the gated path
## against a scratch file (`set_path_override()` first, never `_DEFAULT_PATH`) and clears it back
## to `null` when done, or the override leaks into every suite that runs after it.
static var _uses_save_override: Variant = null

## The one function every read and write of the player's save goes through. Every checkout and
## worktree of this repository shares one `user://`, so a dev flag, a headless run, the test
## runner and `tools/check.sh`'s boot must all fall through to an ordinary, unsaved run rather than
## any of them reading or writing what may be the player's own day 9.
##
## `DisplayServer.get_name() == "headless"` answers the null display server a headless run boots
## against (see the **verify** skill on `AutoScreenshot.can_photograph()`, the same check) —
## checked first and unconditionally, since a headless boot carries no dev flag at all and would
## otherwise read as an ordinary release run. `DevFlags.enabled()` is the same gate every other dev
## flag already answers to (`OS.is_debug_build()`), so this reaches `--seed`, `--day`, `--walk` and
## the rest by construction rather than by naming each one again; `DevFlags.no_save()` and a
## flagless debug run's own empty argument list are the two ways a *windowed* debug session still
## answers "no" — the first because it asked to, the second because nothing here can tell a bare
## `tools/run.sh` apart from the player's own desktop build otherwise, and the flag exists exactly
## so an agent can ask for one anyway.
##
## **A web page keeps its ordinary save too, debug build or release, unless it actually used one
## of `DevFlags.live_debug_requested()`'s own parameters.** *(docs/DECISIONS.md, M193, "the live page's ?debug=1
## reaches the debug flags": "a visitor who tries `?day=12` does not lose their own day 3".)*
## `DevFlags.web_debug_flag_used()` answers that — `false` for the ordinary release page everyone
## else gets, and for `?debug=1` alone with none of the bundle's own parameters named, since
## neither one is a run built any differently from the one every other visitor gets.
static func uses_save() -> bool:
	if _uses_save_override != null:
		return bool(_uses_save_override)
	if DisplayServer.get_name() == "headless":
		return false
	if not DevFlags.enabled():
		return not DevFlags.web_debug_flag_used()
	return _debug_run_uses_save(DevFlags.active_args(), DevFlags.no_save()) \
			and not DevFlags.web_debug_flag_used()

## The one piece of `uses_save()`'s policy that does not depend on the live environment — pulled
## out so a test can drive every combination of flags directly rather than only through whichever
## shape `OS.is_debug_build()` happens to answer under the runner. Called only once `enabled()`
## already holds, so a release build's own empty argument list never reaches this at all.
static func _debug_run_uses_save(args: PackedStringArray, no_save: bool) -> bool:
	return not no_save and args.is_empty()

## Whether a save file is currently on disk — read by `main.gd` for nothing gameplay-facing; a
## test's own way to check `clear()`/`write()` actually touched the filesystem.
static func has_save() -> bool:
	return FileAccess.file_exists(_path())

## Deletes the save, if there is one, and answers what the deletion came to — which is also what
## the save symbol shows, through `EventBus.save_deleted`. `GameState._end_run()` (a run that is
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
	var on_web := OS.has_feature("web")
	var persistent := OS.is_userfs_persistent()
	var removed := _clear_now()
	var result := _moment_result(removed, on_web, persistent)
	if result == Result.FAILED:
		Telemetry.note("save", "the deletion was not kept (%s)"
				% ("the file could not be removed" if not removed else "the browser refused storage"))
	# Before the flush starts, so a symbol has begun by the time any answer reaches it.
	EventBus.save_deleted.emit(int(result))
	if result == Result.PENDING:
		_flush(settled, true)
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

## Writes the current `GameState` to disk and answers what the save moment came to, which is also
## what the save symbol shows, through `EventBus.save_written` — `main._save_now()` is just the one
## place the game calls this from, and relays nothing. `Result.REFUSED` for a dev run, a headless
## run and a run that has already ended, which draw nothing for a write that was never meant to
## happen and announce nothing; `Result.PENDING` on the web while the browser has not yet answered,
## in which case `EventBus.save_write_settled` carries the answer later, and `settled`, if given,
## is called with `Result.CONFIRMED` or `Result.FAILED`, exactly once, and only if its object still
## exists then. `settled` is never called for any other answer. **The symbol is answered by the bus,
## not by `settled`**, because a scene reload may free the caller before the browser answers.
static func write(day_under_way: bool, settled := Callable()) -> Result:
	if not uses_save() or _run_has_ended():
		return Result.REFUSED
	var on_web := OS.has_feature("web")
	# Read at every save moment rather than once, so the answer is the engine's own at the moment
	# the save is meant to be kept.
	var persistent := OS.is_userfs_persistent()
	var wrote := _write_now(day_under_way)
	var result := _moment_result(wrote, on_web, persistent)
	if result == Result.FAILED:
		Telemetry.note("save", "the save was not kept (%s)"
				% ("the file could not be written" if not wrote else "the browser refused storage"))
	# Before the flush starts, so a symbol has begun by the time any answer reaches it.
	EventBus.save_written.emit(int(result))
	if result == Result.PENDING:
		_flush(settled)
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

## Whether the run has an ending, after which nothing is written — see `_write_now()`.
static func _run_has_ended() -> bool:
	return GameState.ending != GameEnums.Ending.NONE

## Starts a web flush and settles it through `settled` — see `_FLUSH_JS` for the page's half and
## `FLUSH_TIMEOUT_SECONDS` for the backstop. Each flush has its own token so the answer and the
## timeout settle the flush they belong to, whichever arrives first. `deleting` says the flush
## carries a removal, which it names as a deletion in the run log. Either kind is settled on
## `EventBus` too (`save_deletion_settled` or `save_write_settled`), which is what reaches a symbol
## when the `settled` callable's object is gone.
##
## Godot's web platform also flushes a persistent path on its own once a file open for writing is
## closed, but only on the *next* main-loop iteration, and it reports a failure to nobody; this
## one starts at once and is the one whose answer the symbol waits for. **A removal closes no
## file**, so for a deletion this is the only flush there is: `FS.syncfs(false, …)` reconciles the
## stored copy with the in-memory filesystem in both directions, dropping what is gone from it.
## **Neither is a guarantee against a tab killed with no JavaScript tick left to run at all** — that
## gap is why every write carries the whole run rather than a change to it: the next write lands
## during the next ordinary session, long before the following quit, so a save that never reached
## IndexedDB on one close is caught up by the time the game is closed again.
static func _flush(settled: Callable, deleting := false) -> void:
	var token := _register_flush(settled, deleting)
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

static func _register_flush(settled: Callable, deleting := false) -> int:
	_next_flush_token += 1
	_pending_flushes[_next_flush_token] = {"settled": settled, "deleting": deleting, "waited": 0.0}
	return _next_flush_token

## Settles one pending flush, once: whichever of the page's answer and the timeout arrives second
## finds the token gone and does nothing, so a flush that answers after timing out stays failed
## rather than flipping the symbol it already struck through. A `settled` whose object is gone — a
## held restart reloads `main` while a flush is still out — is skipped. **The answer always goes out
## on `EventBus` first** (`save_deletion_settled` for a deletion, `save_write_settled` for a write),
## which is what reaches the symbol that outlived the `main` a reload freed.
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
		EventBus.save_deletion_settled.emit(kept)
	else:
		if kept:
			Telemetry.note("save", "the browser kept the save")
		else:
			Telemetry.note("save", "the browser did not keep the save (%s)" % reason)
		EventBus.save_write_settled.emit(kept)
	if settled.is_valid():
		settled.call(result)

## The ungated mechanics `write()` calls through, and the seam `tests/test_save.gd` calls directly
## so a headless test (where `uses_save()` always answers `false`, see its own doc) can still
## exercise the actual file format — pointed at a scratch path with `set_path_override()` first,
## never at `_DEFAULT_PATH`.
##
## **Refuses once `GameState.ending` is set**, checked here rather than only in `write()` so a test
## can drive it without also having to make `uses_save()` answer `true` under the headless runner.
## A finished run already had its save cleared in `GameState._end_run()`; this is the second line
## of the same reasoning `CLAUDE.md`'s "check before accepting, never repair afterwards" asks for
## elsewhere in this project — a stray write between the ending firing and the player being shown
## it must not resurrect a file that answering the ending question already deleted.
##
## Returns whether the file was written and closed; on the web that is not yet a kept save — see
## `write()`.
static func _write_now(day_under_way: bool) -> bool:
	if _run_has_ended():
		return false
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if not file:
		push_warning("GameSave: could not open %s for writing" % _path())
		return false
	var alley_tiles: Array = []
	for tile: Vector2i in GameState.completed_resistance_alley_tiles:
		alley_tiles.append({"x": tile.x, "y": tile.y})
	var stored := file.store_string(JSON.stringify({
		"format_version": FORMAT_VERSION,
		"build": TitleScreen.build_text(),
		"day_under_way": day_under_way,
		"escape_section": GameState.escape_section,
		"completed_resistance_alley_tiles": alley_tiles,
		"fenced_park": {"x": GameState.fenced_park.x, "y": GameState.fenced_park.y},
		"fenced_park_act": GameState.fenced_park_act,
		"posters": GameState.posters.to_data(),
		"state": GameState.save_snapshot(),
	}))
	file.close()
	if not stored:
		push_warning("GameSave: could not write %s" % _path())
		return false
	var state_word := "day under way" if day_under_way else "between days"
	Telemetry.note("save", "wrote the save (%s)" % state_word)
	return true

## Tries to resume a run. Returns `{}` when there is nothing to resume — no file, a file this build
## cannot read, or a dev/headless run `uses_save()` already refused — and `{"day_under_way": bool}`
## once `GameState` has been overwritten with the save's own fields. The caller (`main._ready()`)
## still owns what a `true` costs: the same lost-day path an ordinary loss takes, through
## `GameState.finish_day()`, so this function only ever reads and restores, never spends a nerve.
static func try_resume() -> Dictionary:
	if not uses_save():
		return {}
	return _read_now()

## The ungated mechanics `try_resume()` calls through — the seam `tests/test_save.gd` uses to
## exercise a garbled or version-mismatched file directly, since `uses_save()` always answers
## `false` under the headless test runner (see its own doc).
##
## Every way a file fails to become a resumable run answers the same "drop it for a fresh title
## screen" the design asks for, rather than a half-loaded `GameState`: no file at that path,
## text that is not valid JSON, JSON that is not an object, a `format_version` this build does not
## carry, or a `"state"` missing a field this build's own `GameState.save_snapshot()` writes — see
## `GameState.snapshot_is_complete()`. Only past every one of those does `GameState` actually
## change.
static func _read_now() -> Dictionary:
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
	if not GameState.snapshot_is_complete(state):
		return {}
	GameState.restore_snapshot(state)
	# After the snapshot, never before: `restore_snapshot()` writes every field a run holds and
	# this one is not among them, so a save from a build that never wrote the key leaves the run in
	# the ordinary fourteen days rather than half-way into an escape it never reached.
	GameState.escape_section = int(data.get("escape_section", 0))
	# Same reasoning, same shape, for the alley tiles the resistance has already used this run: a
	# save from a build that never wrote the key leaves the list empty rather than half-restored.
	GameState.completed_resistance_alley_tiles.clear()
	for raw: Dictionary in data.get("completed_resistance_alley_tiles", []):
		GameState.completed_resistance_alley_tiles.append(Vector2i(int(raw["x"]), int(raw["y"])))
	# And the one park barriers may already stand around, the same way again: a save from before
	# `fenced_park` existed loads with none chosen, so act III can still choose one fresh — the same
	# state a run that has not reached act III yet is already in.
	var fenced_park: Variant = data.get("fenced_park", null)
	if fenced_park is Dictionary:
		GameState.fenced_park = Vector2i(int(fenced_park.get("x", -1)), int(fenced_park.get("y", -1)))
	else:
		GameState.fenced_park = Vector2i(-1, -1)
	GameState.fenced_park_act = int(data.get("fenced_park_act", 0))
	# And the walls, the same way again: a save from before there were posters loads with none up,
	# and the next dawn pastes the city's from `PosterWalls.FIRST_DAY` onward.
	GameState.posters.reset()
	var posters: Variant = data.get("posters", {})
	if posters is Dictionary:
		GameState.posters.restore(posters)
	return {"day_under_way": bool(data.get("day_under_way", false))}
