**Event placement completes, always and within a bound**
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #701: "the lag spike explanation
might also be the explanation for the soft lock -- let's audit the placement code for guaranteed
and bounded completion").

**What found it.** Day 9's longest frame in velvet-marten's record (775 ms, 748 ms of it `events`)
reproduces on the desktop as one tick inside `EventManager._site_what_is_on_her_way`: once a second
`EventDirector.site_what_is_on_her_way` asks `WalkSiting.ahead_of` for each of about twelve unplaced
`poster_crew` copies, each is offered one tile, and `EventScheduler._best_of` re-runs the whole
rule chain on that same tile `Tuning.EVENT_PLACEMENT_TRIES` times against every plan of the day
before refusing it.

**The audit.** Every loop, retry and search that places or sites an event, and anything they call
to decide a placement: for each, whether it always terminates and on what argument, its worst-case
work per call, and whether a refusal can repeat every look or every frame while holding up anything
the day needs to progress (a director clock that never advances, a due event that never fires, a
task that cannot complete). Its table is retained as evidence. What is unbounded or super-linear is
fixed without changing any placement where it can be; a fix that would change placements, or that
completes only by giving up differently, goes to the player first. It reports whether azure-koala's
day-12 softlock could have been this.
