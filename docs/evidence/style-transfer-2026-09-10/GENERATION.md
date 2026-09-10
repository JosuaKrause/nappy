# SVG-to-PNG experiment — generation and registration record

This is experimental output and measurement evidence, not an approved style reference.
Generator: built-in `image_gen.imagegen`. Inputs are the existing SVGs rendered by Godot
4.7.2, `graphics-reference-urban-01.jpeg` for illustrated urban linework/material, and
`graphics-reference-cardinal.jpeg` for the supplied style-transferred gameplay appearance.
The latter references are in the parent evidence folder. UI and debug annotations are excluded.

## Runtime source atlas

`rig-sheet-svg.png` is the exact geometry input, 1152×1536. It has 384×512 cells, three columns
and three rows. SVGs are rasterized at 8×, horizontally centered in their cells, with each
SVG canvas bottom at cell y=448. Rows are front, back, side; columns are mother A, mother B, pram.
`*-svg-8x.png` and `*-svg.png` preserve the 8× and native rasters. `rasterize-svg.gd` implements
the Godot SVG rasterization without changing the source drawings.

The exact prompt for `rig-sheet-generated.png`, with inputs in the order above:

> STYLE TRANSFER of the exact sprite atlas in IMAGE 1. It is one 1152x1536 atlas, three columns and three rows with 384x512 cells. The atlas contains 9 sprites. Top row: mother facing viewer pose A, same mother facing viewer pose B, pram front with baby's face. Middle row: mother rear pose A, mother rear pose B, pram rear with NO visible baby. Bottom row: mother east profile pose A, mother east profile pose B, pram east profile. Strictly preserve every sprite silhouette, its original pose and orientation, pixel size relative to canvas, clothing boundaries, wheel centers and hand positions, exact 3x3 placement and blank padding. Do not scale or rearrange the sprites. Each cell baseline remains 448 pixels from its top. Image 1 owns ALL geometry including big heads and compact bodies. Images 2 and 3 are STYLE ONLY: fine dark urban comic ink, painted fabric and subtle material shading, expressive face detail within the original face shape, blue coat seams on the prams, wheels with hub details. Keep red coats, brown hair, blue jeans, dark shoes and dark navy prams with cream hoods from image 1; no new bun or changed clothing. Replace flat fills with finely illustrated texture within existing shapes, without adding anything outside their silhouettes. Same woman consistently in all 6 frames. No background, cast shadows, captions, panel lines, UI, debug notes, arrows, or new objects. Genuinely transparent background between and around all sprites. No checkerboard. Return only the restyled atlas with the identical aspect ratio and registered arrangement.

The generator returned a differently sized RGB atlas with a painted checkerboard, so the raw
file is not a drop-in texture. `tools/remove-checkerboard.py` supplies the alpha extraction in
`rig-sheet-extracted.png`. Registration rescales the atlas to the source sheet dimensions,
measures each cell's alpha bounds above 192, fits its retained artwork to the corresponding
8× SVG alpha bounds, extends retained edge colors into transparent gaps, downsamples to native
size and applies the original native SVG alpha. `registration.json` records every bound and
dimension. This guarantees canvas and alpha equality, not identical interior feature locations.

The script uses Pillow from the project lockfile. Reproduce without overwriting the preserved
inputs or existing runtime assets:

```sh
uv run python docs/evidence/style-transfer-2026-09-10/register-transfer.py /tmp/nappy-transfer-reproduction
```

The new directory contains `rig/*.png`, the extracted atlas and registration measurements.
The runtime copies are `assets/illustrated/svg-transfer/rig/*.png`. Their alpha bytes match
the native SVG rasters exactly. `rig-comparison.png` shows original SVGs on the left and
registered PNGs on the right, both enlarged 4× with nearest-neighbor sampling for inspection.

## Single-sprite probes

`pram-side-generated-v1.png` uses the 24× raster of `assets/rig/pram_side.svg` (864×720), then
the same urban and cardinal references. Exact prompt:

> Edit image 1 only: exact registered SVG-to-PNG game sprite style transfer. Image 1 is an 864x720 raster of a 36x30 SVG, the absolute geometry template. Images 2 and 3 are STYLE ONLY: fine dark ink contours, warm muted illustrated urban materials and gentle painted shading, ignore every HUD, debug note, icon, arrow, background scene and person. Restyle this single east-facing pram while keeping EXACT canvas aspect ratio, every silhouette edge, wheel center, wheel radius, handle position, canopy outline, body shape, object occupancy and transparent empty gap from image 1. The pixel locations of all existing shape boundaries are locked; add fine cloth seams, subtle fabric shading, metal detailing and wheel hub detail inside those existing shapes. Do not redesign the pram, add a baby, change perspective, shift, recenter, shrink, crop, rotate or introduce padding. Preserve existing dark blue body and cream canopy colors. No new objects, cast shadow, background, text or checkerboard. Genuinely transparent RGBA background including all existing gaps. Return only the replacement sprite on the identical 864x720 canvas.

That output is 1374×1145 with no alpha. `pram-side-alpha-retry.png` uses that output and the
original 24× pram raster as inputs. Exact prompt:

> Image 1 is the pram artwork to repair. Image 2 is the exact original geometry template. Remove the painted checkerboard entirely and output a true alpha transparent PNG cutout. All gray/white checkered regions outside the pram and between the wheels must become actual alpha=0, not recolored or painted. Keep the illustrated pram itself unchanged including all dark blue fabric, cream canopy, dark handle and wheels. No backdrop, no new shadow. Register output to image 2 exactly: 864 x 720 pixels, canvas and subject proportions, wheel centers, ground contact, handle and canopy match image 2. Preserve the fine ink, fabric seams and painterly detailing from image 1. Return true RGBA, no checkerboard pixels anywhere.

The retry also paints a checkerboard. Neither single-pram output is used by the runtime.
The default extractor leaves darker checker squares in the first pram probe; do not treat it
as a general-purpose alpha solution merely because it emits an RGBA file.

`mother-side-generated-v1.png` uses the 24× raster of `assets/rig/mother_side_a.svg` (624×1104),
then the same urban and cardinal references. Exact prompt:

> Exact geometry-preserving style transfer of image 1, a single game sprite of a mother facing east with hand extended to push a pram. Image 1 is the geometry template; images 2 and 3 are STYLE REFERENCES ONLY. Preserve the exact silhouette, proportions, pose, east-facing orientation, feet, shoes, hand position, clothing boundaries and placement on the 624x1104 canvas from image 1. Do not add pram or bun beyond the silhouette; do not change clothing colors (red coat, blue jeans, dark shoes, brown hair). Replace the flat interior fills and thick featureless lines with fine ink urban illustration, face detail within existing head shape, coat stitching, fabric folds and subtle warm painterly material shading matching the references. Preserve every alpha gap and all padding. No shift, resizing of the subject, cropping, different perspective, extra objects, floor, shadow, text, debug notes or interface. True transparent RGBA background. Geometry from image 1 takes precedence over proportions in the style images. Return only the replacement sprite.

This probe is also RGB with a painted checkerboard. The lighter checkerboard can be extracted
by the existing script. The complete atlas supplies the consistent runtime family instead.
