# The crowd on the physics tick, drawn interpolated (minty-quail shared-components C1)

**What this folder shows**: with the crowd stepped on the 30Hz physics tick instead of once per
drawn frame, (1) it still moves on every drawn frame at a desktop's frame rate, (2) at 30 steps a
second it moves exactly as before, (3) what its work costs per tick and per second, and (4) what
its own numbers (headways, box throughput, horns, box collisions, bumps, strikes) come to before and
after. Before is `origin/main` at f784f067; after is the branch's first commit, 86f98a06. Machine:
the developer's Apple Silicon Mac, Godot 4.7.2, everything run one at a time.

## 1. Smooth at 120fps — `before-after-strip.png`, `before-strip.png`, `after-strip.png`

`tests/probes/minty_quail_crowd_frames.gd`, run in a window in each revision:

    CROWD_FRAMES_OUT=<dir> "$GODOT" --path . --resolution 1280x720 --disable-vsync --max-fps 120 \
        res://tests/tests.tscn -- probes/minty_quail_crowd_frames.gd

Seed 4242, day 1, the crowd centred on the doorstep, a camera at zoom 2 on the same spot, nobody
handed to the crowd as her; after 90 ticks, twelve consecutive drawn frames are read back and each
strip is the same 240x150 crop of all twelve, round where the moving car nearest the doorstep was
drawn in the first. `frames-before.txt` and `frames-after.txt` are each frame's line: the ticks run
when it was drawn, the interpolation fraction, the car node's position and how many sampled pixels
(every second pixel each way) differ from the frame before.

- Before, the car's node moves on every frame (it moved in `_process()`).
- After, the car's node moves only on the frames a tick ran (every fourth at 120fps, 4.47px a time),
  and the picture still moves on all twelve: of the nine frames drawn with no tick since the one
  before, nine differ from the frame before and none stands still. The strips show the car
  advancing evenly in both.

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

## 4. The crowd's numbers — `cadence-before.txt`, `cadence-after.txt`

`tools/test.sh probes/minty_quail_crowd_cadence.gd` (`CADENCE_FRAMES=1,2,4` before, `1` after).
Each run is a minute of ticks after a five-second warmup, in the live order: before, the crowd's
tick and then 1, 2 or 4 agent frames of a 1, ½ or ¼ tick (30, 60 or 120fps); after, the tick alone,
which no frame rate reaches. Walks: `road`, across the carriageway nearest the doorstep and back;
`walkers`, at the nearest walker. Mean over the eight runs (two seeds, days 1 and 9, two walks):

| | headway p10 / median / min (px) | box entries a minute | mean car speed | horns | box collisions | bumps | strikes |
|---|---|---|---|---|---|---|---|
| before, 30fps | 192 / 422 / 93 | 336 | 111.0 | 5.5 | 1.25 | 6.9 | 0.12 |
| before, 60fps | 175 / 397 / 87 | 342 | 111.5 | 4.5 | 3.12 | 7.3 | 0.38 |
| before, 120fps | 177 / 421 / 67 | 336 | 109.7 | 5.8 | 3.62 | 7.1 | 0.50 |
| after, any fps | 137 / 379 / 66 | 330 | 107.1 | 3.8 | 2.50 | 6.4 | 0.38 |

**Reading it**: the day is chaotic — one changed decision moves every car after it — so each row is
eight samples, and the spread between runs of one row is as wide as the differences between rows
(`cadence-*.txt` has every run). Box throughput, mean speed and bumps sit within that spread
everywhere. Before, box collisions (a startle no horn explains: two cars meeting in a junction box)
came out about three times as often at 60 and 120fps as at 30fps, the decision cadence the queue
item named; after, the rate no longer depends on the machine. Horns, collisions and strikes are a
handful a minute, too few for a smaller difference to mean anything. Headways are snapshot gaps
between moving cars in one lane, dominated by which streets the walk's field holds.

**Limits**: a 60 or 120fps "before" here is emulated by stepping the agents several times a tick in
a headless rig, not measured on a real display; the probe counts horns by `car_near_miss`, bumps by
`crowd_bumped`, strikes by the `car_strike` hard fail, and a box collision as a car's startle that
no horn raised.
