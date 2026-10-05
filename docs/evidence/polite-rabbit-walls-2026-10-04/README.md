# Excitement stops at walls: the picture, the route costs and the frame cost

*(plaid-wombat, inbox #554: "Excitement should not go through any wall but it's not
straightforward. If the player is partially in a wall they should not be protected so the blocking
should happen in the middle of the wall (or one tile deep)"; inbox #568: "half a tile was only
supposed to be done if the wall is only one tile wide otherwise it should be one tile".)* Three
questions about the change that makes every source's contribution zero once the line from it to her
reaches a tile (`Tuning.WALL_SHIELD_DEPTH`, 32px) into a building thicker than one tile, or the
middle (`Tuning.THIN_WALL_SHIELD_DEPTH`, 16px) of a wall one tile thick (`CityMap.wall_between()`):
does a source behind a building stop reaching her on screen, what does it do to the price of the
day's routes, and what does it cost a frame. The first build blocked at half a tile everywhere;
what was measured of it is kept below, marked as such.

## The still pair

`wall-between.json` is a scene recipe: the recipe context city (`context_seed` 1917501), day 2, no
crowd, a street musician (`busker`, 19.3/s over a 45–190px field) on the square at (2992, 2608) and
her standing still at (3152, 2608), 160px east of him on the sidewalk beyond the four-tile building
between them. Both stills are its `playback.capture_at`, five seconds in, taken with
`tools/scene-recipes.sh --recipe wall-between.json --screenshots`.

Before (revision 03e96344): the musician wears an orange rim and the meter has reached 17.

![before](before.png)

After (revision ea5f0b4c): no rim, and the meter is at 0. The first build (d07de58b) gave the same
picture.

![after](after.png)

## The corner pair: what #568 changed

`corner-graze.json` is the same city and musician, here at (2928, 2576) on the square, with her at
(2864, 2512) on the sidewalk round the south-west corner of the building beside it, 91px away: the
line between them cuts the building's corner more than half a tile deep and less than a whole tile.
Both stills are five seconds in, taken the same way.

First build (revision d07de58b, half a tile everywhere): the corner shields her, no rim, the meter
at 0.

![first build](corner-first-build.png)

As built (revision ea5f0b4c, a tile in a building thicker than one tile): the corner is a graze,
the musician wears a red rim and the meter has reached 51.

![as built](corner-as-built.png)

A still of a one-tile wall was not taken: in this city no tile a musician can be placed on has a
one-tile wall between it and open ground within 140px (a scratch search over every tile his row's
ground offers, not kept), and the hand-built cases in `tests/test_wall_shield.gd` hold that rule.

## Route costs

`tests/probes/polite_rabbit_wall_costs.gd` (`tools/test.sh probes/polite_rabbit_wall_costs.gd`,
about twenty to thirty minutes on a loaded machine) builds each day the game builds —
`City.start_day()`, then `EventManager.start_day()` with the seals and the region's bodies — for
seeds 4242, 90210 and 1337 on days 1, 5, 9 and 13, and walks every route of the day's `RouteTree`
from the doorstep at `Tuning.WALK_SPEED` with the events streamed and the crowd stepped around her.
Each step prices every source three ways: through walls, as built, and at half a tile everywhere
(the first build). Its own check holds that the as-built sum is what `contribution_at()` charges.
`route-costs.txt` is its output at revision ea5f0b4c.

| | Through walls | As built | Half a tile everywhere |
|---|---:|---:|---:|
| Events, gross points over 184 routes (11,064s walked) | 22,867.2 | 22,619.0 (−1.1%) | 22,441.9 (−1.9%) |
| Crowd, the same walks | 17,760.9 | 17,760.9 | 17,760.9 |
| Events per minute walked | 124.0 | 122.7 | 121.7 |

The largest single day's drop as built is seed 4242's day 1, 1,305.8 to 1,254.3 points (−3.9%).
Not one crowd body was ever behind a wall on these walks: a walker's field reaches 30px, a car's
104px abeam and at most twice that ahead, and a route runs down sidewalks whose buildings stand
behind her rather than between her and the carriageway. `docs/COSTS.md` prices a row met with
nothing between, so none of its rows move.

`route-costs-first-build.txt` is the same probe at d07de58b, whose columns were through walls,
half a tile everywhere and a whole tile everywhere. Its first two agree with the table above to the
decimal. **Its whole-tile column (22,616.7) is wrong**: the band clip then accepted a tile shrunk
from both sides past itself, so a one-tile wall still blocked at a whole tile; ea5f0b4c refuses
such a band, and the new suite holds it.

**Limits.** The events are not ticked: each is priced at its own live rate where it stands when
streamed in, so a mobile row is met where it starts and nothing pursues; the decay is left out
because it is the same either way. The route tree's cells are walked through the middle of their
walkable tiles, not along a lane.

## Frame cost

**What the wall test itself costs.** `count-walls.patch`, applied to revision ea5f0b4c, counts every
`CityMap.wall_between()` call and its own time, printing the totals every 300 physics steps;
`wall-calls.txt` keeps the lines from headless runs of seed 4242 walking `3s8e4s8w` for 25s on days
1 and 9, four of each as built and one of each for the first build. Between steps 300 and 900:

| Day | Build | Calls a frame | Time a call | Time a frame |
|---:|---|---:|---:|---:|
| 1 (234 crowd bodies) | as built, four runs | 9.9 – 17.9 | 2.3 – 2.9µs | 23 – 53µs (three runs 23–28) |
| 9 (50 crowd bodies) | as built, four runs | 1.1 – 1.5 | 3.1 – 6.2µs | 4 – 7µs |
| 1 | first build | 8.8 | 2.7µs | 23µs |
| 9 | first build | 1.1 | 3.9µs | 4µs |

A headless run is not held to the display, so it draws about 4.8 frames a physics step rather than
two, and it is not frame-for-frame repeatable: the walk meets different sources from run to run,
which is the spread above. The meter asks once a step for each source whose field reaches her; the
rest are the cue pass, the halo's pick and the caret's projection, which asks at up to twenty
projected places for every source whose field reaches one of them.

**What the whole frame does.** `timing.jsonl` holds every timing batch taken, in order, each line
naming its batch and revision. The frame-record lines are `analyse.py`'s summary of one headless
`--frame-record` run (seed 4242, `--walk 3s8e4s8w --after 25`, the first 150 physics steps left
out): the influence sweep per physics step (`Baby._physics_process()`, the meter's sum) and the
cue pass per frame (`ExcitementHalo._process()`, the halo's pick and the carets). The crowd-sweep
lines are `tests/probes/m159_contribution_cost.gd`'s median microseconds for one
`Crowd.excitement_sources_at()` over 180 sampled frames, three repetitions a run.

- **Batch 1** (base, a quiet machine): day 1 influence 248–254µs a step, cues 1,320–1,336µs a frame;
  crowd sweep 57.9µs on day 1, 10.7µs on day 9.
- **Batch 2** (the first build's first commit, c8d81f85): day 1 influence 286–295µs, cues
  1,470–1,502µs, about a sixth more; day 9 no higher.
- **Batch 3** (the line walk reading the tile grid directly rather than through three calls a
  tile, and a by-value answer for the present contribution): day 1 still 289–295µs and
  1,473–1,504µs. A change to the line walk that moved nothing pointed at the crowd instead:
  every body is asked `contribution_at()` every step and frame, and the first commit had split its
  field into a second function, a call more for all 234 of them.
- **Batch 4** (that field folded back into `contribution_at()`, d07de58b): taken while other
  agents' test runs had started loading the machine, so frame counts swing by half and the figures
  by a third run to run.
- **Batches 5 to 8** are therefore interleaved, before and after alternating, the same load on
  both: batches 5 and 6 by swapping the four source files between the two revisions in one
  checkout, batches 7 and 8 with `measure.sh` on two checkouts — 7 against the first build, 8
  against the build as it stands.

| Interleaved, `measure.sh`, 3 pairs | Before 03e96344 | First build d07de58b (batch 7) | Before 03e96344 | As built ea5f0b4c (batch 8) |
|---|---:|---:|---:|---:|
| Day 1 influence, µs a step (mean of runs) | 374 | 386 (+3%) | 447 | 487 (+9%) |
| Day 1 cues, µs a frame | 2,115 | 2,158 (+2%) | 2,558 | 2,780 (+9%) |
| Day 9 influence, µs a step | 300 | 323 (+8%) | 370 | 382 (+3%) |
| Day 9 cues, µs a frame | 1,296 | 1,329 (+3%) | 1,668 | 1,670 (0%) |
| Day 1 crowd sweep, µs | 86.6 | 94.7 (+9%) | 105.2 | 106.6 (+1%) |
| Day 9 crowd sweep, µs | 16.0 | 17.3 (+8%) | 19.5 | 19.7 (+1%) |

Batch 8 ran under the heaviest load of all (761 to 1,696 frames in a day 1 run that draws about
2,900 on a quiet machine), which is also why its "before" column is higher than batch 7's. Batch 6
(crowd sweep, 3 pairs, first build) reads 87.7 to 92.4µs on day 1 (+5%) and 16.5 to 17.5µs on
day 9 (+6%). The frame-record differences sit inside a run-to-run spread of up to a quarter, so
they bound the change rather than measure it: a few percent to a tenth of the two buckets the wall
test touches, consistent with the 23 to 53µs a frame the counted calls take on day 1. Native
desktop CPU only; nothing here says what a phone pays.

## Rerunning

Everything runs from the repository root of a checkout of the revision named.

- The stills: `tools/scene-recipes.sh --recipe docs/evidence/polite-rabbit-walls-2026-10-04/wall-between.json --output <new dir> --screenshots`, once on each revision; needs a display.
- The route costs: `tools/test.sh probes/polite_rabbit_wall_costs.gd`.
- The wall-test count: `git apply docs/evidence/polite-rabbit-walls-2026-10-04/count-walls.patch`
  on a scratch checkout of ea5f0b4c, `tools/check.sh`, then `<godot> --headless --path . -- --seed 4242 --day 1 --no-title --no-save --walk 3s8e4s8w --after 25` and the same with `--day 9`, reading the `ZZWALLS` lines.
- The interleaved timing: two clean checkouts, of 03e96344 and of the revision to compare (fetch
  `refs/pull/<PR>/head` first once the branch is gone), then
  `docs/evidence/polite-rabbit-walls-2026-10-04/measure.sh --before <checkout> --after <checkout> --output <new dir> [--godot <path>]`; `analyse.py` beside it summarises any further record.
