# Mother modular source v2

These are generated source PNGs for the mother and pram. They are not wired to the runtime.
The two part sheets have real RGBA transparency; the review contact sheet intentionally keeps a
warm neutral review background and ground baselines so foot and wheel contact can be judged.

## Registration

Both part sheets use clockwise direction order `N, NE, E, SE, S, SW, W, NW` from left to right.
The mother sheet is `1280×960` with 8 columns × 5 rows of `160×192` cells. Rows are, top to
bottom: `head_hair`, `torso_clothing`, `arms_hands`, `legs`, `shoes`. The logical ground line is
`y=184` in each cell. Mother attachment pivots are `(80,28)` head, `(80,66)` torso, `(52,77)` and
`(108,77)` shoulders, `(80,116)` hips, and foot anchors at the shoe soles on `y=184`.

The pram sheet is `1280×384` with 8 columns × 3 rows of `160×128` cells. Rows are, top to bottom:
`pram_body_basket`, `canopy_baby`, `wheels_frame`. Its logical ground line is `y=118`; body pivot
is `(80,74)`, canopy/baby attachment is `(80,34)`, and wheel centers lie on `y=112`.

Per-direction draw order for the assembled mother is `legs → torso_clothing → head_hair →
arms_hands → shoes`, with `shoes` last to keep sole contact legible. Per-direction pram order is
`wheels_frame → pram_body_basket → canopy_baby`; the pram is composited beside the mother and the
handle overlays the mother's hands where the views meet. These orders are constant for all eight
directions; the authored views are individually drawn rather than mirrored. No genuine symmetry is
claimed. The `N` and `S` views are separate front/back drawings, and each three-quarter view has
its own bun, scarf, coat-fold, hand, wheel and canopy placement.

The contact sheet is a review image only. Its two rows read `N, NE, E, SE / S, SW, W, NW`, and its
baseline shows that shoes and pram wheels sit on the same gameplay ground plane.

