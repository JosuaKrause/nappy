# The escape's invisible wall (inbox #777)

**The claim, measured on `main` at `8d76e7e6`.** In the escape's city section, entered by walking
out of the building, a wall nobody can see runs the whole width of the city along row 26 (y 832 to
864). It is the escape building's
own collision. `InteriorScene._rebuild_collision()` puts a 32px `StaticBody2D` on every cell of the
building's footprint, grown by one cell, that is not floor. The footprint is tiles (0,0) to
(390,25) from the world origin, so that comes to 10,755 bodies covering city rows -1 to 26.
`main._on_escape_exit_requested()` builds the city beside the building in the same viewport, and
nothing takes the building's bodies out of the physics space, so she walks into them on the street.
Row 26 is the footprint's margin, so it is blocked along its whole length, and the walk north stops
on the row below it. That is tile 74,27, where the player stood.

**Why nothing was drawn.** The blockers have no picture of their own: they stand for the building's
walls and for the empty ground around and between its parts. The building's own pictures stay in
the tree at the same world coordinates. Near tile 74,27 those are floor cells only, on its ground
layer at z-index 0, the same as the city's ground. The city is added to the tree after the
building, so at equal z the city's ground is drawn over them. Its wall pictures, at z-index 1 like
the city's buildings, stand elsewhere along the strip, and nothing here checks how they draw. The
debug view's bounding-box layer (`3`) does not draw the blockers either, because in the city
section it walks only the city's subtree (`DebugLayers.collision_nodes_under()` is set up on
`main._world_now()`).

**How often, at `8d76e7e6`.** It happened on every seed and in every escape that reaches the city
through the building: a run's own ending, or `--start-escape` at any part but `city`. The tunnel exit is the
spine's top row (`FinalePlanner.exit_tile()`, row 0), and the service exit is always south of the
wall (row 80 on a 160-tile map). So the tunnel chain is cut off at row 26 every time, and the bridge
chain, which runs south, never is. It never happens in a city section booted on its own,
`--start-escape city` or a save reopened in the city section, because neither builds the building.
`seed-sweep-results.txt` covers 100 seeds:

- both exits are reachable on the plan alone on all 100;
- with the building's cells added, the tunnel is cut off on 100 and the bridge on 0;
- the service exit lands on a building cell on 0.

**Limits.** The sweep is tile-level. It walks the walkable tiles of the plan's open cells, four
neighbours to a tile, and ignores the escape's own event bodies on both passes alike, so it measures
what the building's cells alone take away. The real-physics reproduction is
`tests/test_escape_invisible_wall.gd` on the player's seed only. That the city covers the
building's floor pictures is read from tree order and z-index, not from a capture.

**The fix**, in the same pull request: `main._on_escape_exit_requested()` calls
`InteriorScene.take_the_walls_out()`, which frees the building's blockers before the city is
built. The building's pictures and its fade stay.

## What is here

- `run-170256-seed4216201080-v0.28.0-4-g2148e837/` is the player's run, kept under its own name. It
  was built from `v0.28.0-4-g2148e837`, which is commit `2148e837`, `main` at PR #774. It was
  booted with `--start-escape` (so day 1) and played through the building into the city.
  - `run.log` is the whole log. Its `plan` line (`tunnel via 3 calm, 119 cells | bridge via 3
    calm, 177 cells | 33 open streets, 642 placements`) is the one `main` prints when the test
    boots it on the same seed and day. The plans the test and the sweep make themselves match it
    in chains, cells and streets, with fewer placements (561), because they plan without the
    events (`FinalePlanner.plan(..., false)`), and the chains, cells and streets are all they read.
    The `blocked` line (pressed 0°, north, for 1.0s at 75,27 without moving) is the wall. The roadblock
    chase before it is the context for #771.
  - `asked/002-attempt1-asked.png` is the player's still: 74,27, speed 0.0, 148.9s left, open
    sidewalk ahead.
  - `auto/001-attempt1-chase-roadblock.png` is the automatic still at the chase's start. The guard
    stands at his post at tile 71,23, north of the wall, and he walks through ground she cannot,
    since a pursuer moves by position and has no body.
- `players-city.png` is the player's city at 4px a tile. Dark means ground she cannot stand on, grey
  open ground, amber the tunnel chain's open tiles, blue the bridge chain's, and red the building's
  cells over whatever they cover. Green is the service exit, white the two exits, and magenta 74,27.
  The grey zigzags inside the red are the building's own floor cells (its stairwells), and the
  building's walls close them off.
- `seed_sweep.gd` is the sweep, as text. Its header says how to run it.
- `seed-sweep-results.txt` holds the sweep's output, one line per seed, plus its totals.

Footprint: seven files, about 525 KB, nearly all of it the player's two stills.

## Reproducing it

From a checkout at commit `8d76e7e6a1eb0f608879b7225cbdf8a0a266b43f` with this folder and
`tests/test_escape_invisible_wall.gd` added. That commit was `main` when this was measured: the
player's build plus PR #775, which changes only `tools/reddit.py`, its test and a skill.

```sh
./tools/check.sh
tools/test.sh escape_invisible_wall
cp docs/evidence/escape-invisible-wall-2026-10-17/seed_sweep.gd tests/probes/eiw_sweep.gd
EIW_PICTURE="$(mktemp -d)/players-city.png" tools/test.sh probes/eiw_sweep.gd
```

The suite boots the real `main.tscn` on the building for seed 4216201080, day 1, walks out through
the service door's `exit_requested` and asks two things. At `8d76e7e6`, before the fix, both fail:

- A tile's step north from 74,27 is stopped, by `Interior/Collision/@StaticBody2D@…` at (2384, 864).
- 328 of the 1,170 walkable tiles on the escape's open cells overlap a body outside the city, every
  one of them under `Interior`, the first at 70,26.
