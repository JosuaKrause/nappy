# minty-quail — The arrow suite drives public seams: the director's arrow queries (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: `tests/test_resistance_arrow.gd`, the red arrow. The item stays
open for the other resistance suites and the arrow privates other files still reach.

**Built.**
- `ResistanceDirector` gains read-only queries beside the privates they read: `mast_in_play()`,
  `arrow_key()`, `arrow_targets()`, `arrow_nearest_at()`, `arrow_lead_at()` and `arrow_sweeping()`.
- Each test builds its own city in a run of its own, settles the arrow the way `main` drives it each
  physics tick (`retarget_the_arrow()` and `tick()`, until it stops sweeping), and touches through a
  real physics frame. The suite reads no private member of the director and passes with its tests
  reversed.
- Checks go from 89 to 92: the four-tiles and three-tiles test is two tests, each owning a city
  (one more open-run check), and the freed-instance test gains "the task rides the far man" and "the
  sweep starts the frame after the instance goes", which catches a `tick()` that no longer retargets
  at once when the arrow's target is freed (the old suite did not).
- Breaking the hold by one tile, the re-sweep when what blocks her changes, the arrow kept after the
  contact is done, the following between masts on day 11, or the immediate retarget each fails the
  suite.

**Open to overturn** (the builder's choices where the brief was silent): settling the arrow by ticking
until it stops sweeping, bounded at 1200 ticks.
