## M48 — Things drawn where they stand · built 2026-09-03 · `feature/drawn-where-they-stand`

Playtest 13's finding 3 and playtest 19's repeat of it — *"random gray barriers placed half on the
street and half on the sidewalk — no clue what they are supposed to be but they raise excitement for
some reason?"*, and *"they're all placed with an offset that makes them clip into other things — the
only barrier that is consistently correct is the full street closure"* — which is `construction`, and
which was wrong in three separate ways that are each a rule rather than a row.

**Built ahead of M64 because M64 stands on it**: M64 seals every street off the day's corridor with a
thing lying *across* it, on the order of a hundred and fifty bodies a day whose entire content is
which way they face.

**The first pass at item 1 read "the pavement" as "the lane", and was redone.** Capping every
`SIDEWALK`-placed spread at 16px (half a tile) makes a body that fits inside whichever single lane
tile the scheduler rolled — and at 16px a pram walks past `construction` on the free lane, which
removes the obstruction the row exists to be. It also removes the property M64's **soft seal** needs:
two ordinary obstacles, one per side, leaving no line to walk. The defect in the player's own words is
the **offset**, not the width.

**The fix is that a pavement is one piece of ground rather than two lanes.**
`EventInstance._centred_on_the_pavement_band()` moves a stationary, unpinned (`pavement_side == ANY`)
body from its lane tile to the middle of the two-lane band before `setup()` hands its position to the
drawing or to the collision circle, so the two always agree. The cap that makes correct is **32px**
(half the 64px band): `construction`'s 34 trims to 32, and `market_stall` (28) and `cafe_tables` (24)
fit once centred and keep their original values. Rows pinned to an edge on purpose — `delivery_van`,
`reversing_lorry`, `pavement_side == AT_THE_KERB` / `AGAINST_THE_BUILDING` — are exempt by
construction, checked against `delivery_van` specifically so the exemption cannot quietly become
*everything gets centred*: a kerbed 44px body still leaves 26px to the frontage, narrower than the
28px pram.

**The arithmetic that makes `construction` the one act I event physically in the way**: she needs her
centre `obstructs_radius + PLAYER_BODY_RADIUS` = 32 + 14 = 46px from the barrier's centre, and the
band is 32px from that centre to either edge. 46 > 32 on both lanes, asserted directly in
`tests/test_events.gd` rather than left to a screenshot.

**Rotation is a property of the street, not a field on the row.** A per-row orientation field was
rejected: two rows on the same street have to face the same way for the same reason, so it is stated
once in `EventInstance.setup()` from `CityMap.corridor_offset()`. `_spread_is_vertical()` asks that of
both of a tile's coordinates, which is geometric rather than tile-type, so it answers a `ROAD` or
`CROSSING` tile (a checkpoint, the barricade a stopped convoy leaves) exactly as it answers a
`SIDEWALK` one.

**Open where the design was silent, and cheap to overturn:** a junction — both coordinates inside a
corridor band at once — and ground off any corridor at all (a square, a park, a courtyard) keep the
unrotated lay along local X, because neither has one street to be wrong about and X is what every
spread drew before the rule existed. `_draw_protest` and `_draw_firefight` have the same local-X-only
layout and are left unrotated for the same reason: their placement is `SQUARE` and `CROSSING`, open
ground with no single traffic direction to get wrong.

**The hazard colouring is not a new cue.** The **cues** vocabulary stays at four rows plus the entity
itself; this strengthens the first of them — *the entity itself carries most of it*.
`barrier_segment.svg` is now a cream board with diagonal red stripes, built the way
`checkpoint_block.svg`'s red-and-cream band already is, so the two read as kin without sharing a
picture: a street being mended against a street being held. `barrier_end.svg` is kept mostly
structural — the post rather than the board — so the repeated segments carry the warning rather than
every part competing for it.

- [x] **A body on a pavement has to fit on the pavement.** `construction` drew 68px wide on a 64px
      sidewalk from a tile centre 16px from one edge and 48px from the other, so it overhung by 18px
      whichever lane it landed in. This was M34's rule (*a body is half the silhouette*) meeting
      ground it was never checked against. `tests/test_events.gd` gains a catalogue-wide check,
      `_test_a_spread_body_fits_the_ground_it_stands_on`, so a future row with the same defect fails
      the build rather than waiting for a playtest, and `_test_a_kerbed_body_still_pins_the_frontage`
      pins the kerb exemption. The check's own comment records its blind spot: `burnt_shell` and
      `barricade` have no `def.placement`, so the loop never reaches them
- [x] **A spread is always drawn east–west, whatever street it is on.** `_draw_spread` spread along
      local X and nothing rotated an `EventInstance`, so the barrier that hangs into the carriageway
      on a north–south street lies *along* the kerb on an east–west one, parallel to the traffic,
      blocking a pavement it is not across. `_draw_spread` and `_draw_cafe` are rewritten in terms of
      `_spread_at` and `_spread_extent`, which swap the layout onto local Y when the instance's own
      `_spread_vertical` says to
- [x] **And it does not say what it is.** The sprite was blue-grey (`#6b7a8c`, `#4e5a68`) with no
      hazard marking. M37's rule — one picture per row, no two rows sharing one — passed here and the
      row still said nothing, which is that rule's own limit: *how dangerous a thing is has to be
      visible from looking at the thing*. Verified with `tools/shot.sh` against a live `construction`
      instance; the same screenshots incidentally show the rotation working, one instance drawn as a
      narrow vertical column on an east–west street
