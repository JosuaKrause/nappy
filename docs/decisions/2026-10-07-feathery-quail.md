# feathery-quail — A police car is never removed in her sight · 2026-10-11


[azure-koala](../playtests/2026-10-07-azure-koala.md), finding 5, inbox #601:

> police cars can disappear outright

**The likeliest cause was already fixed when this was built.** The report is from 2026-10-07;
[sunny-finch](2026-10-07-sunny-finch.md) (PR #660, merged 2026-10-10) found the investigating car
standing nose to her and vanishing beside her when its chase ended, and made every police car leave
only once 420px from her. The report gave no day, seed or moment, so every way a police car ends was
probed again headlessly on a real city, with the event manager's own tick and `VisibleView` as the
test of "in sight": the ordinary departure at its route's end, the investigating car that stops,
lets its man out, takes him back and drives on, and streaming. The first two end a car only once it
is out of her view. **Streaming did not:** `EventManager.stream_around()` streams a plan out by her
distance from the plan's *route*, and a car that has run out of route keeps driving as it leaves.
Following 120px behind one for about 1,460px (some 16s of walking), she saw it deleted 1,160px from
its route (the streaming radius plus its hysteresis) with her 124px from it.

**A live instance within `Tuning.OUT_OF_SIGHT` (420px) of her is never streamed out**
(`EventManager._could_be_watched()`), whatever its plan's distance; its own departure still ends it
once out of view. **And a leaving instance streamed out is over:** `_stream_out()` spends its plan
and releases its ground, as a finished plan does (a spent guard still returns as its barrier, as
[spotted-wombat](2026-10-07-spotted-wombat.md) built). Without that, a plan streamed back in is
rebuilt where it was planned; at walking pace that happens 900px from her, out of view, and the car
finishes on its next frame, so the spending is tidiness rather than a visible fix, and keeps day 12's
park people from being rebuilt inside the closed park. No departure route or timing changed.
`docs/EVENTS.md`'s "Going away" and the **events** skill's "Nothing vanishes" name the streaming
path. `tests/test_patrol_vanish.gd` checks the car followed out of its street is kept, failing
before the fix, and the leaving plan streamed out not rebuilt; the route's-end departure and the
investigating car's stop are guards that already held. There is no picture: the case needs a played
run of about 1,460px behind a leaving car, and the test judges "in sight" with the game's own visible
view. [The review item](../review/2026-10-07-feathery-quail.md) asks the player to watch for it.

*Chosen where the entry was silent, open to overturn:* the keep-alive is a 420px circle round her,
not her visible view; it holds for every event, not only the police car; and a leaving plan streamed
out is spent rather than kept.
