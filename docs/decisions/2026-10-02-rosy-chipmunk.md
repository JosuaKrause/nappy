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
`FLUSH_TIMEOUT_SECONDS` (5s of game time, longer than the symbol's whole hold and fade, and
proposed by the filer rather than asked for). `SaveIndicator` stays fully shown with no timer while
any save is pending, starts its 1.5s hold and 1.5s fade once every one has settled, and shows
`art/ui/save_unavailable.svg` (the disk struck through, a red core in a dark casing, corner to
corner) instead of `art/ui/save.svg` when a save in that showing was not kept. The run log gains
"the browser kept the save" and "the browser did not keep the save (reason)" lines under `save`.

**Rejected.** A strike drawn in code over the plain picture was the filer's first proposal and was
built first; the cues skill's "A picture is an asset, never code" (the player's own "Never draw in
code -- at the very least use svgs") rules it out, so the struck symbol is a second SVG on the `ui`
atlas page. A line on the title screen saying the browser keeps no saves was proposed and is not
built: the player's strike through answers the same need. A symbol that stays struck on screen
for the whole session was considered and not taken: the struck symbol shows at the save moments
only, held and faded like the plain one, which keeps the symbol's "noticed without distracting"
bar.

**Verified.** `tools/check.sh`, `tools/lint.sh`, `tools/test.sh save orientation atlas main` and
`tools/ci_telemetry_kinds.py` pass. On a debug web export in headless Chromium,
`tools/web-template/browser-check.mjs` passes, and a probe confirmed the flush function exists and
succeeds, that a connection failing once is reopened and the save kept, that one failing every time
reports the failure, that a flush that never answers keeps the plain symbol up and then shows the
struck one, and that storage refused at boot shows the struck symbol at once. Not verified: the
release web export (it needs the custom runtime built with emsdk), that the custom runtime keeps the
same unminified names (its build passes no closure-compiler option, but the pinned source's
default was not read), and anything on a real iPhone.
