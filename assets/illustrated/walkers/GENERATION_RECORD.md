# Illustrated walker source record

The three PNGs are built-in image generation outputs with genuine RGBA alpha. No symmetry is
claimed: every N, NE, E, SE, S, SW, W and NW view is authored and retained in that order.

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
baked checkerboard; no checkerboard pixels are present in the margins. `MANIFEST.json` records the
exact dimensions and cell rule used by the runtime.
