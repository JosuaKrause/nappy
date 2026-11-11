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
  class, inner classes included (among them the plan record, a region plan and a seal candidate),
  writes marked, each with the method the game calls where one exists and each method's body
  checked to return that field. The whole list, by class, is under "Fields read and written, by
  class" below.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `a96456e32`, over the `.gd` files
under `tests/` its pull request changed, and each method it names read in its class and the classes
it extends. Each read is listed with the public method that returns exactly that field, or "no
method"; each write with every public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `scars` → no method.
- **`Building`**: `condition` → no method; `covered_ground_cols` → no method; `footprint`, written →
  `stand_on()` does `footprint = size`; `lot` → `lot_rect()`; `shape` → no method.
- **`City`**: `map` → no method; `run` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `calm_blocks` → `calm_blocks_now()`;
  `home_block` → `home_block_coordinate()`; `home_rect` → `home_tile_rect()`; `network` →
  `street_network()`; `power_station` → `power_station_blocks()`; `seed_used` → `city_seed()`.
- **`EventDef`**: `act_tag` → no method; `barrier_structure` → `counts_as_one_barrier()`;
  `core_intensity` → no method; `core_intensity`, written → no method; `core_radius` → no method;
  `detain_seconds` → `detains_for()`; `draws_body_shadow` → `casts_a_shadow()`; `duration` → no
  method; `first_day` → no method; `flock_size` → no method; `hard_fail` → `ends_the_day()`;
  `has_a_spread` → no method; `id` → no method; `inner_radius` → `core_within()`; `inner_radius`,
  written → no method; `intensity` → `peak()`; `intensity`, written → no method; `intensity_ramp` →
  no method; `kind` → no method; `look` → `picture()`; `look`, written → no method; `max_per_day` →
  `most_in_a_day()`; `mobile` → `moves()`; `obstructs_radius` → `obstructs_within()`; `on_her_way`,
  written → no method; `outer_radius` → `heard_within()`; `outer_radius`, written → no method;
  `pavement_side` → no method; `placement` → no method; `pulse_period` → `pulses_every()`; `pursuit`
  → no method; `role` → no method; `shape` → `ground_shape()`; `shape`, written → `solid()` does
  `shape = new_shape`; `solid_parts` → no method; `solid_parts`, written → no method; `spawn_mode` →
  no method; `speed`, written → no method; `telegraph_time` → `telegraphs_for()`; `telegraph_time`,
  written → no method; `telegraphs` → no method.
- **`EventFlock.Bird`**: `at`, written → no method.
- **`EventInstance`**: `atlas`, written → no method; `def` → `row()`; `drawer` → no method;
  `excitement` → `source()`; `flock` → no method; `flock.birds` → `birds()` behind a guard
  (`flock.birds if flock else _NO_BIRDS`); `is_finished` → `is_gone()`; `is_leaving` →
  `is_on_its_way_out()`.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.hard_fail` → `ends_the_day()`; `def.id` →
  `row_id()`; `def.obstructs_radius` → `obstructs_within()`; `facing` → no method; `position` →
  `placed_at()`; `role` → no method; `role`, written → `give_role()` does `role = given`.
- **`GroundShape`**: `half_extents` → `rect_half_extents()`; `half_length` → `spine_half_length()`;
  `kind` → no method.
- **`LaneMover`**: `kind`, written through `CrowdAgent` → `setup_at()` does `kind = agent_kind as
  Kind`, `setup()` does `kind = agent_kind`; `strategy` through `CrowdAgent` → `lane().strategy()`
  on its view.
- **`RegionPlanner.RegionPlan`**: `alley_doors` → no method; `alley_walls` → no method;
  `door_bodies` → no method; `doors` → no method; `wall_bodies` → no method; `walls` → no method.
- **`RoadClosure`**: `segment` → no method.
- **`RunHeader`**: `day`, written → `reset()` does `day = 1`, `restore()` does `day =
  int(data["…"])`.
- **`RunState`**: `attempt_spend` → no method; `header` → no method.
- **`SealPlanner.Candidate`**: `def_ids` → no method; `id` → no method; `strength` → no method.
- **`StreetNetwork.Segment`**: `horizontal` → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.

## Verified

The six suites pass one at a time, `tools/typing_census.py --check` holds, and the field-read check
passes. No check was deleted or moved.
