priority: now

# teal-kestrel — test_event_manager's check count varies with suite order and machine · filed 2026-11-23

No player's words name this finding; it is the filer's. It serves a request the player made, read as: "if anything we need tests that are properly isolated and not flaky" (inbox #914 in freckled-moose). The band `now` is the filer's proposal, not asked for.

**Found** by the reviews of pull request #1650 (minty-quail row 5, the event manager's suites).

**What holds today.** `tests/test_event_manager.gd` reports a different number of checks from one run to another: run alone, it gave 1565 on one machine and 1483 on another, on main and on #1650's head alike, and 826 at #1650's head inside a nine-suite run. Suite order alone does not explain the spread, since the two alone runs differ by machine; carried state is one suspect, and whatever differs between the machines another. The runner's leak check (`tests/shared_state.gd`) compares autoload fields and signal connections and does not catch it. To show it: `tools/test.sh test_event_manager` on two machines, and again inside a larger run, comparing the printed check count. No entry holds a runner mode that repeats a suite or shuffles the suite order; this entry asks only for this suite's count to hold still.

**What the fix must hold.** It finds what is carried between runs and what differs between machines, and isolates it. The check count of `test_event_manager` is the same run alone, in any suite order, and on any machine.

**Proposed, not asked for:** the band `now`, because a count that moves hides whether a case ran at all, and the refactor's suites must be isolated.
