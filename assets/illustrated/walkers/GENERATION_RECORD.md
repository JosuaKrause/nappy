# Illustrated walker source record

The three runtime PNGs are built-in image generation outputs with genuine RGBA alpha. The runtime maps
the authored N, NE, E, SE, S, SW, W and NW views explicitly; it does not mirror a facing.

`../source/lower-denim-sneakers-v1.png` and its import sidecar preserve an unused source draft for
the prompt below, kept out of this folder because nothing here ships unbound. Its joined
trouser-and-shoe silhouettes are not the separate articulated cutouts registered by
`MANIFEST.json`. It has no runtime binding and is not an approved replacement for
`legs-denim-sneakers-v1.png`. The source is 2032 × 774 pixels with an alpha channel, and its eight
cells read **front view first**, rotating through a profile to the back view in cell 5, rather than
the N-first order the prompt asks for; registering it by the prompt order would mislabel every
facing.

## Prompts

`upper-mustard-bob-v1.png`: “Use case: stylized-concept. Asset type: game sprite sheet, modular
generic pedestrian torso/head/arms part. Primary request: a production-ready transparent PNG sprite
sheet ... short dark bob haircut, mustard rain jacket, muted teal shirt, small shoulder bag ...
exactly eight ... N, NE, E, SE, S, SW, W, NW ... richly inked and painted urban illustration ...
genuine transparent alpha ... no checkerboard, background, text, labels, watermark, extra views or
mirrored substitutions.”

`upper-rust-curls-v1.png`: same complete structured prompt, with curly auburn hair, brick-red knit
sweater, cream scarf and green satchel as the upper-body variation.

`lower-denim-sneakers-v1.png`: “Use case: stylized-concept. Asset type: game sprite sheet, modular
generic pedestrian lower-body legs and shoes part. Primary request: articulated lower-body parts ...
dark trousers and practical sneakers ... exactly eight ... N, NE, E, SE, S, SW, W, NW ... visible
hip and knee attachment areas and grounded shoe soles ... genuine transparent alpha ... no checkerboard,
background, text, labels, watermark, extra views or mirrored substitutions.”

`legs-denim-sneakers-v1.png`: “Use case: stylized-concept. Asset type: transparent game sprite sheet
for articulated modular pedestrian legs. Primary request: exactly eight authored N, NE, E, SE, S,
SW, W, NW views, each cell containing separately spaced dark-trouser upper thighs, lower shins and
practical sneaker cutouts with hip, knee and sole attachment areas. Richly inked and painted
illustrated apartment-street art; genuine transparent alpha; no checkerboard, background, text,
watermark, extra views or mirrored substitutions.”

## Alpha validation

The generator output reports `PNG ... 8-bit/color RGBA`. The transparent margins were inspected in
the generated previews and the imported textures retain RGBA format. The asset contract rejects a
baked checkerboard; no checkerboard pixels are present in the margins.

`MANIFEST.json` records each upper-body silhouette's own alpha-supported bounding box rather than
dividing the sheet into equal columns. Its crop-local hem is measured from the painted lower jacket
edge. Each thigh, shin and shoe has an independent crop and crop-local proximal/distal axis. The
shoe axis ends at the painted sole; its proximal point is the ankle where the shin attaches.

The leg sheet has only one complete limb set in each E and W profile, so both overlapping legs
explicitly reuse that same facing-specific source. The diagonal limbs remain separate registrations,
but their painted edges overlap in the source and their tight crops include shared edge pixels.
Those source limitations need new authored cutouts for fully independent profile and diagonal legs.
The mustard SW upper silhouette also reads closer to SE than the rust SW view; it stays registered as
the authored SW image instead of being relabelled or mirrored to disguise the source-facing issue.
