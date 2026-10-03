# Playtest silky-bunny — Standalone roof equipment scale

2026-10-03.

PR #441 shows the supported connected-network still at native scale, with five
generated roof layouts and one vertical-only support fixture. The assistant reports
that the implementation is pushed and awaiting final independent review and CI.
The player identifies the next correction to the standalone equipment:

> hmm, the scale of the standalone roof objects is too large. if you take the roof access room and air vents as scale reference the other pipes and vents and ventilators are too big

This feedback covers the appearance review in `docs/review/2026-09-10-M109-3.md`.

The assistant proposes keeping the roof access room and air ducts as scale references
while shrinking the standalone pipes, vents and fans. The player corrects the room
reference and identifies an object that should retain its size:

> roof access room actually needs to be bigger compare its door to a regular door

> water tank looks fine

The assistant confirms a larger access room matched to a regular building door,
an unchanged water tank, and smaller standalone pipes, vents and fans. The player
then identifies the skylight exception and a clipped edge:

> the sky lights are okay but the long version is cut off on the left side
