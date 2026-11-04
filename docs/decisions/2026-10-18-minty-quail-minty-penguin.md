# minty-quail — The save-wiring tests drive a booted main, and the save tests use GameSave's public calls (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_save_wiring.gd` and the save tests' private
`GameSave` calls. The item stays open for the resistance suites.

**Built.**
- `tests/test_save_wiring.gd` boots the real `scenes/main.tscn` as `test_main` does (`configure()`,
  `Main.use_reload()`, `Main.use_quit()`, real touches on the title and the summary's continue button,
  the pause screen's restart signal, the focus notifications, the day's end signal) and finds the save
  symbol as the booted `main`'s child. Its 16 checks are kept, mapped old to new in #960. The lines the
  item's first command counts (a private member read) go from 77 to 1, the reset of
  `TitleScreen._restarted_at_msec`. The suite takes about 22 s, about eleven boots.
- The two checks that read `main.gd`'s source are now behaviour: the booted `main`'s own symbol shows
  the deletion a resumed run's charge makes (it fails when the symbol is raised after the charge), and
  the held restart's "deleted the save" line lands in a memory log before the log closes.
- Whether the day is being walked is read as the tree not being paused (paused behind the title and
  the day brief), and a check that the brief holds the tree before its continue stands beside them.
- `GameSave._uses_save_override` is gone with no replacement. `test_finale.gd` boots under a windowed
  release configuration, `test_move_poses.gd` reaches its day through the `--day` dev flag with no
  save (a headless boot, which the game keeps off the save), and the `_write_now()`, `_read_now()`
  and `_clear_now()` calls in `test_park_return.gd`, `test_run_state.gd` and `test_finale.gd` go
  through `write()`, `try_resume()` and `clear()`.

**Open to overturn** (the builder's choices where the brief was silent): some checks read what the
game shows rather than `flow.mode`: the save's `day_under_way`, the summary showing, the tree not
paused, the ending's title; "closed between days writes nothing" watches the bus and the file's bytes,
since the file can no longer be removed before the boot.
