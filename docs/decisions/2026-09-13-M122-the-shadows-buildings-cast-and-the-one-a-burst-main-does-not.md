## M122 — The shadows buildings cast, and the one a burst main does not · built 2026-09-13

*(2026-09-12, [PLAYTEST-66](../playtests/PLAYTEST-66.md): "don't draw a shadow for water main
breaks", and "can we do a one tile diagonal shadow from all buildings? like the bottom right of a
build has a shadow triangle 45 ne to sw with the top half filled. that shadow then goes all the
way to 1 tile left of the building and up to 1 tile before the building ends. buildings that are
joined don't have an extra shadow where they connect. this should make alleys more obvious since
they will have part of those shadows, too".)* Prioritised with the round: *"this round's feedbacks
should all be prioritized since I'm actively testing the changes as they come in."*

**The reading of the shape was put back to the player and confirmed on 2026-09-13** — *"yes, light
from the north-east, shade falling south and west, as written in its entry"* — so the geometry is
the entry's, not a derivation: a light to the north-east, and a building shades the ground to its
south and west by one tile. A band along its bottom edge runs one tile past its western corner; a
band up its western edge stops one tile short of its top; and the tile under the south-eastern
corner is cut on the diagonal from its north-east to its south-west corner with the half toward
the building filled. **There is no matching triangle at the top of the western band.** A true 45°
sweep of a box would put one there, and the player's sentence describes the bottom-right corner
only and the western band as stopping one tile short — the entry was written as read and the
player confirmed it as written, so the north-western corner is square.

**Stated as two rules over the union of every building footprint**, which is what makes joined
buildings shade as one without a special case: a ground tile outside the union is fully shaded
when the tile to its north-east is in the union, and it is the corner triangle when the tile to its
north is in the union and the tile to its north-east is not. `BuildingShadows.compute()` runs off
the occupied tiles rather than scanning the map, once per city build, since footprints are fixed
for the run (M61). Two buildings sharing an edge fall into one union, so the seam between them
grows nothing and the western building's own corner triangle becomes part of the continuous band
— `tests/test_building_shadows.gd` asserts that two edge-joined rectangles shade exactly as the
merged rectangle would, and pins the single rectangle's band-and-triangle shape including the
square north-western corner.

**Drawn flat, under everything that walks.** A `BuildingShadows` node sits between `Ground` and
`Buildings` in `city.tscn`, the slot `CityDecals` uses for flat un-sorted litter, so the shade lies
under the crowd, the player and every event the way a seal's body shadow does. The look question
the entry left — a flat dark at one alpha, or the ground's own colour taken down a step — went
with the entry's recommendation: flat, the same black every other shadow draws (`Palette.SHADOW`),
at its own alpha `Tuning.BUILDING_SHADOW_ALPHA`. **Silent choices, open to overturn**: the alpha
starts at 0.22, the value `Palette.SHADOW` already carries, since nothing asked for a different
strength and it is now one number; a shaded tile that falls outside the map (a building against
the edge) is drawn anyway, since the layer is a plain canvas draw with nothing to clamp against;
and the union is a dictionary keyed by tile rather than a flat byte grid, because it runs once
over a few hundred tiles. Whether the shade reads at that alpha, and whether an alley is more
obvious for it, is a `REVIEW.md` question; the before-and-after stills are
`evidence/m122-building-shadows-before-seed4242-day1.png` and `-after-`, same seed, day and
spawn.

**The burst main draws no body shadow.** `EventDef.draws_body_shadow`, `true` for every row but
`burst_water_main`, is read at the one place a shadow patch is put down, `EventInstance.
_draw_body_shadow()`, so refusing there is the whole of "no shadow" — the body, the two barriers
and the seal are untouched. The reason is the picture: the crater is sunk into the road, and a
shadow under a hole reads as a mound. `tests/test_event_views.gd` pins the query on the row and on
`fallen_tree`, its same-geometry sibling that keeps the ordinary shadow, following that file's rule
of pinning the query rather than calling a draw function directly.
