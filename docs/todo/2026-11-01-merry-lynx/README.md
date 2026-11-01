priority: now

# merry-lynx — Ask the player for a phone frame record once the new version is published · filed 2026-11-01

[tiny-lark](../../playtests/2026-11-01-tiny-lark.md), #927: "close and open a new item to ask me for a frame record when the new version has been published".

**Context.** Split from bouncy-swan (the phone's lag spikes are found and fixed), closed in the queue review (inbox #922 in tiny-lark). The spike and the placement audit are recorded in [bouncy-swan](../../decisions/2026-10-11-bouncy-swan.md); the fix shipped. What was left is a day-12 frame record from the player's phone. The earlier report was day 12's softlock, said in inbox #601 ([azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 9: "day 12 after closing the park and walking back with sleeping baby softlocks the game"); a headless rig cannot see a phone's frame time, so the player is asked for a frame record (`?debug=1&framerecord=1`, saved with the page's own button; `docs/TELEMETRY.md`, "Per-system frame records") rather than the report being closed here (coral-lark #694-#695).

**The optional list of the placement audit's unmeasured costs is not carried over.** The proposal in the queue review dropped it and the player's answer asked for the frame-record item alone; the audit stays in the record above.

**Read as:** the ask goes to the player once the version carrying the fix is published, so the item waits on that release rather than on a build. *Proposed, not asked for:* the band `now`, the closed entry's own.
