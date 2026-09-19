# Father B-contact source review

This record contains the four editable pushing B-pose corrections and their source review.
The illustrated runtime PNGs retain the original registration; source and raster leg poses
therefore differ in these four assets. This is source evidence, not a completed raster transfer.

## Source contract

The affected sources are `father_back_b.svg`, `father_side_b.svg`,
`father_front_diagonal_b.svg` and `father_front_b.svg`, under `assets/rig/`.
Their creation copies under `docs/graphics-creation/player/` are byte-identical. Canvases,
head geometry and hand landmarks remain fixed. The pelvis, hem, continuous hip-to-shoe paths
and shoe depth define the opposite contact. Side and front-diagonal B draw the far advancing
leg first, then the near trailing thigh over it; their west views use the existing mirror.
Front B advances the image-right leg toward the viewer; back B advances the image-right
leg away from the viewer, leaving the image-left heel nearer.

`inputs/pushing-source-{1,3}x.png` shows all eight directions in columns N, NE, E, SE,
S, SW, W, NW, with rows A, C, B. The images are actual Godot source renders, including
3× vector rasterization. They establish source shape and silhouette only.
`inputs/father_*-{1,3,8}x.png` preserves each affected source at three scales.
`inputs/svg-targets-8x.png` is the four-view pose input, ordered front, back, side,
front diagonal. `inputs/edit-target.png` is an exact crop of the original raw atlas's
four affected B cells; it supplies identity and rendering, not correct leg ownership.
`inputs/sources.json` pins the revised SVG hashes.

The northeast/northwest source and PNG are unchanged:

- `father_back_diagonal_b.svg`: SHA-256
  `9d384f264fb05bd420721312cf2a4a63896cb8a6ce52994e5612213bea5f0078`.
- `father_back_diagonal_b.png`: SHA-256
  `6d737538aa63cb48334a84f2f3ef2547fe8f75d11b1d0d2ca4cb3538f997afe5`.

All A/C poses, carrying poses, stroller pictures, import sidecars and illustrated runtime
PNGs remain unchanged. The player manifest records current creation hashes and existing
shipped PNG hashes. Its pair verifier still proves creation/runtime equality and equality
between shipped PNGs and their original registered files; that does not establish a corrected
raster pose.

## Regeneration

Run from the repository root with fresh output directories. The renderer uses Godot 4.7.2;
assembly uses the locked Python 3.14/Pillow 12.3.0 environment and Pillow's default label font.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/male-player-2026-09-19/render-sources.gd -- \
  --output-dir /tmp/father-b-source
uv run python docs/evidence/male-player-2026-09-19/b-contact/prepare.py \
  --source-dir /tmp/father-b-source --output-dir /tmp/father-b-review
uv run python docs/evidence/male-player-2026-09-19/verify-pairs.py
```

The preparation script also supplies upper-body-only identity crops for further raster work.
The source preview, target crop and JSON files in `inputs/` reproduce with these commands.
The original `../registration.json` remains immutable: its SVG hashes describe the
generation inputs for the original PNGs. Running its registration verifier against the
revised SVG tree intentionally reports a changed input. A completed transfer needs a
separate explicit four-pose override record, while preserving the original raw atlas.

## Raster acceptance gate

The exact prompts, output hashes and rejection reasons are in `raster-attempts.json`.
Those internally rejected images remain outside the repository. For a fresh attempt, read
the [leg-contact procedure](../../../../.claude/skills/illustrated-png/references/leg-contact-corrections.md),
the M160, father's B-contact correction, entry in `docs/TODO.md`, this record and the source
matrix first. Complete the labeled ownership overlay and source contact proof before
transferring the reviewed pose; use the saved upper-body crops as identity references.

Four corresponding whole-figure PNG redraws, registered/contact/comparison sheets and a
hash-checked override recipe remain required. The side needs the near leg trailing without
changing head size, torso length or hand height relative to A/C. Front diagonal needs the
near trailing thigh visibly in front of the far advancing thigh. No raster candidate is
installed or retained here as an accepted result. No motion burst is captured for this
incomplete presentation.
