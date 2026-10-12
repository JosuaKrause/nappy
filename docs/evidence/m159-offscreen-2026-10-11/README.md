# M159: nothing off screen is redrawn, measured before and after

Evidence for the M159 item "nothing off screen is redrawn or animated"
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "Skipping redraws for of
screen elements. Also we don't really change things with animation if it's of screen. If we have a
bounding box that extends a little bit into of screen then it won't be noticable."). The claims:
the off-screen gates take most of the game's own `_draw()` calls and the events' per-frame key work
out of a frame, **nothing drawn on the screen changes**, and two of the places the investigation
named measured too little to build.

**Platform and method on every number.** One Apple M2 desktop, Godot 4.7.2 (the app bundle's
binary), `gl_compatibility`, on a machine other agents were using (the 1-minute load average before
each run is in `provenance.tsv`, 1.7 to 3.9 for every kept run). Not a phone and not a browser. The
microseconds are this desktop's; the ratios and the counts of `_draw()` calls are the transferable
part. What the phone gains is for its next frame record.

## What was built (`feature/m159-offscreen-redraw`)

- `DrawnView` (`src/ui/drawn_view.gd`): the one box, the world the viewport's canvas shows grown by
  64 world px (two tiles), worked out once a process frame.
- `CrowdAgent._redraw_if_the_picture_changed()`: an agent none of whose drawing (`DRAWN_REACH`, two
  tiles about its feet and a car's doubled caret above) is in the box asks for no redraw and
  projects no caret; its key is still kept every frame, and it redraws once on its first frame back.
- `EventInstance._redraw_if_the_picture_changed()`: an event none of whose drawing (`footprint_of()`
  with its spread and the caret) is in the box, and whose roadblock band is not either, runs no
  picture key, no caret projection and no redraw, never-settling pictures included; it redraws
  once on its first tick back. A leaving flock is always drawn.
- `DangerEdge`: redraws while a badge is up and once as the last comes down, not every frame.
- `HomeArrow.hide_arrow()`: redraws only when it hides a shown arrow (the HUD hides both arrows
  every frame neither is wanted).

## Measured before building (a scratch copy of the base, not committed)

`scratch-instrumentation.patch.gz` (gzipped because it carries GDScript's tabs; `git apply` on
`01b8a79b` after `gunzip`) counts and times, per process frame, what each gate would skip, using
the same box. Windowed 1280x720, seed 67, the player's walk (below), 40 seconds, one run each;
`scratch-summary.py` printed `scratch-base-d1.txt`, `scratch-base-d14.txt` and
`scratch-base-d1-mortal.txt` (the same day 1 without `--invincible`, so the meters move). Means per
frame:

| | day 1 (234 agents) | day 14 (86 agents, 45 events) |
|---|---|---|
| crowd agents in the box | 49 of 234 | 12.6 of 86 |
| crowd redraws off screen | 12.9 of 16.0, at 35µs each | 4.5 of 5.3, at 46µs each |
| car caret projections off screen | 21, 219µs | 12, 130µs |
| events in the box | 1.5 of 33 | 3.1 of 44 |
| event picture keys off screen | 400µs | 502µs |
| event redraws off screen | 2.5 of 2.8 (one a frame a never-settling picture), 118µs each | 2.6 of 2.7, 132µs each |
| empty badge-edge redraws | 1.0, 1.9µs | 1.0, 2.0µs |
| hidden-arrow redraws | 2.0, 2.3µs | 2.0, 2.4µs |
| an on-screen car redrawn for its bob alone | 1.05, about 37µs | 0.26, about 12µs |
| meter bar redraws (mortal day 1) | 0.16, of which 0.01 with the same picture | — |

**Not built, because they measure nothing worth the cost:** the meter bar, whose value changes
draw a different picture on all but 0.01 of its 0.16 redraws a frame; and an on-screen car's bob,
about one redraw a frame on day 1, whose fix needs a car's body split onto its own canvas item
between the shadow and the wheels — more render objects for every car in view, on the phone whose
largest bucket is the renderer's. The badge edge and the arrow measure a few microseconds a frame
here and are built since each is a one-condition change.

## Before and after

`run.sh` (`run.sh /tmp/scratch 3 base=01b8a79b offscreen=1dd4190b`) made a detached sparse
worktree for each revision, imported each with `tools/check.sh`, then ran three rotated rounds of
seed 67, days 1 and 14, headless and windowed (1280x720, always on top, VSync off), each
`--invincible --player-view --frame-record --after 40` with the player's walk
`2.6e15.5n1w4n1e11n11s1w4s1e15.5s` (`docs/evidence/m159-frame-record-2026-10-04/measure.py`'s
`WALK`). `analyse.py <out>` read the 24 frame records into `runs-summary.tsv` (one line per run:
frames, the frame's median, mean and 95th percentile, each bucket's mean, the `_draw()` calls by
kind and the renderer's draw calls and objects) and `conditions.txt` (each condition's median run
and range). `provenance.tsv` is the run order, commits, load and the hashes of the four source
files. The records themselves (3.9 MB) are not kept; a rerun takes a fresh scratch directory and
its numbers will differ a little.

**One run was rejected and retaken:** round 2's windowed day 1 on the branch ran beside two other
engines the runner had waited five minutes for (its frames were 12.0ms against 7.0 to 7.7ms for
the other two); it is retaken in the same slot after the rotation, and the rejected run's line is
the last in `provenance.tsv`.

Medians of three runs [range], per frame:

| | base | branch |
|---|---|---|
| **windowed day 1** `_draw()` crowd / events / badges / other | 10.6 / 2.9 / 1.0 / 3.3 | 1.5 / 0.2 / 0 / 1.2 |
| `draw` bucket | 544µs [494..575] | 138µs [129..155] |
| `events` + `cues` | 2220µs | 1944µs |
| `crowd` | 2274µs [2217..2362] | 2163µs [2135..2183] |
| frame mean | 8.37ms [8.15..8.48] | 7.07ms [7.03..7.68] |
| draw calls / render objects | 266.7 / 941.2 | 264.7 / 934.9 |
| **windowed day 14** `_draw()` crowd / events / badges / other | 3.5 / 1.3 / 1.0 / 3.2 | 0.5 / 0.1 / 0 / 1.2 |
| `draw` bucket | 376µs [368..403] | 220µs [219..234] |
| `events` + `cues` | 1994µs | 1734µs |
| `crowd` | 940µs [925..974] | 890µs [880..920] |
| frame mean | 6.27ms [6.13..6.58] | 5.75ms [5.73..6.16] |
| draw calls / render objects | 376.9 / 991.9 | 376.9 / 993.3 |
| **headless day 1** `events` / `cues` | 805µs / 1363µs | 449µs / 1587µs |
| **headless day 14** `events` / `cues` | 1295µs / 1103µs | 862µs / 1292µs |

What the table says, and what it does not:

- **The named work fell in every run.** The game's own `_draw()` calls a frame fell from about 18
  to 3 on day 1 and from 9 to 2 on day 14, and the `draw` bucket, which holds them, by 0.40ms and
  0.16ms. The `events` bucket, which holds the events' keys and their caret projections, fell by
  about 0.4ms headless and windowed on both days. Every branch run is below every base run on
  each of these.
- **Part of the events' saving reappears under `cues`.** `cues` rose by 0.13 to 0.22ms on every
  pairing: the halo's own once-a-frame projection of every live source (`ExcitementHalo`,
  `expected_gross_at()`) now pays for work the events' caret had done earlier in the frame and left
  for it to reuse. `events` plus `cues` still fell by 0.13 to 0.28ms. Taking the halo's own work
  down is the sibling item, "the cues and the events step less", not this one.
