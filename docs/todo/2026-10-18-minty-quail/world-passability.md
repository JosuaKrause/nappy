# One record of what is blocked, and one navigator every mover uses

Five answers to "can this mover stand here?" disagree:
- the player is stopped by physics bodies (buildings, closure barriers, posts, cordon tape, event
  bodies: `city.gd` near 1206/1514/1606, `building.gd` near 612, `event_instance.gd` near 1745,
  `cordon_tape.gd` near 37);
- event figures check only tile types, `EventInstance.walkable_step_on` (near 3145) through
  `CityMap.is_walkable` (`city_map.gd` near 659), which ignores `closed_tiles`, `soft_sealed_tiles` and
  `obstructed_tiles` (hard seals, region walls, bands, cafés); `CityMap.clear_line` (near 697) uses the
  same rule, so a pursuer notices and catches her through those bodies, as its own comment says ("with
  a clear line he goes straight at her, through a barrier as any chase does", near 3260);
- the crowd's own `_cannot_go_on`/`_may_stand_on` (`crowd_agent.gd` near 2123 and 1073);
- the red arrow's `ArrowField.ground_for` (`src/resistance/arrow_field.gd` near 80), the only complete
  one, not on `CityMap`;
- seven hand copies in `ResistanceDirector` (near 833, 990, 1418, 1512, 1568, 2517, 3087).

About eight separate flood fills each carry their own rule (`CityMap.walk_field_from`,
`ReachabilityGrid`, `ArrowField`, `_way_on_out_of_sight_from`, `_keep_the_way_to_her_fresh`,
`CrowdPockets`, two in `ResistanceDirector`); real pathing round buildings exists for day 13's guard
alone (`_paths_to_her`). Departures walk a straight line with no check, `_leave`'s
`position += _heading * step` (near 4044-4053), for every dog that loses interest, every pursuer that
gives up, the warned neighbor and flushed flocks; `_walk_back`, `_walk_points` and
`_advance_along_path` never re-ask the map; the cat's crossing (`EventScheduler._cross_street_path`
near 3941) checks nothing and can end inside a lot; `_along_street_path` checks closures only;
`Crowd._bump` pushes a walker with no check. Bodies and tile records are two authored copies of the
same solids, so a thing with only one is solid to one side and see-through to the other. A step
checks only the tile it lands on, so a frame hitch can carry a chaser through a one-tile wall.

The player: "I mean that happens with a lot of events (eg cat / bike just completely ignoring
buildings; neighbor walking through barricades) we need to do a fix for this at some point but not
now", and "those are examples not an exhaustive list" (minty-lemur #791).

**Build:** one blocked-layer record per map (static type, closures, seals, obstructions, posts, body
footprints) written from one footprint that also builds the physics body; `passable(tile, mover)`;
`clear_line(from, to, mover)`; one `Navigator` (`path`, `step` with a body radius, swept so it cannot
tunnel) injected into every mover; every departure, chase, walk-back, crossing and route goes through
it, and nothing writes `position +=` directly. A test walks every row that moves, on several seeds,
and fails on any step onto a blocked tile.
