# minty-quail — Four members nothing calls are deleted, and the calm areas' floor is checked again · 2026-11-10

**The ask.** "remove dead code or code needed for features that don't exist anymore" (inbox #1180
in gray-dolphin). The dead-code sweep's survey had taken a name in a comment for a use; with
comments stripped, four members had no caller, and one pair of functions claimed a check that did
not exist.

## What was built

- **Deleted, each with what called it last:**
  - `TouchInput.is_press()`: the pause screen and the day summary, until their press branches were
    split into a touch shape and a mouse shape (fe5afa90d, M211 and M212).
  - `Tuning.TELEGRAPH_TIME_DEFAULT`: nothing ever read it.
  - `RunState.city_rng()`: nothing ever called it; the city is generated from `header.run_seed`.
  - `RunState.restore_snapshot()`: the save, until it restored through the registry's own
    `restore_state()` (#919), and the tests, until #1096.
- The comments and the `docs/ARCHITECTURE.md` sentence that named them say what is true: the
  three screens read touch and mouse apart, with the mouse branch gated on `not _touch`.
- **The calm areas' floor gets its check back.** `Tuning.calm_areas_needed()`'s comment said
  `CityGenerator.MIN_CALM_BLOCKS` was asserted against it on boot, and no assert existed.
  `tests/test_tuning_fairness.gd` now asserts `MIN_CALM_BLOCKS >= calm_areas_needed()` beside
  `Tuning`'s other fairness floors: an act's worth of calm areas plus one keeps the last day of an
  act winnable. Both numbers are 5 on `main` (the longest act is four days, plus one in reserve).
  `calm_areas_needed()` and `longest_act_days()` stay, each with a line in the kept group of
  `tools/test_only_members.txt` saying the test holds the relationship, and both comments say so.
- `dead-code-sweep.md`'s method says a name in a comment is not a use.

## Parity

The diff under `src/` is deletions and comments only, so the identity probes were not run.

## Open to the player's overturn

- **The floor's check**, the orchestrator's ruling: the plainer alternative was to delete the two
  functions and the comments' claims, leaving `MIN_CALM_BLOCKS` authored on its own.
