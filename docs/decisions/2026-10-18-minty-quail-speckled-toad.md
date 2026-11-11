# minty-quail — The runner and the booted game's rigs are typed · 2026-11-11

**The ask.** Test code is typed as the code it tests is ("we type when we can", inbox #1280 in
olive-ferret), and a test reads its subject only through methods (inbox #1182 in gray-dolphin): one
pass of `typed-everywhere.md`'s "What is untyped in a test goes as its suite is converted", cut by
the typing plan of 2026-11-11 into file-disjoint passes.

## What was built

- **The runner, the shared-state check and the booted game's rigs are typed and lose their opt-out
  line**: `run_tests.gd`, `shared_state.gd`, `booted_main.gd`, `seat.gd`, `full_run_rig.gd`,
  `test_main.gd`, `test_run_config.gd` and `test_presentation_mode.gd`. Each rig function keeps its
  name, argument order and answer; nothing under `src/` changed.
- **A booted game is held as `main.gd` preloaded as a constant** in `booted_main.gd`, since
  `main.gd` has no class name, so the hand-ins a test makes on it are typed calls; the rig helpers
  keep their `Node` parameters.
- **The runner calls a suite's `run` through `call()`**, since the suites share no base class; its
  exit codes and its load-failure path are unchanged.
- **The full run's freed-instance loop takes its key as a `Variant`**, checked with
  `is_instance_valid()` and cast after: a typed loop variable fails on an instance freed during the
  run, which CI showed in two of the full-run suites.

## Left, each with its reason

- **Search: none.** No class was this pass's to search, so no read was converted.
- **Other modules' fields stay for their passes.** Pull request #1357's description lists them by
  class, inner classes included, each with the method the game calls or "no method".
- **`main.gd` has no class name**; giving it one is a change under `src/` for the root's pass.

## Verified

Every suite that loads `booted_main.gd` or `seat.gd`, directly or through a rig, passes, and the
runner's three fixtures exit as before; `tools/typing_census.py --check` holds. No check was
deleted or moved.
