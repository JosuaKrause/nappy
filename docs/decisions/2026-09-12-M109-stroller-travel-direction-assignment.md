## M109 — Stroller travel-direction assignment — 2026-09-12

PLAYTEST-65 overturns the canopy correction after identifying the direction mismatch: the
original side texture was correct, while the other six directions belonged to their opposites.
Asked for a side-canopy flip · overturned by the player on 2026-09-12 to restoration of the side
image and N ↔ S, NE ↔ SW, NW ↔ SE assignment. The side image is restored byte-for-byte.
The end-view files exchange without pixel changes. Diagonal files exchange and mirror horizontally,
because the runtime stores east-authored slots and derives west through its own mirror.
Mother artwork, draw transforms, dimensions, ground anchors and accepted paving stay unchanged.

The final visual contract is recorded in the illustrated-PNG skill, GRAPHICS, VISUALS and the
new recipe: N/NE/NW show the baby and canopy opening; S/SE/SW show the outside of the hood;
E/W retain the original side image. Direction means travel, and upstream front/back filenames
are not a reason to invert this assignment. The player explicitly asks for notes that prevent a
future session from repeating the swap and undoing the correction. The deterministic recipe reads
frozen originals only, validates their hashes and cannot toggle installed runtime files.

The canopy experiment and script are committed before deletion as requested; they remain
recoverable from commit f47af18. Their working-tree directory and live recipe links are removed
in this following correction commit. `docs/evidence/stroller-view-assignment-2026-09-12/` keeps
the useful final mapping, immutable PNG/SVG inputs and labeled eight-direction comparison.
Its frozen rebuild is byte-identical. Static view review establishes assignment, while live-turn
appearance remains a human-review item.
The root import/boot check, focused visuals, stroller/gait, orientation and presentation-mode
suites, lint and whitespace checks pass. The restored side texture matches its source bytes,
and the accepted paving has no diff during this correction.
