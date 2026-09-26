## M171, the atlas design — 2026-09-19

[PLAYTEST-108](../playtests/PLAYTEST-108.md): *"I think we should focus on fixing the structure of
texture/sprite atlases. the implementation we currently have is not great"*. The contract is
[PLAYTEST-105](../playtests/PLAYTEST-105.md)'s. A read-only inventory preceded the design.

**What the inventory found.** 453 `preload` constants for SVGs (258 in `event_instance.gd`, 70
in `stroller.gd`, 40 in `building.gd`, 30 in `crowd_agent.gd`), four runtime `load()` sites, and
58 SVG references in `assets/ground_tileset.tres`; no PNG is ever preloaded, the illustrated
PNGs arriving only through `TextureResolver`'s path mapping. A picture was resident up to four
times: the preload constant, the resolver's cache — whose `warm()` loaded the SVG *and* its PNG —
the pack's own `sources` array, and the atlas; `release()` freed the last only. Packing read
each picture back from the GPU on the main thread; the crowd's first pack blocked inside a draw
call; the ground recomposed and repacked synchronously on every day repaint. Three packers
(`TextureAtlas`, `GroundLayers.pack_into_one_texture()`, `CrowdAtlas`) and four hand-kept source
tables mirrored the draw code, and every draw site could draw either the region or the source.
Buildings, the interior, closures, checkpoints, traffic lights, the city edge and the UI were
not atlased at all. All 610 SVG imports use scale 1.0, no compression and `fix_alpha_border`;
the in-game catalogue is about 1.15 megapixels and the events about 0.43, so every family fits
one page well inside 2048px. Illustrated PNGs exist for the rig, tiles, tile layers and 19 props.

**Chosen: the engine bakes, headless.** Same rasterizer as the importer, and it can run the
ground's own code. **Rejected: a Python baker** — it needs a second SVG rasterizer whose
antialiasing differs, which breaks pixel parity and the curb colour-match tolerance, and it
cannot reproduce Godot's `hash()` and random generator. **Rejected: the engine's built-in 2D
atlas import mode**, understood (not verified here) to keep per-source resources and not to
serve a TileSet. **Rejected: leaving sources in `assets/` behind an export filter** as the end
state, since a development run could still load a constituent silently.

**The player's answers**, recommendation first where it was refused:

- Mode: *two separately built resources selected before load (PLAYTEST-105) · overturned by the
  player* — "png vs svg mode now should happen at build time -- so we always get png mode -- if
  we really want svg mode we need to run a custom build command locally (no need to have this in
  the release version)".
- "baked on demand. for running locally check the source hashes."
- "move them out but make sure every reference gets updated so we don't have stale instructions
  or comments (code will fail but documentation will not)".
- "we can do one events page for now".
- *Recommended: grass variants and the route-curb tint as bake outputs · refused* — "no, we bake
  each individual item and the composite at runtime. this is not a bottleneck and it allows for
  variety. if we baked everything either we would need to make the atlas huge or we would lose
  variety."

**Open to overturn, stated to the player and not spoken to:** no desktop export is in scope;
the identity images leave the game package; a family with no illustrated PNG is the same pixels
in either bake. The staging into seven pull requests is the orchestrator's, drawn so that the
three consumer moves touch disjoint files and the ground and the events wait for the work that
shares their files. The player also set the order: M163 before, M159 after.
