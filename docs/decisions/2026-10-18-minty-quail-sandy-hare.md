# minty-quail — A live body's pieces are laid out once (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus as
ten pull requests; this is the second, built beside the first as #1607 by a Sonnet agent: the live body's own layouts
ask the one layout a planned body's pieces already take (`BodyStance.pieces_laid_out()`, the record curly-stork,
whose design left this half to row 4b), so the body she sees and the record of standing bodies cannot disagree.

**What was built.** `EventBody.standing_pieces(at, heading)` and `EventInstance.standing_pieces()` answer the live
body's pieces where they stand, through `BodyStance.pieces_laid_out()`; `solid_part_centres()` and
`solid_part_shapes()` go from both. The base look lays its shadow's pieces out the same way, not with offset
arithmetic of its own, and the route rig's stopgap `_live_pieces()` goes, its callers asking the live event. The
body's method takes the heading as well as the point, since the axis a body lies along depends on it (the design's
sketch named the point alone).

**Measured.** The looks' `LK` lines (`tests/probes/look_fingerprint.gd`) and curly-stork's sweep
(`tests/probes/curly_stork_piece_layout.gd`) print the same on main and the branch. The shadow is drawn straight onto the canvas, which no probe records (the
record minty-quail-tall-toad), so that it lands where it did rests on reading the code: the same offsets from the same
flag, in the same order. Nothing a player sees changes.
