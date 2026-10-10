# A suite that boots a real main restores what it wrote

**Low · from the re-review of PR #590 (amber-quail, test_finale puts GameState.escape_section
back).** [Amber-quail](../../decisions/2026-10-05-amber-quail.md) says "A suite that boots a real
`main` restores everything `start_run()` writes", but `tests/test_frame_record.gd`'s
`_save_game_state()`/`_restore_game_state()` restore 11 fields, while `GameState.start_run()` also
writes `escape_section`, `play_seconds`, `city_state`, `posters`, `settled_in`, `fenced_park`,
`fenced_park_act`, `resistance_carrying_package` and `completed_resistance_alley_tiles`, and the
boot's `begin_day()` rewrites the dawn snapshot. A later suite in the same process that loses a day
without its own `begin_day()` gets the frame-record run's dawn back. Save and restore through
`GameState.save_snapshot()`/`restore_snapshot()`, as test_finale's hands-over test does, plus the
fields the save file leaves out.
