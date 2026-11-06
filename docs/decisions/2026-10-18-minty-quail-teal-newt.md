# minty-quail — Tests touch nothing real: the frame recorder's folder is handed in · 2026-11-06


The player's ask: tests touch nothing real, everything mocked or in a test state, no runtime guard
(inbox #984 in brisk-pelican).

**Survey.** Every suite that boots `scenes/main.tscn` (through `tests/booted_main.gd`, `tests/seat.gd`,
`tests/finale_rig.gd` or its own) already hands the boot a `GameSave` at a scratch path; every
`GameSave.new` in `tests/` takes a scratch path; every other `user://` name under `tests/` is a
scratch file or folder. Two things still named the player's folders:

- the frame recorder, which built `user://frame-records/record-...json` itself when its sitting
  had no path yet, so a suite that booted `main` under `--frame-record` without presetting a path
  would have written there;
- `test_scene_recipe_activity.gd`, whose child processes boot `main` on a recipe; a recipe run
  already uses no save, and it now also passes `--no-save`.

**Built.** `FrameRecorder.setup()` takes the records folder; `main` hands it `FRAME_RECORDS_DIR`
(`user://frame-records`) unless a test handed it another through `use_frame_records_dir()`.
`test_frame_record.gd` hands scratch folders and no longer presets the sitting's path.

**Left alone.** The manual probes under `tests/probes/` that instance `main` run on dev flags, which
use no save; they are not suites.

**Rejected.** A guard in the save or the recorder that refuses the real path under test (the player
asked for none).
