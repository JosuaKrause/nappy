# minty-quail — The telemetry's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is: "we type when we can" (inbox #1280 in
olive-ferret). This is the telemetry's pass of `typed-everywhere.md`'s "What is untyped in a test
goes as its suite is converted", after the telemetry's own files were typed
(minty-quail-woolly-marten) and the runner was typed in every suite (minty-quail-downy-kestrel).

## What was built

- **`test_telemetry`, `test_telemetry_observer`, `test_visit_counter`, `test_observers`,
  `test_burst_capture` and `test_performance` are typed**, and each loses its opt-out line. No line
  under `src/` changed.
- **The recording page counter's bus is typed as the bus's script** rather than `Node`, which types
  every signal the suite reads through it. **The boot callbacks of `test_observers` take `Main`**,
  a preload of `res://src/main.gd`, which has no class name.
- **A Variant-valued `back()` became an index** where the suite needs the type.

## Reads left, each with its reason

The suites read no field of the telemetry's own classes. They read and write many fields of other
modules' classes (the run's parts, the live event, the day, the day spec, the map, the plan, her
facing), and those stay until each module's pass; `tools/check_field_reads.py` reads only `src/`,
so it does not list them. `counter.run.header.day` has no method the game calls, as the game reads
the field itself. The frame recorder's and the frame trace's suites (`test_frame_record*`,
`test_frame_trace`) are not in this pass: the hand-in cut that rewrites the recorder and the trace
takes them.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `3e007ceab`, over the `.gd` files
under `tests/` its pull request changed, and each method read in its class and the classes it
extends: each read with the public method that returns exactly that field, or "no method"; each
write with every public method that assigns the field, and what it assigns.

- **`AtlasLibrary`**: `trace_note`, written → no method.
- **`CityMap`**: `block_plans` → `plans_by_block()`; `built_over` → `streets_built_over()`;
  `built_over`, written → `record_built_over()` does `built_over[key] = rect`; `calm_blocks` →
  `calm_blocks_now()`; `calm_blocks`, written → no method; `home_block`, written → no method;
  `home_rect`, written → no method; `main_road` → `main_road_corridor()`; `precinct_spans` →
  `precinct_stretches()`; `seed_used`, written → `generated_from()` does `seed_used = seed_value`;
  `tiles` → `walk_tiles()`.
- **`CityState`**: `trace`, written → `use_trace()` does `trace = sink`.
- **`DayController`**: `exit_reached`, written → `start()` does `exit_reached = -1`;
  `failure_reason`, written → `start()` does `failure_reason = "…"`, `tick()` does `failure_reason =
  Texts.DAY_LOST_DUSK`; `spec` → no method; `time_remaining`, written → `start()` does
  `time_remaining = length`, `tick()` does `time_remaining -= delta`.
- **`DaySpec`**: `exits` → `exit_points()`; `section` → `section_kind()`.
- **`EventDef`**: `duration` → no method; `hard_fail` → `ends_the_day()`; `notice` → no method;
  `outer_radius` → `heard_within()`; `pursuit` → no method; `telegraph_time` → `telegraphs_for()`.
- **`EventInstance`**: `age` → no method (`EventInstance.Figure.age()` returns it on a view no
  public method hands out); `came_under_a_warning`, written → no method; `def` → `row()`;
  `def.telegraph_time` → `telegraphs_for()`; `is_finished` → `is_gone()`; `is_leaving` →
  `is_on_its_way_out()`.
- **`EventScheduler.Planned`**: `def` → `row()`; `def.hard_fail` → `ends_the_day()`; `def.id` →
  `row_id()`; `live` → `instance()`; `live`, written → no method; `path` → `walks()`; `position` →
  `placed_at()`; `role` → no method; `role`, written → `give_role()` does `role = given`.
- **`NoticeSpec`**: `runs_within` → no method.
- **`PursuitSpec`**: `warns_for` → no method.
- **`ResistanceRunState`**: `completed_steps` → no method; `failed_steps` → no method; `progress` →
  no method; `progress`, written → `reset()` does `progress = 0`, `give_back()` does `progress =
  _dawn_progress`, `restore()` does `progress = int(data["…"])`; `sabotage_done`, written →
  `reset()` does `sabotage_done = false`, `give_back()` does `sabotage_done = _dawn_sabotage_done`,
  `restore()` does `sabotage_done = bool(data["…"])`.
- **`RunCalendar`**: `hard_mode`, written → `choose_mode()` does `hard_mode = hard`.
- **`RunFacts`**: `escape_section`, written → `reset()` does `escape_section = 0`, `restore()` does
  `escape_section = int(data.get("…", 0))`.
- **`RunHeader`**: `day` → no method; `day`, written → `reset()` does `day = 1`, `restore()` does
  `day = int(data["…"])`; `ending` → no method; `nerves` → no method; `nerves`, written → `reset()`
  does `nerves = Tuning.STARTING_NERVES`, `restore()` does `nerves = int(data["…"])`.
- **`RunState`**: `calendar` → no method; `facts` → no method; `header` → no method; `resistance` →
  no method.
- **`Stroller`**: `facing`, written → `reset_at()` does `facing = look.normalized()`.
- **`TelemetryLog`**: `lines` → `recorded_lines()`, which returns a copy of it (the tool prints no
  method).
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.

## Verified

The six suites pass, `tools/typing_census.py --check` holds, and nothing a game file runs changed,
so the identity probes do not apply. No check was deleted or moved.
