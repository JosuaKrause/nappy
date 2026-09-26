## M124 — Where a frame goes, measured · the phone half, 2026-09-13

*(Three phone screenshots of the live page with `?debug=1`, v0.10.3, day 1, sent on
2026-09-13 — [PLAYTEST-70](../playtests/PLAYTEST-70.md);
`evidence/playtest-70-phone-readout-2026-09-13/`.)*

| where | fps | draws | objects | primitives | process ms | physics ms | crowd |
|---|---|---|---|---|---|---|---|
| the market street, 170 s left | 30 | 857 | 2193 | 5334 | 32.40 | 6.70 | 234 |
| a junction in the crowd, 177 s left | 29 | 849 | 1843 | 5727 | 45.20 | 6.40 | 234 |
| the doorstep, 172 s left | 27 | 832 | 1800 | 5635 | 36.30 | 8.60 | 234 |

Against the desktop's built state (the desktop half below, row (f): 151 fps, 572 draws, 1585
objects, 3644 primitives, 10.4 ms process, 1.8 ms physics):

**The phone's whole frame is `process`.** At 27 to 30 fps a frame is 33 to 37 ms, and process
alone reads 32 to 45 ms; physics is a fifth of it. On the web build that number is not the
scripts alone: the export runs with threads off, so the frame's draw submission happens on the
main thread inside the step the readout times, and the readout cannot say how much of the 32 to
45 ms is GDScript and how much is WebGL taking 850 draw calls one at a time. **The phone draws
about half again what the desktop draws** — 850 calls against 572, 1800 to 2200 objects against
1585, 5300 to 5700 primitives against 3644 — the portrait viewport shows more of the city and
the touch controls draw over it. So the desktop's finding, that texture switches are not the
cost, does not carry to the phone unread: a draw call is dearer through a browser's GL than
through a desktop driver, and the phone makes more of them. Fill rate is implicated by nothing
here.

**What decides the atlas item** is the split the readout cannot make and the desktop's probes
can: a served debug export on the phone with event `_draw` skipped, then crowd `_draw` skipped —
the (d) and (e) rows of the desktop table — read for fps and process. If process falls with the
draw count, the calls are the cost and an atlas is the fix; if it does not, the scripts are and
no batching touches it. `TODO.md`'s M124 entry holds that probe.
