# Registered SVG style transfers

These PNGs replace their matching `assets/rig/*.svg` textures by default; `--svg` forces SVGs.
The six mother animation frames and three pram views preserve each source SVG's native canvas
and alpha silhouette. Missing or differently sized PNGs fall back to SVGs.

The generation inputs, raw atlas, extraction, reproducible registration script and measured
source/target bounds are in `docs/evidence/style-transfer-2026-09-10/`. Native PNG dimensions
are intentional: these are drop-in replacements for the existing textures and draw transforms.
The high-resolution generated atlas remains preserved for inspection.

SVG-first authoring followed by style transfer is the approved workflow. Every PNG asset needs
a corresponding SVG authored and reviewed first. M108, eight-direction entity graphics, and
M109, convert the SVG catalogue to PNG, hold the remaining catalogue work in `docs/TODO.md`.
