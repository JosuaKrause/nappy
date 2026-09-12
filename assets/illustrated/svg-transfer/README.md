# Registered SVG style transfers

These PNGs replace their matching SVG textures by default; `--svg` forces SVGs.
The `rig/`, `props/` and `tiles/` subdirectories mirror the source family paths under `assets/`.
The mother animation frames and authored pram views preserve each source SVG's native canvas
and functional anchors. Comic redraws keep their own expressive silhouettes and true transparency.
Missing or differently sized PNGs fall back to SVGs.

The generation inputs, raw atlas, extraction, reproducible registration script and measured
source/target bounds are in `docs/evidence/style-transfer-2026-09-10/`. Native PNG dimensions
are intentional: these are drop-in replacements for the existing textures and draw transforms.
The high-resolution generated atlas remains preserved for inspection.

Outdoor tile generation, source pairings and repeated-neighbor comparisons are in
`docs/evidence/style-transfer-tiles-2026-09-12/`; litter and garbage prop generation is in
`docs/evidence/style-transfer-litter-2026-09-12/`. The prepared alley alternative remains
unbound in both formats.

Diagonal inputs, exact prompt, source hashes and registration commands are in
`docs/evidence/style-transfer-eight-directions-2026-09-10/`. Side and diagonal views mirror
explicitly for west, supplying all eight directions without rotating upright artwork.

SVG-first authoring followed by style transfer is the approved workflow. Every PNG asset needs
a corresponding SVG authored and reviewed first. M108, eight-direction entity graphics, and
M109, convert the SVG catalogue to PNG, hold the remaining catalogue work in `docs/TODO.md`.
