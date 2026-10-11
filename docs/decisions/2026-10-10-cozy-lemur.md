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

**The routes go round by the pavement.** Over 12 seeds, 42 route cells held a post's tile: the day's
route tree ran down the carriageway band through the row, a route she cannot walk and a route line
drawn through posts. `RouteTree._ways` and `_ways_including_the_spine` refuse a step onto or off a
post's tile, the pavement entry staying open, and the route rig (`route_rig.gd`'s `_post_tiles()`)
blocks every tile within her body's reach of a post; `tests/test_route_rig.gd` has a plan across a
mouth going round the row. *Built where the entry said a route "must go round on the pavement";
the change to `RouteTree` itself is open to overturn.*

*Left as it is, open to overturn:* crowd walkers have no bodies and still walk through the posts.

The stills are in [bollards-2026-10-11](../evidence/bollards-2026-10-11/): the row at a precinct's west
mouth on seed 500, day 1, and her stopped at it with the collision outlines drawn. The review item
[cozy-lemur](../review/2026-10-10-cozy-lemur.md) asks the player to walk one.
