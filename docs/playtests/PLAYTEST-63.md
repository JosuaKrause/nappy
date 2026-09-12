# Playtest 63 — Ground tiles in PNG

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
[run-143205-seed1489549101-v0.8.2-764-g28fe845](../evidence/playtest-63-2026-09-12/run-143205-seed1489549101-v0.8.2-764-g28fe845/).
It shows horizontal boards stacked along vertical barrier bands. Inspect the authored end
view and the barrier drawing callers, plus how an alley's axis chooses the barrier across it.
Use the correct upright/end-view artwork and place it along the actual barrier axis.

## Tree beds belong to the ground

> the bed of the tree should be a tile not an object. it currently draws on top of the stroller

The supplied screenshot is `asked/005-attempt3-asked.png` in the same preserved run above.
Render the tree bed as ground beneath the stroller and other upright actors; keep the tree
itself in the existing upright drawing and collision system. Preserve the bed's position,
size and tree placement.
