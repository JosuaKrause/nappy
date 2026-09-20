# Father straight-contact review

Review the [clean eight-direction sheet](generated/father-spritesheet-6x.png), its
[native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or
[6×](generated/father-animation-6x.gif) animation loop.

PLAYTEST-90 provisionally accepts these four father B contacts for runtime use. Only E/W and
SE/SW B change. All A/C frames and accepted N/S and NE/NW B frames are byte-identical to the
prior review's files. The four authored B PNGs install byte-identically from `generated/rig/`;
the shared graphics procedure records this narrow, approved splice while a separate refinement
attempt seeks more natural-looking legs without changing these accepted positions.

Columns are N, NE, E, SE, S, SW, W, NW; rows are A, C, B, C. GIFs place N/NE/E/SE above
S/SW/W/NW and repeat four 190ms phases. The sheet and loop reuse the
[woman pushing recipe](../../../comic-pushing-strides-2026-09-12/GENERATION.md) through the
[father loop assembler](../loops-2026-09-19/assemble.py). Only father image inputs supply
the new sprites; the woman recipe supplies assembly code, spacing, background and timing.

## Construction and visual scope

The [unchanged generated donor](side-donor-raw.png) supplies a complete waist-to-sole leg pair.
Its foreground thigh starts at the right side of the pelvis and slopes down-left through the
rear knee and ankle to the trailing shoe. The far advancing thigh disappears behind it at the
upper overlap. The near thigh and shin form one relaxed backward diagonal, without a
forward-pointing knee followed by a backward-folded shin.

The donor crop is `[190,100,1290,1077)` in its 1402×1122 original image. Uniform Lanczos scaling
fits that 1100×977 crop to 243×216 at 12× working resolution. Place it at `(0,336)` on a
312×552 transparent working canvas, then reduce to the native 26×46 canvas. The fit preserves
the full shoes and true generated alpha. The crop omits the top of the waist while retaining the
continuous hip-to-shoe drawing. It excludes only low-alpha residue outside the subject horizontally;
it does not apply an SVG mask or erase neutral clothing colors.

For the front-diagonal candidate, the same lower pair uses the authorized projection from the
prior splice recipe: raise its trailing left foot three native pixels relative to its leading right
foot. Its inverse affine map at working resolution is
`source_y = output_y - (36/242) * output_x + (36/242) * 242`.
This is a projected side donor, not a separately redrawn three-quarter lower body. The player
judges its perspective, join and stride.

For both views, exact accepted A rows y=0 through 27 are pasted last. Head, hands, shirt, stature,
canvas and ground anchor therefore remain unchanged. No per-leg warp, shoe swap, recoloring,
runtime scale or runtime offset compensation is applied. W and SW use the existing horizontal
mirror. All thirteen protected authored frames are copied byte-for-byte from
`../loops-2026-09-19/generated/rig/`.

Native and enlarged inspection shows the continuous near backward thigh/shin in E/W and SE/SW.
The advancing far leg is partly occluded at the upper thigh; both knees retain a natural small bend.
The projected diagonal has a higher trailing foot. The native pelvis meets the preserved shirt hem
without a gap, and the protected upper-body landmarks remain fixed.
These are static pose and offline-loop checks, not a live stroller-contact or gameplay-motion
capture. Player acceptance covers provisional runtime use; a motion burst remains separate
runtime evidence.

## Runtime motion evidence

The [dated full run](../../../archive/session-captures/2026-09-19/rig-155715-seed3-v0.12.0-15-ge29c0eb9-dirty/run.log)
selects the father presentation with seed 3, walks `2e2s2w`, and records an invincible,
no-save burst after two seconds. Its `asked/burst-5068233-001/` folder retains 36 PNG frames and
`burst.json`'s actual timing. The capture checks this installed presentation's motion; its
invincibility means it is not evidence of cost or loss.

## Generation provenance

The built-in `image_gen.imagegen` tool generates waist-to-sole donors from existing corrected
father SVG renders, above-pelvis father identity crops and the two approved comic style references.
The latter supply style only, excluding scene subjects and interface. The wrong lower-body art
and rejected bent donor are not inputs.

[generation.json](generation.json) records each exact prompt file, input role and hash,
original tool output path, output hash, filesystem modification time and anatomy verdict.
There is one initial call and one targeted retry per view. Side retry supplies this candidate;
both separate diagonal outputs fail anatomical review and are unused. The diagonal trial instead
uses the same authorized deterministic side-donor projection. Internally rejected raw outputs
remain outside the repository at the recorded paths. The selected original output remains unchanged
both here and at the generator's original path.

[inputs.json](inputs.json) pins the raw donor, all prompts, protected source PNGs, generation
references, and the original B SVG bytes in [`../inputs/`](../inputs/), beside their frozen 8×
renders, so later active-art revisions cannot alter this historical recipe. The
[output manifest](generated/manifest.json) records crop, transforms, compositing order,
native alpha bounds, frame order, timing and every generated derivative's hash.

## Reproduce

Use the locked Python 3.14/Pillow 12.3 environment from the repository root and a fresh destination.
No font, Godot window, image generation, runtime installation or woman image is needed.

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/straight-contact-2026-09-19/assemble.py \
  --output-dir /tmp/father-straight-review
diff -r docs/evidence/male-player-2026-09-19/b-contact/straight-contact-2026-09-19/generated \
  /tmp/father-straight-review
```

The command rejects a changed frozen input or existing destination before generating output.
It verifies native canvases and ground bounds, byte-identical protected frames, exact upper rows,
every sheet cell and western mirror, exact 6× nearest-neighbor enlargement, and four A/C/B/C
GIF phases with distinct A/C/B images, repeated C and 190ms timing. Fresh output reproduces byte-for-byte.
The one-time `--freeze-inputs` option refuses to overwrite an existing input record.

Branch boot verification uses `./tools/check.sh`; documentation uses `./tools/lint.sh` and
`git diff --check`. These checks do not establish artistic acceptance.
