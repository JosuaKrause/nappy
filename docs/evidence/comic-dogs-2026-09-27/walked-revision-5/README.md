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
SVGs and illustrated resting/step poses are inputs, not files to rewrite. The first illustrated
side proposal is visible as a [three-pose sheet](review/dog-body-three-poses.png) and
[four-beat loop](review/dog-body-four-beats.gif). Other new illustrations are pending.
Exact prompts and reference roles are preserved in [PROMPTS.md](PROMPTS.md); an initial side
attempt with incorrect foreleg ownership is retained as the refinement's dependency, while
`raw/dog_c.png` supplies the selected side C.

`assemble.py` freezes every prior image artifact and recipe, all SVG sources, the reviewed
source sheet/rasters, `source-review.py`, its manifest and the side raw inputs before writes.
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
