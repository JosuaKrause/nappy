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
  classes it extends, inner, record and behaviour classes included, and listed under "Fields read
  and written, by class" below.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `61f8e426c`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`AbductionSpec`**: `taken_over` → no method.
- **`Baby`**: `excitement` → `excitement_level()`; `sleepiness` → `sleepiness_level()`.
- **`City`**: `events` → no method; `map` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`.
- **`DangerEdge`**: `atlas`, written → no method.
- **`EventDef`**: `abduction` → no method; `detain_seconds` → `detains_for()` (a yes-or-no on the
  field alone: `detains_her()`); `duration` → no method; `flock_size` → no method (a yes-or-no on
  the field alone: `is_a_flock()`); `hard_fail` → `ends_the_day()`; `id` → no method; `inner_radius`
  → `core_within()`; `intensity` → `peak()` (a yes-or-no on the field alone: `has_a_field()`);
  `look` → `picture()`; `notice` → no method (a yes-or-no on the field alone: `waits_for_her()`);
  `notice.within` → `notice_within()`; `offscreen_notice` → no method; `outer_radius` →
  `heard_within()`; `pursuit` → no method; `pursuit`, written → no method; `shape` →
  `ground_shape()`; `spawn_mode` → no method; `speed` → no method; `telegraph_time` →
  `telegraphs_for()`; `vehicle` → no method (a yes-or-no on the field alone: `drives()`);
  `warned_first` → no method.
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out); `age`, written → `resume()` does `age = from_age`; `barrier_post` → no
  method; `came_under_a_warning` → `was_warned_of()`; `came_under_a_warning`, written → no method;
  `car` → no method; `def` → `row()`; `def.id` → `row_id()`; `departure` → no method; `excitement` →
  `source()`; `flock` → no method; `flock.birds` → `birds()` behind a guard (`flock.birds if flock
  else _NO_BIRDS`); `flock.offsets()` → `flock_offsets()`; `flock.velocities()` →
  `flock_velocities()`; `gave_up` → `has_given_up()`; `investigation` → no method; `is_finished` →
  `is_gone()`; `is_leaving` → `is_on_its_way_out()`; `look` → no method; `on_foot` → no method;
  `path` → `walks()`; `phase` → no method (a yes-or-no on the field alone: `is_gone()`,
  `is_on_its_way_out()`, `is_only_its_barrier()`); `pursuit` → no method; `route` → no method;
  `signals`, written → no method; `trace`, written → no method; `unreachable` → no method.
- **`EventManager`**: `ahead` → no method; `ahead.owed_ahead()` → `owed_ahead()`; `atlas`, written →
  no method; `sources` → no method; `spawner` → no method; `streaming` → no method; `trace`, written
  → no method; `warnings` → no method; `world` → no method.
- **`EventOfficer`**: `trail` → no method (a yes-or-no on the field alone: `walks_back()`).
- **`EventPursuit`**: `outrun_for` → no method.
- **`EventScheduler.Planned`**: `behaviours` → no method; `def` → `row()`; `def.id` → `row_id()`;
  `live` → `instance()` (a yes-or-no on the field alone: `is_in_the_world()`); `path` → `walks()` (a
  yes-or-no on the field alone: `stands_still()`); `spent` → `is_spent()`.
- **`EventWorld`**: `map` → no method.
- **`GroundShape`**: `radius` → `rounding_radius()`.
- **`NoticeSpec`**: `runs_within` → no method.
- **`PendingWarning`**: `def` → `row()`; `place` → `points_at()`.
- **`PursuitSpec`**: `lunge_reach`, written → no method; `stands` → `stands_for_its_notice()`;
  `stop_excitement` → no method; `walk_speed` → no method; `warns_for` → no method.
- **`VisibleView`**: `view` → no method.
- **`WorldContext`**: `excitement_sources`, written → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`; `world` → no method (a yes-or-no on
  the field alone: `has_world()`); `world`, written through `CityMap` → no method.

## Verified

The four suites pass, `tools/typing_census.py --check` holds, and the field-read check passes. No
check was deleted or moved.
