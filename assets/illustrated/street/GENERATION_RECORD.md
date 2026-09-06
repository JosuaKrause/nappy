# Illustrated street review assets

Generated with the built-in image generation tool on 2026-09-06. These are review-gate
artifacts, not a claim that the live renderer uses them.

## street-ground.png

Prompt: “A seamless hand-painted illustrated asphalt-and-sidewalk street ground tile for a
cardinal top-down urban game camera, broad perspective-friendly tonal shapes, fine ink contour
accents, warm gray pavement, two pale sidewalk bands and subtle seams; no buildings or objects.”
Opaque RGB output; alpha is not required for a ground plate.

## apartment-facade.png

Prompt: “A wide continuous four-storey apartment building front facade for a cardinal top-down
urban game camera, attached urban block, repeated window bays with warm lit windows, balconies,
shared entry canopy, painted brick and cream plaster, ink contours and hand-painted gouache
texture. Include a slightly shortened north-facing upper depth so the street behind remains visible.”
RGBA output with transparent surround.

## roof-depth-overlay.png

Prompt: “Illustrated urban apartment roof depth cutaway, broad dark slate roof plane with brick
parapet, gutters, vents and warm inked edge, designed as a separate transparent PNG overlay that
can sit in front of a street and use a dotted halftone fade along its north-facing lower edge.”
RGBA output; the runtime adds a stable checker-dither reveal at the lower edge.

## street-props.png

Prompt: “A small collection of separately readable hand-painted urban street props arranged with
generous spacing on a transparent background: cast-iron lamp post, green litter bin, newspaper
box, planter with leafy shrub, wooden bench, bicycle rack, and a couple of loose papers.”
RGBA output with transparent surround.
