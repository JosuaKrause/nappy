# Playtest 74 — 2026-09-14

A phone session on the live page, v0.10.6 (6615746), the release that carries the `motion`
skip word. The player sent six screenshots and no words: every one reads `seed 123  day 1`,
three with `skip=motion` and three with `skip=motion,crowd`, all within the first ten seconds
of the day. It is the run the phone item in `REVIEW.md` asked for after playtest 73.

## The crowd's scripts parked, on the phone

Six screenshots of day 1 in `evidence/playtest-74-phone-motion-2026-09-14/`, named by what
was skipped, where she stood and the seconds left. The numbers off each are tabled and read in
`DECISIONS.md`, M140, the phone reading. The reading: parking the crowd's scripts lifts the
phone from playtest 73's 28 to 29 fps with the crowd walking to 33 to 39, and parking and
not drawing it lifts it to 36 to 45 — the first setting in three phone readings that moves the
frame at all. The `physics` mean does not fall: 6 to 9 ms a tick with the crowd's own physics
tick returning at once, against 7 to 8 with it walking, so the physics line is not the crowd's
and is the larger half of what is left.

Whether the lag *felt* any different, with the atlas or with the crowd standing still, is the
half only the player can answer, and the screenshots came without a word on it. Asked again on
2026-09-14 alongside the question the reading opens: whether the next probe is the physics tick
that is not the crowd's, or the slower tick for off-screen agents that the crowd's own 5 to 10
fps would pay for.

## The physics tick, answered

> "physics should be capped at 30fps at the least not 60"

Said to the reading above, on 2026-09-14, to the finding that the physics tick is the larger
half of what is left of the phone's frame and is not the crowd's. Filed as M141 in `TODO.md`.
The felt half of playtest 73 and the choice between the two probes were not answered in words;
the tick instruction is the answer to what to do next.
