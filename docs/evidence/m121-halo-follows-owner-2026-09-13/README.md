# M121 — the halo follows its owner, and a turning car's picture and lane

Three windowed `tools/shot.sh` runs were taken, all on the playtest's own seed `3265820891`, day 1,
all `--invincible` and all recording `--press snapshot_burst` sequences rather than stills, since
every subject here is motion. One of the three produced usable evidence and is kept whole below;
what the other two failed to catch is recorded at the bottom, because a missing capture is a
missing check rather than a passing one.

## `arterial-walk/` — the rim tracks a moving body, and a car's picture sits on its own box

```
tools/shot.sh /tmp/m121-arterial.png 24 --seed 3265820891 --spawn arterial --walk 5e5w5e5w \
    --layers 2,3 --invincible --press snapshot_burst 3 --press snapshot_burst 9 \
    --press snapshot_burst 15 --press snapshot_burst 20
```

The whole player run folder for the first of its four bursts is kept — `run.log`,
`maps/day01-attempt1.png` and `asked/burst-5916162-001/` with its thirty-six numbered frames and
`burst.json` timing record. The other three bursts of the same run are not kept: they are the same
street a few seconds later and show nothing the first does not. `screenshot.png` is the run's own
final still at 24s, which is the file `shot.sh` was asked for rather than part of the sequence.

`--spawn arterial` stands her on the busiest pavement in the city and `--walk 5e5w5e5w` keeps her
moving beside the carriageway for twenty seconds; `--layers 2,3` draws the debug view's shadow
capsules (cyan) and bounding boxes (red, a car's own strike box), which are what the picture's
registration is judged against.

**What it shows.**

- **A rim that tracks its owner, frame by frame.** In frames 8 through 22 two walkers pass her on
  the pavement — a tan coat and a purple coat — each carrying the pale rim of its own silhouette,
  and the rim is tight on the body in every frame rather than left behind where the body was when
  the glow settled. That is the reported defect's own shape for a walking body: the glow itself is
  steady the whole way (`incoming 0.00 /s` in the readout — `--invincible` freezes the meter, so
  every rim draws at `ExcitementHalo.MIN_MAGNITUDE`, pale and faint, which is why they are subtle
  here and not why they are there).
- **A car's picture, its strike box and its shadow capsule agreeing.** The three cars in the
  northbound lane each sit inside a red box whose southern edge is on the car's own tail lights and
  a cyan capsule under the same body. This is the cardinal vertical case of the one registration
  rule `CrowdAgent._car_body_anchor()` now applies to all five views.
- **The car's own rim** hugging its silhouette inside that box, for the same reason the walkers'
  do.

**What it does not show.** No car turns in it, so the diagonal views and the continuity across a
sector boundary are not in these frames; and no side-view car with a live strike box appears, so
the 14px correction to the east/west registration cannot be read off it either. Both are held
analytically instead, by `tests/test_car_views.gd` —
`_test_every_sector_picture_agrees_with_the_strike_box` over all eight sectors and
`_test_the_registration_is_continuous_across_a_sector_boundary` a hundredth of a degree either side
of all eight boundaries. The picture to compare against, for anybody who wants the side view by
eye, is `docs/evidence/m108-crowd-cars-2026-09-11/signal-junction.png`: the side-view car at its
right-hand edge has the box's *top* edge running through its wheels, which is exactly the
disagreement this milestone removed.

## The two runs that caught nothing, and why

- **A car turning with its halo up.** `--spawn closure:0 --layers 2,3 --press snapshot_burst 5`
  over twelve seconds, which is the target
  `docs/evidence/m108-crowd-car-turn-burst-2026-09-11/README.md` recommends for catching a turn —
  every car that would have used the closed street has to turn at that junction. On this seed day
  1's only closure is `roadworks h(1,9)` and the spawn stands her on the crossing at its mouth
  (tile 18,129); no car turned inside the three-second window, and no car came near enough to earn
  a rim. Not kept.
- **A flock over her with its halo up.** `--spawn event:pigeon_flock` cannot work and says so:
  `pigeon_flock` is an `AHEAD_OF_PLAYER` row, so it is never in the day's plan for
  `DevRig.first_event_position()` to find (`WARNING: no non-ambient events planned today` in that
  run's log), and the spawn fell back to the doorstep. The `arterial-walk` run above was the
  replacement attempt — a walking player is what the director owes an ahead-of-player row to — and
  none arrived in any of its four bursts. Not kept. `tests/test_halo.gd`'s
  `_test_a_flocks_rim_has_a_new_body_to_trace_every_frame` holds the property instead: all eleven
  birds are somewhere new one frame on while the rim over them is settled and lit.
- **A car about-facing into a queued lane** was not caught at all. It needs a blockage, a
  populated opposite lane and a three-second window landing on the manoeuvre, and the capture
  budget ran out on the two above. `tests/test_turns.gd`'s
  `_test_a_turn_merges_into_a_lane_without_resetting_it` builds it deterministically instead, and
  fails loudly with the change reverted: a car already in the lane is thrown 62px backwards in a
  single frame and the queue loses its order.
