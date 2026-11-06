# minty-quail — Which calm ground is spoiled gets a check on a day built to make the repair choose · 2026-11-06

The last gap in minty-quail's `tests-coverage-gaps.md`: `EventScheduler._is_spoiled()` decides which
calm ground the walkability repair keeps a route to, and making it always answer "not spoiled" failed
no suite (breezy-chipmunk).

**When the answer can matter.** `_is_spoiled()` is read only by `_calm_to_keep_reachable()`, and only
when the day's resistance target stands in a calm area (day 12's swing park). It changes the outcome
only if the repair has to drop bodies and, at some step, the clean calm area is cut off while a
spoiled one is still reached.

**Searched through the game's own planning, found nothing.** 60 day-12 builds (seeds 1000 + 31k, every
other calm area used so it is spoiled, `_is_spoiled()` made to answer "not spoiled" in the same
process): no body was dropped by the repair on any of them. A forced search over 40 (seed, calm area)
combinations, each tile of the area as the target and the drop loop replayed with both calm sets:
some targets were cut off by bodies, so bodies were dropped, and the two calm sets never dropped a
different number. The route tree keeps calm ground reachable and the placement keeps bodies off the
corridor, so on those seeds the case is not reached in play.

**Built.** `test_events_scheduler.gd` builds day 12 of city 1000 with `CityMap.close_streets()` (the
game's own writer) closing every street but those the home, the swing and the two other calm areas
need; the area she used is the spoiled one, the other is clean, and the pinned draw
(`_CHOICE_DRAW_SEED`) puts bodies on the one street to the clean area. The check reads that, with every
body the day kept, the clean area is reached from home. With `_is_spoiled()` answering "not spoiled"
the repair stops earlier (172 plans on the game, 176 mutated, on the first draw tried) and the clean
area is cut off: the check fails. `tests/spoiled_ground.gd` stays a copy of the rule, its sentence about
the gap now pointing at this day.

**Rejected.** Handing the scheduler a hand-built plan list or calling `_ensure_the_city_is_still_walkable()`
from a test: the repair has no entry but `build_day()`, and a private call or a test-only wrapper
breaks the rule that tests go through what the game exposes (curly-rabbit #1098/#1095). Removing
`_is_spoiled()`: a game rule stays unless the player lets it go.
