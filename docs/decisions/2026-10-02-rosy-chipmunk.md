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
  appears, and for longer while any save is still pending; then it fades over `FADE_SECONDS`
  (1.5s). The 1.5s hold after the answer is gone.
- **A save not kept shows `art/ui/save_unavailable.svg`** (the disk struck through, a red core in a
  dark casing, corner to corner) instead of `art/ui/save.svg`, fully for at least
  `MIN_STRUCK_SECONDS` (10s) counted from the moment it became struck, then the same fade. A
  failure answered in the same call as `begin()` is struck for the full 10s, and a web flush that
  times out after 5s keeps the struck picture up until 15s, since the clock starts at the strike.
- **A save beginning while the symbol fades or is gone brings it back to full and restarts the
  second**; one beginning while it is fully shown does not restart it, though the symbol still
  waits for that save's answer.
- **The strike follows the newest answer** (statement 9, the player's decision). Asked whether a
  kept save after a failed one should clear the strike at once or keep the struck picture for its
  full 10s, the player chose **"Newest answer wins"** over "Keep the full 10s". A batch is the saves
  from one that begins with nothing pending until the pending count returns to zero. When it does,
  the picture is struck if any save of the batch failed, and every failure restarts the 10s; it is
  plain if every save was kept, even with an earlier batch's 10s unspent, and then owes only the
  normal second. A failure while other saves are pending strikes the picture at once. `begin()`
  does not clear the strike, so a new save still unanswered does not hide a failure already known.
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
- **A web deletion is kept only once IndexedDB has dropped the file.** Godot's web runtime copies
  `user://` into IndexedDB after a file open for writing is closed (the engine's web platform marks
  the store dirty from the file-close notification; not confirmed against the pinned source or a
  browser, since neither a web export template nor a browser was available when this was built); a removal closes no file, so a bare `remove_absolute`
  could leave the stored copy to bring back a run that already ended on the next load. `clear()`
  runs the same `FS.syncfs(false, …)` flush with its retry and timeout; `IDBFS`'s populate-false
  pass drops from the store what is gone from memory. The tab killed before any flush answers
  remains a gap, as it does for a write.
- **The route is `EventBus`, announced by `GameSave` itself.** `GameState._end_run()` is an
  autoload and cannot reach `main`'s indicator. `clear()` emits `save_deleted(result)`, and
  `save_deletion_settled(kept)` when a web flush answers, and `SaveIndicator` listens. Considered:
  a signal carrying the result and a callback (the callback has to exist before the call that
  makes the result, so the caller could not supply it), and making the callers (`_end_run()`,
  `_restart_run()`) each announce (a third caller would have to remember to). Announcing inside
  `clear()` leaves both callers unchanged and makes "every deletion shows the symbol" a property
  of the deletion rather than of its callers.
- **The reopening charge shows it too.** `main._ready()` charges a resumed run before the HUD and
  the screens exist, so `_raise_save_indicator()` now runs right before the charge; a symbol built
  after it would never have heard the deletion. The finale walked out shows it through the symbol
  `_ready_escape()` already builds for a run's own escape.
- **The held restart's symbol survives the reload.** `main._carry_the_save_symbol_over()` hands the
  symbol to the scene tree's root (`SaveIndicator.outlive_the_scene()`) when it is up, the next
  `main` takes it with `SaveIndicator.carried()` instead of building a second, and its clocks,
  picture and `EventBus` connections run through the reload, so the browser's answer settles it on
  the new title with the minimums intact. The reload is not delayed. Because the symbol listens
  itself, no callable bound to the freed `main` is ever called; `_settle()` still skips a `settled`
  whose object is gone. Rejected: static state holding the timeline across the reload (shared
  mutable state every test would have to reset, and nothing draws it between the old indicator's
  last frame and the new one's first); an autoload (a `class_name` cannot also be an autoload
  name); delaying the reload for the flush (the player waits on a browser).
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

**Verified.** `tools/check.sh`, `tools/lint.sh`, `tools/test.sh save orientation atlas main` and
`tools/ci_telemetry_kinds.py` pass. On a debug web export in headless Chromium,
`tools/web-template/browser-check.mjs` passes, and a probe confirmed the flush function exists and
succeeds, that a connection failing once is reopened and the save kept, that one failing every time
reports the failure, that a flush that never answers keeps the plain symbol up and then shows the
struck one, and that storage refused at boot shows the struck symbol at once. Not verified: the
release web export (it needs the custom runtime built with emsdk), that the custom runtime keeps the
same unminified names (its build passes no closure-compiler option, but the pinned source's
default was not read), and anything on a real iPhone.
