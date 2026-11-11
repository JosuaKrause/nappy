# minty-quail — The city map's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret). This is the city map's pass of `typed-everywhere.md`'s "What is untyped in a test
goes as its suite is converted", after the city map and its generator were typed
(minty-quail-rosy-pelican) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_generator`, `test_blocks`, `test_city_map` and `test_world_passability` are typed**, and
  each loses its opt-out line. No line under `src/` changed.
- **`test_blocks` reads each node of `City.props()` as a `Prop`**, since the method answers
  `Array[Node2D]`; an `Array[Prop]` answer would make the cast unneeded, which is the city scene's
  pass to decide.
- **`test_city_map`'s `_plain` copies each packed array through its own typed name**
  (`(value as PackedByteArray).duplicate()` and the other packed types). Godot shares a packed array
  by reference, so without the copy the check that a map's copy shares nothing with the original
  could not fail: with `CityMap.copy()` sharing its `tiles`, `tools/test.sh city_map` fails seven
  checks, and none with the copy.
- **Every read of a field that a method the game calls answers goes through that method**: the
  map's `plans_by_block()`, `city_seed()`, `street_network()`, `size_in_tiles()`, `calm_blocks_now()`,
  `home_tile_rect()`, `walk_tiles()`, `has_recipe_dawn_ground()` and the others; a block layout's
  `open_ground()`, `square_rect()` and `alley_rect()`; a block plan's `step_count()`, `step_at()` and
  `steps_in_order()`; a mover's `layers_blocked()`. No method was added for a test.

## Reads left, each with its reason

`tools/check_field_reads.py` reads only `src/`, so it does not list these; they were found by
searching the suites for every field read and `src/` for a method the game calls.

- **`CityMap.dead_ends`, `absent_segments` and `zone_anchor`** (`test_generator`, `test_blocks`),
  **`map.blocked`** (`test_world_passability`), **`Prop.kind` and `Prop.shape`** (`test_blocks`):
  no method the game calls answers them.
- **`fenced_park_act`, `stretch_active` and `recipe_dawn_tiles` compared whole between the map and
  its twin** (`test_city_map`): its member comparison reads every member by name on purpose, as its
  header says.
- **`City`'s fields**, `scenery` and `atlas` in `test_blocks` and the ones `test_world_passability`
  reads, belong to the city scene's pass.

`test_generator`'s CI time rose from about 80 s to about 106 s with the change. No method the
suite now calls in a loop copies what it answers, and back-to-back local runs on a loaded machine
did not reproduce the rise.

## Verified

The four suites and `test_city_map_cache` pass, `tools/typing_census.py --check` holds, and no
game file changed, so the identity probes do not apply. No check was deleted or moved.
