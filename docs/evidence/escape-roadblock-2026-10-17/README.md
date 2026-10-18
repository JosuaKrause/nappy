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
nothing about cost; the probe above is the cost).

**The far guard leaves too** (inbox #771, the player's answer "He leaves too").
`far-guard-leaves.png`, four frames of one burst on this branch at `f1d5dd3d`, cropped to the
street by `bursts.py` (`--crop 480,0,1120,600`, frames 1, 13, 21 and 35):

```sh
tools/shot.sh OUT.png 9.2 --seed 7 --start-escape city --invincible --player-view \
    --press ui_accept 0.3 --press snapshot_burst 5.9 --walk 0.1e5.4n0.6S0.2p8n
```

The same crossing, with a shorter run back and no wait, so the band is still in view when the
guard on her side gives up. A: he charges and the guard at the far post, north of the band, is
standing at it. B: he walks off up the west sidewalk, and the far post is empty. C: she walks past
the band with nobody at it. D: beyond it, still nobody. On this crossing the far guard sets off
from just above the top of the view, straight away from her, so he is not seen walking: the frames
show his post empty from the frame his partner walks off (on `main`, and in still D above, he stays
standing there). `tests/test_finale.gd` holds his walk, his pace and his end out of her sight. Nothing in a still shows a field; the probe and
`tests/test_finale.gd` hold that the band's field is zero after the lure.

## The player's run on seed 4216201080, and the guard who could not be seen (inbox #771)

**The player's run.** `run-235901-seed4216201080-v0.28.0-7-g5f7923b6/` is the run folder the
player's game wrote on `main` at `5f7923b6`, under its original name, copied from the player's own
scratch telemetry, which they may empty. Three of its files are kept: `run.log`, the player's own
walk, which no replay recreates; `auto/003-attempt1-mark-now.png`, a band at the top edge of the
view while she is marked; and `auto/004-attempt1-chase-roadblock.png`, the two bands, the guard
between them and the carts on the roof's edge. Its other two stills are left out: one is the
building section's loss screen and the other a van on another street, neither of which bears on
either claim here. Seed 4216201080 from the building
(`tools/run.sh --start-escape --seed 4216201080 --no-save` replays it). Lines 179-212 of `run.log`
are the city attempt the player could not win: the guard of a band at tile (72,22) warns and
charges, she runs and he gives up, and on her way back the guard of a second band at (72,20) warns
for half a second and catches her. `auto/004-attempt1-chase-roadblock.png` shows the two bands two
tiles apart with one guard between them.

**The guard who could not be seen.** `hidden-guard.png`, four frames of one burst, cropped to the
street, built by `bursts.py`. Taken on this branch at `5586bff1` with
`Tuning.FINALE_GUARDS_PER_STREET` set back to 2 for the capture only, which reproduces `main`'s
plan for the seed exactly (642 placements, bands at (72,20) and (72,22), as the player's
`run.log` says):

```sh
tools/shot.sh OUT.png 35 --start-escape city --seed 4216201080 --invincible \
    --press ui_accept 1 --press snapshot_burst 30.5 --walk 3p9.63n0.7w5.33n0.7e3.55n1.2S6p5n
```

- A: the near band's guard on her side steps out with his hand up.
- B: between the two bands stands one man.
- C: the near band's guard charges; the far band's guard is warning too (his caret is up), and the
  only man under the caret is the near band's far-side guard, a drawing.
- D: the far band's guard, who was standing at his post between the bands the whole time, shows
  from behind the near band's barrier and its far-side guard.

So the cause is the drawing order, not the camera or the streaming: the far band's guard on her
side stands two tiles in front of his band, which puts him just behind the near band, and both
the near band and the guard it posts on its far side sort nearer her than his feet and are drawn
over him. The branch now keeps two bands' notices apart (twice `Tuning.HEAT_HUNTS_WITHIN`), draws a
warning guard above the street's other figures, and has the escape's guard notice her only once
he would stand in her view (`EventDef.notices_in_her_view`): a separate case found by measuring,
a band beside a junction seen from the cross street, where his radius alone reached her with his
head off the top of the view. `tests/test_finale.gd` holds all three.

**After.** `one-guard-on-screen.png`, the seed 7 crossing above on this branch at `1c0f5d3f`, as
a burst (`--player-view`, `--press ui_accept 0.3 --press snapshot_burst 4.2`, the same walk,
8 seconds): one band, its guard steps out on screen with his hand up, charges, and walks off once
she has run.

**Spacing.** `tests/probes/escape_roadblock_spacing.gd` over seeds 1 to 40, its `ESCAPE_SPACING`
lines in `spacing-before.txt.gz` (this branch at `1c0f5d3f` with the
`_keeps_its_notice_to_itself()` call taken out of `EventScheduler._fill_a_finale_street`) and
`spacing-branch.txt.gz` (at `1c0f5d3f`):

| | Roadblocks | Pairs nearer than their two notices (360px) | Nearest two |
|---|---|---|---|
| before | 594 | 135 | 160px |
| this branch | 508 | 0 | 362px |

Rerun: `tools/test.sh probes/escape_roadblock_spacing.gd > OUT.txt` in a checkout of the pull
request's head (`git fetch origin refs/pull/781/head`).

## The escape's placement and the day's (inbox #785)

**The wood on the roof.** `alley-mouth-walls.png`, two stills of the same moment cropped to the
block east of the tunnel chain's street, from

```sh
tools/shot.sh OUT.png 8 --start-escape city --seed 4216201080 --invincible \
    --press ui_accept 1 --walk 3p20n
```

A at `5586bff1`, B at `462958b8`. The block has a through-alley the chains do not use, and the
escape walls both its mouths. In A each wall is the collapsed frontage, a street seal 192px long
laid across the 64px alley, so its timbers stand two tiles into the buildings either side, over
their roofs; in B each is the widest row of the escape's own list that fits the mouth, the impact
crater. The crater's picture is a little wider than its body, so its rim still touches the alley's
walls.

**The carts on the roof's edge.** On the player's still
(`run-235901-seed4216201080-v0.28.0-7-g5f7923b6/auto/004-attempt1-chase-roadblock.png`) the wooden
carts at the right edge are a different seal, the barricade standing across a street off the
chain, and the leftmost stands over the building's roof edge. Which of the two the player meant is
theirs to say; both are fixed. A day stands that seal the same way: its pieces were centred in even
shares of the street, so the 62px barricade, two to the 192px street, reached 14px into the
buildings either side. `barricade-off-the-roofs.png`, two stills of one moment on the player's
seed, cropped to the block east of the tunnel street with the carts at its top right and a second
barricade across the street below it, built by `pair.py` (`--crop 700,150,1280,720`):

```sh
tools/shot.sh OUT.png 22.5 --start-escape city --seed 4216201080 --invincible --player-view \
    --press ui_accept 1 --walk 3p9.63n0.7w5.33n0.7e3.55n
```

A at `5a078d80`, B at `0ab30c98`, where a hard seal's outer pieces stand flush with the street's
edges (`SealPlanner.positions_across()`). In A the carts stand over the roof's east edge and the
column's top cart over the building's front; in B both stop at the sidewalk.

`tests/probes/seal_overhang.gd`, over seeds 1 to 30, days 1 to 14 and the escape, its
`SEAL_OVERHANG` lines in `seal-overhang-before.txt.gz` (at `5a078d80`) and
`seal-overhang-after.txt.gz` (at `0ab30c98`); the measure is `tests/seal_reach_rig.gd`'s, each
solid piece's body without her body radius and the ground its picture is drawn over:

| | Day barricade pieces over a building | Escape barricade pieces over a building | Deepest | Any other row |
|---|---|---|---|---|
| before | 1,269 of 1,494 (body) | 2,799 of 3,326 (body), 2,587 (drawing) | 14px | none |
| after | none | none | | none |

Every row's piece count is the same before and after.

**Density.** `tests/probes/escape_density.gd` over ten seeds, its `ESCAPE_DENSITY` lines in
`density-before.txt.gz` (at `2d775386`, the escape's own ground), `density-after.txt.gz` (at
`462958b8`, the day's ground) and `density-with-the-calm-rule.txt.gz` (`462958b8` with
`_reaches_any(candidate, _calm_to_leave_alone(map, []))` added to the candidate's refusals in
`EventScheduler._fill_a_finale_street`, the day's calm rule, which is not built):

| | Trucks | Vans | Roadblocks | Bursts | Planned in |
|---|---|---|---|---|---|
| before | 126 | 299 | 127 | 131 | 204-284 ms |
| the day's ground | 124 | 299 | 131 | 130 | 332-405 ms |
| and the day's calm rule | 76 | 254 | 143 | 62 | |

`tests/test_finale.gd` floods from the service exit past every body on nine seeds' plans and on the
player's seed, and every one reaches both exits.

**A restart reads the ground the first plan worked out.** `tests/probes/escape_replan_time.gd`, the
escape's plan on eight seeds' cities, first and on three restarts on the same city with the same rng,
its `ESCAPE_REPLAN` lines in `replan-before.txt.gz` (at `096beb3d`) and `replan-after.txt.gz` (with
`EventScheduler._finale_ground_cache()`), on the desktop; the placement counts are the same in every
attempt, and `tests/test_finale.gd` holds that a restart's plan is the first one placement for
placement:

| | First plan | Restarts |
|---|---|---|
| before | 332-405 ms, median 349 | 304-377 ms, median 321 |
| after | 333-404 ms, median 348 | 206-280 ms, median 221 |

Not measured on a phone.

Footprint: four stills, the first strip and its script, the far-guard strip, the barricade pair
and its script, two compressed overhang-probe outputs, two compressed replan-probe outputs, three compressed cost-probe outputs, the
player's run folder (`run.log` and two stills), two burst strips and their script, two
compressed spacing-probe outputs, the alley-wall pair, three compressed density-probe outputs and
this README.
