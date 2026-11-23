# minty-quail — The scenery and prediction suites reach a live event's phase without transition() (tests-one-module, the events) · 2026-11-23

**What was asked.** `tests-one-module.md`'s events entry: the suites that call `EventInstance.transition()` to put a live
event in a phase reach it the way the game does or take a fake (inbox #1156 and #1159 in gray-dolphin; curly-rabbit
#1098). Built as #1663 by a Sonnet agent from an Opus design, for the scenery animation and prediction reuse suites.

**What was built.** The scenery suite's check that a finished event hides every scenery layer is deleted: only the crash
and the burst water main have scenery, both last the whole day and nothing ends them, so the game never reaches it; the
look's `is_gone()` clause it held still decides a retired slice's visibility, which a market stall reaches. The
prediction suite keeps real events, since the projection is the event's own field reprojected and no fake could answer
it without logic of its own: a waiting row notices and lunges through a streaming restore, a mast is silenced, a row
leaves for a completed task and is retired through the manager, each on a fresh event restored from one save so the
check can fail, and a guard holds that each kind of change moved the answer on some rows. The parked write is deleted,
since no change to the projection's cache made it fail.

**Measured.** The scenery suite went from 156 checks to 152, the prediction suite from 7043 to 6742.
