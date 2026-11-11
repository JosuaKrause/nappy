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
  them by class; the whole list is under "Fields read and written, by class" below. The row's
  `hunts.lets_out`, read on a cold row in `test_heat`, is not what `lets_out()` answers: that asks
  the heated copy's `hunting`, null on a cold row.
- **The traffic lights' clock, `TrafficSignals.elapsed`, written** in `test_police_car`: `restart_cycle()`
  and `advance()` do those writes and the crowd calls both (the record minty-quail-tiny-elk names
  the same methods); both of the crowd's passes have merged, so they wait for the suite's own
  conversion to one module, or the sweep `typed-everywhere.md` proposes.
- **Fields of inner classes**, which the field-read check does not list, are in that list too: the
  plan's (`EventScheduler.Planned`), a mast site's (`MastSites.Site`) and a calm area's
  (`ClosurePlanner.CalmArea`).
- **`test_fire_truck_body.gd` still calls the private `EventSpawner._where_the_summoned_row_stops()`**,
  the open breach `tests-public-seams.md` lists.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `2712a6184`, over the pass's files
(the `.gd` files under `tests/` its pull request changed, and any that "What was built" names as
already free of an opt-out line), and each method it names read in its class and the classes it
extends. Each read is listed with the public method that returns exactly that field, or "no method",
and with a yes-or-no method the tool prints beside it, a hint for a null test; each write with every
public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `scars` → no method.
- **`City`**: `crowd` → no method; `events` → no method; `map` → no method; `run` → no method.
- **`CityMap`**: `calm_blocks` → `calm_blocks_now()`; `main_road` → `main_road_corridor()`;
  `network` → `street_network()`.
- **`ClosurePlanner.CalmArea`**: `access` → no method.
- **`Crowd`**: `sources` → no method.
- **`CrowdAgent`**: `excitement` → `mood()`.
- **`DangerEdge`**: `atlas`, written → no method.
- **`EventDef`**: `duration` → no method; `first_day` → no method; `hard_fail` → `ends_the_day()`;
  `heat_response` → no method; `hunts` → no method; `id` → no method; `inner_radius` →
  `core_within()`; `intensity` → `peak()` (a yes-or-no on the field alone: `has_a_field()`); `kind`
  → no method (a yes-or-no on the field alone: `is_ambient()`); `max_per_day` → `most_in_a_day()`;
  `mobile` → `moves()`; `obstructs_radius` → `obstructs_within()` (a yes-or-no on the field alone:
  `has_a_body()`); `outer_radius` → `heard_within()`; `paces`, written → no method; `pursuit` → no
  method; `shape` → `ground_shape()`; `shape`, written → `solid()` does `shape = new_shape`; `speed`
  → no method; `telegraph_time` → `telegraphs_for()`; `vehicle` → no method (a yes-or-no on the
  field alone: `drives()`).
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out); `barrier_post` → no method; `car` → no method; `def` → `row()`; `drawer`
  → no method; `drawer`, written → no method; `excitement` → `source()`; `is_finished` →
  `is_gone()`; `is_leaving` → `is_on_its_way_out()`; `is_parked` → no method
  (`EventInstance.Figure.has_parked()` returns it on a view no public method hands out);
  `is_pelican` → `is_drawn_as_a_pelican()`; `look` → no method; `signals`, written → no method;
  `silenced` → `is_silenced()`.
- **`EventManager`**: `atlas` → no method; `pelican_rig`, written → no method; `spawner` → no
  method; `stream_radius`, written → no method; `streaming` → no method; `trace`, written → no
  method; `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.id` → `row_id()`; `live` → `instance()` (a
  yes-or-no on the field alone: `is_in_the_world()`); `mast_id` → no method; `position` →
  `placed_at()` (a yes-or-no on the field alone: `is_placed()`); `silenced` → no method.
- **`EventStreaming`**: `broadcast_clock` → no method.
- **`EventWorld`**: `drawer`, written → no method.
- **`GroundShape`**: `half_length` → `spine_half_length()`; `kind` → no method (a yes-or-no on the
  field alone: `is_rect()`, `is_segment()`); `radius` → `rounding_radius()`.
- **`HuntSpec`**: `lets_out` → no method.
- **`MastSites.Site`**: `foot` → no method; `id` → no method.
- **`PelicanState`**: `draws` → no method; `draws`, written → `reset()` does `draws = 0`,
  `give_back()` does `draws = _dawn`, `restore()` does `draws = int(data.get("…", 0))`.
- **`PendingWarning`**: `is_pelican` → no method.
- **`PursuitSpec`**: `leaves_its_body` → no method; `stop_excitement` → no method; `warns_for` → no
  method.
- **`RunConfig`**: `pelican` → no method.
- **`RunHeader`**: `day`, written → `reset()` does `day = 1`, `restore()` does `day =
  int(data["…"])`; `run_seed`, written → `restore()` does `run_seed = int(data["…"])`.
- **`RunState`**: `attempt_spend` → no method; `header` → no method; `pelican` → no method;
  `run_parts` → no method.
- **`Stroller`**: `facing` → `facing_direction()`; `facing`, written → `reset_at()` does `facing =
  look.normalized()`.
- **`TrafficSignals`**: `elapsed`, written → `restart_cycle()` does `elapsed = 0.0`, `advance()`
  does `elapsed += delta`.
- **`VehicleSpec`**: `field_from_its_centre` → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.

## Verified

The six suites pass one at a time, `tools/typing_census.py --check` holds on them, and the
field-read and test-only checks pass. No check was deleted or moved.
