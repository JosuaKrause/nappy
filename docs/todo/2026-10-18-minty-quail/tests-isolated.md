# Tests that are isolated and not flaky

**The ask.** Asked how a merge was possible with `main` not green (two PRs passed their own CI and
were landed back to back; `main`'s CI then failed on an order-dependent `test_touch` failure seen
only with both merged), and offered landing one PR at a time or requiring branches to be up to date,
the player: "if anything we need tests that are properly isolated and not flaky" (freckled-moose
#914).

**Read as:** a suite's result depends on nothing but the suite. No suite leaves state behind that
another can see, whichever order the suites run in, and a check that passes or fails on timing or on
a seed it does not control is made deterministic. The landing process stays as it is: the same
statement says "we don't need either" of the two options (freckled-moose #914).

**The incident.** An order-dependent `test_touch` failure on `main`: a suite run alone passes, but
fails in a shard, likely behind another suite that leaves shared state behind. The cause is not
established: a held `pause` action does not fail `test_touch.gd`'s own checks.

**What is left.** The runner fails a suite that leaves shared state changed, and the leaks it found
are fixed (the isolated half). The runner shuffles and repeats suites (`--shuffle SEED`, `--repeat N`), and every CI shard runs
in a shuffled order it prints with the command that replays it, so an order dependence shows on any
pull request, and a re-run draws another order. The suites that boot `main` declare `t.gives_back_observers()`
for the observers' count of a run, which the `Telemetry` and `VisitCounter` autoloads hold and no
suite can hold a copy of; giving each its own teardown, once that count is held by something a
suite is handed, removes the declaration.

**Boots that drift with the wall clock.** A booted `main` has stepped as many physics ticks by the
time a suite takes hold as the wall clock gave its boot frames, so a suite that then counts ticks
or frames starts its walk from a crowd that is a few ticks apart from run to run, which
`test_move_poses.gd` holds still by running the boot at a time scale of 1e-7. The suites that boot
`main` and count physics ticks or frames after it, and check nothing the drift reaches today, are
`test_boot_handing.gd`, `test_run_config.gd`, `test_main.gd`, `test_run_flow.gd`,
`test_frame_record.gd` and `test_run_checkpoints.gd`; they hold the boot still the same way when a
check of theirs reads a position or a crowd state.

**Tests touch nothing real.** A test overwrote the player's desktop save, and asked whether tests
should be made unable to touch it at all, by a guard in the save that refuses the real path while
the test runner runs, the player: "so a) tests shouldn't touch anything real. all of that should be
mocked out or handled in a test state only matter b) are you talking about preventing such a thing
from happening at all? how would that work? if you write a bad test it will happen. don't write bad
tests" (inbox #984 in brisk-pelican).

**Read as:** every test hands in what it touches, a fake or a state made for the test (a scratch-path
save, never `user://save.json`), and a test that reaches anything real is a bad test; no runtime
guard is built. *Proposed, not asked for:* review is where a bad test is stopped, and what is left,
from the filer's reading of the suites rather than a survey, is that the suites that build a `main`
or a `GameSave` without handing it a scratch path or a fake get one; the frame recorder's desktop file name is checked once the records folder is
handed to the recorder rather than named under the player's `user://frame-records/`.

This item sits beside `tests-public-seams.md` (tests drive public seams and real frames), whose
fakes injected instead of patched statics remove part of the same shared state.
