priority: later

# olive-newt — The return-patrol check named for the rigged bag fails without the rig · filed 2026-11-17

**Where it comes from.** No words of the player's: the delta review of #1488 (one declared table of
event density) found it on 2026-11-16, and the filer proposes the entry and its band.

**What was found.** In `tests/test_return_patrols.gd`, the rig that owes her a police patrol back
after she has been let go (`_rig_the_next_patrol()`, called from `owe_the_return()`) is held by one
test only, the one with the ordinary row capped: with the call removed, it fails and every other
check passes. Among them `_test_each_patrol_comes_within_its_rigged_bag`, whose name says it checks
the rigged bag, passes without the rig, since #1477 the ordinary bag hands out enough patrols that
the suite meets one anyway (checked by the review of #1505 with the call removed).

**Item:** `suite-holds-the-rig.md`. `suite-holds-the-rig.md`.
