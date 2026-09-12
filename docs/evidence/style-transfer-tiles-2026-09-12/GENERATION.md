# Outdoor tile style transfer

The current comic redraw's prompts, raw outputs, registration script and comparisons live in
[`comic/`](comic/). The files described below preserve the original surface-treatment batch;
the player's verdict and the change of drawing contract are in PLAYTEST-64 and DECISIONS.

Reproduce the comic tiles into a fresh directory:

```sh
uv run python docs/evidence/style-transfer-tiles-2026-09-12/comic/register.py /tmp/comic-tile-reproduction
```

The comic prompts give the two approved references authority over drawing style and use each
SVG sheet as a subject/layout diagram. `generated-01-layout.png` and `generated-02.png` through
`generated-04.png` are the selected raw inputs; `generated-01.png` preserves the first road
candidate. Each square output is 1254×1254. `register.py` uses CPython 3.14.7 and Pillow 12.3.0,
extracts normalized quarter-sheet cells with a three-pixel atlas-divider allowance, and writes
opaque 32×32 derivatives. Individual generated paint strokes are registered to the source
marking rectangles on the generated plain asphalt. The east curb uses the generated west
curb's stone strip at its source edge anchor. `registered/registration.json` under `comic/`
records these actual crops and destinations. The source SVGs are unchanged.

The full run folders under `runtime/` preserve the initial candidate's gameplay evidence,
including each external shot output as `capture.png`. These commands produced them:

```sh
./tools/shot.sh /tmp/nappy-cafe-vertical-tiles.png 4 --seed 1489549000 --day 2 --spawn event:cafe_tables --invincible --layers 2
./tools/shot.sh /tmp/nappy-cafe-horizontal-tiles.png 4 --seed 1489549001 --day 2 --spawn event:cafe_tables --invincible --layers 2
```

The folder names carry build and seed provenance. These stills include collider overlays;
the player and crowd partly obscure the cafés. They do not show the comic redraw, all café
facings, a stroller crossing a tree bed, or motion. They remain evidence of the initial batch.

## Original generation inputs

The 59 SVG sources in `assets/tiles/` are rasterized by Godot at native 32×32 and 8× sizes.
Four 1024×1024 source sheets contain sixteen 256×256 cells in row-major order; the final
five cells are unused. `source/source-manifest.json` records source hashes, cell coordinates,
SVG/PNG pairs, anchors and runtime consumers. The existing SVGs precede this conversion
at source commit 28fe845.

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
