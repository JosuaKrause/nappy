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
- **Every read of a `CityMap` field that a method the game calls answers goes through that
  method**: `plans_by_block()`, `city_seed()`, `street_network()`, `size()`, `calm_blocks_now()`,
  `home_tile_rect()` and the others. No method was added for a test.

## Reads left, each with its reason

`tools/check_field_reads.py` reads only `src/`, so it does not list these; they were found by
reading the suites.

- **`CityMap.dead_ends`, `absent_segments`, `zone_anchor`, `tiles`, `fenced_park_act`,
  `stretch_active` and `recipe_dawn_tiles`** have no method the game calls. `test_city_map`'s
  member comparison reads every member by name on purpose, as its header says, and compares `tiles`
  whole between two generations.
- **`BlockLayout.open_rect`, `square` and `alley`, `BlockPlan.steps`, `Prop.kind` and
  `Prop.shape`** have no method.
- **`City`'s fields in `test_world_passability`** belong to the city scene's pass.

## Verified

The four suites and `test_city_map_cache` pass, `tools/typing_census.py --check` holds, and no
game file changed, so the identity probes do not apply. No check was deleted or moved.
