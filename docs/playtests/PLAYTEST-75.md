# Playtest 75 — 2026-09-14

A desktop debug session, reported in one sentence on 2026-09-14.

## A layer turned off leaves its last picture behind

> "pressing number keys to turn off a layer doesn't remove the layer anymore. for example if I
> press 2 twice I have ghost circles all over"

`2` is the shadow-outline layer; the circles are the walkers' shadow outlines, still on
screen after the key turned the layer off. Filed as M142 in `TODO.md`. The cause is read from
the code there: the layer node asks for a redraw only while a layer is on, and a retained
`_draw()` keeps its last picture until the next redraw, so the frame that turns the last layer
off is never drawn.

## The desktop stutters above sixty frames

> "local laptop also stutters even though fps is way above 60"
> "this is on current checkout"
> "so no physics ceiling yet"

Two desktop screenshots of v0.10.6-4-g278c8788 — `main` before the physics tick was
lowered — seed 3362612925, day 1, taken with `P`; the whole run folder is
`evidence/playtest-75-desktop-stutter-2026-09-14/`. The readout reads 89 and 85 fps with
`process  last 24.3  mean 21.3  max 24.3` and `last 66.7  mean 51.8  max 66.7`, physics 1.7
throughout, and the run log's own `frame` lines read a worst frame of 16 to 24 ms in every
second the day ran at 85 to 112 fps. What those numbers are, and what the two candidate
causes of the stutter are, is read in `DECISIONS.md`, M138, what the readout's `process` and
`physics` lines measure. The readout fix is M143 in `TODO.md`; the smoothness question goes to
the physics-tick release, M141.
