# Visual presentation

**Every PNG asset has a corresponding SVG asset. The SVG is always authored and reviewed first.**
SVG-first authoring followed by style transfer is the approved graphics workflow. Keep source SVGs
editable and record each SVG/PNG pair; generated source sheets are generation evidence.

The game uses a registered PNG when one exists. `--svg`, or `?svg=1` on the web,
forces original SVG graphics. The same drawing code handles both formats.
The transferred artwork covers the mother's pushing and carrying animation frames and the pram's
five authored views, supplying eight directions through explicit east/west mirroring. The garbage
sack, sack pile and five litter decals also use registered PNGs. The outdoor ground catalogue
under `assets/tiles/` uses registered PNG materials and components. Shared ground bases and transparent damage, markings
and grass features are composed in the engine through `GroundLayers`.
Trees, the overhead bollard cap, the ground tree bed and the rooftop water tank, HVAC units,
skylights, vent stack and ducts also have comic replacements. Other families use SVGs.
The logo, social card and exported stroller icon sizes use the comic identity mark, documented
with their SVG source mappings in the
[identity generation record](evidence/comic-identity-2026-09-12/GENERATION.md).
Compare directions, gait frames and state variants together so the mother
carrying the baby reads as the same woman pushing the stroller.
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
from the runtime SVG fallback artwork. Both families provide contact and together poses. Use the
creation-reference family for high-fidelity generation and its linked recipes for reproduction.

## Replacement contract

`TextureResolver` maps `assets/<family>/<name>.svg` to
`assets/illustrated/svg-transfer/<family>/<name>.png`. Missing or differently sized PNGs fall
back to the SVG. Drawing transforms, animation timing, mirroring, ground anchors, sorting,
collision and camera framing remain the existing game's responsibility.

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
The [southern wheel recipe](evidence/stroller-wheel-mirror-2026-09-12/GENERATION.md) applies NE
wheel pixels to the SE view after direction assignment; SW uses its runtime reflection. Only
wheel and lower attachment regions change, preserving body height and the canopy/handle geometry.
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
