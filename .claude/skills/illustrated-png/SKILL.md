---
name: illustrated-png
description: Generate, register and install illustrated PNGs for SVG sources under art/illustrated/. Load BEFORE adding or changing a PNG there.
---

# SVG-to-PNG workflow

**Every PNG asset must have a corresponding SVG asset, and the SVG always comes first.** Author
and review the SVG before generating its PNG; do not create an SVG after the fact to legitimize
a PNG-only asset. Keep the SVG as the editable source of subject and functional placement. Record
the source/derivative pair in the family's evidence manifest, including UI and identity assets.
The catalogue-wide conversion manifest is open work under M109, convert the SVG catalogue to PNG.
Raw generator outputs belong with generation evidence, not in the runtime asset catalogue.

Read `docs/VISUALS.md`, M109, convert the SVG catalogue to PNG, in `docs/TODO.md`, and
[the integration procedure](references/texture-integration.md) before working on this presentation.
**The presentation is chosen by the bake, not by the running game.** The default
`tools/bake-atlases.sh` takes the registered PNG wherever one exists beside its SVG, and the
SVG's own raster everywhere else; `tools/bake-atlases.sh --svg` bakes the SVGs alone and is a
custom local build, never the release. There is no runtime flag for either — a build is whichever
bake wrote its pages. Both use the same drawing and animation code.

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
record experiments and rejected options in `docs/DECISIONS.md`.

For the illustrated stroller, direction means travel direction: N/NE/NW show the baby and canopy
opening; S/SE/SW show the outside of the hood; E/W use the original side picture. Preserve this
visual contract when generating or assigning views. Upstream front/back filenames do not override
it. The final assignment recipe is `docs/evidence/stroller-view-assignment-2026-09-12/GENERATION.md`;
it reads frozen originals. Never apply another N/S or opposite-diagonal swap to installed textures.

For walking figures, preserve identity and continuous articulation through the pelvis, coat hem,
thighs and knees. See the
[walking-frame correction toolbox](references/leg-contact-corrections.md) for donor selection,
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

## Asset contract

- Raster generation uses the host's image generator (Codex: the imagegen skill; Claude Code has
  none, so say so and stop rather than improvise). Inspect inputs visually first (Codex
  `view_image`, Claude Read). State each input's role in the exact saved prompt.
- Preserve SVGs and raw generated outputs for retained derivatives, following rejected-graphics
  for what a draft's disposition keeps or discards. Record extraction commands, tool versions,
  source dimensions and registration measurements for retained derivatives.
- Runtime PNGs use `art/illustrated/svg-transfer/<family>/<name>.png`, corresponding to
  `art/<family>/<name>.svg`. Match native canvas dimensions, ground anchors and functional
  placement. Preserve the generated artwork's true alpha and expressive silhouette; do not
  reapply the SVG's primitive alpha mask to a redrawn figure or prop. Opaque ground stays fully
  opaque and functional markings retain their joins. Verify outlines, transparent gaps and
  internal placement visually as well as checking canvas registration.
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
- **Commit a runtime PNG on its own: `art/` has a `.gdignore`, so no `.import` sidecar exists and
  the bake reads the files itself** (VISUALS.md, "Where the pictures live").
- **A new or changed picture is not in the game until the pages are rebaked**, and every tool
  that starts the engine does that for you: `tools/bake-atlases.sh` compares a hash per source
  and bakes only when one moved. A new picture also needs a line in
  `assets/atlases/membership.json` naming the group it belongs on, in `members` if both bakes draw
  it or `members_png`/`members_svg` if only one does — a bake reads and hashes its own mode's
  lists alone, so it is baked nowhere and `AtlasLibrary` answers `has_region()` false for it until
  that line exists.
- **A PNG whose size disagrees with its SVG fails the bake by name.** There is no fallback: the
  game holds no second copy of the picture to fall back to, so a mismatch is a committed mistake
  rather than an unfinished art drop to work around.

## Runtime and review

Keep every script used to create retained graphics, comparison sheets, walking rollouts and GIFs
beside its output under `docs/evidence/<family>-<YYYY-MM-DD>/`. Include source paths and hashes, extraction
bounds, frame order, mirroring, scale, GIF timing, tool/font requirements and exact regeneration
commands. Preserve immutable inputs or fail loudly when their hashes change. Link each recipe
from `docs/evidence/README.md` and the family's graphics documentation so it can be found again.
Distinguish nondeterministic image generation from reproducible extraction and assembly of its
saved output. A temporary script or chat-only command is insufficient provenance.

For opaque ground tiles, extraction, boundary joints and the layered variant/damage/grass
composition are in [the ground-tile reference](references/ground-tiles.md).

Resolve textures only. Keep original scale, offsets, animation, mirroring, sorting, shadows,
camera and gameplay behavior. A missing PNG bakes from its SVG; a mis-sized one fails the bake by
name. Do not hide an unfinished family with unrelated generated art.

Run the import/boot check in the exact checkout the player will use, then focused suites
(`tools/test.sh` always bakes PNG). Read the first resource error; passing assertions
do not excuse script or import errors. Read `verify` before tests or captures and use at most one
or two purposeful gameplay captures. Report source registration, appearance and player acceptance
separately. The player approves SVG-first style transfer as the authoring workflow. M108,
eight-direction entity graphics, and M109, convert the SVG catalogue to PNG, specify the remaining
catalogue work. Review each family's visual result without treating workflow approval as proof
that every generated image is correct.
