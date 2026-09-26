## M101 — The fire is found before the engine · built 2026-09-11

*(2026-09-09: "the player should encounter the burning building before the fire truck. basically
the fire truck should spawn when the player sees the burning building not the other way around";
on its place: "M101 can go after the Act III stuff".)* Built ahead of act III with the rest of the
2026-09-11 batch, two agent commits on `feature/fire-before-engine`, reviewed here. **The fire is
day 3's one-shot and the engine is what the sight of it summons.** `burning_building` took over
`fire_truck`'s `ONE_SHOT` slot, sited on the pavement against the building the way the reversing
lorry is; `fire_truck` is `SCRIPTED` and never scheduled. A new def field, `spawns_on_sight`, is
the link in the opposite direction from `spawns_on_finish` — a row naming what arrives once this
one has been seen — and `EventManager` owns the trigger, since it already owns the successor
mechanism and her position. `spawns_on_finish` stays: the convoy still uses it. "On screen" is a
box test against her live position over the view's half extent rather than `DangerEdge`'s own
predicate, which needs a live control a headless rig has none of; screen rotation is ignored,
a touch-only concern. The engine enters along the fire's own street from off screen — the side
chosen by the day's seeded RNG, the other side if one is out of bounds, nothing if neither fits,
retried next frame — and parks at the near kerb across from the building.

**The contract, re-proven from the worst position.** The engine's telegraph is its approach, and
M114 restated it over the forward reach; the route's start is off screen by `Tuning.offscreen_lead()`
stated over the *fire's* position, not hers, with the view's half-diagonal added for the furthest
she can already be from the fire when it first comes into view — the ordinary lead rather than the
stricter one a `hard_fail` row needs, since the engine cannot end the day. The test asserts it
from the worst position on the street. The fire's own telegraph keeps its 2.2s number, now
documented as how long she has once it is in view — the stationary contract already covers it —
and its pulse, obstruction and scar are unchanged.

**Day 3, measured.** The scheduled plan for day 3 is unchanged by M101 — the same count and the
same total cost, since the fire inherits the engine's cost — and the engine is simply absent from
it, arriving at runtime only if the fire is seen; the quietest park's settle time on day 3 is
unchanged. So the day's realised cost is now conditional on finding the fire, which is the point,
and whether that reads differently to a player who never finds it is a played question. **The
larger swing in the same measurement was M100's**, below. `docs/EVENTS.md`'s examples that leaned
on the engine — the one-shot kind, the map route sentence, the finishing-position paragraph, the
table rows — moved in the same commit.
