# teal-kestrel — test_event_manager's check count holds still · 2026-11-23

**What it was.** The reviews of #1650 saw `tests/test_event_manager.gd` print a different number
of checks from one run to another: 1565 on one machine and 1483 on another, and 826 inside a
nine-suite run. The count of a case that loops over what the game made (the day's live events, the
dawn's closed streets, the region wall's segments) is the number of things the game made, so a
different day plan or map on another machine is a different count with every check passing.

**What was measured, on one machine.** The suite alone gave 827 checks five times running, 827 in
each of three passes of a repeated, shuffled run beside other event and crowd suites, and 827 in
each of six processes started together under load; the per-case counts were identical in all of
them, one case at a time. Nothing in the suite or the rig reads a clock, a frame count, the
engine's global random stream or an instance id for its length. The cached generated map
(`tests/city_map_cache.gd`) hands out copies that share no object with the kept map (a walk of
every object reachable from two copies found none in common), so what one suite does to its copy
reaches no other. The leak check (`tests/shared_state.gd`) reads the statics under `src/` and
the autoloads; the cache is the one static under `tests/`, and no suite changes it.

**What was not found.** The movement was not reproduced here, so the cause of a different day on
another machine is not named. What the arithmetic allows: 1565 - 1483 = 82, an even number, and
the case that starts day 1 through the manager made two checks for each live event (349 events,
699 checks, of 827); the closure and wall-segment loops of the city case made one each.

**What changed.** Every check whose count followed what the game made is now one check over the
whole set, saying what was found when it fails: the live events of the day-start case, the freed
nodes after a retirement and after a successor swap, the closed streets and the wall segments held.
The claims are the same and none is loosened; a failure names the offenders and their number. The
suite's count is now 106 and does not move with the number of events, closures or segments. The
cases that loop over the catalogue's rows (a fixed table in the source) still make a check for each
row.

**What stays open.** If the count of this suite moves again, a case outside these loops is the
cause, and a print of the runner's check count after each case names it.
