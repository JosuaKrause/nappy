## M181 — The seals are on her building's front · built 2026-09-25

*([PLAYTEST-131](../playtests/PLAYTEST-131.md): "we can add the door seal starting at the raid. and
the boarded window to indicate the neighbor" · "when returning to find the raid the door texture
should also have changed. and then the change stays" · "agree with putting the boarded window on
her floor".)*

**Where it is seen.** On her building's front and nowhere inside: the escape shows only a door's
back, so no door there is marked as the neighbor's. No sealed-door picture existed; both were drawn
new, SVG first, and shown as composed sheets before either went in.

**What is built.** `City.seal_home_door()` swaps her street door (`props/door`) for
`buildings/home_door_sealed` the moment `ResistanceHappenings._maybe_raid()` spawns day 10's raid,
while she is out and none of it is on screen, so she comes home to the vans and the sealed door
together. It is kept as a scar (`City.SEALED_DOOR_SCAR`), so it stands on every later day and in a
reloaded run, and a lost day 10 gives it back with its other marks; `_sync_home_door()` reads it
every dawn. From day 11's morning `City.board_neighbor_window()` lays `window_boarded_sealed` over
one window of her own building, the column nearest above her door on wall row 3, her third floor:
the escape counts floors from the lobby up, so the ground floor is row 0. The notice's stamp is a
red ring with a solid centre rather than the posters' ring and band, which on a door reads as "no
entry". Four checks in `tests/test_resistance.gd`.

**A front too short for a third floor** boards its topmost row instead. On seed 4242 her building
rolls two wall rows, which is what PLAYTEST-134 answered: her building will not depend on the seed
(M185), and it gets a height with a third floor.

**Two findings from the captures.** An earlier report that the rig started her off her doorstep on
day 11 came from the drawing agent's own picture matching, not the game: every run log starts her at
(80,84). And `tools/shot.sh` prints "wrote" whether or not a picture was written, while `--route`
quits on arrival before `--after` can fire; both are M195's.
