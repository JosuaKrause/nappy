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
  sitings), each method's body checked to return the field read. The whole list, by class, is
  under "Fields read and written, by class" below.
- **The plan record is typed under `EventScheduler.Planned`**; the placement track's scripted rename
  to `EventPlan` reruns over it.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `74f825ce5`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `scars` → no method.
- **`City`**: `events` → no method; `map` → no method; `run` → no method; `spawn_siting` → no
  method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `soft_sealed_tiles` → no method.
- **`DaySpec`**: `holds_the_home_streets` → no method.
- **`EventDef`**: `aftermath` → no method; `aftermath.on_finish` → `leaves_behind()`; `first_day` →
  no method; `hard_fail` → `ends_the_day()`; `hard_fail`, written → no method; `id` → no method;
  `id`, written → no method; `inner_radius` → `core_within()`; `inner_radius`, written → no method;
  `intensity` → `peak()` (a yes-or-no on the field alone: `has_a_field()`); `intensity`, written →
  no method; `kind` → no method (a yes-or-no on the field alone: `is_ambient()`); `look` →
  `picture()`; `max_per_day` → `most_in_a_day()`; `mobile` → `moves()`; `on_her_way` → no method;
  `on_her_way`, written → no method; `outer_radius` → `heard_within()`; `outer_radius`, written → no
  method; `pavement_side` → no method; `pursuit` → no method; `spawn_mode` → no method; `speed` → no
  method; `stands_as`, written → no method; `still_while_telegraphing` → `holds_still()`;
  `stops_where_it_arrives` → no method; `telegraph_time` → `telegraphs_for()`; `telegraph_time`,
  written → no method; `telegraphs` → no method; `when_it_stops`, written → no method.
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out); `age`, written → `resume()` does `age = from_age`; `def` → `row()`;
  `def.hard_fail` → `ends_the_day()`; `def.id` → `row_id()`; `excitement` → `source()`;
  `is_finished` → `is_gone()`; `is_leaving` → `is_on_its_way_out()`; `is_parked` → no method
  (`EventInstance.Figure.has_parked()` returns it on a view no public method hands out); `path` →
  `walks()`.
- **`EventManager`**: `ahead` → no method; `sources` → no method; `spawner` → no method;
  `stream_radius`, written → no method; `streaming` → no method; `warnings` → no method; `world` →
  no method; `world.visible` → `visible_view()`.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.id` → `row_id()`; `live` → `instance()` (a
  yes-or-no on the field alone: `is_in_the_world()`); `live`, written → no method; `mast_id` → no
  method; `noticed_at` → no method; `path` → `walks()` (a yes-or-no on the field alone:
  `stands_still()`); `position` → `placed_at()` (a yes-or-no on the field alone: `is_placed()`);
  `spent` → `is_spent()`; `was_live` → no method; `was_live`, written → no method.
- **`EventScheduler.WalkSiting`**: `holds_the_home_streets`, written → no method; `mast_checks` → no
  method.
- **`EventWorld`**: `day` → no method.
- **`EventsAhead`**: `holds_the_home_streets` → no method.
- **`MarbleBag`**: `drawn` → `draws_made()`.
- **`OnHerWay`**: `at_a_front` → no method.
- **`PendingWarning`**: `def` → `row()`; `left` → `seconds_left()`; `offset` → no method; `place` →
  `points_at()`; `shown` → no method; `withdrawn` → no method.
- **`ResistanceDirector`**: `trace`, written → no method.
- **`ResistanceRunState`**: `completed_steps`, written → `give_back()` does `completed_steps =
  _dawn_completed_steps.duplicate()`, `restore()` does `completed_steps = _to_int_array(data["…"])`;
  `failed_steps`, written → `give_back()` does `failed_steps = _dawn_failed_steps.duplicate()`,
  `restore()` does `failed_steps = _to_int_array(data["…"])`; `progress`, written → `reset()` does
  `progress = 0`, `give_back()` does `progress = _dawn_progress`, `restore()` does `progress =
  int(data["…"])`.
- **`ResistanceSteps.Step`**: `day` → no method; `grants_progress` → no method; `index` → no method;
  `is_pickup` → no method.
- **`RouteTree`**: `branches` → no method.
- **`RouteTree.Branch`**: `routes` → no method.
- **`RunState`**: `attempt_spend` → no method; `resistance` → no method.
- **`ScreenCover`**: `left` → `left_corner()`.
- **`WorldMap`**: `obstructed_tiles` through `CityMap` → no method; `size` through `CityMap` →
  `size_in_tiles()`.

## Verified

The eight suites pass, `tools/typing_census.py --check` holds on them, and the field-read check
passes. No check was deleted or moved.
