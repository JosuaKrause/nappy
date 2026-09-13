# Quiet-square paving registration

The runtime quiet-square tile is generated with the built-in image generation tool. The raw output
is retained at `source/quiet-square-generated.png` and copied unchanged into the bundle. The
authored `assets/tiles/quiet_square.svg` supplies the four-slab subject and its cool-stone role;
`render-quiet-square-source.gd` creates the 8× SVG raster supplied to the generator.
This material registration uses direct LANCZOS downsampling to a 32×32 fully opaque PNG, with no
recoloring or paint-over. The [paving joint recipe](../paving-boundary-joints-2026-09-12/GENERATION.md)
then completes the boundary joints using this material's own pixels and owns the runtime tile.

The built-in generation prompt is:

```text
Use case: style-transfer.
Asset type: seamless top-down 32×32 game ground tile, supplied at high resolution for direct downsampling.
Input images: Images 1 and 2 are approved urban comic style references only; Image 3 is an approved cardinal gameplay style reference only; Image 4 is the authored quiet-square SVG render and defines the subject/layout; Image 5 is a neighboring sidewalk material/value reference only. Do not copy people, buildings, UI, vehicles, text, or objects from any reference.
Primary request: Regenerate quiet-square paving as muted, darker cool stone. Preserve the authored four-large-slab pattern: one vertical and one horizontal seam crossing at the center, with restrained subtle stone speckle and fine seam wear.
Style/medium: crisp hand-inked comic-game material, top-down orthographic, pixel-friendly after downsampling, quiet and low contrast.
Color palette: cool slate blue-gray stone with dark charcoal seams; materially darker than the pale sidewalk reference; avoid bright whites. It should sit between charcoal asphalt and green grass without becoming a bright focal patch.
Composition/framing: square full-bleed tile; edges repeat cleanly horizontally and vertically.
Lighting/mood: flat diffuse overcast material response; no directional light, gradients, glare, or bright patch.
Constraints: fully opaque canvas. Only paving stone and slab joins: no curb, road paint, crosswalk, grass, trees, furniture, people, vehicles, text, signs, objects, shadows, border, watermark, or transparent background.
```

Build and review a fresh bundle:

```sh
 /Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/quiet-square-2026-09-12/render-quiet-square-source.gd -- \
  --output /tmp/quiet-square-svg-8x.png
uv run python docs/evidence/quiet-square-2026-09-12/register.py build \
  --raw docs/evidence/quiet-square-2026-09-12/source/quiet-square-generated.png \
  --svg-render /tmp/quiet-square-svg-8x.png \
  --output-dir /tmp/quiet-square-build
uv run python docs/evidence/quiet-square-2026-09-12/register.py verify \
  --bundle-dir /tmp/quiet-square-build
```

`review/repeat-neighbors-native.png` and `review/repeat-neighbors-4x.png` show repeated slab
joins and the new paving beside the shared sidewalk, asphalt, and grass bases. `manifest.json`
records raw and source hashes, registered tile geometry and opacity, plus mean material brightness
for this review. A later build may use `--input-bundle` to copy only the retained frozen references;
it never needs the installed runtime quiet-square PNG.

When refreshing a neighboring shared base while retaining the recorded quiet-square brightness
comparison input, pass that saved image through `--brightness-reference` on the fresh build.

Verify the final runtime artwork against the joint-registration bundle:

```sh
uv run python docs/evidence/stoop-bottom-face-2026-09-12/rebuild.py verify \
  --bundle-dir docs/evidence/paving-boundary-joints-2026-09-12/bundle \
  --target-dir assets/illustrated/svg-transfer/tiles
```
