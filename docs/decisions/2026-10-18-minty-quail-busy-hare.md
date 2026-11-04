# minty-quail — The day loop suite plays runs of its own (run state handed in: G2) · 2026-11-04

minty-quail's `run-state-handed-in.md`: `tests/test_day_loop.gd`. Tests only.

**Built.** Every day loop test makes its own `RunState` and hands it to what it tests: the day's
controller through `DayController.setup(map, player, run)`, the summary through `SummaryModel`, a
booted `main` through `Boot.home_playing()` on a scratch-path save, a city through
`RunCity.with_own_run()`; the reads of the global run and their writes back, and the helpers that
saved and restored it, are gone, with every check kept. Seven mutation runs fail it.

**Not done:** an untyped empty-array ternary in `RunSession` fails only the runner's script-error
gate, since the summary still comes up and every check passes; it was so before.
