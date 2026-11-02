# minty-quail — The resistance tests drive public seams: the director's seams, the rig and the three suites that leaned on test order (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`, the resistance rewrite's first pass: the director's public
seams, the shared rig and the three suites that leaned on test order. The item stays open for the
other eight resistance suites.

**Built.**
- `ResistanceDirector` gains `contact()`, `read_mark()` and `rider()` (what it has in the world),
  `use_steps(steps)` (a calendar handed in; the game never calls it and the director uses the run's
  own, `ResistanceSteps.all()`, every read of the calendar going through the one it holds; an empty
  calendar is refused), `guard_spot()`, and the statics `draw_reachable(candidates, rng, stands, open,
  used)` (the placement draw, moved out of `_pick_reachable()`), `touch_reach(instance)` and
  `pursuer_walker()`. `SceneRecipeRuntime` reads the public three.
- `tests/resistance_rig.gd`, `test_resistance_steps.gd`, `test_resistance_traps.gd` and
  `test_resistance_reach_contacts.gd` build each test's city in a run of its own, read a mark as setup
  through `contact().complete_now()` (the contact's own completion), step real frames for the touches
  they measure, find guards and pursuers on the street, and cross day 9's door through the events'
  `door_crossed` signal. Private reads: rig 6 to 1, steps 42 to 0, traps 75 to 2, reach_contacts 6 to 1.
- The three carried test-order dependences are gone, and a fourth: `_test_the_guard_is_seeded` ran on
  the day-14 city the test before it left and now builds its own. Each converted suite passes with its
  tests run in reverse order. The six alley tiles `traps` set are gone; from a clean process the test
  they were set for checks 97 times without them, so the 94 record -46 gives came from other leftover
  run state.
- Every test keeps its checks (the per-test table is in #961) but two: the guarded-targets test goes
  97 to 98, since day 9's second side is a second attempt at the day (a task is done once, and sending
  the trap again on a finished day cannot happen in play: the trap is sent only from
  `_on_contact_completed()`), and that crossing also checks that an inspected crossing completes the
  task; and `reach_contacts` gains a test that a real director hands the draw its own predicates
  (three checks).

**Open to overturn** (the builders' choices where the brief was silent): a mark read as setup uses
`complete_now()` rather than a touch; day 9's second side is a second attempt; look-alikes are placed
by a seeded draw over the step's own tiles rather than the private `_place()`; `use_steps()` as the
way a test offers a timed step.
