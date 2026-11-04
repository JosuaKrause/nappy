# The run's state is made fresh and handed in, not a global

- **The run is still a node, and a held restart reuses it.** The run's state is held by the
  `Sitting` (`src/autoload/sitting.gd`, `Sitting.run`), and `main` takes it from there
  (`_take_the_run()`) and hands it to every reader it builds (record minty-quail-22); every suite,
  helper and probe makes a fresh `RunState` and hands it in, and the `GameState` autoload is gone,
  so the test runner resets no global run and its shared-state check skips no run field. What is
  left: `RunState` (`src/autoload/game_state.gd`) is a `Node` the sitting holds as its child,
  where nothing needs a node; a held restart starts a fresh run in the same object
  (`start_run()`) rather than handing the sitting a new one; and the file is still under
  `src/autoload/`, named for the autoload it no longer is.

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

**Where it stands:** the stand-in is gone (record minty-quail-feathery-llama). Left, each a
change of its own: `RunState` as a `RefCounted`, which drops the sitting's `add_child()` of it and
the suites' frees of their runs; a held restart handing the sitting a new run object, cheaper once
the run is not a node; and `game_state.gd` renamed for what it holds and moved out of
`src/autoload/`, every reference to its path with it.
