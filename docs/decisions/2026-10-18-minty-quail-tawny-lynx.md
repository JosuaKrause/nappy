# minty-quail — The live event saves and restores itself as one value: row 3b · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts): streaming carries a live
event's state out and back as one value, where four plan fields copied it one by one (section 2.11); fields are not
API (inbox #1173 in gray-dolphin; **designing-classes**). This pull request (#1594) is the row's "the live event saves
and restores itself as one value", from the Opus design of row 3b (kept in the orchestrator's design folder), built by a
Sonnet agent.

**What was built.** `EventSave` (`src/events/event_save.gd`, model, a `FILES` entry in `tools/layer_map.py`) holds a
live event's age, the distance it has come along its route, when it noticed her and each behaviour's state; its fields
are private and it never changes once made (`aged(seconds)` for an event that arrives part-way through its life,
`at_age(seconds)` for a copy at another age). The live event's `save()` and `restore(saved)` replace `resume()`,
`save_behaviours()`, `restore_behaviours()` and the public `noticed_at()`, with no forwarder kept; `restore()` keeps
the old order (the age half returns early for an age of 0, the behaviours half always runs). The plan's four fields are
one private `_saved`, with `saved()` and `leave_the_world(save)`; `arrive_aged()` sets it. Streaming's stream-out,
stream-in and `_done_for_now()` carry the save, a mast restored at the broadcast clock; the spawner's warned row and
`EventsAhead`'s two sends restore `EventSave.aged(...)`. A script rewrote thirty `.resume(` lines in twenty-one suite,
probe and rig files, the rest by hand; `tools/field_reads.txt` loses five lines. Nothing a player sees changes.

**Open to overturn, the builder's where the design was silent:** the save gives no whole-dictionary reader, so the
suites that compared two whole behaviour-state dictionaries round a stream-out compare the two saves' age, distance
and notice and loop `state_of()` over a written list of the behaviours that keep a state (`STATEFUL` in
`test_event_behaviours.gd`, which a new such behaviour joins by hand); `restore()`'s parameter is `saved` so as not
to shadow `save()`.

**The item.** Row 3b stays open: streaming's own state per plan and the live event's age are left. `_done_for_now()`
still reads the plan's public `arrives_aged`, which streaming's own state per plan makes private.
