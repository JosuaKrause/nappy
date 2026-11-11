# minty-quail — The events' row suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The events' six row suites are typed and lose their opt-out line**: `test_events_catalogue`,
  `test_events_costs`, `test_events_emission`, `test_events_solid`, `test_acts` and `test_shapes`.
  Only untyped loop variables tripped the warnings; each now carries its element's type (among them
  the enum `EventDef.Look`, and `EventScheduler.Planned` under its present name, over which the
  placement track's rename to `EventPlan` reruns). No line under `src/` changed and no rig was
  edited.

## Left, each with its reason

- **Search: none.** The row's, the live event's and the plan's fields are `event-interface.md` row
  4a's scripted rewrite, so this pass converts no read.
- **Other modules' fields stay for their passes.** The pull request's description lists them by
  class, inner classes included. Those a method returns as read: the row's `pulses_every`,
  `telegraph_time` (`telegraphs_for()`), `casts_a_shadow`, `obstructs_radius` (`obstructs_within()`),
  `inner_radius` (`core_within()`), `intensity` (`peak()`), `look` (`picture()`), `shape`
  (`ground_shape()`), `detain_seconds` (`detains_for()`), `max_per_day` (`most_in_a_day()`),
  `mobile` (`moves()`), the barrier count (`counts_as_one_barrier()`) and `hard_fail`
  (`ends_the_day()`); the live event's `is_finished` (`is_gone()`), `is_leaving`
  (`is_on_its_way_out()`), `def` (`row()`) and `excitement` (`source()`); the plan's `def` (`row()`)
  and `position` (`placed_at()`); the map's home, block, network, seed and block plans (each through
  its method), a building's `lot` (`lot_rect()`), a ground shape's half extents and half length, and
  the world map's `size` (`size_in_tiles()`). Answered only in part, by a method that derives
  something else: the row's spawn mode and first day (`spawn_mode_on(day)`, `available_on(day)`),
  its flock and parts, the map's power station (`has_power_station()`), the spend state's scars.
  No method: the row's `id`, `kind`, `duration`, `intensity_ramp`, `act_tag`, `placement`,
  `has_a_spread`, `telegraphs`, `core_intensity` and `role`; the live event's `flock`, `atlas` and
  `drawer`; the plan's `facing` and `role` (read and written); `City`'s `map` and `run`, the run's
  `header` and `attempt_spend`, the header's `day`; a lane mover's `kind` and `strategy`; a road
  closure's `segment`; a building's `condition`, `covered_ground_cols`, `footprint` and `shape`; a
  bird's `at` (written); a segment's `horizontal`.

## Verified

The six suites pass one at a time, `tools/typing_census.py --check` holds, and the field-read check
passes. No check was deleted or moved.
