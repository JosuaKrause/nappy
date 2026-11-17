# polite-tapir — The suites ask a fixture for the events and the crowd of the city they built · 2026-11-16

**The ask.** The escape is a normal day with some special settings, with no separate code (inbox #785 in minty-lemur); the
player approved the design review's plan of one start for every kind of day, its world built per spec by a builder handed
in (inbox #1268 in olive-ferret). The builder (`polite-tapir-snowy-toad`) takes the event manager, the crowd, the spawn siting
and the poster walls out of the city scene's fields, and 130 test files read those fields. This is the pull request #1485,
the design's pull request 1 and the only one it puts before the builder (#1486, its pull request 2; #1484 is its pull request 3, merged earlier than this one): **tests only, nothing under `src/` changes**, so the
pull request that moves the parts changes the fixture and no suite. `snowy-toad` names it in a line and holds none of this.

## What was built

- **`tests/fixtures/run_city.gd` (`RunCity`)** gains `build(city, map)`, `events(city)`, `crowd(city)`, `spawn_siting(city)`
  and `poster_walls(city)`, each reading the city as it did then (`city.build(map)`, `city.events`, `city.crowd`,
  `city.spawn_siting`, `city.poster_walls()`).
- **A codemod** (`convert_city_parts.py`, in the pull request's description, run with `python3 -I`) rewrote 130 suite, rig and
  probe files under `tests/`: 871 `events`, 395 `crowd`, 59 `spawn_siting`, 7 `poster_walls()` and 145 `build(` call sites, the
  counts of the design's dry run. It rewrites a receiver it can tell is a `City` (a name ending in `city`, with any dotted
  prefix, or one named per file in its `RECEIVERS` table), prints the 93 lines it leaves for a person (other classes' `build`,
  `DayDirector.events`, a fake day's `events` and `crowd`, a rig dictionary's `crowd`, input probes' `events`), and a rerun is a
  no-op. A branch that adds such reads merges main and reruns it.
- By hand: three comments the codemod turned into `RunCity.build(_city, )` were put back to `City.build()`; three comments that
  described `src/` and not a suite were reworded to name classes.
- `standing-layer-breaks.md`: the "undecided until then" list ends at how the developer settings reach the parts, and a sentence
  says the suites ask `RunCity`.
- `tools/test_only_members.txt`: the `[kept]` line for `src/crowd/car_turn.gd centre` is deleted; it excused a misread in
  `tests/test_day13_guard.gd`, a `for` over a list the check could not type, which the conversion types.

## Measured

The full local suite (four shards) ran 1,565,043 checks with 0 failures; `check.sh`, `lint.sh`, `check_layers.py` (unchanged,
45 listed exceptions and 86 uses), `check_test_only_members.py` and `check_field_reads.py` were clean. The three fingerprint
probes (`director_placement_fingerprint`, `excitement_fingerprint`, `trap_arrival_fingerprint`) were run on `origin/main` and on
the head and their whole output diffed: only timing lines differ.

## Rejected, with the reason

- **`RunCity.simulation(city)`**: it returns the `WorldSimulation` node, which does not exist before the `src/` pull request, and
  no suite reads it before then; that pull request adds it.
- **Each suite reaching into `City`, 130 files wide**: the fixture is the one place a later change touches.
