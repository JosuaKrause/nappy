priority: later

# olive-newt — The return-patrol suite holds the rig that owes her a patrol · filed 2026-11-17

**Where it comes from.** No words of the player's: the delta review of #1488 (one declared table of
event density) found it on 2026-11-16, and the filer proposes the entry and its band.

**What was found.** `tests/test_return_patrols.gd` still passes, on main too, with the call to
`_rig_the_next_patrol()` removed from `owe_the_return()`, the rig that owes her a police patrol back
after she has been let go: since #1477 the ordinary bag hands out enough patrols that the suite meets
one anyway. The rig is held only by the test beside it ("with the ordinary row capped").

**Item:** `suite-holds-the-rig.md`.
