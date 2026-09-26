## M165 — The escape after the corrected stairs · built 2026-09-19

*([PLAYTEST-84](../playtests/PLAYTEST-84.md): "the basement stairs are bad. the steam walks for some
reason. the masked man is floating in the stairwell … the spawn in the city from the basement can
end up inside an obstacle. pathing is not done from the spawn but from the original door which is
incorrect" · [PLAYTEST-85](../playtests/PLAYTEST-85.md): "the spawning shouldn't be a check. the
pathing should start from the position. then obstacles can never happen. basement stairs are just
not stairs. at the very least use the one tile upward facing stairs we had earlier. how would steam
move? it doesn't make sense. have multiple fixed locations with steam that fully block the path and
have them turn off an on in different intervals so it becomes a timing puzzle.")* The first two
items were found reviewing M158, the staircase follows the corrected tile grammar, and kept out of
it on the player's word. Built by an agent on `feature/m165-escape`.

**What was built.**

- **The masked man runs the stairs.** His path was two points, lobby landing to top landing, on
  the reasoning that every landing sits on one column; the corrected grammar alternates them
  between columns 1 and 8, so the line crossed solid cells. `InteriorScene.stairwell_walk()` is
  the shaft's one branchless walk and his path is built from it. The test asks tile steps rather
  than sampled segments, since a diagonal step passes through the corner where four cells meet.
  **Measured: the nearest door is 32px off his line against the 28px `inner_radius` that takes
  the baby**, which is the whole of the brief's "going into a corridor and letting them pass".
- **The basement's entry is `stair_down.svg`**, restored from `60071de3` as one level walkable
  cell between the entry door and the corridor, so no diagonal is left for the clearance pass.
- **The steam is three fixed vents.** `basement_steam` is a solid 16px body on the seam of the
  two-tile corridor, which shuts it outright: her centre is held 30px out and the walls leave
  18px. The reasoning recorded under M102 that a standing vent left a four-pixel lane was wrong
  about where the body stands. `Tuning.FINALE_STEAM_PERIODS` is 6.5, 8 and 9.5 seconds and
  `FINALE_STEAM_BLOWS_FOR` is 2. Measured: vents 128px apart at the closest, and the worst
  pocket shut at both ends for 1.83s, which costs 32 of the meter's 100. One new `EventDef`
  field, `solid_once_it_starts`: the body goes down when the notice ends and is withheld while
  she stands inside it. Skipping the beat and moving her clear were both rejected, the second
  because it is a repair.
- **The finale plans from where she stands.** What started elsewhere was
  `SealPlanner.plan_finale()`, which spared the *front door's* street, and
  `EventScheduler.build_finale()`, which was offered her own tile. Both now take her position;
  placements refuse ground within a body's reach of it plus the half tile a stationary body is
  moved when it is built. The ten-seed test reproduced the defect first: an `abduction` van 32px
  from the spawn on seeds 31337, 808 and 6. The chains themselves already started at her cell.
- **The fire's words** and `InteriorScene.inner_floor_approaches()` say where it stands; the
  thirteen unbound deck, rail and landing sources are in the rejected-graphics archive and the
  `StairStructure` node is gone.
- **Found by the captures:** `--start-escape basement` showed the lobby and `lobby` the basement,
  because each part's waypoint was the two sides of one door and a transition fires on any frame
  she stands on one. Both waypoints moved off their thresholds.

**Chosen where the design was silent, open to overturn.** The stair picture is mirrored
vertically from the file as committed, so the treads narrow away from her as she walks in. It is
one cell rather than a stacked run, because the picture is a whole flight and a second copy reads
as a second stair; a longer flight is new art. A vent that finishes its notice with her inside it
is on and charging her but not solid until she steps clear, since "never turns on with her inside
its body" and "fully block the path" cannot both hold there. The periods and the two-second blow
are first numbers. **The masked man's margin is 4px**: raising `masked_pursuer.inner_radius` past
32 removes the answer to him, and the ways out are a wider level approach in the grammar or a
smaller radius.
