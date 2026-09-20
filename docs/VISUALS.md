# Visual presentation

**Every PNG asset has a corresponding SVG asset. The SVG is always authored and reviewed first.**
SVG-first authoring followed by style transfer is the approved graphics workflow. Keep source SVGs
editable and record each SVG/PNG pair; generated source sheets are generation evidence.

The game uses a registered PNG when one exists. `--svg`, or `?svg=1` on the web,
forces original SVG graphics. The same drawing code handles both formats.
The transferred artwork covers both parents' pushing and carrying animation frames and the pram's
five authored views, supplying eight directions through explicit east/west mirroring. The garbage
sack, sack pile and five litter decals also use registered PNGs. The outdoor ground catalogue
under `assets/tiles/` uses registered PNG materials and components. Shared ground bases and transparent damage, markings
and grass features are composed in the engine through `GroundLayers`.
Trees, the overhead bollard cap, the ground tree bed and the rooftop water tank, HVAC units,
skylights, vent stack and ducts also have comic replacements. Other families use SVGs.
The logo, social card and exported stroller icon sizes use the comic identity mark, documented
with their SVG source mappings in the
[identity generation record](evidence/comic-identity-2026-09-12/GENERATION.md).
Compare directions, gait frames and state variants together so each parent carrying the baby
reads as the same person pushing the stroller. The female presentation wears red; the male
presentation has short brown hair and a blue overshirt. A run selects one with equal probability
from an independent seeded stream, before its player is placed; days and state changes only read it.
Both carrying and pushing use three distinct poses in four phases: open, together, opposite open,
together. Stopping selects the together pose in either state.

## Reference roles

The source SVG defines the subject, recognizable color identity, pose, direction, canvas and
functional placement. Transfer that idea into the references' comic drawing language, including
redrawn forms, expressive outlines and deliberate shadow shapes. Adding texture to the SVG's
primitive drawing is insufficient. Preserve anchors, gameplay boundaries and tile joins;
interior marks and contours should be authored in the reference style.
`evidence/graphics-reference-urban-01.jpeg` supplies the diagonal illustrated urban style;
`evidence/graphics-reference-cardinal.jpeg` supplies the style-transferred gameplay reference.
Use these for the illustration style. Exclude their interface, debug notes and annotations.
Keep the game's perspective and the SVG subject's identity.

The [player authoring sources](graphics-creation/player/README.md) preserve the high-fidelity SVG
targets used for the accepted PNG sprites. Their manifest distinguishes those creation references
from the runtime SVG fallback artwork. Both presentations provide contact and together poses. Use the
creation-reference family for high-fidelity generation and its linked recipes for reproduction.

## Replacement contract

`TextureResolver` maps `assets/<family>/<name>.svg` to
`assets/illustrated/svg-transfer/<family>/<name>.png`. Missing or differently sized PNGs fall
back to the SVG. Drawing transforms, animation timing, mirroring, ground anchors, sorting,
collision and camera framing remain the existing game's responsibility.

`TextureAtlas` then relocates whichever raster the resolver chose into one shared texture per
group of pictures — the street's decoration and one group per event family — and hands out
`AtlasTexture` regions over it. The player, the head indicators and the crowd draw from the baked
atlas below instead. The atlas changes no
picture: a region reports its source's own size, so scale, offsets, mirroring, anchors, shadows
and sorting read the same numbers in either presentation mode. A group is requested when its
first user is placed and released when its last user is gone; until it is collected, and again
after it is released, every user draws the source texture it would otherwise draw, so nothing
waits on an atlas and nothing draws a missing picture. `GroundLayers` packs the ground the same
way but in one texture the `TileSet` holds directly, each source reaching its own pictures
through `margins` with `texture_region_size` and `separation` unchanged.

## Baked atlases

`tools/bake-atlases.sh` writes one PNG page per group of `assets/atlases/membership.json` into
the gitignored `assets/atlases/baked/`, beside `regions.json` — where each picture sits on its
page and how big it is — and `bake_manifest.json`, which records the SHA-256 of every input the
bake read. The bake is the engine itself, headless: each authored SVG goes through
`Image.load_svg_from_buffer()` at scale 1.0 and `fix_alpha_edges()`, which is the same
rasterizer and the same alpha treatment the import pass gives the same file under
`svg/scale=1.0` and `process/fix_alpha_border=true`. That is what makes a baked pixel the pixel
the import pass produces. Sprite groups get a transparent one-pixel border around each region
and opaque tile families an extruded one, so a filtered sample at a region's edge reads the
picture rather than its neighbour.

