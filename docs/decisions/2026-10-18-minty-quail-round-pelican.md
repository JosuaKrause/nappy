# minty-quail — The single events' and the night group's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The single events' and the night group's six suites are typed and lose their opt-out line**:
  `test_police_car`, `test_fire_truck_body`, `test_car_front`, `test_pelican`, `test_heat` and
  `test_masts`. Loop variables are typed, a scene's `instantiate()` goes through a `PackedScene`
  local, and a Variant read goes through a `Vector2` local. No line under `src/` changed and no rig
  was edited.

## Left, each with its reason

The search covered `CarStrike`, the subject of `test_car_front`; it declares no `var`, and the
suite calls only its static `hits()`, so nothing was converted.

- **Other modules' fields stay for their passes.** The pull request's description lists all of
  them by class. Those the game answers through a method: the map's `main_road`
  (`main_road_corridor()`), `calm_blocks` (`calm_blocks_now()`), `network` (`street_network()`)
  and `size` (`size_in_tiles()`); a crowd agent's `excitement` (`mood()`); the live event's `def`
  (`row()`), `is_finished` (`is_gone()`), `is_leaving` (`is_on_its_way_out()`), `is_pelican`
  (`is_drawn_as_a_pelican()`), `silenced` (`is_silenced()`) and `excitement` (`source()`); the
  row's `hard_fail` (`ends_the_day()`), `inner_radius` (`core_within()`), `outer_radius`
  (`heard_within()`), `intensity` (`peak()`), `max_per_day` (`most_in_a_day()`), `mobile`
  (`moves()`), `obstructs_radius` (`obstructs_within()`), `shape` (`ground_shape()`),
  `telegraph_time` (`telegraphs_for()`); a ground shape's `half_length`
  (`spine_half_length()`), `radius` (`rounding_radius()`) and `kind` (`is_segment()`). The rest
  (among them `City`'s `crowd`, `events` and `run`, the event manager's fields, the run's parts,
  the row's `hunts`, and the live event's `age`, `car`, `look`, `is_parked`, `barrier_post`,
  `drawer` and `signals`) have no method the game calls. The row's `hunts.lets_out`, read on a cold row in `test_heat`, is not
  what `lets_out()` answers: that asks the heated copy's `hunting`, null on a cold row.
- **The traffic lights' clock, `TrafficSignals.elapsed`, written** in `test_police_car`: `restart_cycle()`
  and `advance()` do those writes and the crowd calls both (the record minty-quail-tiny-elk names
  the same methods); both of the crowd's passes have merged, so they wait for the suite's own
  conversion to one module, or the sweep `typed-everywhere.md` proposes.
- **Fields of inner classes**, which the field-read check does not list: the plan's
  (`EventScheduler.Planned`) `def` (`row()`), `position` (`placed_at()`), `live` (`instance()`, and
  `is_in_the_world()` for its null test), `mast_id` and `silenced` (none); a mast site's
  (`MastSites.Site`) `id` and `foot` (none); a calm area's (`ClosurePlanner.CalmArea`) `access`
  (none).
- **`test_fire_truck_body.gd` still calls the private `EventSpawner._where_the_summoned_row_stops()`**,
  the open breach `tests-public-seams.md` lists.

## Verified

The six suites pass one at a time, `tools/typing_census.py --check` holds on them, and the
field-read and test-only checks pass. No check was deleted or moved.
