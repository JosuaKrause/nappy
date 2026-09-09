# Pram registration generation record

These files preserve the opaque generation outputs. PLAYTEST-44 approves their layered drawings
for scripted transparency extraction; this specific approval permits using them as extraction
inputs despite the archive location. They are not runtime assets, and their layer registration
still needs work. The current request and next work remain in the repair brief.

## Inputs and method

Built-in image generation; no CLI/API fallback. The first input,
`docs/evidence/graphics-reference-mother.jpeg`, defines stroller identity and illustration style.
The second, `docs/evidence/graphics-reference-urban-01.jpeg`, supplies illustration treatment.
The extraction attempt uses only the first generated output as its edit target.

## Inspection

Both outputs are 1448 × 1086 RGB PNGs. `sips -g hasAlpha` reports `no` on both.
The gray/white checker pattern is painted background. Eight columns and four component rows
are visible, but components are packed independently instead of sharing the requested chassis
coordinate box. The chassis and seat both contain a storage basket. These outputs fail alpha,
layer isolation and common-registration requirements; no runtime manifest consumes them.
The second output also changes painted edges despite the preservation request.

## Exact first prompt

Use case: illustration-story. Asset type: production modular PNG sprite atlas for a 2D cardinal-view walking game. Generate a NEW replacement dark stroller/pram asset, using reference 1 for the exact dark stroller, warm bundled baby, fine dark ink contours and muted painted colors, reference 2 for illustration treatment only. No environment, mother, words, labels or UI. Real transparent alpha background, absolutely no white or checkerboard pixels painted behind the objects, no ground shadows. Canvas 2048x1536. EXACTLY EIGHT equal-width columns (256 pixels), FOUR equal-height rows (384 pixels). Columns depict travel heading in clockwise order N (away from viewer, handle toward viewer), NE (away right), E (right profile), SE (toward right), S (toward viewer), SW (toward left), W (left profile), NW (away left). All eight views individually drawn; no skipped column or additional ninth view. Slight overhead cardinal game camera, consistent camera height in every view. Every cell reserves an IDENTICAL full-pram coordinate box; components retain their place within that box when split into layers. Align all four rows in each column so overlaying cells recreates one complete pram without translation. Ground contact at cell y=350, chassis center x=128, entire assembled silhouette fits x=20..236 y=65..350. Row 1: ONLY metal chassis, push handle, wheel axles and four wheels, with open transparent spaces between spokes and frame bars. Row 2: ONLY upholstered dark seat/bassinet and lower storage basket, positioned where they attach on the row-1 chassis; NO wheels, frame, handle, canopy or baby. Row 3: ONLY dark fabric folding canopy, at its assembled position near the upper back of the seat; no seat, wheels, baby or handle. Row 4: ONLY sleeping baby in warm ochre knitted hat and cream blanket, at its seated/reclined position in the seat, no pram or canopy. Keep occluded portions natural per direction (back view baby mostly hidden later by seat); layers need clean painting underneath overlap. This is a registered paper-doll atlas, not an exploded diagram: NEVER center each isolated component in its cell vertically. Uniform scale across all columns, generous transparent margins, detailed illustrative ink linework and cloth folds, legible wheels and joints at small gameplay scale. Do not reproduce reference captions or controls.

## Exact extraction prompt

Use case: background-extraction. Edit target: the supplied pram sprite atlas. Remove the entire gray and white checkerboard background, including every opening inside wheels, spokes, handles and gaps between frame bars. Return an actual RGBA PNG with alpha=0 in all background pixels. DO NOT draw a replacement transparency checkerboard or any new backdrop. Preserve exact canvas dimensions, all 8 columns, all 4 rows, all painted objects, positions, colors, dark outlines, fine spokes, pale baby blankets and highlights. Only change background pixels and antialiased boundary contamination. This is a game sprite asset; opaque checkerboard pixels make it unusable. Genuine transparency is the only requested edit.
