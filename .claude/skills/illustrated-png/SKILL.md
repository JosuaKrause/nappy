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
SVG remains the default. The existing `--illustrated` / `?illustrated=1` opt-in selects registered
PNG textures, using the existing drawing and animation code.

## Reference authority

The SVG is the authority for subject, colors, canvas, pose, direction, placement and silhouette.
Inspect it and both `docs/evidence/graphics-reference-urban-01.jpeg` and
`docs/evidence/graphics-reference-cardinal.jpeg` before generation. The latter two supply style
only: omit their interface and debug annotations. Do not substitute a different character design,
projection or composition. Archived experiments and unapproved outputs are not style references.

## Asset contract

- Read the imagegen skill and use the built-in generator for raster generation or editing.
  Inspect local inputs with `view_image` first. State each input's role in the exact saved prompt.
- Preserve SVGs and raw generated outputs. Write versioned derivatives and record extraction
  commands, tool versions, source dimensions and registration measurements.
- Runtime PNGs use `assets/illustrated/svg-transfer/<family>/<name>.png`, corresponding to
  `assets/<family>/<name>.svg`. Match native canvas dimensions and rasterized SVG alpha exactly.
  Verify internal placement visually as well as testing boundary registration.
- Check real alpha, including wheel and handle gaps. A checkerboard painted into an RGBA image
  is not transparency. The player authorizes the existing checkerboard removal script for this
  workflow; preserve its input and inspect retained detail after extraction.
- Commit runtime PNGs with their `.import` sidecars. Preserve sidecar settings and identity.
  `.godot/` is rebuildable and ignored; evidence under `docs/` is excluded by `docs/.gdignore`.

## Runtime and review

Resolve textures only. Keep original scale, offsets, animation, mirroring, sorting, shadows,
camera and gameplay behavior. Missing or differently sized replacements fall back to the SVG;
do not hide an unfinished family with unrelated generated art.

Run the import/boot check in the exact checkout the player will use, then focused suites in the
illustrated mode and normal mode as applicable. Read the first resource error; passing assertions
do not excuse script or import errors. Read `verify` before tests or captures and use at most one
or two purposeful gameplay captures. Report source registration, appearance and player acceptance
separately. The player approves SVG-first style transfer as the authoring workflow. M108,
eight-direction entity graphics, and M109, convert the SVG catalogue to PNG, specify the remaining
catalogue work. Review each family's visual result without treating workflow approval as proof
that every generated image is correct.
