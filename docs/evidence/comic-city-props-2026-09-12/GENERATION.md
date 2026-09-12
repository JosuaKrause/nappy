# Comic city prop redraw generation

This record covers the 12 reviewed prop derivatives requested by PLAYTEST-65: two tree
variants, the tree bed, bollard cap, water tank, two HVAC units, vent stack, two skylights and
two roof ducts. The SVG files remain the subject, native canvas, projection and functional
anchor authority. The corrected white-background redraws in `raw/roof-white.png` and
`raw/trees-white.png` supply the comic drawing language; `raw/tree_pit.png` is the opaque ground
tile. The original checker-background raws remain beside them as retained generation inputs.
The OpenAI image generation tool created the redraws using the saved style-transfer and
background-extraction prompts. `source/roof-atlas.png` and `source/trees-atlas.png` retain the
atlas inputs supplied to generation; the urban and cardinal reference images are style inputs,
not subject or layout references.
Exact prompts are preserved in `prompts/roof.txt`, `prompts/roof-background.txt`,
`prompts/trees.txt`, `prompts/trees-background.txt` and `prompts/pit.txt`.

`register-city-props.py` first renders every source SVG at 1× and 8× into `source/`, recording
the SVG SHA-256, native dimensions, anchor and runtime usage in `source/source-manifest.json`.
It applies the repository's `remove-checkerboard.py` to the corrected roof and tree raws. The
generated alpha is kept on every cropped subject before color extension, so extending edge colors
cannot turn a transparent margin into painted background. The tree atlas uses three 512×512 cells. The roof
atlas is resized to 2048×1024 and uses eight measured, nonoverlapping crops; the straight duct
crop ends at x=1600 so its long right end is retained without taking pixels from the elbow cell.

Tree visible height is fitted uniformly to the source bounds while the crown uses the available
40-pixel canvas.
Other standing props use a modest aspect-preserving fit to their source visible bounds and
bottom-center runtime anchor. The tree bed is resized edge to edge as an opaque 32×32 ground
decal. The bollard source drawing is centered at (6,6), while its runtime standing anchor is
(6,12), because `Prop` draws every standing prop bottom-center. No prop gains a collision body.

The reproducible command, run with the repository's locked Python environment, is:

```sh
UV_CACHE_DIR=/tmp/nappy-uv uv run python \
  docs/evidence/comic-city-props-2026-09-12/register-city-props.py \
  docs/evidence/comic-city-props-2026-09-12/raw/roof-white.png \
  docs/evidence/comic-city-props-2026-09-12/raw/trees-white.png \
  docs/evidence/comic-city-props-2026-09-12/raw/tree_pit.png \
  /tmp/nappy-city-props-registration
```

The script writes the 12 runtime PNGs under `assets/illustrated/svg-transfer/props/`; Godot
creates each PNG's own `.import` sidecar during the import check. `registration/manifest.json`
retains crop bounds, source bounds, fit sizes, placements and native alpha bounds. The
`comparisons/props-native.png` and `props-4x.png` sheets compare every source SVG render with
its registered PNG on a neutral slate background. The registration is visual evidence of
source placement and alpha; gameplay binding remains with the existing `Prop`, `CityDecals` and
`Building` callers through `TextureResolver`.

Preparation uses Godot 4.7.2 and Python 3.14.7 with Pillow 12.3.0 from the locked `uv`
environment. The final sheets were inspected at native size and 4× enlargement; no windowed
gameplay capture is part of this unbound-asset registration.
