# calm-pelican — A place marble that cannot be sited never blocks the route · 2026-10-10

From the re-review of PR #565 (olive-badger, what she meets on her route is drawn from a marble
bag): a place marble (day 6's man shouting, day 11's second mast) that found no legal spot stayed at
the head of the queue and was retried every second, and until it was sited no cat, cyclist, loose
dog or return patrol came — on day 11 a mast drawn near home could stop the return patrols for the
rest of the day.

**Built in PR #643.** A place marble spends its queue slot and its marble the moment it is drawn,
then waits unplaced on the director's list of places her walk sites, with the same siting,
re-siting, once-a-second look and random stream as day 3's fire; `EventManager` adds it to the day's
plan on its first siting. The other fix the item offered, letting a failed siting step aside, would
have needed a second retry mechanism and reordered the bag. `MarbleBag._take()` now does what its
comments said: a queue that starts empty may be filled twice, any other once, so a rig bigger than
the ordinary set gets its full size (no route rig reaches this today). `docs/EVENTS.md` and the
`TASK_CONTACT_WITHIN_THE_NEXT` and `MAST_WITHIN_THE_NEXT` comments in `Tuning` say the guarantee is
about the marble, placed once her walk finds it a site; no number changed. New tests in
`tests/test_route_bag.gd` — a day-11 mast whose siting refuses everything while every return patrol
still comes, and rigs bigger than the ordinary set — fail 8 checks on the old code.

**Chosen where the item was silent, open to overturn:** after a place marble is drawn the next
interval is a fresh roll; a place's siting now has the walk-siting gates (18s of walking since the
day started, 400px from home), which the old path lacked; the first siting can come up to 1s after
the handover; a place that never finds a site is not met, with no dusk fallback like the fire's;
the per-day count for a place is taken when its marble is drawn.
