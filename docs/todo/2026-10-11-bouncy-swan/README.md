priority: now

# bouncy-swan — The phone's lag spikes are found and fixed · filed 2026-10-11


[coral-lark](../../playtests/2026-10-11-coral-lark.md), #670, statements 1, 3 and 5:

> also, there are big lag spikes in the last few days -- I reported that already -- just wanted to give some more info

Asked where, the player answered "Phone (web)", and chose a new entry in the `now` band over
adding the note to [M159](../2026-09-19-M159/README.md), a slow frame names the frame that was slow.
Then:

> I reported it earlier as soft lock but now I also encountered non-soft lock versions

**The earlier report is day 12's softlock**, the only softlock the player has reported (the
filer's reading of "it"). [azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 9:
"day 12 after closing the park and walking back with sleeping baby softlocks the game", said in
inbox #601, opened on 2026-10-06, on v0.25.4 or earlier, when the park was still closed by mud rings
that repainted its ground; [plush-marten](../../decisions/2026-10-10-plush-marten.md)'s police cordon
has replaced them, so a day-12 replay on a current build cannot recreate that exact case.
[snowy-trout](../../decisions/2026-10-07-snowy-trout.md) closed it as not reproduced on headless
desktop rigs and a suite, which cannot see a phone's frame time. *The filer's reading:* it was a
spike long enough to read as a lock, and the player now also meets shorter ones. The note names no
build for those.

**What exists.** The frame record (`--frame-record`, or `?framerecord=1` behind `?debug=1` on the
phone; `docs/TELEMETRY.md`, "Per-system frame records") keeps every frame's time by system for the
last few minutes, slow frames marked, and the page's own button saves it. M159 holds the profiling
tools and the phone constraint ([sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md)).
The work is [find-the-spikes.md](find-the-spikes.md) and [event-placement-completes-always-and-within-a-bound.md](event-placement-completes-always-and-within-a-bound.md).

[Velvet-marten](../../playtests/2026-10-11-velvet-marten.md)'s day-9 frame record on v0.27.1 holds a 775 ms frame, 748 ms of it `events`, kept under
[velvet-marten-phone-records-2026-10-11](../../evidence/velvet-marten-phone-records-2026-10-11/README.md). It is not
day 12's park sequence, which snowy-trout's review item still asks to be replayed on the phone.

The player asks to be asked for a frame record when a bug does not reproduce (#694 in
[coral-lark](../../playtests/2026-10-11-coral-lark.md)): the first step is one from the phone during
a spike, which velvet-marten's day-9 record is. On the phone every
frame already crosses the record's 25ms `slow` line ([M159-2](../../review/2026-09-19-M159-2.md)),
so a spike is found as the longest frames, not the marked ones.
