# Visual presentation

**Every PNG asset has a corresponding SVG asset. The SVG is always authored and reviewed first.**
SVG-first authoring followed by style transfer is the approved graphics workflow. Keep source SVGs
editable and record each SVG/PNG pair; generated source sheets are generation evidence.

The game draws whichever raster the bake chose: a registered PNG where one exists, the authored
SVG's own raster everywhere else. **The choice is made before the game runs and nothing at
runtime can move it** — see "Baked atlases" below.
The transferred artwork covers both parents' pushing and carrying animation frames and the pram's
five authored views, supplying eight directions through explicit east/west mirroring. The garbage
sack, sack pile and five litter decals also use registered PNGs. The outdoor ground catalogue
under `art/tiles/` uses registered PNG materials and components. Shared ground bases and transparent damage, markings
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
`style-references/graphics-reference-urban-01.jpeg` supplies the diagonal illustrated urban style;
`style-references/graphics-reference-cardinal.jpeg` supplies the style-transferred gameplay reference.
Use these for the illustration style. Exclude their interface, debug notes and annotations.
Keep the game's perspective and the SVG subject's identity.

The [player authoring sources](graphics-creation/player/README.md) preserve the high-fidelity SVG
targets used for the accepted PNG sprites. Their manifest distinguishes those creation references
from the runtime SVG fallback artwork. Both presentations provide contact and together poses. Use the
creation-reference family for high-fidelity generation and its linked recipes for reproduction.

## Where the pictures live

**The authoring sources are not in the game.** `art/` holds every picture the bake reads —
`art/<family>/<name>.svg` and the illustrated transfer beside it at
`art/illustrated/svg-transfer/<family>/<name>.png` — and carries a `.gdignore`, so the engine
imports nothing there, keeps no `.import` sidecar there and exports nothing from it. *"they
should cease existing in the build once they get baked into an atlas."* Nothing in `src/` names
one: a consumer holds the region name its picture is baked under, `<family>/<name>`.

What stays under `assets/` is what the engine itself reads at runtime: the gitignored baked pages
with `regions.json` beside them, `assets/atlases/membership.json`, `assets/ground_tileset.tres`,
`assets/ground_layers.json` and `assets/shaders/`. The identity images — the wordmark, the
stroller icon sizes and the social card — are `art/`'s too; the application icon is the
repository root's own `icon.png`, which the engine does load.

A region changes no picture: it reports its source's own size, so scale, offsets, mirroring,
anchors, shadows and sorting read exactly the numbers they read from a texture of its own.
Drawing transforms, animation timing, ground anchors, sorting, collision and camera framing
remain the existing game's responsibility.

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

**The presentation mode is the bake's, and there is no other.** The default bake takes the
illustrated PNG wherever one exists beside the SVG and agrees with it on size, and the authored
SVG's raster everywhere else; `tools/bake-atlases.sh --svg` bakes the authored rasters alone.
That is a custom local build, and `tools/export-web.sh` refuses to export one. A run cannot ask
for the other mode, because the pixels on the page are the ones the build chose;
`AtlasLibrary.bake_mode()` is how the ground compositor finds out which it got.

**And a page holds what its own mode draws.** A group in `membership.json` lists the pictures
both bakes carry under `members` and the ones only one of them draws under `members_png` and
`members_svg`; a bake reads, hashes and packs its own mode's two lists and never looks at the
other's, so changing a picture only the other mode draws leaves this tree up to date. The
`ground` group is the one that needs it: a default bake composes 46 of the 58 TileSet sources
out of layers, so the whole authored pictures of those 46 are members of an `--svg` bake alone,
and the layers they are composed from are members of a default bake alone. Any other key in a
group record, or a picture listed twice in the mode being baked, fails the bake by name.

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
all. **Every family but the ground and the events draws from it directly.** `Stroller` acquires
the run's own parent (`mother` or `father`), `stroller` — the pram, which either parent pushes —
and `ui`, where the marks over her head sit beside the screen furniture. `Crowd` acquires
`crowd` on its first day and every `CrowdAgent` reads its region off the page the owner is
already holding. `src/city/prop.gd`, `src/city/litter.gd` and `src/city/city_decals.gd` ask
`region()` and `native_size()` on region names rather than on loaded textures. Buildings, the
street kit (the city edge, closure markers, traffic lights), the UI (`ModeButton`,
`TouchControls`, `SaveIndicator`) and the interior (`InteriorScene`, `InteriorTileSet`) each
acquire their own group as they enter the tree and release it as they leave. The events are one
page — the whole catalogue, the checkpoint kit and the finale's crater — and `EventManager` holds
one reference on it for its own life, which the screen-edge badge's silhouettes draw from too, so
the thing at the edge of the screen and the thing in the street are the same pixels. The ground
composes its tiles from regions of the `ground` page's image on every repaint.

