# minty-quail — The catalogue and drawn view suites read the pictures through what the game asks (tests through public seams: W8a) · 2026-11-04

minty-quail's `tests-public-seams.md`: the event picture suites, first half, subtask W8a of the
scoped plan. No `src/` change and no seam added; `test_event_redraw.gd` is untouched.

**Built.**
- `test_events_catalogue.gd` (private-read lines 14 to 7) finishes an instance with
  `leave_for_a_completed_task()`, the call a resistance step's contact makes, reads a row's role off
  the `Planned.role` that `recipe_placement()` returns (as grassy-sparrow did), and a spread's axis
  off `runs_vertically()` on an instance set up at that point of the map.
- `test_drawn_view.gd` (11 to 4) checks the car and the walker at `LaneMover`'s default speed
  instead of writing their speed, and finds the street fire's front on a map whose twenty-tile
  building stands only inward of the sidewalk, read through `drawn_rect_now()` and the redraw gate.
- Checks 1057, 293 and 152 to 1057, 294 and 152; seven mutation runs.

**Weighed and dropped:** counting the caret's asks through a stand-in source swapped into the agent's
and the instance's `excitement`, since no game class assigns that member: a test-only door. The
caret's cache key stays a private read instead.

**Not done:** `test_drawn_view.gd`'s caret cache key and cyclist picture key, which no game class
reads, and `FireLook`'s private size constants; `test_events_catalogue.gd`'s `_cap_along`, `_cap_offset`, `_cap_sides` and
`_wide_scene_anchor`, the sprite rectangles a look draws, which want a reader of what a look draws
that a game class calls; `test_event_redraw.gd`'s gait and caret writes, which pin a picture state,
left as the plan says.
