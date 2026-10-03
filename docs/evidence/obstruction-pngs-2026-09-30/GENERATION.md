# Fallen-tree and broken-water-main PNG generation

These are rejected candidates, retained for provenance and comparison. The player's
[roof and obstruction review](../../playtests/2026-10-03-bouncy-squirrel.md) rejects these
water-main and fallen-tree PNGs as worse than their SVGs. The live game uses the existing SVG
families, including their separate water animation layers. The 28 candidate PNGs are preserved
byte-for-byte under `../archive/rejected-graphics/obstruction-pngs-2026-10-03/art/`.
Reproduction below compares with that archive and does not reinstall rejected art.

The player permits direct PNG creation for these obstructions when it produces a better result
than treating the SVG as an image-generation target. The existing SVGs remain the authority for
native canvas size, street-axis choice, obstruction footprint, anchor and water painter order.
The approved urban and cardinal references supply the requested comic rendering style; that
reference authority does not constitute acceptance of these generated obstruction candidates.

The built-in Codex image generator produces the retained raw RGBA sheets. Generation is
nondeterministic. `manifest.json` records every raw and source SHA-256, output size, source and
candidate alpha bounds, extraction cell and candidate-file SHA-256. Its historical `installed_*`
field names refer to the preserved candidate, not the active asset tree. The generator reports no
separate model/version identifier. Godot 4.7.2 renders the SVG geometry inputs, and Pillow 12.3.0
performs deterministic extraction, registration, composition and review-sheet assembly.

## Reference roles

- `docs/style-references/graphics-reference-urban-01.jpeg`: style only; its scene, people, text and
  interface are excluded.
- `docs/style-references/graphics-reference-cardinal.jpeg`: style and the game's cardinal
  projection only; its interface and debug annotations are excluded.
- `source-renders/trees-source-sheet.png`: event horizontal, event vertical, closure horizontal and
  closure vertical geometry/content, in that order.
- `source-renders/water-source-sheet.png`: horizontal A/B then vertical A/B full-scene geometry.
- `source-renders/water-horizontal-layers-source.png` and
  `source-renders/water-vertical-layers-source.png`: exact painter-order component families. Each is
  five cells wide and two cells high in the order named in the prompts below.
- `raw/trees-family-v1.png` and `raw/water-family-v1.png`: generated style concepts and
  edit targets for the cardinal revisions.
- `raw/water-family-v2-cardinal.png`: material and identity reference for both production layer
  sheets. The full runtime scenes are composed from the generated layers rather than cut from this
  concept.

## Exact prompts

`raw/trees-family-v1.png`:

```text
Use case: stylized-concept
Asset type: four-cell source sheet for small top-down/three-quarter 2D game sprites
Primary request: redraw one fallen broadleaf street tree as a consistent four-view family on a genuinely transparent background.
Input images:
Image 1: style reference only, approved diagonal urban comic rendering; ignore its UI, text, people, and scene composition.
Image 2: style reference only, approved cardinal gameplay comic rendering; ignore its UI, debug text, and scene composition.
Image 3: geometry/content reference sheet in fixed order: top-left event broadside, top-right event end-on, bottom-left closure broadside, bottom-right closure end-on.
Scene/backdrop: no scene and no ground tile; transparent background only.
Subject: the same uprooted mature broadleaf tree in four projections, with a recognizable torn root plate showing earth and roots, a solid brown trunk with broken branch stubs, and a broad clumped olive-green crown lying on its side.
Style/medium: authored comic game illustration with warm near-black irregular outlines, hand-shaped contours, deliberate highlight and shadow masses, restrained texture, and the muted olive/brown palette of the references.
Composition/framing: exact 2x2 grid matching Image 3's cell order and silhouette orientation, with generous transparent gutters. Keep every sprite fully inside its cell. No dividers, labels, captions, borders, or cast shadows.
Constraints: same tree identity, foliage clustering, bark treatment, root materials, light direction, and line weight across all four cells; preserve each source cell's orientation and approximate mass placement; broadside roots at one end and crown at the other; end-on root plate at the far/top end and crown toward the near/bottom end; transparent gaps between foliage clumps and around roots; readable at very small native game size.
Avoid: photorealism, vector-flat geometry, smooth airbrush rendering, generic clip art, text, UI, extra props, road, sidewalk, sky, square background, checkerboard background, duplicated trees within a cell, extra branches that change the footprint, and rotation of one view to fake another.
```

