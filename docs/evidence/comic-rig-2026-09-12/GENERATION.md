# Comic rig generation and registration

This evidence records the complete player rig redraw: ten mother-pushing frames, ten
mother-carrying frames and five pram views. The source SVGs define the characters, actions,
directions, palette identity, native canvas and bottom-center ground anchors. They are concept
inputs rather than contours to trace. The two approved reference images define the comic drawing
language: expressive dark ink, purposeful anatomy and construction, painted material folds and
deliberate shadow planes.

The pushing and pram derivatives supply the current runtime assets. The carrying rows and
their registered PNGs are retained rejection evidence for PLAYTEST-65, not reference art or
the current carrying textures. The active carrying family is documented in
[the carrying stride record](../comic-carrying-strides-2026-09-12/GENERATION.md).

The registered derivatives keep every source canvas dimension and bottom-center anchor. They preserve
the generated comic silhouettes and transparent gaps, so they do not reuse the SVG alpha. This is
required for the newly drawn shoulders, elbows, legs, coat shapes, hood curves, bassinet depth and
wheels to survive registration. `registered/registration.json` records the source occupancy,
generated bounds, aspect-preserving fit and final ground line for every asset.

## Generator inputs and outputs

Generator: built-in `image_gen.imagegen`.

The mother atlas uses these inputs in order:

1. `docs/evidence/style-transfer-2026-09-10/rig-sheet-svg.png` — cardinal pushing-mother and pram
   concept sheet.
2. `docs/evidence/style-transfer-eight-directions-2026-09-10/diagonal-sheet-svg.png` — diagonal
   pushing-mother and pram concept sheet.
3. `docs/evidence/style-transfer-player-family-2026-09-12/source/carrying-sheet-svg.png` — carrying
   mother concept sheet.
4. `docs/evidence/graphics-reference-urban-01.jpeg` — approved comic style reference only.
5. `docs/evidence/graphics-reference-cardinal.jpeg` — approved comic style reference only.

`mother-prompt.txt` produced the retained first candidate,
`mother-atlas-generated-v1.png`, 1402×1122 RGB. It established a coherent family but made the
mother too squat and childlike, and its broad profile and diagonal poses had to shrink to fit the
native canvases. It is retained as a raw candidate and is not a style reference or runtime source.

`mother-prompt-v2.txt` corrects the adult anatomy, compact stride, bent pushing arms, native-width
silhouettes, flat comic shadow planes and common full-body scale. Its selected raw output is
`mother-atlas-generated.png`, 1194×1317 RGB: five columns (front, back, east profile, southeast
three-quarter, northeast three-quarter) by four rows (pushing A, pushing B, carrying A, carrying B).
All twenty cells depict the same narrow, adult-proportioned short-haired woman in the same red coat,
jeans and shoes at one consistent height. The two states share her face, body proportions, coat
construction, ink and lighting; the baby and blue-gray blanket recur in the carrying rows. The atlas
uses uniform white for deterministic background extraction.

Both pram calls use these inputs in order:

1. The cardinal SVG concept sheet above.
2. The diagonal SVG concept sheet above.
3. The approved urban reference above, as style only.
4. The approved cardinal reference above, as style only.
5. `mother-atlas-generated-v1.png` — line weight, palette treatment and rendering continuity only.

`pram-prompt-v1.txt` produces `pram-atlas-generated.png`, 2171×724 RGB. Its five views are coherent,
but it changes the compact bassinet idea into a tall contemporary stroller with an underbasket and
long exposed chassis. It is retained because the task explicitly keeps raw candidates; it is not a
style reference or runtime source.

`pram-prompt-v2.txt` corrects the construction. Its retained raw output,
`pram-atlas-generated-v2.png`, is 2172×724 RGB with one row ordered front, back, east profile,
southeast three-quarter and northeast three-quarter. The five views share one low navy bassinet,
cream hood, short handle and small wheel family. The baby appears only through the front openings.

The pram generator painted a neutral checkerboard despite the prompt requesting transparency.
`pram-background-prompt.txt` uses the built-in image generator to replace that background with
uniform white while preserving the five-view compact pram family; its 2172×724 RGB result is
`pram-atlas-background-corrected.png`. `convert.py` runs only the repository's authorized
`tools/remove-checkerboard.py` for both white-background atlases. It does not discard pixels by
neutral color, so cream hood, gray blanket, ink and material shadows remain artwork.
`registered/{mother,pram}-atlas-extracted.png` preserves the extracted atlases.

## Registration

`convert.py prepare` gathers the existing native and 8× Godot SVG rasters into `source/` and writes
`source/source-manifest.json`, which records each source hash, destination, dimensions, anchor and
atlas cell. The sources remain the authoritative concepts and registration measurements.

`convert.py register` crops each generated cell, preserves its aspect ratio and generated alpha,
centers it horizontally and aligns its feet or wheels to the canvas-bottom source anchor. It gives
all twenty mother frames the same 45-pixel registration height; their antialiased alpha bounds span
the full 46-pixel canvas and their widths remain 19–24 pixels across front, rear, profile and
diagonal turns. Prams fit within the source occupancy. The script does not stretch anatomy or
replace generated alpha with SVG alpha. One shared 28-color, no-dither palette keeps skin, hair,
coat, jeans, blanket, navy fabric and cream hood stable across the family while retaining two or
three readable material and shadow tones at native size.

The registered runtime candidates are in `registered/rig/`. `family-comparison-native.png` and
`family-comparison-5x.png` compare every SVG concept with its comic derivative.
`all-views-native.png` and `all-views-4x.png` assemble the runtime's eight directions, both gait
frames, both mother states, all pram views and the three west mirrors. These are source-level review
sheets with approximate source placement, not gameplay captures, proof of live hand-to-handle
contact or proof of player acceptance.

Preparation and registration use CPython 3.14.7 and Pillow 12.3.0. The source rasters were produced
by Godot 4.7.2. Reproduce into fresh directories without overwriting retained evidence:

```sh
uv run python docs/evidence/comic-rig-2026-09-12/convert.py prepare \
  /tmp/comic-rig-source-reproduction
uv run python docs/evidence/comic-rig-2026-09-12/convert.py register \
  /tmp/comic-rig-registration-reproduction \
  /tmp/comic-rig-source-reproduction \
  docs/evidence/comic-rig-2026-09-12/mother-atlas-generated.png \
  docs/evidence/comic-rig-2026-09-12/pram-atlas-background-corrected.png
```

The pushing and pram files in `registered/rig/` match the bytes in
`assets/illustrated/svg-transfer/rig/`; the carrying files preserve the rejected result.
Existing `.import` files remain untouched, preserving each
Godot resource identity. Import/boot and the focused visual, stroller, presentation and orientation
suites verify that each derivative loads at its SVG's native dimensions, contains visible art,
retains real transparency within its artwork bounds and touches its canvas-bottom ground line. The
prop derivatives use their own bottom or center ground anchors, opaque ground tiles cover their full
canvases, and unrecognized future transparent families use the same generic true-alpha validation.
The forced-SVG visual suite keeps the source comparison path live. Appearance is established by the
native and enlarged review sheets; player acceptance remains separate.
