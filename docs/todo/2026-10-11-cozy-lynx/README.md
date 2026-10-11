priority: now

# cozy-lynx — Day 11's rigged mast stands on her route · filed 2026-10-11

Found while building [bouncy-egret](../../decisions/2026-10-10-bouncy-egret.md), not reported by the
player. Day 11's routed second mast is the rigged bag the player set in
[coral-bunny](../../playtests/2026-10-04-coral-bunny.md): "day 11 is going to be a x=3". On the
`tests/test_resistance.gd` rig (a 600s walk of the longest route after reading the mark), the mast
is put down on 10 of 30 seeds on `main` and 8 of 30 with bouncy-egret, so it is a defect on `main`,
not one bouncy-egret made. `tests/probes/bouncy_egret_day11_mast.gd` finds why: on seeds 4242,
314159, 1234567, 555555 and 8675309 only 1, 1, 5, 2 and 1 tiles of the day's route tree pass the
placement rules, 8 of the 10 on the city's edge. Every other tile fails
`_leaves_the_route_junctions_open` or `_leaves_the_routes_sidewalk_open` with the mast standing
alone, since its field reaches the junction box at the end of whatever street it stands on. The
city's six fixed masts are already exempt from those two rules (`_counts_against_the_line` skips a
plan with a `mast_id`); the queued and routed masts are held to them, as
[feathery-marmot](../../decisions/2026-10-03-feathery-marmot.md) says ("the route junctions and
sidewalks the day keeps open"). The work is [place-the-mast.md](place-the-mast.md).
