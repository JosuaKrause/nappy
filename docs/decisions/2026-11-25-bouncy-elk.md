# bouncy-elk — Day 13's chalk mark at (7, 39) on seed 34 is not one the day can pick · 2026-11-25

bouncy-elk, the bug entry filed by the end remeasure of minty-quail (R3): on seed 34, day 13's chalk
mark at tile (7, 39) got no roadblock, found or swapped, where the player's word on the task is
no fallback (inbox #1185 in gentle-owl).

**Cause: no regression, and no defect in the game.** The mark is not one the day can pick. The
dawn picks a mark by `ResistanceDirector._pick_reachable()`, whose last test is
`_she_can_be_sent_to()`: with her nowhere yet, a way from home is confirmed, the units along it
and round the place drawn first (`WayConfirmation`). On seed 34 the way to (7, 39) does not stand
(the confirmation answers false), and the units its draw adds shut the alley's pocket from home:
her paths from the mark reach 14 tiles, none reachable from home, over the whole city as well, so
no section is open to her and no roadblock the day placed is within reach. The probe's
`_legal_marks()` asked only the first two tests (legal ground; open to it and reachable from home
before any unit draws), so it read marks the dawn never picks.

**Built.** The probe `tests/probes/minty_quail_day13_real_marks.gd` asks the confirmation of every
mark as the dawn does (`_the_day_would_pick()`, on the day started again) and prints
`RM_UNPICKABLE` for a mark it refuses, left out of the read. No `src/` change and no suite
change: there is no defect in the game for a test to fail on; the probe is what measures that a
mark the day picks has a roadblock.

**Measured.** Reproduction before: seed 34, `ONLY` (7, 39), a miss. After: `RM_UNPICKABLE`. Whole
probe, 20 seeds: 480 marks, 4 the day would not pick (seed 34 (7, 39), seed 89 (108, 152), seed
31337 (150, 68), seed 2024 (49, 148)), 476 read: found 419 (median 422 px straight-line from the
mark, farthest 1,118), swapped 57 (median 1,052 px, farthest 2,122), none missed.

**Readings, open to correction:** that the dawn draws another mark where the confirmation refuses
one (`_draw_reachable()` redraws a refused tile) is what the game already does; nothing was added
for a day on which no mark confirms.
