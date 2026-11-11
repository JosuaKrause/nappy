# minty-quail — The runner and the booted game's rigs are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The runner, the shared-state check and the booted game's rigs are typed and lose their opt-out
  line**: `run_tests.gd`, `shared_state.gd`, `booted_main.gd`, `seat.gd`, `full_run_rig.gd`,
  `test_main.gd`, `test_run_config.gd` and `test_presentation_mode.gd`. Each rig function keeps its
  name, argument order and answer; nothing under `src/` changed.
- **A booted game is held as `main.gd` preloaded as a constant** in `booted_main.gd`, since
  `main.gd` has no class name, so the hand-ins a test makes on it are typed calls; the rig helpers
  keep their `Node` parameters.
- **The runner calls a suite's `run` through `call()`**, since the suites share no base class; its
  exit codes and its load-failure path are unchanged, and its shuffle takes the typed list of suite
  names.
- **The full run's freed-instance loop takes its key as a `Variant`**, checked with
  `is_instance_valid()` and cast after: a typed loop variable fails on an instance freed during the
  run, which CI showed in two of the full-run suites. A comment above the loop says why.

## Left, each with its reason

- **Search: none.** No class was this pass's to search, so no read was converted.
- **Other modules' fields stay for their passes**, by class, each checked against its class and the
  classes it extends, and listed under "Fields read and written, by class" below.
- **`main.gd` has no class name**; giving it one is a change under `src/` for the root's pass.

## Fields read and written, by class

Built with `tools/field_answers.py` at the pass's merge commit `e888950c9`, over the `.gd` files
under `tests/` its pull request changed, and each method it names read in its class and the classes
it extends. Each read is listed with the public method that returns exactly that field, or "no
method"; each write with every public method that assigns the field, and what it assigns.

- **`AttemptSpendState`**: `scars` → no method.
- **`BuildingShadows`**: `skip_draw` → no method.
- **`City`**: `all_cyclists_pelicans` → no method; `all_cyclists_pelicans`, written → no method;
  `blackout_forced` → no method; `blackout_forced`, written → no method; `crowd` → no method;
  `events` → no method; `forced_interval` → no method; `forced_interval`, written → no method;
  `forced_row` → no method; `forced_row`, written → no method; `ground_mode` →
  `ground_mode_in_force()`; `ground_mode`, written → no method; `map` → no method; `run` → no
  method; `scenery` → no method; `scenery_frame_locked` → no method; `scenery_frame_locked`, written
  → no method; `scenery_ground` → no method; `signals` → `traffic_signals()`; `skip_crowd_drawing` →
  no method; `skip_crowd_drawing`, written → no method; `skip_crowd_motion` → no method;
  `skip_crowd_motion`, written → no method; `skip_event_drawing` → no method; `skip_event_drawing`,
  written → no method; `skip_shadows` → no method; `skip_shadows`, written → no method;
  `spawn_siting` → no method.
- **`CityMap`**: `calm_blocks` → `calm_blocks_now()`; `fenced_park` → `fenced_park_block()`;
  `main_road` → `main_road_corridor()`; `power_station` → `power_station_blocks()`; `shut_calm` → no
  method; `stretch_active` → no method.
- **`Crowd`**: `skip_agent_drawing` → no method; `skip_motion` → no method; `skip_motion`, written →
  no method.
- **`CrowdAgent`**: `skip_draw` → no method.
- **`DayController`**: `invincible`, written → no method; `phase` → no method; `spec` → no method;
  `spec`, written → no method; `time_remaining` → `seconds_left()`.
- **`DaySpec`**: `length` → `seconds_on_the_clock()`.
- **`EventDef`**: `kind` → no method.
- **`EventInstance`**: `def` → `row()`; `def.id` → `row_id()`.
- **`EventManager`**: `pelican_rig` → no method; `skip_drawing` → no method; `stream_radius`,
  written → no method.
- **`ResistanceRunState`**: `progress`, written → `reset()` does `progress = 0`, `give_back()` does
  `progress = _dawn_progress`, `restore()` does `progress = int(data["…"])`; `sabotage_done`,
  written → `reset()` does `sabotage_done = false`, `give_back()` does `sabotage_done =
  _dawn_sabotage_done`, `restore()` does `sabotage_done = bool(data["…"])`.
- **`ResistanceSteps.Step`**: `index` → no method.
- **`RunConfig`**: `active_args` → `dev_flag_words()`; `blackout_requested` → no method;
  `controls_word` → no method; `day_override` → no method; `debug_build` → `is_debug_build()`;
  `debug_build`, written → no method; `ending_override` → no method; `ground_mode` → no method;
  `invincible` → `is_invincible()`; `invincible`, written → no method; `is_rig` → no method;
  `layers_override` → no method; `meters_override` → no method; `no_focus_pause` → no method;
  `no_telemetry` → no method; `parent_override` → no method; `readout_requested` →
  `asks_for_the_readout()`; `recipe_path` → no method; `recording` → no method; `route_targets` → no
  method; `seed_override` → no method; `skip_crowd` → no method; `skip_events` → no method;
  `skip_motion` → no method; `skip_shadows` → no method; `skip_words` → no method; `spawn_target` →
  no method; `start_escape` → no method; `start_escape_at` → no method.
- **`RunFacts`**: `escape_section` → no method; `escape_section`, written → `reset()` does
  `escape_section = 0`, `restore()` does `escape_section = int(data.get("…", 0))`.
- **`RunHeader`**: `day` → no method; `day`, written → `reset()` does `day = 1`, `restore()` does
  `day = int(data["…"])`; `ending` → no method; `nerves` → no method; `nerves`, written → `reset()`
  does `nerves = Tuning.STARTING_NERVES`, `restore()` does `nerves = int(data["…"])`; `play_ticks` →
  no method; `play_ticks`, written → `reset()` does `play_ticks = 0`, `restore()` does `play_ticks =
  roundi(float(data["…"]) * Engine.physics_ticks_per_second)`; `player_is_male` → no method;
  `run_seed` → no method; `run_seed`, written → `restore()` does `run_seed = int(data["…"])`.
- **`RunState`**: `attempt_spend` → no method; `calendar` → no method; `facts` → no method; `header`
  → no method; `resistance` → no method; `settled` → no method.
- **`SaveIndicator`**: `atlas` → no method.
- **`SceneryGround`**: `mode` → no method.
- **`SceneryResidency`**: `frame_locked` → no method.
- **`SettledState`**: `settled_in` → no method.
- **`Sitting`**: `controls_word` → no method; `run` → no method; `run`, written → `take_the_run()`
  does `run = RunState.new()`.
- **`StillWatch`**: `trace` → no method.
- **`Stroller.Pose`**: `mother_sources` → no method.
- **`TrafficSignals`**: `powered` → `is_powered()`.
- **`WorldMap`**: `size` through `CityMap` → `size_in_tiles()`.

## Verified

Every suite that loads `booted_main.gd` or `seat.gd`, directly or through a rig, passes, and the
runner's three fixtures exit as before; `tools/typing_census.py --check` holds. No check was
deleted or moved.
