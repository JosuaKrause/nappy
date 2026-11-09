# Five sentences that say something the code does not do

Found while the skills were checked against the code:

- `tests/test_events_costs.gd`'s header says it holds "nothing happens inside a lethal field"; its
  tests hold only who is exempt.
- `src/routes/route_tree.gd` names `Tuning.MIN_CALM_AREAS_REACHABLE`; the constant is the closure
  planner's.
- `src/events/behaviours/event_flock.gd` says the world sums what each source charges her; the
  baby does.
- `src/city/city.gd`, the docstring of the resistance package's decay multiplier, gives a main
  road's own multiplier as 0.6; the constant is 0.02.
- `docs/TELEMETRY.md` says `draw_kind()` where the method is `FrameRecorder._draw_kind()`.

**Build:** each sentence says what is true. The refactor's own rule brings the comments of a file
it touches to the present tense (`docs/todo/2026-10-18-minty-quail/comments.md`), so whichever
reaches a file first fixes its sentence, and this item closes with what is left.
