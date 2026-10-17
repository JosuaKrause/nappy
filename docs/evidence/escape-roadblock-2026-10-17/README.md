# The escape's roadblock, passed by luring its guard off (inbox #771)

**The claim.** In the escape's city section a roadblock street carries one band, walking straight
past it with its guard posted is caught, and once the guard on her side has been lured into a
charge and run off, walking past the band costs nothing and raises no mark over her.

## The measurement

`tests/probes/escape_roadblock_cost.gd`, on the rig `tests/escape_roadblock_rig.gd`. Per seed, the
finale's own plan (`FinalePlanner.plan()`), and on every open street carrying a roadblock, those
roadblocks alone, as real `EventInstance`s on the real map stepped by hand at 60Hz; the meter fed
as `Baby._update_excitement()` feeds it, at the street's decay. Every crossing is walked both ways
along the middle of the open sidewalk, from 0 asleep (what every attempt at the city section
starts on: `main._on_finale_section_started()` calls `Baby.reset()` then `force_sleep()`) and from
60 awake. "posted" walks straight past; "lure" walks in until a guard charges, runs back until he
gives up and waits until he has gone; "after" walks on past from there. A cost is the meter's
peak less where the walk started. Seeds 4242, 1, 77, 9001, 23, 5, 31337 and 2024.

| Source | Streets | Bands | Posted: caught | Lure cost | After: caught | After cost, asleep | After cost, awake 60 |
|---|---|---|---|---|---|---|---|
| `main` (`5f7923b6`) | 112 | 184 (72 streets with two) | 224 of 224 | 6.7 to 18.3 | 144 of 224 | 0 | 3.0 to 9.4 |
| one band a street only | 115 | 115 | 230 of 230 | 6.7 to 30.0 | 0 of 230 | 0 | 5.2 to 7.2 |
| this branch | 115 | 115 | 230 of 230 | 2.8 to 4.3 | 0 of 230 | 0 | 0 |

On `main` all 144 caught walks after the lure are the two-band streets: the second band's guard
is still posted. "One band a street only" is this branch with `EventCatalogue.escape_roadblock()`'s
`silent_once_unmanned` set false, so the band's field stays on after the lure; the lure's high end
there is standing in that field while he walks off (idle decay is zero). Asleep, the band's 9/s
under `Tuning.SLEEPING_SENSITIVITY` (0.55) is below the walking decay (6/s), which is why the walk
past is free asleep in every row. Every walk's line is in `probe-main.txt.gz`,
`probe-item2-only.txt.gz` and `probe-branch.txt.gz`; the probe at `a2b94a29` produced all three.

**Rerun**, in a fresh checkout of this pull request's head (after the merge,
`git fetch origin refs/pull/781/head` and check out `a8a6d065`), with `check.sh` run once:
`tools/test.sh probes/escape_roadblock_cost.gd > OUT.txt` for this branch's row; for `main`'s,
the same after `git checkout 5f7923b6 -- src` (the rig reads only the plan, so it runs on either);
for the middle row, after setting `escape.silent_once_unmanned = false` in
`src/events/event_catalogue.gd`. Each writes `ESCAPE_ROADBLOCK` lines, the last eight a summary.

**Limits.** The roadblocks alone: the plan's vans, trucks and bursts are not live, so the figures
are the roadblocks' own and not what a whole crossing costs. Her body is a point moved along a
line, not the physics body. The lure's policy is fixed (in, back at a run, wait), so a player who
runs longer or waits elsewhere pays a little more or less for the run.

## The stills

`strip.png` is the four stills below at half size, labelled by `strip.py`. One run's moments, each
its own boot of the same script, on this branch at `a8a6d065`:

```sh
tools/shot.sh OUT.png SECONDS --seed 7 --start-escape city --invincible --player-view \
    --press ui_accept 0.3 --walk 0.1e5.4n0.8S5p8n
```

with SECONDS 4.6, 5.9, 6.5 and 13.2. She walks north up the street the service exit opens onto
toward its one band, which covers the carriageway and the east sidewalk and leaves her west one
open; at about 5.4s she crosses the stand-off of the guard posted on her side and he charges; she
runs south for 0.8s and he gives up and walks off; she waits 5s and walks north past the band.

- `a-posted-4.6s.png`: the band and the guard on her side at his post, the mark over her.
- `b-lured-5.9s.png`: he charges; she runs.
- `c-run-off-6.5s.png`: he has given up and walks off up the sidewalk; no mark over her.
- `d-walking-past-13.2s.png`: she is level with the band; no mark over her. The guard at the far
  post stays standing as a drawing.

`--invincible` stages the lure only (the meter and clock do not move under it, so the stills show
nothing about cost; the probe above is the cost). Nothing in a still shows a field; the probe and
`tests/test_finale.gd` hold that the band's field is zero after the lure.

Footprint: four stills, the strip, its script, three compressed probe outputs and this README.
