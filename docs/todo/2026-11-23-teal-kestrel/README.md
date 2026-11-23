priority: now

# teal-kestrel — test_event_manager's check count varies with suite order and machine · filed 2026-11-23

No player's words name this finding; it is the filer's. It serves a request the player made, read as: "if anything we need tests that are properly isolated and not flaky" (inbox #914 in freckled-moose). The band `now` is the filer's proposal, not asked for.

**Found** by the reviews of pull request #1650 (minty-quail row 5, the event manager's suites).

**What holds today.** `tests/test_event_manager.gd` reports a different number of checks depending on where and after what it runs: alone it gave 1565 on one machine and 1483 on another, and 826 in a nine-suite run; main does the same. State is carried between runs. The runner's leak check (`tests/shared_state.gd`) compares autoload fields and signal connections and does not catch whatever this is. To show it: `tools/test.sh test_event_manager` on two machines, and again inside a larger run, comparing the printed check count. The record 2026-10-18-minty-quail-49 says the flaky half of the `tests-isolated.md` item (a repeat or shuffled suite order) stays open; this is a concrete case of it, filed as an entry of its own.

**What the fix must hold.** It finds what is carried between runs and what differs between machines, and isolates it. The check count of `test_event_manager` is the same run alone, in any suite order, and on any machine.

**Proposed, not asked for:** the band `now`, because a count that moves hides whether a case ran at all, and the refactor's suites must be isolated.
