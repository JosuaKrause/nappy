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
- **Other modules' fields stay for their passes**, by class, each checked against its class and
  its base classes. Answered by a method the game calls that returns the field: the run
  configuration's `debug_build` (`is_debug_build()`), `readout_requested`
  (`asks_for_the_readout()`), `invincible` (`is_invincible()`) and `active_args`
  (`dev_flag_words()`); the city's `ground_mode`, read (`ground_mode_in_force()`); the map's `size`
  (`size_in_tiles()`, inherited from `WorldMap`), `calm_blocks` (`calm_blocks_now()`), `main_road`
  (`main_road_corridor()`), `fenced_park` (`fenced_park_block()`) and `power_station`
  (`power_station_blocks()`); the live event's `def` (`row()`) and its row's id (`row_id()`); the
  day controller's `time_remaining`, read (`seconds_left()`); the traffic signals' `powered`
  (`is_powered()`); and the day spec's `length` (`seconds_on_the_clock()`). No method: the run
  configuration's other overrides and switches, and its `invincible` and `debug_build` written;
  the city's `map`, `events`, `crowd`, `scenery`, `scenery_ground`, `run`, `spawn_siting` and
  `signals`, its `ground_mode` written, and the switches a test sets on it (`scenery_frame_locked`,
  the `skip_*` switches, `blackout_forced`, `all_cyclists_pelicans`, `forced_row`,
  `forced_interval`); the map's `shut_calm` and `stretch_active`; the event manager's
  `stream_radius`, `skip_drawing` and `pelican_rig`; the crowd's `skip_motion` and
  `skip_agent_drawing`; the row's `kind`; the day controller's `phase`, `spec` and `invincible`, and
  its `time_remaining` written; the still watch's `trace`; the run state's parts and, through them,
  the header's `day`, `nerves`, `ending`, `run_seed`, `player_is_male` and `play_ticks`, the facts'
  `escape_section`, the resistance state's `progress` and `sabotage_done`, the settled state's
  `settled_in` and the attempt's `scars`; the sitting's `controls_word` and `run`
  (`take_the_run()` makes a run when none is held, so it answers only in part); a pose's
  `mother_sources` and a resistance step's `index` (inner classes); a crowd member's `skip_draw`,
  the scenery residency's `frame_locked`, the scenery ground's `mode`, the building shadows'
  `skip_draw` and the save indicator's `atlas`.
- **`main.gd` has no class name**; giving it one is a change under `src/` for the root's pass.

## Verified

Every suite that loads `booted_main.gd` or `seat.gd`, directly or through a rig, passes, and the
runner's three fixtures exit as before; `tools/typing_census.py --check` holds. No check was
deleted or moved.
