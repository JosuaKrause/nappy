# main.gd split into an explicit run flow, and run state kept in one place

- **`src/main.gd`** (3,203 lines, about 70 fields) owns boot and resume (with
  `static var _carry_the_run_over`), each day's construction (`_start_day`, about 20 ordered calls),
  the escape flow, the loss cause (near 2171-2254), play time, the debug readout, web focus and
  return, rig timers and save timing. Its modes are implicit: `_process` branches on which of
  `_finale`, `_interior`, `_in_the_title` are null, and `_on_summary_continued` (near 2371) sends one
  `continued` to six outcomes decided by `_recipe`, `escape_section`, `_resume_gate_open`, `_run_over`,
  `_went_back`, `_ending_shown` (seven with `_finale_brief_open`). `tests/test_resistance.gd` (near
  3414) copies `_start_day`'s order because it lives only in a private method.
- **Run state is kept by hand in up to six places per field:** `save_snapshot`, `restore_snapshot`,
  `snapshot_is_complete` (`game_state.gd` near 680-777), the `_dawn_*` copies and the lost day's
  give-back (near 158-180, 561-595), and the save's riders in `GameSave.run_data`/`restore_run_data`
  (`game_save.gd` near 515-566); a field missed in one is silently not given back or not saved.
  `PosterState` and `PelicanState` already have the right shape (`reset`, `photograph`, `give_back`,
  `to_data`, `restore`). `GameState.` is read 122 times in `main` alone, and 58 `static var`s hold
  hidden globals (`StreetNetwork._segments`, `SealPlanner._candidates`, the `AtlasLibrary` statics).
- **One summary screen with five hand-reset modes** (`day_summary.gd` near 108-313: `show_day_brief`,
  `show_day`, `show_ending`, `show_finale`, `show_finale_brief`); `show_finale` never hides the note
  line; the screen's mode is tracked in `main`'s booleans. The resistance tally and the run-standing
  line are each formatted in two places.

**Build:** a `RunFlow` with an explicit mode enum and its transitions; a `DayDirector` with public
`start_day(spec)` and `finish_day(result)` that `main` and the tests both call; a pure `LossCause`;
the debug readout and web lifecycle as their own nodes; one registered list of run sub-states with
the `PosterState` interface, injected rather than read from `GameState`; a pure `SummaryModel` the
screen only renders, and `continued(mode)`.
