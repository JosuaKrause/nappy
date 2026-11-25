priority: bug

# bouncy-elk — One chalk mark on day 13 gets no roadblock (seed 34) · filed 2026-11-25

**The ask.** None; found by the end remeasure of minty-quail (a defect a refactor step's measurement finds, filed `bug` by **orchestrating**, inbox #1519 in breezy-magpie). The player's word on the task: dawn's route-adjacent roadblocks must leave one within 1,024 px of every place she can read the chalk mark, "something nearby can always be used", "it can always swap", fixed with zero misses on the 480-mark probe (inbox #1185 in gentle-owl); the swap replaces a blocking event near her route and there is no fallback. minty-quail-sunny-owl recorded "none misses".

**The band.** `bug`, with no `after:` line: the player's answer on a bug a refactor step finds (inbox #1519 in breezy-magpie) starts it at once, ahead of everything and beside the refactor, so it does not wait for minty-quail.

**What happens.** At head (fc29914e6), one of the 480 real marks gets neither a roadblock found nor one swapped in: seed 34, mark tile (7, 39). `docs/evidence/minty-quail-end-timings-2026-11-25/raw/day13_marks_end_1.log` lines 347 and 348 read `RM_MISS seed 34 at (7, 39)` and `RM_MARK seed 34 mark (7, 39) | missed | -`; line 368 reads `RM_SEED seed 34 | 99 legal marks, 24 read | 14 roadblocks the day placed | { "found": 17, "swapped": 6, "missed": 1 }` and line 525 `RM_TOTAL 480 marks over 20 seeds` with `"missed": 1`.

**Reproduce.** On head, set `ONLY` in `tests/probes/minty_quail_day13_real_marks.gd` to `[[34, Vector2i(7, 39)]]` (the probe's own rerun-of-the-misses hook) and run `tools/test.sh probes/minty_quail_day13_real_marks.gd`; the unfiltered probe reproduces it in about 26 minutes. The run is seed 2, day 13.

**Not known.** Whether it is a regression since sunny-owl and gentle-marmot's records (the refactor's later steps, calm-hare's director change #1742 or placement) or a mark no legal section can reach on that city; the record minty-quail-downy-finch reports the miss and does not explain it.
