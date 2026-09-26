## M203 — A front nobody can stand at is covered by the roof in front of it · built 2026-09-26

*([PLAYTEST-138](../playtests/PLAYTEST-138.md): "the building in the back has a visible ground floor.
this is confusing since you can't actually walk in front of that building" · on the first
pictures: "it would be easier to just extend the roof from the bottom building above to the roof
of the top building".)*

**What is built.** A multi-story front's column is covered when the tile directly south of it is
another building on the fixed lattice (`CityMap.is_walkable()`, never a day's closures). A covered
column draws no facade at all. `City._assign_roof_extensions()` gives the building in front
`Building.roof_extension_rows` for that column, exactly the covered building's `wall_tiles()`, so
its roof reaches the covered building's roof line in its own colour, with a `ROOF_EDGE_N` cap on
top and a `ROOF_EDGE_W`/`ROOF_EDGE_E` step cap wherever a neighbouring column is shorter. The door,
storefronts, portico and fire escape land only on reachable columns, as M185 (a ground floor is
blank wall or shops) already required. `covered_ground_cols` decides what is drawn, never what is
rolled, so no seed's rolls move.

**Offered and rejected.** A row of windows on a covered ground floor, the first pass: the player
saw it on seed 61400 and asked for the roof instead. Its pictures stay in the PR's history.

**Choices open to overturn**, made where the queue was silent: a power station's fenced yard never
extends a roof (its hall can); a building can extend its roof over one neighbour while its own
front is covered by another; a step between two differently tall extended columns gets the same
cap as a step down to an uncovered one, which no sampled seed produced; roof furniture (vents,
tanks, ducts) stays on the building's own roof and is not carried onto the extension. A column
against the map's edge counts as covered with nothing to extend from, and stays blank.

Evidence: `docs/evidence/m203-back-front-windows-2026-09-25/`, seed 61400, before and after.
