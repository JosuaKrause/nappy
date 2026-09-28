# Comic dog preview prompts

The built-in image generator receives three local references per call. Image 1 is the rendered
SVG source grid and supplies identity, projection, pose, stride, order, and functional placement.
Image 2 is `docs/style-references/graphics-reference-urban-01.jpeg` and supplies expressive comic
contours, material planes, ink, and deliberate internal shadows only. Image 3 is
`docs/style-references/graphics-reference-cardinal.jpeg` and supplies the simplified game-scale
comic language only. The two style images do not supply dog identity, pose, layout, interface,
debug text, scenery, or cast shadows.

## Walked dog

```text
Use case: stylized-concept
Asset type: first visual-review contact sheet for ten small top-down/upright game dog sprites
Primary request: Redraw the same walked pet dog from Image 1 as one coherent comic sprite family. Produce exactly ten isolated full-body poses in a strict five-column by two-row grid. Columns, left to right: east-facing side, front, southeast/front diagonal, northeast/back diagonal, back. Top row is stride A; bottom row is stride B. Keep each column's body, head, collar, proportions, scale, and placement fixed between rows; change only continuous leg articulation for the second stride.
Input images: Image 1 is the authoritative source grid for this dog's identity, projections, poses, grid order, stride pairing, and bottom-center ground registration. Image 2 supplies expressive comic contours, material planes, ink, and deliberate internal shadow shapes only. Image 3 supplies simplified cardinal game-scale comic rendering only. Images 2 and 3 do not supply subject identity, pose, scenery, UI, labels, or cast shadows.
Scene/backdrop: genuinely transparent background in every cell; no floor, scenery, labels, borders, checkerboard, or contact shadow
Subject: one friendly compact tan pet dog in every cell, with cream chest and muzzle, soft hanging dark ears, tail carried up, and the same clearly blue collar in every view; preserve the source's distinct side, front, front-diagonal, back-diagonal, and back projections
Style/medium: authored 2D comic game sprite; confident slightly irregular dark ink contour, shaped color planes and restrained painted interior shadow, matching the two style references without tracing the source's primitive geometry
Composition/framing: exact 5x2 evenly spaced grid; one centered full dog per cell; every dog fully visible with generous transparent separation; common ground baseline within each row; no overlap between cells
Color palette: muted warm tan and cream, dark brown ears and outline, saturated readable blue collar
Constraints: preserve all ten source poses and pairings; preserve consistent body length, head size, ear shape, collar thickness and apparent scale across the family; legs connect continuously to shoulders and hips; no halo; no cast shadow; no leash; no accessories beyond the blue collar; no text; no watermark; true alpha transparency
Avoid: primitive stacked shapes, photoreal fur, 3D rendering, extra poses, duplicate cells, missing legs, disconnected paws, identity drift, background texture, interface elements
```

## Charging dog

```text
Use case: stylized-concept
Asset type: first visual-review contact sheet for ten small top-down/upright game dog sprites
Primary request: Redraw the same charging dog from Image 1 as one coherent comic sprite family. Produce exactly ten isolated full-body poses in a strict five-column by two-row grid. Columns, left to right: east-facing side, front, southeast/front diagonal, northeast/back diagonal, back. Top row is gallop stride A; bottom row is gathered stride B. Keep each column's body, head, coat markings, proportions, scale, and placement fixed between rows; change only continuous leg articulation for the second stride.
Input images: Image 1 is the authoritative source grid for this dog's identity, projections, poses, grid order, stride pairing, and bottom-center ground registration. Image 2 supplies expressive comic contours, material planes, ink, and deliberate internal shadow shapes only. Image 3 supplies simplified cardinal game-scale comic rendering only. Images 2 and 3 do not supply subject identity, pose, scenery, UI, labels, or cast shadows.
Scene/backdrop: genuinely transparent background in every cell; no floor, scenery, labels, borders, checkerboard, or contact shadow
Subject: one heavy aggressive black-and-tan charging dog in every cell, with ears pinned back, raised shoulder hackles, head low and level with the back, tail straight behind, tan points, and an open red jaw with small white teeth where the source shows it; preserve the source's full-stretch side gallop and distinct front, front-diagonal, back-diagonal, and back projections
Style/medium: authored 2D comic game sprite; confident slightly irregular dark ink contour, shaped color planes and restrained painted interior shadow, matching the walked dog's drawing language and the two style references without tracing the source's primitive geometry
Composition/framing: exact 5x2 evenly spaced grid; one centered full dog per cell; every dog fully visible with generous transparent separation; common ground baseline within each row; no overlap between cells
Color palette: very dark warm brown-black coat, muted tan points, dark outline, restrained red mouth and white teeth; keep the charging dog clearly distinct from the walked tan pet
Constraints: preserve all ten source poses and pairings; preserve consistent body length, head size, hackle ridge, coat markings and apparent scale across the family; legs connect continuously to shoulders and hips; nearest paw meets the ground baseline; no halo; no cast shadow; no leash or collar; no text; no watermark; true alpha transparency
Avoid: primitive stacked shapes, photoreal fur, 3D rendering, extra poses, duplicate cells, missing legs, disconnected paws, identity drift, friendly expression, background texture, interface elements
```
