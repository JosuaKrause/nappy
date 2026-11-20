# minty-quail — Row 3b's spawner and manager ask the live event and the row · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): fields are not API
(inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1589) is the row's "the spawner and the
manager ask the live event and the row", from the Opus design of row 3b (kept in the orchestrator's design folder),
built by a Sonnet agent.

**What was built.** The live event's `excitement`, `silenced`, `is_pelican`, `came_under_a_warning` and
`held_by_hand` are private; the spawner, the manager, streaming and the day director ask `source()`, `silence()` (which
also drops the source's cached contribution, as streaming did by hand), `be_drawn_as_the_pelican()`,
`arrive_from_its_warning()`, `is_held_by_hand()`, `end_now()` (the ending told from outside, which the spawner's
`retire()` called as the private `_finish()`) and `leaves_behind()`. The row answers `scar_id()` (asking the aftermath's own `scar_id()`) and
`may_be_drawn_as_a_pelican()`, and the spawner's record of a fixed body asks `stands_as_a_fixed_body()`. The marble bag's
`drawn`, the excitement source's `on_first_landing` and the city map's `block_plans` are private behind
`draws_made()`, `when_it_first_lands()` and `plans_by_block()`. A script rewrote 148 test, rig and probe files.
`tools/field_reads.txt` loses thirty lines and gains none; the suites ask the row's `obstructs_within()` where they read
`obstructs_radius`, and the projection-reuse suite checks a silenced event before it leaves, so it writes no private member.
Nothing a player sees or the run log records changes.

**Open to overturn (the builder's, where the design was silent or counted short):** the city map's `block_plans`
converted whole (about 170 reader lines, where the design counted six); the row's `obstructs_radius` kept public as a
`[kept]` line until row 4b, for three suite writes that set a row's reach by hand.

**The item.** Row 3b stays open until its last pull request; section 4.2's rows for the five members and
`field-reads.md`'s city paragraph say what is left.
