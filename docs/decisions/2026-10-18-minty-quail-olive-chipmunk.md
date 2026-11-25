# minty-quail — What the events read of four world classes is asked (row 4b) · 2026-11-22

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), its eleventh pull
request, named by the design's amendment and by `field-reads.md`: the fields the events read of four world classes,
`MoveProposal` (a move a body proposes), `GroundShape` (the shape of a thing on the ground), `Stroller` (her stroller)
and `VisibleView` (her view), go private, asked through methods. Built as #1631 by Sonnet agents one part per turn (the
conversion, the suites and docs), with a measuring agent for the parity.

**What was built.** Eleven fields private, every read outside each class's file asking a method: a move's step target,
body radius, whether it has parked, whether it was walked round, and a new question, whether it is mid-step (asked by
the live event ending its route), with writers for its step target, its body radius, and two new ones, its parking and
its being walked round (the live event's setup and its change of phase); a shape's spine half-length, rounding radius,
rectangle half extents and whether it is a segment or a rectangle, all existing questions; how many times she was put
down outright, a new question named for what it counts (the checkpoint controller); her view through the existing
`camera_view()`. The excitement source's cache key holds the shape itself in place of three values copied from it.
`tools/field_reads.txt` lost the four classes' 26 lines and gained none.

**A test that wrote a shape in place** (`test_prediction_reuse.gd`) builds rows of other shapes and swaps them in, since
nothing in the game changes a shape after it is made; with the key's shape entry broken, 28 of its 7,043 checks fail:
the shape replacement's 8, the no-shape 12, and the swapped rectangle's 8, which holds what main's in-place write of a
shape's kind and extents held. On main, with the old key's copied shape values made constant, 36 of 7,207 fail: the same
replacement and no-shape checks and its two in-place writes, of a shape's length and of its kind and extents, 8 each.
The swapped segment that stood for the length write held the same as the replacement check and is deleted, 164 checks
across the catalogue's rows.

**Measured.** On main and the branch, every line of the row fingerprint (every row, every copy, the planners' plans) is
byte-identical, and the look, excitement and placement fingerprints, `placement_rows.gd`, `escape_density.gd`,
`curly_stork_piece_layout.gd`, the crowd's yields probe and the screen reads print the same but timings; no cost figure
moved. Two probes fail the same way on main: the crowd's yields probe leaves three bus signals connected, and the corner
probe never reaches its end without a screen.

**Left of row 4b**, which the queue gives a twelfth pull request: the composer's writes of the live event's behaviour
slots (`event_behaviours.gd`, the `[EventInstance]` lines of `tools/field_reads.txt`) and the two members
`dead-code-sweep.md` hands to 4b, `EventDef.effect()` (nothing calls it) and `EventHold.stop()` (only a test calls it).

**Open to overturn:** the four new methods and their names; the swapped rows in place of the in-place shape write; the
walk's ground and the seal-reach rig asking a shape's kind through two questions in place of a `match`.
