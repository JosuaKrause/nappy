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
rolled, so no front's rolls move. The one roll that does change is the roof furniture of a building
providing cover, which rolls over its larger roof (below).

**Offered and rejected.** A row of windows on a covered ground floor, the first pass: the player
saw it on seed 61400 and asked for the roof instead. Its pictures stay in the PR's history.

**Choices open to overturn**, made where the queue was silent: a power station's fenced yard never
extends a roof (its hall can); a building can extend its roof over one neighbour while its own
front is covered by another; a step between two differently tall extended columns gets the same
cap as a step down to an uncovered one, which no sampled seed produced.

**Settled: an extended roof carries furniture too.** The first build kept vents, tanks and ducts
off the extension so no seed's furniture would move. Asked why (PLAYTEST-144, 17), the player:
"You can just use rng when extending too the while prices is deterministic so a fixed seed will
still produce the same results." `Building._build_roof_furniture()`'s pool now spans each column's
extended height, so a covering building's whole layout is a different shuffle from the one it had
(the pool grows before the shuffle), and the same on every run of a seed. The review of 00284bdb
found two loose ends in that change, both closed: the `roof_extension_rows` setter only redrew,
so a value set after the building entered the tree left the furniture stale (it now rebuilds), and
an extension cell beside a shorter column, where the step's side lip is drawn, was in the pool
against the rule that a unit never sits on a cell a roof's own lips draw (it is now left out,
through `Building.roof_cell_edges()`; the unextended rows are the pool they always were). The
review of 16c99ae8 found the gate in front of the pool still read the building's own roof depth
(`roof_tiles() < 3`), so a covering roof two rows deep of its own stayed bare however deep its
extension. The gate now reads the tallest column, extension included
(`Building.roof_interior_cells()`). Over the 12 seeds `61400 + 977·i`, 277 buildings extend a
roof; 135 of them have a lip-free cell on the extension, 107 of those under three rows of their
own. Furnished extended roofs went from 45 to 147, and 51 carry a unit on the extension itself.

**Settled: a column against the map's edge stays the special case.** `_covered_ground_cols()`'s
own out-of-bounds default (`CityMap.tile_at()` reads a tile past the map's edge as `BUILDING`)
marks such a column covered too, with no lot on the other side for `_assign_roof_extensions()` to
extend a roof from (`tile_to_index.get(south, -1)`, `if front_index < 0: continue`) — so it draws
no facade and stays blank, the one column this rule leaves with nothing covering it. In every
seed sampled this only ever happens where the front faces a cul-de-sac's dead end that runs to the
map's own boundary. Asked whether to keep this or drop it (treat such a column as reachable
instead, since nothing genuinely stands in front of it): "keep the special case for dead ends."

Evidence: `docs/evidence/m203-back-front-windows-2026-09-25/`, seed 61400, before and after.
