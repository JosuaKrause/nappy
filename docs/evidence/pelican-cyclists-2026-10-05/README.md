# How many cyclists a run meets, and the runs until the first pelican

Measured 2026-10-05 for inbox #575 (filed in
[feathery-lynx](../../playtests/2026-10-05-feathery-lynx.md), queue entry
[pebbly-ibis](../../todo/2026-10-05-pebbly-ibis/README.md)): the player asked for "the expected
value of runs until you see at least one pelican do the p50, p90, p99", comparing today's flat
1/400 roll per cyclist (`EventManager.PELICAN_SHARE`) with one shared bag of 399 cyclists and 1
pelican per run.

## The claim

Over 120 cities, a run of days 2 to 14 meets **26.2 cyclists** on average (median 26, p10 22, p90
29, min 20, max 37), about 2 a day on every day (`analysis.txt` has the per-day lines). From that:

| | chance of a pelican in a run | expected runs to the first | p50 | p90 | p99 |
|---|---|---|---|---|---|
| flat 1/400 per cyclist | 6.34% | 15.8 | 11 | 36 | 70 |
| one bag of 399 + 1 per run | 6.54% | 15.3 | 11 | 35 | 69 |
| a fresh bag of 399 + 1 per day | 6.35% | 15.8 | 11 | 36 | 71 |

The p50, p90 and p99 are from 200,000 simulated players, each playing runs drawn at random from
the 120 measured cities (`sim a` and `sim b` in `analysis.txt`); the per-day bag's row is the
closed form only, which gives 71 rather than 70 for the flat roll's p99. A bag never runs empty
inside one run (at most 37 of its 400 marbles are drawn), so one bag per run gives exactly N/400
for N cyclists and never two pelicans in one run. `analysis.txt` also has a bag kept across runs,
which the player did not choose: first pelican after 8.2 runs on average, at the latest by run 20.

## Its limits

- **One steady walk.** The probe walks her up and down the arterial sidewalk at walking pace
  (`Tuning.WALK_SPEED`), never running, stopping or taking a route, stepping 0.2 s at a time.
- **Every day is full length and won.** Each day runs for `Tuning.day_length(day)`, none is lost
  or ends early, and every run reaches day 14. A run that ends earlier meets fewer cyclists.
- **Days 2 to 14 only.** Day 1 is not measured.
- **No real `EventManager`.** The probe drives `EventDirector` (the route's marble bag) alone and
  counts a cyclist when the director hands one out (`rolls`) and when its warning finds a place to
  stand down her line and a route clear of the doors (`created`); the two are equal on every day
  measured. Nothing is put into the world, so a warning in flight, the streaming and every other
  event's effect on her walk are absent.
- **The runs are independent draws** from the 120 cities in the simulation, as if each player's
  runs were different cities.

## Provenance

- **Source revision:** `cec67517ba603512811b3538b2002b8dc1745a4f`, a commit of the marble-bag pull
  request #565 (olive-badger, what she meets on her route is drawn from a marble bag).
  A fresh clone fetches it with `git fetch origin refs/pull/565/head`.
- **Command:** with the probe copied to `tests/probes/pelican_cyclists_per_run.gd`,
  `tools/test.sh probes/pelican_cyclists_per_run.gd`.
- **Settings:** 120 cities, seeds 772041 + 31 × i for i from 0 to 119, days 2 to 14; each day's
  plan and director draw from streams hashed from the seed and the day, so a rerun gives the same
  lines.

## The files

- `pelican_cyclists_per_run.gd`: the probe. It prints one line per city and day,
  `CYC <seed> <day> <rolls> <created> <all rows> <the other rows' counts>`.
- `pelican.out`: its whole output, as it was. The script errors at the top are the atlas bake's
  own boot on a worktree with no `.godot/` yet, which the bake prints an explanation for; the probe
  ran after them and reported 1 check, 0 failures.
- `an.py`: the analysis. It reads the output named as its argument (`pelican.out` in this folder by
  default). It needs numpy:
  `uv run --no-project --with numpy python an.py pelican.out`.
- `analysis.txt`: what `an.py` printed for this `pelican.out`. Its simulation has a fixed seed, so
  a rerun prints the same.

To measure again, check out the source revision in a fresh worktree, copy the probe into
`tests/probes/`, run the command into a new scratch file, and point `an.py` at that file.
