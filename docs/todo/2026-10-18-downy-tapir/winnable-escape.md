# The escape city is winnable, with the cheapest change to its event distribution

The player: "make escape winnable with minimal changes (fixing event distribution in some cheap way)"
(minty-lemur #794), and on how the escape city's events are spread: "nobody ever asked for all four
events on *every* street. that doesn't make any sense and cannot feasibly work at all. that is why the
density is so high that it's impossible to get anywhere. yes, a marble bag is absolutely needed with
empty events (nothing happening) as well. we need a fair mix", with the order "trucks > explosions >
vans > barriers > empty" (minty-lemur #785).

Today `EventScheduler.build_finale` puts one of each of four rows on every open escape street
(`Tuning.FINALE_TRUCKS_PER_STREET`, `_VANS_`, `_GUARDS_`, `_EXPLOSIONS_PER_STREET`, all 1), through
`_fill_a_finale_street`. Those counts were the build's own choice, recorded as "the dials, all open
to overturn" (`docs/review/2026-09-12-stand-at-the-service-exit-and.md`); the escape's brief asked
for "lots of lethal and dangerous events" (`docs/decisions/2026-09-09-M102-the-finales-brief-and-the-collisions-the-player-answered.md`).

*Proposed, not asked for (the cheap version):* inside `build_finale`, each open street gets a small
number of slots (start from one) and each slot's row is drawn from one escape-wide `MarbleBag` (its
own seeded stream) holding the four rows and empty marbles, counts in the player's order trucks >
explosions > vans > barriers > empty (the barriers are the roadblocks). A drawn marble that cannot be placed is spent unmet. Choose
the slot count and the marble counts by measuring over at least 20 seeds and both exits: dangers per
street, streets with nothing, dangers on the shortest walk to each exit, the meter's cost of that
walk walking and running from the city section's start, and whether each exit is reachable and
survivable at a sensible pace. Keep it the climax and make it fair to get through; the PR carries
the table. Change nothing else: the escape's placement moving onto the day's scheduler is
minty-quail's, and the explosions' look and timing are snowy-goose's. This builds inside `build_finale`, which
minty-quail replaces: the player ordered this minimal step before the refactor (minty-lemur #794),
so it is the stated exception to **orchestrating**'s "Code is designed by layer" ("that's the
whole point -- otherwise it wouldn't be cheap", minty-lemur #798), and its marble bag
is written so minty-quail's `escape-placement.md` can move it onto the day's scheduler unchanged.