**The presentation mode is the bake's.** The default bake takes the illustrated PNG wherever
`TextureResolver` would and the authored SVG's raster everywhere else; `--svg` bakes the
authored rasters alone. That is a custom local build, and `tools/export-web.sh` refuses to
export one.

**The pages are baked on demand and never committed.** Every tool that starts the engine calls
the wrapper first — `tools/check.sh`, `tools/test.sh`, `tools/run.sh`, `tools/shot.sh` and
`tools/export-web.sh`, and `tools/serve-web.sh` through the export — so nothing has to be
remembered. It compares the recorded hashes against the tree without starting the engine, and
bakes only when a source has moved or the mode on disk is not the mode asked for. The two that
open a window repair the way they already repair a stale import cache: through `tools/check.sh`,
which bakes *and* imports, since a freshly baked page is a file a windowed run would otherwise
draw the previous import of.

`AtlasLibrary` reads the result: `acquire(group)` loads that group's page, `release(group)`
drops it on the last reference, `region(name)` hands out an `AtlasTexture` over the page, and
`native_size(name)` answers a picture's own size from the region table with nothing loaded at
all. **The player, the head indicators and the crowd draw from it directly**: `Stroller` acquires
`stroller` and `head_indicators` for the whole run, `Crowd` acquires `crowd` for the day and every
`CrowdAgent` reads its region off the page the owner is already holding. Every other family still
reaches its pictures through `TextureResolver` and `TextureAtlas` as described above, until its own
consumer moves; `tests/test_atlas_library.gd` compares every baked region against the picture its
consumer draws today, pixel for pixel, for as long as that comparison is possible.

`tools/audit-pck.sh` reads an exported `.pck`'s own file table and reports how many baked
constituents it still carries — a member's source, its `.import` sidecar or its imported
`.ctex`. `tools/export-web.sh` runs it after every export and reports the count.

`GroundLayers` builds a presentation TileSet from the authored source resource. Its component
manifest in `assets/illustrated/svg-transfer/tiles/layers/` assigns a shared base and transparent
overlays to each supported source ID. Curbstones, street paint, crosswalks and damage blend in
the engine; pixels outside their alpha remain the base's own pixels. Parks and forests have sparse clump
arrangements selected by city seed and tile coordinates. Daily repaints start from the authored
resource, keeping composition stable. Missing components retain the normal PNG/SVG fallback,
and `--svg` uses the authored vector textures. Source IDs and gameplay geometry stay fixed.

