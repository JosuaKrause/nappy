# Three walked-dog poses

This preview adds the missing third pose to each authored view. Existing selected illustrations
and the accepted pursuing family remain frozen. The new SVG sources are unbound: no atlas,
runtime selection or timing change accompanies this proposal.

| Views | Step 1 | Rest | Step 2 |
|---|---|---|---|
| Side and both diagonals | Original A | Revision-4 B | New C |
| Front and back cardinal | Original A | New C | Original B |

The proposed synthetic review sequence is step 1, rest, step 2, rest. It uses three distinct
images; its four beats are a review choice, not an installed animation.

This phase table assigns the selected illustrations. The existing diagonal B SVGs reverse
the reaching pair modestly; they are not newly authored neutral sources. Their selected
revision-4 illustrations gather the feet and serve as the resting images the player asks to
keep. The source sheet labels those original B drawings as references, while new diagonal C
sources define the stronger opposite extended step. Existing B sources are preserved.

## Authored source geometry

The [source sheet](three-pose-sources.png) shows all five views at the same 6× native scale.
The new `art/events/dog_c.svg`, `dog_front_diagonal_c.svg` and `dog_back_diagonal_c.svg`
extend the opposite anatomical legs from unchanged roots. `dog_front_c.svg` and `dog_back_c.svg`
stand squarely, with both closer feet on the existing ground baseline and the farther pair
level at their middle depth. These ground choices keep the neutral body at the original height.

[pose-paths.json](pose-paths.json) records every named leg's exact A and C articulated path:
the initial M coordinate is the unchanged root, intermediate L coordinates are joints and
the final L is the toe. Near/far shading and painter order remain attached to those same limbs.
`source-review.py` checks that substituting only these paths reconstructs each C SVG exactly
below its explanatory comment; every body path, material, canvas and leg root remains unchanged.

The new SVGs precede illustration generation and pass independent source review. The original
SVGs and illustrated resting/step poses are inputs, not files to rewrite. All five new
illustrations derive from their reviewed C sources through built-in `image_gen`.

## Illustrated review

The complete eight-facing family appears at [native size](review/all-facings-1x.gif),
[2×](review/all-facings-2x.gif) and [6×](review/all-facings-6x.gif), with corresponding `.png`
three-pose sheets. Western directions mirror the same registered images. Each of the four
review beats lasts 450ms; these are synthetic comparisons, not gameplay captures.

| View | Three original-resolution poses | Four-beat loop | Color-free leg contours |
|---|---|---|---|
| Side | [Sheet](review/dog-body-three-poses.png) | [Loop](review/dog-body-four-beats.gif) | [Sheet](review/dog-leg-silhouette-three-poses.png) |
| Front diagonal | [Sheet](review/dog_front_diagonal-body-three-poses.png) | [Loop](review/dog_front_diagonal-body-four-beats.gif) | [Sheet](review/dog_front_diagonal-leg-silhouette-three-poses.png) |
| Back diagonal | [Sheet](review/dog_back_diagonal-body-three-poses.png) | [Loop](review/dog_back_diagonal-body-four-beats.gif) | [Sheet](review/dog_back_diagonal-leg-silhouette-three-poses.png) |
| Front | [Sheet](review/dog_front-body-three-poses.png) | [Loop](review/dog_front-body-four-beats.gif) | [Sheet](review/dog_front-leg-silhouette-three-poses.png) |
| Back | [Sheet](review/dog_back-body-three-poses.png) | [Loop](review/dog_back-body-four-beats.gif) | [Sheet](review/dog_back-leg-silhouette-three-poses.png) |

Matching `-leg-silhouette-four-beats.gif` files show the same phase order. The silhouettes use
alpha at or above 128 with coat colors removed; their crop thresholds are recorded in the
recipe. A/C silhouettes may overlap when opposite limbs exchange reach, so the full-body
figures and their intermediate resting pose establish which continuous limb owns each paw.
Repeated pivot labels, recoloring and aggregate alpha differences cannot establish that alone.
The `review/<view>-source-c.png` images compare each reviewed source and new native PNG at 6×.

