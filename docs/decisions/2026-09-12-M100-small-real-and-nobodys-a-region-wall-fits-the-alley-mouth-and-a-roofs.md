## M100 — Small, real, and nobody's · a region wall fits the alley mouth, and a roof's northern edge is ground, 2026-09-12

*(2026-09-11, playtest 57: "also allow going in a little bit for northern edges of roofs"; "roofs
also should be drawn over objects. the barrier looks on top of the roof in those pictures.")* Two
agent commits on `feature/roof-edge-and-band`, reviewed here. **Measured first, both
orientations, on seed 2199579682, day 7.** A region wall across a road is placed by
`SealPlanner.place_hard_on()`, which already overrides the `roadblock` row's shape to a 32px point
per body, three bodies at exactly 64px spacing across the 192px carriageway: body and picture
agree and fit the street, so the gap the player measured there was the pram's body alone. A wall
at a crossing alley's mouth was placed by `SealPlanner.alley_mouth_wall()` with the row's own
`GroundShape.band(60.0)`, a 120px-wide capsule across a 64px alley, 28px onto each neighbouring
lot: that is the barrier that read as standing on a roof. **What stands**:
`RegionPlanner._alley_mouth_wall_body()` overrides the returned body's shape to a point of half the
alley's width (32px), the same trim the road case already had, so the band draws and collides
edge to edge with the alley's paving; a single 64px body across a 64px mouth still closes it, so
no sealing guarantee moved. The override sits in `RegionPlanner` after the call because
`SealPlanner` was outside the agent's fence; folding it into `alley_mouth_wall()` itself is a
follow-up so a future caller cannot forget it. **Rejected**: sorting roofs above the entities
layer. Buildings are drawn beneath the entities on purpose, since sorting a building against
entities puts cues and the player under a roof (`City`'s top doc); fitting the band was enough.
**The roof's northern edge**: `Building.NORTH_EDGE_INSET`, 6px, pinned and open to overturn. The
body's south-north half-extent shrinks by half the inset and its centre shifts south by the same
half, so the south edge stays on the lot's kerb and the north edge sits 6px inside the lot; no lot
tile becomes walkable. Tests: every crossing alley's wall body draws within its own tile rect on
the across-alley axis over the regions suite's seed sweep, and a built building's body north edge
is the inset south of its lot's with the south edge and the east-west extent unchanged. Evidence:
`docs/evidence/m100-alley-wall-2026-09-12/`, the run folder and `alley-wall.png`, the same
alley playtest 57 stood at, with the bounding-box layer showing the wall's body flush inside the
paving. Two attempts to frame a plain road wall landed on a building and a door, and the road
case was already covered by the test, so no picture of it was kept.
