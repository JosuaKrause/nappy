# minty-quail — The crowd's coverage check moves to a crowd suite · 2026-11-12

**The ask.** A suite tests the one module it is named for (`tests-one-module.md`), and the scene recipe's crowd suite
held a check of the crowd's own behavior, queued to move to a crowd suite.

## What was built

- **`tests/test_recipe_crowd.gd` becomes `tests/test_crowd_coverage.gd`**, its checks word for word: every one was the
  crowd's (`Crowd.recipe_coverage()`, the field covering the whole map, the population per covered area, motion under
  production signals, the normal field restored), and none the scene recipe's. Its row in `tests/suite_costs.txt` moves
  with it, and its header says why it builds a real city: coverage and motion exist only against a city's own map,
  streets and signals.
- **It is renamed, not folded into `test_crowd_field`**, a suite split with its cases in `tests/crowd_rig.gd`, where
  the move would add a second city build.
- **The queue item loses the two clauses that queued the move.**

## Verified

The two crowd suites, `tools/check.sh` and the field-read, test-only member, layer and typing checks pass; CI is green.
