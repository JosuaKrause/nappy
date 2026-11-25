# minty-quail — The controls' and the pause screen's suites are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin):
`typed-everywhere.md`, one pass per module. This pass is the view's controls and pause screen; its
search covers `TouchControls`, `ModeButton`, `PauseScreen`, `ControlsMode` and `ScreenOrientation`.

## What was built

- **Four suites parse without their file-level opt-out line**, which each loses: `tests/test_touch.gd`
  and `tests/test_orientation.gd` (`untyped_declaration`), `tests/test_pause.gd` (`untyped_declaration`,
  `unsafe_property_access`, `unsafe_method_access`) and `tests/test_held_restart.gd`
  (`unsafe_property_access`, `unsafe_method_access`).
- **Loop variables take their writers' types**; the day summary, whose script has no class name, is
  named through a preload of its script as `tests/booted_main.gd` names it; the title, pause and
  summary branches hold a typed local per screen and a `CanvasLayer` for what they share; a runtime
  load of the touch controls' scene is the file's own preload of the same scene.
- **No read is converted**: no method the game calls answers a field of the searched classes that
  the suites read or write. No check deleted or moved, nothing under `src/` or the rigs changed.

## Fields read and written, by class

Built with `tools/field_answers.py --counts` on the four files, each named method read in its class.

- **`ModeButton`** (searched): `hold_progress`, read → no method; written (the setter's clamp, at
  5.0 and -2.0) → `begin_hold()`, `end_hold()` and `cancel_hold()` assign only 0.0, so none is the
  test's write, and the check holds the clamp nothing else covers; `symbol`, written → no method (an
  export the scenes set).
- **`TouchControls`** (searched): `covering` → no method; `rotated`, written → no method (the game's
  `main._apply_orientation()` writes the field itself); `_FOCUS_KNOB_OFFSET` and `_FOCUS_KNOB_RADIUS`
  stay read, as `tests-public-seams.md`'s open entries name.
- **`HelpText`**: `line` → no method.
- **`RunCalendar`**: `hard_mode`, written → `choose_mode()` assigns it.
- **`RunHeader`**: `day`, `nerves`, written → `reset()` and `restore()` assign them; neither sets an
  arbitrary value.
- **`RunState`**: `calendar`, `header` → no method.
- **`ScreenCover`**: `in_force` → `is_in_force()`; `left` → `left_corner()`; `right` →
  `right_corner()` (not this pass's search; they stay for the pass that owns it).

## Verified

At test parity: the four suites pass; the typing census, the field-read and the test-only-member
checks pass.
