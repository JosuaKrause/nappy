# brisk-wombat — The mark and its robber never appear in front of her · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 7: "I just had one appear out
of nowhere while I was walking through an alley and then a robber also appeared out of nowhere and
instakilled me.")*

**Built (PR #414).** Anything the director places while she is out in the city is tested as a box
against her screen, not as a point: the mark's 32px picture and the robber's 22 by 44px body. A
relocated mark lands only where both the mark and its guard's spot are off screen, and a robber is
never placed within his own `pursues_within` of her. At dawn, before she can see anything, guards
ignore the screen and keep clear of the doorstep, so the day's draws depend only on the run seed and
the day, retries included.

**Measured** over six cities: 980 relocations, none showing the mark or its robber, none left
unguarded. Of 30 task guards on days 8, 9, 11, 12 and 13, 29 are placed and none in view; the one
left unguarded (seed 90210, day 11) has every spot in its band on her screen, and a guard is refused
rather than placed in view. That trade is open to overturn.
