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
- **Other modules' fields stay for their passes**, with the game's method where one exists: the
  plan's `def` (`row()`), `def.id` (`row_id()`), `position` (`placed_at()`) and `path` (`walks()`),
  its `role` read (none) and written (`give_role()`);
  the row's `hard_fail` (`ends_the_day()`), `outer_radius` (`heard_within()`), `max_per_day`
  (`most_in_a_day()`), `mobile` (`moves()`), `obstructs_radius` (`obstructs_within()`) and
  `telegraph_time` (`telegraphs_for()`), `aftermath.on_finish` (`leaves_behind()`), `kind` where
  compared with the ambient kind (`is_ambient()`), and its `id`, `kind`, `placement`, `path_mode`,
  `pursuit`, `aftermath.on_sight`, `speed`, `role`, `paces`, `pavement_side`, `first_day` and `on_her_way` (read, and `on_her_way` written
  and restored; no single method answers each); the live event's `is_finished` (`is_gone()`),
  `is_leaving` (`is_on_its_way_out()`), `excitement` (`source()`) and `path` (`walks()`); a pending warning's `shown`, a
  day spec's `wall_row_share` (written) and a segment's `a` and `horizontal` (none); the map's
  `network` (`street_network()`), `home_rect` (`home_tile_rect()`), `calm_blocks`
  (`calm_blocks_now()`), `alley_rects` (`alley_lots()`), `block_plans` (`plans_by_block()`),
  `closed_tiles` (`closed_tile_set()`) and `size` (`size_in_tiles()`).

## Verified

The three suites pass, `tools/typing_census.py --check` holds on them, and the field-read check
passes. No check was deleted or moved.
