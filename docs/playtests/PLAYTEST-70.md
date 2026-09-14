# Playtest 70 — 2026-09-13

A phone session on the live page, v0.10.3, opened with `?debug=1` — the first time the readout
has been read on a phone. The player sent three screenshots and one instruction.

## The phone half of M124, read off the screen

Three screenshots of day 1 with the readout on, in
`evidence/playtest-70-phone-readout-2026-09-13/`: the market street with 170 s left, a junction
in the crowd with 177 s left, and the doorstep with 172 s left. The six numbers off each — 27 to
30 fps, 832 to 857 draws, 1800 to 2193 objects, 5334 to 5727 primitives, 32 to 45 ms of process,
6.4 to 8.6 ms of physics — are tabled and read against the desktop in `DECISIONS.md`, M124, the
phone half.

For the `REVIEW.md` item that asked: the note is legible top-left and covers nothing, and the
readout is readable enough to take the numbers off it. The item closes.

## Debug mode names its build

> "Debug mode should contain the commit + describe."

Sent with the screenshots, whose readout names the seed and the day but not the build: the title
screen's version line is off screen the moment a run starts, and on a release it says only the
tag. Built as M136 (`DECISIONS.md`, M136): the note and the readout's first line carry
`git describe`'s form and the commit, and the export bakes both.
