# minty-quail — The debug views ask events and plans through methods (event interface row 3c) · 2026-11-18

**What it is.** The debug views' part of row 3c of minty-quail's `event-interface.md`: the debug
layers, the readout, the dev rig, the still watch and the auto screenshot ask live events and plans
through methods. An Opus builder built it to the design. It changes nothing in play or on screen:
the fields layer's cost probe draws the same number of outlines on main and on the branch on both
seeds, in the same time within noise.

**What was built.** On the live event `field_rings()` (a `Vector2` of the core ring and the outer
ring, one bird's reach for a flock with birds; asked once per event per redraw, allocating nothing)
and `ground_shape()`; on the plan `is_ambient()`, `notice_within()` and `heard_within()`, each
answering for its row, since no caller asks a plan's row directly. The views read through these and
through existing ones (`is_gone()`, `ends_the_day()`, `source()`, `row_id()`, `telegraphs_for()`,
`pursues()`, `placed_at()`, `faces()`). The dev rig asks `heard_within()`, a distance, rather than
`field_reaches(point)`, since it stands her off by a distance. The layers, readout and still watch
go over `EventManager.instances()` as before; none fetches one plan's live event (inbox #1278 in
olive-ferret). `tools/field_reads.txt` lost 22 lines and gained none.

**Left in the views:** the live event's `age`, read by the readout (a public property, a method once
streaming's resume (3b), the scene recipes and the tests (4a) stop writing it); the world map's
`size` in `dev_rig.gd`; the dev rig's call to the private `_spread_is_vertical()` (3b); the region
plan's `door_bodies` (3a).

**Proposed, not asked for, open to the player:** `field_rings()` returning a `Vector2`; the plan
answering the three questions for its row; the method names.
