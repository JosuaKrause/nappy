# minty-quail — The pursuits' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The pursuits' four suites are typed and lose their opt-out line**: `test_events_pursuit`,
  `test_pursuer_on_foot`, `test_event_behaviours` and `test_events_chat`. Loop variables carry their
  element's type, a saved behaviour's answer is read through a typed `Dictionary` local, and a gold
  encounter's row through a typed `EventDef` local. No line under `src/` changed and no rig was
  edited.
- **The chat suite frees its two cast members one by one**: a typed loop over the pair failed the
  shard when one of them was already freed, so each is checked with `is_instance_valid()` and freed
  alone.

## Left, each with its reason

- **Search: none.** No class was this pass's to search: the row's, the live event's, the plan's and
  a pursuit's fields are `event-interface.md` row 4a's scripted rewrite, so no read was converted.
- **Other modules' fields stay for their passes**, by class, each checked against its class and the
  classes it extends, inner, record and behaviour classes included. Answered by a method the game
  calls that returns the field: the row's `hard_fail` (`ends_the_day()`), `inner_radius`
  (`core_within()`), `outer_radius` (`heard_within()`), `intensity` (`peak()`), `look`
  (`picture()`), `shape` (`ground_shape()`), `telegraph_time` (`telegraphs_for()`) and
  `detain_seconds` (`detains_for()`); a pursuit's `stands` (`stands_for_its_notice()`); the live
  event's `def` (`row()`), `excitement` (`source()`), `gave_up` (`has_given_up()`),
  `came_under_a_warning`, read (`was_warned_of()`), `path` (`walks()`), `is_finished` (`is_gone()`)
  and `is_leaving` (`is_on_its_way_out()`); a flock's `birds` (the live event's `birds()`); the
  event manager's `ahead`, read for what is owed ahead (`owed_ahead()`); the plan record's `def`
  (`row()`, and its id `row_id()`), `path` (`walks()`), `live` (`instance()`, typed `Node2D`) and
  `spent` (`is_spent()`); a pending warning's `place` (`points_at()`) and `def` (`row()`); a ground
  shape's `radius` (`rounding_radius()`); the map's `size` (`size_in_tiles()`) and `block_plans`
  (`plans_by_block()`); and the baby's `excitement` (`excitement_level()`) and `sleepiness`
  (`sleepiness_level()`). No method: the row's `id`, `duration`, `offscreen_notice`, `vehicle`,
  `warned_first`, `flock_size`, `speed`, `spawn_mode`, `notice` and `abduction`, and its `pursuit`,
  read and written; a pursuit's `walk_speed`, `warns_for` and `stop_excitement`, and its
  `lunge_reach`, written; a notice's `within` and `runs_within`; an abduction's `taken_over`; the
  live event's `phase`, `look`, `pursuit`, `departure`, `route`, `car`, `barrier_post`,
  `investigation`, `on_foot`, `flock` and `unreachable`, its `age`, read and written, and its
  `came_under_a_warning`, `trace` and `signals`, written; a pursuit behaviour's `outrun_for`; an
  officer's `trail`; the event manager's `world`, `streaming`, `spawner`, `warnings` and `sources`,
  its `ahead`, read to place what is owed ahead, and its `trace` and `atlas`, written; the event
  world's `map`; the plan record's `behaviours`; a visible view's `view`; the danger edge's `atlas`,
  written; the city's `events` and `map`; the map's `world`, read and written; and the world
  context's `excitement_sources`, written.

## Verified

The four suites pass, `tools/typing_census.py --check` holds, and the field-read check passes. No
check was deleted or moved.
