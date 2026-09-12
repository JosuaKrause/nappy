# Visual presentation

**Every PNG asset has a corresponding SVG asset. The SVG is always authored and reviewed first.**
SVG-first authoring followed by style transfer is the approved graphics workflow. Keep source SVGs
editable and record each SVG/PNG pair; generated source sheets are generation evidence.

The game uses a registered PNG when one exists. `--svg`, or `?svg=1` on the web,
forces original SVG graphics. The same drawing code handles both formats.
The transferred artwork covers the mother's pushing and carrying animation frames and the pram's
five authored views, supplying eight directions through explicit east/west mirroring. The garbage
sack, sack pile and five litter decals also use registered PNGs. The outdoor ground catalogue
under `assets/tiles/` has matching PNGs, including its damage and directional marking variants.
Trees, the overhead bollard cap, the ground tree bed and the rooftop water tank, HVAC units,
skylights, vent stack and ducts also have comic replacements. Other families use SVGs.
The logo, social card and exported stroller icon sizes use the comic identity mark, documented
with their SVG source mappings in the
[identity generation record](evidence/comic-identity-2026-09-12/GENERATION.md).
Compare directions, gait frames and state variants together so the mother
carrying the baby reads as the same woman pushing the stroller.
The carrying walk uses three distinct poses in four phases: open, together, opposite open,
together. Stopping selects the together pose. The pushing walk uses its own two-frame family.

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

## Replacement contract

`TextureResolver` maps `assets/<family>/<name>.svg` to
`assets/illustrated/svg-transfer/<family>/<name>.png`. Missing or differently sized PNGs fall
back to the SVG. Drawing transforms, animation timing, mirroring, ground anchors, sorting,
collision and camera framing remain the existing game's responsibility.

Each runtime replacement matches the SVG's native dimensions and functional anchors.
Identity/export variants retain their documented source-derived canvas sizes. Registration preserves
the redrawn artwork's real transparency rather than stamping the SVG's primitive silhouette
over it. Opaque ground stays opaque; outlines, transparent gaps, internal placement and visual
quality require inspection alongside dimension and anchor checks.
The [comic rig record](evidence/comic-rig-2026-09-12/GENERATION.md) documents generation and
extraction for the pushing mother and every stroller view. Its assembly sheets approximate
source placement and do not establish live hand-to-handle contact.
The [hand-contact comparison](evidence/pram-contact-2026-09-12/MEASUREMENTS.md) assembles both
formats at the current continuous stroller offset. Shadows and cues share that drawing position;
the collision body retains its separate ground-plane position. Static contact does not establish
live turning. The [recipe index](evidence/README.md#graphics-recipes) locates generation,
registration, comparison-sheet and walking-GIF scripts with their inputs and regeneration commands.
The [comic prop record](evidence/comic-props-2026-09-12/GENERATION.md) preserves the redrawn
garbage and litter, their generated silhouettes and reproducible anchor registration.
The [city prop record](evidence/comic-city-props-2026-09-12/GENERATION.md) covers trees,
their opaque ground bed, the overhead bollard cap and rooftop equipment. The
[carrying stride record](evidence/comic-carrying-strides-2026-09-12/GENERATION.md) documents
the current three-pose carrying family, its source pairings and reproducible walking rollout.
The [tile generation record](evidence/style-transfer-tiles-2026-09-12/GENERATION.md) preserves
the terrain sheets, source-pair manifest and native/repeated-neighbor comparisons. Ground tiles
use fixed cell extraction because every pixel belongs to a filled tile, including its edges.

## Review

Review the detail at gameplay size, consistency across animation frames, transparent gaps,
ground contact and unchanged placement. Pixel registration alone does not establish acceptance.
The remaining catalogue work is in [TODO.md](TODO.md): M108, eight-direction entity graphics,
then M109, convert the SVG catalogue to PNG. [PLAYTEST-51](playtests/PLAYTEST-51.md) records the
approval and source-first requirement. Workflow approval does not replace each asset's review.

Use the [illustrated PNG skill](../.claude/skills/illustrated-png/SKILL.md) for integration.
Historical artwork and instructions are indexed in `DECISIONS.md`; the rejected graphics
archive is evidence only and must not become a style reference.
