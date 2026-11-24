# minty-quail — The last four test-only members are internal or gone · 2026-11-24

What the entry `tests-own-class-members.md` (curly-rabbit #1098: a public member only its own class
and the tests use becomes internal, its tests going through what the class does outward) left, and
what each became. The entry is closed. What holds after it: the CI check of test-only members
(`tools/check_test_only_members.py`) lists nothing under `[no reader]` and `[own file only]`, and
`tools/test_only_members.txt` holds the `[kept]` members, each with its reason on its line.

## What each member became

- **`ResistanceHappenings.column` is deleted.** Nothing but the tests read the trucks of day 13's
  column, and the game's own file only filled and cleared it. The trucks stand in the day's events
  (`EventManager.spawn_warned()`), so `tests/test_resistance_placement_kinds.gd` and the two probes
  under `tests/probes/` read them there, as the `military_convoy` events the real manager holds.
  Broken (one truck fewer sent), the suite fails its three column checks; restored, it passes.
- **`SummaryModel.kind` and the enum `SummaryModel.Kind` are deleted.** The builders set the field
  and nothing read it; the four summary suites' `kind ==` clauses asserted back what the builder had
  just set. The same checks keep their outward clauses (the title, the heading, whether it offers a
  continue), which already told the four screens apart.
- **`ReturnWindow.end()` is `_end()`.** Its tests let the window end the way the game does, a frame
  that reads the clock: a fake clock past the window's half second and two frames. The test's window
  runs always, as under `main`, so the pause screen's pause does not stop its frames. The suite that
  boots `main` puts the viewport's input back itself where it used to force the end. Broken (the
  frame no longer ends the window), the suite fails ten checks; restored, it passes.
- **`Footprint.tiles()` is deleted.** Nothing under `src/` called it; the game records a body's tiles
  through `StandingPiece.tiles()`. `tests/test_world_passability.gd` compares the plan's record with
  the instance's own standing pieces' tiles and lays the barrier's box down with
  `GroundShape.tiles_under()`. That body-and-record check now compares two readings of the same
  pieces, so it holds that the live instance and the plan agree, not that a third path does.

## Left as it was

`Crowd.step` and `ContactPoint.is_done` keep their `[kept]` lines, which defer to
`tests-one-module.md`: the rule that a test reads only through methods is still open there.
