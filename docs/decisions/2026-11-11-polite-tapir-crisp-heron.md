# polite-tapir — The baseline's reading after row 4b · 2026-11-22

**What was asked.** polite-tapir's `baseline-measurements.md` left one reading: winnability and frame time after the
events' field-read conversion (row 4b of minty-quail's `event-interface.md`, its twelve pull requests merged), added to
the baseline folder as a further column with the same commands and seeds and the machine's load noted before each run.
Taken by a Sonnet agent as #1636 on main at the commit after row 4b's last merge; nothing is judged.

**What was taken.** Every earlier command on the same seeds, with `uptime` saved before each run (a 1-minute load of 1.9
to 3.6, another agent's probes running beside part of it). Two no longer ran as they did: the placement-closed copy of
the dawn probe no longer matches the tree's calls, so a copy of the current `placement_rows.gd` with the same timers
stands in; and the unmodified frame-profile launcher's six runs were all rejected by its analyzer, so the `--invincible`
copy the third column used carries the frame numbers, both sets kept. A placement comparison by the tool that grew from the
first reading's script (`tools/compare-placement-rows.py`) found none of 476 cells outside two sigma of the third column.

**What moved** is listed for the end remeasure in the item. Equal to the third column: every suite at 0 failures and the
other suites' check counts, `m129_zero_cost_line` (326.2 placed rows a day, 299 of 299 routes with a zero-cost line),
the wall-cost, decay and placement-role probes, every day's placed and moment counts, and the cost table.
