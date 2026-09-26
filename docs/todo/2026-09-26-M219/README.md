## M219 — On a pedestrian street a blocked walker turns round · found 2026-09-26

> "on the pedestrian street people don't turn around when their path is blocked so they accumulate
> on obstacles"

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 5. On a precinct `CrowdAgent._footway_is_shut()`
never answers true (its doc: "A precinct is never shut this way … It is stepped round across all
six lanes instead"). So `_turn_round()` is never reached there. When stepping round a body gives
up, the walker slows to a stop at the obstacle, and the ones behind it queue up.
