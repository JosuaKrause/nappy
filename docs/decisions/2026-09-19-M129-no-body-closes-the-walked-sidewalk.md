## M129 — No body closes the walked sidewalk · built 2026-09-19

> "I still get hard walls on the side of the sidewalk that is on the path -- how can this be so
> hard to do correctly?" ([PLAYTEST-94](../playtests/PLAYTEST-94.md))

The player named no body, seed or day, so it was measured before it was fixed. Agent commits on
`feature/m129-walked-sidewalk-walls`; the probe is `tests/probes/m129_walked_sidewalk_walls.gd`
and its outputs, before and after, are `evidence/m129-walked-sidewalk-walls-2026-09-19/`.

**What was closing it.** Over six seeds by one day per act, 89 of 1869 walked-sidewalk bands had
no lane she fits through: 86 were one `delivery_van` each, placed by the scheduler's own candidate
loop, and 3 were a measuring artifact. None came from the four rows the wall rule named, from
seals, closures, region walls or the park passes. The van was simply never in the rule: parked at
the curb it leaves 48 − 22 = 26px to the frontage, and she needs 28px, twice
`Tuning.PLAYER_BODY_RADIUS` — the pram rides ahead of her circle, not beside it, so it adds
nothing sideways. (The 46px first written into the queue entry is one door's detain reach and
was wrong.)

**Built: a rule by fit, beside the rule by cost.** `_closes_the_band_by_its_own_placement` reads
a row's own `obstructs_radius` against where its `pavement_side` stands it and calls it a wall
when the gap left is under 28px; a wall gets zero copies on any cell that carries a route, as
before. A second hole closed with it: a van could land on a cell of the walked sidewalk that the
route does not itself step on, where the zero-copies rule does not look, so the cumulative check
in the candidate loop asks the same physical question (`closes_a_walked_sidewalk_band`, shared by
the probe and the suite). With the first alone the probe still found 2; with both, 0 of 1869.
The three artifact bands were streets built over at one end, where the check demanded a lane to
the band's raw corner; it now walks between the outermost real sidewalk tiles.

**Every other placing path, by reading:** `SealPlanner`, `ClosurePlanner` and `RegionPlanner`
each refuse a street the tree is on; the park pass places inside a calm block's own rect, which
holds no sidewalk tile; the two `_ensure_*` passes only remove. None needed a change.

**The poster crew stands against the building.** The rule by fit also caught `poster_crew`, an
11px body centered on the band (21px each side). Rather than send it across the street it is
sited `AGAINST_THE_BUILDING`, where it leaves 37px on the curb side and is friction again, which
is also where a crew pasting posters works. It can no longer appear on a square, since a
row that stands against a building needs one beside it; the player asked for a separate square
crew ([PLAYTEST-107](../playtests/PLAYTEST-107.md)), built below.

**What it cost, measured.** `delivery_van` still plans 43.2 a day; 46 of about 1036 in the sample
stand on a route street's far sidewalk where none did. The zero-cost-line share went 262 to 258
of 296, all four in act III and all explained by the van, which as a wall is weighed toward
junction rims; the rim decision below took that back. Two floors in `tests/test_events.gd`
moved with the van leaving the friction pool, each keeping the margin it measured: the corridor's
friction share 0.35 to 0.34 (measured 36.13%) and the narrow-friction share 0.40 to 0.39
(42.55%). **Both are open to overturn.** The friction test's sampling guard asks for two samples
where it asked for four, since the poster crew is now the whole of the population it samples.
A suite test, two seeds by three days, asserts that no body and no set of bodies closes a walked
sidewalk.

**Left alone:** `_closes_the_run`, the pacing rule's street-wide check, makes the same raw-corner
assumption the artifact exposed; nothing measured exercises it.

**A wall by fit gets no pull toward junction rims.** Asked whether the van, now a wall, should
also get the weighting that draws walls to the ground beside junctions
(`Tuning.EVENT_WALL_RIM_WEIGHT`), the player chose "A. No (my recommendation). -- do that"
([PLAYTEST-107](../playtests/PLAYTEST-107.md)). `_is_a_wall_by_cost` keeps the rim pull for rows
whose field alone clears the far lane — the pacing `homeless_yeller` among them — and a row
that is a wall only by fit keeps its zero copies on route cells and is otherwise weighed as
friction. Measured: closures 0 of 1869; the zero-cost line 264 of 296, against 258 with the rim
pull and 262 before the branch; vans 43.2 a day, with far-sidewalk landings 46 to 101, which is
the corridor weight landing on the one legal corridor cell a fit wall has. The narrow-friction
floor went back to 0.40 (measured 42.55%); the whole share's stays 0.34 (35.84%).

**The square's poster crew is its own row.** *"we need a separate square poster crew entity for
this"* ([PLAYTEST-107](../playtests/PLAYTEST-107.md)). `poster_crew_square` places on `SQUARE`
only, with no pavement side, and copies the sidewalk crew's field, point body, first day, act
and cost; `poster_crew` lists `SIDEWALK` alone. It has its own `EventDef.Look`, five views and
a badge. **Density is split, not added:** the pre-branch row put 3 of 512 crews on a square
over 48 planned days (0.6%), and squares are 1.1% of its candidate ground, so the square row
has weight 0.03 and a cap of 1 and the sidewalk row keeps 2.5 and 12 — 10.83 crews a day
together against the one row's 10.67 on the same seeds, a square crew about one day in eight.

**Open to overturn, chosen where the player said nothing:** what the crew pastes onto — a
free-standing advertising column, the orchestrator's idea; the display name "Poster crew", the
sidewalk row's own; the rounding of the split; the worker being the sidewalk family's figure
unmoved on a 44px canvas with a contact shadow baked under the column only. With no pavement
side the row always faces east, so four of its five views are authored and never drawn, as
`reversing_lorry`'s are. **The column is not solid:** the body is the worker's 11px point and
the column's axis is 15px east of it, so her circle can overlap the drawn column by about
10px; a second `SolidPart`, as the car crash has, is the fix if it shows, and `REVIEW.md` asks.

**The zero-cost line reads 261 of 296 with the square row in, and the row is not in it.** With
the row present at weight 0 the scheduler's weighted pick rolls against the same sum, the days
are bit-identical to the branch without it, and the probe reads 264. Any weight re-dices every
day: over 18 other cities the difference is −0.6 points from one base seed and +0.9 from
another, and `poster_crew_square` is in no cut and no blame row of any run. The weight was not
moved to buy the number back. After main's roadblock changes came in the merged tree reads
the same: 0 closures of 1869, 261 of 296, vans 43.3 a day with 102 on a far sidewalk. Outputs,
the control and the still are in `evidence/m129-walked-sidewalk-walls-2026-09-19/`.
