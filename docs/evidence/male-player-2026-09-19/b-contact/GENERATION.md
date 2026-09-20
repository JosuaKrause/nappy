# Father B-contact source review

**Pose-guidance correction:** [PLAYTEST-99](../../../playtests/PLAYTEST-99.md) rejects the
crossed diagonal derived from this record's image-right near-hip assignment. The original
father A raster places the near thigh at the screen-left hip. The diagonal table and source
overlays below describe the retained construction, not a valid anatomical target for the
uncrossed refinement. Follow the current M167, the father's legs read as legs, brief instead.

This record contains the original four editable pushing B-pose corrections and their source review.
The illustrated runtime PNGs use the player-approved final family: pushing side and front-diagonal
B plus carrying back, front, side and front-diagonal B. Their manifest entries preserve the
original registered PNGs and identify the accepted override source and hash.

The [straight-contact recipe](straight-contact-2026-09-19/README.md) preserves the accepted
provisional contact raster and its frozen inputs. The final accepted pushing and carrying
family is the [body-texture and hem assembly](whole-figure-color-2026-09-19/README.md).
Its recipe preserves the approved leg geometry, restores the matching existing upper body,
and moves the new jacket edge to the surrounding frames' height. Earlier candidates remain
available as evidence, with their verdicts in `docs/DECISIONS.md`.

The [retained father-only splice trial](loops-2026-09-19/README.md) preserves the rejected
eight-direction A/C/B/C sprite sheet and native/6× animation loops. It preserves A's upper pixels
and native registration, mirrors A's front/back lower body, and uses a retained father leg drawing
for the side/front-diagonal B trial. [PLAYTEST-88](../../../playtests/PLAYTEST-88.md) accepts
N/S and NE/NW, but rejects E/W and SE/SW: the near thigh still advances and its shin folds
backward to the trailing shoe. The rejected donor and deterministic trial remain preserved.
The [four-pose comparison](review-2026-09-19/README.md) remains superseded evidence.

## Source contract

The affected sources are `father_back_b.svg`, `father_side_b.svg`,
`father_front_diagonal_b.svg` and `father_front_b.svg`, under `assets/rig/`.
Their creation copies under `docs/graphics-creation/player/` are byte-identical. Canvases,
head geometry and hand landmarks remain fixed. The pelvis, hem, continuous hip-to-shoe paths
and shoe depth define the opposite contact. Side and front-diagonal B draw the far advancing
leg first, then the near trailing thigh over it; their west views use the existing mirror.
Front B advances the image-right leg toward the viewer; back B advances the image-right
leg away from the viewer, leaving the image-left heel nearer.

The front-diagonal near hip remains on image right in both A and B, and the far hip remains
on image left. Its B near thigh crosses down-left in front of the far advancing thigh.
The source proof fixes anatomical ownership at the hips, separately from leading foot and
draw order; western mirrors reverse screen coordinates without changing that ownership.

| View | A contact | B contact | Foreground at the thigh overlap |
|---|---|---|---|
| Front | Right leg at image left leads toward the viewer | Left leg at image right leads toward the viewer | The advancing leg |
| Back | Left leg at image left leads away | Right leg at image right leads away | The nearer trailing leg |
| Side | Near image-right hip leads to right shoe; far hip trails left | Near image-right hip trails to left shoe; far hip leads right | Near thigh in both contacts |
| Front diagonal | Near image-right hip leads down-right; far hip trails up-left | Near image-right hip trails up-left; far hip leads down-right | Near thigh in both contacts |

`inputs/pushing-source-{1,3}x.png` shows all eight directions in columns N, NE, E, SE,
S, SW, W, NW, with rows A, C, B. The images are actual Godot source renders, including
3× vector rasterization. They establish source shape and silhouette only.
`inputs/father_*-{1,3,8}x.png` preserves each affected source at three scales.
`inputs/svg-targets-8x.png` is the four-view pose input, ordered front, back, side,
front diagonal. `inputs/edit-target.png` is an exact crop of the original raw atlas's
four affected B cells. Its rejected lower-body poses exclude it from new generation references.
`inputs/sources.json` pins the revised SVG hashes.

`proof/ownership-source-8x.png` places each clean A/B source beside a colored hip–knee–shoe
trace. Hidden hip segments are dashed; the near chain draws continuously over the farther
chain after emerging below the hem. The clean source contour beside it remains the authority
for occlusion. `proof/ownership-b-only-8x.png` isolates the four B explanations.
`proof/source-contact-{1,3}x.png` assembles the SVG father with the unchanged installed PNG
stroller at runtime offsets, 7/6 stroller scale and facing-based draw order. This deliberately
mixed-format static proof shows unchanged hand placement and stroller relation across A/C/B;
it is not an all-SVG or live-motion capture. Positions round to pixels at the stated scale.
The native/3× eight-direction source matrices and contact sheets are inspected before generation.

