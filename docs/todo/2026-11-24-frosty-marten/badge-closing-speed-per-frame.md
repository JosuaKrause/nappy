# The badge measures every drawn frame against positions that move once per tick

**Evidence.** `docs/evidence/minty-quail-end-pictures-2026-11-24/raw/masked-and-mouse-run.log-lines.txt`:
the masked man's badge goes up with `closing 113px/s` on one run and `closing 1949px/s` on the
other (lines 7 and 27); `TELEMETRY.md`'s example has about 110. The review of the picture pull request
saw `closing 500px/s` headless at 145 fps and `1919px/s` windowed. The number scales with the frame
rate, and the window here drew at 140 to 570 fps.

**Cause (read off the code).** `DangerEdge._process()` hands `BadgeModel.step()` the render frame's
`delta` and the event's `global_position`. Events step on the 30 Hz physics tick, so the position the
model reads jumps once per tick, about 3.7 px at his 110 px/s. `BadgeModel._measure()`'s first-moving-frame
rule for a charge takes `maxf(approach, raw)` on the first frame where `raw > 0`, and that frame is a
tick frame: 3.7 px over a render delta of a few milliseconds. On a 60 fps display that is about twice
his real speed. The inflated approach feeds the badge's arrival time, which decides which of
several overlapping badges draws on top, as well as the log line.

**What is open.** The approach has to be measured over the tick's own time, or the rule has to ignore a
frame whose position has not moved since the last tick; how is the builder's to choose, with a check
that the speed is the same at 30, 60 and 500 fps.
