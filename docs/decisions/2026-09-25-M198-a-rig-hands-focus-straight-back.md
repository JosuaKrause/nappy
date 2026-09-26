## M198 — A rig hands focus straight back · built 2026-09-25

*([PLAYTEST-133](../playtests/PLAYTEST-133.md): "are all agents using the non-focus rig now? I still
lose focus and even accidentally closed one window" · "let's try (a) for now".)*

**Why the jump cannot be stopped.** M195's no-focus window flag keeps keys out of a rig's window,
but Godot's own macOS startup calls `activateIgnoringOtherApps:` once its window is ready, which
makes the app frontmost however it was launched. Rejected, measured on the closed #357: a
background launch through `open -g -n -W` only delayed the jump (a walking rig was frontmost for
34 of 38 `lsappinfo front` samples) and `-j` made it worse; no flag, project setting or
GDScript-reachable API gates the call. Also offered and not taken: accepting the jumps, and
fewer windowed captures.

**What is built: the jump is undone.** `tools/lib_dev_flags.sh` holds it, used by `tools/shot.sh`
and a rig-flagged `tools/run.sh` on macOS only. `rig_focus_note()` records the frontmost app's
bundle path before Godot launches (nothing if there is none, or if it is already a Godot);
`rig_focus_watch_start` polls `lsappinfo front` every 0.1s and, whenever the frontmost pid is this
rig's own Godot — by pid, never by name, since other agents run Godot too — reactivates the noted
app with `open -a`. A switch to any other app is left alone. Godot still launches directly, so
its output, exit status, time limit and kill are unchanged. No `osascript` or Apple Events. The
watcher is stopped when `wait_or_kill` returns, by an `EXIT` trap otherwise, and exits by itself
once its Godot is gone. Measured on an 8s walking capture: Godot frontmost for 1 of 89 and 0 of 85
samples, against 15 of 69 with the watcher off; a 2s still, 0 of about 37, three runs.

**A trap found building it:** captured as `x="$(rig_focus_watch_start …)"`, the watcher inherited
the command substitution's pipe, so the assignment waited for Godot to exit and `wait_or_kill`'s
kill was never armed; a hung stub showed it. The watcher's output goes to `/dev/null`.

**Open to overturn or unverified:** `open -a` by bundle path rather than `open -b` by bundle id;
the 0.1s interval was not compared against 0.2s, since the flicker was already under one sample;
if the noted app quits while the rig runs, `open -a` would relaunch it; a second agent's
*windowed* Godot in front at launch was not exercised. Whether the player's own focus now stays
put is in `REVIEW.md`.
