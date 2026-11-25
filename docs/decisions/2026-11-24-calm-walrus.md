# calm-walrus — The escape ends in the tunnel or across the bridge · 2026-11-25

The player: the escape should end when she actually enters the tunnel or crosses the bridge, not
when she reaches that intersection (inbox #1733 in spry-ferret).

**What it was.** `DayController` ended the walk once her centre was within 1.5 tiles
(`FINALE_EXIT_REACH`) of the centre of the spine's last walkable tile, so it fired as she crossed
the border junction's crossing, a tile or two before the portal.

**What is built.** *The game walks her in.* The section is won, and its clock stops, when her centre
is on the spine's last row at either end, across the carriageway (`DayController.FINALE_EXIT_DEPTH`,
half a tile along the spine; `Main._exit_point()` builds the point from `FinalePlanner.exit_tile()`'s
row and the tunnel's or the bridge's own column). Her control ends there: `Main._walk_out_of_the_city()`
hands her to `EscapeWalkIn`, which leads her on (`Stroller.lead()`, at a walk into the tunnel and a run
across the deck, through the boundary wall) into the tunnel's dark as deep as its opening (`CityEdge.TUNNEL_DEPTH_TILES` rows past the
edge) or across the whole deck (`CityEdge.BRIDGE_DECK_PX` past the edge), the camera following, and
the ending screen comes when she is in (`EscapeWalkIn.arrived`). The portal and the deck are drawn
past the map's edge, so the last row is as far as her own steps go.

**Nothing can catch her on the walk.** The section is already won when it begins (the day has ended,
so no loss path is listening), and `Main` pauses the tree with only her and the walk-in running (the
baby, her child node, is put back with the paused world, so her meters stand still and she cannot
wake on the deck after the win), so no car, walker or event moves. Esc and a lost focus open nothing
meanwhile. No walkable ground is added: the map's walkable set is what it was, as M204's record has it (the landscape outside the map
adds no walkable tile, collision or road).

**The point is the orchestrator's pick, open to the player's overturn** (on the board as
escape-end-past-the-edge), not the builder's and not settled by the player. The alternatives: walkable
ground along the spine past the edge, which touches M204's record and the reachability floods; or the
end at the threshold with no walk (the first version of this entry, which the review refused because
the last row is still a crossing tile and the bridge's deck is never set foot on). Two choices inside
the pick are the fixer's, for the player to read: the clock stops at the threshold, not at the end
of the walk (the walk is the game's, and the bridge's is far longer than the tunnel's, so a clock to
the far end would add a distance to every time), and the speed: across the deck at a run (it is
`BRIDGE_DECK_PX` long, a long way at a walk), into the tunnel at a walk, so that the dark ramp inside
the opening takes her a step at a time over most of a second (at a run she crosses its 64px in 0.4 s
and is gone in a handful of frames).

**Measured.** `tests/probes/escape_winnable.gd` on seeds 4242, 1, 77 and 9001 (the game's own bag,
one walk per exit): the same walks are lost and the same two are out as before (seed 4242 bridge at
40.8 s, seed 9001 tunnel at 62.0 s). The probe's rig quits at the win, so it does not see the walk-in;
the walk-in is held by `tests/test_escape_walk_in.gd` and the booted case in `tests/finale_rig.gd`.
