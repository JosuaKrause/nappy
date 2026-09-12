---
name: illustrated-png
description: Add or revise illustrated PNG textures and their reproducible integration workflow. Use before changing assets/illustrated or src/visuals, or preparing an illustrated checkout for testing.
---

# SVG-to-PNG workflow

**Every PNG asset must have a corresponding SVG asset, and the SVG always comes first.** Author
and review the SVG before generating its PNG; do not create an SVG after the fact to legitimize
a PNG-only asset. Keep the SVG as the editable source of content, geometry and placement. Record
the source/derivative pair in the conversion manifest, including UI and identity assets. Raw
generator outputs belong with generation evidence, not in the runtime asset catalogue.

Read `docs/VISUALS.md`, SVG-to-PNG style transfer in `docs/TODO.md`, and
[the integration procedure](references/texture-integration.md) before working on this presentation.
Registered PNG textures are used by default, with SVG fallback. `--svg` / `?svg=1` forces SVG
textures, using the same drawing and animation code.

## Reference authority

The SVG is the authority for subject, colors, canvas, pose, direction, placement and silhouette.
Inspect it and both `docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` before generation. The latter two supply style
only: omit their interface and debug annotations. Do not substitute a different character design,
projection or composition. Archived experiments and unapproved outputs are not style references.

## Directions, frames and variants form one family

Review the complete facing × animation × state matrix together. The mother carrying the baby
must be recognizably the same woman pushing the stroller: preserve hair, face, proportions,
clothing colors and construction, shoes, line weight and material shading wherever the SVGs
share them. Apply the same consistency requirement to other families with multiple variants.

A shared grid is a useful generation input when every cell remains large enough to retain detail.
Keep views in a fixed order, adjacent gait/state variants easy to compare, and record cell bounds
and anchors for extraction. When extending a converted family, supply its existing PNGs as an
explicit identity/rendering reference alongside the new SVG targets. They do not override the
targets' pose or geometry. Split a dense family into batches when needed, carrying the same
reference through every batch; choose by inspected results rather than mandating a single atlas.

Compare native-size and enlarged results across the whole family, including the runtime's west
mirrors. Check that details common to adjacent animation frames hold still and that a state swap
does not change who the character appears to be. Exact alpha registration proves boundaries,
not consistent faces, clothing or interior placement. Update this workflow with observed results;
record experiments and rejected options in `docs/DECISIONS.md`.

## Asset contract

- Read the imagegen skill and use the built-in generator for raster generation or editing.
  Inspect local inputs with `view_image` first. State each input's role in the exact saved prompt.
- Preserve SVGs and raw generated outputs for accepted assets, candidates suggested for human
  review and artwork rejected by a human. Keep drafts rejected only internally by an assistant
  outside the repository. Record extraction commands, tool versions, source dimensions and
  registration measurements for retained derivatives.
- Runtime PNGs use `assets/illustrated/svg-transfer/<family>/<name>.png`, corresponding to
  `assets/<family>/<name>.svg`. Match native canvas dimensions and rasterized SVG alpha exactly.
  Verify internal placement visually as well as testing boundary registration.
- Check real alpha, including wheel and handle gaps. A checkerboard painted into an RGBA image
  is not transparency. The player authorizes the existing checkerboard removal script for this
  workflow; preserve its input and inspect retained detail after extraction.
  Inspect the extracted cell bounds before fitting them: leftover checker or ghost outlines can
  expand those bounds, shrinking the character inside an otherwise exact SVG alpha mask. If the
  removal script leaves residue, correct the background with imagegen and rerun extraction;
  preserve that edit's input and prompt. A plain white background can use the same neutral-region
  extraction when a generated transparency request produces an unusable painted checker.
- Commit runtime PNGs with their `.import` sidecars. Preserve sidecar settings and identity.
  `.godot/` is rebuildable and ignored; evidence under `docs/` is excluded by `docs/.gdignore`.
  Let Godot create sidecars for new PNGs; copying another asset's sidecar can retain its UID or
  source/remap path and load the wrong picture. Check each new resource's own source path and
  unique identity, and verify through Godot's texture loader as well as reading the PNG bytes.
  Preserve existing assets' identities when extending a family.

## Runtime and review

Resolve textures only. Keep original scale, offsets, animation, mirroring, sorting, shadows,
camera and gameplay behavior. Missing or differently sized replacements fall back to the SVG;
do not hide an unfinished family with unrelated generated art.

Run the import/boot check in the exact checkout the player will use, then focused suites in the
default PNG mode and forced SVG mode as applicable. Read the first resource error; passing assertions
do not excuse script or import errors. Read `verify` before tests or captures and use at most one
or two purposeful gameplay captures. Report source registration, appearance and player acceptance
separately. The player approves SVG-first style transfer as the authoring workflow. M108,
eight-direction entity graphics, and M109, convert the SVG catalogue to PNG, specify the remaining
catalogue work. Review each family's visual result without treating workflow approval as proof
that every generated image is correct.
