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
- **Every read of a field of the city map's own classes (the map, a block layout, a block plan, a
  mover) that a method the game calls answers goes through that method**: the map's
  `plans_by_block()`, `city_seed()`, `street_network()`, `size_in_tiles()`, `calm_blocks_now()`,
  `home_tile_rect()`, `walk_tiles()`, `has_recipe_dawn_ground()` and the others; a block layout's
  `open_ground()`, `square_rect()` and `alley_rect()`; a block plan's `step_count()`, `step_at()` and
  `steps_in_order()`; a mover's `layers_blocked()`. No method was added for a test.

## Reads left, each with its reason

`tools/check_field_reads.py` reads only `src/`, so it does not list these. The search covered the
city map's own classes; other modules' fields were listed, not converted.

- **`CityMap.dead_ends`, `absent_segments` and `zone_anchor`** (`test_generator`, `test_blocks`),
  **`map.blocked`** (`test_world_passability`), **`fenced_park_act`, `stretch_active` and
  `recipe_dawn_tiles` compared whole between the map and its twin** (`test_city_map`), and
  **`Prop.kind` and `Prop.shape`** (`test_blocks`): no method the game calls answers them.
- **Other modules' fields stay for their passes**, listed whole under "Fields read and written, by
  class" below. In `test_world_passability`, the events' `is_finished`, `is_leaving`, `excitement`,
  `telegraph_time`, `outer_radius` and `mobile` and a plan's `def`, `position` and `path` have the
  game's `is_gone()`, `is_on_its_way_out()`, `source()`, `telegraphs_for()`, `heard_within()`,
  `moves()`, `row()`, `placed_at()` and `walks()`; `departure`, `barrier_post`, `skip_draw`, a plan's
  `facing` and `RunState.attempt_spend` have no plain getter.
  `City`'s fields there and in `test_blocks` (`scenery`, `atlas`) are the city scene's;
  `CityDecals`' `atlas` and `drawer` (`test_blocks`) are the decals'; a recipe's `data` and the
  built city's `map` (`test_city_map`) are the scene recipes'.

`test_generator`'s CI time rose from about 80 s to about 106 s with the change. No method the
suite now calls in a loop copies what it answers, and back-to-back local runs on a loaded machine
did not reproduce the rise.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `87dc6690c`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `city_state`, written → no method.
- **`BlockPlan.Step`**: `cause` → no method; `from_day` → no method; `purpose` → no method.
- **`City`**: `atlas` → no method; `events` → no method; `map` → no method; `navigator` → no method;
  `scenery` → no method.
- **`CityDecals`**: `atlas`, written → `use_atlas()` does `atlas = library`; `drawer` → no method;
  `drawer`, written → `draw_through()` does `drawer = through`.
- **`CityMap`**: `absent_segments` → no method; `dead_ends` → no method; `fenced_park_act` → no
  method; `recipe_dawn_tiles` → no method; `stretch_active` → no method; `zone_anchor` → no method.
- **`EventDef`**: `detain_seconds` → `detains_for()`; `flock_size` → no method; `id` → no method;
  `mobile` → `moves()`; `outer_radius` → `heard_within()`; `path_mode`, written → no method;
  `placement` → no method; `pursuit` → no method; `solid_when` → `solid_from()`; `speed` → no
  method; `telegraph_time` → `telegraphs_for()`; `vehicle` → no method.
- **`EventInstance`**: `barrier_post` → no method; `departure` → no method; `excitement` →
  `source()`; `is_finished` → `is_gone()`; `is_leaving` → `is_on_its_way_out()`; `skip_draw`,
  written → no method.
- **`EventManager`**: `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.obstructs_radius` → `obstructs_within()`;
  `facing` → no method; `path` → `walks()`; `position` → `placed_at()`.
- **`Navigator.Walked`**: `at` → no method; `stopped` → no method.
- **`Prop`**: `kind` → no method; `shape` → no method.
- **`RunState`**: `attempt_spend` → no method.
- **`StreetNetwork.Segment`**: `horizontal` → no method.
- **`StreetTrees.Planted`**: `position` → no method; `segment_key` → no method; `tile` → no method.
- **`StreetTrees.Run`**: `horizontal` → no method; `length` → no method.
- **`WorldMap`**: `blocked` through `CityMap` → no method.

## Verified

The four suites and `test_city_map_cache` pass, `tools/typing_census.py --check` holds, and no
game file changed, so the identity probes do not apply. No check was deleted or moved.
