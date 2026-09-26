## M181 — The late days are timed · measured 2026-09-24

*([PLAYTEST-122](../playtests/PLAYTEST-122.md): time the late days before anything is cut. This
measures; it cuts and retunes nothing.)*

**The table**, `--route mark,task,calm,home --invincible`, days 6 to 14 on seeds 4242, 90210 and
1234567, each leg's end in the rig's own day time, and the seconds left at home against today's
144 s curfew day and the 180 s one M192 makes it:

```
day  seed       mark      task     calm  settled    home  left144  left180
  6  4242        4.9s    10.0s    18.5s    25.4s   39.3s  104.7s  140.7s
  6  90210      15.2s    21.3s    29.1s    34.7s   58.3s   85.7s  121.7s
  6  1234567     7.3s    35.5s    43.6s    55.0s   88.2s   55.8s   91.8s
  7  4242        4.9s    54.2s    57.5s    62.8s   96.9s   47.1s   83.1s
  7  90210      16.4s    37.8s    55.7s    60.8s   86.8s   57.2s   93.2s
  7  1234567    14.0s    33.4s    45.9s    51.3s   71.9s   72.1s  108.1s
  8  4242        4.9s    42.5s    44.6s    49.6s   84.7s   59.3s   95.3s
  8  90210      20.0s    60.2s    63.8s    68.9s  109.5s   34.5s   70.5s
  8  1234567     9.5s    31.5s    35.3s    40.9s   63.7s   80.3s  116.3s
  9  4242        6.1s    11.4s    26.2s    32.0s   46.6s   97.4s  133.4s
  9  90210      27.7s    91.6s    99.7s   105.2s  172.8s  -28.8s    7.2s  (home uncapped)
  9  1234567    10.4s    30.5s    37.1s    43.5s   69.4s   74.6s  110.6s
 10  4242        4.9s    52.7s    66.6s    72.2s   86.8s   57.2s   93.2s
 10  90210      13.1s    37.2s    53.1s    59.4s   88.1s   55.9s   91.9s
 10  1234567    stuck  unavail.   45.9s    51.3s   67.1s   76.9s  112.9s  (mark: crowd)
 11  4242        6.1s    38.8s    46.2s    50.4s   70.4s   73.6s  109.6s
 11  90210      17.5s    18.8s    39.6s    44.9s   73.2s   70.8s  106.8s
 11  1234567    31.6s    stuck    74.7s    76.0s   94.4s   49.6s   85.6s  (mast: scaffolding)
 12  4242        4.9s    49.9s    50.0s    53.8s   97.8s   46.2s   82.2s
 12  90210      stuck  unavail.      -        -       -       -       -   (door holds 3 times)
 12  1234567    34.5s    75.4s    75.4s  never       -       -       -   (calm never settles)
 13  4242        4.9s    22.5s    34.9s    41.2s   59.2s   84.8s  120.8s
 13  90210      10.4s    40.0s    55.4s    60.5s   88.8s   55.2s   91.2s
 13  1234567    25.3s    36.6s    48.8s    54.1s   77.1s   66.9s  102.9s
 14  4242       unavail. unavail.  18.1s    30.0s   44.0s  100.0s  136.0s
 14  90210      unavail. unavail.  32.7s    38.1s   66.5s   77.5s  113.5s
 14  1234567    unavail. unavail.  21.8s    28.3s   46.4s   97.6s  133.6s
```

Day 14's mark and task read unavailable on a bare `--day 14` run, correctly: the station door
needs `GameState.sabotage_available()`, five earlier tasks no single-day run carries. **24 of 27
fit 144 s; at 180 s the tightest is day 8 on 90210 with 70.5 s left, bar day 9 on 90210.**

**Day 9 on 90210** does not fit 144 s whichever calm area she takes: the task is 3537px off
through four doors, about 64 s of walking. Measured with the calm leg both ways (`--day-length
220`, uncapped): the nearest calm area to her (306px) gets her home at 172.8 s, 7.2 s inside a
180 s day; the new `calm:home` target, which scores a calm area by her walk to it plus its walk
home, takes one 782px off and gets her home at 150.7 s, 6.7 s short of 144 s and 29.3 s inside
180 s. The task is not moved; `calm` stays the rig's default and `calm:home` is an option.

**When the happenings arrived.** Day 10's raid fires as she passes 420px from her door, mid-mark
or mid-task, never after the task. Day 11's market goes while she walks to the task on two seeds
and, through its 90 s fallback, mid-calm on 90210. Day 12's park is taken the instant the swing is
reached. Day 13's column arrives mid-task on 90210 and on the way home on 1234567, and never on
4242, won at 59.2 s without coming within 480px of the main road.

**The rig, fixed on the way.** `RouteRig._blocked_for_phase()` never asked
`CityMap.is_soft_sealed()`, the rule the crowd's own walkers keep, so a plan could send her down a
sidewalk lane a `skip`, `scaffolding` or `moving_van` had shut for the day; it is blocked in every
tier. The "task unavailable" and day 11 mark stalls reported when slice two was built were already
gone with M184's chokepoint work, confirmed by re-running. A route-rig test per bare-point task
shape (neighbor, mast, door, the park's swing, the station door) and one for `calm:home`.

**A probe hazard.** Run beside other agents' Godot processes on the same seeds,
`m184_route_timing.gd`'s `_find_log()` (newest telemetry folder for the seed within 2 s) picked
up other processes' logs and left 7 of 27 rows blank; the table above comes from a pass reading
each run's own announced log path. The probe is unchanged and right for a machine running it
alone.
