# rosy-chipmunk — The save symbol waits for the browser, and a save not kept is struck through · 2026-10-02


Somebody reports that saving does not work in Safari on their iPhone while it works on their
iPad; the player passes it on and asks that the save symbol stay up until the save is confirmed,
show with a strike through when saving is unavailable, and that the IndexedDB repairs proposed in
conversation be built. Their words are in [cozy-pelican, saving on an iPhone](../playtests/2026-10-02-cozy-pelican.md).

**What the web save could not see.** `user://` on the web lives in memory and is copied into the
browser's IndexedDB, the only copy a reload finds. The game's flush was fire-and-forget
(`FS.syncfs(false, function(err) {})`), and the symbol flashed the moment the in-memory file
closed. So two failures reached the player as an ordinary save: storage refused at boot (Godot
prints "IndexedDB not available" and carries on from memory, `OS.is_userfs_persistent()` false),
and a connection lost mid-session, which Emscripten never reopens since `IDBFS.getDB` caches the
connection in `IDBFS.dbs` for the page's lifetime. iOS Safari is known to lose that connection from
a page left in the background under memory pressure, which an iPhone reaches far sooner than an
iPad. Neither is confirmed as the iPhone's cause; the build makes both visible and repairs the
second.

**What is built.** `GameSave.write()` answers `REFUSED` (a run `uses_save()` refuses, or one
already ended: nothing is drawn), `CONFIRMED` (off the web, the file closed), `FAILED` (the write
failed, or on the web storage is not persistent at that moment) or `PENDING` (on the web, waiting
for the browser). A pending save runs `window.nappySaveFlush`, defined once through
`JavaScriptBridge.eval` in the engine module's own scope, where `FS` and `IDBFS` are reachable
(the 4.7.2 web runtime is not closure-minified, and `godot_js_eval` evaluates directly inside the
module). It runs `FS.syncfs(false, …)`; on a failure it closes and drops every cached connection in
`IDBFS.dbs`, the same thing Emscripten's own `IDBFS.quit` does, and flushes once more, and only a
second failure is a failed save. The answer comes back through a `JavaScriptBridge.create_callback`
held for the page's lifetime. A flush that never answers counts as failed after
`FLUSH_TIMEOUT_SECONDS` (5s of drawn frames, several times the symbol's one-second minimum, and
proposed by the filer rather than asked for). The wait is counted in frames, each clamped to
`MAX_FLUSH_STEP_SECONDS` (0.25s), on `SceneTree.process_frame`, which fires while the tree is
paused: a hidden tab runs no frames and reports the whole time it was away as the first frame's
delta on its return, and a timer measuring that gap would have failed a flush the browser was never
given the chance to run, while the browser's own success a moment later is ignored by design — a
kept save struck through, in the very case (an app switch on an iPhone) the report was about. The run log gains "the browser kept the save" and
"the browser did not keep the save (reason)" lines under `save`.

**How long the symbol shows**, in the player's words ([cozy-pelican, how long the symbol
shows](../playtests/2026-10-02-cozy-pelican.md)): *"it shouldn't show if the save takes less than
100ms and it should always show for at least 1s -- if it fails it show for at least 10s"*, then,
once asked whether a fast save should show nothing, *"okay always show it. but show it for at
least a second"*, and a failure always shows its 10s. Statements 4 to 6 are built in
`SaveIndicator.Showing`:
- **Every save shows the symbol from the moment it starts**, with no delay threshold.
- **The symbol is fully shown for at least `MIN_SHOWN_SECONDS` (1s)**, counted from when it
  appears, and for longer while any save is still pending, the newest or an older one, so nothing
  still being written looks finished; then it fades over `FADE_SECONDS` (1.5s). The 1.5s hold
  after the answer is gone. Considered with golden-otter below: holding it only while the newest
  save is unanswered, which would let it fade over an older save the browser had not yet answered.