`raw/trees-family-v2-cardinal.png`:

```text
Use case: precise-object-edit
Asset type: corrected four-cell source sheet for small cardinal/overhead-ground 2D game sprites
Primary request: correct only the projection, scale balance, and placement of the four illustrated fallen trees so they fit the game's established cardinal view and source footprints while preserving the accepted comic style.
Input images:
Image 1: edit target, the accepted-style four-tree concept sheet.
Image 2: authoritative geometry and placement reference in the same cell order: event broadside, event end-on, closure broadside, closure end-on.
Image 3: approved diagonal urban comic style reference only.
Image 4: approved cardinal gameplay style and projection reference only; ignore UI and debug text.
Scene/backdrop: genuinely transparent, no ground tile or atmospheric field.
Composition/framing: retain the exact 2x2 cell order. Match each Image 2 silhouette's axis, footprint proportions, mass placement, and cardinal/overhead-ground projection. Event broadside must be a very wide low sprite; event end-on must be a very narrow tall sprite; closure broadside and closure end-on must be visibly smaller versions with their own source proportions. Preserve generous transparent gutters and keep each sprite fully inside its cell.
Subject constraints: keep Image 1's expressive torn root plate, olive clumped broadleaf crown, warm irregular linework, hand-shaped bark, highlight/shadow language, and consistent tree identity. Broadside roots remain at the left end and crown at the right. End-on root plate remains at the far/top end, trunk runs straight down-screen, crown lies near/bottom. Flatten the lying mass into the game's overhead-ground view; upright root faces can retain frontal depth. Transparent gaps remain around roots and between crown clumps.
Change only: projection, cell-relative scale, footprint proportion, and placement.
Keep unchanged: accepted comic rendering style, colors, material detail, light direction, root/tree identity, four-cell order.
Avoid: isometric ground yaw, three-quarter diagonal ground plane, foreshortening that shortens the street span, tall side-view trunk in end-on cells, photorealism, vector-flat geometry, text, borders, road, sidewalk, shadow ellipse, glow, background color, checkerboard, and extra props.
```

`raw/water-family-v1.png`:

```text
Use case: stylized-concept
Asset type: four-cell source sheet for a layered animated 2D game obstruction
Primary request: redraw one broken municipal water-main scene as a consistent two-orientation, two-phase animation family on a genuinely transparent background.
Input images:
Image 1: style reference only, approved diagonal urban comic rendering; ignore its UI, text, people, and scene composition.
Image 2: style reference only, approved cardinal gameplay comic rendering; ignore its UI, debug text, and scene composition.
Image 3: geometry/content reference sheet in fixed order: top-left horizontal phase A, top-right horizontal phase B, bottom-left vertical phase A, bottom-right vertical phase B.
Scene/backdrop: no road tile or surrounding scene; transparent background around the obstruction.
Subject: ruptured water main in a dark torn asphalt crater with heaved slabs, two visible broken pipe mouths, a shallow blue puddle and runoff, a forceful upright pale-blue fountain with foam and droplets, and one striped municipal barrier at each end.
Style/medium: authored comic game illustration with warm near-black irregular outlines, hand-shaped contours, deliberate highlight and shadow masses, restrained material texture, and the muted asphalt/brown/blue/red-white palette of the references.
Composition/framing: exact 2x2 grid matching Image 3's order and projection, with generous transparent gutters. Top row is the broad horizontal scene; bottom row is the narrow tall end-on scene. Keep each complete scene fully inside its cell. No dividers, labels, captions, borders, or cast shadows.
Animation contract: within each orientation, crater, split pipe, asphalt slabs, barrier boards and legs, barrier lamps, and the outer puddle footprint are exactly identical and in exactly the same positions in phase A and phase B. Change only the fountain shape, foam edge, airborne droplets, small splash arcs, and moving glints. Phase A is a narrower tall jet with outward droplets; phase B is a broader surging jet with changed droplets. The scene must read as alternating water over stationary infrastructure.
Constraints: preserve the source orientation, approximate obstruction footprint, barrier positions, and overhead-versus-upright projection; barriers remain red-and-white striped with amber lamps; crater reads as a recessed hole rather than a mound; pipe lies along the street direction; fountain rises upright; true transparent gaps between pieces; readable at 200x50 and 50x200 native canvases.
Avoid: photorealism, vector-flat geometry, smooth airbrush rendering, generic clip art, text, UI, extra workers or vehicles, complete road/sidewalk background, sky, square background, checkerboard background, different stationary objects between phases, moving barriers, missing barrier, extra barrier, cast shadow under the crater, and rotating one orientation to fake the other.
```

