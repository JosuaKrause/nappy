# minty-quail — The escape city's rigs are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The escape city's two rigs are typed and lose their opt-out line**: `finale_rig.gd` and
  `escape_roadblock_rig.gd`. Each function keeps its name, argument order and answer; the suites
  that load them (`test_finale_a`, `_b`, `_c`, `test_barrier_stays`) pass, and the probe and the rig that
  preload `escape_roadblock_rig.gd` still load. Loop variables are typed; a stage
  `RoadblockRig.build()` hands back in an untyped array is read into a typed local and closed
  through it; the boot and hand-in
  callbacks take `Node`, the seam's type, and cast to `main.gd` preloaded as a constant, as
  `tests/test_observers.gd` does, since `main.gd` has no class name. No line under `src/` changed.

## Left, each with its reason

- **Search: none.** No class was this pass's to search: the plan records' and the events' fields
  stay for the pass or step that owns them (the events' are `event-interface.md` row 4a's).
- **`main.gd` has no class name**, so a rig reaches it through a preloaded script; giving it one is a
  change under `src/` this pass does not make, noted for the root's pass.
- **`RoadblockRig.build()`, in this pass's own `escape_roadblock_rig.gd`, still returns an untyped
  `Array`**, so each caller reads the stage into a typed local; typing that return is left open.
- **Other modules' fields stay for their passes.** The pull request's description lists them by
  class, inner classes included (the finale plan and its chains, a calm area, the plan record, a
  walk solid, a roadblock stage, a street segment), each with the method the game calls where one exists and each
  method's body checked to return that field. The whole list, by class, is under "Fields read and
  written, by class" below.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `62bf02e9a`, over the `.gd` files
under `tests/` its pull request changed, and each method it names read in its class and the classes
it extends. Each read is listed with the public method that returns exactly that field, or "no
method"; each write with every public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `city_state` → `block_arcs()`.
- **`City`**: `crowd` → no method; `events` → no method; `map` → no method; `run` → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `home_block` → `home_block_coordinate()`;
  `main_road` → `main_road_corridor()`; `network` → `street_network()`.
- **`DayController`**: `spec` → no method; `time_remaining` → `seconds_left()`; `time_remaining`,
  written → `start()` does `time_remaining = length`, `tick()` does `time_remaining -= delta`.
- **`DayEnd`**: `hands_over_to_the_escape` → `continues_into_the_escape()`.
- **`DaySpec`**: `bag` → no method; `bag`, written → no method; `exits` → `exit_points()`; `length`
  → `seconds_on_the_clock()`; `number` → `day_number()`; `owes_a_return`, written → no method;
  `section` → `section_kind()`; `title` → no method.
- **`EventDef`**: `aftermath` → no method; `aftermath.on_finish` → `leaves_behind()`; `hard_fail` →
  `ends_the_day()`; `id` → no method; `intensity` → `peak()`; `look` → `picture()`; `mobile` →
  `moves()`; `obstructs_radius` → `obstructs_within()`; `outer_radius` → `heard_within()`; `pursuit`
  → no method.
- **`EventInstance`**: `barrier_post` → no method; `def` → `row()`; `def.id` → `row_id()`;
  `excitement` → `source()`; `gave_up` → `has_given_up()`; `is_finished` → `is_gone()`; `is_leaving`
  → `is_on_its_way_out()`.
- **`EventManager`**: `atlas`, written → no method; `spawner` → no method; `stream_radius`, written
  → no method; `streaming` → no method; `warnings` → no method; `world` → no method.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.hard_fail` → `ends_the_day()`; `def.id` →
  `row_id()`; `def.obstructs_radius` → `obstructs_within()`; `live` → `instance()`; `live`, written
  → no method; `position` → `placed_at()`; `was_live` → no method; `was_live`, written → no method.
- **`FinalePlanner.CalmArea`**: `centre` → no method; `tiles` → no method.
- **`FinalePlanner.Chain`**: `cells` → no method; `complete` → no method; `exit_kind` → no method;
  `stops` → no method.
- **`FinalePlanner.Plan`**: `chains` → no method; `open_cells` → no method; `open_streets` →
  `streets_on_the_walk()`.
- **`GroundShape`**: `kind` → no method; `radius` → `rounding_radius()`.
- **`HelpText`**: `line` → no method.
- **`InteriorScene`**: `map` → no method.
- **`PursuitSpec`**: `leaves_its_body` → no method; `warns_for` → no method.
- **`ResistanceRunState`**: `progress`, written → `reset()` does `progress = 0`, `give_back()` does
  `progress = _dawn_progress`, `restore()` does `progress = int(data["…"])`; `sabotage_done`,
  written → `reset()` does `sabotage_done = false`, `give_back()` does `sabotage_done =
  _dawn_sabotage_done`, `restore()` does `sabotage_done = bool(data["…"])`.
- **`RunFacts`**: `escape_section` → no method; `escape_section`, written → `reset()` does
  `escape_section = 0`, `restore()` does `escape_section = int(data.get("…", 0))`.
- **`RunHeader`**: `day` → no method; `day`, written → `reset()` does `day = 1`, `restore()` does
  `day = int(data["…"])`; `nerves` → no method; `play_ticks` → no method.
- **`RunState`**: `attempt_spend` → no method; `calendar` → no method; `facts` → no method; `header`
  → no method; `resistance` → no method.
- **`Sitting`**: `atlas` → no method; `run` → no method.
- **`StreetNetwork.Segment`**: `horizontal` → no method.
- **`WalkGround.Solid`**: `axis` → no method; `centre` → no method; `shape` → no method.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`; `world` → no method; `world`,
  written → no method.

## Verified

The four suites pass, `tools/typing_census.py --check` holds, and no check was
deleted or moved.
