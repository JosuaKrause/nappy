# round-panda — A capture draws its own frame when the window is hidden · 2026-09-27 · not from an entry

*(2026-09-27: "Yeah fix all gaps." — after hearing that windowed captures were flaky.)*

**What happened.** Two agents taking the roof stills for M203 (a front nobody can stand at is
covered by the roof in front of it, PR #365) saw `tools/shot.sh` end on "a rig's own wall-clock
limit passed" again and again with no other Godot running: the run log showed the game running at
about 115 fps and the walk executing, and no picture. `caffeinate -d -u` helped only partly — one
still took sixteen attempts. An earlier agent found every windowed capture drawing nothing while
Google Chrome was frontmost holding a video wake lock. The verify skill said a rig's window "runs at full speed
while covered or unfocused" and had no advice for this.

**The cause.** Godot 4.7's macOS display server reports a window drawable only while
`[window occlusionState]` has `NSWindowOcclusionStateVisible` (`windowDidChangeOcclusionState:` in
`platform/macos/godot_window_delegate.mm` sets `is_visible` from it), and the main loop draws only
when some window is drawable (`can_any_window_draw()`). Processing and physics carry on regardless.
`AutoScreenshot._capture()` awaited `RenderingServer.frame_post_draw`, which a skipped draw never
emits, so a hidden rig waited until its wall-clock limit. The rig's window takes no focus and
`shot.sh` hands focus straight back, so it opens behind whatever the operator has in front — which
is why the failure came and went with what was on screen. The fps in the run log is
`Engine.get_frames_per_second()`, which counts main-loop iterations, not drawn frames, so it looked
healthy throughout.

**Measured**, with a standalone probe project logging `Engine.get_process_frames()`,
`Engine.get_frames_drawn()` and `DisplayServer.window_can_draw()` once a second:

- Covered by another app's ordinary window in front of it: `window_can_draw()` false, drawn frames
  frozen, process frames still advancing (at a reduced rate); drawing resumes the moment the cover closes.
- Minimized: the same.
- Display forced to sleep (`pmset displaysleepnow`) with the window visible: drawing carried on
  throughout. Display sleep alone is not a cause; a lock screen that follows it would be.
- `RenderingServer.force_draw(false)` while covered or minimized: emits `frame_post_draw` once and
  leaves a fresh frame in the viewport texture — a colour changed while hidden came back in the
  image.
- The real game, `tools/shot.sh out.png 3 --seed 4242 --walk 3s`: on `main`, covered, it ended on
  the wall-clock limit (and on one uncovered attempt did too, with whatever was frontmost in front
  of it); with the change, covered, it wrote the picture, identical to an uncovered one of the same
  seed, and a covered `--press snapshot_burst 1` burst completed with all 36 frames.

Another Space and a locked screen fall under the same occlusion test by macOS's own definition and
were not photographed that way.

**What was decided.** Every capture waits on `AutoScreenshot.drawn_frame()` instead of a bare
`frame_post_draw`: each `process_frame` it checks `DisplayServer.window_can_draw()`, and when that
is false forces one draw with `RenderingServer.force_draw(false)`. `shot.sh`'s still,
`--quit-when-still`, and the telemetry's stills and bursts all go through it. A still taken this way
says so on its `[AutoScreenshot] wrote` line. The verify skill says what a capture needs from the
machine (a display server, not a visible window), what `caffeinate -d -u` does and does not do,
and which line a remaining failure ends on.

**Rejected.**

- **Keeping the window presentable** — `WINDOW_FLAG_ALWAYS_ON_TOP`, or a position on screen. On top
  of the operator's own work is the interruption the rig lockdown exists to prevent, and it does
  nothing for another Space, a minimized window or a locked screen.
- **`caffeinate -d -u` as the remedy.** It keeps the display awake and marks the user active; it
  neither uncovers a window nor makes a covered one drawable, which is why it helped only when it
  happened to coincide with the window being in view.
- **Only a clearer timeout message.** The frame can be drawn, so the capture is fixed rather than
  explained.
