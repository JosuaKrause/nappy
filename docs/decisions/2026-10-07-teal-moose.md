# teal-moose — The burnt-building task is at its door · 2026-10-11


[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 1, inbox #601:

> burnt building task is not at the door of the building

**The door was refused for being on a street held for the day.** `ResistanceDirector._ride_to_the_door()`
put the contact, and with it the red arrow and the touch, on the facade door only when the door's
own frontage tile passed the contact refusals: legal ground, unobstructed, reachable from home, and
not held for the day. A street is held so that no catalogue row is sited on it (a region door's
street, the streets round her block, a closure's segment), but she walks it like any other. A day-3
fire's front was open on day 3, and the same door's frontage is often held on day 8, so the contact
fell back to the facade straight behind the shell, up to five or six columns from the drawn door.
The arrow and the touch both ride the contact, so both were off the door together; the reach to
accept the task was right. A sweep found this on about 18 of 85 remembered fires (seed 1's front
(6,14) put the arrow at x=208 against a door at x=240); the fallback burnt building, when no fire is
remembered, agreed with its door on 18 of 18.

**`_door_can_be_touched()` accepts the door when any of the three frontage-lane tiles within
`DOOR_REACH` of it** (the one below it and one to each side, 45px from the door against a 50.6px
reach) **is legal, unobstructed and reachable, held or not**, the carve-out day 9's door already
uses. The reach rule is unchanged and no stand point is added; the facade behind the shell is used
only for a door with no standable, reachable ground at all. `tests/test_burnt_door.gd` runs the real
day order on seed 1 and sweeps fronts: arrow, contact and `City.way_in_behind()` are one point within
`DOOR_REACH`, some of the doors on held streets, and the fallback agreeing; five of its checks fail
on the old code. The stills, [burnt-door-2026-10-11](../evidence/burnt-door-2026-10-11/), from a
temporary rig not committed, show the arrow on the boarded door for a remembered fire six columns
along from the shell and for the fallback.

*Chosen where the entry was silent, open to overturn:* a held street no longer disqualifies a
door's frontage, and any of three frontage tiles will do, not only the door's own. **Left open:**
about 9 of the 85 remembered fires have no standable, reachable tile by the door, and on all but 2
the shell's own frontage is unreachable from home too, so day 8 cannot be won there whatever the
point; that is queued as [spotted-ibis](../todo/2026-10-11-spotted-ibis/README.md). A one-row facade
has no door, and its point is on the facade at the shell's column.
