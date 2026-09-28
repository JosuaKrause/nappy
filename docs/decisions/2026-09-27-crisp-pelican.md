# crisp-pelican — A won day gives a nerve back · built 2026-09-27

*([pebbly-penguin](../playtests/2026-09-27-pebbly-penguin.md): "a won day recovers a nerve up to the
max" · "that way you can recover from a bad single day without being in a tight spot towards the end
of the game")*

**Overturned by the player:** `docs/MECHANICS.md` said "Nerves never regenerate — this is what makes
an early bad day matter".

**Built (PR #420).** `GameState.regain_a_nerve()` adds one nerve, never past
`Tuning.STARTING_NERVES` (5), on every ordinary won day; a lost day still costs one. `finish_day()`
calls it unless an escape section is running, and day 14, whose win hands over to the escape
without passing through `finish_day()`, calls it in `main._on_day_finished()` before the summary
reads the count. The escape has no nerves (`docs/MECHANICS.md`: a lost section "costs no Nerve"),
so its sections and its completion give none. Tests in `tests/test_day_loop.gd` and
`tests/test_save.gd`.
