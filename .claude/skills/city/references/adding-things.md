# Adding a tile type, a block purpose or a closure kind

Read this before adding any of the three. Each list is every place that has to change, in order.

**Add a tile type** — `GameEnums.TileType`, then `src/city/tile.gd` (walkable / calm / alley / road
/ colour), then an SVG in `art/tiles/`, then `assets/ground_tileset.tres` **and**
`src/city/ground_tiles.gd` in the same order (the source ids are positional and mirrored by hand),
then wherever the generator should emit it.

**Add a block purpose** — `GameEnums.BlockPurpose`, the ground it puts down in
`CityMap.open_tile_for`, `BlockPlan.is_calm` (and `Tile.is_calm` for its tile type) if it is calm
ground, and the arcs that may reach it in `CityGenerator._plan_arcs`. If it is calm, check
`MIN_CALM_BLOCKS_AT_END` still holds — `validate()` will tell you, on every seed, if it does not.
**Write it against `map.lot_rect(block)` rather than `CityMap.block_rect(block)`**, or it will cover
one block of a multi-block calm zone and nobody will notice on the lots that are one block.

**Add a closure kind** — `RoadClosure.Kind`, a row in `RoadClosure.KINDS` (name, first day, weight),
two SVGs in `art/closures/` — `<cause>.svg` lying across a north-south street and
`<cause>_vertical.svg` lying across an east-west one, drawn in the game's projection rather than
rotated — with a line for each in `ClosureMarker.CAUSES` and `ClosureMarker.CAUSES_VERTICAL` and
both in `assets/atlases/membership.json` — unless it has nothing to leave
in the road, like `CORDON`, in which case the barriers are the whole of it. Nothing else: the kinds
differ in look and timing only, because a street you cannot walk down is a street you cannot walk
down.
