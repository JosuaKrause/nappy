## M200 — A region wall has a guard on each sidewalk · built 2026-09-25

*([PLAYTEST-135](../playtests/PLAYTEST-135.md): "maybe four? one on each sidewalk. would that cover
everything?" · "one guard in alleys on each end".)*

**What is built.** Since M196 every roadblock posts a guard on each side of its band, so a region
wall across a street — three bodies, sidewalk, road, sidewalk, 64px each — drew six, and each
mouth of a walled alley drew two, one of them inside an alley walled at both ends. `EventDef.
guard_sides` names the sides a roadblock posts a guard on, `[-1, 1]` by default, and
`_draw_roadblock()` draws one per entry. `SealPlanner.place_hard_on()` gives the road body of a
wall crossing a duplicate with the list emptied (`_no_wall_guards()`), so a crossing draws four;
`RegionPlanner._alley_mouth_wall_body()` sets each mouth's to its street side alone
(`_alley_mouth_street_side()`: `-1` at the mouth at the rect's start, `+1` at its end, on either
axis), so a walled alley draws two. The value is set on a fresh duplicate at placement and never
mutated in place, so the catalogue row and the door bodies are untouched. A wall's bodies are
never heated, so its guards never chase and this is drawing only; the halo and each guard's
shadow follow the same list. `tests/test_regions.gd` holds it: four guards per crossing and none
on the road body, a catalogue roadblock still two, and each alley guard's feet outside the alley.

**Four covers everything on a street**: whichever sidewalk she walks up to, from either side,
has a guard; the road lane has none. Recorded choice, open to overturn: the flag lives on the def
rather than on the placement (`Planned`), so one crossing can hand its bodies different defs.

**Unphotographed:** a wall across an east-west street and a walled alley mouth. No dev flag
spawns her at a coordinate, a wall body streams in only within `Tuning.EVENT_STREAM_RADIUS`
(900px) of her, `--walk` holds one direction, and `--spawn event:roadblock` finds the catalogue
row first. The north-south crossing's before and after are in
`docs/evidence/m200-region-wall-guards-2026-09-25/`.
