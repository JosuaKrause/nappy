# Litter and garbage prop style-transfer preparation

The source atlas is a transparent 1536×768 sheet with four 384×384 columns and two rows. Its
seven cells are row-major in the fixed order `garbage_sack`, `garbage_sacks_pile`, `litter_can`,
`litter_apple`, `litter_bag`, `litter_newspaper`, `litter_cup`; the eighth cell is empty. Garbage
sacks use a bottom-center anchor at y=320 in each cell. Flat litter decals use a center anchor at
(192,192). Native and 8× Godot rasters are retained under `source/` with a source manifest.

The SVG-first sources and their imports are present at source commit `105ef597`. The exact
generator prompt is preserved in [`prompt.txt`](prompt.txt). Built-in `image_gen.imagegen` inputs
in order: `source/litter-sheet-svg.png` is the geometry target;
`docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` are style-only inputs. Their paths are relative
to the repository root except for the local source sheet. Sack and pile material remains black
plastic from their source SVGs. Preparation used Godot 4.7.2; registration used CPython
3.14.7, Pillow 12.3.0 and the locked `uv` environment.

The raw atlas is `litter-sheet-generated.png`, a 1774×887 RGB image. Registration resamples the
extracted atlas to the 1536×768 source layout. It uses the approved neutral-background
extractor on its plain white background, fits each retained cell to the corresponding 8× source
bounds, downsamples and reapplies the native SVG alpha. It writes seven `props/*.png` files plus
measurements and native/3× comparisons. `registration.json` records output dimensions and both
generated and source bounding boxes.

Reproduce from the repository root using fresh output paths:

```sh
uv run python docs/evidence/style-transfer-litter-2026-09-12/convert.py prepare /tmp/nappy-litter-source-reproduction
uv run python docs/evidence/style-transfer-litter-2026-09-12/convert.py register \
  /tmp/nappy-litter-registration-reproduction \
  docs/evidence/style-transfer-litter-2026-09-12/litter-sheet-generated.png
```

Existing output directories are refused. The saved `source/` and `registered/` directories
preserve the integration inputs and results; do not overwrite them when reproducing.