Each runtime replacement matches the SVG's native dimensions and functional anchors.
Identity/export variants retain their documented source-derived canvas sizes. Registration preserves
the redrawn artwork's real transparency rather than stamping the SVG's primitive silhouette
over it. Opaque ground stays opaque; outlines, transparent gaps, internal placement and visual
quality require inspection alongside dimension and anchor checks.
Both complete player families draw from the baked `stroller` page, acquired once in
`Stroller._ready()` for the whole run, including every carrying pose. The bake mode and the pose
selector never reroll a presentation.
The [male player recipe](evidence/male-player-2026-09-19/GENERATION.md) preserves its SVG-first
sources, generated pushing/carrying sheets, native registration and eight-direction comparisons.
The [pushing stride record](evidence/comic-pushing-strides-2026-09-12/GENERATION.md) documents
P2 — Three-pose push, including SVG sources, whole-figure registration and all-direction
contact sheets. The [comic rig record](evidence/comic-rig-2026-09-12/GENERATION.md) preserves
P1 — Two-pose push and every stroller view.
The [stroller view recipe](evidence/stroller-view-assignment-2026-09-12/GENERATION.md) owns the
final illustrated direction assignment. Direction means travel: N/NE/NW show the baby and canopy
opening, S/SE/SW show the outside of the hood, and E/W use the original side image. Rebuild from
its frozen inputs; do not swap the installed textures again or infer direction from upstream
front/back source filenames.
The [north-diagonal contact review](evidence/stroller-diagonal-contact-2026-09-12/GENERATION.md)
records the small downward NE/NW placement adjustment across all three pushing poses. It fades
smoothly to zero at N/E/W; southern placements stay fixed to preserve wheel grounding, including
the accepted SE/SW hand gap.
The [southern wheel arrangement](evidence/stroller-southern-wheel-swap-2026-09-12/GENERATION.md)
defines final SE wheels from the frozen input's displayed SW and final SW wheels from its
displayed SE. Only wheel and lower attachment regions change. Rebuild from the immutable
source, never swap installed pixels; body height and canopy/handle geometry stay fixed.
The [hand-contact comparison](evidence/pram-contact-2026-09-12/MEASUREMENTS.md) assembles both
formats at the current continuous stroller offset. Shadows and cues share that drawing position;
the uniformly enlarged stroller retains its bottom ground anchor, and the collision body retains
its separate ground-plane position. Static contact does not establish
live turning. The [recipe index](evidence/README.md#graphics-recipes) locates generation,
registration, comparison-sheet and walking-GIF scripts with their inputs and regeneration commands.
The [comic prop record](evidence/comic-props-2026-09-12/GENERATION.md) preserves the redrawn
garbage and litter, their generated silhouettes and reproducible anchor registration.
The [city prop record](evidence/comic-city-props-2026-09-12/GENERATION.md) covers trees,
their opaque ground bed, the overhead bollard cap and rooftop equipment. The
[carrying hip-motion record](evidence/comic-carrying-hip-motion-2026-09-12/GENERATION.md) documents
F — Hip motion, its whole-figure source pairings and reproducible walking rollout.
The [tile generation record](evidence/style-transfer-tiles-2026-09-12/GENERATION.md) preserves
the terrain sheets, source-pair manifest and native/repeated-neighbor comparisons. Ground tiles
use fixed cell extraction because every pixel belongs to a filled tile, including its edges.
The [ground component recipe](evidence/layered-ground-2026-09-12/GENERATION.md) retains the
background-free damage stencils, curbstones, street paint and grass clumps. It also prepares
the asphalt and soft grass bases offline by blending four quarter-turn orientations with equal
contributions.
The [engine layout recipe](evidence/layered-ground-layout-2026-09-12/GENERATION.md) assembles
the actual runtime textures in generated streets, junctions and grass patches.
The [forest runtime probe](evidence/grass-runtime-2026-09-12/GENERATION.md) checks the actual
Main scene's loaded forest and park materials and records the ground cells around a reported location.
The [quiet-square recipe](evidence/quiet-square-2026-09-12/GENERATION.md) documents its muted
cool-stone paving and repeated-neighbor review.
The [plaza recipe](evidence/plaza-paving-2026-09-12/GENERATION.md) retains its larger slab layout
and the same muted-stone constraints, with frozen neighboring materials for repeat review.
The [paving joint recipe](evidence/paving-boundary-joints-2026-09-12/GENERATION.md) owns the final
boundary joints across the paving family and reproduces the accepted runtime tiles from frozen
materials. The [shared damage review](evidence/shared-damage-2026-09-12/GENERATION.md) compares
the common hairline, cracked and broken stencil variations over every supported floor base.
The [stoop step-face recipe](evidence/stoop-bottom-face-2026-09-12/GENERATION.md) appends an
existing brown riser band and compresses the tile back to its native height; its verifier checks
the complete runtime paving family against the registered materials and this final stoop derivative.

## Review

Review the detail at gameplay size, consistency across animation frames, transparent gaps,
ground contact and unchanged placement. Pixel registration alone does not establish acceptance.
The remaining catalogue work is in [TODO.md](TODO.md): M108, eight-direction entity graphics,
then M109, convert the SVG catalogue to PNG. [PLAYTEST-51](playtests/PLAYTEST-51.md) records the
approval and source-first requirement. Workflow approval does not replace each asset's review.

Use the [illustrated PNG skill](../.claude/skills/illustrated-png/SKILL.md) for integration.
Historical artwork and instructions are indexed in `DECISIONS.md`; the rejected graphics
archive is evidence only and must not become a style reference.
