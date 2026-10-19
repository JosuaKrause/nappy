# frosty-hare — The title names the mode once it is decided · 2026-10-18 · not from an entry


The player: "the title screen should show the mode name (Normal / Hard Mode) if the decision is
already made (eg loading a save)" (minty-lemur #784).

**Built (PR #786).** `TitleScreen.open()` takes `mode_decided`; when it is true and the title is not
starting a new game, a `ModeName` label in the title scene (beside `HardMode`, in its place) shows
"Normal" or "Hard Mode" (`Texts.TITLE_MODE_NORMAL`, `TITLE_MODE_HARD`). A resumed day or escape shows
the name; a new game shows the checkbox as before; the `--start-escape` epilogue shows neither.
`tests/test_pause.gd` pins both names and the new-game case; `tests/test_run_checkpoints.gd` and one
line in `tests/test_finale.gd` pin `main`'s two call sites.

**Choice open to overturn:** the name stands where the checkbox would, since the two never show
together.
