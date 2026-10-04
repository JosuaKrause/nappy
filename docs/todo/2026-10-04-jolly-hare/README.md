priority: now

# jolly-hare — The fire truck is lethal driving and solid parked · filed 2026-10-04

[calm-kestrel, the fire truck has a body](../../playtests/2026-10-04-calm-kestrel.md) files inbox
#558:

> the fire truck has no collision at all -- I can walk through it without it being lethal

Asked what touching it should do, the player chose "Lethal driving, solid parked (Recommended)":
while it drives it is lethal like a car; once parked at the fire it is a solid body she walks round
but cannot be hurt by.

**What exists.** `EventCatalogue._fire_truck()` is a `SCRIPTED` row created once the fire is seen
(`spawns_on_sight`), `mobile` at 190px/s, `stops_where_it_arrives`, with a field (intensity 26,
70–340px) and no body: no `solid()` shape and no `hard_fail`. `docs/EVENTS.md` has its row.