`raw/water-family-v2-cardinal.png`:

```text
Use case: precise-object-edit
Asset type: corrected four-cell source sheet for a layered cardinal/overhead-ground 2D game obstruction
Primary request: correct only the projection, scale balance, and placement of the four illustrated broken water-main scenes so they fit the game's established cardinal view and exact source footprints while preserving the accepted comic style.
Input images:
Image 1: edit target, accepted-style water-main concept sheet.
Image 2: authoritative geometry and placement reference in the same cell order: horizontal phase A, horizontal phase B, vertical phase A, vertical phase B.
Image 3: approved diagonal urban comic style reference only.
Image 4: approved cardinal gameplay style and projection reference only; ignore UI and debug text.
Scene/backdrop: genuinely transparent, no complete road tile and no atmospheric field.
Composition/framing: exact 2x2 cell order. Match Image 2's cardinal axes, obstruction footprint proportions, and mass placement. Top cells are extremely wide and shallow, designed for 200x50 canvases. Bottom cells are extremely narrow and tall, designed for 50x200 canvases. Preserve generous transparent gutters and keep every scene fully inside its cell.
Projection contract: asphalt crater, pipe, slabs, puddle, and runoff lie in a near-overhead ground plane aligned exactly horizontal or vertical, with no isometric yaw. The fountain and municipal barriers are upright objects seen frontally in the game's cardinal projection. The vertical scene is redrawn end-on, never a rotated horizontal scene.
Animation contract: within each orientation, crater, pipe, slabs, barrier boards/legs/lamps, and outer puddle footprint remain exactly identical and in exactly the same positions in phase A and phase B. Change only fountain shape, foam edge, airborne droplets, small splash arcs, and water glints.
Keep unchanged: Image 1's accepted comic rendering style, color palette, linework, material detail, recessed-hole reading, pipe identity, barrier identity, and A/B water contrast.
Change only: cardinal projection, footprint proportions, scale, and placement.
Avoid: isometric or diagonal ground yaw, foreshortening that shortens street span, side-view ground, photorealism, vector-flat geometry, workers, vehicles, full road or sidewalk background, cast shadow under crater, text, labels, borders, glow, background color, checkerboard, moving barriers, and different stationary geometry between phases.
```

`raw/water-horizontal-layers-v1.png`:

```text
Use case: style-transfer
Asset type: ten-cell transparent source sheet for painter-order layers of one animated horizontal broken water-main game sprite
Primary request: redraw every isolated component in Image 2 using the accepted comic materials and linework of Image 1, preserving the exact 5-column by 2-row cell order and keeping each cell semantically isolated.
Input images:
Image 1: accepted-style full water-main concept family; use it for the crater, pipe, asphalt, puddle, fountain, droplets, barrier identity, colors, linework, and shading.
Image 2: authoritative layer geometry and fixed cell order. Top row left-to-right: static puddle base; phase-A thin water arcs; phase-B thin water arcs; stationary crater/pipe/pool interior; phase-A small foam/glint. Bottom row left-to-right: phase-B small foam/glint; stationary broken slabs and pipe pieces; phase-A fountain/droplets/foam; phase-B fountain/droplets/foam; stationary pair of municipal barriers.
Image 3: approved diagonal urban comic style reference only.
Image 4: approved cardinal gameplay style reference only; ignore UI and debug text.
Scene/backdrop: genuinely transparent in every cell, with no atmospheric field and no road tile.
Composition/framing: exact 5x2 grid matching Image 2. Each cell contains only its named layer, centered independently with generous transparent gutters. No dividers, labels, captions, borders, or cell backgrounds. Horizontal/canonical cardinal projection only.
Layer contract: stationary cells contain no moving spray, fountain, droplets, foam, or glints. Animated cells contain only water motion and no crater, pipe, asphalt, barriers, lamps, or stationary puddle mass. Phase A and phase B of each animated pair share registration and scale but visibly differ in water contour. When the ten cells are overlaid in the source painter order, they reconstruct one coherent accepted-style scene and only the water changes between phases.
Constraints: transfer Image 1's authored comic detail rather than tracing Image 2's primitive pixel look; preserve Image 2's approximate isolated silhouette, aspect ratio, and placement within each cell; warm near-black outlines; transparent gaps; no cast shadow.
Avoid: merged cells, missing cells, duplicated layer content, complete scene in any cell, moving barriers, static objects in motion cells, water motion in static cells, isometric yaw, photorealism, vector-flat geometry, text, UI, road, sidewalk, glow, checkerboard, and opaque background.
```

