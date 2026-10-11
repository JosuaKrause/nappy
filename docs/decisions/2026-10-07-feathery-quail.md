# feathery-quail — A police car is never removed in her sight · 2026-10-11


[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 5, inbox #601:

> police cars can disappear outright

**The report gave no day, seed or moment, so every way a police car ends was probed headlessly**, on
a real city with the event manager's own tick and `VisibleView` as the test of "in sight": the
ordinary departure at its route's end, the investigating car that stops, lets its man out, takes
him back and drives on, the car after its man's pursuit ends, and streaming. The first three end a
car only once it is out of her view. **Streaming did not:** `EventManager.stream_around()` streams a
plan out by her distance from the plan's *route*, and a car that has run out of route keeps driving
as it leaves. Following 120px behind one, she saw it deleted 1,160px from its route (the streaming
radius plus its hysteresis) with her 124px from it. Whether this is the moment the player saw is
not known; it is the one path found that removes a car in sight.

**A live instance within `Tuning.OUT_OF_SIGHT` (420px) of her is never streamed out**
(`EventManager._could_be_watched()`), whatever its plan's distance; its own departure still ends it
once out of view. **And a leaving instance streamed out is over:** `_stream_out()` spends its plan
and releases its ground, so a patrol streamed out while driving away does not come back at its
route's end when she walks back (a spent guard still returns as its barrier, as
[spotted-wombat](2026-10-07-spotted-wombat.md) built). No departure route or timing changed.
`docs/EVENTS.md`'s "Going away" and the **events** skill's "Nothing vanishes" name the streaming
path. `tests/test_patrol_vanish.gd` checks the car followed out of its street is kept, and the
leaving car streamed out is not rebuilt, both failing before the fix, with the three departures
that already held as guards. There is no picture: the case needs a played run following a leaving
car about 1.5km, and the test is the evidence. [The review item](../review/2026-10-07-feathery-quail.md)
asks the player to watch for it.
