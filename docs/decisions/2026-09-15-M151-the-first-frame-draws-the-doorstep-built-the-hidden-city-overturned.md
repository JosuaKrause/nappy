## M151 — The first frame draws the doorstep · built 2026-09-15, the hidden city overturned

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "I don't really like blanking out the
first frame. can we just position the camera to the home so it will just draw what the title
screen will show anyway".)* One agent commit on `feature/m151-doorstep-frame`, reviewed on the
PR; the sanity still is `evidence/m151-doorstep-frame-2026-09-15/`.

**What it is.** The record below this one hid the city for the two frames `Main._ready()`
awaits inside the picture warm-up, before her camera exists. Overturned: a plain `Camera2D` at
the home's doorstep, at the stroller's play zoom and on the physics callback the scene camera
uses, is made current before the first await and freed right after `_start_day()` has placed
her, and freeing the current camera hands current to hers synchronously — checked against the
engine with a throwaway script rather than assumed. The city is never hidden. The halo
warm-up's probe, which stood at world origin because that is what the identity transform put
on screen, now stands at the boot camera's own ground, and both warm-up functions take that
ground as a parameter. The escape sequence's boot gets the same camera at world origin, where
nothing exists yet to show wrongly. `tests/test_camera_start.gd` asserts at the first
suspension that a current camera exists within a tile of the doorstep; it fails on the code
before with no camera at all and passes after. The agent's choice, open to overturn: the boot
camera targets the doorstep itself rather than a `--spawn` target, so under that developer flag
on day 1 the two boot frames show the doorstep while the day starts elsewhere, since matching
it would build the resistance before the day.
