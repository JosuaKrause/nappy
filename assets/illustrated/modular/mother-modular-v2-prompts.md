# Mother modular v2 generation record

Generated 2026-09-06 with the built-in `image_gen` tool. The first call used the three supplied
reference images visible in the session as style/character references. The generator returned a
checkerboard-looking RGB PNG, so the checkerboard was removed by an alpha matte based on its neutral
near-white/gray pixels, then the sheet was resized to its declared registered dimensions. This is
post-processing of generated raster art, not a vector or code stand-in.

## Mother parts prompt

```text
Use case: stylized-concept
Asset type: transparent 2D game modular sprite source sheet
Input images: Image 1 is the existing mother turnaround reference; Image 2 is the illustrated urban style and mother/pram reference; Image 3 is the cardinal gameplay composition reference. Use them for character identity, clothing, linework, palette, and scale only.
Primary request: Create a genuinely transparent PNG sheet containing one compatible modular mother character in eight real views, with the parts separated into named horizontal bands: head/hair, torso/clothing, arms/hands, legs, shoes. Each band contains eight independently usable views in the same fixed cells and exact clockwise direction order N, NE, E, SE, S, SW, W, NW.
Subject: adult mother with a high brown bun, expressive but small illustrated face, olive green coat, warm patterned scarf, blue jeans, dark practical shoes. Arms are posed naturally forward for later pram grip. Keep all parts aligned to one shared body registration.
Style/medium: detailed fine dark ink contours, softly painted gouache/illustration fills, subtle material texture, readable at gameplay scale, grounded cardinal game sprite art. Preserve distinct real front, back, side, and three-quarter views; do not mirror or reuse unrelated views.
Composition/framing: exact 8-column by 5-row modular sheet, equal invisible cells, each cell 160x192 pixels, transparent empty space. Row order top to bottom: head/hair; torso/clothing; arms/hands; legs; shoes. No labels or dividers inside the art. Keep each part centered on the same 160px-wide registration column. Shoes touch the same logical ground line at y=184 in every direction. Head pivot at (80,28), torso attachment at (80,66), arm shoulder pivots near (52,77)/(108,77), hip pivot (80,116), shoe/foot anchor points near y=184.
Lighting/mood: warm neutral illustrated daylight, consistent light from upper left across all directions.
Color palette: olive green coat, ochre/rust scarf pattern, chestnut brown hair, blue-gray denim, charcoal shoes with warm highlights.
Materials/textures: inked folds, scarf weave, coat seams and pockets, denim knees, shoe laces; no generic smooth vector fill.
Constraints: true RGBA transparency outside every painted part; alpha 0 around all art; preserve empty cell space. Every direction must be present and genuinely drawn. Parts must be separately usable with no baked checkerboard, floor, shadow, halo, background, labels, arrows, text, watermark, pram, baby, extra people, UI, or environment.
Avoid: checkerboard pixels, white/gray/black backdrop, gradient, contact shadow, scenery, isometric diamonds, perspective turntable, mirrored placeholders, cropped feet, disconnected anatomy, multiple characters.
```

## Inspection and alpha result

The final mother sheet was inspected at full resolution: all five rows contain eight distinct
registered part views, the bun/scarf/coat/denim/shoes remain readable, and the shoes share the
declared bottom registration. The pram sheet was inspected at full resolution: all three rows
contain eight distinct body, baby/canopy and wheel/frame views, with visible spokes, handle joints
and blanket detail. The contact preview was inspected at gameplay scale: all eight assembled views
show the mother gripping the pram, full wheels and feet, and a shared muted baseline.

An alpha-aware PNG parser was run on both final sheets after resizing. It reported RGBA color type,
alpha range `0..255`, and transparent pixels in both sheets:

```text
mother-parts-v2.png  1280x960  alpha=0..255  alpha0=841087  partial=100650  opaque=287063
pram-parts-v2.png    1280x384  alpha=0..255  alpha0=322219  partial=66433   opaque=102868
```

The preview remains an opaque review image by design; it is not a runtime cutout.

## Pram layers prompt

```text
Use case: stylized-concept
Asset type: transparent 2D game modular sprite source sheet
Input images: Use the illustrated mother/pram reference among the supplied images for stroller construction, ink quality, and warm bundle colors; do not copy any background.
Primary request: Create a genuinely transparent PNG sheet for a detailed dark practical pram with a warmly bundled sleeping baby, shown in eight real directions in exact clockwise order N, NE, E, SE, S, SW, W, NW. Separate the pram into three independently usable bands: pram body/basket, canopy plus bundled baby, and wheels/frame. All eight cells share one ground registration and the layers assemble cleanly with no background.
Style/medium: detailed fine dark ink contours, softly painted gouache illustration, dark charcoal and navy pram, warm ochre blanket and knitted cap, visible seams, handle, frame joints, wheel spokes, and small suspension details. Real front/back/side/three-quarter views; never mirror an unrelated view.
Composition/framing: exact 8-column by 3-row modular sheet, equal invisible cells, each cell 160x128 pixels. Row order top to bottom: pram body/basket; canopy and baby; wheels/frame. Shared ground line y=118. Body pivot at (80,74), canopy/baby attachment around (80,34), wheel centerline y=112. Transparent margins around every layer.
Lighting/mood: warm soft upper-left light, consistent across directions.
Constraints: true RGBA transparency outside every painted layer; alpha 0 around all art; no checkerboard, white/gray/black canvas, floor, cast shadow, halo, labels, dividers, arrows, text, watermark, mother, extra people, street or UI. Keep baby visibly bundled and safe inside the pram. Do not make a flat rectangle or generic circle stand-in.
Avoid: isometric diamond grid, perspective product shot, mirrored placeholders, cropped wheels, disconnected canopy, opaque backdrop.
```

## Contact preview prompt

```text
Use case: stylized-concept
Asset type: gameplay-scale assembled contact sheet and registration review image for a 2D game
Input images: Use the supplied illustrated mother and pram references as style and design references. This is a new assembled preview, not an edit.
Primary request: Create a clean contact sheet showing the complete adult mother with high brown bun, green coat, patterned scarf, jeans, dark shoes, hands on the handle of a detailed dark pram containing a warmly bundled sleeping baby. Show all eight real directions in exact order N, NE, E, SE, S, SW, W, NW in two rows of four. Every assembled view must use the same logical ground line and visibly touch the ground with both mother shoes and the pram wheels; show the handle distance and foot-to-pram spacing clearly.
Style/medium: detailed fine dark ink contours, softly painted gouache illustration, same grounded cardinal-game style as the supplied references, clear at small gameplay scale.
Composition/framing: equal invisible 256x224 cells, two rows of four, ample spacing, no overlap between cells. Keep full body, full pram, wheels and feet visible. Use a very light warm neutral background only for this review contact sheet, with a thin muted ground baseline per cell; do not place the baseline beneath the art's transparent source sheets. The contact sheet itself is a review image.
Lighting/mood: warm upper-left illustrated daylight, consistent all directions.
Constraints: real front/back/side/three-quarter views, coherent layer assembly, pram always in front of mother hands where appropriate, wheels aligned to the same baseline, no labels, arrows, text, watermark, UI, city, extra people, checkerboard, isometric diamonds, mirrored placeholders, floating feet, floating pram, cropped art.
```
