priority: now

# lilac-stork — A bug band above now, and an up-next marker above both · filed 2026-10-11

[mossy-ferret](../../playtests/2026-10-11-mossy-ferret.md), #710:

> we need a new band "bug" that has priority over now. also, maybe something to indicate what to work on next?

> like "immediately after the current items are done" next, not the band next

Offered an `up-next` line in an entry, an inbox label, or a short list file, the player asked:

> what would be the issue with making it a band?

and, asked whether notes from playing now default to `bug`:

> Only when you say so

*The band is the filer's proposal.*

**What it changes.** The bands are `now`, `next`, `later` and `parked`, set by an entry's
`priority:` line and a note's `queue_<band>` label, and `tools/queue.sh` prints them in that order;
there is no order list to edit ([M223](../../decisions/2026-09-26-M223-2.md), the queue's order is a
priority band in each entry). This adds a `bug` band printed before `now`. A note from playing is
still filed `now` unless the player names `bug` (or another band).

**Up next is a marker beside the band, not a band.** Told that a band would cost the entry the band
it came from and one more edit, the player took the way round it (#713: "okay let's do that then."):
an entry's opening block may carry `upnext: true` beside its `priority:` line. The entry keeps its
real band; `tools/queue.sh` prints every marked entry first, in an "up next" section ahead of `bug`,
and the line is dropped in the queue move that starts the work, which puts the entry back in its
band. *Proposed, not asked for:* the same section also names the entries a live agent is working on
(a brief under `.claude/briefs/` whose branch is open).

The work is [a-bug-band-and-an-upnext-marker.md](a-bug-band-and-an-upnext-marker.md).
