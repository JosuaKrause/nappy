# Registered SVG style transfers

The default atlas bake takes these PNGs wherever one sits beside its SVG; a
`tools/bake-atlases.sh --svg` bake takes the SVGs alone and is a custom local build, never the
release. Nothing at runtime chooses between them — the pixels on a baked page are the ones the
build chose. The `rig/`, `props/` and `tiles/` subdirectories mirror the source family paths
under `art/`. The mother animation frames and authored pram views preserve each source SVG's
native canvas and functional anchors. Comic redraws keep their own expressive silhouettes and
true transparency. A PNG whose size disagrees with its SVG fails the bake by name: the game
carries no second copy of the picture to fall back to.

Native PNG dimensions are intentional: these are drop-in replacements for the existing textures
and draw transforms. Generation inputs, raw atlases, exact prompts, reproducible registration
scripts and measured source/target bounds accompany each family below.

Outdoor tile generation, source pairings and repeated-neighbor comparisons are in
`docs/evidence/style-transfer-tiles-2026-09-12/`. The prepared alley alternative remains unbound
in both formats.

The comic mother/stroller family is in `docs/evidence/comic-rig-2026-09-12/`; prop redraws and
their generated transparency are in `docs/evidence/comic-props-2026-09-12/`. The comic tile
redraws and functional paint registration are in
`docs/evidence/style-transfer-tiles-2026-09-12/comic/`. Identity/export PNGs live outside this
tree, beside it under `art/`; their SVG mappings and recipe are in
`docs/evidence/comic-identity-2026-09-12/`.

Side and diagonal views mirror explicitly for west, supplying all eight directions without
rotating upright artwork.

The carrying mother's current redraw is documented in
`docs/evidence/comic-carrying-redraw-2026-09-12/`. Trees, their opaque ground bed, the
overhead bollard cap and rooftop equipment use the source mappings and extraction recipe in
`docs/evidence/comic-city-props-2026-09-12/`.

SVG-first authoring followed by style transfer is the approved workflow. Every PNG asset needs
a corresponding SVG authored and reviewed first. M108, eight-direction entity graphics, and
M109, convert the SVG catalogue to PNG, hold the remaining catalogue work in `docs/TODO.md`.
