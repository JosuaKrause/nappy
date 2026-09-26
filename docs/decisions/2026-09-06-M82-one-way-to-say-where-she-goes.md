## M82 — One way to say where she goes — 2026-09-06

**[PLAYTEST-28.md](../playtests/PLAYTEST-28.md), all three findings, plus the four answers under them, and
playtest 27's sixth finding for the walking rule itself.** The game had two control schemes chosen
on the title screen — the drag stick, and a tap-to-walk mode that fixed a heading *and* a target,
walked the straight line, and paused after `ARRIVAL_PAUSE_AFTER` (5s) of standing at it. Asked
whether the newly-specified aimed joystick (playtest 27 finding 6, drawn but never built) and the
tap scheme should stay as two comparable schemes or merge into one, the answer was *"get rid of all
other modes"* — larger than the question asked. **The game now has one scheme, chosen nowhere: a
press sets a direction, measured from her own world position, locked in and walked with nothing
held down until the next press changes it; a press within a generous radius of her stops her; a
double press sets the direction and holds `run` until the next press changes or releases it; a
pause button, top right, is the only thing drawn, and only on a touch device.**

**The destination is gone, not adapted.** `TapControls.walk_to()`'s target, `has_arrived()`'s plane
test and `ARRIVAL_PAUSE_AFTER` are deleted outright rather than reused, because there is nothing
left to arrive at. The heading calculation (`heading_to()`, a plain normalised offset) and the
double-press windows (`DOUBLE_TAP_SECONDS` 0.35s, `DOUBLE_TAP_DISTANCE` 60px) are the only pieces
of the old tap scheme that survive, unchanged.

**Stopping is a new mechanism, not the old arrival reused.** *"Also, to stop her just click on
her"* — a press within `STOP_RADIUS` (48px world-space, chosen wider than `PLAYER_BODY_RADIUS`
14px alone so a press on the pram at `PRAM_DISTANCE` 34px off her side still counts) releases
whatever direction and `run` were held. `STOP_RADIUS` is a felt number nobody has played against
yet, the same shape `DOUBLE_TAP_DISTANCE` and `RUN_CATCH_RADIUS` (the deleted `RUN` button's own
catch radius) already were when they were first picked — it moves against a played day like they
do.

**`TouchControls` and `TapControls` are one file, not two.** The pause button was the tap scheme's
one drawing gap once `ARRIVAL_PAUSE_AFTER` — its only way to raise a pause — went with the
destination: *"tap mode ... this mode does not have UI elements"* was true only because arriving
was the pause. Giving the surviving scheme a pause button meant giving it something to draw, and
the class that already drew one (`TouchControls`, the stick's own file) is what the direction-and-
stop logic (formerly `TapControls`) was folded into, rather than teaching a second, undrawn node to
reach into the first one's statics. What survived the merge: the pause button itself (centre,
radii, release-catch), `_send_pause_action()`, `_set_axis()`/`_release_movement()`, the
force-release-on-pause discipline (now triggered on any pause, not only on the drawn stick going
invisible, since a keyboard-and-mouse desktop never draws anything to go invisible), `process_mode
= ALWAYS`, and the `ScreenOrientation.to_design_space()` remap — now also needed for the pause
corner to be excluded from the aiming surface, which the old aimed-tap-anywhere design never had to
subtract anything from.

**The mouse gate lost its debug-build half.** *"I still need to press space even in mouse mode"*
(a laptop, on the released, non-debug build) was two defects in one: `TapControls._input()` read a
mouse click only behind `OS.is_debug_build()`, so the one build a player ever loads had no mouse
input at all; and `TitleScreen`, `DaySummary` and `PauseScreen` accepted only `ui_accept` or a real
touch, so the keyboard was the only way past any of them regardless of scheme. `TouchInput.is_press()`
(a touch or a left-mouse click) is what `TitleScreen` and `PauseScreen`'s own plain "carry on" ORs in
beside `ui_accept` on every build. `DaySummary` needed its own explicit `not _touch`-gated mouse
branch instead of that same helper: `_acknowledge_and_continue()`'s two-frame delay leaves
`is_showing()` true long enough for a real touch's own emulated mouse click to arrive while the
screen is still open, and folding that click into `TouchInput.is_press()` unconditionally would
have fired `continued` a second time underneath the very guard (`_continuing`) built to prevent it.
`DaySummary`'s own former reason for reading touch directly — *"rather than turned into a synthetic
click, so a stray mouse press elsewhere on the desktop still cannot skip a summary a player has not
read"* — is overturned deliberately: it was true only while no scheme invited a player to use the
mouse, and the pointer scheme now does everywhere.

**`ControlsMode` and the title screen's two circular buttons are deleted, not deprecated.** With one
scheme there is nothing for `--controls`/`?controls=` to select, nothing for `is_forced()` to mean,
and nothing for the title to ask — it returns to the single "space/tap to begin" hint it had before
the buttons existed. `assets/ui/joystick.svg` and `tap.svg` go with it; `ModeButton` loses the
`STICK`/`TAP` symbols and their SVGs, but not the class — M76 (`#26`) landed while this milestone was
in flight and built `RESTART`/`CONTINUE` in full, hold-fill bar and all, on both the pause screen
and the day summary. Merging the two meant re-indexing `Symbol` down to `{ RESTART, CONTINUE }`,
which changed what the serialized `symbol = N` in `scenes/ui/day_summary.tscn` and
`pause_screen.tscn` meant — caught only by a screenshot, since nothing in the suite constructs a
`ModeButton` from its own scene file's saved int. M76's own restart/continue buttons read a touch
position directly rather than through a `Button`'s `pressed` signal, for the same "Godot delivers
both a real touch and an emulated mouse event" reason `DaySummary._acknowledge_and_continue()` does
— so they needed the identical mouse extension, gated `not _touch`, that the plain "carry on" path
got.

**Playtest 28's fourth finding, found once the rest of this milestone had already landed:** *"the
game over screen cannot have a continue button."* `DaySummary.show_ending()` shared
`_refresh_buttons()` with `show_day()`, which shows both the continue and the restart button on any
touch device — but continue on an ending is drawn as *continue* and does *start over*, the same
promise the restart button already makes honestly. `_showing_ending` (set by `show_day()`/
`show_ending()` before `_present()`) is what `_refresh_buttons()` now reads to hide `_continue_column`
specifically, leaving the row itself, and `_restart_button`, exactly as before — *"the restart
button, hold and all"* is the player's own answer to whether the hold still earns its keep with no
day left to protect. The catch-all underneath — a press anywhere on the ending still starts again —
is untouched.

**Not built as specified: the SVG-icon conversion the `cues` rule asks for.** Editing
`touch_controls.gd` anyway is exactly the trigger `cues` names for converting the pause button's
`_draw()` primitives to an SVG asset, and it was not done — TODO.md's own "drawing work is
deprioritised while the graphics overhaul is in flight" was read as the more specific and more
current instruction for this session. Flagged rather than silently skipped, in case a later reader
disagrees with the call.
