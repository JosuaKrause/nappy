# Playtest 73 — 2026-09-14

A phone session on the live page, v0.10.5 (05f0829), the release that carries the crowd atlas,
`?debug=1&seed=N` and the readout's `mean` and `max` columns. The player sent six screenshots
and no words: every one reads `seed 123  day 1`, two with the crowd drawn and four with
`skip=crowd`. It is the run the two phone items in `REVIEW.md` asked for.

## The crowd atlas, on the phone

Six screenshots of day 1 in `evidence/playtest-73-phone-atlas-2026-09-14/`, named by what was
skipped, where she stood and the seconds left: two with nothing skipped and four with
`skip=crowd`, all in the first five seconds of the day. The numbers off each are tabled and
read in `DECISIONS.md`, M139, the phone reading. The reading: with the atlas, drawing the
crowd and not drawing it read the same — 28 to 29 fps against 18 to 34, a `process` mean of
41 to 50 ms against 35 to 49 — so by the item's own rule the crowd's drawing is not the
phone's cost and the next probe is its scripts.

Whether the lag *felt* any different is the half only the player can answer, and the
screenshots came without a word on it. Asked on 2026-09-14 alongside the next probe, which is
recommended and not filed: a skip word for the crowd's simulation — motion, separation and
lanes, which `skip=crowd` leaves running — so the phone can say what the walkers cost when
they neither move nor draw.

## The seed under the note, and the readout's columns

For the `REVIEW.md` item that asked: all six page loads say `seed 123` and the city is the
same one — two loads, one with the crowd drawn and one without, show the same forty-one live
events and the same dog walker nearest her with 175 s left. The `process` and `physics` lines
read `last  mean  max` whole on every screenshot, `ms` and all, and the block clears the pause
button. The `nearest` line still runs off the screen's edge, as it did before the block moved.
The item closes.

**One thing the widened block does that the desktop still could not show.** In joystick mode
the right focal ring is drawn at (1040, 480) in the design box, and the readout's `incoming`,
`decay` and `net` lines now cross it: on every screenshot the knob sits over their values.
Before the block moved 90px left the ring clipped only the labels' ends. It is a debug readout
over a debug ring, so it is noted here and not filed.

**And one thing the `mean` column shows that a single frame could not.** On every screenshot
the `process` mean is longer than the frame the `fps` line implies — 34 fps is 29 ms a frame
and the mean beside it reads 49 — so on the web one of the two lines is not measuring what its
name says. Which one is not established; it is recorded in `DECISIONS.md`, M139, the phone
reading, as the first thing to settle before the phone's frame is read again.
