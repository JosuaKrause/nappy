## M171, build-time atlases replace individual textures — 2026-09-19

[PLAYTEST-105](../playtests/PLAYTEST-105.md) requests an implementation TODO: atlases must be
created at build time for cheap runtime loading, related items must share an atlas to avoid
wasted residency, and an atlas's constituent textures must never also load individually.
This extends the grouping and advance-loading intent of PLAYTEST-75 and PLAYTEST-76.

Inspection found runtime packing in `TextureAtlas.request()`/`collect()`: source images are
read on the main thread, blitted on a worker, then uploaded on the main thread. Crowd's first
pack waits synchronously; ground packs during TileSet construction and day repaint. The
preloaded originals stay resident, and `TextureResolver.warm()` also loads individual transfers.
Dropping temporary CPU image buffers therefore does not remove the original GPU textures.
The atlas plus retained originals duplicates image storage; no measured exact memory ratio
was claimed. Merely moving the existing blit earlier would leave that ownership problem.

The queued contract generates deterministic images and region metadata in the build, groups
related consumers and lifetimes, and makes runtime references resolve to atlas regions only.
PNG and SVG comparison modes remain available through separately built, exclusively selected
resources. Source files remain editable authoring inputs without becoming runtime constituent
textures. Validation must cover exports, indirect preloads, group release, GPU residency and
the existing visual/animation contracts. No atlas implementation changes accompany this design.

The player then clarifies that the exclusion is stronger than avoiding duplicate GPU uploads:
"or any memory. they should cease existing in the build once they get baked into an atlas".
The TODO therefore excludes individual baked images and their imported resource copies from
the exported package, forbids runtime CPU/GPU constituent copies, and requires package-content
and dependency checks in addition to memory measurements. Source artwork stays in the repository
for authoring; it is not a fallback dependency in the shipped atlas-only representation.
