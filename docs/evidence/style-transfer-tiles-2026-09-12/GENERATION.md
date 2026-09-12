# Outdoor tile style transfer

The 59 SVG sources in `assets/tiles/` are rasterized by Godot at native 32×32 and 8× sizes.
Four 1024×1024 source sheets contain sixteen 256×256 cells in row-major order; the final
five cells are unused. `source/source-manifest.json` records source hashes, cell coordinates,
SVG/PNG pairs, anchors and runtime consumers. The existing SVGs precede this conversion
at source commit `28fe845`.

Each built-in image generator call uses its numbered source sheet as the geometry and palette
target, then `docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` as style-only inputs, in that order.
`prompt-01.txt` through `prompt-04.txt` preserve the exact prompts. `generated-01.png` through
`generated-04.png` are the unmodified 1254×1254 outputs.

Registration crops normalized quarter-sheet cells, rounding their pixel boundaries, resizes
each cell to 32×32 with Lanczos and restores the exact native SVG alpha. It does not fit
opaque tiles by silhouette bounds. `registered/registration.json` records the actual crop
bounds and dimensions. The comparison sheets show every SVG above its PNG; the neighbor
sheet assembles opposite road-line halves and repeated crosswalk and sidewalk tiles.
These are appearance-review candidates, not a record of player acceptance.

Reproduce from the imported repository with fresh output directories:

```sh
./tools/check.sh
uv run python docs/evidence/style-transfer-tiles-2026-09-12/convert.py prepare /tmp/tile-sources
uv run python docs/evidence/style-transfer-tiles-2026-09-12/convert.py register /tmp/tile-registration \
  docs/evidence/style-transfer-tiles-2026-09-12/generated-01.png \
  docs/evidence/style-transfer-tiles-2026-09-12/generated-02.png \
  docs/evidence/style-transfer-tiles-2026-09-12/generated-03.png \
  docs/evidence/style-transfer-tiles-2026-09-12/generated-04.png
```

Preparation uses Godot 4.7.2. Registration uses CPython 3.14.7 and Pillow 12.3.0 from the
locked repository environment. `City` resolves the TileSet sources through `TextureResolver`;
the separate mountain drawing in `CityEdge` uses the same resolver. `alley_draft` remains
prepared and unbound. Each runtime PNG has Godot-generated import metadata with its own UID.
