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

## The hitch without the observer

> "I tried with no telemetry (manual screenshot) but I'm not sure I actually captured any
> stutters (I did see them)"

Three desktop screenshots of the same build under `--no-telemetry --debug`, seed 555797753,
day 1, running; `evidence/playtest-75-desktop-stutter-2026-09-14/no-telemetry/`, named by
the `fps` and the `process last` they read. They did capture it: `process last` is the
longest frame of the previous second, and two of the three read 24.0 and 24.4 ms at 87 and
103 fps — the same 24 ms every second of the telemetry run read — while the third read 11.5
at 119 fps, a second with no hitch in it. So the observer's log write is not the hitch, and
whatever is, it makes a frame of about 24 ms in most seconds and none in some. Read in
`DECISIONS.md`, M138, what the readout's `process` and `physics` lines measure; the probe
that would find it is M144 in `TODO.md`.

> "spike line sounds good"
> "make that toggleable separately though since it can be quite noisy"

Said to the M144 probe on 2026-09-14; it goes to an agent as filed, with the line behind its
own flag.

## The route's curbs, tinted

> "also one gameplay experiment I want to try -- can we tint the curbstones that belong to a
> path slightly yellow? to give a faint hint on an optimal path. I just want to try it out. this
> is in addition to the environmental guidance through obstacles. it should be faint as to more
> subconciously guide as well"

> "that's why I'm framing it as experiment. I don't really want it to be how we show paths but
> I want to assess whether it can be done without being too obvious and on the nose"

Said on 2026-09-14. Filed as M145 in `TODO.md`, as the experiment it is: the city's own
record says it never suggests a route and there is no cue of any kind toward calm
(`CITY.md`, "Guiding her to the calm"), and this is not that rule overturned but a trial of
whether a hint on the ground can stay under the threshold of being noticed as one — beside
the guidance through obstacles, and not the way paths are meant to be shown.
