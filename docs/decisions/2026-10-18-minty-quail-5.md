# minty-quail — One record of what is blocked, and one navigator every mover uses · 2026-10-20


minty-quail's `world-passability.md`, the refactor's fifth PR (PR #817). The player: "I mean that
happens with a lot of events (eg cat / bike just completely ignoring buildings; neighbor walking
through barricades) we need to do a fix for this at some point but not now", and "those are examples
not an exhaustive list" (minty-lemur #791). Five answers to "can this mover stand here?" disagreed:
physics bodies stopped her, event figures asked only the tile's type (`walkable_step_on`, which
ignored closures, seals and event bodies, and so did `clear_line`, so a pursuer saw and caught her
through a barrier), the crowd had its own rule, the red arrow its own and the resistance director
seven hand copies; departures, walk-backs, route walks and the cat's crossing never asked at all, a
step checked only the tile it landed on, and bodies and tile records were two authored copies of
the same solids.

**Built** (`src/world/`). A `Mover` names the layers that stop it (the ground, a precinct's posts,
today's closures, soft seals, bodies, street ground only) and a body radius: `lattice()`, `ground()`,
`on_foot(r)`, `vehicle(r)`. A `BlockedLayer` is one record per map (`CityMap.blocked`) of posts,
closures, soft seals and bodies, bodies counted per tile and owner; the old fields are properties
over it. `CityMap.passable(tile, mover)` is the one predicate, `clear_line(from, to, mover)` the one
line test (a line from inside a solid sees out of it), `ground_for(mover)` the record laid out for a
sweep. A `Footprint` is one solid's ground contact and builds both its physics body and its tiles,
for events (`EventInstance.solid_footprint_of`) and closure barriers (`City.barrier_footprint`). The
`Navigator` is the one way a figure moves: a swept step that keeps its radius clear ahead (capped at
15px), so a long frame cannot carry anything through a one-tile wall, plus `move_to`, `walk`,
`path`, `way_out` and `trim`; the city builds it with the map and hands it to the event manager, its
figures, the crowd and the resistance director. On it now: every event figure's chase, walk-back,
departure, route walk, the far guard and the mouse's dash; both cat crossings, cut at the first solid
on each side. The director's run (not the scheduler's placed cat, which is only cut at solids and refused when it has no length) starts no nearer her line than `EventDef.nearest_crouch()` (the crouching
field's outer radius over sqrt(1 + (WALK_SPEED / speed)^2), about 112px for the cat), because when
the cat runs she is still short of the middle by the ground she covers meanwhile, and her walk must
not reach the crouching field before it does. It is centred where both sides allow that, runs from
the open side where only one does, and is refused where neither does (the director retries after a
second's walk, the owed row kept). A cat whose start is cut crouches longer by the run it lost
(`EventDef.crouch_for_a_run()`), so it still reaches her line when it did and its telegraph only
grows, and a crossing event that does not crouch is refused a shortened start;
bike, dog and patrol-car routes, trimmed when sited and when created; `_along_street_path` and the
neighbor's walk to work; the crowd's push and tile questions; the director's hand copies, chase
prediction, the guard's clear run and the roadblock guard's line; and the floods
(`ReachabilityGrid`, `ArrowField`, the guard's sweep, the way out of her sight). From
`likely-bugs.md`: the cat's crossing no longer ends inside a lot.

**Verified at test parity** (inbox #813): `check.sh`, `lint.sh`, `ci_telemetry_kinds.py` and
`cost-table.sh --check` (no route cost moved), and the full suite (`tools/test.sh`, all shards) with 0
failures. Tests changed only as far as the code moved: instances given a map by hand get its
navigator, callers of the removed step call `Navigator.step`, day 13's guard is measured over the
ground he walks, the placement test samples day 3 as well, since a scheduler re-roll moved day
1's only walled pacing beat, and `test_events_fire` measures where the cat's run meets her line
(`Geometry2D.line_intersects_line`) rather than the run's midpoint, which is the property its
sentence states: a run from the open side is not centred on her line, and at that test's spot (cuts
40.5px and 136.5px) the midpoint is 48px off it. A new `tests/test_world_passability.gd` checks the rules on hand-built
ground and, on seed 4242's day 9, that bodies and the record agree, barriers stand on closed ground,
the cat crosses open ground, a dog departs round solids and, walking on, she is never inside the
crouching cat's field before it runs (on seed 4242 day 9, 416 sidewalk tiles and 4 headings: the
old rule, a start under half a tile, put her inside it on 306 of 1062 crossings, the new one on 0 of
1031; the nearest start is 136.5px; the new rule refuses 31 more of 1063 placeable tries, 2.9%, each
a one-second delay); its walker runs 13 moving rows on routes
laid through her own building and fails when the route walk or the chase step bypasses the
navigator.

**Choices made where the design was silent, open to overturn:** a figure sees along its own
layers without street ground only, so the investigating police car (merry-stork) still sees her on
an alley, square, park or courtyard while it drives only on the street; a row's radius is its shape's reach
where the shape moves and a man's 9px where it is a solid he stands at; closures block lines as well
as steps; a pacer whose beat a solid crosses holds until the beat comes back, and any other route
ends at the solid and the figure leaves from there; a departure that meets a solid ahead plans a way
out of her sight, and where none exists over passable ground it may be held in view; a man walking
back to his vehicle goes round a solid on his trail or gets in where he stands; the flock's birds fly
over anything; the crowd's lane movement stays its own for `shared-components.md`; the cordon tape
keeps its tile rule and bollards and buildings their bodies; the dev scene-recipe runtime moves held
departures directly, since through the navigator they stop at the edge of an authored shot.

**Left:** day 12's cordon officers walk off the navigator, through the day's bodies beside the park
(`world-passability.md` now holds that); the building's events move with no map until `world-map.md`.
Tried and reverted for the cordon: dropping a point under a body, a slide under a quarter step
counted as stopped, and going round to the next point; the cordon closed and `park_cordon` ran in
24s, but the last gap closed 15–37s after the touch on 9 of the seeds suite's parks and the busker's
escort no longer brought him out, 18 checks failing.

**For the remeasuring step:** the walker over several seeds and days, every moving row; winnability
and route costs, since routes cut by solids make the scheduler re-roll rows and day plans shift;
pursuit catch timings at corners and bodies; pictures of a cat crossing, a departure round a
building, the neighbor at a barricade and a walk-back round a body.
