# M102, the escape has what a day has around it — the pause screen, open over the building

One `tools/shot.sh` capture on `feature/m102-escape-pause`, 1280×720, `--start-escape --invincible`,
the escape's own brief dismissed with `--press ui_accept 0.5` and Esc pressed at `--press pause 2`.

- `pause-over-building.png` — the same `PauseScreen` a day opens, open over the third-floor hallway
  she is already standing in: the same `"Tap to walk, double tap to run."` body, the same
  continue / hold-to-restart pair, and the HUD's own hint line — *"Escape the building"* — still
  showing faintly through the dim behind it, because the HUD keeps running through a pause exactly
  as it does on a day. The debug-only header (`day 1 / 14  act 1  nerves *****  INVINCIBLE`) is the
  same furniture `tools/shot.sh` rigs always carry on a debug build; the escape has no day or act of
  its own to report through it.

`tests/test_finale.gd` is the actual verification — that the pause opens on `Esc`, the pause
button's own action and a window losing focus, the same way a day's does; that it does not open
over a section's brief or the epilogue; that `--no-focus-pause` suppresses the focus-loss case; and
that `FinaleController`, the interior scene and the finale city all stop processing the instant the
tree pauses. This capture is what a person looking at the screen sees, which a headless assertion
cannot show.
