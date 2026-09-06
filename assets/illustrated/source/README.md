# Illustrated mother source draft

This directory contains a handoff-quality source draft for the illustrated character direction. It
is not production-ready runtime art and is not wired into the game.

## `mother-turnaround-v1.png`

Generated with the built-in `image_gen` tool on 2026-09-06, using the three supplied reference
images as style and camera references. The saved file is 1402×1122 PNG, RGB, with no alpha channel
(`sips -g hasAlpha` reports `no`). The checkerboard visible around the figures is baked image data,
not transparency. Do not use this file as a cutout until the background is removed or a genuinely
transparent replacement is generated.

The sheet visibly contains a 4×2 directional arrangement, but its observed reading order is
`S, SE, E, NE / N, NW, W, SW` rather than the requested N-first order. It has a consistent green
coat, warm scarf, high brown bun, blue jeans and dark shoes, with no stroller, UI, labels or
environment. The views are cardinal-game character views rather than an isometric diamond, but cell
bounds are implicit rather than machine-registered and the generated canvas is not an exact 2:1
sheet. The front/three-quarter/back silhouettes are useful for style and proportion review only;
direction remapping and registration remain open.

The tool's first correction attempt produced an RGBA PNG but replaced the checkerboard with an
opaque dark gradient; it was rejected and is not copied into this checkout. A separate modular
parts sheet was not generated because the handoff direction arrived after the final turnaround
attempt; it remains open work.

## Exact generation prompt

```text
Use case: stylized-concept
Asset type: transparent game character source sheet
Input images: Image 1 is the mother character/style reference; Image 2 is fine-ink illustrated urban style; Image 3 is cardinal-game art direction. Use them only for style and character design. Do not include any UI or environment.
Generate an original eight-direction turnaround source sheet of one adult mother for a 2D game. Green coat, warm patterned scarf, high brown hair bun, blue jeans, dark shoes. Upright neutral stance, both arms naturally forward to later grip a pram handle, no pram and no props.
Layout: exactly 4 columns by 2 rows, equal invisible cells; top row N, NE, E, SE; bottom row S, SW, W, NW. Full body in every cell, same scale and anatomy, feet visible, generous empty margin.
View: non-diagonal cardinal-game orthographic sprite presentation, not isometric, not a diamond grid, not a perspective turntable. Fine dark ink contours with softly painted fills and subtle paper/gouache texture.
ABSOLUTE OUTPUT REQUIREMENT: a true transparent PNG cutout. Outside every figure there must be zero background pixels and alpha 0. Do not draw or render a checkerboard, white canvas, gray canvas, black canvas, gradient, floor, shadow, halo, or studio backdrop. Transparent empty space must remain empty. No cell dividers, no labels, no arrows, no text, no watermark, no stroller, no extra characters. This is an unapproved modular rigging source draft.
```

## Remaining work for Luna

- Generate or extract a genuine RGBA turnaround with alpha 0 outside every figure and registered
  equal cells.
- Generate a matching separable-parts source sheet for head/hair, coat/torso, arms, legs and shoes;
  keep parts registered and do not draw runtime primitives into it.
- Validate the replacement visually and with an alpha-aware image tool before treating either sheet
  as a source for modular animation.
