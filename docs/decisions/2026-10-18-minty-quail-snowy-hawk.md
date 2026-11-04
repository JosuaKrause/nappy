# minty-quail — The suites that took the stand-in through RunCity.of_the_run() build their city on a run of their own (run state handed in: G7) · 2026-11-04

minty-quail's `run-state-handed-in.md`: the fifteen suites and `tests/view_rig.gd` that built their
city through `RunCity.of_the_run()`, which handed it the stand-in, so `rg GameState` did not count
them. Tests only.

**Built.** Each builds its city through `RunCity.with_own_run()` on a run of its own, on seed 2, the
seed the runner reset the stand-in to, named beside the city's scene; nothing read the run back
through the stand-in, and every check is kept. A city handed no run refuses to build.
