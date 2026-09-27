# Walked-dog fixed-joint correction

This evidence proposal replaces only `dog_b`, `dog_front_diagonal_b` and `dog_back_diagonal_b`.
The legs exchange reach through continuous thighs from the original haunches and forelegs from
the original shoulders. Every first-pass walked A/cardinal frame and pursuing-dog artifact remains
byte-identical. No runtime asset, atlas or drawing code changes.

## Review

- Clean all-facing A/B loops: [native](review/all-facings-1x.gif),
  [game-scale 2×](review/all-facings-2x.gif), [enlarged 6×](review/all-facings-6x.gif).
  The [6× static sheet](review/all-facings-6x.png) exposes both frames and every western mirror.
- Original-resolution torso-aligned pairs: [side](review/dog-torso-pair.png),
  [front diagonal](review/dog_front_diagonal-torso-pair.png),
  [back diagonal](review/dog_back_diagonal-torso-pair.png). Matching `-torso-loop.gif` files
  alternate these clean pairs at 650ms; the native loops use 450ms.
- Separate anatomical traces: [side](review/dog-joint-trace.png),
  [front diagonal](review/dog_front_diagonal-joint-trace.png),
  [back diagonal](review/dog_back_diagonal-joint-trace.png). Red/magenta follow near/far hind legs;
  blue/orange follow near/far forelegs throughout the contact swap. Internal pivots are inferred
  inside the opaque body. Their repeated coordinates are explanatory, not proof that the art is
  correct; the visible haunch-to-thigh connection and continuous leg contours are the check.
- Separate torso-registration marks: [side](review/dog-torso-marks.png),
  [front diagonal](review/dog_front_diagonal-torso-marks.png),
  [back diagonal](review/dog_back_diagonal-torso-marks.png). The tail/body junction, haunch-crease
  top and collar bottom register the body independently of moving paws. Manual contour estimates
  carry approximately ±3 original-crop pixels of uncertainty.

These are synthetic frame comparisons, not gameplay captures. The native side is only 26×20 and
the diagonals 38×28; individual joint bends cannot be judged there alone. Enlarged source pairs
establish limb continuity while the reduced sheets check that legs and reach remain readable.
The selected pairs have no clear sliding attachment or disappearing leg in the independent
anatomy review. Appearance acceptance remains the player's: the back-diagonal B has brighter coat
and collar shading, and small head, ear, tail and outline differences remain. The PNGs are not
pixel-identical outside the legs, and passing file-integrity checks does not approve their look.

## Generation and selection

Codex's built-in `image_gen` creates all artwork. No Python painting, limb warping or body/leg
compositing is used. The approved urban/cardinal style references and the original SVG poses are
inspected before generation. A PNG is an edit target for its existing identity and fixed body;
rejected poses are never promoted to approved style references. The built-in tool reports no
model/version selector. Generation is nondeterministic; its saved raw outputs are immutable.

| Raw output | Exact prompt and supplied reference roles | Disposition |
|---|---|---|
| `raw/dog_b.png` | [PROMPTS.md, Side B](PROMPTS.md): first-pass `crops/dog/dog.png` as edit target | Selected side B |
| `raw/dog_front_diagonal_b.png` | [PROMPTS.md, Front diagonal B](PROMPTS.md): first-pass `crops/dog/dog_front_diagonal.png` as edit target | Visible thigh connection is ambiguous; not selected |
| `raw/dog_back_diagonal_b.png` | [PROMPTS.md, Back diagonal B](PROMPTS.md): first-pass `crops/dog/dog_back_diagonal.png` as edit target | Belly outline separates thigh cap from haunch; not selected |
| `raw/front-refinement-hook.png` | [DIAGONAL-REFINEMENT.md, Front diagonal](DIAGONAL-REFINEMENT.md): first front B as edit target, frozen front A as anatomy authority | Does not clarify thigh connection; not selected |
| `raw/dog_back_diagonal_b-connected.png` | [DIAGONAL-REFINEMENT.md, Back diagonal](DIAGONAL-REFINEMENT.md): first back B as edit target, frozen back A as anatomy authority | Selected back-diagonal B; haunch contour continues into thigh |
| `raw/front-lost-haunch-line.png` | [FRONT-CONTINUITY.md](FRONT-CONTINUITY.md): first front B as edit target, frozen front A as anatomy authority | Removes the stationary haunch line; rejected |
| `raw/front-guided-hook.png` | [FRONT-GUIDED.md](FRONT-GUIDED.md): first front B as edit target, `front-thigh-guide.png` as diagram, frozen front A as anatomy authority | Anatomically plausible forward-thigh fold; not selected |
| `raw/dog_front_diagonal_b-from-a.png` | [FRONT-FROM-A.md](FRONT-FROM-A.md): frozen front A as edit target, connected back B as anatomical continuity example only | Selected front-diagonal B; clearest continuous thigh and retracting foreleg |

The first-pass crop paths in the table are relative to this folder's parent. Every retained
attempt is visible in the generation/review conversation. The guide is an annotated diagram,
reproducible with `pose-guide.py`, never candidate artwork. A forward contour on a bent thigh is
not automatically a moved hip: near/far ownership, the original haunch and its connected femur
must be traced together. The guided front candidate's hook is a plausible anterior thigh fold;
the selected A-based edit makes that interpretation easier to read.

## Registration and frozen inputs

The raw edited canvas is scaled uniformly into the frozen A crop's coordinate plane. A small
translation from the three visible torso landmarks then places it; neither scale nor placement
uses a new paw bounding box or bottom alignment. The native B inherits A's original crop-to-native
scale, integer fitted dimensions and canvas position from the frozen first-pass manifest.
Registration never stretches a limb or moves an individual joint. Original generated alpha is
preserved through Lanczos reduction. No SVG silhouette is applied.

[revision-manifest.json](revision-manifest.json) records the selected raw dimensions/hashes,
raw-to-A scale, torso marks and translation, inherited native transform and every derivative hash.
[input-manifest.json](input-manifest.json) freezes the original sources, first-pass and revision-2
artifacts, the first three edits and their prompt. [refinement-input-manifest.json](refinement-input-manifest.json)
freezes the refinements, prompts and diagram. Their own hashes are pinned in `assemble.py`.
There is no refresh command: changed manifests or raw inputs fail before outputs are written.
The preserved pursuing raw, crops, native candidates and review images are all within that check.

## Rebuild and verify

Run from the repository root with the project environment (Python 3.14.7, Pillow 12.3.0 for this
recorded pass). Pillow's bundled default font draws annotations; no system font is required.

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-3/assemble.py build
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-3/assemble.py verify
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-3/verify-rebuild.py
./tools/lint.sh
git diff --check
```

The isolated rebuild reproduces all 24 derivatives byte-for-byte. Its altered-selected-raw probe
fails before any file is written. Integrity verification checks native sizes, real alpha, frozen
unaffected frames and review hashes. Evidence-only scope needs no gameplay test suite or windowed
capture; live movement and visual acceptance remain gates before runtime installation.
