# minty-quail — The event manager's and the bags' suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The event manager's and the bags' eight suites are typed and lose their opt-out line**:
  `test_event_manager`, `test_event_manager_fire`, `test_events_fire`, `test_route_bag`,
  `test_shared_bag`, `test_return_patrols`, `test_day7_van` and `test_day6_yeller_met`. What each
  tripped was one to three lines: loop variables over literals, Variant-keyed dictionaries and
  untyped arrays, and two casts. No line under `src/` changed and no rig was edited.

## Left, each with its reason

- **Search: none.** The events' fields are `event-interface.md` row 4a's scripted rewrite and the
  manager's own are rows 3a and 3b, so this pass converts no read.
- **`test_event_manager_fire.gd` still calls the private
  `EventSpawner._where_the_summoned_row_stops()`**, the open breach `tests-public-seams.md` lists.
- **`test_event_manager.gd` keeps its real City**, for the reason its header states.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Verified

The eight suites pass, `tools/typing_census.py --check` holds on them, and the field-read check
passes. No check was deleted or moved.
