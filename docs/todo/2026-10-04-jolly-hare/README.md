priority: now

# jolly-hare — The fire truck is lethal driving and solid parked · filed 2026-10-04

[calm-kestrel, the fire truck has a body](../../playtests/2026-10-04-calm-kestrel.md) files inbox
#558:

> the fire truck has no collision at all -- I can walk through it without it being lethal

Asked what touching it should do, the player chose "Lethal driving, solid parked (Recommended)":
while it drives it is lethal like a car (which
[grassy-alpaca](../2026-10-03-grassy-alpaca/README.md) makes lethal only in front of it while it
drives, see the item); once parked at the fire it is a solid body she walks round
but cannot be hurt by.

**What exists.** `EventCatalogue._fire_truck()` is a `SCRIPTED` row created once the fire is seen
(`spawns_on_sight`), `mobile` at 190px/s, `stops_where_it_arrives`, with a field (intensity 26,
70–340px) and no body: no `solid()` shape and no `hard_fail`. `docs/EVENTS.md` has its row.

**It keeps its warning.** Asked, about PR #597 (M226, one-second off-screen warnings), whether only
things that can end the day are warned, which would stop warning the fire truck, the player
answered "the telegraphing rule was about heavy penalty not *only* lethal" and "fire truck has heavy
penalty" (inbox #598 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md)). So the
fire truck is warned from off screen like every other thing so warned: the badge alone for at most
one second, then the truck placed just out of sight.

**The band is the player's**, for right after the release (inbox #591 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md), of this entry with pebbly-ibis,
olive-badger's forced cases and sandy-ferret): "queue those items as immediately now after the
release (but don't start them this session)".
