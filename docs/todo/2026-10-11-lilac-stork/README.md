priority: now

# lilac-stork — A bug band above now, and an up-next band above both · filed 2026-10-11

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

**Open, for the player:** the answer to "what would be the issue with making it a band?". The
filer's reading is that there is none that matters, so "what to work on next" becomes a band too.
*Proposed, not asked for:* a band `upnext`, printed first, above `bug`, for what is picked up
immediately after the current items. The only costs are that an entry moved there no longer
records the band it came from, and that its band line is edited once more when it is moved.

The work is [the-new-bands.md](the-new-bands.md).
