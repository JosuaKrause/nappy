priority: later
after: 2026-10-18-minty-quail

# frosty-raven — The crowd tick costs 29 percent more than before the refactor · filed 2026-11-25

**The ask.** None: the player accepted this cost for now. Asked about the crowd tick's cost, the player: "let's eat the cost for now and think about optimizing later" (minty-dolphin #852). The end remeasure's reading is "later" arriving as a number.

**Read as:** the crowd tick (`Crowd` stepping the pedestrians and cars once per 30 Hz physics tick) may be optimized now that the refactor's remeasure has measured it, and polite-plover's rule holds: attribute the remaining slow frames before another optimization.

**Evidence.** Head (fc29914e6) runs the tick at 2374, 2398 and 2374 µs against v0.29.0's 1672, 1695 and 1675 (agents column plus tick column), in three rounds run at the same moment, no overlap: about 700 µs, 29% of head's tick, slower in every round. Against the refactor's step 4b (b3693bee7) it has not moved (2351 µs, the baseline's reading), so the cost was added before that step. Figures, rounds and load files: `docs/evidence/minty-quail-end-timings-2026-11-25/README.md` (table T2) and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/crowdtick_end_*` and `docs/evidence/minty-quail-end-timings-2026-11-25/raw/crowdtick_v029_side_*`; the reading is in the record minty-quail-downy-finch.

**Proposed, not asked for:** the band `later` and the bar (slower than the earlier tree in every side-by-side round, beyond both trees' spread, and by more than a tenth of the system's tick) are the filer's proposal (the remeasure's planner, minty-quail-downy-finch), open to the player's correction; the plainer alternative is to file no entry and let a phone's frame record (polite-plover) decide first.

**What would close it.** The same probe (`tools/test.sh probes/m159_crowd_tick_cost.gd` on head and on v0.29.0, started together, three rounds) after an attribution of the 700 µs to the mover base and the lane interface, with head's tick back within a tenth of v0.29.0's or the remaining cost named and accepted by the player. A headless debug build overstates GDScript call costs (minty-quail-brisk-lark) and no release build is measured, so whether a phone shows it is decided by the frame record first.
