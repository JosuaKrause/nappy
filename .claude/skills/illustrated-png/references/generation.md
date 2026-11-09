# Generating an illustrated PNG

This is the generation procedure, and only a host with an image generator can run it: Codex has
one (its imagegen skill) and Claude Code has none, so a Claude Code session that is asked for a new
PNG says so and stops. Nothing is being converted for now either (`SKILL.md`). The sections below
are the procedure as it stands for the host that can run it.

## Reference authority

Transfer the SVG's idea into the references' comic drawing language: redraw its forms,
linework, material details and shadow shapes. Adding grain or surface shading to a traced
SVG does not satisfy style transfer. The SVG defines subject, recognizable color identity,
canvas, pose, direction and functional placement; its primitive interior shapes are not an
exact tracing template. Preserve gameplay boundaries and anchors while giving the artwork
the references' authored contours and shading.
Inspect it and both `docs/style-references/graphics-reference-urban-01.jpeg` and
`docs/style-references/graphics-reference-cardinal.jpeg` before generation. The latter two supply style
only: omit their interface and debug annotations. Do not substitute a different character identity,
projection or composition. Archived experiments and unapproved outputs are not style references.

Player generation targets and the runtime SVG in `art/rig/` have separate roles. Preserve the
creation-reference family in `docs/graphics-creation/player/`; its manifest links each
creation SVG, runtime SVG and illustrated PNG. Both families provide contact and together poses.
Use the preserved creation target when
reproducing its high-fidelity PNG, and keep the original source hashes and authoring order.

## Directions, frames and variants form one family

Review the complete facing × animation × state matrix together. Each parent carrying the baby
must be recognizably the same person pushing the stroller: preserve hair, face, proportions,
clothing colors and construction, shoes, line weight and material shading wherever the SVGs
share them. Apply the same consistency requirement to other families with multiple variants.

A shared grid is a useful generation input when every cell remains large enough to retain detail.
Keep views in a fixed order, adjacent gait/state variants easy to compare, and record cell bounds
and anchors for extraction. When extending a converted family, supply its reviewed PNGs as an
explicit identity/rendering reference alongside the new SVG targets. They do not override the
targets' pose or functional placement. Split a dense family into batches when needed, carrying the same
reference through every batch; choose by inspected results rather than mandating a single atlas.
Do not use a rejected family to perpetuate the rendering the player asked to replace; derive
the revised family's identity from its source concept and the approved style references.

Compare native-size and enlarged results across the whole family, including the runtime's west
mirrors. Check that details common to adjacent animation frames hold still and that a state swap
does not change who the character appears to be. Canvas registration does not prove consistent
faces, clothing or interior placement. Update this workflow with observed results;
record experiments and rejected options in a decision record under `docs/decisions/`.

For the illustrated stroller, direction means travel direction: N/NE/NW show the baby and canopy
opening; S/SE/SW show the outside of the hood; E/W use the original side picture. Preserve this
visual contract when generating or assigning views. Upstream front/back filenames do not override
it. The final assignment recipe is `docs/evidence/stroller-view-assignment-2026-09-12/GENERATION.md`;
it reads frozen originals. Never apply another N/S or opposite-diagonal swap to installed textures.

For walking figures, preserve identity and continuous articulation through the pelvis, coat hem,
thighs and knees. See the
[walking-frame correction toolbox](leg-contact-corrections.md) for donor selection,
anatomical leg ownership, uncrossed pose guides, material matching and constrained body/hem reuse.

Measure stature across all facings and frames after registration. Fitting an over-wide pose
into its canvas must not shrink the person when she turns. Redraw a compact pose with consistent
proportions instead of stretching it or changing the runtime canvas. Inspect the native result,
not only the enlarged atlas. An approximate assembly sheet does not prove live hand-to-handle
contact or motion; label its coverage accurately.

Equal full-figure height alone does not establish equal proportions. Compare the head, coat hem
and hands across contacts and the together frame: short legs in one generated cell make its
upper body grow when every cell is fitted to the same height. Redraw the affected whole figures
in a separate batch when a dense atlas constrains their stature. Register horizontal placement
from stable body landmarks so changing leg spread does not move the hands sideways.

## Asset contract: generation and extraction

- Raster generation uses the host's image generator (Codex: the imagegen skill; Claude Code has
  none, so say so and stop rather than improvise). Inspect inputs visually first (Codex
  `view_image`, Claude Read). State each input's role in the exact saved prompt.
- Preserve SVGs and raw generated outputs for retained derivatives, following rejected-graphics
  for what a draft's disposition keeps or discards. Record extraction commands, tool versions,
  source dimensions and registration measurements for retained derivatives.
- Check real alpha, including wheel and handle gaps. A checkerboard painted into an RGBA image
  is not transparency. The player authorizes the existing checkerboard removal script for this
  workflow; preserve its input and inspect retained detail after extraction.
  Inspect the extracted cell bounds before fitting them: leftover checker or ghost outlines can
  expand those bounds and shrink the character during registration. If the
  removal script leaves residue, correct the background with imagegen and rerun extraction;
  preserve that edit's input and prompt. A plain white background can use the same neutral-region
  extraction when a generated transparency request produces an unusable painted checker.
  Save the alpha before extending colors beneath transparent pixels; the color-extension
  buffer is not an alpha mask. Do not erase every neutral pixel to remove background residue:
  gray materials and enclosed light details are artwork too. Correct persistent background
  artifacts with the generator and preserve that correction's input and prompt.