- **A save not kept shows `art/ui/save_unavailable.svg`** (the disk struck through, a red core in a
  dark casing, corner to corner) instead of `art/ui/save.svg`, fully for at least
  `MIN_STRUCK_SECONDS` (10s) counted from the moment it became struck, then the same fade. A
  failure answered in the same call as `begin()` is struck for the full 10s, and a web flush that
  times out after 5s keeps the struck picture up until 15s, since the clock starts at the strike.
- **A save beginning while the symbol fades or is gone brings it back to full and restarts the
  second**; one beginning while it is fully shown does not restart it, though the symbol still
  waits for that save's answer.
- **Only the newest save action decides the picture** (statement 9 and
  [golden-otter](../playtests/2026-10-02-golden-otter.md), the player's decisions). Asked whether a
  kept save after a failed one should clear the strike at once or keep the struck picture for its
  full 10s, the player chose **"Newest answer wins"** over "Keep the full 10s". The first build read
  "newest" as a batch: the saves from one that begins with nothing pending until the pending count
  returns to zero, struck if any save of the batch failed. The Codex reviewer found that an older
  save failing and a newer one kept, both answered while overlapping, left the symbol struck, and
  the player, during that review: *"if a new save succeeds it doesn't really matter if an old save
  failed. only the latest save action matters"* (golden-otter statement 1, which replaces the
  batch rule). So every write and deletion has an operation id from `GameSave._new_operation()`,
  increasing for the life of the process, carried on `save_written`/`save_deleted` and again on
  `save_write_settled`/`save_deletion_settled`. `Showing` keeps the ids it began and not yet
  answered and the largest id it began. That newest change's answer alone moves the strike: not
  kept strikes it at once and restarts the 10s, even while older saves are out; kept clears it,
  even with an earlier failure's 10s unspent, and the plain symbol then owes only its second. An
  older change's answer, in either order of arrival, only stops it being pending. `begin()` does
  not clear the strike, so a new save still unanswered does not hide a failure already known.
- **The strike keeps the traffic lights' red** (statement 11, the player's decision). `art/ui/
  save_unavailable.svg` strikes the disk in `#e04a3f`, the same red as `Palette.SIGNAL_RED`, a
  colour `src/palette.gd` otherwise keeps to the traffic lamps. Asked whether the strike should
  have a red of its own, the player chose **"Keep signal red"**. `palette.gd`'s note on the lamps
  now names this one exception and the choice.
- The clocks advance only through `Showing.advance()`, which `SaveIndicator._process()` calls
  while the game is paused too.

