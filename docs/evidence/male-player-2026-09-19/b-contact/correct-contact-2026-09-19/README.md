# Correct carrying-contact normalization preview

This uninstalled preview answers [PLAYTEST-96](../../../../playtests/PLAYTEST-96.md) with the
selected woman-carrying-F contact. Inspect the [clean 6× eight-direction sheet](generated/father-spritesheet-6x.png),
its [native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or [6×](generated/father-animation-6x.gif)
A/C/B/C pushing loop. Only E/W B and SE/SW B differ from the straight-contact baseline; all
other rig PNGs are byte-identical. Nothing here is installed in runtime art.

The [contact proof](inputs/correct-donor-contact-proof.png) shows the source roles directly. In
the selected side source, the green foreground thigh crosses in front and continues down-left to
the left, trailing shoe; the yellow far leg advances to the right shoe behind it. In the selected
front diagonal source, the screen-left near shoe trails higher and the screen-right far shoe
advances lower. The [contour-only leg review](inputs/correct-donor-leg-review.png) exposes the
same ownership without the carrying figure.

The one generated result retains those endpoints and the side crossing: the foreground thigh
descends down-left to the trailing shoe, while the far leg reaches the advancing shoe. The front
diagonal keeps the screen-left shoe higher and screen-right shoe lower. This establishes a useful
early contact candidate, not final acceptance. The generator redraws all pixels, including face,
hands, jacket, trousers and shoes, so B can pulse against the protected A/C frames. At native size
the profile B also fills the full 26px width, and both B frames have cleaner, heavier outlines and
brighter trousers than A/C. Player review still determines whether the crossing reads clearly in
motion.

The separate current baby-carrying review remains unchanged in the rejected preview folder:
[native GIF](../normalized-crop-2026-09-19/carrying-generated/carrying-native.gif),
[6× GIF](../normalized-crop-2026-09-19/carrying-generated/carrying-6x.gif), and
[6× sheet](../normalized-crop-2026-09-19/carrying-generated/carrying-spritesheet-6x.png).
Those artifacts display the installed carrying PNGs and do not use this pushing candidate.

## Frozen source selection

The exact final source is `raw/carrying-f-selected.png`, 1380×1140 RGB, SHA-256
`27ba7489bf0efbf9e475c72bbd7f7670841c7111a0703355641122873ad8f7fb`. `prepare.py` extracts
the neutral background with the pinned `tools/remove-checkerboard.py` algorithm and asserts the
result equals the already registered source pixel for pixel.

- Side desired B uses raw cell `[552,755,828,1140)`, visible bounds `[49,9,220,360)`, and
  leg-plus-hem crop `[45,232,224,365)`. The selected registered source is
  `mother_carrying_side_b.png`, SHA-256
  `1f097869a20714f8aa61227ddd017c2b462fe80c6e01e0cae72414b43bc8d62b`.
- Front diagonal desired B uses raw cell `[828,0,1104,400)`, visible bounds
  `[67,21,196,392)`, and leg-plus-hem crop `[84,245,164,395)`. The selected registered source is
  `mother_carrying_front_diagonal_a.png`, SHA-256
  `72bdff73c001cdef4886a0dca9f97ab10f1737f549fe4fd932a80415a3010745`.
- Father identity comes from the original high-resolution extracted B figures, not enlarged
  runtime sprites: profile SHA-256
  `3fe82dc8e3e2c23578742ce35fb1dd34869081cdde3b8b5632457b84490bb7ae` and front diagonal
  SHA-256 `3c2b3219bb71158a57078dcd782eaacb172f17f55bce09e43518e352488b323a`.
  Both references end at source y=208, above the pelvis. The rejected father legs never enter a
  generator input.

The coat mask follows each painted red hem column, expands through the adjacent dark outline, and
retains only art below that contour. The [rough edit target](inputs/normalization-targets-review.png)
therefore leaves the pelvis-to-thigh gap visible for normalization instead of hiding it with a
horizontal splice. The generator received the rough target, the
[above-pelvis father reference](inputs/father-above-pelvis-reference.png), and the
[correct donor legs](inputs/correct-donor-leg-reference.png), in that order. The exact request is
in [prompt.txt](prompt.txt). [generation.json](generation.json) records the call and the original
output path; [raw/normalized.png](raw/normalized.png) is the unchanged 1376×1143 RGBA result,
SHA-256 `0ec2cc8eef27aa3c7ee9275e96c5cd770f72f795bb7b943cd88fa06533790be0`.

## Registration and reproduction

Each generated panel is extracted through its real alpha, uniformly fitted to 45 native pixels
at 12×, placed one pixel above the ground line, and reduced to the unchanged 26×46 canvas with
Lanczos. Horizontal placement matches the protected C frame's opacity-weighted upper-body
centroid over its top 57%. The side fits at 298×540 at x=0; the front diagonal fits at 224×540 at
x=43. Neither placement needs a canvas-edge adjustment. Columns are N, NE, E, SE, S, SW, W, NW;
rows are A, C, B, C. W and SW mirror the authored generated panels, and GIF frames last 190ms.

Run from the repository root with the locked Python environment and fresh destinations:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/correct-contact-2026-09-19/prepare.py \
  --output-dir /tmp/father-correct-contact-inputs
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/correct-contact-2026-09-19/inputs \
  /tmp/father-correct-contact-inputs

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/correct-contact-2026-09-19/assemble.py \
  --output-dir /tmp/father-correct-contact-review
diff -r \
  docs/evidence/male-player-2026-09-19/b-contact/correct-contact-2026-09-19/generated \
  /tmp/father-correct-contact-review
```

The assembler pins the raw generator output, preparation inputs, baseline rig and shared helpers.
It verifies native canvases, byte-identical protected frames, nearest-neighbor 6× output and four
190ms GIF phases. These checks establish provenance and deterministic assembly; the sheet and GIF
carry the visual review.
