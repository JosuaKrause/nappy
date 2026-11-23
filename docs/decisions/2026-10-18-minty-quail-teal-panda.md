# minty-quail — Two suites reach a live event's phase without transition() (tests-one-module, the events) · 2026-11-23

**What was asked.** `tests-one-module.md`'s events entry: suites that call `EventInstance.transition()` to put a live
event in a phase reach it the way the game does or take a fake (inbox #1156 and #1159 in gray-dolphin; the player's
pick that a member only tests use becomes internal, curly-rabbit #1098). Built as #1659 by a Sonnet agent, for the moves
and route lines suites.

**What was built.** An event that is over is ended the way the game ends one, `end_now()`. The fire engine parks by
driving its route to its end; the patrol car and the charging dog are stepped through a drive, a leave and an end, their
move never reading parked. A parked engine never leaves in the game and the row validation refuses a parked patrol or
dog, so the checks that put them there by hand read what the game can reach; that leaving clears the parked flag is no
longer asked, since no event the game makes is parked when it leaves.

**Measured.** The moves suite went from 18 checks to 21, the route lines suite stayed at 6.
