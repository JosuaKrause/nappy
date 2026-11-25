# olive-lynx — A body is stood once · 2026-11-21

**What was asked.** The entry olive-lynx, a bug the design of curly-stork (a planned body's pieces laid out once) found,
filed `bug` as a bug a refactor step finds is (inbox #1519 in breezy-magpie): `BodyStance.stands_at()` moved an
already-stood point half a tile for a row it centers on its sidewalk band's middle, and two live callers stood a point
twice, so the record of those bodies' tiles came out half a tile off. Built by a Sonnet agent as #1602, from a
first agent's work that a usage limit stopped.

**What was built.** `stands_at()` returns an already-stood point unchanged (the filer's pick of the item's two fixes).
The band's middle lies on the line between two lanes, and a second standing read the lane past it; the shift onto the
band's middle is now worked out from the coordinate itself (the tile's offset plus how far into the tile the point
lies), as `CityMap.kerb_beside()` works out the kerb, so a point on the middle line stands where it is. Every caller
that passes a build point passes a tile's center, so the plan builder, the walk's ground,
the route rig and the live event's setup and moves answer as before, and only the two callers that pass a stood point
(`EventBody.tiles_at(body_position())` through `EventInstance.clear_line_to()`, and `EventSpawner.move_extra()`) now get
it back where it is. A suite holds it for every row stood on its band's middle (23 in the catalogue, eight of which the day cities place),
from the lane's middle and from points off it, and for the roadblock's kerb.

**Measured.** On base, a throwaway probe showed the record wrong for every café table, scaffolding and construction
handed a stood point, nearly every market stall and leaf blower, and a share of the loudspeakers, unmarked vans and
night raids. With the fix, curly-stork's sweep (`tests/probes/curly_stork_piece_layout.gd`) and
`probes/escape_density.gd` print the same on base and branch: planned bodies stand where they did.

**What a player sees: nothing.** None of the eight rows notices or pursues (`notice_within` 0, `pursues()` false), so
no line of sight leaves out their own body, and `move_extra()` moves only day 13's task guard, who has no standing body.
No pictures, since nothing is drawn differently.

**Open to overturn:** the fix chosen (`stands_at()` made idempotent rather than the two callers handing the build point),
the filer's pick.
