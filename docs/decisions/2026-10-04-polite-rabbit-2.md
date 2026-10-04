# polite-rabbit — Excitement does not go through a wall · built 2026-10-04

*([plaid-wombat](../playtests/2026-10-04-plaid-wombat.md), inbox #554: "Excitement should not go
through any wall but it's not straightforward. If the player is partially in a wall they should not be
protected so the blocking should happen in the middle of the wall (or one tile deep)", answering
whether it was the robber's field only or every source's; from
[freckled-goose](../playtests/2026-10-04-freckled-goose.md), #544: "Also excitement shouldn't go up
behind a wall at least".)*

**What was built** (PR #567). `CityMap.wall_between(from, to, depth)` says whether a building stands
between two points: the line is blocked once it passes a point `Tuning.WALL_SHIELD_DEPTH` (16px, half
a tile) inside a building, measured as straight-line distance from the nearest open ground. It walks
the tiles the line crosses; in each building tile it shrinks the tile by 16px on every side facing
open ground and cuts a 16px disc round a corner open ground touches only diagonally, so the answer is
exact. A one-tile wall blocks at its middle; a corner clipped or a face run along blocks nothing; and
since 16px is more than her 14px body radius, her body poking into a wall shields her from nothing.
`EventInstance.contribution_at()` and `CrowdAgent.contribution_at()` both ask it (horn and bump jolts
included), so the meter, the halo's pick and the caret read the same answer; the caret asks it between
where the two bodies will be at each projected step. Interiors have no map and are unchanged.
`docs/EVENTS.md`, `docs/MECHANICS.md` and the **events** skill say so; `tests/test_wall_shield.gd`
pins the geometry on hand-built maps and against a per-pixel depth on seed 4242.

**Measured** (`docs/evidence/polite-rabbit-walls-2026-10-04/`): a busker 160px away beyond a building
read 17 on the meter before and 0 after. Over 184 routes on three seeds and four days, events lose
1.9% of their gross points (1.1% at a whole tile's depth); the crowd is unchanged, and no row of
`docs/COSTS.md` moves, whose header now says rows are priced with nothing built between. The wall test
costs about 23µs a frame on day 1 on the desktop; whole-frame buckets moved within run-to-run noise.

**Proposed, not asked for, and open to overturn:** half a tile rather than a whole one (one constant);
depth as straight-line distance from open ground; "building" as a tile `is_walkable()` refuses, ground
off the map counting as building, closures, barriers, gatehouses and event bodies not blocking; blocked
as zero, not reduced; the line from the source's own position to her centre; a point exactly 16px deep
blocking; horn and bump jolts blocked too; the evidence recipe kept in the evidence folder. **Left
open:** interiors (their plan would need to answer `wall_between()`), the debug fields layer still
drawing through buildings, and a pursuer's 140px notice still working through them.
