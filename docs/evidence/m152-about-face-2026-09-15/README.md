# M152 — the about-face, and the morning unpack

Runs of `tests/probes/m152_car_jumps.gd`, which walks a rig day on four cities and records, per
physics frame and per car: every move further than twice the fastest car's own frame step, every
reversal on the spot with the reason the planner gives for it, and every episode of a car swaying
across its carriageway without going anywhere — each marked by whether either end of it was inside
the play viewport (`Tuning.VIEW_HALF_EXTENT`, 320 × 180 px of world) around the crowd field's
centre, which is where the camera is.

Every file here is the whole output of

```sh
tools/test.sh probes/m152_car_jumps.gd
```

| file | tree |
|---|---|
| `probe-before.txt` | the probe as it is now, against `main`'s crowd code at `c7dfc4ed` |
| `probe-after.txt` | this branch, with the morning unpacked early and the about-face planned |
| `run-202436-seed3126506586-v0.10.7-107-gc7dfc4ed/` | the player's own desktop run on `main` at `c7dfc4ed`, copied whole; its `asked/burst-25017518-001/` is the burst [PLAYTEST-77](../../playtests/PLAYTEST-77.md) describes, a car at a sealed street sliding between the two lanes |

The two runs are comparable because the probe itself is identical in both: only
`src/crowd/crowd.gd` and `src/crowd/crowd_agent.gd` differ.

`PROBE m152 in-view jumps:`, `PROBE m152 turn-rounds:` and `PROBE m152 sway episodes:` on the last
three lines of each are the numbers the work turns on.

**A recycle is a teleport by construction and is legal out of sight**, which is why the classes are
counted separately rather than summed: the `recycle` row is hundreds of moves per run and not one of
them is a defect, because every one happens outside the viewport.

## Why a reversal happened

The `why cars reversed on the spot` table under each rig day and at the foot of the run is the
planner's own record read back — `CrowdAgent.turn_round_cause` for which of the two ways out fired,
and `turn_refusals` for what turned away each of the four places it looked, in the order it looks:
the near arm, the far arm, an about-face in the junction box, an about-face in the street. The
numbers beside them are the state the car was in on the frame before: how many tiles to the
blockage, how much room its brake had left it, how far the blockage actually was, how fast it was
going, and whether it had already taken an arc on this approach.

Read the refusals in two halves. `landing-taken` is another car standing where the arc ends and goes
away on its own; `sweep-blocked`, `too-tight`, `exit-plugged`, `past-blockage` and `out-of-sight` are
the ground, the geometry and the map, and none of those changes while a car waits.

## The cities

Three of them are the ones the teleport probe already used: day 1 is the busiest road the game has
(34 cars, act I) and day 13 the most closed (4 closures, act IV). The fourth is seed 3126506586 day
1, the seed of the burst the player took of a car shaking its head at a `burst_water_main` seal, so
that case is inside the measurement rather than beside it. The focus walks between the mouths of
every shut street, closure and hard seal alike, nearest the doorstep first.

## Stopped cars

The count the M111 record measures a change to the manoeuvre against — how much traffic is at a
standstill after ninety seconds — was re-measured with a throwaway rig on seeds 4242, 24757 and
99001, day 1, the crowd's focus pinned to the doorstep and `Crowd.step()` driving the whole frame.
A car counts as stopped when `speed()` is under `Tuning.CAR_STOPPED_SPEED` (5px/s).

| | 4242 | 24757 | 99001 |
|---|---|---|---|
| `main` at `c7dfc4ed`, stopped at 90s | 8 of 34 | 21 of 34 | 5 of 34 |
| this branch, stopped at 90s | 7 of 34 | 15 of 34 | 8 of 34 |
| `main`, mean stopped per frame | 7.67 | 15.65 | 9.69 |
| this branch, mean stopped per frame | 9.23 | 13.24 | 8.99 |

The rig is not the one M111 used and its absolute numbers are higher, because a focus that never
moves lets traffic pile up around one junction all day; both columns were taken with the same rig,
which is what makes the pair readable.
