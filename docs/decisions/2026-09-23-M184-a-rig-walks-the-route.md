## M184 — A rig walks the route · built 2026-09-23

*([PLAYTEST-122](../playtests/PLAYTEST-122.md).)* One Sonnet agent on `feature/rig-walks-the-route`
built the flag and the probe and died to a usage limit after its first sweep; a replacement agent
in the same worktree found why that sweep measured nothing and fixed it. Reviewed by the
orchestrator. What stays open — the legs it gives up — is in `TODO.md`.

**What was built.** `--route <target,…>` (`src/dev/route_rig.gd`, its own `DEV_FLAG_TABLE` entry)
walks her along a planned path's edges at `Tuning.WALK_SPEED` through the ordinary input path, to
`mark`, `task`, `calm` (where she walks a short lap until the baby is asleep — standing still
drains sleepiness, so waiting can never settle her), `home` and `spawn:<name>`, re-planning when
the way closes, and logs a telemetry line per target, per re-plan and at the day's end. It is a dev
flag only (`DECISIONS.md`, M82: a pathfinding walk handed to the player hands the route decision to
the game). `tests/probes/m184_route_timing.gd` runs it over days and seeds and prints the table.

**Why the first sweep measured nothing.** She was lost within six seconds on most days because the
rig walked straight at a mark's guard: every mark has an `alley_robbery` within its pursuit range,
and the plan knew nothing of a lethal radius. Fixing that exposed four more, each hiding behind the
last: plans ignored `CityMap.obstructed_tiles`, so a parked van re-triggered the same plan forever;
a wedge could be re-entered without bound; standing still on calm ground never settles the baby;
and `DayController` wins the day on the home tile a few pixels before the rig's own arrival check,
which hung the rig. Also: `--invincible` stands the day clock still, so the rig counts its own
elapsed time. **Mobile hazards are not avoided** — chasing a moving hazard's last position made the
rig re-plan every half second — so a run with the meter live dies to the mark's guard giving chase
(day 6, seed 4242: the mark at 5.3s, lost at 7.2s). The clock question is therefore measured with
`--invincible`: whether a route fits the day is a different question from whether a day is
survivable, and the second is the player's.

**Measured**, `--route mark,task,calm,home --invincible`, 24 runs, about 29 minutes of wall time.
"Stuck fast" is a leg the rig gave up after three stuck episodes; "unreachable" is no plan found;
"unavailable" is a day with no such target yet (days 10 and 11 wait on M181 slice two).

```
day  seed       mark    task    calm  settled    home  left
 6  4242        5.3s   10.8s   17.9s   24.0s   38.0s  106s
 6  90210      37.6s   45.2s   54.5s   54.5s   80.5s   64s
 6  1234567   stuck    unavail stuck      -    stuck     -
 7  4242        5.3s   47.4s   52.4s   57.8s   91.9s   52s
 7  90210     stuck    unreach stuck      -    73.2s   71s
 7  1234567   unreach  unavail  17.9s   24.0s   39.5s  104s
 8  4242        5.3s   stuck    59.1s   64.0s   81.1s   63s
 8  90210      42.1s   unreach stuck      -   102.5s   42s
 8  1234567    21.1s   unavail  29.6s   36.5s  stuck     -
 9  4242      unreach  unavail  15.8s   27.8s   41.8s  102s
 9  90210      25.9s   unavail  31.7s   43.1s   67.3s   77s
 9  1234567    41.1s   stuck    97.9s   97.9s  122.2s   22s
10  4242      unavail  unavail  17.7s   24.1s   37.9s  106s
10  90210     unavail  unavail  30.5s   36.3s   62.0s   82s
10  1234567   unavail  unavail  19.5s   25.3s   41.1s  103s
11  4242      unavail  unavail  stuck      -    25.2s  119s
11  90210     unavail  unavail  34.0s   40.1s   66.9s   77s
11  1234567   unavail  unavail  25.6s   31.7s   47.2s   97s
12  4242        5.3s   48.0s   48.1s   52.4s  stuck     -
12  90210     stuck    unavail  53.7s   58.7s   89.6s   54s
12  1234567    48.7s   stuck   114.1s  118.4s  stuck     -
13  4242        5.3s   unreach  17.1s   29.4s   43.4s  101s
13  90210     stuck    unavail stuck      -    47.1s   97s
13  1234567   stuck    unavail  39.4s   45.0s   60.6s   83s
```

**Open to overturn, chosen where the design was silent.** No `run` modifier on a target (the
brief allowed one if cheap; left out). No reactive flight from a pursuer under `--route` — `--flee`
exists for that and is not combined with it. Stationary hazards are kept off by their lethal reach
plus her body radius. The calm lap is ±10px along the world's x axis.
