# Carrying mother style-transfer preparation

This evidence preserves the SVG-first input for the carrying mother family requested in
PLAYTEST-62. The source atlas is 1920×1024: five columns (`front`, `back`, `side`,
`front_diagonal`, `back_diagonal`) and two rows (`a`, `b`), with 384×512 cells. Each source is
centered in its cell and its canvas bottom is at y=448. Native and 8× Godot rasters are retained
beside the atlas; `source-manifest.json` records each SVG hash and its future PNG destination.

`pushing-family-reference-sheet.png` assembles the existing pushing mother PNGs in the same
five-view/two-frame layout. It is an identity and rendering comparison reference; the carrying
SVG sheet remains authoritative for pose, geometry, placement and transparent alpha.

The SVGs and their `.import` files are present at source commit `105ef597` (the fetched M109
starting tree), before raster generation. The generator input roles and exact prompts are
preserved in [`prompt.txt`](prompt.txt) and [`background-correction-prompt.txt`](background-correction-prompt.txt):
the carrying SVG atlas is the geometry target, the urban and cardinal reference images are style
only, and the existing pushing PNG family supplies identity and rendering continuity. The first
raw output is retained as `carrying-sheet-generated.png`; the corrected background-only output is
`carrying-sheet-background-corrected.png`.

Preparation used Godot 4.7.2 for SVG rasterization. Registration used CPython 3.14.7, Pillow
12.3.0 and the locked `uv` environment, reusing `tools/remove-checkerboard.py` and the prior
registration algorithm. The source manifest records dimensions, bottom-center anchors, runtime
usage, source hashes and review evidence for every carrying frame.

Prepare the source evidence with the locked Python environment:

```sh
uv run python docs/evidence/style-transfer-player-family-2026-09-12/convert.py prepare docs/evidence/style-transfer-player-family-2026-09-12/source
```

The generator input is `source/carrying-sheet-svg.png`; it has a genuinely transparent background
and no labels or extra objects. The first generator output is preserved as
`carrying-sheet-generated.png`; it contains painted background artifacts and is retained as the
source for the accepted background-only correction. The corrected raw output is
`carrying-sheet-background-corrected.png`. Registration reuses the established
checkerboard extraction and color-extension algorithm, fits each cell to its 8× SVG bounds,
downsamples to native dimensions, and reapplies the native SVG alpha:

```sh
uv run python docs/evidence/style-transfer-player-family-2026-09-12/convert.py register \
  docs/evidence/style-transfer-player-family-2026-09-12/registered \
  docs/evidence/style-transfer-player-family-2026-09-12/carrying-sheet-background-corrected.png
```

The registration output contains ten native PNGs, measurements, an extracted atlas and an
SVG-left/PNG-right comparison. `convert.py` rejects unknown modes and refuses to overwrite an
existing output directory.
