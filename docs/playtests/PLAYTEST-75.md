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

> "that is not the curbstone -- it's the sidewalk"
> "I specifically said *curbstone*"

Said on 2026-09-14 to the first build, which tinted the whole kerb *tile* — the pavement's
edge tile, paving and all — rather than the curbstone, the strip of stone along the tile's
road-side edge. Re-opened as M145's correction in `TODO.md`.

## A pocketed agent stands instead of pacing

> "I get the remove entity when there is no route idea. maybe let's do instead stop the entity
> if there is no way. and despawn once offscreen"
> "it looks very weird otherwise"

Said on 2026-09-14, on v0.10.7. What is built is M119, the crowd with nowhere to go leaves: an
agent a seal goes up around is recycled at the first frame it is out of view, and in view it
paces to the far seal and back, one stride between about-faces. The pacing is what looks
weird. Filed as M146 in `TODO.md`: stand where the seal caught it, and leave unseen as today.

## A route crossing the carriageway mid-block

> "how is this path possible? the rule is to only allow crossing at crossings never across the
> street"

Said on 2026-09-14 to a v0.10.7 screenshot, seed 2128084176, day 1, with the route layer on:
the purple route line runs down one pavement, jogs across the carriageway between two
junctions and continues down the other. A re-report, closed from the older entry: M129, a
path through the city never has to cost, carries the item *mid-block crossings are not
counted on* — the route tree grows on the reachability grid's cells and crosses a carriageway
mid-block about three times per route today, and the item is a change to how the corridor is
grown, with the probe's own mid-block count as its test. Not yet built.

## A rolling graph of frame times

> "hmm, I don't see a graph showing the history of the fps / spikes"
> "I would expect there to be an overlay that shows the last x frames of frame times in a
> rolling window"
> "not sure what you thought that would be"

Said on 2026-09-14, on the `--spikes` branch. What "spike line" was built as is a line in the
run log (M144); what the player meant by it was a graph on screen. Filed as M148 in
`TODO.md`: an overlay under the readout drawing the last frames' own lengths as a rolling
window, the spikes marked.

## A stutter whenever a new picture is shown

> "I feel whenever a new entity/image/sprite is shown there is a visible stutter. this would be
> an argument *for* a full atlas so sprites don't need to be loaded in late"

Said on 2026-09-14, on v0.10.7. Read against the code the same evening: `TextureResolver`
loads each picture's PNG transfer from disk the first time that picture is drawn, inside the
frame, once per distinct picture per run, and the halo's shader is built at the first halo.
Filed as M147 in `TODO.md`: every picture loaded before the day starts, and the spike line
naming a late load when one happens. The atlas is recorded as the player's word for when
draw calls are the cost; the phone reading says they are not yet.

## The stutter branch on the laptop, with every picture warm

> "hmm, burst/screenshots prevent spikes from happening"

Said on 2026-09-14 of a run on the stutter branch (v0.10.7-37, the graph, the warm pass and
the spike line all present; "86 pictures warmed in 233 ms" at boot), seed 3762731053, day 1,
with two bursts pressed; the whole run is
`evidence/playtest-75-desktop-stutter-2026-09-14/run-220628-seed3762731053-v0.10.7-37-gcf305c28/`.
The log reads the bursts differently from the graph: while a burst records, every frame is 60
to 76 ms and the second draws 33 to 47 fps, since the capture reads the viewport back each
frame — so nothing in such a second is twice its mean and the graph colours no bar amber,
while a frame past 33 ms is still red. Outside the bursts the seconds read 85 to 91 fps with
a worst frame of 24 to 26 ms in every one of them, the same frame playtest 75 read on
v0.10.6 — so with every picture loaded before the day, the laptop's once-a-second hitch is
still there and the late loads were not it. Read in `DECISIONS.md`, M147, every picture
loaded before it is needed.

## Atlases by group, loaded before they are drawn

> "so I think the correct strategy is to pack together graphics into atlases and load/unload
> atlases in a clever way so it happens while the things that will get drawn haven't been
> drawn yet (so the graphics can be properly loaded asynchronously). for example all head
> indicators should be in one atlas and loaded together (zzz and the exclamation sign and the
> tildes etc.). at least all 8 directions of an entity should be in one atlas. since entities
> spawn off screen their graphics can be loaded before they will be visible"

Said on 2026-09-14, on the reading above. Filed as M149 in `TODO.md` with what the code says
about its premise: an entity's pictures are imported SVG rasters preloaded with its script at
boot, so no entity picture was ever loaded late; the late loads were the prop, rig and ground
transfers, warm since M147; and the laptop's hitch outlived that. The question of whether to
build it is put to the player there.

## The route grower's graph

> "why not just remove the street tiles and main street blocks from the graph entirely?"

Said on 2026-09-14 while M129's four rules were being built, for the fourth: mid-block
crossings are not counted on. The construction it names — the tree grows on a graph with no
carriageway cell but the junctions' and no main-road cell at all — was handed to the agent on
that branch as the way to build the rule, with the reachability grid the winnability and
closure guarantees are stated over left as it is.
