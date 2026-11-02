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
are fixed (the isolated half). The flaky half: a repeat mode and a shuffled order (`--shuffle SEED`)
in the runner so that an order-dependent or timing-dependent check shows itself without two suites
happening to meet on `main`; three green full runs on the head; and making deterministic every check
whose result changes between runs. The suites that boot `main` declare `t.gives_back_observers()`
for the observers' count of a run; giving each its own teardown, once `hidden-statics.md` puts the
state in an owner a suite can hold, removes the declaration.

This item sits beside `tests-public-seams.md` (tests drive public seams and real frames), whose
fakes injected instead of patched statics remove part of the same shared state.
