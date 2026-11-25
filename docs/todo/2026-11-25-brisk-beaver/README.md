priority: later
after: 2026-10-18-minty-quail

# brisk-beaver — Day 13's chalk mark frames cost 96 and 49 ms · filed 2026-11-25

**The ask.** None. The end remeasure set day 13's chalk marks beside minty-quail-sunny-owl's record: the frame on which she reads a mark that swaps a roadblock in costs 96.1 ms at the median (max 180.8) against 35 (max 41), and the frame that finds a roadblock costs 48.8 ms (max 384.1) against 4; the whole-city walk inside the swap is unchanged (36.4 ms median, 33 to 36 before), so something else on those frames grew. Swaps rose from 40 to 58 of 480 marks.

**Read as:** a frame of 49 to 384 ms is a stall a player feels at the moment she reads the chalk. The player's words on the task are about its result, not its cost (inbox #1185 in gentle-owl).

**Evidence.** `docs/evidence/minty-quail-end-timings-2026-11-25/raw/day13_marks_end_1.log` (RM_TIME lines, RM_TOTAL), `docs/evidence/minty-quail-end-timings-2026-11-25/README.md` (T6); the probe is `tools/test.sh probes/minty_quail_day13_real_marks.gd`; it ran alone at a load of 3.3, so a load difference does not explain a 12-fold rise on the found frame. The comparison is in minty-quail-downy-finch.

**Proposed, not asked for:** the band `later` after minty-quail is the filer's proposal (the orchestrator's), open to the player's correction.

**The probe changed after the comparison.** Since minty-quail-downy-finch the probe draws the units along a way from home to each mark before timing the placement (bouncy-elk), so its RM_TIME lines now measure different ground; they are not comparable with downy-finch's, and the frames are measured again before and after, on the same probe, before anything is concluded.

**What would close it.** The probe's RM_TIME lines with the found frame back near 4 ms and the swap near 35 ms, or the remainder named and accepted; first, find which part of those frames grew.
