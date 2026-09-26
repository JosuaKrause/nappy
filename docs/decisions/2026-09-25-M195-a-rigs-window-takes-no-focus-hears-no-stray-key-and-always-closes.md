## M195 — A rig's window takes no focus, hears no stray key, and always closes · built 2026-09-25

*([PLAYTEST-133](../playtests/PLAYTEST-133.md): "since it takes the focus away from what I'm doing
every time" · "right now if I click somewhere else they stay open" · "and the agent is waiting
forever" · "will it also prevent godot windows from staying open indefinitely?")*

**Why a covered rig stalled.** On macOS an unfocused or covered window throttles Godot's whole main
loop, not only its drawing, to about one iteration a second while vsync is on, so a
`--screenshot --after 25` run went on for minutes without firing. It is the engine's frame pacing,
not the game's own pause on focus loss, which a rig already skips. Measured by covering a rig's
window twice (both stalled) and then with Godot's `--disable-vsync` (both finished at 25 s).
`tools/shot.sh` and a rig's `tools/run.sh` now launch with `--disable-vsync`. Of eleven later
attempts, two early runs still failed without a cover and without a cause caught; the time limit
below ended both with an error. A stall the player sees again is what makes this worth
reopening.

**What is built.** `DevFlags.is_rig()` holds for `--screenshot`, `--walk`, `--flee`, `--press`,
`--tap` and `--route`. Under it `main.gd` sets the window's no-focus flag first thing, marks every
real input event handled in `_input()`, and strips the key and pointer bindings from every non-`ui_`
input action, so the rig's own presses still work and a stray key moves nothing. The game quits
itself, non-zero, once the OS clock passes `--after` (or the day's length) plus 15 s, never more
than 240 s; `tools/shot.sh` and a rig's `tools/run.sh` kill the process 15 s after that and say so.
`tools/shot.sh` reports a picture only when Godot exited cleanly and the file exists, and both
scripts refuse `--route` with `--screenshot`, since the route quits on arrival before `--after` can
fire.

**Not verified live, open to overturn:** whether the app still becomes frontmost in the menu bar
(the window flag stops key focus; macOS may still activate the process), and a real keystroke
into a rig, which could not be sent without scripting another app. The 15 s margin, 240 s ceiling
and 15 s kill grace were chosen so a 210 s day fits. `--tap` counts as a rig here but not in
`main._somebody_is_playing()`, which is unchanged.
