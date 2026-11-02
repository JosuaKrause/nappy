# minty-quail — The save-wiring tests drive a booted main, and the save tests use GameSave's public calls (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_save_wiring.gd` and the save tests' private
`GameSave` calls. The item stays open for the resistance suites.

**Built.**
- `tests/test_save_wiring.gd` boots the real `scenes/main.tscn` as `test_main` does (`configure()`,
  `Main.use_reload()`, `Main.use_quit()`, real touches on the title and the summary's continue button,
  the pause screen's restart signal, the focus notifications, the day's end signal) and finds the save
  symbol as the booted `main`'s child. Its 16 checks are kept, mapped old to new in #960; private
  reads go from 84 to 1 (`TitleScreen._restarted_at_msec`). It takes about 22 s, about eleven boots.
- The two checks that read `main.gd`'s source are now behaviour: the symbol hears the deletion a
  resumed run's charge makes, and the held restart's "deleted the save" line lands in a memory log.
- `GameSave._uses_save_override` is replaced by `GameSave.use_gate(gate: Callable)`, empty by default,
  which answers `uses_save()`; `test_finale.gd` and `test_move_poses.gd` use it. The `_write_now()`,
  `_read_now()` and `_clear_now()` calls in `test_park_return.gd`, `test_move_poses.gd`,
  `test_run_state.gd` and `test_finale.gd` go through `write()`, `try_resume()` and `clear()`.

**Open to overturn** (the builder's choices where the brief was silent):
- `use_gate()` is a seam only tests call; a save policy `main` hands to `GameSave` would be one the
  game uses too, and is a larger change to `main`.
- Some checks now read what the player sees rather than `flow.mode`: the save's `day_under_way`, the
  summary showing, the day running, the ending's title; "closed between days writes nothing" watches
  the bus and the file's bytes, since the file can no longer be removed before the boot.
