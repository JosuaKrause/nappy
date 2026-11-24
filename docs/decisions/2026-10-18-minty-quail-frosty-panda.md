# minty-quail — The events' interface design is built, and its file goes · 2026-11-24

`docs/todo/2026-10-18-minty-quail/event-interface.md` was the design of the events' interface:
every caller asks an event through methods, and an event is made of parts (inbox #1173 in
gray-dolphin). Every row of its section 5 is built, so the file is deleted; the whole text is at
`git show 3fa20307d:docs/todo/2026-10-18-minty-quail/event-interface.md`.

**What each row became.** 2a, the live event's behaviours asking it through `Figure` and handed
their settings (the records minty-quail-velvet-owl, -olive-finch, -tiny-alpaca, -tawny-swan,
-striped-hawk, -striped-magpie, -silver-marmot); 2b, the looks (-polite-newt, -mossy-hedgehog,
-tall-toad, -busy-badger, -merry-magpie, -calm-egret); 3a to 3c, the dawn and the walk, the event
manager's parts, the resistance, the scene recipes and the rigs; 4a, the tests, the probes and the
cost table through the methods (-busy-walrus, -grassy-elk, -frosty-wombat); 4b, a row written as
its parts through `EventDraft` (twelve pull requests, the first
`tests/probes/row_fingerprint.gd`); 5, the events' and the resistance's suites (the last,
-frosty-tapir). `docs/EVENTS.md` and `docs/ARCHITECTURE.md` describe the built interface.

**Open point 6, the answers that were slightly wrong, is all built.** The player's word was to do
what is the correct implementation (inbox #1278 in olive-ferret). The field's real shape is the
record minty-quail-dappled-llama; the ground a deadly event shuts is one stated fact,
`EventDef.catch_shuts_within()`, the record minty-quail-calm-marmot, with the route rig and the
live event asking the same fact (its follow-up, pull request 1695).

**What the file still owed, and where it went.** The two stale lines it carried about
`AbductionSpec` (`taken_over`, `standing_offset`) and the row's `pulse_period`,
`runs_its_own_line()` and `warning_picture` reads were true of no tree any more: the first two
members are private behind methods, and no `EventDef` group is left in `tools/field_reads.txt`,
which is empty. What was owed is the timing readings of its section 6 that 2a's last three pull
requests and 2b's six did not take: they are listed in the entry's README, step 4, for the end
remeasure. What was left of the scene recipes' walk (the route tree and the locations it works out
again) is `re-derived-cases.md`.

**The design's rules, kept for the reader who needs the reasons.** No getter or forwarder stays
under a field's old name so that old readers go on working (minty-dolphin #852), hence readers
first and the parts last. A method across objects, a property only inside its own class (inbox
#1173 in gray-dolphin, statement 28). The tests read through the methods too (inbox #1182 in
gray-dolphin). The cost per frame is measured and reported, never a bar: "get the clean design
first no matter the cost" (inbox #1278 in olive-ferret); no step was held or tuned for its time. A
dead `display_name` and `Texts.EVENT_NAMES` went in 4b under the player's rule on dead code (inbox
#1180 in gray-dolphin).
