# curly-stork — A planned body's pieces are laid out once · 2026-11-20

**What was asked.** The entry curly-stork, a finding of the design of minty-quail's row 3a: three loops laid out a
planned body's pieces from its geometry, each its own way (`WalkGround.solids_of()`, `EventSpawner.obstructed_footprint()`,
`RouteRigPlanner._planned_body_tiles()`); a fact derived in more than one place is the smell **designing-classes** names
(inbox #1156 in gray-dolphin). Designed by Opus (kept in the orchestrator's design folder), built by a Sonnet agent as
#1600.

**What was measured first.** The three loops are one reading: on 18 day cities over 14 days and 10 escape cities, every
body the record keeps has the same pieces (center, shape, axis) in all three. What differs is what each caller asks
around the layout (only the walk's ground counts the checkpoint's hut, gate and post and the escape's crater; each
does its own thing with a piece), and those stay with their callers.

**What was built.** `StandingPiece` (`src/events/standing_piece.gd`, model) is one solid piece of a body where it stands
(`center()`, `ground_shape()`, `axis()`, `tiles()`), built by `BodyStance.pieces_at()` for a body built at a point and
`pieces_laid_out()` for one whose stance is decided; the walk's ground, the record of standing bodies, the route rig and
the live body's physics footprint ask them. The three loops, the rig's `_planned_parts()`, `EventPlan.body_pieces()` and
`EventDef.parts()` (folded into `body_pieces()`) go; `BodyStance.body_axis()` is private. A new probe
(`tests/probes/curly_stork_piece_layout.gd`) prints the three answers' digest per city and day, identical on main and the
branch, as is `probes/escape_density.gd`; a new suite holds `BodyStance`. Nothing a player sees changes.

**Open to overturn:** the design's forks, built on the designer's picks: the value's name and shape (F1); the live body's
own layouts left to minty-quail's row 4b (F2); a plan's pieces built at where it was placed (F3); the physics footprint
laid out through `pieces_laid_out()` (F4); the door filter and the crater staying with their caller (F5). The builder's,
forced by `tools/check_test_only_members.py`: `EventDef.parts()` folded into `body_pieces()`, and `body_axis()` private.

**Not fixed here (F6):** `BodyStance.stands_at()` moves an already-stood point half a tile for rows stood on their band's
middle; behaviour is kept exactly, and the entry olive-lynx (a body stood twice moves half a tile) holds it.