`raw/water-vertical-layers-v1.png`:

```text
Use case: style-transfer
Asset type: ten-cell transparent source sheet for painter-order layers of one animated vertical/end-on broken water-main game sprite
Primary request: redraw every isolated component in Image 2 using the accepted comic materials and linework of Image 1, preserving the exact 5-column by 2-row cell order and keeping each cell semantically isolated.
Input images:
Image 1: accepted-style full water-main concept family; use it for the end-on crater, pipe, asphalt, puddle, fountain, droplets, barrier identity, colors, linework, and shading.
Image 2: authoritative layer geometry and fixed cell order. Top row left-to-right: stationary far barrier plus long puddle base; phase-A thin water arcs; phase-B thin water arcs; stationary end-on crater/pipe/pool interior; phase-A small foam/glint. Bottom row left-to-right: phase-B small foam/glint; stationary broken slabs and pipe pieces; phase-A fountain/droplets/foam; phase-B fountain/droplets/foam; stationary near municipal barrier.
Image 3: approved diagonal urban comic style reference only.
Image 4: approved cardinal gameplay style reference only; ignore UI and debug text.
Scene/backdrop: genuinely transparent in every cell, with no atmospheric field and no road tile.
Composition/framing: exact 5x2 grid matching Image 2. Each cell contains only its named layer, centered independently with generous transparent gutters. No dividers, labels, captions, borders, or cell backgrounds. Vertical/end-on cardinal projection only; do not rotate a horizontal view.
Layer contract: stationary cells contain no moving spray, fountain, droplets, foam, or glints. Animated cells contain only water motion and no crater, pipe, asphalt, barriers, lamps, or stationary puddle mass. Phase A and phase B of each animated pair share registration and scale but visibly differ in water contour. When the ten cells are overlaid in the source painter order, they reconstruct one coherent accepted-style end-on scene and only the water changes between phases.
Constraints: transfer Image 1's authored comic detail rather than tracing Image 2's primitive pixel look; preserve Image 2's approximate isolated silhouette, aspect ratio, and placement within each cell; warm near-black outlines; transparent gaps; no cast shadow; far barrier smaller than the near barrier through the game's established end-on projection.
Avoid: merged cells, missing cells, duplicated layer content, complete scene in any cell, moving barriers, static objects in motion cells, water motion in static cells, isometric yaw, rotated horizontal scene, photorealism, vector-flat geometry, text, UI, road, sidewalk, glow, checkerboard, and opaque background.
```

## Registration and reproduction

`render_sources.gd` rasterized the four tree SVGs and four complete water scenes with Godot's own
SVG decoder. `render_layer_sources.gd` rasterized the 20 existing painter-order layer SVGs and
assembled the two generation-reference grids. Those committed renders are frozen registration
inputs: `install.py` pins and verifies all 28 files before creating any output. The generated
sheets contain real alpha; the dark fields visible in some viewers are RGB beneath transparent
pixels. The rebuild clears alpha at or below 8, makes alpha at or above 248 fully opaque, and
preserves the antialiased interval.

