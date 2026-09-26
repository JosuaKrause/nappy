## M211 and M212 — The held restart starts a new game, on the pause screen and on a phone · built 2026-09-26

*([PLAYTEST-142](../playtests/PLAYTEST-142.md): "the pause screen is currently bugged where you cannot
restart from it. it just goes back to the current game when pressing the button" · "the restart
button doesn't visible fill up on mobile when pressing. and sometimes it just doesn't work at all" ·
[PLAYTEST-143](../playtests/PLAYTEST-143.md): "restart button restarts the game from scratch".)*

**What reached the continue path (M211).** A real touch goes through the engine's
emulate-mouse-from-touch pass, which dispatches an emulated mouse press before the touch press
itself. `PauseScreen._unhandled_input()`'s "any press carries on" branch read that mouse press as
continue, because unlike `_handle_restart_touch()`'s mouse branch and the day summary's own catch-all
it was not gated on `not _touch`. The screen closed and cancelled the hold before the touch's
release could complete it. The branch is now gated like the others. The existing touch tests used
`Viewport.push_input()`, which skips that emulation, so they never saw it.
`tests/test_held_restart.gd` drives touches through `Input.parse_input_event()` and
`flush_buffered_events()` instead.

**What cancelled a hold on a phone (M212).** A second finger anywhere on the screen while the disc
was held: `ModeButton.begin_hold()` refused the second index, but the refused press still fell
through to "carry on", whose close cancelled the hold, on both the pause screen and the day
summary. `ModeButton.is_held()` now guards each screen's `_handle_restart_touch()`. Ruled out, and
said so in the test's class doc: a drag off the disc (a release ends a hold by touch index alone),
a release reaching another control, and a fill drawn only on hover (`_draw()` reads
`hold_progress` alone). The fill is pinned by reading `hold_progress` partway through a real hold
on both screens. Each fix's test fails with the fix reverted.

**Why the fill was invisible on a phone.** The fill is a translucent white sweep over the disc.
Under a mouse the cursor hovers the disc for the whole hold, so the disc sits on the brighter
`Palette.BUTTON_HOVER` and the sweep reads; a touch never hovers, so the sweep painted over the dark
`BUTTON_FILL` and barely showed. *([PLAYTEST-144](../playtests/PLAYTEST-144.md): "this is already
implemented for mouse. Just make it appear everywhere.")* `ModeButton._refresh_look()` now takes
the bright fill for any hold, mouse or touch; a test drives both through the engine's real input
path on both screens and fails with the fix reverted.

**The restart fires the moment the disc is full**, not when the finger or button is lifted
*([PLAYTEST-144](../playtests/PLAYTEST-144.md): "The button only activated when releasing though" ·
"It should trigger the moment it is full")*. `ModeButton` raises `hold_completed` from `_process()`
the frame `hold_progress` reaches full, once per hold; both screens restart on it. The later release
only ends the hold: it neither restarts again nor reads as carry on. A test holds a touch and a mouse
on both screens and sees the restart before any release, and fails with the fix reverted.

**Not verified on a device.** No capture shows the disc filling under a held finger: `--tap` sends
press and release in one frame and `--press` carries no screen position, so a sustained synthetic
touch needs a new dev capability. It waits on a phone (`REVIEW.md`).
