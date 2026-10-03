# Connected roof vent networks and rejected obstruction transfers

[Bouncy-squirrel, the roof review](../../playtests/2026-10-03-bouncy-squirrel.md)
accepts the roof objects' general appearance, rejects the water-main and fallen-tree
PNG replacements as worse than their SVGs, and requests proper vent networks instead
of a single repeated L. Correct this in the existing roof PR.

Keep the accepted roof family's style, attached supports, cardinal perspective,
hidden west/north openings and tall roof-foot placement. Build connected networks
that vary with available roof space while keeping compact equipment and collision
footprints intact. Show an early in-engine still with actual game surroundings,
including several useful network layouts; label manual arrangements honestly.

**Proposed, not asked for:** remove the rejected obstruction transfers from active
asset paths so the existing SVGs render again, preserving the removed art and its
provenance in the rejected archive. This does not claim a successful PNG conversion
or cancel the broader catalogue request. Prefer existing accepted roof components
where they can form convincing networks; any new component follows the roof family's
explicit PNG-first permission and visual review requirements.

Integrate current main's nearby scenery loading with the PR's separately parented
roof objects: unloaded buildings must release those pictures, and reentry must
restore correct placement and rotor phase without orphan objects. Verify the actual
combined lifecycle, asset selection and roof footprints with focused checks. The
independent review identifies this semantic conflict even though Git merges cleanly.
