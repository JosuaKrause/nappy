# minty-quail — The suites and rigs hold the run, the trace and the atlas they hand the city (minty-quail, C6a) · 2026-11-24

C6a of the city scene's pass (`.claude/briefs/designs/minty-quail-city-scene-pass.md`): no suite or rig
reads `city.run`, `city.trace` or `city.atlas` any more; each keeps the run, the trace or the library
it hands the city.

## What was built

- **Rigs.** `resistance_rig` and `test_park_cordon` hold members `_run` and `_library`. `test_park_return`
  boots `main`, so it takes the library from the parked sitting (`Sitting.atlas()`). `test_dev_rig` uses a
  `RunTrace` of its own.
- **`RunCity`.** `with_own_run()` is gone: `RunCity.started_run(seed)` only makes a run for the suite to
  keep, and `RunCity.in_run(scene, run)` builds the city in it. `RunCity.build(city, run, map, builder, dark,
  library)` takes the run because it used to read `city.run`; the 84 non-probe call sites follow, and
  `poster_view.walk` takes `run` too.
- **Queue.** The `City trace` line leaves `tools/test_only_members.txt`; the `run` and `atlas` reasons
  name C6b; the entry's README lists only C6b and C7.
- **A doc made false.** `docs/todo/2026-11-12-tiny-bunny/mode-and-deadline.md` named `with_own_run()`;
  it names `in_run()`, as do four probe header comments.

## The probes

Dropping `with_own_run()` and changing `RunCity.build` broke all 45 probes under `tests/probes/`, and their
untyped receivers made `check_test_only_members` count reads of `SpawnSiting.map()`. Their calls are
changed mechanically (`started_run`/`in_run`, `run` passed to `build`, one `walk` call); the orchestrator
ruled this not a fork. Their own `city.run` and `city.atlas` reads stay for C6b.
`tests/probes/minty_quail_crowd_frames.gd` redeclares `drawn` and fails to parse on main too.

## Reads left

Outside the probes (C6b) the one is `tests/test_atlas_boot.gd:203`, `node.get("atlas")` over every node of a
booted `main`, the city included: C7, which makes the field private, lists it.

## Measured

The 71 touched suites, run one at a time, report 0 failures and no script error; a static diff shows no
`t.check` added or removed. One mutation: `RunCity.build` equipping the city with a new library instead of
the one handed makes `test_blocks`, `test_city_buildings` and `test_home_block` fail (a region asked for
while its group is not acquired). `check.sh`, `lint.sh`, `check_field_reads`, `check_test_only_members` and
`check_layers` pass.
