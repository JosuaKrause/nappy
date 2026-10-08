# spotted-osprey — Pelican diagonal anatomy follows the bars and pedals · 2026-10-07

[Sandy-marmot](../playtests/2026-10-07-sandy-marmot.md) records the request: "also the north
eastern pelican has his arms on the back", "can you fix that?", "and the south east one has
only one eye", and "and norht east and south east's legs are weird". This corrects the
SVG-only rider approved in [feathery-bison](2026-10-03-feathery-bison.md).

**Approved repair.** [Jolly-puffin](../playtests/2026-10-07-jolly-puffin.md) records the final
depth instruction and the player's verdict, "605 looks good now", on candidate 4. All six
northeast, southeast and east A/B SVGs put the far leg behind the complete bicycle, wheels
included, and the near leg in front of every bicycle part. The northeast leg identities keep
their own hip attachments through the pedal phase change. Both northeast wing roots are hidden
behind the torso and the reaches emerge toward the bars; the southeast second eye is retained.
Western views use the existing mirrors. The queue and the eye review are answered by this
approval. Bicycle geometry, native canvases, bottom anchors, bindings and gameplay stay intact.

**Final verification.** The [evidence recipe](../evidence/pelican-diagonals-2026-10-07/README.md)
retains current native and enlarged sheets and a six-direction production `EventInstance`
fixture at the normal 2× camera scale. Its 36 frames span 2.925106 seconds; every view shows
both pedal phases, with 27 transitions. It establishes rendering and phase transitions on
controlled routes, not city placement or route frequency. XML, preserved bicycle geometry,
complete leg/bicycle ordering, source rendering, import/boot and lint pass. Labeler checks pass;
the full Python gate's only failures were three sandbox-induced temporary-file assertions,
reproduced with Apple's git launcher; the focused disk-headroom suite passes outside the sandbox.
No gameplay tests or tooling changes are added for this art correction.

**First attempt.** The northeast near wing attached at the side/chest and reached toward the bars;
the far wing is painted behind the torso. The southeast head has a far eye above the bill
root. Both diagonal views have coherent forward-bending knee chains and webbed feet meeting
the pedals through both A/B frames. Western diagonals use the existing mirrors. Only the
four `pelican_cyclist_{back_diagonal,front_diagonal}{,_b}.svg` source pictures change; the
bicycle paths, 40×44 canvases, bottom-center (20,44) anchors, bindings and gameplay stay intact.

**First drawing choices.** The far eye is smaller, the far shins use the side
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

**First attempt rejected, 2026-10-07.** [Plaid-kestrel](../playtests/2026-10-07-plaid-kestrel.md)
says the northeast arms still sit on the back and both legs are in front of the bicycle,
including the east-facing view. The technical checks above did not establish the requested
anatomy. The correction stays in this PR and returns to the spotted-osprey queue item with
east/west side views included. The new attempt must distinguish the legs' depth relative to
the frame and keep the northeast wing roots off the visible back.

**Later corrections.** Candidate 2 hid the northeast wing roots and separated the legs around
the bicycle tubes. [Dappled-dolphin](../playtests/2026-10-07-dappled-dolphin.md) identified that
the northeast leg identities swapped between A/B and that the east near leg still missed the
vertical pedal bar. Candidate 3 aligned the hip attachments and overlapped that bar. Jolly-puffin
then required the wheels, as well as every frame part, between the legs in all three directions.
Candidate 4 changed only that painter order and received the approval above. Earlier useful
attempts remain in the evidence folder as historical comparisons, not proof of the final repair.
