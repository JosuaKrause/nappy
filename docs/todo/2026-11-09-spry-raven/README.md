priority: now
after: 2026-10-18-minty-quail

# spry-raven — The main road is never closed: a region line crossing it is a guardhouse whose boom stays up · filed 2026-11-09

**The ask.** Said in the chat on 2026-11-07, while day 13's police column, which then dropped a
barricade mid-block on the main road, was discussed: "also there shouldn't be any barricades on the
main road ever. if a quadrant line goes through there it must become a guardhouse", then "traffic on
the main road always needs to be able to go from the tunnel to the bridge unhindered" and "(this
doesn't apply to escape)" (gentle-owl #1186). A "quadrant line" is a region boundary, the line the
region wall follows from day 9 (`Tuning.REGION_WALL_FIRST_DAY`); a guardhouse is a street door of the
wall, the two checkpoint huts and the boom over the road between them.

**Read as:** on every ordinary day, nothing that closes a street (a barricade, a roadblock, any hard
seal) stands on the main road, and its cars drive its whole length, from the tunnel at its north end
to the bridge at its south, with nothing on the carriageway stopping them. Where a region boundary
crosses the main road, the crossing is always a guardhouse, whether or not the day's routes cross
there. The escape is exempt, so its sealing of the main road, which keeps its two chains from
joining at the spine (`DaySpec.seals_the_main_road`), stays.

**The boom stays up for cars.** Asked on the board (main-road-guardhouse) how a guardhouse on the
main road lets the cars through, with Option A, the boom stays up for cars and never lowers, her
side unchanged, and Option B, no boom on the main road, only the two huts, the player answered "a"
(gentle-owl #1186). **Read as:** the main road's guardhouse keeps its boom, which never lowers, so no
car is held at it (`Crowd._stop_for_gates()` never sees it); she meets the guard as at every other
guardhouse.

**It stands two tiles in from the junction.** Asked on the board (main-road-guardhouse-spot) whether
it stands at the junction like every guardhouse or two tiles in, where a route crossing the main road
at the corner would not be taken in, the player answered "move it in so she doesn't accidentally
trigger it" (gentle-owl #1186). **Read as:** two tiles in, so crossing the main road at the corner
never triggers its two-second inspection; an alley mouth's body beside it stands a tile deeper.

**Already built elsewhere:** placement by construction (minty-quail) never offers the main road a
roadblock, neither one day 13's roadblock phase places nor one the task swaps in
(`EventScheduler._is_on_the_main_road()`), and no convoy drops a barricade any more (gentle-owl #1183,
the record minty-quail-crisp-koala).

**Item:** `main-road-guardhouse.md`, mostly built on draft pull request #1188, paused until the
refactor closes (the minty-quail `README.md`: nothing else is worked on until it is done,
gentle-owl #1210).

*Proposed, not asked for:* the band `now`, since the player named none and the work is a broken
guarantee of the player's that is mostly built already; waiting for minty-quail, since #1188 is
paused for it and its region wall and closures now sit on code the refactor rewrote.
