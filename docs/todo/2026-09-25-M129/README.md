## M129 — A path through the city never has to cost · one route in five still breaks

> "a path through the city must never hit excitement -- so all obstacles should be routable
> around … the routing should only cross the street at intersections"

[PLAYTEST-69](../../playtests/PLAYTEST-69.md), [PLAYTEST-71](../../playtests/PLAYTEST-71.md),
[PLAYTEST-75](../../playtests/PLAYTEST-75.md), [PLAYTEST-76](../../playtests/PLAYTEST-76.md),
[PLAYTEST-77](../../playtests/PLAYTEST-77.md). The four rules, the leaf blower's two-part field, the
wall reading and the catalogue seeing the seals and the region wall are built and recorded
(`DECISIONS.md`, M129 and its sections, the newest "the catalogue sees the seals and the wall").
The probe, `tests/probes/m129_zero_cost_line.gd`, assembles a day the way `EventManager.start_day`
does and finds a zero-cost line along 239 of 299 routes. A region wall or a seal may cost a route where it
stands at a junction ([PLAYTEST-140](../../playtests/PLAYTEST-140.md), statement 7: "it's okay if
the route costs something"), and it is most of what the probe still blames. What is left:
