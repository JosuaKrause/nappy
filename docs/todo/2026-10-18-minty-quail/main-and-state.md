# main.gd split into an explicit run flow

- **`src/main.gd`** owns boot and resume (with `static var _carry_the_run_over`), the escape flow,
  play time and save timing, and the scene recipes' own day start (`_start_recipe_day()`,
  `_apply_recipe_teaching()`). A day's construction and its end are `DayDirector`'s
  (`start_day(spec)`, `finish_day(result)` returning a `DayEnd`) and the loss cause is `LossCause`'s;
  `main` builds the director for the world as it stands and writes the save and raises the screen
  after `finish_day()`. Its modes are implicit: `_on_summary_continued` sends one `continued` to
  outcomes decided by `_recipe`, the day's `_spec`, `_resume_gate_open`, `_run_over`, `_went_back` and
  `_ending_shown`, and whether a run stands behind the escape is `main`'s `_escape_from_a_run`.
- **The run's parts are read through `GameState`, by `GameSave` and by the readers.** `GameSave` is a
  static that reads `GameState.run_parts` rather than being handed it; every reader other than
  `City` and `DayDirector` (which are handed the run) takes a part off the `GameState` global
  (`GameState.header.day`, `GameState.attempt_spend.scars`), `main` among them. The hidden globals held
  in statics are filed in `hidden-statics.md`, and so is moving the calendar's operations
  (`day_rng()`, `begin_day()`, `finish_day()`) off the autoload.
- **One summary screen with four hand-reset modes** (`day_summary.gd`: `show_day_brief`, `show_day`,
  `show_ending`, `show_finale`); the screen's mode is tracked in `main`'s booleans. The resistance tally and the run-standing
  line are each formatted in two places.

**Build:** a `RunFlow` with an explicit mode enum and its transitions; the run handed to the save and
to the remaining readers rather than read from `GameState`; a pure `SummaryModel` the screen only
renders, and `continued(mode)`.

**Scene recipes become configurations of `RunFlow`.** The dev flags are one `RunConfig` read at boot
(`src/run_config.gd`), and these `_recipe` branches run through `main`'s flow: loading the
recipe and building its runtime in `_ready()`; the setup-failed early return after the first day
starts; `_recipe.begin()` in both boots and the escape boot's install block; the scripted capture
clock; `_city_map()` choosing the recipe's map; the escape boot taking its day only from a recipe;
the early return in `_plan_the_finale_city()`; the escape-section retry through
`lose_the_attempt()`; `_start_day()` branching to `_start_recipe_day()`; `_apply_recipe_teaching()`,
which writes the HUD's private fields (a dependency pointing up a layer);
`main._new_director()` setting `escape_follows` to false for a recipe; the scene reload in `_on_summary_continued()`.
