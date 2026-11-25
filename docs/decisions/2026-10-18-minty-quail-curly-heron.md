# minty-quail — The resistance asks events, rows and plans through methods (event interface row 3c) · 2026-11-18

**What it is.** The resistance's part of row 3c of minty-quail's `event-interface.md` (the event
interface: every caller asks an event through methods): the resistance director, day 12's park
cordon and the contact point ask rows, live events and plans through methods. An Opus builder built
it to the design's section 4 tables. It changes nothing in play; the run log's and GoatCounter's
names are unchanged.

**What was built.** Methods added, nothing else changed, on the row (`was_sent_at_her()`,
`paces_a_beat()`), the live event (`has_parked()`, `core_reaches(point)`, `is_ambient()`,
`was_sent_at_her()`, `departure_speed()`, `beat()`) and the plan (`is_a_boom()`,
`detains_again()`, `faces()`, `is_a_live_mast()`). The resistance reads through them and through
existing ones (`is_gone()`, `is_on_its_way_out()`, `core_within()`, `placed_at()`, `row_id()`,
`drives()`, `solid_reach()`); the park cordon's five-field test of who is walked out is
`is_ambient()`, `was_sent_at_her()` and `drives()`; the roadblock search uses the step's own task
id. `tools/field_reads.txt` lost 23 lines and gained none.

**Where the design was not followed, and why.** The contact asks the live `solid_reach()` rather
than the design's live `has_a_body()`, since the row's `has_a_body()` is a different test and the
contact tested a reach above zero. `core_reaches(point)` measures a disc round the event's centre,
as the contact did, not the shape `field_reaches()` uses, which would stretch a pacing man's core
ahead of him and change when day 6's note is delivered. The live event's `path` and `is_parked`,
read now only by tests (about 55 lines), stay public in `tools/test_only_members.txt` until row 4a.

**Left in the resistance:** the row's `id` and `speed` (4b; a method cannot share a public field's
name), the plan's `mast_id` (3a), `EventManager.points_at` (3b), the happenings' pacing copy of the
patrol car (4b's draft) and the world map's reads.

**Proposed, not asked for, open to the player:** the two departures from the design above; the
method names; `path` and `is_parked` kept public for tests.