- **`crowd` did not rise**, so the box test each agent now makes costs no more than the car caret
  projections it skips.
- **The whole frame fell by about 1.3ms on day 1 and 0.5ms on day 14 windowed**, more than the
  buckets above explain on day 1, where `render` also moved by run-to-run noise (2.5 to 3.1ms in the
  branch's three runs). Three runs a side on a shared desktop establish the direction, not the
  size; nor do they say anything about perceived smoothness on the phone.
- **Nothing on the screen changed.** Draw calls and render objects match on day 14. On day 1 the
  branch's per-frame means are about 1% lower (render objects 928.8 to 939.0 against 940.6 to
  943.0), and averaged over each five seconds of the walk instead they match within the runs' own
  spread (1196 to 1202 in the first five seconds, 756 to 774 in the emptiest): the branch runs
  more frames in the cheaper stretches of the walk, which weights its mean towards them. The walk
  is driven by the wall clock, so no two runs draw the same frames.

## The same frame, before and after

`still-base-d14.png` and `still-offscreen-d14.png`: `tools/shot.sh <png> 14 --seed 67 --day 14
--invincible --no-save --player-view --walk 2.6e15.5n1w4n1e11n11s1w4s1e15.5s`, taken from the two
worktrees one after the other. She has walked into the day-14 checkpoint by then, with the burst
main, the barriers, the soldiers and the walkers in view, several of whom walked in from off screen.
The two differ in 3,345 of 921,600 pixels, all inside the walkers' own boxes: the walk is driven by
the wall clock, so two runs place the crowd a few pixels apart, which a still cannot tell from a
picture left stale. The tests carry the claim a still cannot: `tests/test_drawn_view.gd` walks a
red-marked car and a red-marked cyclist in from off screen a step at a time and checks that each
asks for its redraw, caret up, no later than the first step any of its own drawing reaches the
screen; that a picture unchanged while off screen is still redrawn on its first frame back; that
the badge edge redraws on the frame a badge goes up and once as it comes down; and that the reach
the crowd asks with holds every view of every car and walker and the doubled caret.

## Footprint

Files in this folder and their bytes are listed in the pull request description.
