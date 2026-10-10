**The fire truck has a body, lethal while it drives and solid once parked.** Give the row a solid
shape; while it moves, inside that body ends the day as a car's does; once it has stopped at the fire it obstructs like a parked car and
ends nothing. Every fairness contract in the **events** skill holds for a lethal arrival, and it keeps
its off-screen warning, M226's one second ("fire truck has heavy penalty", inbox #598 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md)); the route-redundancy guarantee in
**city** still holds with a parked
engine on the street, and `docs/EVENTS.md` and `docs/COSTS.md` say what is true. Play it in
`scene-recipes/fire-truck.json`.

**"As a car's does" meets [grassy-alpaca](../2026-10-03-grassy-alpaca/README.md)** (a car is
lethal only in front of it while it drives, queued `now`): once that lands, a car kills only what is
ahead of it. *Proposed, not asked for:* the driving truck follows the same rule, lethal only in
front of it while it drives, whichever of the two entries is built first; the alternative is its
whole body lethal while it moves.

*Proposed, not asked for:* the body matches the fire engine's drawing; a loss to it names its own
cause in the loss line, the run log and the GoatCounter loss event, as other causes do. The band
`now` is the player's, for right after the release (see the README).
