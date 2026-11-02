# minty-quail — The presentation-mode, meters and web-display suites drive public seams (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the presentation-mode, meters and web-display suites. The item
stays open for the touch, HUD and orientation suites.

**Built.**
- `test_presentation_mode.gd` reads each flag off the field of `RunConfig.parse(args, query,
  debug_build)` that the game reads, not `DevFlags`' private parsers; it adds the `?debug=1` gate for
  `?day=`, `?layers=` and `?escape=`, and `--day 4` with `?debug=1` and no `?day=` giving 4. The old
  "not given" sentinel for `?day=` (-1) is narrowed to its end value, since an absent `?day=` and
  `?day=1` both give day 1 and nothing observable differs.
- `WebDisplay.dpr_cap(config, on_web := OS.get_name() == "Web")`, which the game's `apply()` calls
  with the default; `test_web_display.gd` hands `on_web` in.
- `test_meters.gd` steps real physics frames with the baby in the tree; the whole of day 1's street
  walking and the park's 45 s walk-out run under `Engine.time_scale` (21x), restored before the next
  scenario; the bump loop is bounded and asserts the jolt has run down. A first pass drove the baby
  by hand through `Baby.step()`, a member only tests call; a second shortened the long scenarios,
  which let a walking gain that rises after the first minute pass; both were turned back in review.
- Private reads: presentation_mode 73 to 0, meters 3 to 0, web_display 11 to 0. Checks:
  presentation_mode 101 to 108, meters 126 to 128, web_display 12 to 15. The meters suite takes
  about 86 s where it took under one; its row in `tests/suite_costs.txt` stays stale until the
  cost table is refreshed.

**Open to overturn** (the builders' choices where the brief was silent): the long stretches under
`Engine.time_scale` rather than a hand-passed delta, which records -44 and -47 allow only when a real
frame's length is not the one the check means.
