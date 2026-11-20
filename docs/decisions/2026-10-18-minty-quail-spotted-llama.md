# minty-quail — Row 3a's plan marks go private: role, mast, silenced, permanent, and a mast site's id and foot · 2026-11-20

**What was asked.** Row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows and plans):
fields are not API (inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1580) is the row's "the
plan's marks go private", from the Opus design of row 3a (kept in the orchestrator's design folder), built by a Sonnet
agent.

**What was built.** `EventPlan`'s `role`, `mast_id`, `silenced` and `permanent` are private behind `role()` and
`mast_id()` (fields that are not yes-or-no keep their name, event-interface.md 2.1 rule 3), `silence()`, `is_silenced()`
(the yes-or-no field takes a new name), `make_permanent()` and `is_a_mast()`; a write is its verb (`stand_as_a_mast()`,
`silence()`, `give_role()`, `make_permanent()`). A mast site's `id` and `foot` are private behind `id()` and `foot()`.
The dawn's mast, one-shot and scar phases, the scheduler, streaming, `EventsAhead`, the run log's map, the resistance
director's five reads, 24 suite files, their helper and six probes ask the methods. `tools/field_reads.txt` loses eleven
lines (one more than the design listed: streaming asks `plan.is_a_mast()` where it read the row's `role`). Nothing a
player sees or the run log records changes.

**Open to overturn:** fork F3 of the design (the six placement fields' suite reads stay public until row 4a, as rows 2a
and 2b left theirs); and the builder's choice that the spoilage probe asks `plan.spoils()` instead of re-deriving it.
No suite line writes a value no game verb gives: `test_resistance_reach_relocated`'s sabotage check queues a fresh lit
mast through `EventManager.queue_a_mast()` and checks that `silence_all_masts()` silences it, so the guarantee its header
promises is held.

**The item.** Row 1 of section 5 (the run log's map asking the plan's `role()`) is done and leaves the table;
row 3a stays open until its last pull request; its text in section 5 says which of the plan's fields are
private and which wait for 4a, and section 4.3's rows mark the new methods.
