# Natural southeast contact review

This uninstalled candidate changes only southeast B and its southwest mirror in both states.
The accepted east/west artwork and every other frame remain byte-identical to the
`color-match-2026-09-19/final` rigs.

| State | Clean PNG sheet | A/C/B/C animation |
|---|---|---|
| Pushing | [native](generated/pushing/pushing-spritesheet-native.png), [6×](generated/pushing/pushing-spritesheet-6x.png) | [native](generated/pushing/pushing-animation-native.gif), [6×](generated/pushing/pushing-animation-6x.gif) |
| Carrying | [native](generated/carrying/carrying-spritesheet-native.png), [6×](generated/carrying/carrying-spritesheet-6x.png) | [native](generated/carrying/carrying-animation-native.gif), [6×](generated/carrying/carrying-animation-6x.gif) |

The [large recolored source](generated/recolored-source.png) shows natural trouser volume and
continuous hip–knee–shoe articulation. The foreground leg starts at the screen-right hip,
descends down-left through its knee and reaches the higher trailing shoe. The screen-left hip's
leg advances down-right behind that thigh. Southwest mirrors the whole drawing, preserving
ownership. The [colored source](generated-colored.png) makes that overlap independently visible.

This is an early appearance review. Both southeast upper bodies are coherent generated redraws,
not preserved pixel rows. Father identity, pushing hands, baby and carrying pose remain visually
recognizable, while facial detail and jacket contours can pulse against protected A/C frames.
The new lower jacket hem is approximately two native pixels higher than A/C; the longer legs and
wider shoes remain visible differences. The charcoal shoe conversion includes soles and laces.
These sheets and offline loops establish the frame sequence and contact, not live stroller
alignment or player acceptance.

## Source and contact authority

`prepare.py` crops the original extracted father images at source y=208, above the pelvis, and
uniformly enlarges the visible upper bodies to 650 pixels. The discarded original lower-body
pose never enters the generator input. A colored contact diagram expresses the accepted
`assets/rig/father_front_diagonal_b.svg` chains: screen-right hip to higher left shoe in front,
screen-left hip to lower right shoe behind. The diagram is geometry guidance, not final artwork.
The final female carrying diagonal contacts are frontal enough that they cannot supply this
three-quarter lower-body projection. Their filename alone is not a valid pose donor.

The built-in image generator normalizes
[the assembled colored contact target](inputs/colored-contact-edit-target.png), using the exact
[request](retry-prompt.txt). Its saved, unchanged output is [generated-colored.png](generated-colored.png),
1391×1131 RGBA. Generation metadata is in [generation.json](generation.json); generation is
nondeterministic, while every subsequent derivative is reproducible from this saved source.

## Registration and color

`assemble.py` selects only the red/cyan trouser colors below source y=580 and the two shoe
regions. Trousers map source luminance L to V = round(0.66L + 9), then RGB =
round(V × (0.86, 1.02, 1.25)), matching the existing muted blue-gray family. Shoes map to
V = round(0.19L + 32), then RGB = (V+3, V, V−2), including pale soles and laces. Alpha and
pixels outside the recorded mask remain identical. Neither accepted side B receives this mapping.

The source splits at x=695. Each visible figure uses alpha greater than 1 to determine its crop,
retains the source alpha, and fits uniformly to 540 pixels high on a 312×552 canvas. Horizontal
placement aligns the opacity-weighted centroid of the top 57% with the protected C frame;
vertical placement is y=12. Lanczos reduction produces the unchanged 26×46 native canvas.
No pelvis splice, separate upper-body scaling, runtime offset or camera change is involved.
The manifest records exact crop bounds and placement.

Measurements on native sprites use alpha greater than 128. The skin sample uses R>90,
R>1.15G and G>1.05B over rows 17–28; carrying samples include any baby skin in those rows.
Bounds below are inclusive pixel coordinates.

| State/frame | Opaque top | Head-region width, rows 0–12 | Sampled hand/skin bounds |
|---|---:|---:|---|
| Pushing A | 2 | 11 | x8–20, y20–23 |
| Pushing C | 1 | 12 | x8–20, y20–23 |
| Pushing B | 1 | 12 | x8–21, y20–24 |
| Carrying A | 2 | 10 | x8–18, y17–23 |
| Carrying C | 1 | 11 | x9–18, y19–23 |
| Carrying B | 1 | 11 | x9–19, y17–24 |

All six figures end at native row 45. Head-region width includes the whole silhouette in its
sampled rows, not an inferred anatomical skull measurement. The table separates equal stature
from remaining hand/hem differences; it does not claim identical upper-body landmarks.

## Reproduction

Use the repository's locked Python/Pillow environment. Inputs, shared helpers and protected rigs
are hash-pinned in `inputs.json`; changed sources cause assembly to fail. No font installation is
needed: preparation uses Pillow's bundled default font.

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/natural-southeast-2026-09-19/prepare.py \
  --output-dir /tmp/father-natural-inputs
diff -r docs/evidence/male-player-2026-09-19/b-contact/natural-southeast-2026-09-19/inputs \
  /tmp/father-natural-inputs

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/natural-southeast-2026-09-19/assemble.py \
  --output-dir /tmp/father-natural-review
diff -r docs/evidence/male-player-2026-09-19/b-contact/natural-southeast-2026-09-19/generated \
  /tmp/father-natural-review
```

Columns are N, NE, E, SE, S, SW, W, NW; sheet rows and GIF phases are A, C, B, C.
West views mirror the authored east views. Each GIF phase lasts 190ms. The assembler verifies
protected files, native dimensions, unchanged alpha during recoloring, nearest-neighbor 6×
sheets and GIF timing. Fresh preparation and assembly reproduce all saved PNG/GIF bytes.
