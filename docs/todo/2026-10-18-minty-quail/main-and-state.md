# main.gd split into an explicit run flow, and run state kept in one place

- **`src/main.gd`** (2,436 lines) owns boot and resume (with `static var _carry_the_run_over`),
  each day's construction (`_start_day`, about 20 ordered calls), the escape flow, the loss cause
  (`_loss_cause()` and its helpers), play time and save timing. Its modes are implicit: `_on_summary_continued` sends one `continued`
  to outcomes decided by `_recipe`, the day's `_spec`, `_resume_gate_open`, `_run_over`, `_went_back`
  and `_ending_shown`, and whether a run stands behind the escape is `main`'s `_escape_from_a_run`. `tests/test_resistance.gd` (near
  3414) copies `_start_day`'s order because it lives only in a private method.
- **Run state is kept by hand in up to six places per field:** `save_snapshot`, `restore_snapshot`,
  `snapshot_is_complete` (`game_state.gd` near 680-777), the `_dawn_*` copies and the lost day's
  give-back (near 158-180, 561-595), and the save's riders in `GameSave.run_data`/`restore_run_data`
  (`game_save.gd` near 515-566); a field missed in one is silently not given back or not saved.
  `PosterState` and `PelicanState` already have the right shape (`reset`, `photograph`, `give_back`,
  `to_data`, `restore`). `GameState.` is read over a hundred times in `main` alone. The 58
  `static var`s that hold hidden globals (`StreetNetwork._segments`, `SealPlanner._candidates`, the
  `AtlasLibrary` statics) are left out of this item, since they are the city's, the routes' and the
  art's rather than the run's.
- **One summary screen with four hand-reset modes** (`day_summary.gd`: `show_day_brief`, `show_day`,
  `show_ending`, `show_finale`); the screen's mode is tracked in `main`'s booleans. The resistance tally and the run-standing
  line are each formatted in two places.

**Build:** a `RunFlow` with an explicit mode enum and its transitions; a `DayDirector` with public
`start_day(spec)` and `finish_day(result)` that `main` and the tests both call; a pure `LossCause`;
one registered list of run sub-states with
the `PosterState` interface, injected rather than read from `GameState`; a pure `SummaryModel` the
screen only renders, and `continued(mode)`.

**Scene recipes become configurations of `RunFlow`.** The dev flags are one `RunConfig` read at boot
(`src/run_config.gd`), and these `_recipe` branches run through `main`'s flow: loading the
recipe and building its runtime in `_ready()`; the setup-failed early return after the first day
starts; `_recipe.begin()` in both boots and the escape boot's install block; the scripted capture
clock; `_city_map()` choosing the recipe's map; the escape boot taking its day only from a recipe;
the early return in `_plan_the_finale_city()`; the escape-section retry through
`lose_the_attempt()`; `_start_day()` branching to `_start_recipe_day()`; `_apply_recipe_teaching()`,
which writes the HUD's private fields (a dependency pointing up a layer);
`_hands_over_to_the_escape()` refusing for a recipe; the scene reload in `_on_summary_continued()`.

The developer readout, the return window and the rig lock as nodes of their own, and `--touch` and
`--web` as `RunConfig` values handed in, are built (minty-quail-11).
