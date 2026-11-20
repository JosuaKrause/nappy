# minty-quail — Row 3b's director and what is sent ahead ask the row and the live event; crossing_ahead_of() is public · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): every caller asks an
event through methods (inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1581) is the row's
"what is sent ahead asks the row and the live event", from the Opus design of row 3b (kept in the orchestrator's design
folder), built by a Sonnet agent.

**What was built.** The row (`EventDef`) answers `is_past_its_switch_on(day)`, `comes_toward_her()`,
`is_placed_on_the_map()`, `noun_for(count)` and `hunts_for_her()`, and `comes_down_her_line()` asks the first with
`keeps_to_the_carriageway()`; the live event forwards `hunts_for_her()`. The event director and `EventsAhead` ask these
instead of reading fields; the director's stale opt-out line goes, so it is typed; `EventDirector.crossing_ahead_of()`
is public, which the scene recipes call. `tools/field_reads.txt` loses fifteen lines. The director's placement
fingerprint prints the same lines on main and on the branch; nothing a player sees or the run log records changes.

**Open to overturn (the builder's, where the design was silent):** `noun_for(count)` rather than the design's
`noun(count)`, since the row's public `noun` field stays until row 4b and GDScript lets no method share a field's name;
`is_past_its_switch_on(day)` answers false for a row with no switch (its one caller asks it of the charging dog, which
has one).

**The item.** Row 3b stays open until its last pull request; section 4.1 names `noun_for()`, row 3c no longer lists the
director's private call as left in the scene recipes, and `field-reads.md` drops the director from its untyped files.
