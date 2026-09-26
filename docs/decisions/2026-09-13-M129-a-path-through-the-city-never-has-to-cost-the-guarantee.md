## M129 — A path through the city never has to cost · the guarantee measured 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "a path through the city must never hit
excitement -- so all obstacles should be routable around by eg crossing to the other side of the
street … the routing should only cross the street at intersections".)* The entry's first item,
a probe before any rule: `tests/probes/m129_zero_cost_line.gd`, run by name with
`tools/test.sh probes/m129_zero_cost_line.gd`, one agent commit on
`feature/m129-zero-cost-probe`. Six seeds, one day per act, 298 routes, about half a minute.

**What a zero-cost line is, as measured.** A walk from the home notch (or the street it opens
onto) to any tile of the route's calm area, staying outside every placed row's `outer_radius`
where it emits and its `obstructs_radius` where it has a body, on the route's own streets and
the junctions at their ends, changing pavements only inside a junction box, never on a
mid-block carriageway; a route cell on no street contributes its own tiles; precincts and
absorbed streets are ground by tile type. City-wide rows and the queue-fed `AHEAD_OF_PLAYER`
and `TOWARD_PLAYER` rows are outside it, since they have no position at plan time. A pulse moves
no radius, so the top of a beat is the catalogued disc; a moving row's field is the plain disc.
Four bugs were found and fixed on the way, each of which had moved a headline number: an
absorbed street's grass read as carriageway, the line starting strictly inside the home notch,
a minimal-removal framing that found the facing pair zero times, and subtracting discs from a
flat mask instead of counting rows per tile.

**The result.** Routes with a zero-cost line, primary reading (a pacing row denies its whole
beat, mobile rows at their dawn position, region doors counted):

| act I | act II | act III | act IV | all |
|---|---|---|---|---|
| 16 of 88, 18.2% | 6 of 88, 6.8% | 0 of 73 | 0 of 49 | 22 of 298, 7.4% |

The other readings move it little: a pacing row denying only where its beat never opens gives
10.7%; every mobile row denying its whole swept route gives 2.7%; region doors left out, 7.7%;
catalogue rows only, without seals, walls and doors, 9.4%. A broken route is broken in 5.3
stretches on average and 12 at worst — 1469 cuts over 276 broken routes.

**The failing shapes**, by the routes each breaks first and by every cut:

| routes | cuts | shape |
|---|---|---|
| 171 | 773 | the junction itself is covered — the only legal crossing sits inside a row's reach |
| 47 | 169 | a pacing row whose beat never leaves an opening (`homeless_yeller`, end to end) |
| 24 | 144 | one row covering the street's whole width alone (`police_patrol`, `busker`, `ice_cream_van`) |
| 27 | 231 | a cut that is not a straight band across one street |
| 5 | 74 | a region door on the route (`checkpoint_hut`, by design from day 7) |
| 2 | 23 | a body with the far pavement also taken (`construction` + `cafe_tables`, `dog_walker` + `cafe_tables`) |
| 0 | 0 | two friction fields on facing pavements |

The rows most often in a cut: `dog_walker` (223 of 276 broken routes), `homeless_yeller` (221),
`cafe_tables` (207), `leaf_blower` (186), `poster_crew` (136), `police_patrol` (135). The shape
the entry predicted — a van with the far pavement taken — is the rarest, and the facing pair
never occurs, because one row is usually wide enough on its own: the street is 192px kerb to
kerb and the catalogue's reaches run 179 to 240px.

**The corridor crosses mid-block.** 258 of 298 routes put at least one cell on a carriageway
between junctions; 871 complete pavement-to-pavement crossings inside one street, about 2.9 per
route, all on ordinary streets and none on the spine, which routes reach along cross streets
that meet it at junctions.

**What follows, decided by the entry's own rule** that a rule whose case the probe never finds
is not written: the far-pavement rule as drafted is dropped, since the pair it guards against
does not occur, and the rules are rewritten in `TODO.md` against the shapes that do — a covered
junction, a single row wide enough to take a street alone, the yeller's beat, and the corridor's
own mid-block crossings. Which readings the rules answer (pacing as union or intersection,
mobile rows at dawn or swept, doors in or out) is the player's call and is put in the entry.
M131's map-placed flock was merged after these numbers were taken; a re-run is the first step
of any rule.
