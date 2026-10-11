priority: now

# bouncy-swan — The phone's lag spikes are found and fixed · filed 2026-10-11


[coral-lark](../../playtests/2026-10-11-coral-lark.md), #670, statements 1, 3 and 5:

> also, there are big lag spikes in the last few days -- I reported that already -- just wanted to give some more info

Asked where, the player answered "Phone (web)", and chose a new entry in the `now` band over
adding the note to [M159](../2026-09-19-M159/README.md), a slow frame names the frame that was slow.
Then:

> I reported it earlier as soft lock but now I also encountered non-soft lock versions

**The earlier report is day 12's softlock**, the only softlock the player has reported (the
filer's reading of "it"). [azure-koala](../../playtests/2026-10-07-azure-koala.md),
finding 9: "day 12 after closing the park and walking back with sleeping baby softlocks the game".
[snowy-trout](../../decisions/2026-10-07-snowy-trout.md) closed it as not reproduced: headless rigs
and a suite on the desktop, which cannot see a phone's frame time. By the player's word it was a
lag spike long enough to read as a lock, and they now also meet shorter ones. The softlock was reported on 2026-10-07, so
the spikes were there by v0.25.x and through v0.26.0, v0.27.0 and v0.27.1, which brought many event
changes since (pursuers on foot, the park cordon, pathing for day 13's guard, cars that drive).

**What exists.** The frame record (`--frame-record`, or `?framerecord=1` behind `?debug=1` on the
phone; `docs/TELEMETRY.md`, "Per-system frame records") keeps every frame's time by system for the
last few minutes, slow frames marked, and the page's own button saves it. M159 holds the profiling
tools and the phone constraint ([sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md)).
The work is [find-the-spikes.md](find-the-spikes.md).

*Proposed, not asked for:* the first step is a frame record from the player's phone during a spike,
which only the player can take.
