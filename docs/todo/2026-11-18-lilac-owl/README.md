priority: now

# lilac-owl — The posted roadblock guard follows her round the corner · filed 2026-11-18

**The ask.** On the Nappy board the orchestrator asked whether a walker who goes straight past a posted
roadblock guard and turns the next corner before he reaches her may get away, or whether he follows her
round it. Its pick was "He follows her round the corner": the roadblock guard's chase finds its way
round buildings, as day 13's task guard's does, so walking straight past is caught wherever the street
ends. The player answered "sure, your pick" (inbox #1534 in velvet-alpaca, which holds the question and
its options as shown).

**Read as** (the orchestrator's reading): the posted roadblock guard (the guard by a roadblock's
barrier who charges her when she walks past his post instead of luring him away) chases her by a way
round buildings, as the day-13 task guard's pursuit does through `ChaseWay` (`src/world/chase_way.gd`),
so a straight walker who turns the next corner before he reaches her is still caught.

**Why it matters.** Luring the guard away is the way past a roadblock: "it should be in a way that
luring away the guard is enough" (inbox #771 in minty-lemur). The entry azure-squirrel (record
`2026-11-17-azure-squirrel`) found that he catches a straight walker about 400px past his band (he
notices her about 150px away, warns for 2 seconds, then runs at 130px/s against her 92px/s), and that
where his street ends sooner than that, his chase runs straight at her and stops at the buildings, so
turning the next corner very likely gets her past without luring. `docs/EVENTS.md` and
`docs/MECHANICS.md` say a straight walk is caught along his street and that nothing checks a walk
that turns the next corner first.

**Proposed, not asked for** (the orchestrator's, open to the player): the band `now` (the player named
none; this closes the gap a bug-band entry found, and `bug` is filed only when the player names it).
The fairness contract still holds as it stands: his warning on screen before he charges, and his
give-up time; nothing about his notice distance, warning time or speed changes unless a measurement
shows the corner chase breaks one of those rules, which comes back to the player first.