The opposite side/diagonal step advances the near hind leg and far foreleg, with near fore
trailing and far hind retreating. Cardinal C places each visible foot pair level in a neutral
stance. The generated limbs stay connected to the original attachment regions; hidden joints
are not directly visible, so this is not a claim of pixel-exact fixed internal pivots.

Appearance acceptance remains open. New coat shading is smoother/flatter and body/chest/head
contours differ slightly. Paw-height and body drift remain through the cycle. In SE/SW the
two near paws are tightly spaced and their gap compresses at native size, although they remain
separate owned limbs in the original-resolution artwork. The retained images keep their own
previously disclosed differences; they are not normalized or repainted during assembly.

## Generation provenance and registration

Exact prompts/reference roles are in [PROMPTS.md](PROMPTS.md),
[REMAINING-PROMPTS.md](REMAINING-PROMPTS.md) and [FRONT-RETRACTION.md](FRONT-RETRACTION.md).
The first side C has incorrect foreleg ownership; its refinement changes actual front-leg
connection and reach. The first front-diagonal C does not retract the near foreleg enough;
the retraction edit omits the near hind leg and the final refinement restores it. All these
raw edit dependencies remain unmodified. Selected raw inputs are:

| New pose | Selected raw |
|---|---|
| Side C, opposite step | `raw/dog_c.png` |
| Front diagonal C, opposite step | `raw/dog_front_diagonal_c-retracted.png` |
| Back diagonal C, opposite step | `raw/dog_back_diagonal_c.png` |
| Front C, neutral | `raw/dog_front_c.png` |
| Back C, neutral | `raw/dog_back_c.png` |

Generation is nondeterministic. Registration and assembly are reproducible from the exact
saved outputs. No programmatic limb painting, warping, body/leg composites or SVG alpha masks
are used. One uniform scale and translation registers each complete raw to the frozen A
crop plane, then its original native scale, fitted dimensions and canvas position are reused.
The stable upper-body bounds supply the correction for extra generated margins: diagonal
head/tail through y=170, cardinal head/tail through y=150, all measured at alpha 128 in A's
crop plane. Neither moving paws nor overall pose bounds determine scale or translation.
`REGISTRATION` in the recipe and `revision-manifest.json` record those transforms. The side
uses its already aligned canvas without an additional correction.

`assemble.py` checks three pinned input manifests before any write. They freeze every prior
image artifact and recipe, all SVG sources, reviewed source sheet/rasters, `source-review.py`,
its manifest, all selected/generated raw dependencies and their exact prompts.
Source authoring commands below record the pre-generation stage; the saved source artifacts
are authoritative inputs to illustration assembly, not hashes to refresh after generation.

## Source reproduction

```sh
./tools/check.sh
xmllint --noout art/events/dog_c.svg art/events/dog_front_diagonal_c.svg \
  art/events/dog_back_diagonal_c.svg art/events/dog_front_c.svg art/events/dog_back_c.svg
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/comic-dogs-2026-09-27/render-svgs.gd -- \
  docs/evidence/comic-dogs-2026-09-27/walked-revision-5/sources.txt . \
  docs/evidence/comic-dogs-2026-09-27/walked-revision-5/source-renders
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-5/source-review.py
```

The renderer writes 1× and 6× rasters through Godot's SVG parser. `source-manifest.json`
records the source and sheet-input hashes; the sheet uses Pillow's bundled font.

## Illustration rebuild and verification

Run from the repository root with the project environment (Python 3.14.7, Pillow 12.3.0).
Pillow's bundled font draws review annotations.

```sh
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-5/assemble.py build
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-5/assemble.py verify
uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-5/verify-rebuild.py
./tools/lint.sh
git diff --check
```

Integrity checks cover the frozen existing selections/pursuing family, new source/raw inputs,
native dimensions, true alpha and output hashes. The isolated rebuild reproduces 41 derivatives
byte-for-byte. Each selected raw and a reviewed source, independently changed or removed,
fails before any output write. XML validation and the headless import/boot check pass.
No runtime code changes or bindings require gameplay suites or a windowed capture here.
