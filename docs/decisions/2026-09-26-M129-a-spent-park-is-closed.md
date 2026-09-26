## M129 — A spent park is closed · built 2026-09-26

*([PLAYTEST-140](../playtests/PLAYTEST-140.md): "a spent park should not be accesible and no route
should go through it".)*

**What is built.** A calm area she has settled in this act is shut the next day the way a closure
shuts ground: `ClosurePlanner.calm_to_shut()` decides it at `CityMap.repaint()`, before the day's
route tree is grown, so the tree, the region plan and the street closures all plan around it.
`ParkClosure` (a `RoadClosure` of `Kind.PARK`) stands the street closure's barrier panels and
`closed` sign at every entrance to the area's ground. Each area is checked before it is accepted and
never repaired afterwards: it stays open if shutting it would leave fewer than
`Tuning.MIN_CALM_AREAS_REACHABLE` calm areas reachable or cut any tile off from the doorstep, and
day 12's swing park is never shut on its own day. A refused area is spoiled with events instead
(`EventScheduler._spoil_the_parks_she_used`), which is what every used area got before.

**Measured** over `tests/test_spent_park.gd`'s sweep of 6 seeds × 14 days: 107 of 108 used areas
were shut and 1 was refused. The zero-cost probe's used-park mode (`M129_USED_PARKS=shut`) reads
close to the day without used parks, since the route tree never planned through calm ground.

**Choices open to overturn**: the refusal falls back to spoiling rather than leaving the area
open and unspoiled; `docs/EVENTS.md`'s "The city remembers where she went" now says spoiling is the
fallback. Stills of a shut park are in `docs/evidence/m129-spent-park-closed-2026-09-25/`, built
by a one-off script that is not committed, since no dev flag reaches a day with a used park.
