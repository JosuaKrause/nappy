class_name GameSave
extends RefCounted
## Persists a run to disk so the game can be closed and picked up again — see docs/MECHANICS.md,
## "Saving and resuming". Not an autoload, the same shape `DevFlags` already uses: every member
## below is `static`, so the class is a namespace for file I/O and format policy rather than an
## object with a lifetime of its own. Lives beside `GameState`, the one thing it reads and writes,
## rather than under `src/ui/` with the symbol that announces a write — a save module is data, the
## symbol is presentation, and the two only meet through `main._save_now()`.
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
## recorded" by absence.
##
## **One save, no slots.** `_DEFAULT_PATH` is the only file this ever reads or writes on a real
## run; `set_path_override()` is the one seam a test uses to point at a scratch file instead, and
## `uses_save()` is the one gate every read and write goes through so a dev flag, a headless boot
## or the test runner never touches either.

## Bumped only when the shape `GameState.save_snapshot()` writes changes — never for an ordinary
## release. **This is the whole of what makes a save "the running build cannot read": a newer
## build with the same format keeps finding an older build's save, and only a format change drops
## one.** The build string below is recorded for a person to read, not for this comparison.
const FORMAT_VERSION := 1

const _DEFAULT_PATH := "user://save.json"

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

## Deletes the save, if there is one. The held restart (`main._restart_run()`) and a finished run
## (`GameState._end_run()`) both call this — a run that is over or has been thrown away leaves
## nothing to resume, and deleting a file that is not there is a silent no-op rather than an error.
static func clear() -> void:
	if FileAccess.file_exists(_path()):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path()))

## Writes the current `GameState` to disk. Returns whether it actually did, which is also whether
## the save symbol should flash — see `main._save_now()` — so a dev run, a headless run and a run
## that has already ended draw nothing for a write that never happened.
static func write(day_under_way: bool) -> bool:
	if not uses_save():
		return false
	return _write_now(day_under_way)

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
static func _write_now(day_under_way: bool) -> bool:
	if GameState.ending != GameEnums.Ending.NONE:
		return false
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if not file:
		push_warning("GameSave: could not open %s for writing" % _path())
		return false
	var alley_tiles: Array = []
	for tile: Vector2i in GameState.completed_resistance_alley_tiles:
		alley_tiles.append({"x": tile.x, "y": tile.y})
	file.store_string(JSON.stringify({
		"format_version": FORMAT_VERSION,
		"build": TitleScreen.build_text(),
		"day_under_way": day_under_way,
		"escape_section": GameState.escape_section,
		"completed_resistance_alley_tiles": alley_tiles,
		"posters": GameState.posters.to_data(),
		"state": GameState.save_snapshot(),
	}))
	file.close()
	# Godot's web platform syncs a persistent path's file to the browser's IndexedDB on its own,
	# once the file that was open for writing is closed — but only on the *next* main-loop
	# iteration, which a tab that is already tearing down after `NOTIFICATION_WM_CLOSE_REQUEST` may
	# never reach. `FS.syncfs(false, ...)` is Emscripten's own flush, `false` meaning "push the
	# in-memory filesystem to IndexedDB" (`true` is the opposite direction, used to populate it at
	# startup); calling it here starts that write immediately rather than waiting for a loop that
	# may not come, on every write rather than only the quit path, since a dawn or a day's-end write
	# is the common case and costs nothing extra to also flush promptly. **Neither this nor the
	# engine's own autosync is a hard guarantee against a tab killed with no JavaScript tick left to
	# run at all** — that gap is exactly why the dawn write exists as a second line of defence: it
	# lands during the next ordinary session's main loop, long before the following quit, so a save
	# that never reached IndexedDB on one close is still caught up by the time the game is closed
	# again. Whether this actually flushes on the deployed page is for a person to verify there,
	# never from this build alone.
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
				"if (typeof FS !== 'undefined' && FS.syncfs) { FS.syncfs(false, function(err) {}); }")
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
	# And the walls, the same way again: a save from before there were posters loads with none up,
	# and the next dawn pastes the city's from `PosterWalls.FIRST_DAY` onward.
	GameState.posters.reset()
	var posters: Variant = data.get("posters", {})
	if posters is Dictionary:
		GameState.posters.restore(posters)
	return {"day_under_way": bool(data.get("day_under_way", false))}
