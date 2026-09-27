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
extends a roof (its hall can), so a front facing it keeps its facade; a building can extend its roof over one neighbour while its own
front is covered by another; a step between two differently tall extended columns gets the same
cap as a step down to an uncovered one, which no sampled seed produced. The yard guard has no
picture because no seed tried has a column it applies to: none in the 40 seeds `61400 + 977·i`,
and in the 200 seeds `500000 + 7919·i` the 14 covered columns standing over a power station are
all over its hall, none over its yard. One of them, seed 1917501 (a dead end's wall `[118,14]`
2×6 over the hall's columns 0–1), is the picture of the hall extending its own roof.

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
through `Building.roof_cell_edges()`). The
review of 16c99ae8 found the gate in front of the pool still read the building's own roof depth
(`roof_tiles() < 3`), so a covering roof two rows deep of its own stayed bare however deep its
extension. The gate now reads the tallest column, extension included
(`Building.roof_interior_cells()`). Over the 12 seeds `61400 + 977·i`, 277 buildings extend a
roof; 135 of them have a lip-free cell on the extension, 107 of those under three rows of their
own. Furnished extended roofs went from 45 to 147, and 51 carry a unit on the extension itself.
The review of 4771dc08 found the pool listed column by column where `main` lists it row by row;
the shuffle permutes positions, so 435 of 466 furnished roofs with nothing to cover (six seeds)
had their units on other cells than on `main`, against every claim that nothing else moved. The
pool is listed row by row again, up to the tallest column, keeping a cell only below its own
column's top. On the six seeds `61400 + 977·i`, all 825 buildings with nothing to cover (468 of
them furnished) now carry exactly `main`'s layout, and a test pins two of seed 61400's roofs to it.

**Settled: a front facing the map's edge keeps its facade.** `CityMap.tile_at()` reads a tile
past the map's edge as `BUILDING`, so a front whose south tile is off the map first read as
covered, with no lot on the other side to extend a roof from: it drew no facade and left the dark
background where its wall was. Asked, before any picture of it existed, whether to keep that or
treat the column as reachable: "keep the special case for dead ends." (2026-09-26). Shown seed
73124's before/after, the facade on `main` becoming a near-black rectangle: "Keep its facade"
(2026-09-27). The answer is built as a rule rather than a list of exceptions, and that
generalization is open to overturn: a front column draws no facade only where a roof extension
actually covers it. `City._assign_roof_extensions()` narrows `covered_ground_cols` to the columns
an extension reached, so a column facing the map's edge, a power station's yard or any south
tile no lot owns keeps its windows, storefronts and door, as on `main`. On the pictured seeds the
only columns this uncovers are ones facing the map's edge, so no picture changed with the
generalization.

Evidence: `docs/evidence/m203-back-front-windows-2026-09-25/`, seed 61400, before and after; and
`docs/evidence/m203-roof-cases-2026-09-27/`, one before/after pair per roof case (PLAYTEST-144,
statement 17: "The roof cases are judged on pictures"), before being `main` without M203 or M216,
each from `tools/shot.sh <out.png> <s> --seed <n> --invincible --no-save --press key:4 0.5` plus
the flags named: seed 61400 `--spawn signal --walk 0.35n3.13w --zoom 0.6` (the first pair's
front again, its covering roof two rows deep of its own and now carrying a unit), seed 84848
`--spawn square` (a roof two rows deep of its own carrying a unit on
its extension), seed 72147 `--spawn signal --walk 0.35n --zoom 0.75` (a building extending its
roof north while its own front is covered, between two more of the same), seed 73124
`--spawn edge:s` (a front against the map's edge, which keeps its facade), seed 1917501
`--spawn power_station` (the station's hall extending its roof to a dead end's wall).
