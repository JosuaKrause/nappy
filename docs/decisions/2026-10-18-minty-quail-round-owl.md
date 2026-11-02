# minty-quail — The alley-siting suite drives public seams: the director's guard-placement draws (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_resistance_alley_siting.gd` and the director's
guard-placement draws. The item stays open for the reach suites and the reads other files still make.

**Built.**
- Seven of the director's private draws are public, renamed in place: `guard_position()`,
  `draw_guard_position()`, `alley_ends()`, `place_contact()` (was `_place()`), `nearest_alley_within()`,
  `mark_tiles()` (a copy; the director's own readers use the field) and `weighted_mast_index()`; and
  `nearest_alley_among(candidates, here)`, which `nearest_alley_within(here)` calls over the director's
  own marks, so a test hands it the pool it asks about, as `draw_reachable()` takes its candidates.
- Each test builds its city, or a bare map, in a run of its own; the robber is woken and put back to
  sleep through `EventInstance.step()` with her position set. The suite reads no private member (24
  lines before) and passes with its tests reversed; `replacement`'s three director-draw tests moved
  onto the same queries.
- Checks: alley_siting 32624 to 32630 (the relocated-mark test 1 to 4, which picks its cases without
  the avoidance it tests, so breaking the avoidance fails only "avoids the used alley"; the
  guard-moves-with-the-mark test 5 to 6; the guard-in-view-or-awake test 7 to 9). The covered-corner
  sweep keeps all 259 cases and its exact assertion (nothing placed under the covered corner) through
  `nearest_alley_among()`; removing the view refusals fails all 259.

**Open to overturn** (the builders' choices where the brief was silent): the renames done in place;
the courtyard test reached through `guard_spot()` and `guard_position()`; the robber woken through
`step()`; handing the pool rather than a per-tile query.
