# Father leg-drawing refinement review

Review the [clean eight-direction sheet](generated/father-spritesheet-6x.png), its
[native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or
[6×](generated/father-animation-6x.gif) animation loop.

This is one early, uninstalled drawing-refinement attempt for PLAYTEST-90 and M160, the father's
opposite B contact. It retains the provisionally accepted leg positions and changes only E/W and
SE/SW B lower-body pixels. Every A/C frame, N/S B and NE/NW B is byte-identical to the accepted
straight-contact candidate. The head, hands and upper 28 rows of both changed authored B frames
are pixel-identical too. Runtime artwork and shared graphics procedures remain unchanged.

Columns are N, NE, E, SE, S, SW, W, NW; rows are A, C, B, C. GIFs place N/NE/E/SE above
S/SW/W/NW and repeat four 190ms phases.

## What this attempt changes

The built-in image generator edits the accepted father-only
[side donor](../straight-contact-2026-09-19/side-donor-raw.png) once. The exact prompt asks only
for a more credible pelvis and crotch join, restrained thigh volume, visible knee articulation,
tapered calves, ankle transitions and fabric folds that follow each leg. It locks the accepted
right-facing contact: the foreground near leg still runs from the right hip down-left to the
trailing shoe, while the far leg passes behind it and advances down-right. Shoe positions,
stride width, sole baseline, overlap order and travel axis are explicit invariants.

There is one generated edit and no internal retry. The retained
[raw output](side-donor-refined-raw.png) is 1402×1122 RGBA with SHA-256
`5ad5ba4e6ba6971edc06c135caabed9534282d1162d253a85eefe54228df7aaf`.
[generation.json](generation.json) records the exact prompt, input role and hash, generator output
path and timestamp. The [saved prompt](prompt-side-refinement-01.txt) has SHA-256
`8528d21cc2be9a6711be612a905c5a5caece486b91c65aa672fdfa99e0c55095`.

## Registration and assembly

The deterministic assembly deliberately reuses the accepted straight-contact registration rather
than choosing a new fit around the edited silhouette. It crops `[190,100,1290,1077)` from the raw
donor, scales that 1100×977 region uniformly to 243×216 at 12× working resolution, and places it
at `(0,336)` on the 312×552 working canvas. Reduction produces the native 26×46 frame. Exact
accepted B rows 0 through 27 are pasted last, protecting the father above the lower-body splice.

The front-diagonal uses the already accepted provisional side-to-diagonal projection without a
new generation strategy. Its inverse affine map at 12× is
`source_y = output_y - (36/242) * output_x + (36/242) * 242`, which raises the trailing left foot
three native pixels relative to the leading right foot. W and SW are the runtime mirrors.

The assembler verifies the 26×46 canvases, ground-reaching alpha bounds, byte-identical protected
frames, exact upper rows, western mirrors, sheet cells, nearest-neighbor 6× sheet, distinct A/C/B/C
GIF phases, repeated C and 190ms timing. These are image-integrity and offline-loop checks, not
runtime installation, stroller contact or player acceptance.

At native size, the revised side contact retains the accepted ownership while giving the rear knee
and advancing knee more shape than the straight-contact donor. The diagonal remains a projection
of the same side art, so whether its knee volume and hip join read naturally in three-quarter view
is the principal visual uncertainty for player judgment. The splice seam is hidden beneath exact
accepted upper pixels and also awaits visual judgment; checks establish preservation, not beauty.

Review of this early attempt identifies three points for the next refinement rather than changes
to this retained preview: the far leg needs the same dark depth cue used by A/C; the shoes need the
family's chunkier brown shape and highlights; and SE/SW should narrow its stride toward A and the
accepted NE/NW three-quarter contacts instead of projecting the full side stride beneath a
three-quarter torso. This attempt therefore records the first visual pass, not a claim that those
remaining family-consistency findings are resolved.

## Reproduce

Use the locked Python 3.14/Pillow 12.3 environment from the repository root and a fresh destination.
No font, Godot window, image generation, runtime installation or woman image is needed.

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/leg-refinement-2026-09-19/assemble.py \
  --output-dir /tmp/father-leg-refinement
diff -r docs/evidence/male-player-2026-09-19/b-contact/leg-refinement-2026-09-19/generated \
  /tmp/father-leg-refinement
```

The command rejects a changed frozen input or existing destination before generating output.
Fresh output reproduces byte-for-byte. Documentation uses `./tools/lint.sh` and `git diff --check`.
No full suite, windowed run or CI claim applies to this offline review evidence.
