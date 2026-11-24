# minty-quail — The suites and rigs hold the run, the trace and the atlas they hand the city (minty-quail, C6a) · 2026-11-24

C6a of the city scene's pass (`.claude/briefs/designs/minty-quail-city-scene-pass.md`): no suite or rig
reads `city.run`, `city.trace` or `city.atlas` any more; each keeps the run, the trace or the library
it hands the city, apart from the one read left for C7 ("Reads left") and the probes' own, which
are C6b's.

## What was built

- **Rigs.** `resistance_rig` and `test_park_cordon` hold members `_run` and `_library`. `test_park_return`
  boots `main`, which takes the parked sitting's library and hands the city `_sitting.atlas()`
  (`main._new_city()`), so the suite asks that sitting (`Sitting.atlas()`) for the object the city
  draws from rather than making a second one. `test_dev_rig` uses a
  `RunTrace` of its own.
- **`RunCity`.** `with_own_run()` is gone: `RunCity.started_run(seed)` only makes a run for the suite to
  keep, and `RunCity.new_city(scene)` makes the city, and `RunCity.build(city, run, map, builder, dark, library)`
  hands the run to the city (`use_run()`) and to the simulation: one place, so a suite cannot hand the
  two different runs. The 84 non-probe call sites follow, and `poster_view.walk` takes `run` too.
- **Departure from the design.** The design has each rig that hands a suite its city gain a `run()`
  of its own; the rigs hold a `_run` member and the helpers take a `run` parameter instead, because a
  `run()` method on a rig is one more public surface for a thing the suite already made and holds.
- **Queue.** The `City trace` line leaves `tools/test_only_members.txt`; the `run` and `atlas` reasons
  name C6b; the entry's README lists only C6b and C7.
- **A doc made false.** `docs/todo/2026-11-12-tiny-bunny/mode-and-deadline.md` named `with_own_run()`;
  it names `new_city()`, as do four probe header comments.

## The probes

Dropping `with_own_run()` and changing `RunCity.build` broke all 45 probes under `tests/probes/`, and their
untyped receivers made `check_test_only_members` count reads of `SpawnSiting.map()`. Their calls are
changed mechanically (`started_run`/`new_city`, `run` passed to `build`, one `walk` call); the orchestrator
ruled this not a fork. Their own `city.run` and `city.atlas` reads stay for C6b.
`tests/probes/minty_quail_crowd_frames.gd` redeclares `drawn` and fails to parse on main too.

## Reads left

Outside the probes (C6b) the one is `tests/test_atlas_boot.gd:203`, `node.get("atlas")` over every node of a
booted `main`, the city included. Once C7 makes the field private the loop skips the city silently,
while its holder count still passes on `Prop` and `PosterWalls`; C7's line in the entry's README says
the sweep then asks the city's library through its method.

## Measured

The 71 touched suites, run one at a time, report 0 failures and no script error; a static diff shows no
`t.check` added or removed. One mutation: `RunCity.build` equipping the city with a new library instead of
the one handed fails `test_posters` and `test_recipe_city_drawing` on their own checks, and
`test_city_buildings` and `test_home_block` on atlas errors; `test_blocks` crashes (a region asked for
while its group is not acquired, then `get_size` of null) rather than failing a check. `check.sh`, `lint.sh`, `check_field_reads`, `check_test_only_members` and
`check_layers` pass.
