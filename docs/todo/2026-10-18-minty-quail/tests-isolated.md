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
fails in a shard behind another suite that leaves shared state behind.

**Proposed, not asked for:** the test runner checks shared state before and after each suite
(`InputMap` bindings, which actions `Input` holds pressed, autoload fields, static variables) and
fails a suite that leaves it changed, naming the field. Every flaky check found, by that or by a
repeated run, is made deterministic rather than retried. The plainer alternative is to fix each
leak as it shows up; the check is proposed because a leak is otherwise found only when two suites
happen to meet on `main`.

This item sits beside `tests-public-seams.md` (tests drive public seams and real frames), whose
fakes injected instead of patched statics remove part of the same shared state.
