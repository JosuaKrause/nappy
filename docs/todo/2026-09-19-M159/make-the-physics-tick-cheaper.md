**Make the physics tick cheaper: the influence sweep and the events' step**
([jolly-trout](../../playtests/2026-10-04-jolly-trout.md), #542: "Also what about the physics twice
per frame? Should we fix that?", then "Sure we can look into making the tick cheaper").

On the phone 35% of frames run two or more physics ticks: the tick is 30 a second
([M141](../../decisions/2026-09-14-M141-the-physics-tick-at-thirty.md)) and a frame longer than
33ms catches up, which keeps the clock, chases and speeds the same on every device. Each extra tick
cost about 3.8ms in the phone's frame record: the crowd 1.7, the influence sweep 0.7, events 0.7
and the rest 0.7. The crowd's step and its agents' own update are cheaper ([M159-6](../../decisions/2026-09-19-M159-6.md)
and [the crowd tick record](../../decisions/2026-09-19-M159-8.md)). What is left, without changing
behaviour: the influence sweep and the events' step, measured the same way, with the crowd's probe
(`tests/probes/m159_crowd_tick_cost.gd`, which hashes every agent tick for tick, a leg through
walkers included) or one like it for what they change. Retain before and after per-tick distributions over equal windows
as evidence, as the entry's README asks of any optimization. The tick rate stays 30 and the number
of ticks a frame runs stays the engine's: capping catch-up would slow the game on a slow phone, and
a lower rate was not asked for.
