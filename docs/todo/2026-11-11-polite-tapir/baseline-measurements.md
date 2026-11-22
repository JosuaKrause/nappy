# The numbers from before the refactor are captured while the old tree still runs

**The ask.** The refactor (minty-quail) remeasures once, at the end (inbox #813 in curly-moose), comparing "main and the
refactor's head", but the refactor merges into main as it goes. Shown the design review's finding
that "the single remeasure at the end has no stored 'before'. No baseline commit is named and no
winnability or route-cost numbers from before the refactor are saved. Capturing them now blocks
nothing", the player: "sure" (inbox #1268 in olive-ferret).

**Read as:** the before-numbers are measured on the tree from before the refactor and kept in the
repository, so the end remeasure has something to compare with. *The specifics are the
orchestrator's, proposed and open to the player's correction.*

**What is left** (four readings are built in `docs/evidence/minty-quail-baseline-2026-11-09/`: `v0.29.0`
beside a mid-refactor `main`, record mossy-raven, a third column with placement closed, record
polite-tapir-velvet-heron, and a fourth after the events' field-read conversion, record polite-tapir-crisp-heron):

- **What moved after the events' field-read conversion, listed for the end remeasure** (the fourth
  column against the third, the record polite-tapir-crisp-heron): dawn planning inside `build_day()` 51.6 s to 44.1 s,
  inside `draw_every_unit()` 345.6 to 334.3, the whole probe 568.6 to 505.2; the crowd tick's mean
  whole-mode median about 2,466 µs to 2,351 µs; the frame profile's callback interval with
  `--invincible` 4.9 ms to 4.0 profiled and 7.5 to 6.3 with the profiler off; `test_acts` 349
  checks to 45 (its sweep holds scripted rows only) and `test_finale` 9,464 to 9,463; the
  unmodified frame-profile launcher's six runs all rejected by the analyzer (an 8.3 ms callback
  interval), not looked into.
- **The escape's mix and walks, listed for the end remeasure** (step 5's switch, the record
  polite-tapir-coral-badger; `tests/probes/escape_winnable.gd`, 24 seeds): main before the switch planned 0.66
  dangers a street and 34% of streets with none (trucks 167, explosions 193, vans 91, roadblocks 44),
  and walked out to the tunnel on 13 walks and to the bridge on 10; after it, 0.66 and 34% (181,
  178, 89, 46), 12 and 10.
- **Streaming's loop over every plan, listed for the end remeasure**: `EventStreaming.stream_around()`,
  which row 3b's design asked to be measured and which was not (the record minty-quail-gray-koala).
- **Nothing is judged here.** A number that moved is listed for the end remeasure; no step waits on
  a reading.
