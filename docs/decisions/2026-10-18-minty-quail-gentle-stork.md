# minty-quail — The live event's age is asked: row 3b · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): the live event's `age`,
a public property whose setter settled the phase, is asked through a method once its writers outside it are gone;
fields are not API (inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1597) is the row's "the
live event's age is asked", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a
Sonnet agent. It also takes the leftover rows 2b and 3c named: the looks' and the readout's reads of `age`.

**What was built.** `EventInstance.age` goes; `_age` stays and `age()` answers; `restore()` sets `_age` and settles the
notice itself, as the setter did. The excitement, the event look, the fire look, the rank look and the developer's
readout ask `age()`. Every suite's and probe's write of a live event's age is `restore(EventSave.aged(a))` (or
`aged(X.age() + d)` for a step), the one event that had already noticed her (the moved guard in
`test_event_manager`) keeping its notice through `restore(guard.save().at_age(...))`; no check changed meaning.
`tools/field_reads.txt` loses five lines. Nothing a player sees changes.

**Open to overturn, the builder's where the design was silent:** every write is a `restore()` rather than stepping the
event, since none of those events had moved; `restore()` also resets the stride, the route's start and the charge's
flags, which none of the edited checks read. The four probes the design names are converted and parse under
`check.sh` but were not run.

**The item.** Row 3b stays open until streaming keeps its own state per plan.