`proof/identity-upper-only.png` contains the accepted illustrated heads, shirts and pushing
hands, cropped at raw-atlas y=1032 above the pelvis. Its four separate crops are retained too.
Neither the rejected lower body nor any internally rejected output is a generation reference.
`proof/proof.json` pins all father and stroller runtime SVG/PNG/import hashes, source-render
hashes, the exact anatomical centerlines, recipe version and every proof output. The three
unchanged corrected B sources, A/C, carrying and back-diagonal sources retain their hashes.

The northeast/northwest source and PNG are unchanged:

- `father_back_diagonal_b.svg`: SHA-256
  `9d384f264fb05bd420721312cf2a4a63896cb8a6ce52994e5612213bea5f0078`.
- `father_back_diagonal_b.png`: SHA-256
  `6d737538aa63cb48334a84f2f3ef2547fe8f75d11b1d0d2ca4cb3538f997afe5`.

All A/C poses, the remaining 24 father runtime PNGs, stroller pictures and import sidecars remain
unchanged. The player manifest records current creation hashes and shipped PNG hashes. Its pair
verifier proves creation/runtime equality, requires each final runtime B PNG to match its
accepted whole-figure source, and separately pins the original registered PNG for every override.

## Regeneration

Run from the repository root with fresh output directories. The renderer uses Godot 4.7.2;
assembly uses the locked Python 3.14/Pillow 12.3.0 environment and Pillow's default label font.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/male-player-2026-09-19/render-sources.gd -- \
  --output-dir /tmp/father-b-source
uv run python docs/evidence/male-player-2026-09-19/b-contact/prepare.py \
  --source-dir /tmp/father-b-source --output-dir /tmp/father-b-review
uv run python docs/evidence/male-player-2026-09-19/b-contact/prove-source.py \
  --source-dir /tmp/father-b-source --output-dir /tmp/father-b-proof \
  --verify docs/evidence/male-player-2026-09-19/b-contact/proof/proof.json
uv run python docs/evidence/male-player-2026-09-19/verify-pairs.py
```

The proof script supplies the above-pelvis identity references for raster work.
The source preview, target crop and JSON files in `inputs/` reproduce with these commands.
The original `../registration.json` remains immutable: its SVG hashes describe the generation
inputs for the original PNGs. The manifest's explicit overrides record the accepted runtime
derivatives while preserving the original raw atlas and registered PNGs.

## Raster acceptance gate

The exact prompts, output hashes and per-pose rejection reasons are in `raster-attempts.json`,
`prompt-ownership-transfer.txt` and `prompt-ownership-retry.txt`. The changed strategy supplies
the corrected SVG targets, named anatomical overlays and above-pelvis identity crops. Its single
targeted retry supplies only B diagrams and repeats the failed proportion targets, without using
the rejected output as a reference. Both outputs retain the wrong foreground advancing thigh
in profile and front diagonal. The procedure's one initial attempt plus one correction retry is
exhausted; this approach is stopped. Internally rejected images remain outside the repository.

The first output is examined in native and 3× eight-direction A/C/B and stroller-contact sheets
from `review-raster.py`. `raster-first-measurements.json` retains its extraction and registered
output hashes. Front/back leg depth reads correctly, but the complete family fails anatomy and
proportion checks: enlarged heads and lower hands differ from A/C. The retry also exceeds the
side canvas at full stature; registration fails loudly instead of shrinking or clipping it.
No complete registered retry sheet or accepted four-pose override recipe exists.

The candidate-only registration uses the family's uniform 45px stature, 12× working canvas,
Lanczos reduction and true alpha. Its horizontal anchor uses the accepted C frame's top 57%
opacity centroid, above the pelvis, so rejected leg spread cannot affect the new hand position.
It is an inspection recipe, not the installed family's immutable original registration.
Given an external raw output and a fresh external destination, reproduce that inspection with:

```sh
uv run python docs/evidence/male-player-2026-09-19/b-contact/review-raster.py \
  --raw /path/to/generated-atlas.png --output-dir /tmp/father-b-candidate
```

The accepted side and front-diagonal contacts preserve the N/S and NE/NW pixels and every A/C
frame. The side's near knee and shoe trail behind its hip without changing head size, torso
length or hand height relative to A/C; the front diagonal keeps its projected near trailing thigh
in front of the far advancing thigh. This father-only splice is accepted provisionally. These
source artifacts alone do not establish gameplay motion; no runtime motion burst covers this
presentation.