**Opening a saved game writes only when it charged a day** (statement 10, the player's decision).
Asked what opening a save should write, the player answered: *"either it saves with one less nerve
and a cleared "during active game" flag. or you defer saving to the actual day start"*. Both halves
are built, each for the case it fits. A save closed with its day under way is charged a nerve in
`main._ready()`, and `main._write_dawn_for_a_resumed_run()` writes that nerve with no day under
way before the title, so a kill at any instant finds what is on screen. A save closed between days
charged nothing and already says `day_under_way: false`, so opening it writes nothing and draws no
symbol; its next write is `_engage_the_day()`'s `true`, when the day starts. Before this, every
reopened save was rewritten at opening, whether or not anything had been charged. A charge that
ends the run deletes the save, which `write()` refuses to resurrect.

**Deleting the save shows the symbol** (statements 7 and 8). The player, quoting the sentence that
a day ending the run skips the save because ending the run already deleted it: *"show deleting the
save file with a save symbol as well. every change in the save state needs to show the symbol"*.
What is built:
- **`GameSave.clear(settled)` answers a `Result` like `write()`.** `REFUSED` when `uses_save()`
  refuses or there is no file to delete (a restart after the run already ended and deleted the save
  changes nothing, so it shows nothing: statement 8's last sentence); `CONFIRMED` once the file is
  removed off the web; `FAILED` when removal failed or on a web page whose storage was refused at
  boot; `PENDING` on the web, where a flush decides. It shares `_moment_result()` with `write()`.
  The ungated `_clear_now()` is the seam a test puts a scratch file away with, since `clear()` now
  refuses a headless run, which it did not before: a headless test run that ended a run used to
  delete whatever sat at `user://save.json`.
- **A web deletion is kept only once IndexedDB has dropped the file, and only `clear()`'s own
  flush says so.** Godot's web runtime copies `user://` into IndexedDB on its own after a removal
  as much as after a write: in the pinned 4.7.2 source, `platform/web/os_web.cpp` installs
  `OS_Web::file_access_close_callback` as `FileAccessUnix::close_notification_func` and
  `OS_Web::dir_access_remove_callback` as `DirAccessUnix::remove_notification_func`, and each sets
  `idb_needs_sync` for a path under `/userfs`, which the next `main_loop_iterate()` syncs. That
  sync reports its outcome to nobody, so the symbol would have nothing to wait for. `clear()` runs
  the same `FS.syncfs(false, …)` flush a write does, with its retry and timeout, and its answer is
  what settles the symbol; `IDBFS`'s populate-false pass drops from the store what is gone from
  memory. The first build's record and `GameSave`'s doc said a removal triggers no sync of the
  engine's own; a reviewer read the pinned source and found the remove callback, and both now say
  what the source does. The tab killed before any flush answers remains a gap, as it does for a
  write.
- **The route is `EventBus`, announced by `GameSave` itself, for a write as much as a deletion.**
  `GameState._end_run()` is an autoload and cannot reach `main`'s indicator. `clear()` emits
  `save_deleted(operation, result)`, and `save_deletion_settled(operation, kept)` when a web flush
  answers, and `write()` emits `save_written(operation, result)` and
  `save_write_settled(operation, kept)` the same way; `SaveIndicator`
  listens to all four and is the only thing that begins or answers the symbol. Considered: a
  signal carrying the result and a callback (the callback has to exist before the call that makes
  the result, so the caller could not supply it), and making the callers (`_end_run()`,
  `_restart_run()`) each announce (a third caller would have to remember to). Announcing inside
  `clear()` leaves both callers unchanged and makes "every deletion shows the symbol" a property
  of the deletion rather than of its callers.
- **A write's answer is not relayed by `main`.** `main._save_now()` first called `begin()` itself
  and bound `main._on_save_settled` as the web flush's callback. A reload that frees `main` while a
  web save is unanswered (a held restart on a day's summary while the end-of-day save is retried;
  the day-14 hand-over's reload to the escape) dropped that answer, since `_settle()` skips a
  callable whose object is gone, and the carried or surviving symbol's pending count never
  returned to zero: fully shown for good, which a reviewer reproduced (pending 1, alpha 1.0 after
  sixty seconds). The write now takes the deletion's route above, so `main._save_now()` is a bare
  `GameSave.write()`, and the one place that decides when the symbol begins is the indicator, which
  begins it exactly once per announced change. `write()`'s and `clear()`'s `settled` callable
  stays for a caller that wants the answer itself and is no longer how the symbol hears it.
  Considered: binding the callback to the indicator instead (the symbol would then be told by two
  routes, a callable for a write and the bus for a deletion, and a second place to keep in step).
- **The reopening charge shows it too.** `main._ready()` charges a resumed run before the HUD and
  the screens exist, so `_raise_save_indicator()` now runs right before the charge; a symbol built
  after it would never have heard the deletion. The finale walked out shows it through the symbol
  `_ready_escape()` already builds for a run's own escape.
- **The symbol survives every reload a run makes.** `main._carry_the_save_symbol_over()` hands the
  symbol to the scene tree's root (`SaveIndicator.outlive_the_scene()`) when it is up, the next
  `main` takes it with `SaveIndicator.carried()` instead of building a second, and its clocks,
  picture and `EventBus` connections run through the reload, so the browser's answer settles it on
  the new title or escape with the minimums intact. The reload is not delayed. Every reload in
  `main` goes through `main._reload_the_scene()`, which carries the symbol first: the held restart,
  the day-14 hand-over to the escape, and the flag's escape played again. The first build carried
  it only on the held restart; the Codex reviewer and the internal reviewer each reproduced what
  the hand-over then did to day 14's own save still pending at the reload: the symbol was freed
  with the scene, cutting its second short and never showing its failure, and the escape's new
  symbol began the escape's first save while day 14's answer, arriving on the global signal,
  settled it in its place, so the escape save's own failure was ignored. Carrying the symbol fixes
  the first, and the operation ids the second: an answer to a change a symbol never began is
  ignored, so an older scene's answer cannot settle the replacement's save. `_reload_the_scene()`
  hands the reload to `_reload_override` when a test has set one, so `tests/test_save.gd` drives
  the real `_on_summary_continued()` across the hand-over without throwing away the runner's
  scene. Because the symbol listens
  itself, no callable bound to the freed `main` is ever called; `_settle()` still skips a `settled`
  whose object is gone. Rejected: static state holding the timeline across the reload (shared
  mutable state every test would have to reset, and nothing draws it between the old indicator's
  last frame and the new one's first); an autoload (a `class_name` cannot also be an autoload
  name); delaying the reload for the flush (the player waits on a browser).
- **The held restart logs its deletion.** `main._restart_run()` calls `GameSave.clear()` before
  `Telemetry.end_run()`, which closes the run log: the "deleted the save" line, and the "deletion
  was not kept" line for a deletion that fails at once, land in the run that was abandoned. Nothing
  in `end_run()` reads the save, and `clear()` reads nothing the log's closing changes. A web
  deletion's own answer ("the browser dropped the deleted save") arrives after the log is closed and
  is not logged; `docs/TELEMETRY.md` says so.
- **Also fixed on the way.** A flush whose page JavaScript is unreachable used to settle before its
  caller had begun the symbol, which dropped the answer and left the symbol up for good; it now
  settles on the next idle frame.
- **Two stale sentences.** `SaveIndicator`'s class doc said the finale never saves and is reachable
  only behind a dev flag; a won day 14 with every task complete hands the run to it
  (`main._hands_over_to_the_escape()`) and its section briefs write the save. The doc, the
  `InteriorScene` doc and the architecture notes now say so.

**Rejected.** A strike drawn in code over the plain picture was the filer's first proposal and was
built first; the cues skill's "A picture is an asset, never code" (the player's own "Never draw in
code -- at the very least use svgs") rules it out, so the struck symbol is a second SVG on the `ui`
atlas page. A line on the title screen saying the browser keeps no saves was proposed and is not
built: the player's strike through answers the same need. A symbol that stays struck on screen
for the whole session was considered and not taken: the struck symbol shows at the save moments
only, for its 10s and a fade, which keeps the symbol's "noticed without distracting" bar. **A
100ms rule** (no symbol for a save answered within 100ms, anywhere or on the web only) came from
the player's first question and was overturned by their own *"okay always show it. but show it
for at least a second"*: a desktop save is answered in the frame it begins, so the rule would
have hidden the symbol on every desktop save. **A minimum that includes the fade**, and **a
minimum counted from the answer**, were the other two readings of "at least a second" and were not
taken; the player chose the symbol fully shown for the minimum, then the fade. A 1.5s hold after
the answer was dropped with them.

**Verified.** `tools/check.sh`, `tools/lint.sh`, `tools/test.sh save main orientation atlas held_restart title
finale telemetry` and
`tools/ci_telemetry_kinds.py` pass. The newest-action, operation-id and hand-over tests in
`tests/test_save.gd` fail with the batch rule, the uncarried hand-over and a second relay of a write
by `main` put back, respectively. On a debug web export in headless Chromium,
`tools/web-template/browser-check.mjs` passes, and a probe confirmed the flush function exists and
succeeds, that a connection failing once is reopened and the save kept, that one failing every time
reports the failure, that a flush that never answers keeps the plain symbol up and then shows the
struck one, and that storage refused at boot shows the struck symbol at once; that probe ran
before the operation ids and the hand-over carry were added and was not repeated. Not verified: the
release web export (it needs the custom runtime built with emsdk), that the custom runtime keeps the
same unminified names (its build passes no closure-compiler option, but the pinned source's
default was not read), and anything on a real iPhone.
