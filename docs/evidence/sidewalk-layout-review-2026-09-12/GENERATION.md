# Actual-map sidewalk layout review

This evidence places the current ground textures edge-to-edge using the same map generator, ground
source selector, TileSet source IDs, and illustrated texture resolver as the game. It is a CPU
assembly of ground tiles rather than a gameplay capture; dark blank cells mark building-covered
coordinates where the game paints no ground.

Seed 4242 is recorded at day 1 and day 14. Each day includes 12×12 ordinary- and main-road junction
crops with all four block corners, plus full-period ordinary vertical, ordinary horizontal, and
main vertical runs. Every six-tile cross-section contains both two-tile sidewalks and the two-tile
carriageway. Labels sit outside the tiled areas.

[`layout.json`](layout.json) records each crop's map coordinates, source-ID grid, resolved texture
path grid, and semantic tile-type grid. [`manifest.json`](manifest.json) hashes the generator,
selector, TileSet, resolver, tool files, and every resolved PNG used by the crops. Exact input PNGs
are frozen under [`inputs/tiles/`](inputs/tiles/). The native crop files are under [`crops/`](crops/);
the day sheets also have nearest-neighbor 4× views.

Run the retained-authority rebuild into a new directory, then compare every byte:

```sh
uv run python docs/evidence/sidewalk-layout-review-2026-09-12/assemble.py build \
  --output-dir /tmp/sidewalk-layout-review-rebuild
uv run python docs/evidence/sidewalk-layout-review-2026-09-12/assemble.py verify \
  --rebuilt-dir /tmp/sidewalk-layout-review-rebuild
```

`build` verifies the retained code, TileSet, tool-version, and live resolved-PNG hashes before it
creates the requested directory. Its Godot headless scene runs through the project so autoloads such
as `Tuning` are available. Both commands reject unknown arguments; `build` refuses an existing
output directory.
