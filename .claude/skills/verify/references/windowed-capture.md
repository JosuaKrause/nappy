# A windowed run and its capture

Part of **verify**. Read it before planning a capture (`tools/shot.sh`, a windowed `tools/run.sh`,
a movie) and when a capture fails: it says why a rig's window is bounded, how a covered window is
still photographed, what a movie needs on top, and which failure each closing line names. The rule
itself, headless unless the picture is the question, is in `SKILL.md`.

## A rig's window is bounded, not free

**Working beside a windowed run is not free** (woolly-finch 1): the window opens on the player's
screen and loses focus the moment they do something else. A rig's own window carries three
defences against a run that never ends (`tools/decisions.sh M195`): it never takes the OS focus in
the first place (`DisplayServer.WINDOW_FLAG_NO_FOCUS`), its main loop runs at full speed while
covered or unfocused rather than throttling to about once a second the way an ordinary window's
does on macOS (`--disable-vsync`, both scripts' own launch; running is not drawing, see "A hidden
window is not drawn" below), and it always closes — the game's own wall-clock timer, backstopped
by `tools/shot.sh`'s (and a rig-flagged `tools/run.sh`'s) outside kill. None of that makes a
windowed run *free*, only bounded: it is still slower than a headless check by however long Godot
takes to boot a window and draw a frame, and a run left to its outside kill still costs the whole
of that wait before it says so.

**Several rigs may run at once**, windowed or headless, from different worktrees: each is its own
Godot process with its own window, and parallel agents capture side by side.

## A hidden window is not drawn

**A hidden window is not drawn, so a still or movie draws its own current frame.** On macOS the main loop skips its
draw step while no window of the process passes the system's occlusion test — covered by another
app's opaque window, or minimized, and by the same test on another Space or behind a locked screen
— and the game runs on in real time underneath: the walk goes on, the HUD's fps readout still shows
a healthy number, and not one frame is drawn. A rig's window takes no focus and `shot.sh` hands
focus straight back, so it opens *behind* whatever the operator has in front, and whether that
covers it depends on the window in front: an ordinary opaque window over it does, one the desktop
shows through may not. A capture that only waited for the render loop's next frame would wait for
ever there, and the run would end on `[Main] a rig's own wall-clock limit ... passed` however
often it was retried.
`DrawnFrame.wait()` (`src/drawn_frame.gd`) is what every still and burst under
`src/` waits on — `shot.sh`'s still, `--quit-when-still`, and the telemetry's stills and `snapshot_burst`
bursts, which `tests/test_auto_screenshot.gd` holds by failing on a bare wait for the render loop's
frame anywhere under `src/` — and when the window cannot be drawn it draws that frame on demand
with `RenderingServer.force_draw()`. Of the probes, `tests/probes/scenery_animation_runtime.gd`
waits on it too, and `scenery_shader_warmup_runtime.gd` keeps the render loop's own frame on
purpose, since the engine's warmup draw is what it measures, so it wants its window in view. A
forced still shows the same frame an uncovered window gives — the same scene and moment, not a
pixel-identical file, since two ordinary runs of one seed already differ — and its
`[AutoScreenshot] wrote` line ends "(window not visible, so this frame was drawn on demand)".

**A timed Godot movie carrying `--after` needs that answer on every covered frame, not only at the
final capture.** The simulation and a scene-recipe manifest keep advancing while an occluded movie
window repeats its last viewport texture, so a complete manifest cannot prove that recorded action
is visible. Its recording `AutoScreenshot` node calls `RenderingServer.force_draw(false)`
synchronously from `_process()` when `DisplayServer.window_can_draw()` is false. That draw must
finish before the movie writer captures the viewport texture; a deferred call can miss that
boundary and leave stale frames in the movie. Visible recordings and non-recording runs use the
ordinary render path. A trailer shot that promises visible action marks `motion: true`;
`tools/trailer.sh` rejects a selected cut with more than half a
second of identical consecutive PNGs before it encodes or deletes them. Check those raw-frame hashes
as well as the manifest when a movie is evidence of motion.

**So a capture needs a display server from the machine, and not a visible window.** Covered and
minimized windows are the two cases photographed through the forced frame; another Space and a
locked screen go through the same test and the same path and are not photographed that way.
A display that sleeps with the window visible keeps drawing. **`caffeinate -d -u` is not a remedy
for a covered window**: it keeps the display from idle-sleeping and marks the user active, which
neither uncovers a window nor stops a covered one from being skipped. What it does guard is the
one case with no photograph of its own — a display sleeping into a locked screen — so a long
capture run may still keep it on.

## When a capture fails

**The line a failed capture ends on says which failure it is.**

- `[AutoScreenshot] nothing to photograph: this run is headless` — no display server; see "A
  screenshot needs a display" below. No retry will change it.
- `[Main] a rig's own wall-clock limit ... passed` with no `[AutoScreenshot] wrote` line — the run
  never reached its capture in time, which a hidden window does not cause. Read the run back with
  `./tools/telemetry.sh` to see how far it got, and run it once more. A second identical failure is
  a bug in the rig or the capture path to report with that log, not bad luck to retry past.
- `shot.sh: killed Godot after ...` — the game's own limit did not fire either: the process
  stopped running, which is a hang to report, not a capture problem.

## A rig never pauses on focus and hears no stray key

**A rig never pauses on focus, unlike the game itself, and never hears a real key or pointer
press while it drives a run.** The game opens the pause screen on
`NOTIFICATION_APPLICATION_FOCUS_OUT`, the same notification a window loses the moment it opens
behind whatever the operator is doing — so left alone, every windowed run here would
capture a picture of the pause screen rather than the day it was sent to look at. `--screenshot`
carries `--no-focus-pause` on its own, so `shot.sh` needs nothing extra; a `run.sh` session with no
screenshot passes `--no-focus-pause` itself. A stray key typed into the operator's own foreground
window does not reach the rig either way — see README.md's "Dev flags" section,
"A rig's window and its wall-clock limit".

## A screenshot needs a display

**A screenshot cannot be taken at all without a display**, which is worth knowing before
planning a verification around one. `shot.sh` runs Godot *without* `--headless` on purpose, so a
process with no window server to open a window against falls back to the null display server, where
no frame is ever drawn and there is no viewport texture to save. `AutoScreenshot._capture()` says so
and quits non-zero rather than waiting — `_capture()`'s check of `DisplayServer.get_name()` is the guard,
and `"headless"` is the name Godot gives that null server.

**Whether a sub-agent can take one is a property of its environment, not of being a sub-agent** —
some background worktrees reach a display and photograph the game perfectly well. So do not assume
either way: **the guard is what answers it**, because a run with no display says so and exits
instead of sitting there. If an agent reports that capture "stalls" or hangs, that is the message it
should have got, and the branch is worth pulling and photographing from a session that does have a
display. A missing screenshot from an agent is a missing check, never evidence that the change is
wrong.
