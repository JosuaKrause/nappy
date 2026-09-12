# Playtest 64 — Ground tiles in PNG

2026-09-12

> let's convert more assets to png -- let's focus on tiles next

Continue M109, convert the SVG catalogue to PNG, with the outdoor ground family in
`assets/tiles/`. Preserve the SVG geometry, palette, markings, seams and native canvases;
review repeated terrain and neighboring road/sidewalk variants together. The SVG-first
workflow and the style references in `VISUALS.md` remain authoritative.

## Restaurant seating directions

> in the horizontal restaurant, the right person looks in the wrong direction. in the vertical version they are looking sideways

Inspect the café sitters' facing selection and chair-to-table placement in both frontage
orientations. Each seated person should face their table; horizontal and vertical layouts
need directions derived from the individual seat, not one facing shared by the whole row.

## Barrier direction and vertical artwork

> vertical barriers look wrong (just sideways textures stacked on top of each other) also barriers in horizontal alleys use the wrong orientation

The supplied screenshot is `asked/002-attempt2-asked.png` in the preserved full run
[run-143205-seed1489549101-v0.8.2-764-g28fe845](../evidence/playtest-64-2026-09-12/run-143205-seed1489549101-v0.8.2-764-g28fe845/).
It shows horizontal boards stacked along vertical barrier bands. Inspect the authored end
view and the barrier drawing callers, plus how an alley's axis chooses the barrier across it.
Use the correct upright/end-view artwork and place it along the actual barrier axis.

## Tree beds belong to the ground

> the bed of the tree should be a tile not an object. it currently draws on top of the stroller

The supplied screenshot is `asked/005-attempt3-asked.png` in the same preserved run above.
Render the tree bed as ground beneath the stroller and other upright actors; keep the tree
itself in the existing upright drawing and collision system. Preserve the bed's position,
size and tree placement.

## Style transfer means transferring the idea

> hmm, a lot of those textures are basically the exact same as the svg just with a nicer texture. style transfer means that the idea of the svg graphic gets *transferred* to the style of the comicesque reference images

The player rejects the surface-only treatment in the first tile comparison. Transfer the
SVG's subject and gameplay meaning into the references' comic drawing: authored shapes,
expressive outlines, material-specific marks and deliberate shadow shapes. The original
primitive edges and tiny rectangular details are not a tracing template. Preserve functional
tile boundaries, directional markings, anchors and source pairing, without freezing the
SVG's interior drawing. Rework the outdoor family and compare the actual native-size tiles.

> the same applies to all textures generated so far

Apply this correction to the complete generated texture catalogue, including the mother in
both states, the stroller, garbage and litter, as well as ground tiles. Audit prior families
and rework their drawing; do not treat the correction as a tiles-only instruction.

## Tile redraw approval

> yes I like the new versions

> of the tiles

The player approves the comic tile redraws. This approval covers the tiles specifically;
the revised mother, stroller, props and identity assets still require their own review.
