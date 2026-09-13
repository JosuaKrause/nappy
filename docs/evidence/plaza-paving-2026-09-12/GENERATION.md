# Plaza paving registration

The runtime plaza tile is generated with the built-in image generation tool. The retained raw
output is `source/plaza-generated.png`; registration is a direct LANCZOS downsample to a 32×32
fully opaque PNG with no recoloring or paint-over. The authored `assets/tiles/plaza.svg` remains
the subject authority: one tile-wide top and left edge joint around a larger slab, rather than
the quiet square's four-quarter center seam.

The exact generation prompt was:

```text
Use case: style-transfer.
Asset type: seamless top-down 32×32 game ground tile, generated at high resolution for direct downsampling.
Input images: Image 1 is the existing plaza PNG, comparison only; Image 2 is the accepted quiet-square PNG, identity and muted-material constraint only; Images 3, 4, and 5 are neighboring sidewalk, asphalt, and grass base materials for value comparison only. Approved urban/cardinal comic references were inspected separately for style only. The authored plaza SVG is the subject/layout authority.
Primary request: Regenerate plaza paving as darker muted cool gray stone with low-contrast fine texture and clean repeating joins.
Subject/layout: Preserve the authored plaza tile's larger slab layout: one broad slab spanning the tile with a single tile-wide edge joint along the top and left edges, rather than the quiet-square four-quarter center cross. The joint must repeat cleanly across horizontal and vertical neighbors. Full-bleed tile.
Style/medium: crisp hand-inked comic-game ground material, top-down orthographic, pixel-friendly after direct downsampling, restrained authored stone variation.
Color palette: neutral/cool muted gray slate, aligned with the accepted quiet-square's darker cool stone; darker and less warm than the old plaza; between charcoal asphalt and warmer sidewalk, compatible with the muted grass base. Avoid pale beige and bright whites.
Lighting/mood: flat diffuse overcast lighting; uniform illumination; no directional gradient, glare, vignette, or bright focal patch.
Materials/textures: subtle fine stone grain and restrained slab wear, low contrast so actors and route markings remain legible.
Constraints: fully opaque 32×32 tile after registration; only plaza paving and its slab edge joint; no curb, road paint, crosswalk, grass, trees, furniture, people, vehicles, shadows, border, watermark, text, or transparent background. Do not alter the SVG or invent additional slabs.
```

The built-in generator's raw output is retained unchanged. The registration script records its hash,
the source SVG render, approved style references, the old plaza brightness reference, and frozen
neighbor materials. The sidewalk input is the approved PR138 material at `/tmp/nappy-sidewalk-138.png`
and is copied into `bundle/frozen-inputs/`; the final grass base is the rotated shared base. A later
`build --input-bundle bundle` rebuild copies only these frozen inputs and does not read installed
runtime textures. The fresh-output guard refuses an existing output directory, and `install` requires
the explicit `--replace` flag. `-h`, `--help`, and unknown arguments are handled by argparse.

Source render and registration commands:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path /private/tmp/plaza-render \
  --script docs/evidence/plaza-paving-2026-09-12/render-plaza-source.gd -- \
  --output /private/tmp/plaza-svg-8x.png \
  --source assets/tiles/plaza.svg
UV_PROJECT_ENVIRONMENT=/Users/krause/workspace/nappy-codex/.venv UV_NO_SYNC=1 \
  UV_CACHE_DIR=/tmp/nappy-plaza-uv-cache uv run python \
  docs/evidence/plaza-paving-2026-09-12/register.py build \
  --raw docs/evidence/plaza-paving-2026-09-12/source/plaza-generated.png \
  --svg-render /private/tmp/plaza-svg-8x.png \
  --brightness-reference assets/illustrated/svg-transfer/tiles/plaza.png \
  --sidewalk-reference /tmp/nappy-sidewalk-138.png \
  --output-dir docs/evidence/plaza-paving-2026-09-12/bundle
uv run python docs/evidence/plaza-paving-2026-09-12/register.py verify \
  --bundle-dir docs/evidence/plaza-paving-2026-09-12/bundle \
  --target assets/illustrated/svg-transfer/tiles/plaza.png
```

`review/repeat-neighbors-native.png` and `review/repeat-neighbors-4x.png` show repeated plaza
tiles and the neighboring sidewalk, asphalt, and grass materials. The manifest records dimensions,
opacity, source hashes, and mean RGB brightness for comparison with the old plaza and shared bases.
