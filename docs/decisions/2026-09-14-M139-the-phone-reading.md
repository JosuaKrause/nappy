## M139 — The phone reading · measured 2026-09-14

*(Six phone screenshots of the live page, v0.10.5 (05f0829), day 1, seed 123, sent on
2026-09-14 without a word — [PLAYTEST-73](../playtests/PLAYTEST-73.md);
`evidence/playtest-73-phone-atlas-2026-09-14/`.)* The run the atlas's `REVIEW.md` item asked
for: `?debug=1&seed=123` with the crowd drawn, then `&skip=crowd` for the control, all within
the first five seconds of the day. Every load is the same city, so for the first time the
settings are compared on one seed rather than across six. *Standing* is speed 0 on the
sidewalk before a step; the rest are walking at speed 92. `process` and `physics` are the
readout's new columns, `last  mean  max` over the last second.

| skipped | where | s left | fps | draws | objects | primitives | process last / mean / max ms | physics last / mean / max ms |
|---|---|---|---|---|---|---|---|---|
| nothing | road | 177 | 29 | 654 | 1855 | 5495 | 34.6 / 40.8 / 45.0 | 5.6 / 7.3 / 8.4 |
| nothing | sidewalk | 175 | 28 | 833 | 2185 | 6349 | 40.1 / 50.3 / 64.0 | 6.6 / 7.5 / 8.7 |
| crowd | standing | 178 | 34 | 772 | 2180 | 5840 | 26.5 / 49.2 / 57.7 | 6.1 / 5.9 / 6.1 |
| crowd | sidewalk | 178 | 29 | 812 | 2204 | 5545 | 35.7 / 35.0 / 35.7 | 8.5 / 8.0 / 8.5 |
| crowd | crossing | 177 | 18 | 628 | 1999 | 5158 | 57.7 / 47.9 / 57.7 | 8.6 / 8.6 / 8.6 |
| crowd | crossing | 175 | 29 | 664 | 1850 | 4715 | 43.3 / 43.2 / 43.3 | 7.9 / 8.6 / 10.6 |

**With the atlas, drawing the crowd costs the phone nothing it can measure.** The two
settings read the same: 28 to 29 fps with the crowd drawn against 18 to 34 without, a
`process` mean of 41 to 50 ms against 35 to 49, a `max` of 45 to 64 against 36 to 58. Against
playtest 72's table (M124, the phone's process time split, below) the crowd-drawn fps sits at
the top of the 20 to 32 it read on v0.10.4, and where `skip=crowd` was then the only setting
that lifted it, to 29 to 39, it now lifts nothing. The draw count with the crowd drawn, 654 to
833, is where playtest 72's `skip=crowd` loads were, 618 to 706, and the `skip=crowd` loads
here read 628 to 812 — the calls a walker's own texture used to cost are gone and the phone's
frame did not move with them. By the item's own rule — *if neither the feel nor the numbers
move, the crowd's drawing was not the cost and the next probe is its scripts* — the numbers
half is answered. The felt half is the player's, asked on 2026-09-14 with the screenshots'
reading.

**The next probe, recommended and not filed.** `skip=crowd` turns off the crowd's *drawing*
and nothing else: the 234 agents still move, separate and keep their lanes on every tick, and
`crowd 234` reads the same on every load. What is left after this reading is exactly that
simulation and the events' fields, and a skip word that stops the crowd's scripts — the agents
parked where they spawned, undrawn — would say what the walkers cost when they neither move
nor draw. It is a question for the player in playtest 73, not a `TODO.md` item, because M124's
skip words were their design and a fourth word is one more of them.

**Two things the columns showed that a single frame could not.**

- **The `mean` outruns the frame.** On every screenshot the `process` mean is longer than the
  frame the `fps` line implies: 34 fps is 29 ms a frame and the mean beside it reads 49; 28
  fps is 36 and the mean is 50. `fps` is the engine's one-second frame count and `process` is
  `Performance.TIME_PROCESS`, the engine's own timing of its process step; on the web the
  browser paces the frames from outside the engine, and which of the two lines the phone is
  misreading is not established. Until it
  is, the `fps` line — which agreed with the player's feel in playtest 72 where the one-frame
  process reading did not — is the number to read, and the columns are the check on it.
- **`max` is usually the frame the screenshot landed on.** Four of six `process` readings and
  four of six `physics` readings have `last` equal to `max`: the stall of taking the
  screenshot is the heaviest frame of its own second. `mean` is the column a still is worth
  reading for; `max` on a phone screenshot is mostly the screenshot.

**And the readout crosses the right focal ring.** In joystick mode the right focus is drawn at
(1040, 480) in the 1280x720 design box, a 48px ring with a knob, and the readout block now
starting at x 960 puts its `incoming`, `decay` and `net` lines across it — every screenshot
shows the knob over their values, where before M138 the ring clipped only the ends of the
labels. M138's own check that "nothing else is drawn in that strip" missed the ring because
the desktop still was taken in tap mode. Noted in playtest 73 and not filed: a debug readout
over a debug ring, on the two lines the meter itself already shows.

**What closes.** The two phone items in `REVIEW.md` — the atlas's reading and the seed under
the note with the columns. The seed answers on the live page: six loads, six `seed 123`, and
two loads with different skip words show the same forty-one live events and the same dog
walker with 175 s left, so the city is the same one. The three columns fit a phone in
portrait with margin, `ms` and all, and the block clears the pause button; the `nearest` line
runs off the edge as it always did.
