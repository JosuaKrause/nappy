## M202 — A rig's own presses reach the game · built 2026-09-25

*(Found building M137, the trap comes to her: a `--press snapshot_burst` capture recorded
nothing.)*

**Why they were lost.** M195's lockout has `Main._input()` mark every event handled while
`_rig_locked_out`, and `--press` is itself a rig flag, so the lockout was on for every run that
pressed anything and swallowed the rig's own presses with the real ones.

**What is built.** `AutoScreenshot._tap()` sets `event.device = InputEvent.DEVICE_ID_EMULATION`
(the engine's reserved `-1`) on every event it injects, action form and `key:<name>` form alike,
and `Main._input()` lets through only what `_is_the_rigs_own_press()` recognises by that tag;
`Input.parse_input_event()` carries the device through both input phases. Rejected: letting a
whole event class through, since a `key:` press is an `InputEventKey` like a real key and a real
`InputEventAction` can reach a window too. `--tap`'s touch event was never lost, because every
node's `_input()` runs before any handled mark stops the next phase. `tests/test_rig_press.gd`
holds both halves: a real key or pointer press is swallowed while locked out, and the rig's own
presses of both forms reach the unhandled phase. One windowed `--press snapshot_burst 2` wrote a
36-frame burst.
