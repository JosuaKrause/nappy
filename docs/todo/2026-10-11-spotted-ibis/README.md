priority: now

# spotted-ibis — Day 8's burnt building can stand where she cannot reach it · filed 2026-10-11


Found while building [teal-moose](../../decisions/2026-10-07-teal-moose.md), not reported by the
player. Day 8's task is at a burnt building's door: the building day 3's fire left, when one is
remembered (the SCAR step in `ResistanceDirector`), otherwise a fallback burnt building. On a sweep
of 85 remembered fires, about 9 have no tile by the door that she can stand on and reach from home,
and on 7 of those the shell's own frontage is unreachable from home as well: the remembered building
stands in ground the day's closures, seals or walls cut off from home by day 8, so the task cannot
be done and the day cannot be won there. The task's place is chosen without asking whether day 8 can
reach it. The work is [reach-the-burnt-building.md](reach-the-burnt-building.md).

*Proposed, not asked for:* the band `now`, since a day that cannot be won is the defect the **city**
skill's guarantees exist to prevent.
