# minty-quail — Every suite takes the typed runner, by one script · 2026-11-11

**The ask.** "we type when we can" (inbox #1280 in olive-ferret), and the runner's class name
(inbox #1282). The scripted rewrite is the orchestrator's proposal, put to the player with the count
before those words; the words do not name it. The plainer alternative was to leave every test file
until its suite is converted.

## What was built

- **Every function handed the runner takes `t: TestRunner`**, 2975 lines in 350 files, about 2956 by
  a script and 19 by hand. Where such a function had no return type and returns no value it gained
  `-> void`. No line under `src/` changed.
- **Each test file's opt-out line names only what the file still trips**, by
  `tools/typing_census.py --write`: 131 test files lost the line, and 235 still carry one.
- **A function is taken to hold the runner by what it does with `t`**: it calls `t.check(` or
  `t.close_to(`, or the Node calls the runner exposes, or hands a bare `t` on to a function already
  known to take it. What the pattern cannot tell the script prints, and those were done by hand.

## What a later branch owes

The script and the census commands are in the pull request's description. It is idempotent, and a
branch that merges this and edits a suite reruns both.

**A helper that only anchors on a node is typed `t: Node`, not `TestRunner`.** The script first typed
the helpers of `tests/physics_ticks.gd` as the runner. The census then failed two suites, because
`test_meters` hands them a `Baby` and `test_scene_recipe_stretch_crowd` a `Crowd`. A rerun's load
failures show any more of these.

## Left as they were

Functions already typed `t: Node` that anchor on any node, which the script lists each run;
`_see` in `tests/test_ground_floor.gd`, which returns a value and has no return type; and the two
suites whose `PROBE` constants hold a script's source as a string.

## Verified

`tools/typing_census.py --check` reports no file that fails to load, and CI's whole run passes
every suite. Nothing under `src/` changed, so the identity probes do not apply.

## Open to the player's overturn

- **The scripted rewrite itself**, as above.
- **Typing a helper by what it does with `t`**, and leaving what the pattern cannot tell to be done by
  hand.
