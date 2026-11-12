# minty-quail — The screens and controls are typed · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module. This pass is the screens and
controls (`src/ui/`, the view layer). Its search is none: it types and deletes lines and converts no read.

## What was built

- **Five files parse without their file-level opt-out line**: `src/ui/mode_button.gd` (`untyped_declaration`),
  `pause_screen.gd` and `title_screen.gd` (`unsafe_property_access`), `return_window.gd` (`unsafe_property_access`,
  `unsafe_method_access`) and `touch_controls.gd` (`untyped_declaration`, `unsafe_property_access`); none after.
- **Typing**: a key event's `pressed` is read through `as InputEventKey` after the `is` test that guards it (an `is`
  inside an `and` does not narrow the next operand), once each in the pause screen and the touch controls and twice
  in the title screen; the touch controls' four move actions loop as `StringName` and the mode button's six theme
  colour names as `String`; the title screen's `_place_column()` takes the `VBoxContainer` the scene hands it, and the
  mode button reads its old letter child as the `Label` it is.
- **The return window calls the browser page by name.** It reaches the page's `document` and `window`
  (`JavaScriptObject`s) through `call("addEventListener", …)`, `call("removeEventListener", …)`, `get("type")` and
  `get("visibilityState")`, a comment at the first call saying why: the engine declares none of a page object's
  members, so no typed call parses on any receiver. A page object is no class under `src/`, so nothing is hidden from
  the field-read check, and typed files already use the form (`FrameRecorder` calls `window.call(...)`, `GameSave`
  `_window.call(...)`). The orchestrator accepted it over keeping the file's opt-out line, the brief's rule against
  calls by name being there to keep reads of the game's classes visible.
- **Left**: `TouchControls._rig` stays a `Node2D`. In the game it holds her stroller and reads only the engine's
  `global_position`, but `test_touch`, `test_pause` and `test_orientation` put a bare `Node2D` in the "player" group,
  for which a `Stroller` cast would leave it null and steering ignored; `current_heading()`, the heading the steering
  ring's knob is drawn at, keeps its `has_method(&"is_detained")` and `call(&"is_detained")` for the same reason. Both
  go with those suites' conversion to public seams (`tests-public-seams.md`), when they hand in a real stroller or a fake
  of it. The title screen's two reads of the run's hard mode (`_run.calendar.hard_mode`) were already listed and wait on
  `field-reads.md`'s "A run's parts": no method returns `RunState.calendar` or `RunCalendar.hard_mode`, which the
  public `choose_mode()` writes.

## Fields read and written, by class

`tools/field_answers.py` on the five files, as it prints them at 485eafd1c, each named method read in its class.

Fields of classes under `src/` that `src/ui/mode_button.gd`, `src/ui/pause_screen.gd`, `src/ui/return_window.gd`, `src/ui/title_screen.gd`, `src/ui/touch_controls.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `RunCalendar`: `hard_mode` read (`src/ui/title_screen.gd`:256,259): no method
- `RunState`: `calendar` read (`src/ui/title_screen.gd`:256,259): no method


## Verified

At parity: `tools/check.sh` boots clean; the field-read check against `origin/main` sees no new read; the typing census
passes; the screens' suites and those that load the five classes pass; CI is green.
