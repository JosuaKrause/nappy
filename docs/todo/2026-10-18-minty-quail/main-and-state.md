# main.gd split into an explicit run flow

- **`src/main.gd`** owns boot and resume (with `static var _carry_the_run_over`), the escape flow,
  play time and save timing, and the scene recipes' own day start (`_start_recipe_day()`,
  `_apply_recipe_teaching()`). A day's construction and its end are `DayDirector`'s, and which screen
  is up and what its continue leads to are `RunFlow`'s (`src/run/run_flow.gd`): its modes, its
  `continued()` steps, how the boot came to the run (`Opening`), and the recipe's continue, retry and
  `escape_follows` as its `authored` configuration. The readout, the HUD's clock precision and the
  route rig hear the day from `RunFlow.day_started` / `day_planned`.
- **The run's parts are read through `GameState`, by `GameSave` and by the readers.** `GameSave` is a
  static that reads `GameState.run_parts` rather than being handed it; every reader other than
  `City` and `DayDirector` (which are handed the run) takes a part off the `GameState` global
  (`GameState.header.day`, `GameState.attempt_spend.scars`), `main` among them. The hidden globals held
  in statics are filed in `hidden-statics.md`, and so is moving the calendar's operations
  (`day_rng()`, `begin_day()`, `finish_day()`) off the autoload.
- **One summary screen with four hand-reset modes** (`day_summary.gd`: `show_day_brief`, `show_day`,
  `show_ending`, `show_finale`), whose one `continued` signal `RunFlow` answers by its own mode; the
  screen keeps its own epilogue flag (`is_showing_the_epilogue()`, read by a test alone). The
  resistance tally and the run-standing line are each formatted in two places.

**Build:** the run handed to the save and to the remaining readers rather than read from `GameState`
(PR 4b); a pure `SummaryModel` the screen only renders, and `continued(mode)` (PR 4c).

**Scene recipes become configurations of `RunFlow`** (PR 4c). The dev flags are one `RunConfig` read
at boot (`src/run_config.gd`), and these `_recipe` branches still run outside the flow: loading the
recipe and building its runtime in `_ready()`; the setup-failed early return after the first day
starts; `_recipe.begin()` in both boots and the escape boot's install block; the scripted capture
clock; `_city_map()` choosing the recipe's map; the escape boot taking its day only from a recipe;
the early return in `_plan_the_finale_city()`; `_start_day()` branching to `_start_recipe_day()`;
`_apply_recipe_teaching()`, which writes the HUD's private fields (a dependency pointing up a layer).

**Carry-over for the events PR 4** (the events agent's files): these read the run off `GameState`
rather than being handed it — `src/events/event_manager.gd`, `event_scheduler.gd`, `event_def.gd`,
`event_catalogue.gd`, `event_director.gd`, and `src/resistance/resistance_director.gd`,
`happenings.gd`, `resistance_steps.gd`.
