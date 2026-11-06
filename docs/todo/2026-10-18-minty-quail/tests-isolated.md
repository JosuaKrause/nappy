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

**What is left** is the boots below, which drift with the wall clock. Beside them, the runner fails
a suite that leaves shared state changed, shuffles and repeats suites (`--shuffle SEED`, `--repeat
N`), and every CI shard runs in a shuffled order it prints with the command that replays it, so an
order dependence shows on any pull request.

**Boots that drift with the wall clock.** A booted `main` has stepped as many physics ticks by the
time a suite takes hold as the wall clock gave its boot frames, so a suite that then counts ticks
or frames starts its walk from a crowd that is a few ticks apart from run to run, which
`test_move_poses.gd` holds still by running the boot at a time scale of 1e-7. The suites that boot
`main` and count physics ticks or frames after it, and check nothing the drift reaches today, are
`test_boot_handing.gd`, `test_run_config.gd`, `test_main.gd`, `test_run_flow.gd`,
`test_frame_record.gd` and `test_run_checkpoints.gd`; they hold the boot still the same way when a
check of theirs reads a position or a crowd state.

This item sits beside `tests-public-seams.md` (tests drive public seams and real frames), whose
fakes injected instead of patched statics remove part of the same shared state.
