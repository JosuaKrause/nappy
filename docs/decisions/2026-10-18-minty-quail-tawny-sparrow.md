# minty-quail — The event suites hand the event manager its world instead of writing its fields (tests through public seams) · 2026-11-05


minty-quail's `tests-unseen-reads.md`, section 2.2's sites left after the event manager suites: six
suites wrote `EventWorld` fields the manager's own setup sets. Tests only; no `src/` change.

**Built.**
- `test_event_behaviours.gd` hands its manager a world through `setup_world()` over open ground.
- `test_event_manager.gd` sets the day through `start_day()`, and the restoring write at its end goes,
  since each test builds its city fresh.
- `test_pursuer_on_foot.gd` and `test_patrol_vanish.gd` set the day through `start_recipe()` with no
  plans, and the pursuer suite sets the manager's `trace`; the patrol suite puts the lights out
  through `Blackout.go_dark()` where it cleared the world's signals by hand.
- Every suite's check count is unchanged; they pass shuffled and repeated.
- `test_invincible.gd`'s `noise` and `test_excitement_source.gd`'s `excitement_sources` stay: the first
  is the suite's own fake world's state, the second the hand-in `main.gd` and `City` make.

**Open to overturn:** `start_recipe()` with no plans rather than `start_day()` for the two city rigs,
since a planned day's events, seals and doors changed their encounters (nine and two checks failed);
its side effect, a recipe-plan flag that stops the ambient directors and the return hook, touches
nothing those rigs use. `go_dark()` also marks buildings unpowered and signals the city gone dark,
which nothing in the suite reads.
