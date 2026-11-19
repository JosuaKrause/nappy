# The road stubs go

`CityEdge.Piece.ROAD_EAST` and `ROAD_WEST` (`src/city/city_edge.gd`) are deleted, with what only they
reach: `CityEdge.ROAD_ON`, the picture `art/props/road_on.svg`, its line in
`assets/atlases/membership.json`, its row in `docs/GRAPHICS.md`, and the check in
`tests/test_atlas_leaf_consumers.gd` that holds it. A builder confirms first that nothing reaches them
(`rg -n "ROAD_EAST|ROAD_WEST|ROAD_ON|road_on" src tests tools assets docs`) and rebakes the atlas as
**svg-art** and **illustrated-png** say for a removed membership line. It waits for #1564 (the city
edge's kinds), which renamed the enum these pieces are in.
