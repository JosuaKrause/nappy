# bouncy-elk — Day 13's chalk mark at (7, 39) on seed 34 is not one the day can pick · 2026-11-25

bouncy-elk, the bug entry filed by the end remeasure of minty-quail (R3): on seed 34, day 13's chalk
mark at tile (7, 39) got no roadblock, found or swapped, where the player's word on the task is
no fallback (inbox #1185 in gentle-owl).

**Cause: the probe fell out of step with the dawn's pick, and the game has no defect.** The mark
is not one the day can pick. The dawn picks a mark by `ResistanceDirector._pick_reachable()`,
whose last test is `_she_can_be_sent_to()`: with her nowhere yet, a way from home is confirmed,
the units along it and round the place drawn first (`WayConfirmation`). On seed 34 the way to
(7, 39) does not stand (the confirmation answers false), and the units its draw adds shut the
alley's pocket from home: her paths from the mark reach 14 tiles, none reachable from home, over
the whole city as well, so no section is open to her and no roadblock the day placed is within
reach. The probe's `_legal_marks()` asked only the first two tests (legal ground; open to it and
reachable from home before any unit draws), so it read marks the dawn never picks.

**When it fell out of step.** minty-quail-sunny-owl (#1249, 2026-11-08), which recorded none
missing, was measured when the dawn's pick asked those same two tests. polite-tapir's unit draw
(#1468, 2026-11-15, a unit draws when she comes near it) added `_she_can_be_sent_to()` to
`_pick_reachable()`, and the probe was not brought along. The game's own pick was checked at head
rather than assumed: the four refused marks below are refused by `_pick_reachable()` on the day as
the dawn leaves it, and a dawn that draws one of them first redraws another mark, which then gets its
roadblock.

**What the game does when no mark confirms.** `_draw_reachable()` falls back to
`_nearest_open_in_pool()`, which answers no tile, `_pick_reachable()` answers `Vector2.INF`, and
`_begin_step()` reads that as a step with nowhere to go today: a warning, no step, no mark and no
task that day, the step neither done nor failed. There is no fallback mark. It is not reached in
practice: 4 of the 480 sampled marks are refused, each in its own sealed pocket, against pools of
53 to 109 candidate tiles a city, so a pool wholly refused would need the home itself sealed, which
the city's guarantees rule out.

**Built.** The probe `tests/probes/minty_quail_day13_real_marks.gd` asks the confirmation of every
candidate mark as the dawn does (`_the_day_would_pick()`, on the day started again) and prints
`RM_UNPICKABLE` for a mark it refuses, left out of the read; `RM_SEED`'s count of marks read
excludes them, and a run of refused marks alone (`ONLY` naming only them) passes the probe's guard.
No `src/` change and no suite change: there is no defect in the game for a test to fail on, and
the probe is what measures that a mark the day picks has a roadblock.

**Measured.** Reproduction before: seed 34, `ONLY` (7, 39), a miss. After: `RM_UNPICKABLE`. Whole
probe, 20 seeds: 480 candidate marks, 4 the day would not pick (seed 34 (7, 39), seed 89 (108, 152),
seed 31337 (150, 68), seed 2024 (49, 148)), 476 read: found 419 (median 422 px straight-line from
the mark, farthest 1,118), swapped 57 (median 1,052 px, farthest 2,122), none missed.

Against the end remeasure (minty-quail-downy-finch, 480 read: found 421, swapped 58, missed 1) the
four refused marks account for the whole difference: the one miss, two marks that were found and one
that was swapped; no other mark changed its outcome, and the found median and farthest are the same.

**The timing lines are not comparable with downy-finch's.** The probe now draws the units along a
way from home to each mark before reading it, as the dawn does in play, so `_place_the_roadblock_near()`
is timed on different ground. This run's `RM_TIME` medians are found 48.9 ms (max 424.6), swapped
67.1 ms (max 182.9) and the whole-city walk 37.0 ms (max 65.6); downy-finch's are not the same
measurement, and brisk-beaver (day 13's chalk mark frames) compares them as if they were.

**Readings, open to correction:** that the dawn draws another mark where the confirmation refuses
one (`_draw_reachable()` redraws a refused tile) is what the game already does; nothing was added
for a day on which no mark confirms.
