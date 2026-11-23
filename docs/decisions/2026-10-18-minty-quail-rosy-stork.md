# minty-quail — The live event's four own-file members go private (tests-own-class-members) · 2026-11-23

**What was asked.** `tests-own-class-members.md`: a member only its own class and the tests use becomes internal,
its tests checking what the class does from outside (curly-rabbit #1098). Built as #1673 by a Sonnet agent from an
Opus design, for the live event's charge radius, chase age, clear line to a point and notice time.

**What was built.** Each suite asks what the game asks: the robber's stand-off from its pursuit settings; the day-3
dog's age, which agreed with its chase clock on every frame of the case; the notice start a stream-out carries, from
the put-back event's save; the line to her from where the event is told she is; a guard's warning bound from his row.
The two pursuit cases whose subject is the tile walk moved to the passability suite and ask the city map. A check that
duplicated the one below it was deleted. The four are private, the behaviours' own forwards keep their names, and the
field the notice time collided with is renamed for what it holds, how long the notice is to run (the length the
director gave, or a crossing's crouch made longer), as `_notice_length`. With no suite calling it any more, the call
that changes the live event's phase is private too (`_transition()`, the design's last pull request folded in). Docs
that named the four as public, one sentence of the events skill's pursuits reference among them, say what is true now.

**Measured.** The nine suites went from 3359 checks to 3360 (one duplicate deleted, two steps added to the day 13
guard's not-parked case), the three finale suites stayed at 9457. Each rewritten check failed under the mutation the
design named: the own-body exemption dropped, the strict mover used, the notice restarted at the restore, no notice
passed by the director.
