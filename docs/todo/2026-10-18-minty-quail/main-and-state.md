# main.gd split into an explicit run flow, and run state kept in one place

- **`src/main.gd`** owns boot and resume (with `static var _carry_the_run_over`), each day's
  construction (`_start_day`, about 20 ordered calls), the escape flow, the loss cause
  (`_loss_cause()` and its helpers), play time and save timing. Its modes are implicit: `_on_summary_continued` sends one `continued`
  to outcomes decided by `_recipe`, the day's `_spec`, `_resume_gate_open`, `_run_over`, `_went_back`
  and `_ending_shown`, and whether a run stands behind the escape is `main`'s `_escape_from_a_run`. `tests/test_resistance.gd` (near
  3414) copies `_start_day`'s order because it lives only in a private method.
- **The registered run state reaches the save and every reader through `GameState`.** The run's
  sub-states are one list, `GameState.run_parts`, and the dawn copy, the lost day's give-back, the
  snapshot and the save walk it; `GameSave` is a static that reads that list off `GameState` rather
  than being handed it; every other reader takes a part off the
  `GameState` global (`GameState.header.day`, `GameState.attempt_spend.scars`) rather than being
  handed it; and `GameState` keeps eleven forwarding properties (`run_seed`, `day`,
  `resistance_progress`, `consumed_one_shots`, `completed_resistance_steps`,
  `failed_resistance_steps`, `scars`, `city_state`, `sabotage_done`, `resistance_carrying_package`,
  `completed_resistance_alley_tiles`) for the readers in `src/events/**`, `src/resistance/**`,
  `tests/test_resistance.gd` and `tests/test_event_manager.gd`, which go when those files read the
  parts. `GameState.` is read about a hundred times in `main`, `GameState.day` among them. The
  hidden globals held in statics are filed in `hidden-statics.md`.
- **One summary screen with four hand-reset modes** (`day_summary.gd`: `show_day_brief`, `show_day`,
  `show_ending`, `show_finale`); the screen's mode is tracked in `main`'s booleans. The resistance tally and the run-standing
  line are each formatted in two places.

**Build:** a `RunFlow` with an explicit mode enum and its transitions; a `DayDirector` with public
`start_day(spec)` and `finish_day(result)` that `main` and the tests both call; a pure `LossCause`;
the registered run sub-states handed to the save, to every `City` and to the readers named above rather than read
from `GameState`; a pure `SummaryModel` the screen only renders, and `continued(mode)`.

**Scene recipes become configurations of `RunFlow`.** The dev flags are one `RunConfig` read at boot
(`src/run_config.gd`), and these `_recipe` branches run through `main`'s flow: loading the
recipe and building its runtime in `_ready()`; the setup-failed early return after the first day
starts; `_recipe.begin()` in both boots and the escape boot's install block; the scripted capture
clock; `_city_map()` choosing the recipe's map; the escape boot taking its day only from a recipe;
the early return in `_plan_the_finale_city()`; the escape-section retry through
`lose_the_attempt()`; `_start_day()` branching to `_start_recipe_day()`; `_apply_recipe_teaching()`,
which writes the HUD's private fields (a dependency pointing up a layer);
`_hands_over_to_the_escape()` refusing for a recipe; the scene reload in `_on_summary_continued()`.
