## M127 — The first press walks her · built 2026-09-13

*(2026-09-13, [PLAYTEST-67](../playtests/PLAYTEST-67.md): "the player direction should be reset to
zero when the game starts. Right now it always starts already walking (probably from clicking
the button) same with exiting pause or any other screen"; "Pause can keep the last direction
just don't overwrite it from the button press".)* Two agent commits on
`feature/m127-first-press`, reviewed here.

**The fall-through was a fourth mechanism, not either of the two the entry named.**
`TouchControls._on_pointer()` armed its drag pointer for the press that dismisses a screen even
though `_on_tap()`'s own paused-tree guard had already made that press a no-op; every dismissing
screen acknowledges a press two frames late, so a finger or mouse button still down for a couple
of frames produced an ordinary drag or motion event for the same pointer once the tree was
running again, and `_on_drag()` read it as a fresh heading. Reproduced on a scratch rig with a
follow-up jitter of two pixels, which is why a touchscreen reported *always* rather than
*sometimes*. The fix is an early return in `_on_pointer()`: a press that never reached the world
is never armed for a later drag either. **The title disc was never reachable this way** — the rig
`_on_drag()` needs is null on every boot and restart — and the summary's continue button, which
keeps one `TouchControls` running across days, was the vulnerable one;
`tests/test_touch.gd`'s new case sets a direction first, as an earlier day's walk would have, to
make the leak reachable at all. No explicit zeroing was added: once the dismissing press cannot
plant a heading, the existing force-release when a screen pauses the tree already leaves her
standing, and a second zeroing would be repairing a guarantee rather than checking it.

**Pause keeps the last direction, and it was not only the leak.** Opening the pause
force-releases the held direction and nothing restored it, so a mid-walk `Esc` and continue left
her standing. `TouchControls.remember_before_pause()` and `resume_after_pause()` stash the
heading and the run flag the instant `PauseScreen.open()` runs and press them back once
`close()` runs, whichever of the screen's three exits gets there; only the pause screen gets
this — the title and the summary want the release with nothing restored, which is what they
already did. Two cases in `tests/test_pause.gd` hold the entry's own wording: pause walking east
and continue resumes east; pause standing and continue stays standing.

**One silent choice, open to overturn.** A direction key still held through the title screen's
synchronous unpause reads as a nonzero input on the next physics frame, because the engine's
input map drives the move actions independently of `TouchControls`; left as is, since
suppressing a genuinely held key would be a worse defect than the one closed. `space` starts the
run standing. No timer or grace window anywhere.
