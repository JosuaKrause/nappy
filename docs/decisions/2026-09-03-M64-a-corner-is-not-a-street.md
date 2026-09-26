## M64 — A corner is not a street · built 2026-09-03

*(2026-09-03, playtest 22: "barriers are still placed in odd ways that leave gaps and overlap with
other things".)*

**M48's two fixes both switched themselves off on the same ground, and each said so in its own
comment.** `EventInstance._spread_is_vertical`, which decides whether a barrier's segments lie along
local Y instead of local X, returned *not vertical* whenever both of a tile's coordinates fell inside
a corridor band — a junction, which "belong[s] to two streets at once, with no single direction to be
wrong about". `_centred_on_the_pavement_band` gave up on exactly those tiles too, because
`CityMap.pavement_inward` returns zero there: "nothing here has one band to be centred on." So a
barrier on a crossroads corner kept the raw lane-tile position *and* the unrotated lay.

**Refused rather than repaired**, which is this project's rule that placement is checked before it is
accepted, and the same shape M69 used to refuse a barrier beside a calm area's access street.
`EventInstance.has_a_spread(def)` names exactly the looks dispatched to `_draw_spread`/`_draw_cafe`,
and `EventScheduler._open_ground_for` refuses those a junction tile. **Two alternatives were named
and not taken:** passing the street axis the scheduler chose down into the instance (keeps every site,
but two barriers at one crossroads then face different ways), and centring on the nearer band while
leaving the rotation alone (fixes the offset, leaves half the corners lying along the street they
should block).

**The measured cost, 3 seeds × 14 days, and it is much larger than the arithmetic said.** `TODO.md`
had estimated *one pavement tile in six* from the lattice's geometry — a 14×14 cell holds 96 sidewalk
tiles and 16 are crossroads corners. The real pool already excludes closed, doorstep and kerb-rejected
tiles before a corner is asked about, so the drop is **23.7–24.3%** for `construction`, `cafe_tables`
and `market_stall`, and **40.6–40.7%** for `checkpoint`. The larger figure is not the rule reaching
too far: `checkpoint` also draws through `_draw_spread`, its whole function is closing a street, and
`CROSSING` tiles sit disproportionately next to junctions by construction, so more of that pool is
corner ground to begin with. No row failed to place on any sampled day.

**A cache bug was found on the way, and it predates all of this.** `EventScheduler._ground_for`'s
role-weighted cache key — placement, pavement side, role, site, `hard_fail` — did not distinguish a
spread row from a non-spread row asking the same five questions, so a plain row processed first
handed its unfiltered pool to a spread row and the refusal never ran. Caught by an end-to-end test
before it shipped.

**A spread was drawn wider than it obstructed.** `_draw_spread`'s docstring is the contract it broke:
a blocking object "is drawn at exactly the width it obstructs, by repeating a segment across it.
Anything else would be a lie about where the player can walk." The segments did; the end caps were
drawn *centred* at ±half, and `barrier_end.svg` is 6px, so a `construction` barrier obstructing 64px
drew 70. The cap is now inset by half its own width, asserted against the sprite's real size rather
than against rendered pixels. `construction` is the only row that passes a cap at all.

**`alley_robbery` is refused any alley cell on the day's corridor.** Under the sealing an alley is
how she gets round a wall, and a row that is lethal inside 30px whose own note says *"a robbery has
no telegraph you could see coming, and it never did"* is unfair on ground she has no way around.
Stated over the placement shape (`placement == [ALLEY]`) rather than over the id. It costs 10.6% of
alley tiles across 5 seeds × days 8–14, and the row still placed on all 35 samples.

**What none of this explains is the screenshot that started it.** Enumerating seed 2102613802, day 6
finds exactly two `construction` placements, at tiles `(154,20)` and `(88,67)` — neither on a corner,
and neither near the player's `(105,131)`. The barrier in playtest 22's picture is ~70 world px wide,
which is `construction`'s 64px obstruction plus its caps, and a road-closure barrier is ruled out
because `City._spawn_barrier` spans `STREET_WIDTH * TILE_SIZE` = 192px. **So a defect remains
unfound**, and the corner fix stands on its own evidence rather than on that picture.