Tree cells are cropped at the bounds recorded in `TREE_SPECS` and fitted to the source picture's
complete alpha extent, so the event tree covers 200×50/50×200 and the closure marker covers
98×40/44×122 with the established roots-to-crown street span. Layer cells follow the exact 5×2
grid order. Each generated component is fitted into its source layer's native alpha extent without
using the SVG silhouette as an alpha mask. The broadside barriers are registered independently to
their left and right source positions. Full A/B water scenes are then composed from the candidate
layers at the runtime offsets in `src/events/event_scenery_parts.gd`; stationary layers are byte-for-byte
the same across phases and only the three water layers select `_b` files.

The source-render commands that created the frozen inputs were, from the repository root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/obstruction-pngs-2026-09-30/render_sources.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/obstruction-pngs-2026-09-30/render_layer_sources.gd
```

They write the tracked source-render directory and are only for an intentional registration-input
refresh, followed by review and updated pins. An ordinary rebuild writes a full repo-relative
layout to a required new directory and refuses an existing destination, so it cannot overwrite
active art or retained evidence:

```sh
uv run python docs/evidence/obstruction-pngs-2026-09-30/install.py \
  /private/tmp/obstruction-png-build
```

Compare the staging tree with the preserved rejected output; do not copy it into active art:

```sh
diff -r /private/tmp/obstruction-png-build/art \
  docs/evidence/archive/rejected-graphics/obstruction-pngs-2026-10-03/art
for artifact in manifest.json review-native.png review-enlarged.png water-phases.gif; do
  cmp "/private/tmp/obstruction-png-build/docs/evidence/obstruction-pngs-2026-09-30/$artifact" \
    "docs/evidence/obstruction-pngs-2026-09-30/$artifact" || exit 1
done
```

`review-native.png` places all four trees and four complete water scenes on a light neutral backing
at exact native size. `review-enlarged.png` uses nearest-neighbor 4× enlargement. `water-phases.gif`
alternates the two generated layer compositions every 0.5 seconds; it proves generated animation
coverage and stationary-layer reuse, not gameplay timing or visual acceptance.

## In-engine context

`../m109-water-main-context-2026-09-30/in-engine-water-main.gif` is a 36-frame, 2.99-second burst
of the rejected horizontal candidate on
its real roadway, between the game's buildings and sidewalks and among its crowd. The burst shows
the two generated water phases while the generated crater, pipe, asphalt and barriers remain fixed.
It establishes in-engine perspective, scale, placement and animation coverage. The run uses
`--invincible`, so it establishes no meter cost or day outcome. The whole run folder, including its
log, map and `burst.json` timestamps, remains beside the GIF with its original name.

The following capture command now renders the current SVG comparison. It does not recreate the
retained rejected candidate, whose original capture is the artifact described above. The GIF
command reads that preserved candidate burst and writes only to scratch.

```sh
./tools/shot.sh /private/tmp/obstruction-water.png 10 --seed 4242 \
  --spawn event:burst_water_main --press snapshot_burst 5 --invincible --no-save
uv run python docs/evidence/m159-scenery-animation-2026-09-26/burst-gif.py \
  docs/evidence/m109-water-main-context-2026-09-30/rig-043407-seed4242-v0.21.1-2-ga5303253-dirty/asked/burst-11410367-001 \
  /private/tmp/obstruction-candidate-water.gif --width 960
```

`../m109-fallen-tree-context-2026-09-30/in-engine-fallen-tree.png` shows the rejected broadside
event tree spanning a north-south street from the uprooted sidewalk to the crown at the opposite
edge, among the game's buildings, street trees, park edge, crowd and player. It establishes that
orientation's in-engine perspective, scale and placement. It does not establish the end-on event
view or either smaller closure-marker view. The whole run folder remains beside the still with its
original name. The first documented `--spawn closure:0` target on seed 4229 now selects the day's
accident closure; the event itself remains at `--spawn event:fallen_tree`, which is the capture
used here.

This command likewise renders the current SVG comparison, not the retained candidate still:

```sh
./tools/shot.sh /private/tmp/obstruction-tree.png 4 --seed 4229 \
  --spawn event:fallen_tree --invincible --no-save
```
