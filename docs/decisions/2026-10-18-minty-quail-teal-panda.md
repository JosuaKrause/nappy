# minty-quail — Two suites reach a live event's phase without transition() (tests-one-module, the events) · 2026-11-23

**What was asked.** `tests-one-module.md`'s events entry: suites that call `EventInstance.transition()` to put a live
event in a phase reach it the way the game does or take a fake (inbox #1156 and #1159 in gray-dolphin; the player's
pick that a member only tests use becomes internal, curly-rabbit #1098). Built as #1659 by a Sonnet agent, for the moves
and route lines suites.

**What was built.** An event that is over is ended the way the game ends one, `end_now()`. The fire engine parks by
driving its route to its end; the patrol car and the charging dog are stepped through a drive, a leave and an end, their
move never reading parked. The game never parks a patrol car or a dog, since only a row that parks where its route
ends is parked when it is done, so their checks read what the game can reach. A row parked from the start (a market
stall, a leaf blower, a poster crew) is sent off by day 12's park cordon, and leaving clears its parked flag: a case
sends one off the way the cordon does and reads the flag before and after.

**Measured.** The moves suite went from 18 checks to 24, the route lines suite stayed at 6.
