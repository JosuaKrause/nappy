## M143 — The readout's `process` and `physics` lines say what they measure · built 2026-09-24

*([PLAYTEST-75](../playtests/PLAYTEST-75.md); follows M138, what the readout's `process` and
`physics` lines measure.)* `FrameCost.readout_lines()` prints one column each, `process worst`
and `physics worst`, the engine's own worst interval of the previous second, read straight off
`Performance`. The `last`, `mean` and `max` columns, their one-second rolling window,
`FrameCost.sample()` and its once-a-frame call in `main.gd` are gone, since the readout was their
only reader and `mean` was the column every phone reading had mistaken for a per-frame cost.
`docs/TELEMETRY.md` says, at the run log's `frame` line and at the readout, that both numbers are
the worst interval of the second, that `process` includes the render submit, and that `worst
frame` and `process` read the same hitch from two sides.
