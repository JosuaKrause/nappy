priority: now

## M219 — On a pedestrian street a blocked walker turns round · found 2026-09-26

> "on the pedestrian street people don't turn around when their path is blocked so they accumulate
> on obstacles"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 5. On a precinct `CrowdAgent._footway_is_shut()`
never answers true (its doc: "A precinct is never shut this way … It is stepped round across all
six lanes instead"). So `_turn_round()` is never reached there. When stepping round a body gives
up, the walker slows to a stop at the obstacle, and the ones behind it queue up.

**Re-reported on 2026-10-11** on v0.27.1, seed 67, day 9
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #696):

> I noticed people still pile up in the pedestrian zone instaed of turning around at barriers.

Filed from `later` into `now` as a note from playing. *The filer's reading:* "at barriers" names the obstacle: walkers pile
up at the barriers standing in a precinct, rather than turning round in front of them.
