# minty-quail — Every suite takes the typed runner, by one script · 2026-11-11

**The ask.** "we type when we can" (inbox #1280 in olive-ferret), and the runner's class name
(inbox #1282). The scripted rewrite is the orchestrator's proposal, put to the player with the count
before those words; the words do not name it. The plainer alternative was to leave every test file
until its suite is converted.

## What was built

- **Every function handed the runner takes `t: TestRunner`**, 2987 lines in 352 files, 20 of them by
  hand and the rest by a script. No line under `src/` changed.
- **Each test file's opt-out line names only what the file still trips**, by
  `tools/typing_census.py --write`: 136 test files lost the line, and 230 still carry one.
- **A function is taken to hold the runner by what it does with `t`**: it calls `t.check(` or
  `t.close_to(`, or the Node calls the runner exposes, or hands a bare `t` on to a function already
  known to take it. What the pattern cannot tell the script prints, and those were done by hand.

## What a later branch owes

The script and the census commands are in the description of #1339. The script is idempotent, and a
branch that merges this and edits a suite reruns both. It prints only a function that needs work by
hand.

**A parameter is `TestRunner` wherever every caller hands the runner, and `Node` where one hands
anything else.** The script first typed the helpers of `tests/physics_ticks.gd` as the runner. The
census then failed two suites, because `test_meters` hands them a `Baby` and
`test_scene_recipe_stretch_crowd` a `Crowd`. A rerun's load failures show any more of these where
the caller's argument has a static type; an untyped argument fails when the suite runs.

## Left as they were

Functions already typed `t: Node` that anchor on any node;
`_see` in `tests/test_ground_floor.gd`, which returns a value and has no return type;
`_is_really_on_screen` in `test_resistance_traps.gd`, typed though nothing calls it; and the two
suites whose `PROBE` constants hold a script's source as a string.

## Verified

`tools/typing_census.py --check` reports no file that fails to load, and CI's whole run passes
every suite. Nothing under `src/` changed, so the identity probes do not apply.

## Open to the player's overturn

- **The scripted rewrite itself**, as above.
- **Typing a helper by what it does with `t`**, and leaving what the pattern cannot tell to be done by
  hand.
