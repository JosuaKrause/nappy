# spotted-osprey — Pelican diagonal anatomy follows the bars and pedals · 2026-10-07

[Sandy-marmot](../playtests/2026-10-07-sandy-marmot.md) records the request: "also the north
eastern pelican has his arms on the back", "can you fix that?", "and the south east one has
only one eye", and "and norht east and south east's legs are weird". This corrects the
SVG-only rider approved in [feathery-bison](2026-10-03-feathery-bison.md).

**Built.** The northeast near wing attaches at the side/chest and reaches toward the bars;
the far wing is painted behind the torso. The southeast head has a far eye above the bill
root. Both diagonal views have coherent forward-bending knee chains and webbed feet meeting
the pedals through both A/B frames. Western diagonals use the existing mirrors. Only the
four `pelican_cyclist_{back_diagonal,front_diagonal}{,_b}.svg` source pictures change; the
bicycle paths, 40×44 canvases, bottom-center (20,44) anchors, bindings and gameplay stay intact.

**Drawing choices, open to correction.** The far eye is smaller, the far shins use the side
view's darker orange, and the far northeast wing is partly hidden by the body. These are the
drawing proposal, not a new approval of the art by the player.

**Verification and evidence.** XML validity, comparison of the preserved canvas/wheel/frame
geometry, Godot SVG rendering at native and six-times scale, import/boot and lint pass. The
[comparison and runtime evidence](../evidence/pelican-diagonals-2026-10-07/README.md) retains
the before/after sheets, renderer and a controlled production-rider fixture: 36 frames over
2.923 seconds with both phases in NE, SE, NW and SW at the normal 2× camera scale. It uses real
`EventInstance` movement, phase selection and drawing on fixed diagonal routes, not a played
city; it proves frame selection and transitions, not natural route frequency. The provenance
records the premature first capture and clean rerun. Nine evidence files occupy 265,652 bytes.
No gameplay tests are added for the artwork-only correction.

The queue item is completed in this PR. The remaining visual judgment is in
[the diagonal-pose review](../review/2026-10-07-spotted-osprey.md).
