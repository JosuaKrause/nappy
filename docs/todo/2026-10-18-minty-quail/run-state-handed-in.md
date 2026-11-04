# The run's state is made fresh and handed in, not a global

- **The tests still lean on a global run.** The run's state is held by the `Sitting`
  (`src/autoload/sitting.gd`, `Sitting.run`), and `main` takes it from there (`_take_the_run()`) and
  hands it to every reader it builds (record minty-quail-22); no class under `src/` reads the
  `GameState` autoload. It stays only as a stand-in for the suites not yet moved, about a hundred of
  which read or set it directly: the test runner hands it to every `Sitting` that enters the tree
  holding no run (`tests/run_tests.gd`, `_hand_the_stand_in()`; a suite that keeps its sitting off
  the tree and reads `GameState` beside its `main` hands it the stand-in itself), resets it before every suite
  (`GameState.start_run(RESET_SEED)`), and the shared-state check skips its parts.

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

**Where it stands:** the run is on the `Sitting` and the waves of `tests-public-seams.md` move their
suites onto a fresh run state, each giving its suites' `GameState` lines. A booted `main` is handed its run through `tests/seat.gd` (a fresh run, its home and a scratch-path save) or `Boot.home_playing()`, and a city through `RunCity.in_run()` or `with_own_run()`; the save suite plays runs of its own handed to `GameSave`, the day loop suite hands its run to the day's controller and the summary as `main` does, the visit counter is configured with a run of its own as `main` configures it, an event manager is handed a run through `use_run()` and a bare event world through its `run`, the member `EventManager.setup_world()` assigns, and the pause and title screens through `use_run()` and the summary through its parameter, as `main` hands them. While the stand-in exists a
held restart starts a fresh run in the same object (`start_run()`), not a new one, since a new object
would split the sitting's run from the stand-in. The last wave removes the `GameState` line in
`project.godot`, the runner's `_hand_the_stand_in()` and its reset of the stand-in (with its
`use_trace()` call and `VisitCounter.configure(null, GameState)`), `GameState` from the shared-state
check's autoloads and its skip; `RunState` then need not be a node, the sitting stops adding it as a
child, and a held restart gives the sitting a new run object.
