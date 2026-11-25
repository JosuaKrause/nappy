# calm-walrus — The escape ends in the tunnel or on the bridge · 2026-11-25

The player: the escape should end when she actually enters the tunnel or crosses the bridge, not
when she reaches that intersection (inbox #1733 in spry-ferret).

**What it was.** `DayController` ended the walk once her centre was within 1.5 tiles
(`FINALE_EXIT_REACH`) of the centre of the spine's last walkable tile, so it fired as she crossed
the border junction's crossing, a tile or two before the portal.

**What is built.** The exit points are the middle of the carriageway on the spine's last row
(`FinalePlanner.exit_point()`), and the walk ends when her centre is on that row, across the
carriageway (`DayController.FINALE_EXIT_DEPTH`, half a tile along the spine, and the carriageway's
half width across). The last row is as far as she can go: the tile beyond the map is not ground
(`CityEdge` keeps every walkable tile where it was), and the portal's opening and the bridge deck
are drawn past it. The crossing before it stays part of the route.

**Open point settled by the builder.** Which point of the tunnel and the bridge counts: the last
row, the portal's threshold, because walking into the opening itself would move the walkable set,
which `CityEdge` and `tests/test_blocks.gd` hold still tile for tile. Stills of both ends are in
`docs/evidence/calm-walrus-escape-end-2026-11-25/`.

**Measured.** `tests/probes/escape_winnable.gd` on seeds 4242, 1, 77 and 9001 (the game's own
bag, one walk per exit): before and after, the same walks are lost and the same two are out
(seed 4242 bridge, seed 9001 tunnel); the out times moved by 0.4 s at most (40.5 to 40.8 s, 61.6 to
62.0 s), the cost of the walk's last tile or so.
