# Illustrated street review assets

Generated with the built-in image generation tool on 2026-09-06. These are review-gate
artifacts, not a claim that the live renderer uses them.

## v2 reference-alignment pass

The v2 layers are generated against `docs/evidence/graphics-reference-urban-01.jpeg` and
`graphics-reference-urban-02.jpeg` for their clean expressive ink contour, flatter gouache
material blocks, brick/plaster apartment frontage, storefront density and street-furniture
detail. `graphics-reference-cardinal.jpeg` remains the composition and perspective floor only;
the approved cardinal composition, shortened north depth, roof overlay and stable dotted reveal
are unchanged. `graphics-reference-mother.jpeg` is retained as the broader illustrated-city
style reference and is not copied into any street layer.

The runtime review gate consumes only the `*-v2.png` files. The v1 files remain in place as
historical source material.

### apartment-facade-v2.png

Prompt: “Create a transparent-background PNG asset for a 2D cardinal apartment-street game
review. Wide continuous four-storey urban apartment frontage, straight-on facade with a slight
top-down depth cheat: warm terracotta brick and cream plaster sections, thick clean expressive
dark ink contour, flatter hand-painted gouache fills with subtle paper texture. Dense readable
city detail: repeated windows with varied warm/cool interiors, fire escapes, balconies with
plants, gutters, utility boxes, and a ground-floor row of distinct storefronts with small awnings
and signage (simple abstract sign shapes, no gibberish text). The silhouette must be one
continuous building frontage with transparent pixels outside and along the shortened upper north
depth; no sky, no people, no cars, no road, no black background, no glow, no photorealism.”

### roof-depth-overlay-v2.png

Prompt: “Create a transparent-background PNG layer for a 2D cardinal illustrated apartment-street
game review: a broad shallow rooftop depth overlay seen from slightly above, dark slate roof planes
with clean expressive dark ink outlines, warm muted gouache shading, brick parapets, gutters,
vents, skylight, small HVAC units, water tank and fire-escape access. The lower/north-facing edge
should be a clean architectural silhouette designed for a stable dotted reveal shader; transparent
pixels outside the roof. Flat illustrated graphic matching urban comic concept art, no black
background, no glow, no photorealism.”

### street-props-v2.png

Prompt: “Create a transparent-background PNG sheet of dense, separately readable urban street
furniture for a 2D cardinal apartment-street game review. Arrange with generous spacing: ornate
cast-iron street lamp, green litter bin, blue newspaper box, concrete planter with leafy shrub,
wooden slat bench, black bicycle rack, utility box, fire hydrant and two loose newspapers. Use
clean expressive dark ink contour and flatter hand-painted gouache fills matching illustrated
urban comic concept art, warm brick-city palette, small material accents and shadows contained
within each object. Real transparent pixels around and between all objects; no black background,
glow, photorealism, people, cars, text or UI.”

### street-ground-v2.png

Prompt: “Create an opaque PNG ground plate for a 2D cardinal apartment-street game review, viewed
from a gently top-down cardinal camera. Believable urban sidewalk and road surface arranged as
broad horizontal depth bands: warm pale concrete sidewalk slabs with irregular seams and small
cracks, a darker asphalt carriageway with subtle lane markings and patched texture, a narrow
red-brown brick curb strip. Clean expressive ink contour accents and flatter hand-painted gouache
fills matching illustrated urban comic concept art. Full canvas covered edge to edge; no buildings,
people, vehicles, props, UI or text.”

Alpha validation (2026-09-06): `apartment-facade-v2.png`, `roof-depth-overlay-v2.png` and
`street-props-v2.png` are 8-bit RGBA PNGs with transparent surround/inter-object pixels;
`street-ground-v2.png` is an opaque 8-bit RGB PNG by design. Validation used `file` plus visual
inspection on the generated files; no checkerboard was baked into the transparent layers.

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
