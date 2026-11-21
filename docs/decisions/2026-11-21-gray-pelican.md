# gray-pelican — The location is the one place that says a beat stands on it · 2026-11-21

**What was asked.** Fable's review of #1548 (the beats become rigged marbles in the units ahead of her), a merged pull
request of the fable-only entry polite-tapir, found that a beat standing on a location was written in three places,
the location, its unit's rigged list and the walk siting's own list, kept in step by the siting; Fable wrote this
change as its design (the record calm-lemur holds the verdicts), and the player asked for its fixes to be built and
reviewed again by Fable (the entry's README quotes the go-ahead). Built as #1617 by a Sonnet agent.

**What was built, as the design wrote it.** `Location` remembers the beat her walk stood on it, and `beat()` answers
it only while it is still what stands there, so a section swapped in over it (day 13's task roadblock) ends it.
`MarbleDraw.draw()` leaves drawn every location of the unit that is open or holds a beat, so a location given back
after its unit filled in reads drawn-empty with no repair. `PlacementUnit`'s `rig()`, `unrig()` and `rigged()` give
way to `beats()`, which reads its locations; the unit's draw asks it. `WalkSiting` loses the units it was handed,
its three null-unit guards and the re-record repair: a location is open while its unit has not filled in, which the
location answers. `SitingMaker` builds no units, and `DayUnits.unit_of()` is gone.

**Measured.** `tests/probes/placement_rows.gd` prints the same on main and the branch, and day 3 of
`tests/probes/walk_rows.gd` is identical (the whole probe outlasts its 900-second cap, so days 4 to 14 were not
compared). No probe line moved when the beats came in their locations' order.

**Fable's review of the built pull request** found its design standing as built, and ruled both of the builder's
open readings as the design: the replacement for `test_day_units.gd`'s `unit_of()` check (every location is held by
exactly one unit), and `give_back()` forgetting the beat even where a section was swapped over it ("forgets both").
It also ruled that `beats()` does not remove duplicates, since no game state puts one beat on two locations, and
that the check standing in for that case holds instead that a plan put over a beat ends it.
