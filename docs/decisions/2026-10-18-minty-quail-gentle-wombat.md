# minty-quail — The checkpoints, seal reach, touch and balance suites drive the crowd's own hand-in and real ticks (tests through public seams: W24) · 2026-11-04

minty-quail's `tests-public-seams.md`: `tests/test_checkpoints.gd`, `tests/seal_reach_rig.gd`,
`tests/test_touch.gd` and `tests/test_balance.gd`; `tests/test_burst_capture.gd`,
`tests/test_telemetry.gd`, `tests/test_city_decay.gd`, `tests/test_route_rig.gd` and
`tests/stroller_steer.gd` were looked at and left. Tests only.

**Built.** The checkpoints suite hands the crowd her through `Crowd.use_player()` and steps its
gates through `Crowd.step()`, the calls the game makes; the seal reach rig builds its band through
`EventInstance.setup()` and reads where it stands and whether it runs vertically through
`position` and `runs_vertically()`; the touch suite's one match was a check's wording. The balance
suite walks her on real physics ticks at four times real time, since a headless tick costs about the
same wall time whatever its work, its settle times counted in game seconds, and stays under two
minutes; every check is kept.

**Not done, and what each wants:** the burst and telemetry suites' reads of `Telemetry`'s bursts and
shots, which want `Telemetry` handed its screen and clock, a door no game class would call yet; the
city decay suite's read of the scheduler's sack-pile preference, which wants a public entry for
placing one row at one site that the scheduler and the mouse's placement both call; the route rig's
line of sight, which wants a public cut query the planner's smoothing also calls; the 45-degree
walk helper, whose callers apply her body's displacement by hand each tick; and the balance suite's
calm-park checks, which a walking sleepiness gain low enough to push her settling past their bound
(about 103 s against 99 s) would fail, not run, since every later day of such a mutation walks a
hundred seconds of game time or its whole length; their bound lets her settling grow about
thirty-five-fold before they fail, which is a balance decision.
