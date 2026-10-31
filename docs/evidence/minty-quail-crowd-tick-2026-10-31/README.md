# The crowd on the physics tick, drawn interpolated (minty-quail shared-components C1)

**What this folder shows**: with the crowd stepped on the 30Hz physics tick instead of once per
drawn frame, (1) it still moves on every drawn frame at a desktop's frame rate, (2) at 30 steps a
second it moves exactly as before, (3) what its work costs per tick and per second, and (4) what
its own numbers (headways, box throughput, horns, box collisions, bumps, strikes) come to before and
after. Before is `origin/main` at f784f067; after is the branch (the frames, parity and cadence runs are of its head; the cost runs, of its first commit, 86f98a06, which the later commits do not touch in the crowd's step). Machine:
the developer's Apple Silicon Mac, Godot 4.7.2, everything run one at a time.

## 1. Smooth at 120fps — `before-after-strip.png`, `before-strip.png`, `after-strip.png`

`tests/probes/minty_quail_crowd_frames.gd`, run in a window in each revision:

    CROWD_FRAMES_OUT=<dir> "$GODOT" --path . --resolution 1280x720 --disable-vsync --max-fps 120 \
        res://tests/tests.tscn -- probes/minty_quail_crowd_frames.gd

Seed 4242, day 1, the crowd centred on the doorstep, a camera at zoom 2 on the same spot, nobody
handed to the crowd as her; after 90 ticks, twelve consecutive drawn frames are read back and each
strip is the same 240x150 crop of all twelve, round where the moving car nearest the doorstep was
drawn in the first. `frames-before.txt` and `frames-after.txt` are each frame's line: the ticks run
when it was drawn, the interpolation fraction, the car node's position and how many of the crop's
36,000 pixels differ from the frame before (the crop, not the screen, so nothing else that moves
on the screen is counted).

- Before, the car's node moves on every frame (it moved in `_process()`).
- After, the car's node moves only on the frames a tick ran (every fourth at 120fps, 4.47px a time),
  and the picture still moves on all twelve: of the nine frames drawn with no tick since the one
  before, nine differ from the frame before in the crop (about 2,700 to 3,000 of its pixels each)
  and none stands still. The strips show the car advancing evenly in both.

**Limits**: the two runs follow different cars, since the engine's own loop, with its real frame
timing, ran the crowd for the warmup; the strips are a crop, not the whole screen; a window covered
by another one would have been drawn on demand (`forced_draw` says whether, and is false on every
frame here). The recording mode (`main.gd` turns interpolation off under a movie recording) is not
shown: there the crowd steps at 30Hz like her and the events.

## 2. Identical at 30 steps a second — `lane-parity-before.txt`, `lane-parity-after.txt`

`LANE_PARITY_REPS=1 tools/test.sh probes/minty_quail_lane_parity.gd` in each revision (the probe
calls an agent's own `_process()` only where the crowd does not step its agents itself, so the one
file runs on both). Its rig steps the agents and then the crowd's tick, once per 1/30s, which is the
order the crowd's own tick now runs. **All twelve runs' position chains and drawn-state chains are
identical**, seeds 478156010 and 4242, days 1, 9 and 14, both walks.

In the live game at 30fps the order moved by one step: before, a drawn frame ran the crowd's tick
(spacing, doors, give-way, strike, horn, bump) and then the agents' motion; now the tick runs the
motion first, so a strike, horn or bump is decided against where this tick's step put the car, and
an agent recycling reads the crowd's box as last tick's player half left it (a tick behind, 3px at
her walk).

## 3. Cost — `tick-cost-before.txt`, `tick-cost-after.txt`

`tools/test.sh probes/m159_crowd_tick_cost.gd`, the median over the `whole` mode's 600 timed ticks
of three repetitions of both walks and both seeds. Before, `agents` is one frame of every agent's
`_process()` and `tick` is `Crowd._physics_process()`; after, the tick holds both.

| day (agents) | before: tick / agents' frame | after: tick | per second at 60fps, before → after | at 120fps, before → after |
|---|---|---|---|---|
| 1 (234) | 297µs / 2524µs | 2798µs | 160ms → 84ms | 312ms → 84ms |
| 9 (50) | 217µs / 550µs | 767µs | 40ms → 23ms | 73ms → 23ms |
| 14 (86) | 348µs / 957µs | 1294µs | 68ms → 39ms | 125ms → 39ms |

Per second is 30 × tick + fps × agents' frame before, and 30 × tick after. The crowd's per-tick cost
grows by the agents' step; a frame drawn with a tick costs about what it did, a frame without one
costs none of the crowd. Not counted on either side: the engine's own interpolation of each
agent's transform per drawn frame, which is native and not timed by the probe. The probe's split
check (that its call-by-call tick moves every agent exactly as the real tick) holds in all 36 runs.

## 4. The crowd's numbers, and what changes for a player

**What changes for a player at 30 frames a second**: the tick runs every agent's step first and
then the traffic, the doors and her (main ran the traffic, the doors and her first and the agents'
step after). That is the only change there, and it shows as about one more box collision a minute
(2.0 to 3.1), a car about two percent slower on average (102 to 100px/s), and nothing else past
chance: horns 4.9 to 4.8, bumps 7.0 to 6.5, strikes 0.42 to 0.35 a minute. **What changes at 120
frames a second** (a desktop): box collisions 2.9 to 3.1, horns 5.0 to 4.8, bumps 7.1 to 6.5 and
strikes 0.52 to 0.35 a minute, so the machine no longer decides the numbers; only the strikes'
fall is past chance, and it is a fall.

`tools/test.sh probes/minty_quail_crowd_cadence.gd` (`CADENCE_FRAMES=1,4` on main, `1` on the
branch; `CADENCE_SEEDS` names the cities). Each run is a minute of ticks after a five-second
warmup, in the live order: on main, the crowd's tick and then 1 or 4 agent frames of a 1 or ¼ tick
(30 or 120fps); on the branch, the tick alone, which no frame rate reaches. Walks: `road`, across
the carriageway nearest the doorstep and back; `walkers`, at the nearest walker. **Twelve seeds,
days 1 and 9, both walks: 48 runs a row**, `cadence12-main.txt`, `cadence12-after.txt`. The day is chaotic:
one changed decision moves every car after it, so the spread between runs is as wide as most
differences and a few runs tell nothing.

Mean of the 48 runs, with the paired difference (the same city, crowd and walk on both sides;
`paired.py`) in the last two rows as difference ± its standard error:

| | horns | box collisions | bumps | strikes | mean car speed | box entries a minute |
|---|---|---|---|---|---|---|
| main, 30fps | 4.92 | 2.00 | 6.98 | 0.42 | 101.9 | 311 |
| main, 120fps | 5.04 | 2.85 | 7.10 | 0.52 | 100.2 | 299 |
| branch, any fps | 4.79 | 3.10 | 6.48 | 0.35 | 99.6 | 303 |
| branch minus main at 30fps | -0.12 ± 0.35 | **+1.10 ± 0.41** | -0.50 ± 0.47 | -0.06 ± 0.06 | **-2.3 ± 1.0** | -7.8 ± 4.4 |
| branch minus main at 120fps | -0.25 ± 0.35 | +0.25 ± 0.61 | -0.62 ± 0.41 | **-0.17 ± 0.07** | -0.6 ± 1.1 | +3.5 ± 5.4 |

Bold is past twice its error; a handful of measures out of twelve compared will show one by chance,
so none of the three is firm. The headway median is 356px on main at 30fps, 365px at 120fps and
348px on the branch (-8 ± 9 and -17 ± 8).

**Why 30fps changed at all although the 30Hz parity chains are identical.** The parity probe's rig
steps the agents and then the tick, the order the branch's live tick runs, so it matches the branch
and not main's live game at 30fps. Run in main's order (`CADENCE_ORDER=old`, which runs
`_advance_the_world()`, `_meet_the_player()` and then `_step_the_agents()` on the branch;
`cadence12-after-in-mains-order.txt`), the branch reproduces main's 30fps row exactly: **all 48
runs identical on every measure**. So the whole 30fps change is the order inside the tick.

**Limits**: a 120fps "main" here is emulated by stepping the agents four times a tick in a headless
rig, not measured on a real display; the probe counts horns by `car_near_miss`, bumps by
`crowd_bumped`, strikes by the `car_strike` hard fail, and a box collision as a car's startle that
no horn raised. `cadence-before.txt` and `cadence-after.txt` are an eight-run subset (two seeds), too few to tell a difference from the chance between runs: they read collisions 1.25 to 2.5 at 30fps and strikes 0.12 to 0.38, which the 48 runs do not bear out.

## 5. What is drawn at 30 steps a second on a faster screen

A car's bob over its wheels and a walker's gait are redrawn on the tick, so they step thirty times
a second on a 120fps screen while the body between them moves smoothly. A marked car's caret, the
danger cue, breathes with its horn on every drawn frame (a `_process` that is on only while a horn
is running). Redrawing every car every frame would put back the per-frame cost this change took
out of section 3.
