# Mother modular source v3

Generated 2026-09-06 with the built-in `image_gen` tool. The generator was asked for actual
transparent RGBA output and returned a PNG whose alpha channel contains both zero and partial
values; it was resized horizontally from the tool's 1024×1536 raster to the registered
1280×1536 sheet without replacing any existing v2 asset. The source sheet is a fresh sibling
asset, not an overwrite.

## Registration

The runtime sheet is 1280×1536, with eight 160×192 cells per row and clockwise columns:
`N, NE, E, SE, S, SW, W, NW`. Rows are, top to bottom, `head_hair`, `torso_clothing`,
`arms_hands`, `left_upper_leg`, `left_lower_leg`, `right_upper_leg`, `right_lower_leg`, and a
shoe-pair row whose left and right shoe sub-art are separate cutouts inside every direction cell.
The shared body pivots are head `(80,28)`, torso `(80,66)`, shoulders `(52,77)/(108,77)`, and
hips `(68,116)/(92,116)`. Knee, ankle, toe/heel and sole anchors are direction-specific so a
leg can bend and a shoe can lift independently; planted soles use the shared ground line `y=184`.

The compositor draw order is upper/lower legs by side, torso, head/hair, arms/hands, left shoe,
right shoe. The eight directions are individually authored. No mirroring or symmetry is claimed;
the front/back, side, and four three-quarter views have their own bun, scarf, coat folds, hand,
leg, knee, ankle, and shoe placement.

## Final generation prompt

```text
Use case: stylized-concept. Asset type: transparent RGBA 2D game sprite source sheet.
Generate a new mother modular source sheet with an ACTUAL transparent alpha channel, no colored
background. Exact 1280x1536 PNG, 8 columns x 8 rows, each cell 160x192. Columns exactly N, NE,
E, SE, S, SW, W, NW, all independently authored. Rows exactly: head_hair; torso_clothing;
arms_hands; left_upper_leg; left_lower_leg; right_upper_leg; right_lower_leg; shoes_separate_left_right.
The mother identity is high brown bun, olive green coat, patterned scarf, blue jeans, dark practical
shoes. First seven rows are separate transparent parts; last row shows separate left and right shoes
in each cell. Legs must be independently poseable at hips and knees, with distinct left/right art
and visible clean knee breaks. Use shared pivots: head (80,28), torso (80,66), hips (68,116)/(92,116),
knees independently posed, ankles and shoe soles, ground y=184. Fine dark ink, painted gouache,
readable at gameplay scale, warm upper-left light. MANDATORY OUTPUT: true RGBA transparency around
every painted part and in every unused cell; alpha 0 outside art with antialiased edges allowed.
Do not draw checkerboard, white, gray, brown, blue, gradient, floor, shadow, glow, halo, labels,
text, watermark, scenery, pram, baby, extra people, UI, or any backdrop. Do not combine both legs or
shoes into one layer. Do not mirror any direction. All eight views are genuinely drawn.
```

## Alpha proof

The final `mother-parts-v3.png` was checked by decoding its RGBA pixels through `ffmpeg` and
counting the alpha byte of every pixel. The result was:

```text
1280x1536 RGBA PNG
alpha=0..254  zero=1133302  partial=832778  opaque=0
```

The zero count proves transparent cell space and the partial count proves antialiased alpha; the
generator's raster uses 254 as its maximum opaque value. No checkerboard, floor, or backdrop is
present in the source sheet when inspected at full resolution.

## Walk contact review

`mother-walk-contact-v3.png` is an opaque review image generated separately with the built-in
tool. At gameplay scale it shows two assembled three-quarter walk poses: `planted left / swing
right` and `planted right / swing left`. In each pose the planted shoe sits flat on one shared
baseline and the opposite knee is visibly bent with its shoe lifted, making the knee-to-ankle
relationship readable. It is review evidence only and is not a runtime cutout.
