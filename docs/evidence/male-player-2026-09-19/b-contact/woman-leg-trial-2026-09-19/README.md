# Father's woman-leg donor trial

Review the [clean eight-direction sheet](generated/father-spritesheet-6x.png), its
[native version](generated/father-spritesheet-native.png), and the
[native](generated/father-animation-native.gif) or
[6×](generated/father-animation-6x.gif) A/C/B/C loop.

This is one early, uninstalled M167 preview after PLAYTEST-92 rejected the first leg refinement
and proposed using the woman's legs because both parents wear the same pants. It changes only
E/W B and SE/SW B. Every A/C frame, N/S B and NE/NW B is byte-identical to the provisionally
accepted straight-contact baseline. The father's rows 0 through 27 are exact in both changed
authored frames. No runtime, SVG, carrying, stroller or shared-procedure file changes.

Columns are N, NE, E, SE, S, SW, W, NW; rows are A, C, B, C. The GIFs put N/NE/E/SE above
S/SW/W/NW and use four 190ms phases.

## Donor choice and one edit

The accepted `mother_side_b.png` and `mother_front_diagonal_b.png` are both 26×46 with the same
bottom-center registration as the father. Their B contacts already provide the required far-leg
advance and near-leg trail. The front-diagonal is its own narrow three-quarter drawing rather than
a projected profile stride. Mother A/C were inspected beside B to confirm anatomical exchange,
trouser material and shoe construction. The creation SVGs were inspected to confirm the authored
hip–knee–shoe ownership.

`assemble.py prepare` makes [the transparent edit target](edit-target.png) without scaling native
geometry before its final 12× nearest-neighbor enlargement. For each changed view it starts from
the accepted mother B figure, maps only low-green red coat-hem pixels at and below row 28 into the
father's blue garment palette, then pastes the exact father rows 0..27 last. The side target is at
`(96,236)` and the front-diagonal target at `(616,236)` on the 1024×1024 canvas.

The built-in image generator makes [one retained composite](woman-leg-composite-raw.png) from that
target. [The exact prompt](prompt.txt) names the target, the two mother B donors and the two father
B identity references in input order. [generation.json](generation.json) records their roles,
hashes, the original generator path and the exhausted one-edit budget. The 1254×1254 output is
split into horizontal halves. Alpha at or above 8 defines the source bounds, suppressing only the
generator's nearly transparent full-canvas fringe. Side crop `[116,303,465,966)` fits to 24×45 at
`(1,1)`; front-diagonal crop `[186,303,477,964)` fits to 20×45 at `(3,1)`.

The generated registration owns only rows 28..33, where the blue jacket meets the borrowed pants.
Exact father rows 0..27 are pasted last above it. The original accepted mother PNG is pasted last
for rows 34..45, making all 312 pixels in that lower block byte-identical, including its trouser
shading, leg contours and chunky shoe highlights. The frozen generation target retains its wider
prep-only red-hem-to-blue mapping because it is the exact image the one edit received; the final
donor lock does not inherit that mapping below row 33. W and SW are mirrors of the two authored
results.

## Scope of the evidence

The clean sheet establishes fixed canvas registration, protected frames and the two static B poses.
The GIFs establish the offline A/C/B/C order and 190ms timing. The side and diagonal now use the
woman's distinct accepted contacts instead of one father side donor projected into both views.

This remains an early visual question, not accepted artwork. The generated six-row seam is
resampled from a one-pass edit, so whether the pelvis join reads naturally at native size is still
for player judgment. The direct diagonal donor is narrower than the rejected projected stride, but
the apparent step rhythm across the complete A/C/B/C loop also remains a human-review question.
No additional generation attempt was made to hide either uncertainty.

## Reproduce

Use the repository's locked Python 3.14/Pillow environment from the repository root. Both commands
require fresh destinations. The comparison exposes preparation drift, and assembly fails on any
changed frozen input:

```sh
UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/woman-leg-trial-2026-09-19/assemble.py \
  prepare --output /tmp/father-woman-leg-edit-target.png
cmp docs/evidence/male-player-2026-09-19/b-contact/woman-leg-trial-2026-09-19/edit-target.png \
  /tmp/father-woman-leg-edit-target.png

UV_CACHE_DIR=/tmp/nappy-uv-cache uv run --frozen python \
  docs/evidence/male-player-2026-09-19/b-contact/woman-leg-trial-2026-09-19/assemble.py \
  assemble --output-dir /tmp/father-woman-leg-trial
diff -r docs/evidence/male-player-2026-09-19/b-contact/woman-leg-trial-2026-09-19/generated \
  /tmp/father-woman-leg-trial
```

[inputs.json](inputs.json) pins the assembler itself, prompt, edit target, raw output, all protected
father files, mother A/B/C donors, creation SVG targets, the original father B SVG bytes in
[`../inputs/`](../inputs/), and both style references. The
[output manifest](generated/manifest.json) records the raw crops, fits, placements, protection
contract, loop timing and every derivative hash. The recipe carries its own sheet and GIF helpers;
it does not import a prior preview assembler, and every donor asset is hash-pinned. `./tools/check.sh`,
`./tools/lint.sh` and `git diff --check` are the branch gates. They do not establish appearance or
player acceptance.
