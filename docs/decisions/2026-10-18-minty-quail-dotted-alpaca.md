# minty-quail — The event manager's and the bags' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The event manager's and the bags' eight suites are typed and lose their opt-out line**:
  `test_event_manager`, `test_event_manager_fire`, `test_events_fire`, `test_route_bag`,
  `test_shared_bag`, `test_return_patrols`, `test_day7_van` and `test_day6_yeller_met`. What each
  tripped was one to three lines: loop variables over literals and untyped arrays (a segment key
  typed `Vector3i`, as `HeldStreets` takes it), and two casts. No line under `src/` changed and no rig was edited.

## Left, each with its reason

- **Search: none.** The events' fields are `event-interface.md` row 4a's scripted rewrite and the
  manager's own are rows 3a and 3b, so this pass converts no read.
- **`test_event_manager_fire.gd` still calls the private
  `EventSpawner._where_the_summoned_row_stops()`**, the open breach `tests-public-seams.md` lists.
- **`test_event_manager.gd` keeps its real City**, for the reason its header states.
- **Other modules' fields stay for their passes.** The pull request's description lists them by
  class, inner classes included (the plan record, a resistance step, a route branch, the walk's
  sitings), each method's body checked to return the field read. Those the game answers through a
  method: the live event's `def` (`row()`), `is_finished` (`is_gone()`), `is_leaving`
  (`is_on_its_way_out()`) and `excitement` (`source()`); the plan's `def` (`row()`), `position`
  (`placed_at()`), `path` (`walks()`), `live` (`instance()`) and `spent` (`is_spent()`); the row's
  `max_per_day` (`most_in_a_day()`), `mobile` (`moves()`), `hard_fail` (`ends_the_day()`),
  `still_while_telegraphing` (`holds_still()`), `telegraph_time` (`telegraphs_for()`),
  `outer_radius` (`heard_within()`), `inner_radius` (`core_within()`), `intensity` (`peak()`),
  `aftermath.on_finish` (`leaves_behind()`) and `look` (`picture()`); a pending warning's `def`
  (`row()`), `place` (`points_at()`) and `left` (`seconds_left()`); a marble bag's `drawn`
  (`draws_made()`). The rest (among them `City`'s and the event manager's fields, the run's
  resistance and spend states, the row's `stands_as`, `when_it_stops`, `spawn_mode` and
  `on_her_way`, which methods answer only in part) have no method that returns them.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Verified

The eight suites pass, `tools/typing_census.py --check` holds on them, and the field-read check
passes. No check was deleted or moved.
