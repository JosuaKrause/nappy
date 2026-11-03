# The run's state is made fresh and handed in, not a global

- **The run's state is still a global** (`GameState`, `src/autoload/game_state.gd`, a `RunState`
  autoload). In the game only `main` takes it, once (`var _run: RunState = GameState`), and hands it
  to every reader it builds (record minty-quail-22); the autoload keeps the run across the reloads that carry it on (the day-14 hand-over, a run carried to its checkpoint), and a held restart throws the run away and starts a fresh one in it. The tests lean on
  it: about a hundred suites read or set `GameState` directly, and the test runner resets it before
  every suite (`tests/run_tests.gd`, `GameState.start_run(RESET_SEED)`), so the runner's
  shared-state check has to accept the run's fields that suites change.

**The ask.** Told that PR #976 lists 17 of the run's fields as exempt from the runner's leak check
because the runner puts them back before every suite, the player: "why would you put a state back
in a test? that doesn't sound right from the get go. the state is created fresh and injected for
every test", then "which item makes the game state not a global?"; told none does and what it would
cost, "yes, do it. consider it part of the refactor", and "so it comes before items that were
scheduled for after the refactor" (inbox #985 in round-egret).

**Read as:** every test makes its own run state and hands it to what it tests; nothing reads a
global run, so nothing has to be put back between tests. It is a step of this entry, done before the
entry closes and so before the work queued after the refactor.

**Build**, the orchestrator's proposal that the player said yes to ("yes, do it", inbox #985 in round-egret), not their own words: the run's state is held by the `Sitting` (`src/autoload/sitting.gd`), and `main` takes it from there and hands it down as it does now; the `GameState` autoload goes from `project.godot`. Each suite makes a fresh `RunState` and hands it in, directly to the part it tests or through the `Sitting` it hands a booted `main`; the runner stops resetting a global run, and its shared-state check accepts no run field.

It keeps what record minty-quail-fluffy-lark decided: that record put what outlives a held restart (the controls word, the restart stamp, the save symbol's home, `carry_the_run_over`) on a `Sitting` `main` parks rather than on `GameState`, because "a held restart throws the run away, and these facts outlive it". That stays true with the run on the `Sitting`: a held restart replaces the sitting's run with a fresh one and leaves its other facts as they are, while the hand-over and a carried run keep it. It keeps record minty-quail-41 as well: the run's calendar (`RunCalendar`) is built over the run's parts and moves with the run; only where the run is held changes.

*Proposed, not asked for:* the order, as told to the player when asked for the cost. One PR moves
the run onto the `Sitting` and keeps `GameState` only as a stand-in that suites not yet moved still
use, read by no game class; each wave of `tests-public-seams.md` moves its own suites onto a fresh
run state as it converts them; the stand-in, the runner's reset and any exemption of run fields go
when the last suite stops using it. Until then the runner's deeper check (#976) skips the run's
parts and names this item as the reason, rather than listing fields.
