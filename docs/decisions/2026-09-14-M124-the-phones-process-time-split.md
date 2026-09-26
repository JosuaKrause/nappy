## M124 — The phone's process time split · measured 2026-09-14

*(Nineteen phone screenshots of the live page, v0.10.4 (1f80b57), day 1, sent on 2026-09-14 —
[PLAYTEST-72](../playtests/PLAYTEST-72.md); `evidence/playtest-72-phone-skip-probe-2026-09-14/`.)*
The probe the phone half (below) asked for: `?debug=1` with each `skip` word in turn, then all
three. Each setting is one page load and so one seed, except where a second seed is named —
those are the first three screenshots, sent before the rest. *Walking* is the first thirty
seconds of the day at speed 92; *doorstep* is standing where the day starts, before the first
step.

| skipped | where | s left | fps | draws | objects | primitives | process ms | physics ms |
|---|---|---|---|---|---|---|---|---|
| nothing, seed 4244904977 | doorstep | 179 | 31 | 955 | 2222 | 6109 | 60.60 | 7.00 |
| | crossing | 176 | 32 | 941 | 2140 | 5885 | 33.70 | 6.60 |
| | road | 176 | 20 | 901 | 2096 | 5872 | 42.10 | 8.20 |
| | road | 175 | 22 | 735 | 1810 | 5330 | 44.80 | 8.70 |
| shadows, seed 1793795987 | doorstep | 178 | 23 | 764 | 1840 | 5076 | 49.30 | 8.30 |
| | road | 174 | 28 | 889 | 1991 | 5239 | 28.00 | 9.80 |
| | sidewalk | 169 | 18 | 742 | 1759 | 5147 | 47.20 | 10.20 |
| shadows, seed 4021358616 | doorstep | 173 | 24 | 867 | 1857 | 5931 | 44.30 | 8.30 |
| events, seed 62022562 | doorstep | 179 | 30 | 912 | 2238 | 5661 | 59.30 | 6.10 |
| | road | 173 | 34 | 887 | 2034 | 5520 | 32.30 | 6.40 |
| | sidewalk | 170 | 31 | 942 | 2219 | 6090 | 27.80 | 8.50 |
| events, seed 4209957228 | doorstep | 176 | 30 | 759 | 1848 | 4948 | 38.20 | 9.40 |
| crowd, seed 2638076029 | road | 178 | 30 | 706 | 1838 | 4476 | 65.10 | 6.90 |
| | sidewalk | 173 | 36 | 618 | 1661 | 4152 | 30.20 | 7.00 |
| | crossing | 169 | 39 | 655 | 1800 | 4355 | 21.70 | 5.70 |
| crowd, seed 951876270 | doorstep | 175 | 29 | 653 | 1763 | 4373 | 32.10 | 6.00 |
| all three, seed 1506072341 | doorstep | 171 | 19 | 723 | 1957 | 4694 | 45.00 | 11.50 |
| | sidewalk | 162 | 21 | 483 | 1486 | 3704 | 46.70 | 9.70 |
| | crossing | 158 | 39 | 711 | 1817 | 4366 | 32.20 | 6.70 |

**The draw calls are not the cost, so the atlas item is struck** — on the rule the item itself
set: *if process falls with the draw count, the calls are the cost; if it does not, the scripts
are.* With all three families off the phone makes 480 to 720 calls against 900 to 950 with
nothing skipped — up to half the calls gone, and the crowd's, the events' and the shadows'
draw scripts with them — and process reads 32 to 47 ms, inside the 34 to 61 ms it reads with
everything drawn. Skipping the crowd's drawing alone lifts fps the most (30 to 39 against 20 to
32), but its process readings span 22 to 65 ms, the widest of any setting; nothing here falls
with the draw count. What is left is the scripts — the crowd's motion and separation, the
events' fields and the costs, none of which a skip word touches — and the physics tick, which
reads 6 to 11.5 ms on the phone against 1.8 on the desktop. The desktop said texture switches
were not the cost and the phone says the same, from the other side.

**Two things the probe turned up that it was not looking for.**

- **The readout's process line is one frame.** `Performance.TIME_PROCESS` is the last frame's
  time, so a still catches whichever frame the screenshot landed on: the same setting reads
  21.7 and 65.1 ms a few seconds apart, and the doorstep readings — taken within ten seconds of
  the day starting, while the first textures are still going up — are the highest of every
  setting. `fps` is the engine's one-second average and is the steadier number. A one-second
  mean for process and physics in the readout would make a single still worth taking; it is
  recommended under M138 in `TODO.md`, not built.
- **Half the phone's draw calls belong to none of the three families.** 480 to 720 remain with
  the crowd, every event and the shadows off. The ground is a `TileMap`, so it is not the
  ground; what is left is the buildings, the props, the litter and decals, the traffic, the
  HUD, the touch controls and the readout's own text. Which of those it is has not been
  measured, and it is the first thing to skip if the phone's frame is ever worked on again.

**And then the player's felt report:** *"I can see lag only if the crowd is being drawn
though."* The `fps` column, the engine's one-second average, agrees with the feel where the
one-frame `process` column cannot: `skip=crowd` is the only setting that lifts it, to 29 to 39
against 20 to 32 with nothing skipped. A walker redraws only when its picture changes — a gait
frame every stride, a heading — so what the word turns off is the recording of a few hundred
walker canvases a second and the two hundred and fifty GL calls they become, each walker's own
texture breaking the batch. That is exactly what an atlas for the crowd family alone would
change, and nothing else in the table would; the atlas item was struck a moment earlier by the
entry's own rule, so whether it comes back narrowed to the crowd was the player's call, put to
them on 2026-09-14 and answered the same day — *"yes, let's start with a crowd atlas"* — as
M139 in `TODO.md`.

**What closes.** M124's two remaining items — the split is this measurement, and the atlas item
is struck on it and comes back narrowed to the crowd as M139. M124 leaves the queue.
