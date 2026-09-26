## Sideways stair flights and two building-side stairwells — 2026-09-10

PLAYTEST-53 rejects the front-to-back stair projections in the prepared SVG kit and requests
sideways zigzag flights. The player supplies two generated JPEGs, an interior switchback and an
exterior fire escape, and explicitly asks to preserve them and adjust the actual images. They
were first committed as the original bytes under an evidence folder named for the generator; on
the player's instruction the same day (playtest 54, *"properly ingest the reference images with
proper names instead of who made it"*) they went through `tools/reference.sh` like every other
reference and live as `docs/reference/stairwell-switchback-interior-01.jpg` and
`fire-escape-switchback-exterior-01.jpg`.
The references govern flight direction and landings, not the game's camera, characters or signs.

The building's two staircases mean exactly one stairwell on the left side and one on the right;
each stairwell contains its own alternating lateral flights. M102, the finale, owns placement,
floor transitions and traversal. M106, roofs, fronts and street trees, owns the facade overlays.
The human-rejected `stair_down.svg` and both `fire_escape_*.svg` sources from `290efd4` are
preserved in `docs/evidence/archive/rejected-graphics/stairs-front-to-back-2026-09-10/`, without
import sidecars. Original recommended review sheets remain available as the rejection record.

The three replacement SVGs show opposed lateral flights with an intermediate landing. The
interior module uses a transparent 64×64 canvas anchored at (32,64), rather than treating the
picture as a floor tile or transition trigger. Its upper/middle/lower landing points are
(8,10), (56,34) and (8,58). The left stairwell mirrors the module; the right uses it unmirrored,
so the upper/lower landings face the connecting hallway. Both 48×64 facade variants retain
transparent tread and rail gaps. These projection and registration choices are reviewable
implementation details; floor traversal and facade placement remain queued with their owners.

Native/3× Godot source renders, the two-stairwell hallway assembly and facade overlays are
preserved in `docs/evidence/svg-sideways-stairs-2026-09-10/`. Each revised graphic has its own
commit. Visual review confirms lateral switchbacks and the opposite hallway-facing placements.
