# Uncrossed southeast contact review

[PLAYTEST-100](../../../../playtests/PLAYTEST-100.md) accepts these legs and this pose.
The [accepted final assembly](../whole-figure-color-2026-09-19/README.md) uses the existing
matching frame's body texture and full-size carrying baby, with this B frame's hem edge moved
down to match A/C. It lightens the trousers and matches the hem's jacket colors independently,
preserving this leg geometry and alpha below the extended hem.

This uninstalled candidate addresses [PLAYTEST-99](../../../../playtests/PLAYTEST-99.md).
Only southeast B and its southwest mirror change in pushing and carrying. Every other frame,
including the accepted E/W pixels and color correction, is byte-identical to the
`color-match-2026-09-19/final` rigs.

| State | Clean PNG sheet | A/C/B/C animation |
|---|---|---|
| Pushing | [native](generated/pushing/pushing-spritesheet-native.png), [6×](generated/pushing/pushing-spritesheet-6x.png) | [native](generated/pushing/pushing-animation-native.gif), [6×](generated/pushing/pushing-animation-6x.gif) |
| Carrying | [native](generated/carrying/carrying-spritesheet-native.png), [6×](generated/carrying/carrying-spritesheet-6x.png) | [native](generated/carrying/carrying-animation-native.gif), [6×](generated/carrying/carrying-animation-6x.gif) |

In the [large source](generated/recolored-source.png), the near leg begins on the screen-left
side of the pelvis and stays left through its knee to the trailing shoe. The far leg begins
screen-right and stays right through its knee to the advancing shoe. The thighs and knees do not
cross or swap lateral tracks. The right shoe is farther right and lower; southwest mirrors the
complete figure. The [colored source](generated-colored.png) makes each chain explicit.

This is an early appearance candidate. The pelvis remains somewhat frontal, with diagonal depth
expressed through the foot positions and shoe angles. The jacket hem sits approximately 2–3
native pixels above A/C, and the legs and shoes have different proportions. The coherent upper
redraw retains recognizable father identity, hands, baby and carrying pose, but does not preserve
their exact pixels. These offline sheets and loops do not establish live stroller alignment.
The player's acceptance covers the legs and pose; the final assembly supplies the accepted
body, hem and colors. This intermediate family is retained as evidence.

## Inputs and generation

`prepare.py` crops the earlier source at y=580, retaining only the father upper bodies. None of
its crossed lower-body artwork enters the normalization input. It draws two separate colored
guides: red near/left hip–knee–shoe coordinates `(260,600)`, `(240,775)`, `(218,955)`;
cyan far/right coordinates `(366,600)`, `(395,820)`, `(430,1008)`. The carrying panel repeats
the guides 695 pixels to the right. These coordinates describe a preparation guide, not an
anatomical claim inferred from trouser color.

The built-in image generator normalizes the [assembled target](inputs/uncrossed-contact-edit-target.png)
with the exact [request](retry-prompt.txt). [generation.json](generation.json) identifies the
unchanged 1391×1131 RGBA output. Generation is nondeterministic; extraction, color conversion,
registration and assembly reproduce from the saved source.

## Color and registration

`assemble.py` maps red/cyan trousers below source y=575 into the muted A/C blue-gray palette.
For source luminance L, V = round(0.66L + 9), then RGB = round(V × (0.86, 1.02, 1.25)).
Source-specific ankle boundaries select the shoes, including soles and laces: V =
round(0.19L + 32), then RGB = (V+3, V, V−2). The retained mask records selected pixels;
alpha and every pixel outside the mask remain unchanged. Accepted E/W is never recolored.

Each panel splits at x=695, crops to alpha greater than 1, and fits uniformly to 540 pixels high
on a 312×552 canvas at y=12. Horizontal registration matches the protected C upper-body opacity
centroid over its top 57%. Lanczos reduction produces the unchanged 26×46 canvas. No fixed-row
upper splice, separate body-part rescaling, runtime offset or camera adjustment is used.
`generated/manifest.json` records exact visible bounds, placement and output hashes.

The native opaque silhouette begins at row 1 and ends at row 45 in both new B frames.
Head/hand appearance, hem position and step length still need visual judgment alongside this
equal total stature; registration alone does not establish matching proportions.

## Reproduction

Use the repository's locked Python/Pillow environment and fresh destinations. `inputs.json`
pins the generated source, preparation input, source upper bodies, shared helpers and all
protected rig files. Changed input hashes fail loudly. Preparation needs no external fonts.

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/uncrossed-southeast-2026-09-19/prepare.py \
  --output-dir /tmp/father-uncrossed-inputs
diff -r docs/evidence/male-player-2026-09-19/b-contact/uncrossed-southeast-2026-09-19/inputs \
  /tmp/father-uncrossed-inputs

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/uncrossed-southeast-2026-09-19/assemble.py \
  --output-dir /tmp/father-uncrossed-review
diff -r docs/evidence/male-player-2026-09-19/b-contact/uncrossed-southeast-2026-09-19/generated \
  /tmp/father-uncrossed-review
```

Sheet columns are N, NE, E, SE, S, SW, W, NW; rows and GIF phases are A, C, B, C, at 190ms
per phase. Western views mirror the authored eastern views. The recipe verifies all 28 protected
authored PNGs, native dimensions, alpha preservation, pixels outside the color mask, 6×
nearest-neighbor sheets and GIF timing. Fresh preparation and assembly reproduce all saved bytes.
