# minty-quail — Tests that hold nothing are kept out: the four kinds in the testing rules, and a CI check of test-only members · 2026-11-05



minty-quail's `tests-kept-out.md`: after the player asked for an audit of the tests for checks that
hold nothing, "let's make sure those tests also won't enter the codebase again" (curly-rabbit
#1097). The mechanism is the orchestrator's proposal, open to the player's correction.

**Built.**
- **verify**'s testing policy names the four kinds the player quoted back: a state only the test
  can create (input the game does not control excepted), a design decision read back, a check that
  cannot fail (asserting back what the test set itself among them), and a duplicate. It carries the
  rule for a member with no reader (curly-rabbit #1095, with its two-part exception and its remark
  that a kept one may hint at a module's design) and for a function only its own file and the tests
  use, which is internal (curly-rabbit #1098, with its exception for a function nothing outside can
  confirm, its reason written down). Extending that rule to variables and signals, exempting
  constants, and keeping the dependency hand-ins public are marked as the orchestrator's.
- **pr-review**'s code checklist names the four kinds and points at that policy: the reviewer is who
  catches the three a script cannot.
- `tools/check_test_only_members.py`, in CI's `gates` job, fails a test that reads a public member
  no other file under `src/` uses: a function only as a call, a caller under `src/dev` counting and
  one in the member's own file not, a small set of engine member names never taken as a read.
  `tools/test_only_members.txt` lists those that stand in groups, each opened by a `# [tag]` header:
  no reader and own file only, which only shrink and fail on a stale line, and kept groups whose
  lines carry their reasons (the three fairness helpers of Tuning; eleven dependency hand-ins; an
  empty one for a function nothing outside can confirm or a line the check misreads). With
  `--base <commit>`, which CI gives the pull request's base (the commit before, on `main`), a line
  added to a shrinking group fails, and a kept line with no reason fails always; the base's own list
  being absent, as on the pull request that introduced the check, compares nothing, which is how the
  merges' two lines below stand. Constants, vars and signals with no use anywhere stay in the no
  reader group as the orchestrator's proposal. Its docstring says what it can
  miss and where it can accuse falsely. It has a test of its own, run by `tools/pycheck.sh`, and a
  row in the **using-tools** catalogue.
- The merges of `main` added `Blackout.go_dark()` (a patrol test now calls it, and only the
  blackout's own file uses it) and `RunStateRegistry.state_data()` (the save suites now read the
  run's parts through it, and only its own file's `run_data()` calls it) to the own-file group,
  and took off the eight members the save, run, telemetry and screen build deleted. The second merge took
  off eight more: `City.close_ground`, `PosterArt.region_names`, `SceneryGround.has_water`,
  `InteriorTileset.region_name_for`, `AtlasLibrary.is_resident` and `last_load_moment`,
  `AtlasTable.region_names`, and `Stroller.stroller_sources` (no test reads it any more).

**Open to overturn:** the variables, signals and constants line of the own-file rule and the
hand-ins' kept group, both the orchestrator's readings of the player's words; the engine-name set's
contents; a stale line failing outright rather than only on the pull request's own diff.
