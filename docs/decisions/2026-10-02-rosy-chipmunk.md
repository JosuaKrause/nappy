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
`FLUSH_TIMEOUT_SECONDS` (5s of game time, several times the symbol's one-second minimum, and
proposed by the filer rather than asked for). The run log gains "the browser kept the save" and
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
- **The strike follows the newest answer.** A batch is the saves from one that begins with nothing
  pending until the pending count returns to zero. When it does, the picture is struck if any save
  of the batch failed, and every failure restarts the 10s; it is plain if every save was kept, even
  with an earlier batch's 10s unspent, and then owes only the normal second. A failure while other
  saves are pending strikes the picture at once. `begin()` does not clear the strike, so a new
  save still unanswered does not hide a failure already known.
- The clocks advance only through `Showing.advance()`, which `SaveIndicator._process()` calls
  while the game is paused too.

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
