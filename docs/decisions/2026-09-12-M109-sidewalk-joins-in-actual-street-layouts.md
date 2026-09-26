## M109 — Sidewalk joins in actual street layouts — 2026-09-12

PLAYTEST-65 reports that the sidewalk is still not continuous and requests tiles placed as they
appear in the game. The earlier three-cell neighbor strips were insufficient to establish
continuity through repeated runs and junction corners. The review now uses the actual generated
map and `GroundTiles.source_for`, retaining both two-tile sidewalk bands and the six-tile street.
The accepted F/P2 mother artwork, curb textures and runtime placement remain unchanged.

Inspection of the current 32×32 PNGs finds the plain sidewalk's strongest middle horizontal joint
at row 15, east/west curb joints at row 14, the south curb at row 13 and the north curb at row 15.
The measurement takes the minimum row-mean RGB brightness over rows 10–19 and columns 4–27,
excluding the side curb strips. Thus a family can share a broad paving pattern and still have
misaligned joints. Actual-layout evidence is a diagnosis of the current tiles, not a claim that
the remaining material and seam correction is complete.

`docs/evidence/sidewalk-layout-review-2026-09-12/` retains seed 4242 at days 1 and 14, with
12×12 ordinary and main-road junction crops at `[25,25,12,12]` and `[109,25,12,12]`, plus
6×14 vertical and 14×6 horizontal street runs. The capture uses the game's generator, day repaint,
ground selector, TileSet and texture resolver. Native and nearest-neighbor 4× CPU assemblies place
the selected 32×32 PNGs edge-to-edge, with labels outside the tile areas. They are ground-only
assemblies, not gameplay screenshots; building-covered cells have no ground tile.

Visual review confirms a brighter, more textured curb-paving band beside the plain interior and
misaligned slab joints through repeated runs. Day 14 also records all six damaged sidewalk
variants in their actual map positions. The saved source-ID grids, resolved texture paths, input
hashes and frozen PNGs make the exact comparisons reproducible. A fresh rebuild matches the layout,
input tiles, ten crops and four sheets byte for byte; CLI rejection checks, Python static checks
and doc lint pass. No runtime texture or code changes are part of this review. Sidewalk repair
remains in `TODO.md`, with the accepted curb and mother artwork preserved.
