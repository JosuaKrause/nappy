# minty-quail — The dawn's placement suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The dawn's three placement suites are typed and lose their opt-out line**:
  `test_events_scheduler`, `test_events_placement` and `test_route_rules`. Loop variables over
  literals are typed, a signature and a loop over plans are typed `EventScheduler.Planned` (the
  placement track's scripted rename to `EventPlan` reruns over them), and a dictionary of walks per
  place is read through typed locals whose keys are segment keys (`Vector3i`) and whose values are
  `StreetNetwork.Segment`. No line under `src/` changed and no rig was edited.

## Left, each with its reason

- **Search: none.** The row's, the live event's and the plan's fields are `event-interface.md` row
  4a's scripted rewrite, so this pass converts no read.
- **Other modules' fields stay for their passes**, listed by class, each with the game's method or
  "no method", under "Fields read and written, by class" below.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `e30bd1666`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`Aftermath`**: `on_sight` → no method.
- **`CityMap`**: `alley_rects` → `alley_lots()`; `block_plans` → `plans_by_block()`; `calm_blocks` →
  `calm_blocks_now()`; `closed_tiles` → `closed_tile_set()`; `home_rect` → `home_tile_rect()`;
  `network` → `street_network()`.
- **`DaySpec`**: `wall_row_share`, written → no method.
- **`EventDef`**: `aftermath` → no method; `aftermath.on_finish` → `leaves_behind()`; `first_day` →
  no method; `hard_fail` → `ends_the_day()`; `id` → no method; `kind` → no method; `max_per_day` →
  `most_in_a_day()`; `mobile` → `moves()`; `obstructs_radius` → `obstructs_within()`; `on_her_way` →
  no method; `on_her_way`, written → no method; `outer_radius` → `heard_within()`; `paces` → no
  method; `path_mode` → no method; `pavement_side` → no method; `placement` → no method; `pursuit` →
  no method; `role` → no method; `speed` → no method; `telegraph_time` → `telegraphs_for()`.
- **`EventInstance`**: `excitement` → `source()`; `is_finished` → `is_gone()`; `is_leaving` →
  `is_on_its_way_out()`; `path` → `walks()`.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.hard_fail` → `ends_the_day()`; `def.id` →
  `row_id()`; `path` → `walks()`; `position` → `placed_at()`; `role` → no method; `role`, written →
  `give_role()` does `role = given`.
- **`PendingWarning`**: `shown` → no method.
- **`StreetNetwork.Segment`**: `a` → no method; `horizontal` → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.

## Verified

The three suites pass, `tools/typing_census.py --check` holds on them, and the field-read check
passes. No check was deleted or moved.
