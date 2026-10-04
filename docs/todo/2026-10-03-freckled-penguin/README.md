priority: later

# freckled-penguin — Rethink the masts · filed 2026-10-03

[quiet-yak, the inbox from the feathery-marmot session](../../playtests/2026-10-03-quiet-yak.md)
files it from #486 and #503. Asked whether day 11's mast task should add a seventh mast near the
mark, overturning M180's six fixed mast sites, the player said:

> The 6 masts rule is stupid anyway. It doesn't come from me. And it actually makes it harder to
> encounter masts. We need to discuss this again but not now. Now just add a new mast close by

and later, about the mast added near day 11's mark:

> we need to rethink masts anyway

**What stands now.** `MastSites.compute(map)` (`src/events/mast_sites.gd`) farthest-point-samples
`Tuning.MAST_COUNT` (6) sites over the city, and `EventScheduler._place_masts()` plants a
`loudspeaker` at each from day 5, the same sites every day (the M180 loudspeaker record,
`tools/decisions.sh M180`). Day 11 alone queues an extra mast near her when none is in reach of the
mark (the feathery-marmot record). The player's complaint is that six fixed sites make masts hard
to come across, and that the rule is not theirs.

**This entry is a conversation, not a build.** Nothing here is ready for an agent: it waits until
the player wants to discuss how masts are placed. What would make it worth raising: the player
asks, or a playtest reports that masts are rarely met.

**Proposed, not asked for:** band `later`, since the player said "not now". The marble bags
(olive-badger) are one possible shape for "masts she meets", since the player expects day 11's
queued mast to be simplified by them (#504); that is the filer's link, not a design.
