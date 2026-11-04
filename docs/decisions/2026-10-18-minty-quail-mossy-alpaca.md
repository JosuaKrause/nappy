# minty-quail — The visit counter and run state suites and the scenario fixture use runs of their own (run state handed in: G3) · 2026-11-04

minty-quail's `run-state-handed-in.md`: `tests/test_visit_counter.gd`, `tests/test_run_state.gd`
and the fixture `tests/fixtures/run_state_scenario.gd`. Tests only.

**Built.** Each visit counter builds a run of its own and is configured with it through
`VisitCounter.configure()`, the listening and send-gate checks hand a run of their own and free it,
and the saved and restored mode and day are gone. The scenario fixture takes the run it builds,
writes and loses, and the run state suite makes a fresh run per test, so its tail that put the
stand-in back and its giving back of the observers are gone. Every check is kept; one is reworded,
"leaves the run it counts untouched". Five mutation runs fail them.
