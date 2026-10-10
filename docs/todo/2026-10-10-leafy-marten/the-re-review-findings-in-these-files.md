# The re-review's findings in the controls' files

From the re-review of PR #603 (round-gecko, the unused joystick becomes Run), in files this entry
rewrites, so they are built with it.

- **Nothing of the pre-selection state survives:** today joystick mode shows two rings and no Run
  before the first press, which leaves a player steering with keys without Run while the help text
  says "hold {run}", against `src/ui/hud.gd`'s "a symbol for a button that is not on screen would point at nothing"),
  and a first press on Run's side never steers.
- **Docs say one steering ring with a knob and one Run disc:** `docs/MECHANICS.md` ("Both rings
  always show that same heading", and the paragraph describing swapping), the touch-controls
  paragraph in `docs/ARCHITECTURE.md`, the art/ui row in `docs/GRAPHICS.md`, the doc comments in
  `src/ui/controls_mode.gd` and `src/ui/touch_controls.gd`, `src/events/encounter_watch.gd` ("rings
  and run buttons"), `src/ui/pause_screen.gd` and `src/ui/hud.gd` ("draws run buttons"), and
  `tests/test_touch.gd` ("both circles").
- **Comments a rename left wrong:** `src/ui/title_screen.gd` ("inside
  `_joystick_button.contains_design_point()`"), `tests/test_pause.gd` ("whatever rect" and
  "`contains_design_point()` centre"); say "the button's round catch" or "the button's centre".
  `TouchControls.RUN_CATCH_RADIUS` is unread while `run_button_at()` recomputes it: use it there or
  delete it.

The catch sizes themselves are calm-pelican's question for the player
([button-catches-shrank.md](../2026-10-10-calm-pelican/button-catches-shrank.md)), not this item's.
