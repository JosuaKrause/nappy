priority: now

# bouncy-egret — From the gatehouse day on, fewer hard blockers · filed 2026-10-10

[azure-puffin](../../playtests/2026-10-10-azure-puffin.md), point 4, inbox #664:

> when the guard houses are set up the city gets much harder to navigate let's loosen the density
> of the hard blocking events in that case. let's treat every street from that day on as if it was
> on a path (but keep the path calculations still the same for connectedness, distances, routing
> etc)

Asked whether that means, from day 9, no seals, no road closures and wall events weighted as on a
path everywhere, the player answered:

> fewer of all three. gatehouses stay and remain on the actual paths

The guard houses are the region doors' gatehouses, which `RegionPlanner.plan_day` puts up from
`Tuning.REGION_WALL_FIRST_DAY` (day 9). This loosens, from that day on, what
[M64, off the path is closed](../../decisions/2026-09-03-M64-off-the-path-is-closed-sealing.md)
puts off the day's route tree, and with it the rule behind M64,
[M55, off the paths is the dangerous place](../../decisions/2026-09-01-M55-off-the-paths-is-the-dangerous-place-partly.md). The work is [fewer-hard-blockers.md](fewer-hard-blockers.md).
