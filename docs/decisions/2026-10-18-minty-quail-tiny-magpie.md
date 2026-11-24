# minty-quail — The end remeasure's two probes are ready · 2026-11-23

**What was asked.** minty-quail's step 4 (the end remeasure) named two preconditions before the remeasure runs: the
comparison tool `tools/compare-placement-rows.py` refuses a log line of a day outside 1 to 14, and both placement probes
plan a day as `DayPlanner` plans it.

**What was built.** The tool reads a day through one function that accepts 1 to 14 in ASCII digits and nothing else, on
every line kind it reads (`RD`, `RV`, `RK` and the role table's `ROLE`). A day-15 `RD` line was accepted before, since
days 1 to 14 were all present and the extra day only added a cell; a line of day 15 or day 0 is now refused with exit 2,
a message on stderr and nothing on stdout, like every other unreadable line. `tools/test_compare_placement_rows.py` has a
case for each line kind. `tests/probes/placement_view_mix.gd` plans each day's closures, region wall, holds and seals the
way `tests/probes/placement_rows.gd` does (`RegionPlanner.plan_day()`, `ClosurePlanner.plan_day()`, `SealPlanner.plan_day()`,
the seals and the wall's bodies handed to the dawn as standing, the doors as doors), before it counts the day's
locations, so a held or closed street no longer counts as an available location. Its random streams for the closures and
the seals are its own ("placement_view_mix closures:..." and "placement_view_mix seals:..."), so the two probes differ in
those two streams only; the dawn's stream is unchanged.

**What it measured** (one seed, 90210, days 3, 8 and 13, the probe cut to those with `SEEDS := 1` in a throwaway copy; the
committed probe keeps its 18 seeds and 14 days):

| day | placed before | placed after | moments owed | locations on / adjacent / off, before | after |
|---|---|---|---|---|---|
| 3 | 98 | 88 | 26 / 26 | 881 / 979 / 643 | 872 / 807 / 535 |
| 8 | 171 | 126 | 29 / 29 | 701 / 875 / 927 | 692 / 460 / 684 |
| 13 | 140 | 109 | 32 / 32 | 614 / 704 / 1149 | 470 / 452 / 915 |

Events per view moved with the locations: day 8's route-adjacent bag 53 to 28 events, day 13's 45 to 35 (22 of them
roadblocks, as before 23 of 45). The moments the day owes her did not move, since they are placed nowhere. The probe's
output now describes a day as the game plans it; it is not comparable with a reading of the same probe from before this
change, which the baseline's lists do not include.

**What is left for the remeasure.** Its step 4 sentence on the two preconditions says what holds now: the tool refuses a
log line of a day outside 1 to 14, and both probes plan a day's closures, region wall and seals as `DayPlanner` does.