## When a page loads

**A page is read from disk at startup or during a day brief and at no other moment.**
`acquire()` is a blocking `load()` in whatever frame calls it, so a page that arrives on the
frame it is first drawn in is a stutter the player sees. `AtlasLibrary` is told which moment is
open — `startup`, `day brief`, or `escape` for the `--start-escape` boot, which is that mode's
own startup — and an `acquire()` that still has to read from disk with no window open loads it
anyway, writes `OUTSIDE` in the run log and raises an engine error, which makes the test gate
red. A process where no boot has claimed the moments at all is `unmanaged` and loads freely:
that is a suite building a `City` or a `Stroller` by hand, where no frame is being watched.

**The ground's composition recipe follows the same rule.** `GroundLayers` reads
`assets/ground_layers.json` once, in the city's first build, and holds it for the life of the
process, so a day's repaint composes from the held page and the held recipe and reads nothing
from disk.

**`main`'s boot holds every group a day can draw for the life of the process** —
`main.RESIDENT_GROUPS`, plus the run's own parent — so nothing is ever unloaded between one day
and the next, and a consumer's own `acquire()`/`release()` pair is only ever a count on a page
that is already there. The residency is what makes that true by construction: a consumer's
release can drop the count to the residency underneath it and no further, so a city torn down
between two runs or a node re-entering the tree costs no reload.

**Two groups are not in that list.** The **other parent's** page — the choice is fixed for a
run, so the run that draws the mother never loads the father's sixty views, and a held restart
that rerolls the choice gives the previous one back. And the **interior**, which only the escape
sequence draws; it is held from the `--start-escape` boot, and moves to that sequence's own
brief when M102, the finale, has one.

The run log carries one `texture` line per page actually read, with the moment, the milliseconds
the read took and the page's size, and one per page actually dropped, with how long it was
resident.

`tools/audit-pck.sh` reads an exported `.pck`'s own file table and answers two questions about
it: whether any baked constituent is still in it — a member's source, its `.import` sidecar or
its imported `.ctex` — and whether any baked page in it is one the pack's own `regions.json`
names no group for, which is what a group folded into another leaves behind.
`tools/export-web.sh` runs it with `--fatal` after every export, so either fails the export.

`GroundLayers` builds a presentation TileSet from the authored source resource, which names each
source's baked region and holds no texture of its own. Every base, overlay, damage stencil, grass
feature and whole authored tile it draws is a region of `AtlasLibrary.page_image(&"ground")`, read
once per build, and the composed pictures go to the GPU as one sheet. Its component
manifest, `assets/ground_layers.json`, assigns a shared base and transparent
overlays to each supported source ID; it stays under `assets/` because the game reads it at
runtime, and the Web preset's `include_filter` names it so the export keeps it. Curbstones, street paint, crosswalks and damage blend in
the engine; pixels outside their alpha remain the base's own pixels. Parks and forests have sparse clump
arrangements selected by city seed and tile coordinates. Daily repaints start from the authored
resource, keeping composition stable.

**A default bake's page carries what it composes from and nothing it composes.** The layers are
on it, and the twelve whole tiles whose source the recipe composes nothing for — `bulkhead`,
`courtyard`, `fence`, `mountain`, `plaza`, `precinct`, `quiet_square`, `sand`, `scree`,
`spoiled`, `stoop`, `water` — and no whole picture of the 46 sources it does compose, so no SVG
raster of a ground tile reaches the game. **A composed source's picture is therefore its
composition or nothing**: a recipe that cannot be carried out — a missing base, component,
damage pool or grass feature — is a `push_error` naming the source and what was missing, and the
test gate is red for it. A `tools/bake-atlases.sh --svg` page is the reverse: all 58 whole tiles,
no layer, and nothing composed but the route-kerb tint, which it finds by matching the
curbstone's own fill colour. Source IDs and gameplay geometry stay fixed in both.

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
