priority: now

# sandy-badger — The mouse's ground stops branching on its row id · filed 2026-11-19

**The finding.** The design of row 3a of minty-quail's `event-interface.md` found that `RuledLocationGround`
(`src/events/ruled_location_ground.gd`) branches on the mouse's row id (`_MOUSE_ID`, read at two places). A fix
lands in the shared mechanism, not in a branch keyed on one row's id or picture (**designing-classes**, a proposal
of plush-kestrel's, not the player's words). minty-quail's list is frozen, so this is an entry of its own
(inbox #1268 in olive-ferret).

**Item:** `mouse-ground-by-its-row.md`.

**Proposed, not asked for:** the band `now`, and the fix itself, since the rule it rests on is a proposal.
