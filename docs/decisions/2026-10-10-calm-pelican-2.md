# calm-pelican — A suite that boots a real main restores what it wrote · 2026-10-10

From the re-review of PR #590 (amber-quail, test_finale puts GameState.escape_section back): the
record [amber-quail](2026-10-05-amber-quail.md) says "A suite that boots a real `main` restores
everything `start_run()` writes", while `tests/test_frame_record.gd` restored 11 fields and left
`play_seconds`, `city_state`, `settled_in`, the dawn snapshot and five fields the save file leaves
out for the next suite in the same process.

**Built in PR #640.** `_save_game_state()` and `_restore_game_state()` go through
`GameState.save_snapshot()` and `restore_snapshot()`, which cover every saved field and the dawn
photograph, and carry beside it the fields the snapshot leaves out: `escape_section`, `posters`,
`fenced_park`, `fenced_park_act` and `completed_resistance_alley_tiles`. The real-main test ends by
checking that a fresh save equals the one taken before it, comparing whole dictionaries so a field
added to the snapshot later is covered too (the agent's addition, open to overturn). Cut back to
restoring day and nerves only, that check fails; with the fix, the frame-record suite and the
finale, invincible, orientation and day-loop suites pass together. Amber-quail's sentence is true
again.
