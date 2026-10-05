# polite-rabbit — Excitement does not go through a wall · built 2026-10-04

*([plaid-wombat](../playtests/2026-10-04-plaid-wombat.md), inbox #554: "Excitement should not go
through any wall but it's not straightforward. If the player is partially in a wall they should not be
protected so the blocking should happen in the middle of the wall (or one tile deep)", answering
whether it was the robber's field only or every source's; from
[freckled-goose](../playtests/2026-10-04-freckled-goose.md), #544: "Also excitement shouldn't go up
behind a wall at least".)*

*(And [bouncy-kestrel](../playtests/2026-10-04-bouncy-kestrel.md), inbox #568: "half a tile was only
supposed to be done if the wall is only one tile wide otherwise it should be one tile"; "Near the end of
the building the same spacing is used so a 2x8 building has a 6 unit long line through its middle".)*

**What was built** (PR #567). `CityMap.wall_between(from, to)` says whether a building stands between
two points, exactly: it walks the tiles the line crosses, and each building tile decides for itself
whether it is thick or thin. A tile with a corner where four building tiles meet is part of a thick
building and blocks once the line is a tile deep from open ground (`Tuning.WALL_SHIELD_DEPTH`, 32px);
every other building tile is part of a one-tile wall, the bend of an L included, and blocks at the
wall's middle (`Tuning.THIN_WALL_SHIELD_DEPTH`, 16px). So a corner clipped or a face run along blocks
nothing, her body poking into a wall (14px) shields her from nothing, a one-tile wall blocks at its
middle, and a 2x8 building blocks along a middle line six tiles long, one tile in from each end, as the
player described. Reading the rule as "half the wall's thickness along the line" was rejected: a
slanted line across a one-tile wall runs more than a tile inside it and would never block.
`EventInstance.contribution_at()` and `CrowdAgent.contribution_at()` both ask it (horn and bump jolts
included), so the meter, the halo's pick and the caret read the same answer; the caret asks it between
where the two bodies will be at each projected step. Interiors have no map and are unchanged.
`docs/EVENTS.md`, `docs/MECHANICS.md` and the **events** skill say so; `tests/test_wall_shield.gd`
pins the geometry on hand-built maps, including a 2x8 building's open ends.

**Measured** (`docs/evidence/polite-rabbit-walls-2026-10-04/`): a busker 160px away beyond a building
read 17 on the meter before and 0 after; a corner cut between half a tile and a tile deep shields
nothing. Over 184 routes on three seeds and four days, events deliver 1.1% fewer gross points (the
largest single day, seed 4242's day 1, 3.9% fewer); the crowd is unchanged and no row of
`docs/COSTS.md` moves, whose header now says rows are priced with nothing built between. The wall test
costs about 23 to 53µs a frame on day 1 on the desktop; whole-frame buckets moved within run-to-run
spread, so the cost is bounded rather than measured.

**Proposed, not asked for, and open to overturn:** depth as straight-line distance from open ground;
"building" as a tile `is_walkable()` refuses, ground off the map counting as building, closures,
barriers, gatehouses and event bodies not blocking; blocked as zero, not reduced; the line from the
source's own position to her centre; a point exactly at the depth blocking; horn and bump jolts blocked
too; the evidence recipes kept in the evidence folder. **Left open:** interiors (their plan would need
to answer `wall_between()`), the debug fields layer still drawing through buildings, and a pursuer's
140px notice still working through them.
