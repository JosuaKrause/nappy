---
name: illustrated-png
description: Add or revise illustrated PNG textures and their reproducible integration workflow. Use before changing assets/illustrated or src/visuals, or preparing an illustrated checkout for testing.
---

# SVG-to-PNG workflow

**Every PNG asset must have a corresponding SVG asset, and the SVG always comes first.** Author
and review the SVG before generating its PNG; do not create an SVG after the fact to legitimize
a PNG-only asset. Keep the SVG as the editable source of subject and functional placement. Record
the source/derivative pair in the conversion manifest, including UI and identity assets. Raw
generator outputs belong with generation evidence, not in the runtime asset catalogue.

Read `docs/VISUALS.md`, SVG-to-PNG style transfer in `docs/TODO.md`, and
[the integration procedure](references/texture-integration.md) before working on this presentation.
Registered PNG textures are used by default, with SVG fallback. `--svg` / `?svg=1` forces SVG
textures, using the same drawing and animation code.

## Reference authority

Transfer the SVG's idea into the references' comic drawing language: redraw its forms,
linework, material details and shadow shapes. Adding grain or surface shading to a traced
SVG does not satisfy style transfer. The SVG defines subject, recognizable color identity,
canvas, pose, direction and functional placement; its primitive interior shapes are not an
exact tracing template. Preserve gameplay boundaries and anchors while giving the artwork
the references' authored contours and shading.
Inspect it and both `docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` before generation. The latter two supply style
only: omit their interface and debug annotations. Do not substitute a different character identity,
projection or composition. Archived experiments and unapproved outputs are not style references.

Player generation targets and runtime SVG fallback artwork have separate roles. Preserve the
creation-reference family in `docs/graphics-creation/player/`; its manifest links each
creation SVG, runtime SVG and illustrated PNG. Both families provide contact and together poses.
Use the preserved creation target when
reproducing its high-fidelity PNG, and keep the original source hashes and authoring order.

## Directions, frames and variants form one family

Review the complete facing × animation × state matrix together. The mother carrying the baby
must be recognizably the same woman pushing the stroller: preserve hair, face, proportions,
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

For walking figures, preserve identity through coherent full-figure edits. Do not composite fixed
upper pixel rows over moving lower legs: the pelvis, coat hem, thighs and knees need continuous
articulation. Check anatomical leg ownership from hip to shoe through both contacts; recoloring
the same leg silhouettes does not establish an opposite step. Diagonal contacts retain the same
projected travel axis while the legs exchange leading and trailing positions. Review three-quarter
torso and pelvis silhouettes separately from front views.

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

- Read the imagegen skill and use the built-in generator for raster generation or editing.
  Inspect local inputs with `view_image` first. State each input's role in the exact saved prompt.
- Preserve SVGs and raw generated outputs for accepted assets, candidates suggested for human
  review and artwork rejected by a human. Keep drafts rejected only internally by an assistant
  outside the repository. Record extraction commands, tool versions, source dimensions and
  registration measurements for retained derivatives.
- Runtime PNGs use `assets/illustrated/svg-transfer/<family>/<name>.png`, corresponding to
  `assets/<family>/<name>.svg`. Match native canvas dimensions, ground anchors and functional
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
- Commit runtime PNGs with their `.import` sidecars. Preserve sidecar settings and identity.
  `.godot/` is rebuildable and ignored; evidence under `docs/` is excluded by `docs/.gdignore`.
  Let Godot create sidecars for new PNGs; copying another asset's sidecar can retain its UID or
  source/remap path and load the wrong picture. Check each new resource's own source path and
  unique identity, and verify through Godot's texture loader as well as reading the PNG bytes.
  Preserve existing assets' identities when extending a family.

## Runtime and review

Keep every script used to create retained graphics, comparison sheets, walking rollouts and GIFs
beside its output under `docs/evidence/<family>/`. Include source paths and hashes, extraction
bounds, frame order, mirroring, scale, GIF timing, tool/font requirements and exact regeneration
commands. Preserve immutable inputs or fail loudly when their hashes change. Link each recipe
from `docs/evidence/README.md` and the family's graphics documentation so it can be found again.
Distinguish nondeterministic image generation from reproducible extraction and assembly of its
saved output. A temporary script or chat-only command is insufficient provenance.

For opaque ground tiles, extract fixed atlas cells rather than fitting visible bounding boxes.
Cell edges are part of the texture's placement contract. Generated atlas dimensions need not
divide evenly by the grid: record normalized cells and rounded pixel bounds. Compare opposite
road-line halves assembled as neighbors as well as repeated full tiles; alpha equality alone
cannot reveal shifted markings, unwanted grid borders or a material that changes between variants.
Keep low-contrast ground texture quiet enough for actors and route markings to remain legible.

Review street-surface continuity in actual generated map layouts, using `GroundTiles.source_for`
and the runtime TileSet mapping. Include repeated runs, both sidewalk lanes, both street axes and
junction corners. Short isolated neighbor strips do not expose all repeated joints or corner
transitions. Keep diagnostic labels and grid overlays separate from the clean assembled artwork.

Ground variants share their base material. Build sidewalk variants from one paving texture and
road variants from one asphalt texture; use transparent layers for curbstones, red main-street
edges, yellow lines, crosswalks and damage. Remove the ground background from detail artwork
before alpha compositing it over the actual base. Preserve the layer inputs and composition
recipe, including SVG sources for the components. Pixels outside the overlay remain identical
to the base. Inspect repeated bases in both axes for lighting gradients and brightness jumps;
a shared texture still needs to tile cleanly. Blend curbstones, markings, damage and grass
features over their bases in the engine, retaining the separate component graphics. The
rotation/offset blend that makes one continuous asphalt base is an offline preparation step.
Separate existing grass features from a soft green base and place them sparsely with stable
city-seed variation, keeping grass detail quieter than the actors and route markings.
Validate component IDs and rotations against the authored TileSet and ground selector rather
than inferring their order from filenames. Verify the composed grass atlas itself as well as
its selection logic; a missing component can leave a valid-looking fallback in place. Crop
grass features to their visible bounds before placing them so their clumps remain whole.

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
