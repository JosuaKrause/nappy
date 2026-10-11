# cozy-lemur — The bollards close the carriageway at a precinct's mouth · 2026-10-11

[azure-puffin](../playtests/2026-10-10-azure-puffin.md), point 1, inbox #664:

> let's add the bollards back. it will make the middle of the road impassable when going from
> street to pedestrian road. that's okay. this is intended

**This overturns, in the player's own words, "gaps still passable"** from
[tall-walrus](2026-10-07-tall-walrus.md), which stood two posts 46px apart so she could walk between
them. `City.BOLLARD_SPACING` is 14px again, [M53, the bollard](2026-09-08-M53-the-bollard.md)'s value:
five posts on the 64px carriageway band with 4.4px between them, narrower than her 28px body at any
facing, so the band is shut to her and the pavements beside the row stay open. Each post keeps the
`StaticBody2D` tall-walrus gave it. `tests/test_bollards.gd` holds that every gap is narrower than her
body, that the row stops her walking straight at it and 30° and 45° either way from nine offsets across
the band, that the pavement either side lets her pass, and that holding a diagonal she gets past only by
sliding round the row's end. `docs/CITY.md` says the row is a detour inside the junction box, never a
cut.

**Every flood and every step but the route tree's sees the posts.** `CityMap.post_tiles()`, built
with the map (`index_posts()`), is folded into `is_walkable`, `is_open`, `walk_field_from` and
`ReachabilityGrid.build`, so every winnability check (the scheduler's, `ClosurePlanner`'s,
`RegionPlanner`'s), the red arrow's ground and every pursuer's step and catch line go round the row as
her body does; the route rig blocks every tile within her body's reach of a post (`Prop.bollard_shape()`
is the one definition of a post). `tests/test_bollards.gd` holds that a pursuer's step does not enter a
post's tile, that a flood goes round the row, and that the grid has no node on a post's tile.

**The route tree grows on the lattice without the posts** (`ReachabilityGrid.build(map, false)` in
`RouteTree.for_day`), so it still draws a branch through a row's cell, where the walk goes round by the
pavement inside the same junction box; the route line that shows it is a dev overlay. Both ways of
making the tree see the posts were tried and rejected: a step filter in `RouteTree._ways`, and a
post-aware grid, each re-grow the corridor on most days — measured by the reviewer over 20 seeds and 8
days, the tree's cells differ on 146 of 160 days and the region doors on 64 of 80 from the region-wall
day, with branches unchanged at 1,191 and second-route branches 788 to 793 — and each breaks six
authored scene recipes (`task-09-crossing`, `trailer-choice`, `trailer-dog`, `trailer-gatehouse`, the
two-mast task's mast site and a bounded-context check), and a day-10 seed of the resistance
sweep. `RouteTree.lattice_grid(map)` is the one place the posts-blind grid is built, so every tree
grown outside `for_day` (the power station's and the route tree's own tests) grows on the same lattice. *Open to overturn, at the cost of re-authoring
those recipes.*

*Left as it is, open to overturn:* crowd walkers have no bodies and still walk through the posts.

The stills are in [bollards-2026-10-11](../evidence/bollards-2026-10-11/): the row alone, her pram
against the five posts (seed 624), and her going round by the pavement (seed 500). The review item
[cozy-lemur](../review/2026-10-10-cozy-lemur.md) asks the player to walk one.
