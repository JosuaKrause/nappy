# The stair flight decks' diagonal tread strokes, superseded by vertical steps

`stair_flight_run_e.svg`, `stair_flight_run_w.svg` and `stair_flight_short_e.svg` drew each
flight's tread surface as a series of 45° diagonal strokes, parallel to the flight's own run
direction, crossing the deck perpendicular to its length. The player rejected this in
PLAYTEST-60 (see `docs/playtests/PLAYTEST-60.md`, "The stairs"):

> the stairways are also somewhat improved but the staircase floor graphic should be vertical
> lines for steps

Superseded by the current sources, which keep the exact same deck outline, canvas size and
top-landing registration — nothing in `src/interior/interior_scene.gd` moves — but draw the
treads as vertical lines clipped to the tread body, one per step, thickening toward the bottom
landing so the flight still reads as descending.

This file is preserved for historical reference only. It is not design guidance, a style
reference, or an implementation target for new art; no import sidecar belongs in this ignored
archive.
