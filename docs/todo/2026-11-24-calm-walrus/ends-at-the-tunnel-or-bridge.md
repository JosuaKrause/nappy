# The escape ends when she enters the tunnel or crosses the bridge

The player: "the escape should end when actually entering the tunnel or crossing the bridge not
when reach that intersection" (inbox #1733 in spry-ferret).

**What the code claims today:** `DaySpec.Goal.CITY_EDGE` is documented as "the tunnel mouth or the
bridge deck", and `DayController._reached_an_exit()` ends the walk once she is within
`FINALE_EXIT_REACH` (1.5 tiles) of `FinalePlanner.exit_tile()`, the road tile under the tunnel or
bridge picture. The portal's face is drawn on the map's edge, past the last ground she can stand
on, so the walk ends at the first walkable tile inward of it, and the 1.5-tile reach can end it
while she is still on the street before the portal. That is not "entering the tunnel or crossing
the bridge", and it is what the player saw as the intersection. The item is therefore not done
already, whatever the goal's docstring says.

**Build:** the escape's win fires when she is in the tunnel or on the bridge, not on reaching the
street tile before it. The intersection stays part of her route; only where the run ends moves.

**Read as:** "that intersection" is the street tile before the portal. Which point of the tunnel
(its mouth or inside it) and of the bridge (its first tile or its far end) counts is open for the
builder to settle with the escape's day spec and show the player.
